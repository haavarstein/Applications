Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "Workspace Environment Management"
$Version = $MyConfigFile.Settings.Citrix.Version
$LogPS = "${env:SystemRoot}" + "\Temp\Configure $Vendor $Product $Version Site PS Wrapper.log"

Start-Transcript $LogPS

$Domain = $env:USERDOMAIN
$DomainFQDN = $env:USERDNSDOMAIN
$LicenseServer = $MyConfigFile.Settings.Citrix.LicenseServer
$SiteName = $MyConfigFile.Settings.Citrix.SiteName
$WEMAdminGroup = $MyConfigFile.Settings.Citrix.WEMAdminGroup
$WEMSvcAcc = $MyConfigFile.Settings.Citrix.WEMSvcAcc
$IsSingleServer = $MyConfigFile.Settings.Citrix.XASingleServer

$ElevatedUser = $WEMSvcAcc
$PasswordFile = "\\dc-01\xa\Credentials\citrix-wem.txt"
$KeyFile = "\\dc-01\xa\Credentials\citrix-wem.key"

Write-Verbose "Getting Encrypted Password from KeyFile" -Verbose
$SecurePassword = ((Get-Content $PasswordFile) | ConvertTo-SecureString -Key (Get-Content $KeyFile))
$SecurePasswordInMemory = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword) 
$PasswordAsString = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecurePasswordInMemory)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($SecurePasswordInMemory)

$WEMSvcAccPwd = ConvertTo-SecureString $PasswordAsString -AsPlainText -Force
$WEMSvcAccCred = New-Object System.Management.Automation.PSCredential($WEMSvcAcc, $WEMSvcAccPwd);
$DBVuemUserPwd = $MyConfigFile.Settings.Citrix.DBVuemUserPwd
$DBVuemUserCred = $DBVuemUserPwd | ConvertTo-SecureString -asPlainText -Force

If ($IsSingleServer -eq "False") {
$DatabaseServer = $MyConfigFile.Settings.Microsoft.DatabaseServer
$DatabaseFolderUNC = $MyConfigFile.Settings.Microsoft.DatabaseFolderUNC
$DatabaseFolder = $MyConfigFile.Settings.Microsoft.DatabaseFolder
} Else {
$DatabaseServer = "localhost\SQLExpress"
$DatabaseFolderUNC = "C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\"
$DatabaseFolder = $DatabaseFolderUNC
}

$DatabaseName = "$SiteName" + "_" + "WEM"
$DataFilePath = "$DatabaseFolder" + "$DatabaseName" + "_" + "Data.mdf"
$DataFileUNCPath = "$DatabaseFolderUNC" + "$DatabaseName" + "_" + "Data.mdf"
$LogFilePath = "$DatabaseFolder" + "$DatabaseName" + "_" + "Log.ldf"

Write-Verbose "Import PowerShell Module" -Verbose
Import-Module "C:\Program Files (x86)\Norskale\Norskale Infrastructure Services\Citrix.Wem.InfrastructureServiceConfiguration.dll" -Verbose

If (Test-Path $DataFileUNCPath){
  Write-Verbose "Database already exists" -Verbose  
  }Else{
  Write-Verbose "Create New Database using Windows Authenticaion" -Verbose
  New-WemDatabase -DatabaseServerInstance $DatabaseServer -DatabaseName $DatabaseName -DataFilePath $DataFilePath -LogFilePath $LogFilePath -DefaultAdministratorsGroup $WEMAdminGroup -WindowsAccount $WEMSvcAcc -VuemUserSqlPassword $DBVuemUserCred -PSDebugMode Enable
}

Write-Verbose "Configure CWEM Service" -Verbose
Set-WemInfrastructureServiceConfiguration -EnableInfrastructureServiceAccountCredential Enable -InfrastructureServiceAccountCredential $WEMSvcAccCred -DatabaseServerInstance $DatabaseServer -DatabaseName $DatabaseName -SetSqlUserSpecificPassword Enable -SqlUserSpecificPassword $DBVuemUserCred -EnableScheduledMaintenance Enable -PSDebugMode Enable -SendGoogleAnalytics Disable -UseCacheEvenIfOnline Disable -DebugMode Enable -LicenseServerName $LicenseServer

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
