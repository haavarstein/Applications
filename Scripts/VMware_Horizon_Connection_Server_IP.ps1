Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Write-Verbose "Getting Global Settings from XML" -Verbose
$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Config"
$Product = "Horizon Connection Server IP Address"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product PS Wrapper.log"

$NIC = Get-WMIObject Win32_NetworkAdapterConfiguration -computername . | where{$_.IPEnabled -eq $true -and $_.DHCPEnabled -eq $true}
$GW = $nic.DefaultIPGateway | Out-String
$DNS1 = $nic.DNSServerSearchOrder | Select-Object -First 1 | Out-String
$IPAddress = $MyConfigFile.Settings.VMware.ConnectionServerIP

Start-Transcript $LogPS

Write-Verbose "Getting Static IP Address" -Verbose
New-NetIPAddress -InterfaceAlias Ethernet0 -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $GW.Trim()
Set-DnsClientServerAddress -InterfaceAlias Ethernet0 -ServerAddresses $DNS.Trim()

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
