# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

# 64-bit Unified App Installer
# https://www.adobe.com/devnet-docs/acrobatetk/tools/VirtualizationGuide/singleinstaller.html

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Adobe"
$Product = "Acrobat DC (64-bit)"
$PackageName = "AcroPro"
$Version = "23.006.20360"
$InstallerType = "msi"
$MST = "AcroPro.mst"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType TRANSFORMS=$MST ALLUSERS=1 /qn /liewa $LogApp"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS | Out-Null

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Patching $Vendor $Product" -Verbose
$MSP = "AcrobatDCx64Upd2300620360.msp"
$UnattendedArgs1 = "/p $MSP /norestart /qn /liewa ${env:SystemRoot}\Temp\$MSP.log"
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs1 -Wait -Passthru).ExitCode

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript  | Out-Null
