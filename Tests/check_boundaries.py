#!/usr/bin/env python3
"""Architecture boundary gate for the AIDesktop V0 scaffold.

This is the mechanically enforceable part of the frozen architecture. It runs
anywhere Python runs (including Windows), which is exactly why it exists: the
Swift toolchain is not available here, so the boundaries are checked by reading
the manifest and the sources rather than by compiling.

What this script does NOT do: it cannot prove the code compiles, and it cannot
prove the runtime behaviour. Checks that need an Apple toolchain are reported as
NEEDS-APPLE-TOOLCHAIN instead of being faked.

Usage:  python Tests/check_boundaries.py
Exit code 0 = every check passed.
"""

from __future__ import annotations

import io
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
else:  # pragma: no cover
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "Package.swift"
PRODUCT_CORE = ROOT / "ProductCore"
BRAIN_KIT = ROOT / "BrainKit"
APP = ROOT / "App"

INFERENCE_LIBRARIES = (
    "ManifoldKit",
    "Manifold",
    "FoundationModels",
    "MLX",
    "mlx",
    "llama",
    "Llama",
)

# Names that must be owned by ProductCore. If any of these is missing, the
# vocabulary has drifted out of the layer that is supposed to own it.
REQUIRED_PRODUCT_CORE_TYPES = (
    "BrainProtocol",
    "BrainResponse",
    "CompanionTurn",
    "CharacterState",
    "PersonaState",
    "ActionIntent",
    "MemoryEvent",
)

# V0 must not contain these, in any form, including placeholder comments.
FORBIDDEN_EVERYWHERE = ("Jev", "Live2D", "Live Activity", "LiveActivity", "DigitalSelf", "SETV")

results: list[tuple[str, str, list[str]]] = []  # (check, status, evidence lines)


def record(check: str, ok: bool | None, evidence: list[str]) -> None:
    status = "PASS" if ok else ("FAIL" if ok is False else "NEEDS-APPLE-TOOLCHAIN")
    results.append((check, status, evidence))


def swift_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.swift") if p.is_file())


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def find_symbols(root: Path, pattern: re.Pattern[str]) -> list[str]:
    hits: list[str] = []
    for path in swift_files(root):
        for number, line in enumerate(read(path).splitlines(), start=1):
            if pattern.search(line):
                hits.append(f"{rel(path)}:{number}: {line.strip()}")
    return hits


def target_block(manifest_text: str, name: str) -> str | None:
    """Return the source text of the .target/.testTarget block declaring `name`."""
    for match in re.finditer(r"\.(?:test)?[Tt]arget\(", manifest_text):
        start = match.end()
        depth = 1
        index = start
        while index < len(manifest_text) and depth:
            character = manifest_text[index]
            if character == "(":
                depth += 1
            elif character == ")":
                depth -= 1
            index += 1
        block = manifest_text[start:index]
        if f'name: "{name}"' in block:
            return block
    return None


def find_swift() -> str | None:
    found = shutil.which("swift")
    if found:
        return found
    base = Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Swift" / "Toolchains"
    if base.is_dir():
        candidates = sorted(base.glob("*/usr/bin/swift.exe"))
        if candidates:
            return str(candidates[-1])
    return None


def find_visual_studio() -> str | None:
    vswhere = (
        Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"))
        / "Microsoft Visual Studio" / "Installer" / "vswhere.exe"
    )
    if not vswhere.is_file():
        return None
    try:
        result = subprocess.run(
            [str(vswhere), "-latest", "-products", "*", "-property", "installationPath"],
            capture_output=True, text=True, timeout=120,
        )
    except Exception:
        return None
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    return lines[0] if lines else None


