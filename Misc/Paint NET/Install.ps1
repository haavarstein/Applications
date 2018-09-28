# https://github.com/BronsonMagnan/SoftwareUpdate/blob/master/PaintDotNet.ps1

Function Get-PaintDotNetURl {
    [cmdletbinding()]
    [outputType([string])]
    $sourceUrl = "https://www.dotpdn.com/downloads/pdn.html"
    $raw = (wget -UseBasicParsing -Uri $sourceUrl)
    $multiline = $raw.content.split("`n").trim()
    $justtags = $multiline.replace("<","#$%^<").split("#$%^")
    $pattern = "paint\.net\S*(\d+\.)+\d\S*\.(zip|exe)"
    #https://www.dotpdn.com/files/paint.net.4.1.1.install.zip
    $relativehtml = ($justtags | Select-String -Pattern $pattern | Select-Object -First 1).tostring().trim()
    $relativeURL = $relativehtml.replace('<a href="','').replace('">','')
    $dotdotreplacement = "https://www.dotpdn.com"
    $finalurl = $relativeURL.replace("..",$dotdotreplacement)
    Write-Output $finalurl
}

function Get-PaintDotNetVersion {
    [cmdletbinding()]
    [outputType([Version])]
    $downloadurl = Get-PaintDotNetURl
    $filename = ($downloadurl.split('/') | select-string -Pattern "(\d+\.)+\d+" | select-object -first 1).tostring().trim()
    $filename -match "(\d+\.)+\d+" | Out-Null
    $fileversion = [Version]::new($matches[0])
    Write-Output $fileversion
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

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Misc"
$Product = "Paint Net"
$PackageName = "PaintDotNet_x64"
$Version = "$(Get-PaintDotNetVersion)"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs='/auto'
$URL = "$(Get-PaintDotNetURl)"

Start-Transcript $LogPS

if ( -Not (Test-Path -Path $Version ) ) {
    New-Item -ItemType directory -Path $Version
    CD $Version
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    Invoke-WebRequest -Uri $url -OutFile "$PackageName.zip"
    Expand-Archive -Path "$PackageName.zip" -DestinationPath .
    Get-ChildItem *.exe | Rename-Item -NewName $Source
  }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
            CD $Version
         }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
