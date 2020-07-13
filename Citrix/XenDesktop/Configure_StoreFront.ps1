# Determine where to do the logging
$logPS = "C:\Windows\Temp\configure_storefront.log"
 
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Domain = $env:USERDOMAIN
$DomainFQDN = $env:USERDNSDOMAIN
$XDC01 = $MyConfigFile.Settings.Citrix.XDC01
$XDC02 = $MyConfigFile.Settings.Citrix.XDC02
$SF01 = $MyConfigFile.Settings.Citrix.SF01
$SF02 = $MyConfigFile.Settings.Citrix.SF02

$DatabaseUser = $MyConfigFile.Settings.Microsoft.DatabaseUser
$DatabasePassword = $MyConfigFile.Settings.Microsoft.DatabasePassword
$DatabasePassword = $DatabasePassword | ConvertTo-SecureString -asPlainText -Force
$Database_CredObject = New-Object System.Management.Automation.PSCredential($DatabaseUser,$DatabasePassword)
 
# Import the StoreFront SDK
import-module "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"
 
# Use New UI
$UseNewUI = "no"
 
# Set up Store Variables
$baseurl = "https://workspace." + "$DomainFQDN"
$Farmname = "Controllers"
$Port = "443"
$TransportType = "HTTPS"
$sslRelayPort = "443"
$Servers = "$XDC01","$XDC02"
$LoadBalance = $true
$FarmType = "XenDesktop"
$FriendlyName = "Store"
$SFPath = "/Citrix/Store"
$SFPathWeb = "/Citrix/StoreWeb"
$SiteID = 1
 
# Define Gateway
$GatewayAddress = "https://workspace." + "$DomainFQDN"
 
# Define Beacons
$InternalBeacon = "https://workspace." + "$DomainFQDN"
$ExternalBeacon1 = "https://workspace." + "$DomainFQDN"
$ExternalBeacon2 = "https://www.citrix.com"
 
# Define NetScaler Variables
$GatewayName = "workspace" + "$DomainFQDN"
$staservers = "https://$XDC01/scripts/ctxsta.dll","https://$XDC02/scripts/ctxsta.dll"
$CallBackURL = "https://workspace." + "$DomainFQDN"
 
# Define Trusted Domains
$AuthPath = "/Citrix/Authentication"
$DefaultDomain = $Domain

# Check if New or Existing Cluster

