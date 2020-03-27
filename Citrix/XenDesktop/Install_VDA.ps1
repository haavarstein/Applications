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
$PackageName = "XenAppWorker"
$InstallerType = "exe"
$Version = $MyConfigFile.Settings.Citrix.Version
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $PackageName $Version PS Wrapper.log"
$LogPath = "${env:SystemRoot}" + "\Temp\"

$ListofDDCs = $MyConfigFile.Settings.Citrix.ListofDDCs

$UnattendedArgs = '/noreboot /noresume /quiet /components vda /controllers "'+$ListofDDCs+'" /mastermcsimage /install_mcsio_driver /enable_remote_assistance /enable_hdx_ports /enable_hdx_udp_ports /enable_real_time_transport /disableexperiencemetrics /includeadditional "Citrix User Profile Manager WMI Plugin" /exclude "Personal vDisk","Citrix Telemetry Service" /virtualmachine /logpath "C:\Windows\Temp"'
$Destination = "$Version\x64\XenDesktop Setup\"

Start-Transcript $LogPS

CD $Destination

Write-Verbose "Starting Installation of $Vendor $Product $PackageName $Version" -Verbose
(Start-Process -FilePath "XenDesktopVdaSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
write-Host $UnattendedArgs

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
