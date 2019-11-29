Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
$LogPS = "${env:SystemRoot}" + "\Temp\Microsoft Active Directory Certificate Services.log"

Start-Transcript $LogPS

Write-Verbose "Install AD-Certificate Features" -Verbose
Install-WindowsFeature AD-Certificate
Install-AdcsCertificationAuthority -Force
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Install-WindowsFeature -Name RSAT-ADCS -IncludeManagementTools

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
