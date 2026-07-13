$ErrorActionPreference = 'Stop'

$packageName = 'minimalclock'
# These __TOKEN__ placeholders are substituted automatically by
# .github/workflows/publish-choco.yml at pack time. For a manual/local pack,
# replace them by hand: version must match a GitHub release tagged "v$version"
# with MinimalClock-x64.exe / MinimalClock-arm64.exe assets (produced by
# .github/workflows/build-windows.yml), and the checksums come from
#   (Get-FileHash MinimalClock-x64.exe -Algorithm SHA256).Hash
$version       = '__VERSION__'
$checksumX64   = '__CHECKSUM_X64__'
$checksumArm64 = '__CHECKSUM_ARM64__'

$releaseTag  = "v$version"
$baseUrl     = "https://github.com/ImJustIvaan/Minimal-Clock-Desktop/releases/download/$releaseTag"

$isArm64 = $env:PROCESSOR_ARCHITECTURE -eq 'ARM64'

if ($isArm64) {
  $url      = "$baseUrl/MinimalClock-arm64.exe"
  $checksum = $checksumArm64
} else {
  $url      = "$baseUrl/MinimalClock-x64.exe"
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
