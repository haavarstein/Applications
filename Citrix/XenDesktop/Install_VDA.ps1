Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)	

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "VDA"
$Version = $MyConfigFile.Settings.Citrix.Version
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogPath = "${env:SystemRoot}" + "\Temp\"

$ListofDDCs = $MyConfigFile.Settings.Citrix.ListofDDCs
#$ListofDDCs = $env:ListofDDCs

$UnattendedArgs = '/noreboot /noresume /quiet /components vda /controllers "'+$ListofDDCs+'" /mastermcsimage /enable_remote_assistance /enable_hdx_ports /enable_hdx_udp_ports /enable_real_time_transport /disableexperiencemetrics /includeadditional "Citrix User Profile Manager WMI Plugin" /exclude "Personal vDisk","Citrix Telemetry Service" /virtualmachine /logpath "C:\Windows\Temp"'
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
