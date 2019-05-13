# Get latest version and download latest Open Shell release via GitHub API

# GitHub API to query repository
$repo = "git-for-windows/git"
$releases = "https://api.github.com/repos/Open-Shell/Open-Shell-Menu/releases/latest"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$r = Invoke-WebRequest -Uri $releases -UseBasicParsing
$latestRelease = ($r.Content | ConvertFrom-Json | Where-Object { $_.prerelease -eq $False })[0]
$latestVersion = $latestRelease.tag_name

# Array of releases and downloaded
$releases = $latestRelease.assets | Where-Object { $_.name -like "OpenShell*" } | `
    Select-Object name, browser_download_url

# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Misc"
$Product = "Open Shell"
$PackageName = "OpenShellSetup"
$Version = $Version = $latestVersion.Trim(".windows.1 , v")
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\OpenShell.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$url = $releases.browser_download_url | Select-Object -first 1
$UnattendedArgs = "/i ""$Source"" ALLUSERS=1 /qn"

Start-Transcript $LogPS | Out-Null

if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version | Out-Null
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
.\OpenShellSetup.exe extract64
Start-Sleep -s 3
$Source = Get-ChildItem *.msi
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript | Out-Null
