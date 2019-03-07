function Get-ODTUri {
    <#
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
            Modified by: Marco Hofmann
            Twitter: @xenadmin
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    $url = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to ODT: $url with error $_."
        Break
    }
    finally {
        $ODTUri = $response.links | Where-Object {$_.outerHTML -like "*click here to download manually*"}
        Write-Output $ODTUri.href
    }
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

$Vendor = "Microsoft"
$Product = "Office 365 x32"
$PackageName = "setup"
$InstallerType = "exe"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/configure RDSH.xml'
$UnattendedArgs2 = '/download RDSH.xml'
$URL = $(Get-ODTUri)
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS | Out-Null

Write-Verbose "Checking Internet Connection" -Verbose
 
If (!(Test-Connection -ComputerName www.google.com -Count 1 -quiet)) {
    Write-Verbose "Internet Connection is Down" -Verbose
    }
    Else {
    Write-Verbose "Internet Connection is Up" -Verbose
    }

Write-Verbose "Downloading Latest Version of Office 365 Deployment Tool (ODT)" -Verbose
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile .\officedeploymenttool.exe
$Version = (Get-Command .\officedeploymenttool.exe).FileVersionInfo.FileVersion

Write-Verbose "Writing Version Number to File" -Verbose
if (!$Version) {
    $Version = Get-Content -Path ".\Version.txt"
    }
    Else {
    $Version | Out-File -FilePath ".\Version.txt" -Force
    }

if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version | Out-Null
    Copy-item .\RDSH.xml -Destination $Version -Force
    $Dir = Get-Location
    $Path = "$Dir" + "\$Version"
    .\officedeploymenttool.exe /quiet /extract:.\$Version
    $Version | Out-File -FilePath ".\Version.txt" -Force
    start-sleep -s 5
}

CD $Version

If (!(Test-Path -Path $PSScriptRoot\$Version\Office\Data\v32.cab)) {
    Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
    (Start-Process "Setup.exe" -ArgumentList $unattendedArgs2 -Wait -Passthru).ExitCode
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
Stop-Transcript | Out-Null
