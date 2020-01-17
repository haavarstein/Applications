# Determine where to do the logging
$logPS = "C:\Windows\Temp\Configure_Additional_Domain_Controller.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$MyConfigFileloc = ("$PSScriptRoot\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Domain = $MyConfigFile.Settings.Domain
$DomainFQDN = $MyConfigFile.Settings.DomainFQDN
$NetworkId = $MyConfigFile.Settings.NetworkId
$ReverseLookup = $MyConfigFile.Settings.ReverseLookup
$val = Get-ItemProperty -Path "hklm:software\microsoft\windows nt\currentversion\" -Name "InstallationType"

set-executionpolicy bypass -force
net user Administrator /passwordreq:yes
Add-WindowsFeature "RSAT-AD-Tools"
Add-WindowsFeature -Name "ad-domain-services" -IncludeAllSubFeature -IncludeManagementTools
Add-WindowsFeature -Name "dns" -IncludeAllSubFeature -IncludeManagementTools
#Add-WindowsFeature -Name "gpmc" -IncludeAllSubFeature -IncludeManagementTools
#Add-WindowsFeature -Name "DHCP" -IncludeManagementTools

Install-ADDSDomainController `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-CriticalReplicationOnly:$false `
-Credential (Get-Credential $Domain\Administrator) `
-DatabasePath "C:\Windows\NTDS" `
-DomainName "$DomainFQDN" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$true -Force `
-SiteName “Default-First-Site-Name” `
-SysvolPath "C:\Windows\SYSVOL" `
-SafeModeAdministratorPassword (ConvertTo-SecureString 'P@ssword' -AsPlainText -Force) `


Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
