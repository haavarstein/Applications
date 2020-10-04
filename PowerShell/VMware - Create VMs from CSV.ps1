#https://github.com/jootuom/posh-mac/blob/master/Get-RandomMAC.psm1
Function Get-RandomMAC {
	[CmdletBinding()]
	Param(
		[Parameter()]
		[string] $Separator = ":"
	)

	[string]::join($Separator, @(
		# "Locally administered address"
		# any of x2, x6, xa, xe
		"00","50","56","00"
		("{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255)),
		("{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255))
	))
}

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)	

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$VCenter = $MyConfigFile.Settings.VMware.VCenter
$VCUser = $MyConfigFile.Settings.VMware.VCUser
$VCPwd = $MyConfigFile.Settings.VMware.VCPwd
$VMDiskType = $MyConfigFile.Settings.VMware.VMDiskType
$VMDS = $MyConfigFile.Settings.VMware.VMDS
$VMCluster = $MyConfigFile.Settings.VMware.VMCluster
$VMFolder = $MyConfigFile.Settings.VMware.VMFolder
$NICType = $MyConfigFile.Settings.VMware.NICType
$NetName = $MyConfigFile.Settings.VMware.NetName
$VMGuestOS = $MyConfigFile.Settings.VMware.VMGuestOS
$ISO = $MyConfigFile.Settings.VMware.ISO
$ESXi = $MyConfigFile.Settings.VMware.ESXi

$csv = "$PSScriptRoot\VMList.csv"
$PSINIPath = "$env:Settings\Applications\Modules\PSini\PSini.psm1"
$IniFile = "\\$env:computername\mdtproduction$\Control\CustomSettings.ini"
copy-item $IniFile -Destination $env:TEMP

# Add Module
Import-Module VMware.DeployAutomation
Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -ErrorAction Stop -WarningAction Stop
Import-Module $PSINIPath -ErrorAction Stop -WarningAction Stop

Write-Verbose "Connecting to vCenter Server $vCenter" -Verbose
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Confirm:$false
Set-PowerCLIConfiguration -DisplayDeprecationWarnings 0 -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-viserver $VCenter -user $VCUser -password $VCPwd -WarningAction 0 | out-null
Write-Host ""

foreach($vmLine in (Import-Csv -Path $csv -UseCulture)){

    $vmname = $vmline.VMName
    $taskid = $vmline.TaskID
    $ip = $vmline.VMStaticIP
    $sub = $vmLine.VMNetmask
    $gw = $vmline.VMGateway
    $dns1 = $vmLine.VMDns1
    $fqdn = $env:userdnsdomain
    $ou = $vmline.OU
    
    Write-Verbose "Creating $vmname" -Verbose
    New-VM -Name $vmline.VMName -VMHost $ESXi -numcpu $vmline.vCPU -MemoryGB $vmline.vRAM -DiskGB $vmline.vDiskGB -DiskStorageFormat $VMDiskType -Datastore $VMDS -GuestId $VMGuestOS -NetworkName $NetName -CD | out-null
    Get-VM $vmline.VMName | Get-NetworkAdapter | Set-NetworkAdapter -Type $NICType -StartConnected:$true -Confirm:$false | out-null
    Start-Sleep -s 10
    Get-VM $vmline.VMName | Get-CDDrive | Set-CDDrive -ISOPath $ISO -StartConnected:$true -Confirm:$false | out-null
    
    # Set Random MAC address
    $VMMAC = Get-RandomMAC
    Get-VM $vmline.VMName | Get-NetworkAdapter | Set-NetworkAdapter -MacAddress $VMMAC -StartConnected:$true -Confirm:$false | out-null
                       
    # Create MAC Address entry in CS.ini
    $CustomSettings = Get-IniContent -FilePath $IniFile -CommentChar ";"
           
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDComputerName"="$vmname"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"SkipTaskSequence"="YES"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"SkipComputerName"="YES"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"TaskSequenceID"="$taskid"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"HideShell"="YES"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"SkipFinalSummary"="YES"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"FinishAction"="REBOOT"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
        
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"MachineObjectOU"="$OU"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapterCount"="1"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapter0EnableDHCP"="False"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapter0IPAddressList"="$ip"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate
        
    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapter0SubnetMask"="$sub"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapter0Gateways"="$gw"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapter0DNSServerList"="$dns1"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapter0DNSSuffix"="$fqdn"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    $CSIniUpdate = Set-IniContent -FilePath $IniFile -Sections "$VMMAC" -NameValuePairs @{"OSDAdapter0Name"="$NetName"}
    Out-IniFile -FilePath $IniFile -Force -Encoding ASCII -InputObject $CSIniUpdate

    Write-Verbose "Starting $vmname" -Verbose
    Start-VM -VM $vmline.VMName -confirm:$false -RunAsync | out-null

    Start-Sleep -s 60

    #Write-Verbose "Waiting for $VMname to respond to Ping" -Verbose
    #   do {
	#	    $ping = test-connection -ComputerName $vmname -count 1 -Quiet
	#   } until ($ping)
    
    Write-Verbose "Deployment of $VMname started Successfully" -Verbose
    Write-Host ""
    copy-item "$env:TEMP\CustomSettings.ini" -Destination $IniFile
}

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose

