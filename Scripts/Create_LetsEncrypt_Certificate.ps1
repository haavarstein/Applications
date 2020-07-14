# Determine where to do the logging
$logPS = "C:\Windows\Temp\Create_LetsEncrypt_Certificate.log"
 
Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

Write-Verbose "Installing Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name Posh-ACME)) {Install-Module Posh-ACME -Force | Import-Module Posh-ACME}
 
Start-Transcript $LogPS

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$CertFQDN = "*.desktopanywhere.io"
$API = $MyConfigFile.Settings.LE.API
$Email = $MyConfigFile.Settings.LE.Email
$SecureAPI = $API | ConvertTo-SecureString -asPlainText -Force

Write-Verbose "Requesting Certificate for $CertFQDN" -Verbose
New-PACertificate $CertFQDN -Contact $email -AcceptTOS -DnsPlugin CloudFlare -PluginArgs @{ CFToken = $SecureAPI } -Install

Write-Host "Exporting Certificate"
$OutPath = "$env:XA\Certificates"
$Cert = Get-PACertificate
$Cert.Thumbprint | Out-File $OutPath\Wildcard.txt

Copy-Item -Path $cert.PfxFile -Destination $OutPath\Wildcard.pfx
Copy-Item -Path $cert.CertFile -Destination $OutPath\Wildcard.cer
Copy-Item -Path $cert.KeyFile -Destination $OutPath\Wildcard.key
Copy-Item -Path $cert.ChainFile -Destination $OutPath\Chain.cer
Copy-Item -Path $cert.FullChainFile -Destination $OutPath\FullChain.cer
Copy-Item -Path $cert.PfxFullChain -Destination $OutPath\FullChain.pfx

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
