Clear-Host
Write-Verbose "Settings Arugments"
$StartDTM = (Get-Date)

Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {Install-Module PSWindowsUpdate -Force | Import-Module PSWindowsUpdate}
if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}

Update-Module -Name Evergreen -Force

Write-Verbose "Checking if the Windows Update Service is Running" -Verbose
$ServiceName = 'wuauserv'
Set-Service -Name $ServiceName -Startup Automatic
Start-Service -Name $ServiceName

Write-Verbose "Deleting FSLogix Rules" -Verbose
Remove-Item -Path "C:\Program Files\FSLogix\Apps\Rules\*.*" -Force -Recurse

Write-Verbose "Gettings Available Updates from Microsoft" -Verbose
Get-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -ComputerName localhost | Out-File C:\PSWindowsUpdate.log -Append

Write-Verbose "Installing Available Updates from Microsoft" -Verbose
Get-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -ComputerName localhost -Install -AcceptAll -IgnoreReboot | Out-File C:\PSWindowsUpdate.log -Append

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
