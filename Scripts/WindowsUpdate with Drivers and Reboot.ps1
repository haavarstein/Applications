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
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Scope AllUsers -Confirm:$false -ErrorAction
