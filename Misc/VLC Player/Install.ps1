Function Get-VideoLanVlcPlayer {
    <#
        .SYNOPSIS
            Get the current version and download URL for VideoLAN VLC Media Player.
        .NOTES
            Site: https://stealthpuppy.com
            Author: Aaron Parker
            Twitter: @stealthpuppy
        
        .LINK
            https://github.com/aaronparker/Get.Software
        .EXAMPLE
            Get-VideoLanVlcPlayer
            Description:
            Returns the current version and download URLs for VLC Media Player on Windows (x86, x64) and macOS.
    #>
    [CmdletBinding()]
    Param()

    # Get VLC Player versions and URLs from private functions
    $Win32 = Get-VlcPlayerUpdateWin -Platform Win32
    $Win64 = Get-VlcPlayerUpdateWin -Platform Win64
    
    # Return output object to the pipeline
    Write-Output $Win32, $Win64, $macOS
}

Function Get-VlcPlayerUpdateWin {
    <#
        .SYNOPSIS
            Queries the VLC Player for Windows update site and returns the version number and download URL.
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet('Win32', 'Win64')]
        [string] $Platform = 'Win64'
    )

    # Platform URLs
    $platforms = [PSCustomObject]@{
        Win32 = 'https://update.videolan.org/vlc/status-win-x86'
        Win64 = 'https://update.videolan.org/vlc/status-win-x64'
    }

    # RegEx to match version numbers
    # $versionRegEx = "\d+\.\d+\.\d+"

    # Query the VLC Player update site
    $r = Invoke-WebRequest -Uri $platforms.$Platform
    $lines = $r.RawContent -Split "`n"

    # Construct the output
    $output = [PSCustomObject]@{
        Platform = $Platform
        Version  = $lines[11]
        URI      = $lines[12]
    }

    # Return the custom object to the pipeline
    Write-Output $output
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
$Product = "VLC Player"
$PackageName = "VLCPlayer"
$Latest = Get-VlcPlayerUpdateWin -Platform Win64
$Version = $latest.Version
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/Verysilent /Norun"
$url = $latest.uri
$ProgressPreference = 'SilentlyContinue'

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
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript | Out-Null
