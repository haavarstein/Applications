Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "Activate KMS License"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product PS Wrapper.log"

Start-Transcript $LogPS

Write-Verbose "Activate KMS License" -Verbose
slmgr //B /ato
start-sleep -s 15

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
