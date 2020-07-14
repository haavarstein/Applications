Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$PackageName = "Import and Bind Certificate"
$LogPS = "${env:SystemRoot}" + "\Temp\$PackageName PS Wrapper.log"

$Domain = $env:USERDOMAIN
$DomainFQDN = $env:USERDNSDOMAIN
$Certificates = $MyConfigFile.Settings.Microsoft.Certificates

Start-Transcript $LogPS

Install-WindowsFeature -Name Web-Server -IncludeManagementTools
copy-item "$Certificates\Wildcard.pfx" -Destination C:\Windows\Temp\wildcard.pfx 
copy-item "$Certificates\Wildcard.txt" -Destination C:\Windows\Temp\wildcard.txt

import-module webadministration
$PFXPath="C:\Windows\Temp\wildcard.pfx"
$PFXPassword="poshacme"
$strThumb = Get-Content C:\Windows\Temp\wildcard.txt
 
certutil -f -importpfx -p $PFXPassword $PFXPath

Remove-Item C:\Windows\Temp\wildcard.txt -Force

Push-Location IIS:
cd SslBindings
New-webBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https
get-item cert:\LocalMachine\MY\$strThumb | new-item 0.0.0.0!443
Pop-Location

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
