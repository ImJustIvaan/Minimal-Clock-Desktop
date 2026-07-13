$ErrorActionPreference = 'Stop'

$packageName = 'minimalclock'
# Bump this alongside <version> in ../minimalclock.nuspec and tag the
# matching GitHub release as "v$version" with MinimalClockSetup-x64.exe /
# MinimalClockSetup-arm64.exe assets (produced by .github/workflows/build-windows.yml).
$version     = '1.0.0'
$releaseTag  = "v$version"
$baseUrl     = "https://github.com/ImJustIvaan/Minimal-Clock-Desktop/releases/download/$releaseTag"

# TODO: after publishing the GitHub release, replace these with the real
# SHA256 checksums, e.g. via:
#   (Get-FileHash MinimalClockSetup-x64.exe -Algorithm SHA256).Hash
$checksumX64   = 'REPLACE_WITH_X64_SHA256'
$checksumArm64 = 'REPLACE_WITH_ARM64_SHA256'

$isArm64 = $env:PROCESSOR_ARCHITECTURE -eq 'ARM64'

if ($isArm64) {
  $url      = "$baseUrl/MinimalClockSetup-arm64.exe"
  $checksum = $checksumArm64
} else {
  $url      = "$baseUrl/MinimalClockSetup-x64.exe"
  $checksum = $checksumX64
}

$packageArgs = @{
  packageName    = $packageName
  fileType       = 'exe'
  url            = $url
  checksum       = $checksum
  checksumType   = 'sha256'
  silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
