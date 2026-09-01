<#
.SYNOPSIS
    Installs Windows Updates and driver updates with PSWindowsUpdate,
    then reboots ONLY if the PSWindowsUpdate module says a reboot is required.

.DESCRIPTION
    Based on haavarstein/Applications Scripts/WindowsUpdate.ps1.

    Behaviour:
      - Includes Drivers (original script used -NotCategory "Drivers")
      - Does NOT use registry / PnP heuristics for reboot
      - Reboots only when PSWindowsUpdate reports RebootRequired:
          1) RebootRequired on objects returned by Get-WindowsUpdate -Install
          2) Get-WURebootStatus -Silent

    Designed to run elevated (Administrator or SYSTEM).
    For Intune platform scripts enable "Run script in 64-bit PowerShell".

.NOTES
    Log: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\WindowsUpdate.log
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

function Write-LogDivider {
    param([string]$Title)
    Write-Log ("-" * 72)
    if ($Title) { Write-Log $Title }
}

function Write-LogObjectList {
    param(
        [object[]]$InputObject,
        [string]$EmptyMessage = "  (none)"
    )
    if (-not $InputObject -or @($InputObject).Count -eq 0) {
        Write-Log $EmptyMessage
        return
    }
    foreach ($item in @($InputObject)) {
        $kb     = if ($item.PSObject.Properties['KB']     -and $item.KB)     { $item.KB }     else { '-' }
        $size   = if ($item.PSObject.Properties['Size']   -and $item.Size)   { $item.Size }   else { '-' }
        $result = if ($item.PSObject.Properties['Result'] -and $item.Result) { $item.Result } else { '-' }
        $title  = if ($item.PSObject.Properties['Title']  -and $item.Title)  { $item.Title }  else { [string]$item }
        $reboot = $null
        if ($item.PSObject.Properties['RebootRequired']) { $reboot = [string]$item.RebootRequired }
        $category = '-'
        if ($item.PSObject.Properties['Categories'] -and $item.Categories) {
            $category = ($item.Categories | ForEach-Object { $_.Name }) -join ', '
        } elseif ($item.PSObject.Properties['Category'] -and $item.Category) {
            $category = [string]$item.Category
        }
        Write-Log ("  KB={0,-12} Result={1,-16} RebootRequired={2,-6} Size={3,-10} Category={4}" -f $kb, $result, $(if ($null -ne $reboot) { $reboot } else { 'n/a' }), $size, $category)
        Write-Log ("    Title: {0}" -f $title)
    }
}
#endregion

#region PSWindowsUpdate reboot helpers
function Convert-ToExplicitBoolean {
    param([object]$Value)
    if ($null -eq $Value) { return $false }
    if ($Value -is [bool]) { return $Value }
    if ($Value -is [int] -or $Value -is [long]) { return [bool]$Value }
    $text = [string]$Value
    if ($text -match '^(True|Yes|1)$') { return $true }
    if ($text -match '^(False|No|0)$') { return $false }
    return $false
}

