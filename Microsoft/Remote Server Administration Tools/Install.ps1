Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
$LogPS = "${env:SystemRoot}" + "\Temp\Install RSAT.log"

Start-Transcript $LogPS

Write-Verbose "Install RSAT Features" -Verbose
Install-WindowsFeature RSAT-AD-Tools,RSAT-DHCP,RSAT-DNS-SERVER -IncludeAllSubFeature
Get-WindowsFeature RSAT* | Install-WindowsFeature

Write-Verbose "Get Installed RSAT Features" -Verbose
Get-WindowsFeature RSAT*

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
