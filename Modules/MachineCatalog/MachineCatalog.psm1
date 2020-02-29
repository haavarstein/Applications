Set-StrictMode -Version 2

Add-PSSnapin Citrix*

function New-MachineCatalog {
    <#
    .SYNOPSIS
    Creates a new catalog
    .PARAMETER Name
    Name of the new catalog
    .PARAMETER Description
    Description of the new catalog
    .PARAMETER AllocationType
    Allocation type of the catalog
    .PARAMETER ProvisioningType
    Provisioning type of the catalog
    .PARAMETER PersistUserChanges
    Whether and how to persist user changes
    .PARAMETER SessionSupport
    How many sessions are permitted
    .PARAMETER CatalogParams
    Hash of settings for new broker catalog
    .PARAMETER MasterImageVM
    Path to master image
    .PARAMETER CpuCount
    Number of vCPUs for virtual machines
    .PARAMETER MemoryMB
    Memory in MB for virtual machines
    .PARAMETER CleanOnBoot
    Whether to discard changes on boot
    .PARAMETER UsePersonalVDiskStorage
    Whether to use Personal vDisk
    .PARAMETER NamingScheme
    Naming scheme for new virtual machines
    .PARAMETER NamingSchemeType
    Type of naming scheme
    .PARAMETER OU
    Organizational unit for new virtual machines
    .PARAMETER Domain
    Domain for new virtual machines
    .PARAMETER HostingUnitName
    Hosting connection to use
    .PARAMETER Suffix
    Suffix to be added to name of the catalog
    .EXAMPLE
    Get-BrokerCatalog | ConvertFrom-MachineCatalog | New-MachineCatalog -Suffix '-test'
    .LINK
    ConvertFrom-MachineCatalog
    Export-MachineCatalog
    Sync-MachineCatalog
    Update-DeliveryGroup
    .NOTES
    Thanks to Aaron Parker (@stealthpuppy) for the original code (http://stealthpuppy.com/xendesktop-mcs-machine-catalog-powershell/)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the new catalog',ParameterSetName='Explicit')]
        [Parameter(Mandatory=$True,HelpMessage='Name of the new catalog',ParameterSetName='Explicit2')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$False,HelpMessage='Description of the new catalog',ParameterSetName='Explicit')]
        [Parameter(Mandatory=$False,HelpMessage='Description of the new catalog',ParameterSetName='Explicit2')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description
        ,
        [Parameter(Mandatory=$True,HelpMessage='Allocation type of the catalog',ParameterSetName='Explicit')]
        [Parameter(Mandatory=$True,HelpMessage='Allocation type of the catalog',ParameterSetName='Explicit2')]
        [ValidateSet('Static','Permanent','Random')]
        [string]
        $AllocationType
        ,
        [Parameter(Mandatory=$True,HelpMessage='Provisioning type of the catalog',ParameterSetName='Explicit')]
        [Parameter(Mandatory=$True,HelpMessage='Provisioning type of the catalog',ParameterSetName='Explicit2')]
        [ValidateSet('Manual','PVS','MCS')]
        [string]
        $ProvisioningType
        ,
        [Parameter(Mandatory=$True,HelpMessage='Whether and how to persist user changes',ParameterSetName='Explicit')]
        [Parameter(Mandatory=$True,HelpMessage='Whether and how to persist user changes',ParameterSetName='Explicit2')]
        [ValidateSet('OnLocal','Discard','OnPvd')]
        [string]
        $PersistUserChanges
        ,
        [Parameter(Mandatory=$True,HelpMessage='How many sessions are permitted',ParameterSetName='Explicit')]
        [Parameter(Mandatory=$True,HelpMessage='How many sessions are permitted',ParameterSetName='Explicit2')]
        [ValidateSet('SingleSession','MultiSession')]
        [string]
        $SessionSupport
        ,
        [Parameter(Mandatory=$False,HelpMessage='Name of the new catalog',ParameterSetName='Explicit2')]
        [ValidateNotNullOrEmpty()]
        [bool]
        $MachinesArePhysical = $False
        ,
        [Parameter(Mandatory=$True,HelpMessage='Path to master image',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $MasterImageVM
        ,
        [Parameter(Mandatory=$True,HelpMessage='Number of vCPUs for virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [int]
        $CpuCount
        ,
        [Parameter(Mandatory=$True,HelpMessage='Memory in MB for virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [int]
        $MemoryMB
        ,
        [Parameter(Mandatory=$True,HelpMessage='Whether to discard changes on boot',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [bool]
        $CleanOnBoot
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to use Personal vDisk',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [bool]
        $UsePersonalVDiskStorage = $False
        ,
        [Parameter(Mandatory=$True,HelpMessage='Naming scheme for new virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NamingScheme
        ,
        [Parameter(Mandatory=$True,HelpMessage='Type of naming scheme',ParameterSetName='Explicit')]
        [ValidateSet('Numeric','Alphabetic')]
        [string]
        $NamingSchemeType
        ,
        [Parameter(Mandatory=$True,HelpMessage='Organizational unit for new virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OU
        ,
        [Parameter(Mandatory=$True,HelpMessage='Domain for new virtual machines',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Domain
        ,
        [Parameter(Mandatory=$True,HelpMessage='Hosting connection to use',ParameterSetName='Explicit')]
        [ValidateNotNullOrEmpty()]
        [string]
        $HostingUnitName
        ,
        [Parameter(Mandatory=$True,HelpMessage='Collection of catalogs to be duplicated',ParameterSetName='CreateCatalogFromParam',ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [psobject[]]
        $CatalogParams
        ,
        [Parameter(Mandatory=$False,HelpMessage='Suffix to be added to name of the catalog',ParameterSetName='CreateCatalogFromParam')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Suffix = ''
    )

    Begin {
        Write-Debug ('[{0}] Process' -f $MyInvocation.MyCommand)
    }

    Process {
        if ($CatalogParams) {
            foreach ($Catalog in $CatalogParams) {
                $Catalog.Name += $Suffix

                if ($Catalog.ProvisioningType -like 'manual') {
                    Write-Verbose ('[{0}] Calling recursively to create catalog with name {1} and provisioning type manual' -f $MyInvocation.MyCommand, $Catalog.Name)
                    New-MachineCatalog -Name $Catalog.Name -AllocationType $Catalog.AllocationType -ProvisioningType $Catalog.ProvisioningType -PersistUserChanges $Catalog.PersistUserChanges -SessionSupport $Catalog.SessionSupport
                    if ($Catalog.Description) { Set-BrokerCatalog -Name $Catalog.Name -Description $Catalog.Description }

                } else {
                    $Catalog.CleanOnBoot = $Catalog.CleanOnBoot -eq 'True'
                    Write-Verbose ('[{0}] Calling recursively to create catalog with name {1} with provisioning scheme' -f $MyInvocation.MyCommand, $Catalog.Name)
                    New-MachineCatalog `
                        -Name $Catalog.Name -Description $Catalog.Description -AllocationType $Catalog.AllocationType -ProvisioningType $Catalog.ProvisioningType -PersistUserChanges $Catalog.PersistUserChanges -SessionSupport $Catalog.SessionSupport `
                        -Domain $Catalog.Domain -OU $Catalog.OU -NamingScheme $Catalog.NamingScheme -NamingSchemeType $Catalog.NamingSchemeType `
                        -MasterImageVM $Catalog.MasterImageVM -CpuCount $Catalog.CpuCount -MemoryMB $Catalog.MemoryMB -CleanOnBoot $Catalog.CleanOnBoot `
                        -HostingUnitName $Catalog.HostingUnitName
                }
            }

        } else {
            if (Get-BrokerCatalog -Name $Name -Verbose:$False -ErrorAction SilentlyContinue) {
                throw ('[{0}] Broker catalog with name {1} already exists. Aborting.' -f $MyInvocation.MyCommand, $Name)
            }
            Write-Verbose ('[{0}] Creating broker catalog with name {1}' -f $MyInvocation.MyCommand, $Name)
            if (-Not $Description) {
                $Description = $Name
            }
            $NewBrokerCatalog = New-BrokerCatalog -Name $Name -Description $Description -AllocationType $AllocationType -ProvisioningType $ProvisioningType -PersistUserChanges $PersistUserChanges -SessionSupport $SessionSupport -MachinesArePhysical $MachinesArePhysical -Verbose:$False

            if ($ProvisioningType -like 'manual') {
                Write-Verbose ('[{0}] Broker catalog named {1} does not need a provisioning scheme' -f $MyInvocation.MyCommand, $Name)
                continue
            }
            
            if (Get-AcctIdentityPool -IdentityPoolName $Name -Verbose:$False -ErrorAction SilentlyContinue) {
                throw ('[{0}] Account identity pool with name {1} already exists. Aborting.' -f $MyInvocation.MyCommand, $Name)
            }
            Write-Verbose ('[{0}] Creating account identity pool with name {1}' -f $MyInvocation.MyCommand, $Name)
            $NewAcctIdentityPool = New-AcctIdentityPool -Domain $Domain -IdentityPoolName $Name -NamingScheme $NamingScheme -NamingSchemeType $NamingSchemeType -OU $OU -Verbose:$False
            Set-BrokerCatalogMetadata -CatalogId $NewBrokerCatalog.Uid -Name 'Citrix_DesktopStudio_IdentityPoolUid' -Value ([guid]::NewGuid()) -Verbose:$False
            
            if (Get-ProvScheme -ProvisioningSchemeName $Name -Verbose:$False -ErrorAction SilentlyContinue) {
                throw ('[{0}] Provisioning scheme with name {1} already exists. Aborting.' -f $MyInvocation.MyCommand, $Name)
            }
            Write-Verbose ('[{0}] Creating provisioning scheme with name {1}' -f $MyInvocation.MyCommand, $Name)
            $NewProvTaskId = New-ProvScheme -ProvisioningSchemeName $Name -HostingUnitName $HostingUnitName -IdentityPoolName $Name -MasterImageVM $MasterImageVM -VMCpuCount $CpuCount -VMMemoryMB $MemoryMB -CleanOnBoot:$CleanOnBoot -Verbose:$False -RunAsynchronously

            $ProvTask = Get-ProvTask -TaskId $NewProvTaskId
            Write-Debug ('[{0}] Tracking progress of creation process for provisioning scheme with name {1}' -f $MyInvocation.MyCommand, $Name)
            $CurrentProgress = 0
            While ($ProvTask.Active) {
                Try { $CurrentProgress = If ( $ProvTask.TaskProgress ) { $ProvTask.TaskProgress } Else {0} } Catch { }

                Write-Progress -Activity ('[{0}] Creating Provisioning Scheme with name {1} (copying and composing master image)' -f $MyInvocation.MyCommand, $Name) -Status ('' + $CurrentProgress + '% Complete') -PercentComplete $CurrentProgress
                Start-Sleep -Seconds 10
                $ProvTask = Get-ProvTask -TaskID $NewProvTaskId
            }
            $NewProvScheme = Get-ProvScheme -ProvisioningSchemeName $Name

            if (-Not $ProvTask.WorkflowStatus -eq 'Completed') {
                throw ('[{0}] Creation of provisioning scheme with name {1} failed. Aborting.' -f $MyInvocation.MyCommand, $Name)

            } else {
                Set-BrokerCatalog -Name $Name -ProvisioningSchemeId $NewProvScheme.ProvisioningSchemeUid -Verbose:$False
                $Controllers = Get-BrokerController -Verbose:$False | Select-Object -ExpandProperty DNSName -Verbose:$False
                Add-ProvSchemeControllerAddress -ProvisioningSchemeName $Name -ControllerAddress $Controllers -Verbose:$False
            }
        }
    }

    End {
        Write-Debug ('[{0}] End' -f $MyInvocation.MyCommand)
    }
}

function Sync-MachineCatalog {
    <#
    .SYNOPSIS
    Ensures the same amount of resource in the new broker catalog
    .DESCRIPTION
    Creates the same number of VMs in the new broker catalog as there are VMS present in the old broker catalog
    .PARAMETER BrokerCatalogName
    The currently active broker catalog
    .PARAMETER NewBrokerCatalogName
    The new broker catalog
    .LINK
    New-MachineCatalog
    Update-DeliveryGroup
    .EXAMPLE
    Sync-ProvVM -BrokerCatalog 'BrokenCatalog' -NewBrokerCatalog 'FixedBrokerCatalog'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='The currently active broker catalog',ParameterSetName='Sync')]
        [Parameter(Mandatory=$True,HelpMessage='The new broker catalog',ParameterSetName='Count')]
        [ValidateNotNullOrEmpty()]
        [string]
        $BrokerCatalogName
        ,
        [Parameter(Mandatory=$True,HelpMessage='The new broker catalog',ParameterSetName='Sync')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewBrokerCatalogName
        ,
        [Parameter(Mandatory=$True,HelpMessage='The new broker catalog',ParameterSetName='Count')]
        [ValidateNotNullOrEmpty()]
        [int]
        $Count
    )

    Write-Verbose ('[{0}] Processing catalog {1}' -f $MyInvocation.MyCommand, $BrokerCatalogName)

    $BrokerCatalog = Get-BrokerCatalog -Name $BrokerCatalogName
    if ($BrokerCatalogName -And $NewBrokerCatalogName) {
        $NewBrokerCatalog = Get-BrokerCatalog -Name $NewBrokerCatalogName
        $VmCount = Get-ProvVM -ProvisioningSchemeUid $BrokerCatalog.ProvisioningSchemeId -Verbose:$False | Measure-Object -Line | Select-Object -ExpandProperty Lines
        Write-Verbose ('[{0}] Calling recursively for catalog with name {1}' -f $MyInvocation.MyCommand, $NewBrokerCatalogName)
        Sync-MachineCatalog -BrokerCatalog $NewBrokerCatalog.Name -Count $VmCount
        return
    }

    $AcctIdentityPool = Get-AcctIdentityPool -IdentityPoolName $BrokerCatalog.Name -Verbose:$False
    $ProvScheme = Get-ProvScheme -ProvisioningSchemeName $BrokerCatalog.Name -Verbose:$False

    Write-Verbose ('[{0}] Creating new accounts in identity pool {1}' -f $MyInvocation.MyCommand, $AcctIdentityPool.IdentityPoolName)
    $AdAccounts = New-AcctADAccount -IdentityPoolName $AcctIdentityPool.IdentityPoolName -Count $Count -Verbose:$False
    $ProvTaskId = New-ProvVM -ADAccountName @($AdAccounts.SuccessfulAccounts) -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -RunAsynchronously
    $ProvTask = Get-ProvTask -TaskId $ProvTaskId

    $CurrentProgress = 0
    While ( $ProvTask.Active -eq $True ) {
        Try { $CurrentProgress = If ( $ProvTask.TaskProgress ) { $ProvTask.TaskProgress } Else {0} } Catch { }

        Write-Progress -Activity 'Creating Virtual Machines' -Status ('' + $CurrentProgress + '% Complete') -PercentComplete $CurrentProgress
        Start-Sleep -Seconds 10
        $ProvTask = Get-ProvTask -TaskID $ProvTaskId
    }

    Write-Verbose ('[{0}] Assigning machines to catalog with name {1}' -f $MyInvocation.MyCommand, $ProvScheme.ProvisioningSchemeName)
    $ProvVMs = Get-ProvVM -ProvisioningSchemeUid $ProvScheme.ProvisioningSchemeUid -Verbose:$False
    ForEach ($ProvVM in $ProvVMs) {
        Lock-ProvVM -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -Tag 'Brokered' -VMID @($ProvVM.VMId) -Verbose:$False -ErrorAction SilentlyContinue
        New-BrokerMachine -CatalogUid $BrokerCatalog.Uid -MachineName $ProvVM.ADAccountName -Verbose:$False | Out-Null
    }
}

function ConvertFrom-MachineCatalog {
    <#
    .SYNOPSIS
    Convert a broker catalog to a hash
    .DESCRIPTION
    Only those fields are extracted from the catalog object that are required for creating the catalog
    .PARAMETER BrokerCatalog
    Collection of broker catalog to convert to a hash
    .PARAMETER ExcludeProvScheme
    Whether to exclude the provisioning scheme
    .PARAMETER ExcludeAcctIdentityPool
    Whether to exclude the account identity pool
    .PARAMETER ExcludeHostingUnit
    Whether to exclude the hosting unit
    .LINK
    ConvertTo-MachineCatalog
    New-MachineCatalog
    Export-MachineCatalog
    .EXAMPLE
    ConvertFrom-MachineCatalog -BrokerCatalog (Get-BrokerCatalog)
    .EXAMPLE
    Get-BrokerCatalog | ConvertFrom-MachineCatalog
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Collection of broker catalog to convert to a hash',ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [Citrix.Broker.Admin.SDK.Catalog[]]
        $BrokerCatalog
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to exclude the provisioning scheme')]
        [switch]
        $ExcludeProvScheme
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to exclude the account identity pool')]
        [switch]
        $ExcludeAcctIdentityPool
        ,
        [Parameter(Mandatory=$False,HelpMessage='Whether to exclude the hosting unit')]
        [switch]
        $ExcludeHostingUnit
    )

    Process {
        Write-Debug ('[{0}] Enumerating members of BrokerCatalog' -f $MyInvocation.MyCommand)

        foreach ($Catalog in $BrokerCatalog) {
            Write-Verbose ('[{0}] [{1}] Processing BrokerCatalog.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)

            $CatalogParams = New-Object psobject -Property @{
                    Name               = $Catalog.Name
                    Description        = $Catalog.Description
                    AllocationType     = $Catalog.AllocationType
                    ProvisioningType   = $Catalog.ProvisioningType
                    PersistUserChanges = $Catalog.PersistUserChanges
                    SessionSupport     = $Catalog.SessionSupport
            }

            if (-Not $Catalog.ProvisioningSchemeId) {
                Write-Verbose ('[{0}] [{1}] No provisioning scheme specified' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $CatalogParams
                continue
            }

            if (-Not $ExcludeProvScheme) {
                Write-Debug ('[{0}] [{1}] Accessing ProvisioningScheme' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $ProvScheme = Get-ProvScheme -ProvisioningSchemeUid $Catalog.ProvisioningSchemeId -Verbose:$False
                Write-Verbose ('[{0}] [{1}] Retrieved ProvisioningScheme.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)

                $CatalogParams | Add-Member -NotePropertyMembers @{
                        MasterImageVM           = $ProvScheme.MasterImageVM
                        CpuCount                = $ProvScheme.CpuCount
                        MemoryMB                = $ProvScheme.MemoryMB
                        CleanOnBoot             = $ProvScheme.CleanOnBoot
                }
            }

            if (-Not $ExcludeAcctIdentityPool) {
                Write-Debug ('[{0}] [{1}] Accessing AcctIdentityPool' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $AcctIdentityPool = Get-AcctIdentityPool -IdentityPoolUid $ProvScheme.IdentityPoolUid -Verbose:$False
                Write-Verbose ('[{0}] [{1}] Retrieved AcctIdentityPool.IdentityPoolName={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $AcctIdentityPool.IdentityPoolName)

                $CatalogParams | Add-Member -NotePropertyMembers @{
                        NamingScheme       = $AcctIdentityPool.NamingScheme
                        NamingSchemeType   = $AcctIdentityPool.NamingSchemeType
                        OU                 = $AcctIdentityPool.OU
                        Domain             = $AcctIdentityPool.Domain
                }
            }

            if (-Not $ExcludeHostingUnit) {
                Write-Debug ('[{0}] [{1}] Accessing HostingUnit' -f $MyInvocation.MyCommand, $Catalog.UUID)
                $HostingUnit = Get-ChildItem XDHyp:\HostingUnits -Verbose:$False | Where-Object HostingUnitUid -eq $ProvScheme.HostingUnitUid -Verbose:$False
                Write-Verbose ('[{0}] [{1}] Retrieved HostingUnit.HostingUnitName={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $HostingUnit.HostingUnitName)

                $CatalogParams | Add-Member -NotePropertyMembers @{
                        HostingUnitName    = $HostingUnit.HostingUnitName
                }
            }

            Write-Debug ('[{0}] [{1}] Returning custom object with parameters for BrokerCatalog.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)
            $CatalogParams
            Write-Debug ('[{0}] [{1}] Finished processing BrokerCatalog.Name={2}' -f $MyInvocation.MyCommand, $Catalog.UUID, $Catalog.Name)
        }
    }
}

function ConvertTo-MachineCatalog {
    <#
    .SYNOPSIS
    Creates broker catalogs from a CSV file
    .DESCRIPTION
    The contents of the specified file is parsed using ConvertFrom-Csv and piped to New-MachineCatalog
    .PARAMETER Path
    Path of CSV file to import catalogs from
    .EXAMPLE
    ConvertTo-MachineCatalog -Path .\Catalogs.csv
    .LINK
    ConvertFrom-MachineCatalog
    New-MachineCatalog
    Export-MachineCatalog
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Path of CSV file to import catalogs from')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (-Not (Test-Path -Path $Path)) {
        throw ('[{0}] File <{1}> does not exist. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }

    Get-Content -Path $Path | ConvertFrom-Csv | New-MachineCatalog
}

function Export-MachineCatalog {
    <#
    .SYNOPSIS
    Exports all broker catalogs to the specified CSV file
    .DESCRIPTION
    The output of Get-BrokerCatalog is piped through ConvertFrom-MachineCatalog and written to a CSV file
    .PARAMETER Path
    Path of the CSV file to export broker catalogs to
    .LINK
    ConvertFrom-MachineCatalog
    ConvertTo-MachineCatalog
    New-MachineCatalog
    .EXAMPLE
    Export-MachineCatalog -Path .\Catalogs.csv
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Path of the CSV file to export broker catalogs to')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (Test-Path -Path $Path) {
        throw ('[{0}] File <{1}> already exists. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }

    Get-BrokerCatalog | ConvertFrom-MachineCatalog | ConvertTo-Csv | Out-File -FilePath $Path
}

function Remove-MachineCatalog {
    <#
    .SYNOPSIS
    Removes a machine catalog with all associated objects
    .DESCRIPTION
    The following objects will be removed: virtual machines, computer accounts, broker catalog, account identity pool, provisioning scheme
    .PARAMETER Name
    Name of the objects to remove
    .LINK
    New-MachineCatalog
    Rename-MachineCatalog
    .EXAMPLE
    Remove-BrokerCatalog -Name 'test'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the objects to remove')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    Get-BrokerMachine | Where-Object CatalogName -eq $Name | Remove-BrokerMachine
    Get-ProvVM -ProvisioningSchemeName $Name | foreach {
        Unlock-ProvVM -ProvisioningSchemeName $Name -VMID $_.VMId
        Remove-ProvVM -ProvisioningSchemeName $Name -VMName $_.VMName
    }
    Get-AcctADAccount    -IdentityPoolName $Name       -ErrorAction SilentlyContinue | Remove-AcctADAccount -IdentityPoolName $Name
    Get-BrokerCatalog    -Name $Name                   -ErrorAction SilentlyContinue | Remove-BrokerCatalog
    Get-AcctIdentityPool -IdentityPoolName $Name       -ErrorAction SilentlyContinue | Remove-AcctIdentityPool
    Get-ProvScheme       -ProvisioningSchemeName $Name -ErrorAction SilentlyContinue | Remove-ProvScheme
}

function Rename-MachineCatalog {
    <#
    .SYNOPSIS
    Renames a machine catalog
    .DESCRIPTION
    The following objects are renamed: BrokerCatalog, ProvScheme, AcctIdentityPool
    .PARAMETER Name
    Name of the existing catalog
    .PARAMETER NewName
    New name for the catalog
    .LINK
    Remove-MachineCatalog
    New-MachineCatalog
    .EXAMPLE
    Rename-MachineCatalog -Name 'OldName' -NewName 'NewName'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the existing catalog')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$True,HelpMessage='New name for the catalog')]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewName
    )

    Rename-BrokerCatalog    -Name                   $Name -NewName                   $NewName
    Rename-ProvScheme       -ProvisioningSchemeName $Name -NewProvisioningSchemeName $NewName
    Rename-AcctIdentityPool -IdentityPoolName       $Name -NewIdentityPoolName       $NewName
}

function Update-DeliveryGroup {
    <#
    .SYNOPSIS
    Substitutes machines in a desktop group
    .DESCRIPTION
    The machines contained in the desktop group are removed and new machines are added from the specified catalog
    .PARAMETER Name
    Name of an existing desktop group
    .PARAMETER CatalogName
    Name of the catalog containing new machines
    .PARAMETER Count
    Number of machines to add
    .LINK
    New-MachineCatalog
    Sync-MachineCatalog
    .EXAMPLE
    The following command adds all machines from the given catalog to the specified desktop group
    Update-DeliveryGroup -Name 'DG-SessionHost' -CatalogName 'MCS-SessionHost'
    .EXAMPLE
    The following command adds two machines from the given catalog to the specified desktop group
    Update-DeliveryGroup -Name 'DG-SessionHost' -CatalogName 'MCS-SessionHost' -Count 2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of an existing desktop group')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$True,HelpMessage='Name of the catalog containing new machines')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CatalogName
        ,
        [Parameter(Mandatory=$False,HelpMessage='Number of machines to add')]
        [ValidateNotNullOrEmpty()]
        [int]
        $Count
    )

    Write-Verbose ('[{0}] Retrieving machines in desktop group named {1}' -f $MyInvocation.MyCommand, $Name)
    $ExistingMachines = Get-BrokerMachine | Where-Object DesktopGroupName -eq $Name
    $ExistingMachines | foreach { Write-Debug ('[{0}]   {1}' -f $MyInvocation.MyCommand, $_.MachineName) }
    
    $Catalog = Get-BrokerCatalog -Name $CatalogName
    if (-Not $Count) {
        $Count = $Catalog.UnassignedCount
    }
    Write-Verbose ('[{0}] Adding {2} machines from catalog {1} to desktop group <{3}>' -f $MyInvocation.MyCommand, $CatalogName, $Count, $Name)
    $AddedCount = Add-BrokerMachinesToDesktopGroup -DesktopGroup $Name -Catalog $Catalog -Count $Count

    Write-Verbose ('[{0}] Removing old machines from desktop group named {1}' -f $MyInvocation.MyCommand, $Name)
    $ExistingMachines | Set-BrokerMachine -InMaintenanceMode $True | Out-Null
    $ExistingMachines | Remove-BrokerMachine -DesktopGroup $Name | Out-Null

    Write-Verbose ('[{0}] Starting new machines in delivery group named {1}' -f $MyInvocation.MyCommand, $Name)
    Get-BrokerMachine -DesktopGroupName $Name | Where-Object { $_.SupportedPowerActions -icontains 'TurnOn' } | foreach {
        New-BrokerHostingPowerAction -Action 'TurnOn' -MachineName $_.MachineName
    }
}

function New-HostingConnection {
    <#
    .SYNOPSIS
    Create a new hosting connection
    .DESCRIPTION
    This function only creates a connection to a hosting environment without choosing any resources (see New-HostingResource)
    .PARAMETER Name
    Name of the hosting connection
    .PARAMETER ConnectionType
    Connection type can be VCenter, XenServer and SCVMM among several others
    .PARAMETER HypervisorAddress
    This contains the URL to the vCenter web API
    .PARAMETER HypervisorCredential
    A credentials object for authentication against the hypervisor
    .LINK
    New-HostingResource
    .EXAMPLE
    New-HostingConnection -Name vcenter-01 -ConnectionType VCenter -HypervisorAddress https://vcenter-01.example.com/sdk -HypervisorCredential (Get-Credential)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the hosting connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$True,HelpMessage='Connection type can be VCenter, XenServer and SCVMM among several others')]
        [ValidateSet('VCenter','XenServer','SCVMM')]
        [string]
        $ConnectionType
        ,
        [Parameter(Mandatory=$True,HelpMessage='This contains the URL to the vCenter web API')]
        [ValidateNotNullOrEmpty()]
        [string]
        $HypervisorAddress
        ,
        [Parameter(Mandatory=$True,HelpMessage='A credentials object for authentication against the hypervisor')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $HypervisorCredential
    )

    if (-Not (Test-Path -Path XDHyp:\Connections\$Name)) {
        $HostingConnection = New-Item -Path XDHyp:\Connections\$Name -ConnectionType $ConnectionType -HypervisorAddress $HypervisorAddress -HypervisorCredential $HypervisorCredential -Persist
    } else {
        $HostingConnection = Get-Item XDHyp:\Connections\$Name
    }
    $HypervisorConnectionUid = $HostingConnection.HypervisorConnectionUid | Select-Object -ExpandProperty Guid
    New-BrokerHypervisorConnection -HypHypervisorConnectionUid $HypervisorConnectionUid | Out-Null
}

function New-HostingResource {
    <#
    .SYNOPSIS
    Create a new hosting resource
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
    New-HostingConnection
    .EXAMPLE
    New-HostingResource -Name cluster-01 -HypervisorConnectionName vcenter-01 -ClusterName cluster-01 -NetworkName (vlan_100,vlan_101) -StorageName (datastore1,datastore2)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,HelpMessage='Name of the hosting resource')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$True,HelpMessage='Name of the hosting connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $HypervisorConnectionName
        ,
        [Parameter(Mandatory=$True,HelpMessage='Name of the host cluster in vCenter')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ClusterName
        ,
        [Parameter(Mandatory=$True,HelpMessage='Array of names of networks in vCenter')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $NetworkName
        ,
        [Parameter(Mandatory=$True,HelpMessage='Array of names of datastores in vCenter')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $StorageName
    )

    $HypervisorConnectionPath = Join-Path -Path XDHyp:\Connections -ChildPath $HypervisorConnectionName
    $BasePath = Join-Path -Path XDHyp:\HostingUnits -ChildPath $ClusterName

    Write-Verbose ('[{0}] Caching objects for lookups under {1}' -f $MyInvocation.MyCommand, $HypervisorConnectionPath)
    $CachedObjects = Get-ChildItem -Recurse $HypervisorConnectionPath -Verbose:$False

    $ClusterPath = $CachedObjects | Where-Object { $_.Name -like $ClusterName } | Select-Object FullPath
    Write-Verbose ('[{0}] Using cluster named {1} via path <{2}>' -f $MyInvocation.MyCommand, $ClusterName,$ClusterPath.FullPath)

    $NetworkPath = $CachedObjects | Where-Object { $NetworkName -icontains $_.Name } | Select-Object FullPath
    Write-Verbose ('[{0}] Using network named {1} via path <{2}>' -f $MyInvocation.MyCommand, [string]::Join(',', $NetworkName), [string]::Join(',', $NetworkPath.FullPath))

    $StoragePath = $CachedObjects | Where-Object { $StorageName -icontains $_.Name } | Select-Object FullPath
    Write-Verbose ('[{0}] Using storage named {1} via path <{2}>' -f $MyInvocation.MyCommand, [string]::Join(',', $StorageName), [string]::Join(',', $StoragePath.FullPath))

    New-Item -Verbose:$False -Path $BasePath -RootPath $ClusterPath.FullPath `
        -HypervisorConnectionName $HypervisorConnectionName `
        -NetworkPath $NetworkPath.FullPath `
        -PersonalvDiskStoragePath $StoragePath.FullPath `
        -StoragePath $StoragePath.FullPath | Out-Null
}
