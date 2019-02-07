Function Get-uberAgentVersion {
    
    <#
        .NOTES
            Author: Trond Eirik Haavarstein
            Twitter: @xenappblog
    #>
    
    
    $url = "https://uberagent.com/downloads/uberAgent/current/uberAgent-current.txt"

    try {
        $temp = New-TemporaryFile
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $temp -ErrorAction SilentlyContinue
        $file = get-content $temp
        $f1 = $file.trimstart("uberAgent-")
        $Version = $f1.TrimEnd(".zip")
        Write-Output $Version
    }
    catch {
        Throw "Failed to connect to URL: $url with error $_."
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

$Vendor = "Misc"
$Product = "uberAgent x64"
$PackageName = "uberAgent-64"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "zip"
$Version = "$(Get-uberAgentVersion)"
$LogPS = "C:\Windows\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "C:\Windows\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 SERVERS=SPL-01:19500 /qn /liewa $LogApp"
$URL = "https://uberagent.com/downloads/uberAgent/current/uberAgent-$Version.zip"
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
    Expand-Archive -Path $Source -DestinationPath .
         }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
         }

CD "uberAgent components\uberAgent_endpoint\bin"

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
