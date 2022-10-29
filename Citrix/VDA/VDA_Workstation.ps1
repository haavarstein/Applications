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

$Vendor = "Citrix"
$Product = "VDA"
$PackageName = "VDAWorkstationSetup"
$InstallerType = "exe"
$Version = "2209"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $PackageName $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$UnattendedArgs = '/noreboot /noresume /quiet /components VDA /masterimage /xendesktopcloud /enable_remote_assistance /enable_hdx_ports /enable_hdx_udp_ports /enable_real_time_transport /virtualmachine /includeadditional "Citrix VDA Upgrade Agent" /logpath "C:\Windows\Temp"' # /controllers "'+$ListofDDCs+'"

$Destination = "$Version\"

Start-Transcript $LogPS

CD $Version

Write-Verbose "Starting Installation of $Vendor $Product $PackageName $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
# Rendezvous V2
reg add HKLM\SOFTWARE\Citrix\VirtualDesktopAgent /v GctRegistration /t REG_DWORD /d 1

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript 
 
