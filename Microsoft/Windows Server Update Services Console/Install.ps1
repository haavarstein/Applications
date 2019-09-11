Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
$LogPS = "${env:SystemRoot}" + "\Temp\Install WSUS Console.log"

Start-Transcript $LogPS

Write-Verbose "Install WSUS Console Feature" -Verbose
Install-WindowsFeature -Name UpdateServices-Ui

Write-Verbose "Get Installed WSUS Console Feature" -Verbose
Get-WindowsFeature UpdateServices-Ui

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
