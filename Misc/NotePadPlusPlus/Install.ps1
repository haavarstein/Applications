# https://github.com/BronsonMagnan/SoftwareUpdate/blob/master/NotePadPlusPlus.ps1

function get-NPPCurrentVersion {
    [cmdletbinding()]
    [outputtype([version])]
    $url = "https://notepad-plus-plus.org/"
    $content = wget -Uri $url
    #pipe this match to out-null so it does not corrupt the pipeline
    ($content.allelements | ? id -eq "download").innerText -match "\d+\.\d+\.\d+" | out-null
    $ver = [version]::new($Matches[0])
    Write-Output $ver
}

function get-NPPCurrentDownloadURL {
    [cmdletbinding()]
    [outputtype([string])]
    param (
        [validateSet("x86","x64")][string]$Architecture = "x64"
    )
    $version = get-NPPCurrentVersion
    if ("x86" -eq $Architecture) { $archcode = "" } else { $archcode = ".x64" }
    $url = "https://notepad-plus-plus.org/repository/$($version.major).x/$version/npp.$($version).Installer$($archcode).exe"
    Write-Output $url
}

#Example get-NPPCurrentDownloadURL -Architecture x64
#Example wget -uri (get-NPPCurrentDownloadURL) -OutFile .\npp.exe

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

$Vendor = "Misc"
$Product = "NotePadPlusPlus"
$PackageName = "NotePadPlusPlus_x64"
$Version = "$(get-NPPCurrentVersion)"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$url = "$(get-NPPCurrentDownloadURL -Architecture x64)"
$UnattendedArgs = '/S'

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

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
