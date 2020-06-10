Clear-Host
Write-Verbose "Settings Arugments"
$StartDTM = (Get-Date)

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {Install-Module PSWindowsUpdate -Scope CurrentUser -Force | Import-Module PSWindowsUpdate}

Write-Verbose "Checking if the Windows Update Service is Running" -Verbose
$ServiceName = 'wuauserv'
Set-Service -Name $ServiceName -Startup Automatic
Start-Service -Name $ServiceName

Write-Verbose "Gettings Available Updates from Microsoft" -Verbos
Get-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -ComputerName localhost | Out-File C:\PSWindowsUpdate.log -Append

Write-Verbose "Installing Available Updates from Microsoft" -Verbose
Get-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -ComputerName localhost -Install -AcceptAll -IgnoreReboot | Out-File C:\PSWindowsUpdate.log -Append

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
