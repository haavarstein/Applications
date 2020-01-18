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

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "XenDesktop"
$PackageName = "Controller"
$InstallerType = "exe"
$Version = $MyConfigFile.Settings.Citrix.Version
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $PackageName $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$UnattendedArgs = '/quiet /configure_firewall /COMPONENTS CONTROLLER,DESKTOPDIRECTOR /nosql /ignore_hw_check_failure /logpath $LogApp /noreboot'
$Destination = "$Version\x64\XenDesktop Setup\"

Start-Transcript $LogPS

CD $Destination
 
Write-Verbose "Starting Installation of $Vendor $Product $PackageName $Version" -Verbose
(Start-Process -FilePath "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
