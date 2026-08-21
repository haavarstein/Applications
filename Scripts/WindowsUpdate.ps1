<#
.SYNOPSIS
    Installs pending Windows Updates via PSWindowsUpdate. Designed to run as an Intune
    Platform Script (executes as SYSTEM, no logged-on user).

.NOTES
    Fixed version - changes from the original are documented inline as "FIX:" comments.
    Log file: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WindowsUpdate.log
#>

# FIX: Intune runs platform scripts as SYSTEM. If the "Run script in 64-bit PowerShell
# Host" option is left at its default (No/32-bit) on a 64-bit OS, modules installed by
# the 64-bit engine (which is what actually owns C:\Program Files\WindowsPowerShell)
# won't be found by a 32-bit host, and vice versa. Make sure that setting is enabled
# on the script/app in Intune. This script cannot change that setting itself.

#region Logging setup
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
    } catch {
        # Logging must never crash the script.
    }
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error'   { Write-Error $Message -ErrorAction Continue }
        default   { Write-Verbose $Message -Verbose }
    }
}
#endregion

$StartDTM = Get-Date
$ExitCode = 0
$RebootRequired = $false

# FIX: This is what actually caused the original failure. Running as SYSTEM via Intune
# gives the script no console to answer prompts on, so ANY cmdlet that asks for
# confirmation (e.g. "Do you want PowerShellGet to install and import the NuGet
# provider now? [Y] Yes [N] No [S] Suspend") just hangs until Intune's timeout kills
# the process and reports a failure. Force every confirmation prompt off for the whole
# script as a safety net, on top of the -Force/-ForceBootstrap flags used below.
$ConfirmPreference = 'None'

Write-Log "===== WindowsUpdate.ps1 started ====="
Write-Log "Running as: $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Log "PowerShell version: $($PSVersionTable.PSVersion) | Is64BitProcess: $([Environment]::Is64BitProcess)"

try {

    # FIX: PSGallery requires TLS 1.2. On a fresh SYSTEM session TLS 1.2 is not always
    # negotiated by default, which makes Install-Module / Find-PackageProvider fail
    # with "Unable to connect" or "could not establish trust relationship" errors.
    # This was the most likely single cause of the original failure.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Write-Log "TLS 1.2 enabled for this session."
    } catch {
        Write-Log "Could not force TLS 1.2: $($_.Exception.Message)" -Level Warning
    }

    # FIX: Check/bootstrap the NuGet provider using Get-PackageProvider instead of a
    # brittle folder path test (the folder layout includes a version sub-folder and
    # doesn't reliably indicate a working provider).
    $nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue
    if (-not $nuget) {
        Write-Log "NuGet provider not found. Bootstrapping..."
        try {
            # FIX: -ForceBootstrap is what actually suppresses the "Do you want
            # PowerShellGet to install and import the NuGet provider now?" prompt seen
            # in the failed run - -Force alone does not cover the bootstrap-consent
            # prompt, only the "are you sure" prompt for the package itself.
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Scope AllUsers -Confirm:$false -ErrorAction Stop | Out-Null
            Write-Log "NuGet provider installed."
        } catch {
            Write-Log "Failed to install NuGet provider: $($_.Exception.Message)" -Level Error
            throw
        }
    } else {
        Write-Log "NuGet provider already present."
    }

    try {
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction Stop
        Write-Log "PSGallery set to Trusted."
    } catch {
        Write-Log "Could not set PSGallery to Trusted: $($_.Exception.Message)" -Level Warning
    }

    # FIX: Original logic only ran Import-Module inside the "not installed" branch, via
    # `Install-Module ... | Import-Module ...`. Install-Module produces no pipeline
    # output by default, and if the module was ALREADY installed (Get-Module
    # -ListAvailable returned something), Import-Module was never called at all - the
    # rest of the script then called Get-WindowsUpdate against a module that might not
    # be loaded in the session. Now install (if missing) and import are separate,
    # unconditional steps.
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "PSWindowsUpdate module not found. Installing..."
        Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false -ErrorAction Stop
        Write-Log "PSWindowsUpdate module installed."
    } else {
        Write-Log "PSWindowsUpdate module already installed."
    }
    Import-Module -Name PSWindowsUpdate -Force -ErrorAction Stop
    Write-Log "PSWindowsUpdate module imported."

    # FIX: Removed the unused Evergreen module install/update. It was never referenced
    # anywhere else in the script, but a failure inside `Update-Module -Name Evergreen
    # -Force` (e.g. Evergreen not actually installed, or a PSGallery hiccup) would throw
    # a terminating error and abort the whole script before Windows Update ever ran.
    # Re-add it deliberately if something else in your environment depends on it.

    Write-Log "Checking Windows Update service ($([string]'wuauserv'))..."
    try {
        Set-Service -Name 'wuauserv' -StartupType Automatic -ErrorAction Stop
        Start-Service -Name 'wuauserv' -ErrorAction Stop
        Write-Log "Windows Update service is running."
    } catch {
        Write-Log "Could not start Windows Update service: $($_.Exception.Message)" -Level Error
        throw
    }

    Write-Log "Removing FSLogix rule files (if any)..."
    Remove-Item -Path "C:\Program Files\FSLogix\Apps\Rules\*.*" -Force -Recurse -ErrorAction SilentlyContinue

    Write-Log "Scanning for available updates from Microsoft Update..."
    try {
        $available = Get-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -ComputerName localhost -ErrorAction Stop
        if ($available) {
            $available | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_ }
            Write-Log "Found $(@($available).Count) update(s)."
        } else {
            Write-Log "No applicable updates found."
        }
    } catch {
        Write-Log "Update scan failed: $($_.Exception.Message)" -Level Error
        throw
    }

    if ($available) {
        Write-Log "Installing available updates..."
        try {
            $installResult = Get-WindowsUpdate -NotCategory "Drivers" -MicrosoftUpdate -ComputerName localhost -Install -AcceptAll -IgnoreReboot -ErrorAction Stop
            $installResult | Format-Table -AutoSize | Out-String | ForEach-Object { Write-Log $_ }
        } catch {
            Write-Log "Update install failed: $($_.Exception.Message)" -Level Error
            throw
        }
    }

    # Surface whether a reboot is now pending so Intune can report 3010 (soft reboot).
    try {
        $rebootStatus = Get-WURebootStatus -Silent
        $RebootRequired = [bool]$rebootStatus
        Write-Log "Reboot required: $RebootRequired"
    } catch {
        Write-Log "Could not determine reboot status: $($_.Exception.Message)" -Level Warning
    }

    Write-Log "Windows Update run completed successfully."

} catch {
    Write-Log "FATAL: $($_.Exception.Message)" -Level Error
    Write-Log ($_.ScriptStackTrace) -Level Error
    $ExitCode = 1
} finally {
    $EndDTM = Get-Date
    Write-Log ("Elapsed time: {0:N2} seconds ({1:N2} minutes)" -f ($EndDTM - $StartDTM).TotalSeconds, ($EndDTM - $StartDTM).TotalMinutes)
    if ($ExitCode -eq 0 -and $RebootRequired) {
        # 3010 = success, soft reboot required (standard Intune/MSI convention).
        $ExitCode = 3010
    }
    Write-Log "===== WindowsUpdate.ps1 finished with exit code $ExitCode ====="
}

exit $ExitCode
