Clear-Host

Set-ExecutionPolicy Bypass -Force
$env:SEE_MASK_NOZONECHECKS = 1

Write-Verbose "Installing Required PowerShell Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) { Install-PackageProvider -Name 'Nuget' -Force }
if (!(Get-Module -ListAvailable -Name Evergreen)) { Install-Module Evergreen -Force | Import-Module Evergreen }
if (!(Get-Module -ListAvailable -Name FSLogix.PowerShell.Rules)) { Install-Module FSLogix.PowerShell.Rules -Force | Import-Module FSLogix.PowerShell.Rules }
if (!(Get-Module -ListAvailable -Name IntuneWin32App)) {Install-Module IntuneWin32App -Force | Import-Module IntuneWin32App}
if (!(Get-Module -ListAvailable -Name powershell-yaml)) {Install-Module powershell-yaml -Force | Import-Module powershell-yaml}

.\Install-RSATv1809v1903v1909v2004v20H2 -Basic -DisableWSUS