If (Test-Path "\\$SF01\C$\Windows\Temp\Passcode.ps1"){
  Write-Verbose "StoreFront Cluster Exists - Joining" -Verbose
  Invoke-Command -ComputerName "$SF01" -Credential $Database_CredObject -ScriptBlock {Start-ScheduledTask -Taskname 'Create StoreFront Cluster Join Passcode'}
  Start-Sleep -s 60
  $passcode = Get-Content "\\$SF01\C$\Windows\Temp\Passcode.txt"
  import-module "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"
  Start-DSXdServerGroupJoinService
  Start-DSXdServerGroupMemberJoin -authorizerHostName "$SF01" -authorizerPasscode $Passcode
  Write-Verbose "Waiting for join action to complete" -Verbose
  Start-Sleep -s 300
  Invoke-Command -ComputerName "$SF01" -Credential $Database_CredObject -ScriptBlock {
    import-module "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"
    Start-Sleep -s 60
    Write-Verbose "Replicating StoreFront Cluster" -Verbose
    Start-DSConfigurationReplicationClusterUpdate -Confirm:$false
    Start-Sleep -s 180
    Remove-Item "C:\Windows\Temp\Passcode.txt" -Force
    }
  }Else{
    Write-Verbose "StoreFront Cluster Doesn't Exists - Creating" -Verbose
    # Do the initial Config
    Set-DSInitialConfiguration -hostBaseUrl $baseurl -farmName $Farmname -port $Port -transportType $TransportType -sslRelayPort $sslRelayPort -servers $Servers -loadBalance $LoadBalance -farmType $FarmType -StoreFriendlyName $FriendlyName -StoreVirtualPath $SFPath -WebReceiverVirtualPath $SFPathWeb
 
    # Add NetScaler Gateway
    $GatewayID = ([guid]::NewGuid()).ToString()
    Add-DSGlobalV10Gateway -Id $GatewayID -Name $GatewayName -Address $GatewayAddress -CallbackUrl $CallBackURL -RequestTicketTwoSTA $false -Logon Domain -SessionReliability $true -SecureTicketAuthorityUrls $staservers -IsDefault $true
 
    # Add Gateway to Store
    $gateway = Get-DSGlobalGateway -GatewayId $GatewayID
    $AuthService = Get-STFAuthenticationService -SiteID $SiteID -VirtualPath $AuthPath
    Set-DSStoreGateways -SiteId $SiteID -VirtualPath $SFPath -Gateways $gateway
    Set-DSStoreRemoteAccess -SiteId $SiteID -VirtualPath $SFPath -RemoteAccessType "StoresOnly"
    Add-DSAuthenticationProtocolsDeployed -SiteId $SiteID -VirtualPath $AuthPath -Protocols CitrixAGBasic
    Set-DSWebReceiverAuthenticationMethods -SiteId $SiteID -VirtualPath $SFPathWeb -AuthenticationMethods ExplicitForms,CitrixAGBasic
    Enable-STFAuthenticationServiceProtocol -AuthenticationService $AuthService -Name CitrixAGBasic
 
    # Add beacon External
    Set-STFRoamingBeacon -internal $InternalBeacon -external $ExternalBeacon1,$ExternalBeacon2
 
    # Enable Unified Experience
    $Store = Get-STFStoreService -siteID $SiteID -VirtualPath $SFPath
    $Rfw = Get-STFWebReceiverService -SiteId $SiteID -VirtualPath $SFPathWeb
    Set-STFStoreService -StoreService $Store -UnifiedReceiver $Rfw -Confirm:$False
 
    # Set the Default Site
    Set-STFWebReceiverService -WebReceiverService $Rfw -DefaultIISSite:$True
 
    # Configure Trusted Domains
    Set-STFExplicitCommonOptions -AuthenticationService $AuthService -Domains $Domain1 -DefaultDomain $DefaultDomain -HideDomainField $True -AllowUserPasswordChange Always -ShowPasswordExpiryWarning Windows
 
    # Enable the authentication methods
    # Enable-STFAuthenticationServiceProtocol -AuthenticationService $AuthService -Name Forms-Saml,Certificate
    Enable-STFAuthenticationServiceProtocol -AuthenticationService $AuthService -Name ExplicitForms
 
    # Fully Delegate Cred Auth to NetScaler Gateway
    Set-STFCitrixAGBasicOptions -AuthenticationService $AuthService -CredentialValidationMode Kerberos
 
    # Create Featured App Groups1
    $FeaturedGroup = New-STFWebReceiverFeaturedAppGroup `
        -Title "Office 365" `
        -Description "Office 365 Applications" `
        -TileId appBundle1 `
        -ContentType AppName `
        -Contents "Outlook 2016","Word 2016","Excel 2016","PowerPoint 2016","Access 2016","Publisher 2016"
    Set-STFWebReceiverFeaturedAppGroups -WebReceiverService $Rfw -FeaturedAppGroup $FeaturedGroup

    # Set Receiver for Web Auth Methods
    Set-STFWebReceiverAuthenticationMethods -WebReceiverService $Rfw -AuthenticationMethods ExplicitForms,Certificate,CitrixAGBasic,Forms-Saml
 
    # Set Receiver Deployment Methods
    Set-STFWebReceiverPluginAssistant -WebReceiverService $Rfw -Html5Enabled Fallback -enabled $false
 
    # Set Session Timeout Options
    Set-STFWebReceiverService -WebReceiverService $Rfw -SessionStateTimeout 60
    Set-STFWebReceiverAuthenticationManager -WebReceiverService $Rfw -LoginFormTimeout 30
 
    # Set the Workspace Control Settings
    Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlLogoffAction "None"
    Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlEnabled $True
    Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlAutoReconnectAtLogon $False
    Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlShowReconnectButton $True
    Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -WorkspaceControlShowDisconnectButton $True
 
    # Set Client Interface Settings
    Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -AutoLaunchDesktop $False
    Set-STFWebReceiverUserInterface -WebReceiverService $Rfw -ReceiverConfigurationEnabled $True
 
    # Enable Loopback on HTTP
    Set-DSLoopback -SiteId $SiteID -VirtualPath $SFPathWeb -Loopback OnUsingHttp
 
    # Use New UI
    If($UseNewUI -eq "yes"){
        Remove-Item -Path "C:\iNetPub\wwwroot\$SFPathWeb\receiver\css\*" -Recurse -Force
        Copy-Item -Path "$PSScriptRoot\custom\storefront\workspace\receiver\*" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\receiver" -Recurse -Force
        Copy-Item -Path "$PSScriptRoot\custom\storefront\workspace\receiver.html" -Destination "C:\iNetPub\wwwroot\$SFPathWeb" -Recurse -Force
        Copy-Item -Path "$PSScriptRoot\custom\storefront\workspace\receiver.appcache" -Destination "C:\iNetPub\wwwroot\$SFPathWeb" -Recurse -Force
        iisreset
    }
 
    # Copy down branding
    Copy-Item -Path "$PSScriptRoot\custom\storefront\branding\background.png" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
    Copy-Item -Path "$PSScriptRoot\custom\storefront\branding\logo.png" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
    Copy-Item -Path "$PSScriptRoot\custom\storefront\branding\hlogo.png" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
    Copy-Item -Path "$PSScriptRoot\custom\storefront\branding\strings.en.js" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force
    Copy-Item -Path "$PSScriptRoot\custom\storefront\branding\style.css" -Destination "C:\iNetPub\wwwroot\$SFPathWeb\custom" -Recurse -Force

    # Create Scheduled Task for Citrix StoreFront Cluster Join Passcode

    Copy-Item -Path "$PSScriptRoot\Passcode.ps1" -Destination "C:\Windows\Temp\" -Recurse -Force

    $A = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -file C:\Windows\Temp\Passcode.ps1'
    $T = New-ScheduledTaskTrigger -Once -At (get-date).AddSeconds(-10); $t.EndBoundary = (get-date).AddSeconds(60).ToString('s')
    $S = New-ScheduledTaskSettingsSet -StartWhenAvailable -DeleteExpiredTaskAfter 00:00:30
    Register-ScheduledTask -Force -user SYSTEM -TaskName "Create StoreFront Cluster Join Passcode" -Action $A -Trigger $T -Settings $S

}
 
Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
