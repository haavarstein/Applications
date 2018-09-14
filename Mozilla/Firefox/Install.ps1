# Get Lastest FireFox URL by Bronson Magnan
function get-LatestFirefoxURL {
[cmdletbinding()]
[outputtype([String])]
param(
    [ValidateSet("bn-BD","bn-IN","en-CA","en-GB","en-ZA","es-AR","es-CL","es-ES","es-MX")][string]$culture = "en-US",
    [ValidateSet("win32","win64")][string]$architecture="win64"
)

$FFReleaseNoticeURL = "https://www.mozilla.org/en-US/firefox/releases/"
$FFLatestVersion = ((wget -uri $FFReleaseNoticeURL | % content).split() | Select-String -Pattern 'data-latest-firefox="*"').tostring().split('"')[1]
$VersionURL = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$($FFLatestVersion)/$($architecture)/$($culture)/Firefox%20Setup%20$($FFLatestVersion).exe"
Write-Output $VersionURL
}

# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 

# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru

# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination

# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$FFReleaseNoticeURL = "https://www.mozilla.org/en-US/firefox/releases/"
$FFLatestVersion = ((wget -uri $FFReleaseNoticeURL | % content).split() | Select-String -Pattern 'data-latest-firefox="*"').tostring().split('"')[1]
$url = get-LatestFirefoxURL

$Vendor = "Mozilla"
$Product = "FireFox"
$Version = "$FFLatestVersion"
$PackageName = "Firefox"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/SILENT MaintenanceService=false'
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version
}

CD $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -Uri $url -OutFile $Source
         }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
         }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
sc.exe config MozillaMaintenance start= disabled
cd..
cd Config
copy-item -Path * -Destination "C:\Program Files\Mozilla Firefox" -Recurse -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
