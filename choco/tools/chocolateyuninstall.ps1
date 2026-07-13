$ErrorActionPreference = 'Stop'

$packageName = 'minimalclock'
$softwareName = 'Minimal Clock'

$uninstallKey = Get-UninstallRegistryKey -SoftwareName $softwareName

if ($uninstallKey) {
  $uninstallKey | ForEach-Object {
    $uninstallString = "$($_.UninstallString) /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"

    $packageArgs = @{
      packageName    = $packageName
      fileType       = 'exe'
      silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'
      file           = $_.UninstallString -replace '"', ''
      validExitCodes = @(0)
    }

    Uninstall-ChocolateyPackage @packageArgs
  }
} else {
  Write-Warning "Could not find uninstall registry entry for '$softwareName'; it may already be uninstalled."
}
