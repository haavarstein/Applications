Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Windows"
$Product = "SysinternalsSuite"
$Version = "1.0"
$InstallerType = "zip"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$url = "https://live.sysinternals.com/Files/SysinternalsSuite.zip"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile "${env:SystemRoot}\Temp\$Product.$InstallerType"
Expand-Archive -Path "${env:SystemRoot}\Temp\$Product.$InstallerType" -DestinationPath "${env:SystemRoot}\System32"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
