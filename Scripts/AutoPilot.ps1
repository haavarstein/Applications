# https://docs.microsoft.com/en-us/archive/blogs/mniehaus/speeding-up-windows-autopilot-for-existing-devices

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "AutoPilot"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product.log"

Start-Transcript $LogPS

Write-Verbose "Reading AutoPilot Configuration File" -Verbose
$config = Get-Content .\AutoPilotConfigurationFile.json | ConvertFrom-Json

Write-Verbose "Getting Computer Name" -Verbose
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$computerName = $tsenv.Value("_SMSTSMachineName")

Write-Verbose "Adding Computer Name to AutoPilot Configuration File" -Verbose
$config | Add-Member "CloudAssignedDeviceName" $computerName
$targetDrive = $tsenv.Value("OSDTargetSystemDrive")
$null = MkDir "$targetDrive\Windows\Provisioning\Autopilot" -Force
$destConfig = "$targetDrive\Windows\Provisioning\Autopilot\AutoPilotConfigurationFile.json"
$config | ConvertTo-JSON | Set-Content -Path $destConfig -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
