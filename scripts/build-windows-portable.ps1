# Builds Oxy Capture for Windows (release) and packages the Release folder
# into a portable ZIP. Must be run on Windows with Flutter + VS 2022 installed.
#
# Usage (from repo root):
#   .\scripts\build-windows-portable.ps1

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSPlatform -and $PSVersionTable.PSPlatform -ne 'Win') {
    Write-Error 'This script must be run on Windows.'
}

$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
$AppDir = Join-Path $Root 'app'
$PubspecPath = Join-Path $AppDir 'pubspec.yaml'
$ReleaseDir = Join-Path $AppDir 'build\windows\x64\runner\Release'
$DistDir = Join-Path $Root 'dist'

if (-not (Test-Path $PubspecPath)) {
    Write-Error "pubspec.yaml not found: $PubspecPath"
}

$versionLine = Select-String -Path $PubspecPath -Pattern '^version:\s*(.+)$' |
    Select-Object -First 1
if (-not $versionLine) {
    Write-Error "Could not read version from $PubspecPath"
}

$rawVersion = $versionLine.Matches.Groups[1].Value.Trim()
$Version = ($rawVersion -split '\+')[0]

Write-Host 'Building Oxy Capture (Windows release)...'
Push-Location $AppDir
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $buildArgs = @('build', 'windows', '--release')
    if ($env:CI -eq 'true') {
        $buildArgs += '-v'
    }
    & flutter @buildArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

$ExePath = Join-Path $ReleaseDir 'oxy_capture.exe'
if (-not (Test-Path $ExePath)) {
    Write-Error "Build output not found: $ExePath"
}

$ZipName = "OxyCapture-$Version-windows-x64.zip"
$ZipPath = Join-Path $DistDir $ZipName

New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Write-Host 'Packaging portable ZIP...'
Push-Location $ReleaseDir
try {
    Compress-Archive -Path * -DestinationPath $ZipPath -Force
}
finally {
    Pop-Location
}

if (-not (Test-Path $ZipPath)) {
    Write-Error "ZIP was not created: $ZipPath"
}

Write-Host ''
Write-Host 'Built successfully:'
Write-Host "  $ZipPath"
Write-Host ''
Write-Host 'To install (portable):'
Write-Host '  1. Extract the ZIP to a folder (e.g. C:\Apps\OxyCapture\)'
Write-Host '  2. Run oxy_capture.exe from that folder'
Write-Host ''
Write-Host 'Note: Keep all DLLs and the data\ folder next to oxy_capture.exe.'
