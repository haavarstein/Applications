 function New-VMware-VM {
    <#
    .SYNOPSIS
    Create a new VMware VM
    .DESCRIPTION
    This function creates a resource (network and storage) based on a hosting connection (see New-HostingConnection)
    .PARAMETER Name
    Name of the hosting resource
    .PARAMETER HypervisorConnectionName
    Name of the hosting connection
    .PARAMETER ClusterName
    Name of the host cluster in vCenter
    .PARAMETER NetworkName
    Array of names of networks in vCenter
    .PARAMETER StorageName
    Array of names of datastores in vCenter
    .LINK
    New-VMware-VM
    .EXAMPLE
    New-VMware-VM -VMName $VMName -vCPU $vCPU -MemoryGB $MemoryGB -DiskGB $DiskGB -DiskType $VMDiskType -Network $NetName -vCenter $VCenter -VCUser $VCUser -VCPwd $VCPwd -DataStore $VMDS -GuestId $VMGuestOS
    .EXAMPLE
    New-VMware-VM -VMName $VMName -vCPU $vCPU -MemoryGB 4 -DiskGB 50 -DiskType $VMDiskType -ISO $ISO -Network $NetName -NetworkType $NICType -vCenter $VCenter -VCUser $VCUser -VCPwd $VCPwd -DataStore $VMDS -GuestId $VMGuestOS
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VMName
        ,
        [Parameter(Mandatory=$True,HelpMessage='vCPU')]
        [ValidateNotNullOrEmpty()]
        [string]
        $vCPU
        ,
        [Parameter(Mandatory=$True,HelpMessage='Memory (GB)')]
        [ValidateNotNullOrEmpty()]
        [string]
        $MemoryGB
        ,
        [Parameter(Mandatory=$True,HelpMessage='Disk (GB)')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DiskGB
        ,
        [Parameter(Mandatory=$True,HelpMessage='Disk Type (Thin/Thick)')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DiskType
        ,
        [Parameter(Mandatory=$False,HelpMessage='ISO Image')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ISO
        ,
        [Parameter(Mandatory=$True,HelpMessage='Network')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Network
        ,
        [Parameter(Mandatory=$False,HelpMessage='Network Type')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NetworkType
        ,
        [Parameter(Mandatory=$True,HelpMessage='vCenter')]
        [ValidateNotNullOrEmpty()]
        [string]
        $vCenter
        ,
        [Parameter(Mandatory=$True,HelpMessage='vCenter User')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VCUser
        ,
        [Parameter(Mandatory=$True,HelpMessage='vCenter Password')]
        [ValidateNotNullOrEmpty()]
        [string]
        $VCPwd
                ,
        [Parameter(Mandatory=$True,HelpMessage='vCenter Datastore')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DataStore
        ,
        [Parameter(Mandatory=$True,HelpMessage='vCenter GuestOS')]
        [ValidateNotNullOrEmpty()]
        [string]
        $GuestId
    )

    Write-Verbose "Installing Modules" -Verbose 
    if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    if (!(Get-Module -ListAvailable -Name VMware.PowerCLI)) {Install-Module -Name VMware.PowerCLI -AllowClobber}

    Write-Verbose "Importing VMware PowerCli Module" -Verbose
    Set-PowerCLIConfiguration -DisplayDeprecationWarnings 0 -Confirm:$false | out-null
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | out-null    
    Import-Module VMware.DeployAutomation

    Write-Verbose "Connecting to vCenter $vCenter" -Verbose
    Connect-VIServer $vCenter -User $VCUser -Password $VCPwd | Out-Null
    $Resource = Get-ResourcePool
    $ResourceName = $Resource.Name
    New-VM -Name $VMName -numcpu $vCPU -MemoryGB $MemoryGB -DiskGB $DiskGB -DiskStorageFormat $DiskType -Network $Network -DataStore $DataStore -GuestId $GuestId -ResourcePool $ResourceName -CD | Out-Null
    Get-VM $VMName | Get-CDDrive | Set-CDDrive -ISOPath $ISO -StartConnected:$true -Confirm:$false | out-null
}

$MyConfigFileloc = ("\\mdt-01\mdtproduction$\Applications\VMware.xml")
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
$vCPU = 2
$VMName = "Test"

New-VMware-VM -VMName $VMName -vCPU $vCPU -MemoryGB 4 -DiskGB 50 -DiskType $VMDiskType -Network $NetName -vCenter $VCenter -VCUser $VCUser -VCPwd $VCPwd -DataStore $VMDS -GuestId $VMGuestOS

