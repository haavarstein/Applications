Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Config"
$Product = "Set Static IP Address"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product PS Wrapper.log"

Start-Transcript $LogPS

Write-Verbose "Getting Static IP Address" -Verbose
New-NetIPAddress -InterfaceAlias Ethernet0 -IPAddress 192.168.86.16 -PrefixLength 24 -DefaultGateway 192.168.86.254
Set-DnsClientServerAddress -InterfaceAlias Ethernet0 -ServerAddresses ("192.168.86.10","192.168.86.11")

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
