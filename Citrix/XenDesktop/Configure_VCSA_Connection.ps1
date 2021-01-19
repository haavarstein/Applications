# Determine where to do the logging
$logPS = "C:\Windows\Temp\configure_vcsa_connection.log"
 
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Domain = $env:USERDOMAIN
$DomainFQDN = $env:USERDNSDOMAIN
$XDC01 = $MyConfigFile.Settings.Citrix.XDC01

$VCenter = $MyConfigFile.Settings.VMware.VCenter
$VCUser = $MyConfigFile.Settings.VMware.VCUser
$VCPwd = $MyConfigFile.Settings.VMware.VCPwd
$PasswordFile = $MyConfigFile.Settings.VMware.PasswordFile
$KeyFile = $MyConfigFile.Settings.VMware.KeyFile
$DataCenter = $MyConfigFile.Settings.VMware.DataCenter
$ESXi = $MyConfigFile.Settings.VMware.ESXi
$Cluster = $MyConfigFile.Settings.VMware.VMCluster
$VMDS = $MyConfigFile.Settings.VMware.VMDS
$NetName = $MyConfigFile.Settings.VMware.NetName

Write-Verbose "Getting Encrypted Password from KeyFile" -Verbose
$SecurePassword = ((Get-Content $PasswordFile) | ConvertTo-SecureString -Key (Get-Content $KeyFile))
$SecurePasswordInMemory = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword);
$VCPwd = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecurePasswordInMemory);
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($SecurePasswordInMemory);
$VCPwd = $VCPwd | ConvertTo-SecureString -asPlainText -Force

$VCenterSDK = "https://" + "$VCenter" + "/sdk"
$ConnectionName = "VCSA"
$ResourceName = "$NetName" + " " + "$VMDS"
$RootPath = "XDHyp:\Connections\$ConnectionName\$DataCenter.datacenter\$Cluster.cluster\"
$NetworkPath = "$RootPath" + "$Netname.network"
$StoragePath = "$RootPath" + "$VMDS.storage"
$PvDPath = "$RootPath" + "$VMDS.storage"

Write-Verbose "Import PowerShell Module" -Verbose
Add-PSSnapin Citrix.*

Set-HypAdminConnection -AdminAddress "$XDC01:80"
New-Item -ConnectionType "VCenter" -HypervisorAddress @("$VCenterSDK") -Path @("XDHyp:\Connections\$ConnectionName") -Persist -Scope @() -SecurePassword $VCPwd -UserName $VCUser

$Hyp = Get-ChildItem -Path @('XDHyp:\Connections')
$HypGUID = $Hyp.HypervisorConnectionUid.Guid
New-BrokerHypervisorConnection -AdminAddress "$XDC01:80" -HypHypervisorConnectionUid "$HypGUID"

$job = [Guid]::NewGuid()
New-HypStorage -AdminAddress "$($XDC01):80" -JobGroup $job -StoragePath @("$StoragePath") -StorageType "TemporaryStorage"
New-Item -HypervisorConnectionName $ConnectionName -JobGroup $job -NetworkPath @("$NetworkPath") -Path @("XDHyp:\HostingUnits\$ResourceName") -PersonalvDiskStoragePath @("$PvDPath") -RootPath $RootPath -StoragePath @("$StoragePath")

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
