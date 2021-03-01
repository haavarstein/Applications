Function Disable-NetAdapterPowerSavings {
    [CmdletBinding()]

    Param
    (
        [string]$NIC ,
        [string]$registryKeyword = 'PnPCapabilities' ,
        [switch]$disable ,
        [switch]$noRestart
    )

    if( ! ( $adapters = Get-Netadapter -Physical ) )
    {
        Throw 'Failed to find any physical NICs'
    }

    [int]$successes = 0

    foreach ($adapter in $adapters)
    {
        Write-Verbose -Message "$($adapter.Name) - $($adapter.InterfaceDescription)"
        if( ! $PSBoundParameters[ 'NIC' ] -or $adapter.InterfaceDescription -match $NIC )
        {
            [int]$newValue = -1

	        if( ! ( $pnp = $adapter | Get-NetAdapterAdvancedProperty -RegistryKeyword $registryKeyword -AllProperties  -ErrorAction SilentlyContinue) )
	        {
                if( $disable )
                {
		            $newValue = 280
                }
                Write-Verbose -Message "No $registryKeyword found"
	        }
	        elseif (([int]"$($pnp.RegistryValue)" -band 24) -eq 0)
	        {
                Write-Verbose -Message "$registryKeyword found but power saving not set"
                if( $disable )
                {
		            $newValue = [int]"$($pnp.RegistryValue)" -bor 24
		            $adapter | Remove-NetAdapterAdvancedProperty -RegistryKeyword $registryKeyword -AllProperties -NoRestart:$noRestart
                }
	        }
	        elseif (([int]"$($pnp.RegistryValue)" -band 24) -eq 24)
	        {
		        Write-Verbose -Message "Power saving $registryKeyword already enabled"
                $successes++
	        }
	        else
	        {
		        Write-Warning -Message "Unexpected setting $($pnp.RegistryValue)" 
	        }

            if( $disable -and $newValue -ge 0 )
            {
		        if( ! ( $newSetting = $adapter | New-NetAdapterAdvancedProperty -RegistryKeyword $registryKeyword -RegistryValue $newValue -RegistryDataType REG_DWORD -NoRestart:$noRestart ) -or $newSetting.RegistryValue -ne $newValue )
                {
                    Write-Warning -Message "Failed to set $registryKeyword to $newValue"
                }
                else
                {
                    Write-Verbose -Message "Set $registryKeyword to $newValue succeeded"
                    $successes++
                }
            }
        }
        else
        {
            Write-Verbose -Message "Ignoring `"$($adapter.InterfaceDescription)`" as doesn't match $NIC"
        }
    }

    $successes ## return
}

# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Write-Verbose "Installing Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted  | Out-Null
Install-Module Evergreen -Force | Import-Module Evergreen | Out-Null

$Vendor = "VMware"
$Product = "Tools"
$PackageName = "setup64"
$Evergreen = Get-VMWareTools | Where-Object {$_.Architecture -eq "x64"}
$Version = $Evergreen.Version
$URL = $Evergreen.uri
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/S /v /qn REBOOT=R'
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS | Out-Null
 
If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null}
 
CD $Version
 
Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source}

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Disabling Power Savings on NIC" -Verbose
Disable-NetAdapterPowerSavings -disable -noRestart

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
