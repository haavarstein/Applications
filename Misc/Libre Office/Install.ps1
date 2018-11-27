Function Get-LibreOfficeVersion {
    [CmdletBinding()]
    [OutputType([version])]
    Param (
        [ValidateSet("Latest", "Business")]
        [string] $Release = "Latest"
    )

    $url = "https://www.libreoffice.org/download/download/"

    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to Libre Office URL: $url with error $_."
    }
    finally {
        # Search for their big green logo version number '<span class="dl_version_number">*</span>'
        $content = $response.Content
        $spans = $content.Replace('<span', '#$%^<span').Replace('</span>', '</span>#$%^').Split('#$%^') | `
            Where-Object { $_ -like '<span class="dl_version_number">*</span>' }
        $verBlock = ($spans).Replace('<span class="dl_version_number">', '').Replace('</span>', '')

        If ($Release -eq "Latest") {
            $version = [version]::new($($verblock | Select-Object -First 1))
        }
        Else {
            $version = [version]::new($($verblock | Select-Object -Last 1))
        }

        Write-Output $version
    }
}

Function Get-LibreOfficeUri {
    <#
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [ValidateSet("Latest", "Business")]
        [string] $Release = "Latest"
    )

    # Get current version number using Get-LibreOfficeVersion
    $currentVersion = Get-LibreOfficeVersion -Release $Release

    $rootUrl = "https://download.documentfoundation.org/libreoffice/stable/"
    $downloadURL = "$rootUrl$($CurrentVersion.ToString())/win/x86_64/LibreOffice_$($CurrentVersion.tostring())_Win_x64.msi"

    Write-Output $downloadURL
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

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Misc"
$Product = "Libre Office"
$PackageName = "LibreOffice_Win_x64"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$Version = "$(Get-LibreOfficeVersion)"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
$url = "$(Get-LibreOfficeUri)"

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
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
