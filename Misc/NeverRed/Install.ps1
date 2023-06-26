# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 REBOOT=ReallySuppress /norestart /qn /L*V `"$LogApp`""
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Write-Verbose "Installing Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}
Update-Module Evergreen

$Vendor = "Misc"
$Product = "NeverRed"
$PackageName = "NeverRed"
$URL = "https://codeload.github.com/Deyda/NeverRed/zip/refs/heads/master"
$InstallerType = "zip"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$ProgressPreference = 'SilentlyContinue'
$UnattendedArgs = '/S'

Start-Transcript $LogPS | Out-Null

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source}
        
Write-Verbose "Extracting $Vendor $Product $Version" -Verbose
Expand-Archive -Path $Source -DestinationPath C:\ -Force

Write-Verbose "Customization" -Verbose
Copy-Item -Path .\LastSetting.txt -Destination "C:\NeverRed-master" -Force
Copy-Item -Path .\Execute.ps1 -Destination "C:\NeverRed-master" -Force

Write-Verbose "Creating Scheduled Task" -Verbose

$TaskName = "NeverRed"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NonInteractive -NoLogo -NoProfile -File ""C:\NeverRed-master\Execute.ps1"""
$Trigger = New-ScheduledTaskTrigger -Daily -At 3am
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet
$Config = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal


if(Get-ScheduledTask $TaskName -ErrorAction Ignore) { 
    Write-Verbose "$TaskName Scheduled Task Exist" -Verbose
    }
else { 
    Write-Verbose "$TaskName Scheduled Task Do Not Exist - Creating" -Verbose
    Register-ScheduledTask -TaskName $TaskName -InputObject $Config
}

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $([math]::Round( ($EndDTM-$StartDTM).TotalSeconds )) Seconds" -Verbose
Write-Verbose "Elapsed Time: $([math]::Round( ($EndDTM-$StartDTM).TotalMinutes )) Minutes" -Verbose
Stop-Transcript | Out-Null
