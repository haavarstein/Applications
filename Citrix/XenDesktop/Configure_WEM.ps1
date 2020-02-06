Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "Workspace Environment Management"
$Version = "4.5"
$LogPS = "${env:SystemRoot}" + "\Temp\Configure $Vendor $Product $Version Site PS Wrapper.log"

Start-Transcript $LogPS

$Domain = $env:USERDOMAIN
$DomainFQDN = $env:USERDNSDOMAIN
$SiteName = $MyConfigFile.Settings.Citrix.SiteName
$WEMAdminGroup = $MyConfigFile.Settings.Citrix.WEMAdminGroup
$WEMSvcAcc = $MyConfigFile.Settings.Citrix.WEMSvcAcc
$WEMSvcAccPwd = ConvertTo-SecureString $MyConfigFile.Settings.Citrix.WEMSvcAccPwd -AsPlainText -Force
$WEMSvcAccCred = New-Object System.Management.Automation.PSCredential($WEMSvcAcc, $WEMSvcAccPwd);
$DBVuemUserPwd = $MyConfigFile.Settings.Citrix.DBVuemUserPwd
$DBVuemUserCred = $DBVuemUserPwd | ConvertTo-SecureString -asPlainText -Force

$DatabaseServer = $MyConfigFile.Settings.Microsoft.DatabaseServer
$DatabaseFolder = $MyConfigFile.Settings.Microsoft.DatabaseFolder
$DatabaseFolderUNC = $MyConfigFile.Settings.Microsoft.DatabaseFolderUNC

$DatabaseName = "$SiteName" + "_" + "WEM"
$DataFilePath = "$DatabaseFolder" + "$DatabaseName" + "_" + "Data.mdf"
$DataFileUNCPath = "$DatabaseFolderUNC" + "$DatabaseName" + "_" + "Data.mdf"
$LogFilePath = "$DatabaseFolder" + "$DatabaseName" + "_" + "Log.ldf"

#Write-Verbose "Getting Encrypted Password from KeyFile" -Verbose
#Use When Reading Password in clear text from XML
#$DatabasePassword = $DatabasePassword | ConvertTo-SecureString -asPlainText -Force
#$DatabasePassword = ((Get-Content $DatabasePasswordFile) | ConvertTo-SecureString -Key (Get-Content $DatabaseKeyFile))
#$DatabasePassword = $DatabasePassword | ConvertTo-SecureString -asPlainText -Force
#$Database_CredObject = New-Object System.Management.Automation.PSCredential($DatabaseUser,$DatabasePassword)

Write-Verbose "Import PowerShell Module" -Verbose
Import-Module "C:\Program Files (x86)\Norskale\Norskale Infrastructure Services\Citrix.Wem.InfrastructureServiceConfiguration.dll" -Verbose

If (Test-Path $DataFileUNCPath){
  Write-Verbose "Database already exists" -Verbose  
  }Else{
  Write-Verbose "Create New Database using Windows Authenticaion" -Verbose
  New-WemDatabase -DatabaseServerInstance $DatabaseServer -DatabaseName $DatabaseName -DataFilePath $DataFilePath -LogFilePath $LogFilePath -DefaultAdministratorsGroup $WEMAdminGroup -WindowsAccount $WEMSvcAcc -VuemUserSqlPassword $DBVuemUserCred -PSDebugMode Enable
}

Write-Verbose "Configure CWEM Service" -Verbose
#Set-WemInfrastructureServiceConfiguration -DatabaseServerInstance $DatabaseServer -DatabaseName $DatabaseName -InfrastructureServiceAccountCredential $Database_CredObject
Set-WemInfrastructureServiceConfiguration -EnableInfrastructureServiceAccountCredential Enable -InfrastructureServiceAccountCredential $WEMSvcAccCred -DatabaseServerInstance $DatabaseServer -DatabaseName $DatabaseName -SetSqlUserSpecificPassword Enable -SqlUserSpecificPassword $DBVuemUserCred -EnableScheduledMaintenance Enable -PSDebugMode Enable -SendGoogleAnalytics Disable -UseCacheEvenIfOnline Disable -DebugMode Enable


Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
