# Determine where to do the logging
$logPS = "C:\Windows\Temp\Export_Wildcard_Certificate.log"

Write-Verbose "Loading Functions" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

<#
.Synopsis
   Export a PFX certificate to CRT + Key file
.DESCRIPTION
   Export a PFX certificate to CRT + Key file for use with for instance NetScaler and Cisco equipment
.EXAMPLE
   Export-CertificateToCRT -OpenSSLPath "D:\temp\export-certificatetocrt\openssl.exe" -PFXPath "D:\Shares\Wildcard.pfx" -PFXPassword "Password1" -ExportPassword "Password1" -OutputPath "D:\temp"
#>
function Export-CertificateToCRT
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Path to OpenSSL.exe file (Only directory path)
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
                   $OpenSSLPath,
        # Password for PFX and Export
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
                   [string]$PFXPassword,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
                   [string]$PFXPath,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
                   [string]$ExportPassword,
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
                   [string]$OutputPath
        
    )

    Begin {
        
    }
    Process {
        (Start-Process -FilePath "$OpenSSLPath" -ArgumentList "pkcs12 -in $PFXPath -nocerts -out $OutputPath\Wildcard-Encrypted.key -password pass:$PFXPassword -passout pass:$ExportPassword" -Wait).ExitCode
        (Start-Process -FilePath "$OpenSSLPath" -ArgumentList "pkcs12 -in $PFXPath -clcerts -nokeys -out $OutputPath\Wildcard-certificate.crt -password pass:$PFXPassword" -Wait).ExitCode
        (Start-Process -FilePath "$OpenSSLPath" -ArgumentList "rsa -in $OutputPath\Wildcard-Encrypted.key -out $OutputPath\Wildcard-decrypted.key -passin pass:$ExportPassword -passout pass:$ExportPassword" -Wait).ExitCode
        (Start-Process -FilePath "$OpenSSLPath" -ArgumentList "rsa -in $OutputPath\Wildcard-Encrypted.key -outform PEM -out $OutputPath\Wildcard-Encrypted-Pem.key -passout pass:$ExportPassword -passin pass:$ExportPassword" -Wait).ExitCode
        (Start-Process -FilePath "$OpenSSLPath" -ArgumentList "pkcs12 -export -in $OutputPath\Wildcard-certificate.crt -inkey $OutputPath\wildcard-Decrypted.key -out $OutputPath\Wildcard.p12 -passout pass:$ExportPassword" -Wait).ExitCode
        (Start-Process -FilePath "$OpenSSLPath" -ArgumentList "pkcs12 -in $OutputPath\Wildcard.p12 -nodes -out $OutputPath\Wildcard-temp.pem -password pass:$PFXPassword" -Wait).ExitCode
        Get-Content $OutputPath\Wildcard-temp.pem | Where { $_ -notmatch "^Bag A" -and $_ -notmatch "^*Microsoft" -and $_ -notmatch "^*localkey" -and $_ -notmatch "^*friendlyName" -and $_ -notmatch "^*X509v3" -and $_ -notmatch "^*1.3.6" -and $_ -notmatch "^*Key Attributes" -and $_ -notmatch "^*subject" -and $_ -notmatch "^*issuer" } | Set-Content $OutputPath\Wildcard.pem
        Remove-Item -Path $OutputPath\Wildcard-temp.pem -Force -Confirm:$false
    }
    End {
    }
}

Write-Verbose "Setting Arguments" -Verbose

$PFXPath = "\\DC-01"
$OpenSSLPath = "C:\Windows\Temp\OpenSSL\openssl.exe"

Write-Verbose "Downloading OpenSSL" -Verbose
$uri = "http://xenapptraining.s3.amazonaws.com/Hydration/OpenSSL.zip"
$PackageName = $uri.Substring($uri.LastIndexOf("/") + 1)
Invoke-WebRequest -Uri $uri -OutFile "$PackageName"
Expand-Archive -Path $PackageName -DestinationPath C:\Windows\Temp -Force

Write-Verbose "Export Certificate to Various File Formats" -Verbose
Export-CertificateToCRT -OpenSSLPath "$OpenSSLPath" -PFXPath "$PFXPath\XA\Certificates\Wildcard.pfx" -PFXPassword "poshacme" -ExportPassword "poshacme" -OutputPath "$PFXPath\XA\Certificates"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
