<#
.SYNOPSIS
    Installs pending Windows Updates AND driver updates via PSWindowsUpdate,
    then reboots automatically if required.

.DESCRIPTION
    Based on haavarstein/Applications Scripts/WindowsUpdate.ps1.

    Changes from the original:
      - Includes the Drivers category (original used -NotCategory "Drivers")
      - Reboots automatically when a restart is required (original used -IgnoreReboot)
      - Structured logging, TLS 1.2, NuGet bootstrap, no interactive prompts

    Designed to run elevated (Administrator or SYSTEM). Safe for Intune Platform
    Scripts if "Run script in 64-bit PowerShell" is enabled.

.NOTES
    Log file: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WindowsUpdate.log
    Driver updates from Microsoft Update can replace OEM-specific drivers.
    Test on a pilot machine before wide deployment.
#>

#Requires -RunAsAdministrator

#region Logging
$LogFolder = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile   = Join-Path -Path $LogFolder -ChildPath "WindowsUpdate.log"

if (-not (Test-Path -Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')][string]$Level = 'Info'
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $line = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop
    } catch { }
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error'   { Write-Error $Message -ErrorAction Continue }
        default   { Write-Verbose $Message -Verbose }
    }
}
#endregion

$StartDTM       = Get-Date
$ExitCode       = 0
$RebootRequired = $false
$RebootDelaySec = 60   # delay before reboot so the log can flush / Intune can report

# No interactive prompts (critical when running as SYSTEM / Intune)
$ConfirmPreference = 'None'

Write-Log "===== WindowsUpdate.ps1 started (software + drivers, auto-reboot) ====="
Write-Log "Running as: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Log "PowerShell version: $($PSVersionTable.PSVersion) | Is64BitProcess: $([Environment]::Is64BitProcess)"

try {
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Write-Log "TLS 1.2 enabled for this session."
    } catch {
        Write-Log "Could not force TLS 1.2: $($_.Exception.Message)" -Level Warning
    }

    $nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue
    if (-not $nuget) {
        Write-Log "NuGet provider not found. Bootstrapping..."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Scope AllUsers -Confirm:$false -ErrorAction Stop | Out-Null
        Write-Log "NuGet provider installed."
    } else {
        Write-Log "NuGet provider already present."
    }

    try {
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction Stop
        Write-Log "PSGallery set to Trusted."
    } catch {
        Write-Log "Could not set PSGallery to Trusted: $($_.Exception.Message)" -Level Warning
    }

    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "PSWindowsUpdate module not found. Installing..."
        Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false -ErrorAction Stop
        Write-Log "PSWindowsUpdate module installed."
    } else {
        Write-Log "PSWindowsUpdate module already installed."
    }
    Import-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
    Write-Log "PSWindowsUpdate module imported."

    Write-Log "Checking Windows Update service (wuauserv)..."
    Set-Service -Name 'wuauserv' -StartupType Automatic -ErrorAction Stop
    Start-Service -Name 'wuauserv' -ErrorAction Stop
    Write-Log "Windows Update service is running."

    Write-Log "Removing FSLogix rule files (if any)..."
    Remove-Item -Path "C:\Program Files\FSLogix\Apps\Rules\*.*" -Force -Recurse -ErrorAction SilentlyContinue

    # Include software AND drivers. No -NotCategory "Drivers".
    $commonParams = @{
        MicrosoftUpdate = $true
        ComputerName    = 'localhost'
        AcceptAll       = $true
        Confirm         = $false
        ErrorAction     = 'Stop'
    }

    Write-Log "Scanning for available software and driver updates from Microsoft Update..."
    $available = Get-WindowsUpdate @commonParams
    if ($available) {
        $available | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_.TrimEnd() }
        Write-Log "Found $(@($available).Count) update(s) (software + drivers)."
    } else {
        Write-Log "No applicable updates found."
    }

    if ($available) {
        Write-Log "Installing available software and driver updates..."
        # IgnoreReboot during install so we control the reboot ourselves
        # (cleaner logging + predictable delay). AutoReboot is used as fallback below.
        $installResult = Get-WindowsUpdate @commonParams -Install -IgnoreReboot
        $installResult | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_.TrimEnd() }
        Write-Log "Install pass finished."
    }

    try {
        $rebootStatus   = Get-WURebootStatus -Silent
        $RebootRequired = [bool]$rebootStatus
        Write-Log "Reboot required: $RebootRequired"
    } catch {
        Write-Log "Could not determine reboot status via Get-WURebootStatus: $($_.Exception.Message)" -Level Warning
        # Fallback: pending-file-rename / Component Based Servicing / WU flags
        $RebootRequired = (
            (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
            (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or
            ($null -ne (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue))
        )
        Write-Log "Reboot required (fallback check): $RebootRequired"
    }

    Write-Log "Windows Update run completed."

} catch {
    Write-Log "FATAL: $($_.Exception.Message)" -Level Error
    Write-Log "$($_.ScriptStackTrace)" -Level Error
    $ExitCode = 1
} finally {
    $EndDTM = Get-Date
    Write-Log ("Elapsed time: {0:N2} seconds ({1:N2} minutes)" -f `
        ($EndDTM - $StartDTM).TotalSeconds, ($EndDTM - $StartDTM).TotalMinutes)

    if ($ExitCode -eq 0 -and $RebootRequired) {
        $ExitCode = 3010   # success + reboot required (Intune/MSI convention)
        Write-Log "Scheduling automatic reboot in $RebootDelaySec second(s)..."
        try {
            # /t delay, /f force apps closed, /d planned:application:installation
            shutdown.exe /r /t $RebootDelaySec /f /d p:4:2 /c "Windows Update + drivers installed. Rebooting automatically."
            Write-Log "Reboot command issued."
        } catch {
            Write-Log "shutdown.exe failed ($($_.Exception.Message)). Falling back to Restart-Computer." -Level Warning
            Restart-Computer -Force
        }
    }

    Write-Log "===== WindowsUpdate.ps1 finished with exit code $ExitCode ====="
}

exit $ExitCode
