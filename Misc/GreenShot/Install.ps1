# https://githubusercontent.com/BronsonMagnan/SoftwareUpdate/master/Greenshot.ps1
function Get-GreenShotURL {
    [cmdletbinding()]
    [outputtype([string])]
    $GreenshotURL="http://getgreenshot.org/downloads/"
    $raw = (wget -UseBasicParsing -Uri $GreenshotURL).content
    #we are looking for the github download
    $pattern = "https:\/\/github\.com.+\.exe"
    #split into lines, then split into tags, #$%^ is arbitrary
    $multiline = $raw.split("`n").trim().replace("<","#$%^<").split("#$%^")
    #find the html tag containing the github url
    $urlline = ($multiline | select-string -Pattern $pattern).tostring().trim()
    #url line now looks like this
    #<a href="https://github.com/greenshot/greenshot/releases/download/Greenshot-RELEASE-1.2.10.6/Greenshot-INSTALLER-1.2.10.6-RELEASE.exe">
    #strip out the html tags
    $greenshotURL = $urlline.replace('<a href="','').replace('">','')
    Write-Output $GreenshotURL    
}

function Get-GreenShotVersion {
    [cmdletbinding()]
    [outputtype([Version])]
    $GreenshotURL = Get-GreenShotURL
    $versionPattern = "\d+\.\d+\.\d+\.\d+"
    #get the URL and split it on the forward slash, then look for the version pattern
    $productTitle=($GreenshotURL.split("/") | select-string -Pattern $versionPattern | Select-Object -First 1).tostring().trim()
    #there will be two because they put the version in the EXE and also in the path as a subfolder.
    $GreenshotVersion = [VERSION]::new(($productTitle.split('-') | select-string -Pattern $versionPattern | Select-Object -First 1).tostring().trim())
    write-output $GreenshotVersion
}

#usage 
Get-GreenShotURL
Get-GreenShotVersion

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
$Product = "GreenShot"
$PackageName = "GreenShot"
$Version = "$(Get-GreenShotVersion)"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/VERYSILENT /SUPPRESSMESSAGEBOXES /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /NORESTART'
$ProgressPreference = 'SilentlyContinue'
$URL = "$(Get-GreenShotURL)"

Start-Transcript $LogPS

if ( -Not (Test-Path -Path $Version ) ) {
    New-Item -ItemType directory -Path $Version
}

CD $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    Invoke-WebRequest -Uri $url -OutFile $Source
         }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
         }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
if (Get-Process 'Greenshot' -ea SilentlyContinue) {Stop-Process -processname Greenshot}
.\GreenShot.exe /VERYSILENT /NORESTART
Start-Sleep -s 60
get-process iexplore | stop-process

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
