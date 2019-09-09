Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
$LogPS = "${env:SystemRoot}" + "\Temp\Install GPMC.log"

Start-Transcript $LogPS

Write-Verbose "Install GPMC Feature" -Verbose
Install-WindowsFeature GPMC

Write-Verbose "Get Installed GPMC Feature" -Verbose
Get-WindowsFeature GPMC

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