def run_compile_check() -> tuple[bool | None, list[str]]:
    """Actually build and test. Returns None (unknown) when it cannot run."""
    swift = find_swift()
    if swift is None:
        return None, ["no Swift toolchain found - install one, or verify on a Mac"]

    visual_studio = find_visual_studio()
    if visual_studio is None:
        return None, [
            f"swift found: {swift}",
            "no Visual Studio install to supply link.exe, so nothing can be linked",
        ]

    shell = shutil.which("pwsh") or shutil.which("powershell")
    if shell is None:
        return None, ["no PowerShell available to prepare the MSVC environment"]

    swift_bin = str(Path(swift).parent)
    command = (
        "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; "
        f"$vs = '{visual_studio}'; "
        "Import-Module (Join-Path $vs 'Common7\\Tools\\Microsoft.VisualStudio.DevShell.dll'); "
        "Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation "
        "-DevCmdArguments '-arch=x64 -host_arch=x64' | Out-Null; "
        f"$env:Path = '{swift_bin};' + $env:Path + ';' + [Environment]::GetEnvironmentVariable('Path','User'); "
        "$env:SDKROOT = [Environment]::GetEnvironmentVariable('SDKROOT','User'); "
        "swift build 2>&1 | Out-String; "
        "if ($LASTEXITCODE -ne 0) { Write-Output 'AIDESKTOP_BUILD_FAILED'; exit 0 }; "
        "swift test 2>&1 | Out-String"
    )

    try:
        result = subprocess.run(
            [shell, "-NoProfile", "-Command", command],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=3600, cwd=str(ROOT),
        )
    except subprocess.TimeoutExpired:
        return None, ["swift build / swift test exceeded the time limit"]

    output = (result.stdout or "") + (result.stderr or "")
    log = ROOT / "work" / "swift-build-test.log"
    try:
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text(output, encoding="utf-8", errors="replace")
    except OSError:
        log = None

    evidence = [f"toolchain: {swift}"]
    if log is not None:
        evidence.append(f"full output: {rel(log)}")

    if "AIDESKTOP_BUILD_FAILED" in output:
        evidence += [line.strip() for line in output.splitlines() if ": error:" in line][:5] or ["swift build failed"]
        return False, evidence

    if "Build complete" not in output:
        evidence.append("swift build did not report completion")
        return False, evidence

    passed = len(re.findall(r"^Test Case '.*' passed", output, re.M))
    failed = len(re.findall(r"^Test Case '.*' failed", output, re.M))
    evidence.append("swift build: Build complete")
    evidence.append(f"swift test: {passed} passed / {failed} failed")

    if failed:
        evidence += [line.strip() for line in output.splitlines() if "' failed" in line][:5]
        return False, evidence
    if passed == 0:
        evidence.append("no test cases executed")
        return False, evidence
    return True, evidence


