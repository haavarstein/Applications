# Get latest version and download latest ShareX release via GitHub API

# GitHub API to query repository
$repo = "Sumatrapdfreader/sumatrapdf"
$releases = "https://api.github.com/repos/$repo/releases/latest"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$r = Invoke-WebRequest -Uri $releases -UseBasicParsing
$latestRelease = ($r.Content | ConvertFrom-Json | Where-Object { $_.prerelease -eq $False })[0]
$latestVersion = $latestRelease.tag_name

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

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Misc"
$Product = "SumatraPDF"
$PackageName = "SumatraPDF"
$Version = $Version = $latestVersion.Trim(".windows.1 , v")
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/S"
$url = "https://kjkpubsf.sfo2.digitaloceanspaces.com/software/sumatrapdf/rel/SumatraPDF-$Version-64-install.exe"
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Start-Transcript $LogPS | Out-Null
 
If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null}
 
CD $Version
 
Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source}

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript | Out-Null
