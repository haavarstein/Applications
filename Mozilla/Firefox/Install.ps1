function get-LatestFirefoxESRURL {
[cmdletbinding()]
[outputtype([String])]
param(
    [ValidateSet("bn-BD","bn-IN","en-CA","en-GB","en-ZA","es-AR","es-CL","es-ES","es-MX")][string]$culture = "en-US",
    [ValidateSet("win32","win64")][string]$architecture="win64"

)

# JSON that provide details on Firefox versions
$uriSource = "https://product-details.mozilla.org/1.0/firefox_versions.json"

# Read the JSON and convert to a PowerShell object
$firefoxVersions = (Invoke-WebRequest -uri $uriSource).Content | ConvertFrom-Json

$VersionURL = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$($firefoxVersions.FIREFOX_ESR)/$($architecture)/$($culture)/Firefox%20Setup%20$($firefoxVersions.FIREFOX_ESR).exe"
Write-Output $VersionURL
}

function get-LatestFirefoxESRVersion {
[cmdletbinding()]
[outputtype([String])]
param(
    [ValidateSet("bn-BD","bn-IN","en-CA","en-GB","en-ZA","es-AR","es-CL","es-ES","es-MX")][string]$culture = "en-US",
    [ValidateSet("win32","win64")][string]$architecture="win64"

)

# JSON that provide details on Firefox versions
$uriSource = "https://product-details.mozilla.org/1.0/firefox_versions.json"

# Read the JSON and convert to a PowerShell object
$firefoxVersions = (Invoke-WebRequest -uri $uriSource).Content | ConvertFrom-Json

$Version = [Version]$firefoxVersions.FIREFOX_ESR.replace("esr","")
Write-Output $Version
}

get-LatestFirefoxESRURL
get-LatestFirefoxESRVersion

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

$Vendor = "Mozilla"
$Product = "FireFox"
$Version = "$(get-LatestFirefoxESRVersion)"
$PackageName = "Firefox"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/SILENT MaintenanceService=false'
$url = "$(get-LatestFirefoxESRURL)"
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

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