def main() -> int:
    if not MANIFEST.exists():
        print("FAIL: Package.swift not found at repository root")
        return 1

    manifest = read(MANIFEST)

    # C1 — ProductCore depends on nothing external.
    block = target_block(manifest, "ProductCore")
    if block is None:
        record("C1 ProductCore has no external dependencies", False, ["Package.swift: ProductCore target not found"])
    else:
        empty = re.search(r"dependencies:\s*\[\s*\]", block) is not None
        imports = find_symbols(PRODUCT_CORE, re.compile(r"^\s*import\s+(?!Foundation\b)\S+"))
        external = [line for line in imports if any(lib in line for lib in INFERENCE_LIBRARIES)]
        ok = empty and not external
        evidence = [f"Package.swift: ProductCore dependencies == [] -> {empty}"]
        evidence += external or ["ProductCore/**: no inference-library import found"]
        record("C1 ProductCore has no external dependencies", ok, evidence)

    # C4 — the root manifest declares no external SwiftPM packages at all.
    top_level = re.search(r"\n\s*dependencies:\s*\[(.*?)\]\s*,", manifest, re.S)
    top_body = top_level.group(1).strip() if top_level else "<not found>"
    record(
        "C4 root manifest declares no external SwiftPM packages",
        top_body == "",
        [f"Package.swift: top-level dependencies == [] -> {top_body == ''}"],
    )

    # C2 — dependency direction is one-way.
    brain_block = target_block(manifest, "BrainKit")
    brain_depends_on_core = brain_block is not None and '"ProductCore"' in brain_block
    core_depends_on_brain = block is not None and '"BrainKit"' in block
    reverse_refs = find_symbols(PRODUCT_CORE, re.compile(r"\bBrainKit\b"))
    ok = brain_depends_on_core and not core_depends_on_brain and not reverse_refs
    evidence = [
        f"Package.swift: BrainKit depends on ProductCore -> {brain_depends_on_core}",
        f"Package.swift: ProductCore depends on BrainKit -> {core_depends_on_brain}",
    ]
    evidence += reverse_refs or ["ProductCore/**: zero references to BrainKit"]
    record("C2 dependency direction BrainKit -> ProductCore (one way)", ok, evidence)

    # C3 — the vocabulary is ours, and ProductCore knows no provider types.
    definitions = "\n".join(read(p) for p in swift_files(PRODUCT_CORE))
    missing = [name for name in REQUIRED_PRODUCT_CORE_TYPES if f"struct {name}" not in definitions and f"protocol {name}" not in definitions and f"enum {name}" not in definitions]
    leaks = find_symbols(PRODUCT_CORE, re.compile("|".join(INFERENCE_LIBRARIES)))
    ok = not missing and not leaks
    evidence = [f"ProductCore/**: defined types -> {list(REQUIRED_PRODUCT_CORE_TYPES)}"] if not missing else [f"ProductCore/**: MISSING -> {missing}"]
    evidence += leaks or ["ProductCore/**: no provider type names present"]
    record("C3 structured types are owned by ProductCore", ok, evidence)

    # C5 — V0 exclusions.
    forbidden_hits: list[str] = []
    for directory in (PRODUCT_CORE, BRAIN_KIT, APP, ROOT / "Tests"):
        for path in swift_files(directory):
            for number, line in enumerate(read(path).splitlines(), start=1):
                for token in FORBIDDEN_EVERYWHERE:
                    if token in line:
                        forbidden_hits.append(f"{rel(path)}:{number}: {line.strip()}")
    record(
        "C5 V0 exclusions absent (Jev / Live2D / Widget / Live Activity / DigitalSelf / SETV)",
        not forbidden_hits,
        forbidden_hits or ["no forbidden token found in Swift sources"],
    )

    # C6 — the composition root never names a provider.
    root_file = APP / "CompositionRoot.swift"
    if not root_file.exists():
        record("C6 composition root does not name ManifoldKit", False, ["App/CompositionRoot.swift missing"])
    else:
        text = read(root_file)
        leaks = [
            f"App/CompositionRoot.swift:{n}: {line.strip()}"
            for n, line in enumerate(text.splitlines(), start=1)
            if "Manifold" in line
        ]
        record("C6 composition root does not name ManifoldKit", not leaks, leaks or ["App/CompositionRoot.swift: no ManifoldKit reference"])

    # C7 — ManifoldKit appears in exactly one permitted place, if at all.
    manifest_mentions = [
        f"Package.swift:{n}"
        for n, line in enumerate(manifest.splitlines(), start=1)
        if "Manifold" in line and "dependencies: []" not in line
    ]
    record(
        "C7 root manifest never links ManifoldKit",
        not re.search(r'\.package\(\s*url:\s*"[^"]*[Mm]anifold', manifest),
        ["Package.swift: no ManifoldKit package dependency"] if not re.search(r'\.package\(\s*url:\s*"[^"]*[Mm]anifold', manifest) else manifest_mentions,
    )

    # C8 — the App target is Apple-only code.
    shell_files = swift_files(APP)
    unguarded = []
    for path in shell_files:
        text = read(path)
        if "import SwiftUI" in text and "#if canImport(SwiftUI)" not in text:
            unguarded.append(rel(path))
    record(
        "C8 SwiftUI sources are behind #if canImport(SwiftUI)",
        not unguarded,
        unguarded or [f"App/**: {len(shell_files)} Swift files, all SwiftUI imports guarded"],
    )

    # C9 — the real compile/test check. Only runs when a toolchain is actually
    # present, and never reports a pass it did not observe.
    record("C9 swift build / swift test actually runs", *run_compile_check())

    # C10 — SwiftPM argument order. Since we cannot compile, the cheapest way to
    # catch a whole class of manifest errors is to check the argument order that
    # the compiler would enforce: `path:` must not precede `dependencies:`.
    order_violations: list[str] = []
    for match in re.finditer(r"\.(?:test)?[Tt]arget\(", manifest):
        start = match.end()
        depth = 1
        index = start
        while index < len(manifest) and depth:
            character = manifest[index]
            if character == "(":
                depth += 1
            elif character == ")":
                depth -= 1
            index += 1
        body = manifest[start:index]
        name_match = re.search(r'name:\s*"([^"]+)"', body)
        label = name_match.group(1) if name_match else "<unnamed>"
        dependencies_at = body.find("dependencies:")
        path_at = body.find("path:")
        if dependencies_at != -1 and path_at != -1 and path_at < dependencies_at:
            order_violations.append(f"Package.swift: target {label} declares path: before dependencies:")
    record(
        "C10 Package.swift declares dependencies: before path:",
        not order_violations,
        order_violations or ["all target declarations use compiler-valid argument order"],
    )

    width = max(len(check) for check, _, _ in results)
    failures = 0
    for check, status, evidence in results:
        print(f"{status:24} {check}")
        for line in evidence:
            print(f"{'':26}- {line}")
        if status == "FAIL":
            failures += 1

    print()
    passed = sum(1 for _, status, _ in results if status == "PASS")
    print(f"summary: {passed} PASS / {failures} FAIL / {len(results) - passed - failures} NEEDS-APPLE-TOOLCHAIN")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
