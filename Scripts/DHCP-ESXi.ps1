# Determine where to do the logging
$logPS = "C:\Windows\Temp\Configure_DHCP.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$MyConfigFileloc = ("$PSScriptRoot\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Domain = $MyConfigFile.Settings.Domain
$DomainFQDN = $MyConfigFile.Settings.DomainFQDN

$DNSServerIP="192.168.10.10"
$DHCPServerIP="192.168.10.10"
$StartRange="192.168.10.150"
$EndRange="192.168.10.199"
$Subnet="255.255.255.0"
$Router="192.168.10.1"

Install-WindowsFeature -Name "DHCP" -IncludeManagementTools
netsh dhcp add securitygroups
Restart-service dhcpserver
Add-DhcpServerInDC -DnsName $Env:COMPUTERNAME
Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
Add-DhcpServerV4Scope -Name "DHCP Scope" -StartRange $StartRange -EndRange $EndRange -SubnetMask $Subnet
Set-DhcpServerV4OptionValue -DnsDomain $DomainFQDN -DnsServer $DNSServerIP -Router $Router
Set-DhcpServerv4OptionValue -OptionId 6 -Value $DNSServerIP -ComputerName $Env:COMPUTERNAME
Set-DhcpServerv4OptionValue -OptionId 66 -Value "192.168.10.12" -ComputerName $Env:COMPUTERNAME
Set-DhcpServerv4OptionValue -OptionId 67 -Value "\boot\x64\wdsnbp.com" -ComputerName $Env:COMPUTERNAME			
Set-DhcpServerv4Scope -ScopeId $DHCPServerIP -LeaseDuration 1.00:00:00

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