function Test-PSWindowsUpdateRebootRequired {
    <#
        Returns reboot decision based ONLY on PSWindowsUpdate:
          - RebootRequired on each installed-update object
          - Get-WURebootStatus (-Silent, and object form if present)
    #>
    param([object[]]$InstallResults)

    $reasons = New-Object System.Collections.Generic.List[string]
    $statusDump = New-Object System.Collections.Generic.List[string]

    Write-Log "Evaluating reboot requirement using PSWindowsUpdate only."
    Write-Log "Sources used: install-result.RebootRequired + Get-WURebootStatus."
    Write-Log "Sources NOT used: registry keys, PendingFileRenameOperations, PnP problem codes."

    $fromResults = $false
    $resultCount = @($InstallResults).Count
    Write-Log "Install-result objects to inspect: $resultCount"

    foreach ($u in @($InstallResults)) {
        if (-not $u) { continue }
        $title = if ($u.Title) { $u.Title } elseif ($u.KB) { $u.KB } else { '<untitled update>' }
        $hasProp = [bool]($u.PSObject.Properties['RebootRequired'])
        $raw = if ($hasProp) { $u.RebootRequired } else { $null }
        $flag = if ($hasProp) { Convert-ToExplicitBoolean $raw } else { $false }

        $statusDump.Add(("  result reboot flag: Title='{0}' PropertyPresent={1} RawValue='{2}' Parsed={3}" -f $title, $hasProp, $(if ($null -eq $raw) { '<missing>' } else { $raw }), $flag))

        if ($flag) {
            $fromResults = $true
            $reasons.Add("Install result RebootRequired=True: $title")
        }
    }

    $fromStatusCmd = $false
    $statusRaw = $null
    Write-Log "Calling Get-WURebootStatus -Silent (module's official reboot check)..."
    try {
        $statusRaw = Get-WURebootStatus -Silent
        $statusType = if ($null -eq $statusRaw) { '<null>' } else { $statusRaw.GetType().FullName }
        Write-Log "Get-WURebootStatus -Silent raw type : $statusType"
        Write-Log "Get-WURebootStatus -Silent raw value: $statusRaw"

        if ($statusRaw -is [bool] -or $statusRaw -is [int] -or $statusRaw -is [string]) {
            $fromStatusCmd = Convert-ToExplicitBoolean $statusRaw
            Write-Log "Interpreted Get-WURebootStatus -Silent as boolean: $fromStatusCmd"
        } elseif ($null -ne $statusRaw) {
            # Newer module builds sometimes return an object even with -Silent
            $propNames = ($statusRaw.PSObject.Properties.Name) -join ', '
            Write-Log "Get-WURebootStatus returned an object. Properties: $propNames"
            if ($statusRaw.PSObject.Properties['RebootRequired']) {
                $fromStatusCmd = Convert-ToExplicitBoolean $statusRaw.RebootRequired
                Write-Log "Object.RebootRequired raw='$($statusRaw.RebootRequired)' parsed=$fromStatusCmd"
            } else {
                $fromStatusCmd = Convert-ToExplicitBoolean $statusRaw
                Write-Log "No RebootRequired property; fell back to string parse: $fromStatusCmd"
            }
            if ($statusRaw.PSObject.Properties['RebootScheduled']) {
                Write-Log "Object.RebootScheduled = $($statusRaw.RebootScheduled)"
            }
            if ($statusRaw.PSObject.Properties['ComputerName']) {
                Write-Log "Object.ComputerName = $($statusRaw.ComputerName)"
            }
        } else {
            Write-Log "Get-WURebootStatus -Silent returned null. Treating as False." -Level Warning
        }
    } catch {
        Write-Log "Get-WURebootStatus -Silent failed: $($_.Exception.Message)" -Level Warning
        Write-Log "Will rely on install-result.RebootRequired only." -Level Warning
    }

    if ($fromStatusCmd) {
        $reasons.Add('Get-WURebootStatus reported RebootRequired=True')
    }

    # Non-silent object form, if available, for extra log detail only
    try {
        $statusObj = Get-WURebootStatus | Select-Object -First 1
        if ($statusObj -and $statusObj.PSObject.Properties['RebootRequired']) {
            Write-Log "Get-WURebootStatus (object) RebootRequired   = $($statusObj.RebootRequired)"
            if ($statusObj.PSObject.Properties['RebootScheduled']) {
                Write-Log "Get-WURebootStatus (object) RebootScheduled  = $($statusObj.RebootScheduled)"
            }
        }
    } catch {
        Write-Log "Optional object-form Get-WURebootStatus not available: $($_.Exception.Message)"
    }

    foreach ($line in $statusDump) { Write-Log $line }

    $required = ($fromResults -or $fromStatusCmd)
    Write-Log "Module reboot decision: fromInstallResults=$fromResults ; fromGetWURebootStatus=$fromStatusCmd ; FINAL=$required"

    [pscustomobject]@{
        RebootRequired     = $required
        FromInstallResults = $fromResults
        FromWURebootStatus = $fromStatusCmd
        Reasons            = $reasons
    }
}
#endregion

$StartDTM       = Get-Date
$ExitCode       = 0
$RebootRequired = $false
$RebootDelaySec = 60
$installResult  = @()
$available      = @()

$ConfirmPreference = 'None'

Write-LogDivider
Write-Log "===== WindowsUpdate.ps1 started ====="
Write-Log "Goal            : install software + driver updates from Microsoft Update"
Write-Log "Reboot policy   : reboot ONLY if PSWindowsUpdate says RebootRequired"
Write-Log "Log file        : $LogFile"
Write-Log "Running as      : $([Security.Principal.WindowsIdentity]::GetCurrent
