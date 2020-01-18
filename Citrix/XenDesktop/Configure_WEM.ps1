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
$LicenseServer = $MyConfigFile.Settings.Citrix.LicenseServer
$DomainAdminGroup = $MyConfigFile.Settings.Citrix.DomainAdminGroup

$DatabaseServer = $MyConfigFile.Settings.Microsoft.DatabaseServer
$DatabaseFolder = $MyConfigFile.Settings.Microsoft.DatabaseFolder
$DatabaseFolderUNC = $MyConfigFile.Settings.Microsoft.DatabaseFolderUNC
$DatabaseUser = $MyConfigFile.Settings.Microsoft.DatabaseUser
$DatabasePassword = $MyConfigFile.Settings.Microsoft.DatabasePassword
$DatabasePasswordFile = $MyConfigFile.Settings.Microsoft.DatabasePasswordFile
$DatabaseKeyFile = $MyConfigFile.Settings.Microsoft.DatabaseKeyFile

$DatabaseName = "$SiteName" + "_" + "WEM"
$DataFilePath = "$DatabaseFolder" + "$DatabaseName" + "_" + "Data.mdf"
$DataFileUNCPath = "$DatabaseFolderUNC" + "$DatabaseName" + "_" + "Data.mdf"
$LogFilePath = "$DatabaseFolder" + "$DatabaseName" + "_" + "Log.ldf"

Write-Verbose "Getting Encrypted Password from KeyFile" -Verbose
#Use When Reading Password in clear text from XML
#$DatabasePassword = $DatabasePassword | ConvertTo-SecureString -asPlainText -Force
$DatabasePassword = ((Get-Content $DatabasePasswordFile) | ConvertTo-SecureString -Key (Get-Content $DatabaseKeyFile))
$Database_CredObject = New-Object System.Management.Automation.PSCredential($DatabaseUser,$DatabasePassword)

Write-Verbose "Import PowerShell Module" -Verbose
Import-Module "C:\Program Files (x86)\Norskale\Norskale Infrastructure Services\Citrix.Wem.InfrastructureServiceConfiguration.dll" -Verbose

If (Test-Path $DataFileUNCPath){
  Write-Verbose "Database already exists" -Verbose  
  }Else{
  Write-Verbose "Create New Database using Windows Authenticaion" -Verbose
  New-WemDatabase -DatabaseServerInstance $DatabaseServer -DatabaseName $DatabaseName -DataFilePath $DataFilePath -LogFilePath $LogFilePath -DefaultAdministratorsGroup $DomainAdminGroup -PSDebugMode Enable 
}

Write-Verbose "Configure CWEM with Database" -Verbose
Set-WemInfrastructureServiceConfiguration -DatabaseServerInstance $DatabaseServer -DatabaseName $DatabaseName -LicenseServerName $LicenseServer -InfrastructureServiceAccountCredential $Database_CredObject

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
