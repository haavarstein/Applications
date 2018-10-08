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
$PackageName = "setup-BIS-F-6.1.0_build01.101"
$Version = "6.1.0.01.101"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "zip"
$SourceXML = "$PackageName" + "." + "zip"
$SourceCTX = "CitrixOptimizer.zip"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/VERYSILENT /log:$LogApp /norestart /noicons"
$url = "http://loginmarketing.blob.core.windows.net/public/tools/setup-BIS-F-6.1.0_build01.101.exe.zip"
$xml = "https://eucweb.com/download/765/"
$ctx = "http://xenapptraining.s3.amazonaws.com/Hydration/CitrixOptimizer.zip"
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
    Expand-Archive -Path $Source -DestinationPath .\
    Remove-Item -Path $Source
    Write-Verbose "Downloading $Vendor $Product Reference Configuration" -Verbose
    Invoke-WebRequest -Uri $xml -OutFile $SourceXML
    Expand-Archive -Path $SourceXML -DestinationPath .\
    Remove-Item -Path $SourceXML
    Write-Verbose "Downloading Citrix Optimizer" -Verbose
    Invoke-WebRequest -Uri $ctx -OutFile $SourceCTX
    Expand-Archive -Path $SourceCTX -DestinationPath .\Tools\
    Remove-Item -Path $SourceCTX
         }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
         }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
Copy-Item -Path .\Tools\* -Destination $env:SystemRoot\System32 -Recurse -Force
Copy-item -Path .\*.xml -Destination "C:\Program Files (x86)\Base Image Script Framework (BIS-F)" -Recurse -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript 
