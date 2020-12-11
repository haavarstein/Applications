# Determine where to do the logging
$logPS = "C:\Windows\Temp\Create OU Structure.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$CurrentDomain = Get-ADDomain
    New-ADOrganizationalUnit -Name:"Deployment" -Path:"$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Users" -Path:"OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"vDesktops" -Path:"OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Workstations" -Path:"OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Security Groups" -Path:"OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Admin Accounts" -Path:"OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Service Accounts" -Path:"OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Servers" -Path:"OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Cloud Connectors" -Path:"OU=Servers,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Infrastructure Servers" -Path:"OU=Servers,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Delivery Controllers" -Path:"OU=Servers,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Hyper-V Servers" -Path:"OU=Servers,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Database Servers" -Path:"OU=Servers,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Splunk" -Path:"OU=Servers,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Microsoft" -Path:"OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Citrix" -Path:"OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"VMware" -Path:"OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"Parallels" -Path:"OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    
    New-ADOrganizationalUnit -Name:"W10" -Path:"OU=Microsoft,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS08" -Path:"OU=Microsoft,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS12" -Path:"OU=Microsoft,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS16" -Path:"OU=Microsoft,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS19" -Path:"OU=Microsoft,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator

    New-ADOrganizationalUnit -Name:"W10" -Path:"OU=VMware,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS08" -Path:"OU=VMware,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS12" -Path:"OU=VMware,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS16" -Path:"OU=VMware,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS19" -Path:"OU=VMware,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator

    New-ADOrganizationalUnit -Name:"W10" -Path:"OU=Parallels,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS08" -Path:"OU=Parallels,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS12" -Path:"OU=Parallels,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS16" -Path:"OU=Parallels,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS19" -Path:"OU=Parallels,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    
    New-ADOrganizationalUnit -Name:"W10" -Path:"OU=Citrix,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS08" -Path:"OU=Citrix,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS12" -Path:"OU=Citrix,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS16" -Path:"OU=Citrix,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    New-ADOrganizationalUnit -Name:"WS19" -Path:"OU=Citrix,OU=vDesktops,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator
    
    New-ADOrganizationalUnit -Name:"W10" -Path:"OU=Workstations,OU=Deployment,$CurrentDomain" -ProtectedFromAccidentalDeletion:$false -Server:$CurrentDomain.PDCEmulator 

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript