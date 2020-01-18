# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "Edge Enterprise x64"
$Version = "79.0.309.68"
$PackageName = "MicrosoftEdgeEnterpriseX64"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
$Url = "http://dl.delivery.mp.microsoft.com/filestreamingservice/files/c39f1d27-cd11-495a-b638-eac3775b469d/MicrosoftEdgeEnterpriseX64.msi"

Start-Transcript $LogPS

If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null}

CD $Version

If (!(Test-Path -Path $Source)) {Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source}

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Copy Preferences File" -Verbose
CD..
Copy-Item -Path .\master_preferences -Destination "C:\Program Files (x86)\Microsoft\Edge\Application\master_preferences" -Recurse -Force

Write-Verbose "Stop and disable Microsoft Edge services" -Verbose
$Services = "edgeupdatem","edgeupdate","MicrosoftEdgeElevationService"
ForEach ($Service in $Services)
{
If ((Get-Service -Name $Service).Status -eq "Stopped")
{
Set-Service -Name $Service -StartupType Disabled
}
else
{
Stop-Service -Name $Service -Force -Verbose
Set-Service -Name $Service -StartupType Disabled
}
}

Write-Verbose "Delete Microsoft Edge scheduled tasks" -Verbose
$EdgeScheduledTasks = "MicrosoftEdgeUpdateTaskMachineCore","MicrosoftEdgeUpdateTaskMachineUA"
ForEach ($Task in $EdgeScheduledTasks)
{
Unregister-ScheduledTask -TaskName $Task -Confirm:$false
}

Write-Verbose "Fix Citrix API Hook" -Verbose
$RegPath = "HKLM:SYSTEM\CurrentControlSet\services\CtxUvi"
$RegName = "UviProcessExcludes"
$EdgeRegvalue = "msedge.exe"

# Get current values in UviProcessExcludes
$CurrentValues = Get-ItemProperty -Path $RegPath | Select-Object -ExpandProperty $RegName
# Add the msedge.exe value to existing values in UviProcessExcludes
Set-ItemProperty -Path $RegPath -Name $RegName -Value "$CurrentValues$EdgeRegvalue;"

Write-Verbose "Remove Shortcut from Public Desktop" -Verbose
Remove-Item -Path "$env:PUBLIC\Desktop\Microsoft Edge.lnk"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
