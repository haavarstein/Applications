# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$Vendor = "Citrix"
$Product = "Federated Authentication Service"
$PackageName = "FederatedAuthenticationService_x64"
$InstallerType = "msi"
$Version = $MyConfigFile.Settings.Citrix.Version
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
$Destination = "$Version\x64\Federated Authentication Service\"

Start-Transcript $LogPS

CD $Destination

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose  
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
Add-WindowsFeature "RSAT-AD-Tools"
reg add HKLM\SOFTWARE\Policies\Citrix\Authentication\UserCredentialService\Addresses /f /v Address1 /t REG_SZ /d $env:Computername
reg add HKLM\SOFTWARE\WOW6432Node\Policies\Citrix\Authentication\UserCredentialService\Addresses /f /v Address1 /t REG_SZ /d $env:Computername

Write-Verbose "Adding Server to Enterprise Admin Group" -Verbose
$Computer = "$env:computername" + "$"
ADD-ADGroupMember "Enterprise Admins" -members "$Computer"

Write-Verbose "Creating Firewall Rule" -Verbose
New-NetFirewallRule -DisplayName "Citrix FAS" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
