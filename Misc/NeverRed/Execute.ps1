Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Misc"
$Product = "NeverRed"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product PS Wrapper.log"

Start-Transcript $LogPS | Out-Null

Write-Verbose "Starting NeverRed" -Verbose
CD "C:\NeverRed-master"
.\NeverRed.ps1 -ESfile LastSetting.txt

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $([math]::Round( ($EndDTM-$StartDTM).TotalSeconds )) Seconds" -Verbose
Write-Verbose "Elapsed Time: $([math]::Round( ($EndDTM-$StartDTM).TotalMinutes )) Minutes" -Verbose
Stop-Transcript
