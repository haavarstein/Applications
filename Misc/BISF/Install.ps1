# Get latest version and download latest BIS-F release via GitHub API
# URL Format : https://github.com/EUCweb/BIS-F/releases/download/6.1.2/setup-BIS-F-6.1.2_build01.109.exe

# GitHub API to query repository
$repo = "EUCweb/BIS-F"
$releases = "https://api.github.com/repos/$repo/releases/latest"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$r = Invoke-WebRequest -Uri $releases -UseBasicParsing
$latestRelease = ($r.Content | ConvertFrom-Json | Where-Object { $_.prerelease -eq $False })[0]
$latestVersion = $latestRelease.tag_name

# Array of releases and downloaded
$releases = $latestRelease.assets | Where-Object { $_.name -like "setup-BIS-F*" } | `
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
$Product = "BISF"
$PackageName = "setup-BIS-F"
$Version = $Version = $latestVersion.Trim(".windows.1 , v")
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$SourceXML = "$PackageName" + "." + "zip"
$SourceCTX = "CitrixOptimizer.zip"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/VERYSILENT /log:$LogApp /norestart /noicons"
$url = $releases.browser_download_url | Select-Object -first 1
$xml = "https://eucweb.com/download/765/"
$ctx = "http://xenapptraining.s3.amazonaws.com/Hydration/CitrixOptimizer.zip"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version | Out-Null
}

CD $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source
    Write-Verbose "Downloading $Vendor $Product Reference Configuration" -Verbose
    Invoke-WebRequest -Uri $xml -OutFile $SourceXML
    Expand-Archive -Path $SourceXML -DestinationPath .\
    Write-Verbose "Downloading Citrix Optimizer" -Verbose
    Invoke-WebRequest -Uri $ctx -OutFile $SourceCTX
    Expand-Archive -Path $SourceCTX -DestinationPath .\CitrixOptimizer
             }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
         }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
New-Item -ItemType directory -Path "C:\Program Files (x86)\Citrix Optimizer\" | Out-Null
Copy-Item -Path .\CitrixOptimizer\* -Destination "C:\Program Files (x86)\Citrix Optimizer\" -Recurse -Force
Copy-item -Path .\*.xml -Destination "C:\Program Files (x86)\Base Image Script Framework (BIS-F)" -Recurse -Force
CD..
Copy-Item -Path .\Tools\* -Destination $env:SystemRoot\System32 -Recurse -Force
Copy-Item BISF.reg -Destination C:\Windows\Temp\BISF.reg -Recurse
cmd.exe /c "regedit /s C:\Windows\Temp\BISF.reg"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript 
