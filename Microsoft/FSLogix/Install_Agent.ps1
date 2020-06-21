# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 http://xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode
# Example 5 MSI with Space in the file name we need to use double quotes
# $UnattendedArgs = "/i `"$PackageName.$InstallerType`" ALLUSERS=1 /qn /liewa `"$LogApp`""

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Write-Verbose "Installing Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}
Update-Module Evergreen

$Vendor = "Microsoft"
$Product = "FSLogix Apps"
$PackageName = "FSLogixAppsSetup"
$Evergreen = Get-MicrosoftFSLogixApps
$Version = $Evergreen.Version
$URL = $Evergreen.uri
$DownloadType = "zip"
$InstallerType = "exe"
$Source1 = "$PackageName" + "." + "$DownloadType"
$Source2 = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$ProgressPreference = 'SilentlyContinue'
$UnattendedArgs = '/S'

Start-Transcript $LogPS | Out-Null
 
If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null
    Copy-Item .\WSearch.xml -Destination .\$Version
}

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source1)) {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile "$PSScriptRoot\$Version\$Source1"
    Expand-Archive -Path "$PSScriptRoot\$Version\$PackageName.$DownloadType" -DestinationPath "$PSScriptRoot\$Version"
}

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PSScriptRoot\$Version\x64\Release\$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Register-ScheduledTask -Xml (Get-Content WSearch.xml | Out-String) -TaskName "Reset Windows Search at Logoff" -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
