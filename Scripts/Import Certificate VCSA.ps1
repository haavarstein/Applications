# Determine where to do the logging
$logPS = "C:\Windows\Temp\Import Certificate VCSA OCP.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$VCenter = $MyConfigFile.Settings.VMware.VCenter
$VCenterSDK = "https://" + "$VCenter" + "/sdk"
$uri = "https://" + "$VCenter" + "/certs/download.zip"
$certpath = "C:\Windows\Temp\certs\win\"

# Could not establish trust relationship for the SSL/TLS Secure Channel – Invoke-WebRequest
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Download and Extract Certificate
$PackageName = $uri.Substring($uri.LastIndexOf("/") + 1)
Invoke-WebRequest -Uri $uri -OutFile "${env:SystemRoot}\Temp\$PackageName" -UseBasicParsing
Expand-Archive -Path "${env:SystemRoot}\Temp\$PackageName" -DestinationPath "${env:SystemRoot}\Temp" -Force

# Find SSL certificates ending with .crt
$Dir = get-childitem "${env:SystemRoot}\Temp\certs\win" -recurse
$File = $Dir | where {$_.extension -eq ".crt"}
$Cert = $File.Name

# Import Certificate to Trusted People"
CERTUTIL -addstore -enterprise -f -v root $certpath\$Cert
CERTUTIL -addstore -f "TRUSTEDPEOPLE" $certpath\$Cert

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
