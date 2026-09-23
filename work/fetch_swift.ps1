# Resumable, stall-tolerant multi-part downloader for the official Swift 6.4.0
# Windows installer (2 GB), which this network delivers at roughly 1 MB/s.
#
# Design notes, all measured on this machine:
#   * single connection          ~0.18-0.20 MB/s
#   * 8 connections via proxy    ~1.2 MB/s  (best observed)
#   * direct (no proxy)          ~0.74 MB/s
#   * `curl --continue-at` is mutually exclusive with `--range`, so per-part
#     resume is implemented by re-requesting only the missing byte range and
#     appending it with a .NET FileStream.
#
# A part that stalls simply gets another attempt; completed parts are skipped,
# so the script can be re-run at any time without losing progress.

param(
    [int]$Connections = 16,
    [string]$Proxy = "http://127.0.0.1:7890",
    [string]$Url = "https://download.swift.org/swift-6.4.0-release/windows10/swift-6.4.0-RELEASE/swift-6.4.0-RELEASE-windows10.exe",
    [string]$ExpectedSha256 = "76169a85bcba82854a0cd8f9655ffb74b3758d60c35a245457510095f2823c03",
    [string]$AlternateProxy = "http://127.0.0.1:7890",
    [int]$MaxAttempts = 400,
    [int]$AttemptTimeoutSeconds = 90,
    [int]$WorkerIndex = -1,
    [long]$WorkerStart = -1,
    [long]$WorkerEnd = -1,
    [long]$WorkerExpected = -1
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$partDir = Join-Path $root "swift-parts"
$final = Join-Path $root "swift-6.4.0-windows10-installer.exe"
New-Item -ItemType Directory -Path $partDir -Force | Out-Null

function Get-PartSize([string]$path) {
    if (Test-Path $path) { return (Get-Item $path).Length }
    return 0
}

function Invoke-Worker {
    param([int]$Index, [long]$Start, [long]$End, [long]$Expected)

    $part = Join-Path $partDir ("part_{0:D2}.bin" -f $Index)
    $tmp = "$part.tmp"
    $attempts = 0
    $stalled = 0

    # Direct and proxied traffic leave through different paths here, so
    # alternating them lets both routes carry data at the same time.
    $transports = @($Proxy)
    if ($AlternateProxy -ne "" -and $AlternateProxy -ne $Proxy) { $transports += $AlternateProxy }

    while ((Get-PartSize $part) -lt $Expected) {
        $attempts++
        if ($attempts -gt $MaxAttempts) { exit 3 }

        $have = Get-PartSize $part
        $from = $Start + $have
        if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force }

        $transport = $transports[($attempts - 1) % $transports.Count]
        $arguments = @(
            "-sS",
            "--max-time", "$AttemptTimeoutSeconds"
        )
        # "direct" is a sentinel: an empty string would be swallowed when the
        # worker is relaunched through Start-Process -ArgumentList.
        if ($transport -ne "direct") { $arguments += @("--proxy", $transport) }
        $arguments += @(
            "--range", "$from-$End",
            "--output", $tmp,
            $Url
        )
        Start-Process -FilePath "curl.exe" -ArgumentList $arguments -Wait -WindowStyle Hidden

        $got = Get-PartSize $tmp
        if ($got -gt 0) {
            $destination = [System.IO.File]::Open($part, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write)
            try {
                $source = [System.IO.File]::OpenRead($tmp)
                try { $source.CopyTo($destination) } finally { $source.Dispose() }
            } finally {
                $destination.Dispose()
            }
        } else {
            $stalled++
            Start-Sleep -Seconds 3
        }
        if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force }
    }

    $size = Get-PartSize $part
    if ($size -ne $Expected) { exit 4 }
    exit 0
}

if ($WorkerIndex -ge 0) {
    Invoke-Worker -Index $WorkerIndex -Start $WorkerStart -End $WorkerEnd -Expected $WorkerExpected
    exit $LASTEXITCODE
}

$head = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 30
$total = [int64]$head.Headers.'Content-Length'[0]
$chunk = [math]::Ceiling($total / $Connections)
Write-Output "total=$([math]::Round($total/1MB,1))MB parts=$Connections chunk=$([math]::Round($chunk/1MB,1))MB"

$self = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$workers = @()
$plan = @()

for ($i = 0; $i -lt $Connections; $i++) {
    $start = [int64]$i * $chunk
    if ($start -ge $total) { break }
    $end = [math]::Min($start + $chunk - 1, $total - 1)
    $expected = $end - $start + 1
    $part = Join-Path $partDir ("part_{0:D2}.bin" -f $i)
    $plan += [pscustomobject]@{ Index = $i; Start = $start; End = $end; Expected = $expected }

    if ((Get-PartSize $part) -eq $expected) { continue }

    $arguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $PSCommandPath,
        "-Connections", $Connections,
        "-Proxy", $Proxy,
        "-Url", $Url,
        "-ExpectedSha256", $ExpectedSha256,
        "-AlternateProxy", $AlternateProxy,
        "-MaxAttempts", $MaxAttempts,
        "-AttemptTimeoutSeconds", $AttemptTimeoutSeconds,
        "-WorkerIndex", $i,
        "-WorkerStart", $start,
        "-WorkerEnd", $end,
        "-WorkerExpected", $expected
    )
    $workers += Start-Process -FilePath $self -ArgumentList $arguments -PassThru -WindowStyle Hidden
}

if ($workers.Count -gt 0) {
    Write-Output "started $($workers.Count) worker(s); waiting ..."
    $workers | Wait-Process -Timeout 10800 -ErrorAction SilentlyContinue
} else {
    Write-Output "all parts already complete"
}

$assembled = 0
foreach ($entry in $plan) {
    $part = Join-Path $partDir ("part_{0:D2}.bin" -f $entry.Index)
    $size = Get-PartSize $part
    if ($size -ne $entry.Expected) {
        throw "part $($entry.Index) incomplete: $size / $($entry.Expected) bytes - re-run to resume"
    }
    $assembled += $size
}
if ($assembled -ne $total) { throw "size mismatch: $assembled vs $total" }

if (Test-Path $final) { Remove-Item -LiteralPath $final -Force }
$out = [System.IO.File]::Create($final)
try {
    foreach ($entry in $plan) {
        $part = Join-Path $partDir ("part_{0:D2}.bin" -f $entry.Index)
        $input = [System.IO.File]::OpenRead($part)
        try { $input.CopyTo($out) } finally { $input.Dispose() }
    }
} finally {
    $out.Dispose()
}

$hash = (Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "assembled=$([math]::Round((Get-Item $final).Length/1MB,1))MB"
Write-Output "sha256=$hash"
if ($hash -ne $ExpectedSha256.ToLowerInvariant()) {
    Write-Output "HASH MISMATCH - expected $ExpectedSha256"
    exit 1
}
Write-Output "HASH OK"
