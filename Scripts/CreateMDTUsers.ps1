# Determine where to do the logging
$logPS = "C:\Windows\Temp\Create MDT Users Accounts.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

Write-Verbose "Create MDT Users" -Verbose

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$DomainName = $Domain.Name
$OU = "OU=Service Accounts,OU=Deployment,DC=$($Domain.Name -split '\.' -join ',DC=')"
$Password = "Win0PS@AutomationFrameWork!"

Import-Module ActiveDirectory
New-AdUser -Name svc-joinaccount -SamAccountName svc-joinaccount -Path $OU -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
New-AdUser -Name svc-buildaccount -SamAccountName svc-buildaccount -Path $OU -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -AsPlainText $Password -Force)

Write-Verbose "Set full control to create objects in deployment OU" -Verbose

$OU = "OU=Deployment,DC=$($Domain.Name -split '\.' -join ',DC=')"
$OuObject = Get-ADObject -Identity $OU
$Acl = Get-Acl "ActiveDirectory:://RootDSE/$($OuObject.DistinguishedName)"

function New-DsAce ([Microsoft.ActiveDirectory.Management.ADObject]$AdObject, [string]$Identity, [string]$ActiveDirectoryRights, [string]$Right, [System.DirectoryServices.ActiveDirectorySecurity]$Acl) {
		$Sid = (Get-ADObject -Filter "name -eq '$Identity'" -Properties ObjectSID).ObjectSID
		$NewAccessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Sid, $ActiveDirectoryRights, $Right)
		$Acl.AddAccessRule($NewAccessRule)
		Set-Acl -Path "ActiveDirectory:://RootDSE/$($AdObject.DistinguishedName)" -AclObject $Acl
	}

New-DsAce -AdObject $OuObject -Identity JoinAccount -ActiveDirectoryRights 'GenericAll' -Right 'Allow' -Acl $Acl

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
