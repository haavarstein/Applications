# Determine where to do the logging
$logPS = "C:\Windows\Temp\Configure_DNS.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$MyConfigFileloc = ("$PSScriptRoot\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Domain = $MyConfigFile.Settings.Domain
$DomainFQDN = $MyConfigFile.Settings.DomainFQDN
$NetworkId = $MyConfigFile.Settings.NetworkId
$ReverseLookup = $MyConfigFile.Settings.ReverseLookup

#Set-DnsServerPrimaryZone –Name "$DomainFQDN" –ReplicationScope "Forest"
Set-DnsServerScavenging –ScavengingState $True –RefreshInterval  7:00:00:00 –NoRefreshInterval  7:00:00:00 –ScavengingInterval 7:00:00:00 –ApplyOnAllZones –Verbose
Set-DnsServerZoneAging "$DomainFQDN" –Aging $True –NoRefreshInterval 7:00:00:00 –RefreshInterval 7:00:00:00 –ScavengeServers 192.168.1.10 –PassThru –Verbose
Add-DnsServerPrimaryZone –ReplicationScope "Forest"  –NetworkId "$NetworkId" –DynamicUpdate Secure –PassThru –Verbose
Set-DnsServerZoneAging "$ReverseLookup" –Aging $True –NoRefreshInterval 7:00:00:00 –RefreshInterval 7:00:00:00  –PassThru –Verbose
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
reg add "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\ServerManager" /v DoNotOpenServerManagerAtLogon /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\ServerManager" /v DoNotOpenServerManagerAtLogon /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\ServerManager\Oobe" /v DoNotOpenInitialConfigurationTasksAtLogon /t REG_DWORD /d 1 /f
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
Add-DnsServerForwarder -IPAddress 1.1.1.1 -PassThru
Remove-DnsServerForwarder -IPAddress fec0:0:0:ffff::1 -Force
Remove-DnsServerForwarder -IPAddress fec0:0:0:ffff::2 -Force
Remove-DnsServerForwarder -IPAddress fec0:0:0:ffff::3 -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript