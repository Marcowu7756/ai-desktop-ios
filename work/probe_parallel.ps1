# Measures aggregate download throughput from download.swift.org for a given
# number of parallel ranged connections. Read-only: writes only into work/.
param(
    [int]$Connections = 4,
    [int]$Seconds = 20,
    [string]$Proxy = "",
    [int]$StartOffsetMB = 0,
    [string]$Url = "https://download.swift.org/swift-6.4.0-release/windows10/swift-6.4.0-RELEASE/swift-6.4.0-RELEASE-windows10.exe"
)

$ErrorActionPreference = "Stop"
$work = Join-Path $PSScriptRoot "probe"
if (Test-Path $work) { Remove-Item -LiteralPath $work -Recurse -Force }
New-Item -ItemType Directory -Path $work -Force | Out-Null

$chunkBytes = 40MB
$processes = @()
$base = [int64]$StartOffsetMB * 1MB

for ($i = 0; $i -lt $Connections; $i++) {
    $start = $base + ($i * $chunkBytes)
    $end = $start + $chunkBytes - 1
    $out = Join-Path $work "probe_$i.bin"
    $arguments = @(
        "-sS",
        "--max-time", "$Seconds",
        "--range", "$start-$end",
        "--output", $out,
        $Url
    )
    if ($Proxy -ne "") {
        $arguments = @("-sS", "--max-time", "$Seconds", "--proxy", $Proxy, "--range", "$start-$end", "--output", $out, $Url)
    }
    $processes += Start-Process -FilePath "curl.exe" -ArgumentList $arguments -PassThru -WindowStyle Hidden
}

# curl exits by itself via --max-time; allow a little scheduling slack.
$processes | Wait-Process -Timeout ($Seconds + 20) -ErrorAction SilentlyContinue

$totalBytes = 0
for ($i = 0; $i -lt $Connections; $i++) {
    $file = Join-Path $work "probe_$i.bin"
    if (Test-Path $file) { $totalBytes += (Get-Item $file).Length }
}

$mb = [math]::Round($totalBytes / 1MB, 1)
$rate = [math]::Round($totalBytes / 1MB / $Seconds, 3)
$label = if ($Proxy -ne "") { "proxy=$Proxy" } else { "proxy=direct" }
Write-Output "connections=$Connections  $label  offset=${StartOffsetMB}MB  bytes=$totalBytes  MB=$mb  rate=$rate MB/s"
