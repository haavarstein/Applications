# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
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
# https://www.christiaanbrinkhoff.com/2020/03/22/windows-virtual-desktop-technical-walkthrough-including-other-unknown-secrets-you-did-not-know-about-the-new-microsoft-managed-azure-service/

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Write-Verbose "Installing Modules" -Verbose
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}
Update-Module Evergreen

$Vendor = "Microsoft"
$Product = "Virtual Desktop Boot Loader"
$PackageName = "RDInfra_RDAgentBootLoader_Installer_x64"
$Version = "1.0.0.0"
$URL = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH?ranMID=24542&ranEAID=je6NUbpObpQ&ranSiteID=je6NUbpObpQ-sSuccZvhED4Nxw5lDWKa8g&epi=je6NUbpObpQ-sSuccZvhED4Nxw5lDWKa8g&irgwc=1&OCID=AID2000142_aff_7593_1243925&tduid=%28ir__uldfun9kl9kfthdhkk0sohzjx32xnj1d0medbvat00%29%287593%29%281243925%29%28je6NUbpObpQ-sSuccZvhED4Nxw5lDWKa8g%29%28%29&irclickid=_uldfun9kl9kfthdhkk0sohzjx32xnj1d0medbvat00"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UnattendedArgs = "/i `"$PackageName.$InstallerType`" /quiet /qn /norestart /passive /liewa `"$LogApp`""

Start-Transcript $LogPS | Out-Null
 
If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null}
 
CD $Version
 
Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source}
        
Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
