Function Get-VMWareToolsVersion {
    <#
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
    #>
    [CmdletBinding()]
    [OutputType([Version])]
    Param()

    $vmwareTools = "https://packages.vmware.com/tools/esx/latest/windows/x64/index.html"
    $pattern = "[0-9]+\.[0-9]+\.[0-9]+\-[0-9]+\-x86_64"

    #get the raw page content
    $pageContent=(wget -UseBasicParsing -Uri $vmwareTools).content

    #change one big string into many strings, then find only the line with the version number
    $interestingLine = ($pageContent.split("`n") | Select-string -Pattern $pattern).tostring().trim()

    #remove the whitespace and split on the assignment operator, then split on the double quote and select the correct item
    $filename = (($interestingLine.Replace(" ","").Split("=") | Select-string -Pattern $pattern).ToString().Trim().Split("`""))[1]

    #file name is in the format "VMware-tools-10.2.1-8267844-x86_64.exe"
    #convert to a .NET version class, that can be used to compare against other version objects
    $version = [version]$filename.Replace("VMware-tools-","").Replace("-x86_64.exe","").Replace("-",".")

    #return the version object
    Write-Output $version
}

Function Get-VMWareToolsUri {
    <#
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param()

    $vmwareTools = "https://packages.vmware.com/tools/esx/latest/windows/x64/index.html"
    $pattern = "[0-9]+\.[0-9]+\.[0-9]+\-[0-9]+\-x86_64"

    #get the raw page content
    $pageContent=(wget -UseBasicParsing -Uri $vmwareTools).content

    #change one big string into many strings, then find only the line with the version number
    $interestingLine = ($pageContent.split("`n") | Select-string -Pattern $pattern).tostring().trim()

    #remove the whitespace and split on the assignment operator, then split on the double quote and select the correct item
    $filename = (($interestingLine.Replace(" ","").Split("=") | Select-string -Pattern $pattern).ToString().Trim().Split("`""))[1]

    $url = "https://packages.vmware.com/tools/esx/latest/windows/x64/$($filename)"
    Write-Output $url
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

$Vendor = "VMware"
$Product = "Tools"
$PackageName = "setup64"
$Version = "$(Get-VMWareToolsVersion)"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/S /v /qn REBOOT=R'
$URL = "$(Get-VMWareToolsUri)"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version
}

CD $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source
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

