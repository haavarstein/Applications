Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "XenDesktop"
$Version = $MyConfigFile.Settings.Citrix.Version
$LogPS = "${env:SystemRoot}" + "\Temp\Configure $Vendor $Product $Version Site PS Wrapper.log"
$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Start-Transcript $LogPS

$VMWDrivers = "C:\Program Files\Common Files\VMware\Drivers"
$XENDrivers = "C:\Program Files\Citrix\XenTools\Drivers"
$NTXDrivers = "C:\Program Files\Nutanix\VirtIO"

$Domain = $env:USERDOMAIN
$DomainFQDN = $env:USERDNSDOMAIN
$Target = "$env:COMPUTERNAME" + "." + "$DomainFQDN"

$SiteName = $MyConfigFile.Settings.Citrix.SiteName
$FullAdminGroup = $MyConfigFile.Settings.Citrix.DomainAdminGroup
$LicenseServer = $MyConfigFile.Settings.Citrix.LicenseServer
$LicensingModel = $MyConfigFile.Settings.Citrix.LicensingModel
$ProductCode = $MyConfigFile.Settings.Citrix.ProductCode
$ProductEdition = $MyConfigFile.Settings.Citrix.ProductEdition
$Port = $MyConfigFile.Settings.Citrix.Port
$AddressType = $MyConfigFile.Settings.Citrix.AddressType
$ProductVersion = "7.24"
$XDC01 = $MyConfigFile.Settings.Citrix.XDC01
$IsSingleServer = $MyConfigFile.Settings.Citrix.XASingleServer
 
 
If ($IsSingleServer -eq "False") {
$DatabaseServer = $MyConfigFile.Settings.Microsoft.DatabaseServer
$DatabaseFolderUNC = $MyConfigFile.Settings.Microsoft.DatabaseFolderUNC
} Else {
$DatabaseServer = "localhost\SQLExpress"
$DatabaseFolderUNC = "C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS\MSSQL\DATA\"
}

$DatabaseName_Site = "$SiteName" + "_" + "Site"
$DatabaseName_Logging = "$SiteName" + "_" + "Logging"
$DatabaseName_Monitor = "$SiteName" + "_" + "Monitor"
$DataFileUNCPath = "$DatabaseFolderUNC" + "$DatabaseName_Site" + ".mdf"

Write-Verbose "Import PowerShell Snapins" -Verbose
Asnp Citrix.*

If (Test-Path $DataFileUNCPath){
  Write-Verbose "$SiteName Site Exists - Joining $SiteName" -Verbose
  Add-XDController -AdminAddress $target -SiteControllerAddress $XDC01
  Set-BrokerSite -TrustRequestsSentToTheXmlServicePort $true
  }Else{
    Write-Verbose "New Site - Creating $SiteName Site and Databases" -Verbose  
    New-XDDatabase -AdminAddress $target -SiteName $SiteName -DataStore Site -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Site
    New-XDDatabase -AdminAddress $target -SiteName $SiteName -DataStore Logging -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Logging
    New-XDDatabase -AdminAddress $target -SiteName $SiteName -DataStore Monitor -DatabaseServer $DatabaseServer -DatabaseName $DatabaseName_Monitor
    New-XDSite -AdminAddress $target -SiteName $SiteName -DatabaseServer $DatabaseServer -LoggingDatabaseName $DatabaseName_Logging -MonitorDatabaseName $DatabaseName_Monitor -SiteDatabaseName $DatabaseName_Site
    Set-BrokerSite -TrustRequestsSentToTheXmlServicePort $true

        if( (Test-Path -Path $VMWDrivers ) )
        {
            Invoke-Expression "$myDir\Configure_VCSA_Connection.ps1"
        }

        if( (Test-Path -Path $XENDrivers ) )
        {
            Invoke-Expression "$myDir\Configure_XenServer_Connection.ps1"
        }

        if( (Test-Path -Path $NTXDrivers ) )
        {
            Invoke-Expression "$myDir\Configure_AHV_Connection.ps1"
        }
}

Write-Verbose "Adding Permissions" -Verbose
New-AdminAdministrator -Enabled $True -Name "$env:UserDomain\Domain Admins"
Add-AdminRight -Administrator "$env:UserDomain\Domain Admins" -Role "Full Administrator" -Scope "All"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
