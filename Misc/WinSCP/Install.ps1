# https://github.com/UNT-CAS/SourceForge-API
# Requires -Version 5.0
class SourceForge {
    [string]        $Project = $Null
    [PSCustomObject]$LatestRelease = $Null

    
    SourceForge([string] $project) {
        $this.Project = $project
        $this.GetLatestRelease()
    }

    
    [void] GetLatestRelease() {
        $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $this.GetLatestRelease('https://sourceforge.net/projects/{0}/best_release.json')
        
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
    }


    [void] GetLatestRelease([string] $url) {
        $url = $url -f @($this.Project)
        Write-Debug "[SourceForge].GetLatestRelease URL: ${url}"
        $this.LatestRelease = ConvertFrom-Json (Invoke-WebRequest $url -UseBasicParsing).Content
    }

    
    [string] LatestVersion() {
        if (-not $this.LatestRelease) {
            $this.GetLatestRelease()
        }

        return $this.LatestRelease.release.filename.Split('/')[2]
    }

    [hashtable] LatestHash() {
        if (-not $this.LatestRelease) {
            $this.GetLatestRelease()
        }

        return @{
            'Algorithm' = 'MD5';
            'Hash' = $this.LatestRelease.release.md5sum.ToUpper();
        }
    }
}

$WinSCP = [SourceForge]::new('WinSCP')
$WinSCP.LatestVersion()

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
$Product = "WinSCP"
$PackageName = "WinSCP"
$Version = "$($WinSCP.LatestVersion())"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
$url = "https://ufpr.dl.sourceforge.net/project/winscp/WinSCP/$Version/WinSCP-$Version-Setup.exe"
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

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
