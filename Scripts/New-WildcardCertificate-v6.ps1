# Determine where to do the logging
$logPS = "C:\Windows\Temp\Configure_Wildcard_Certificate.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
Start-Transcript $LogPS

$PFXPath = "\\DC-01"
$PFXFile = "$PFXPath\xa\Certificates\" + "Wildcard.txt"

<#
.Synopsis
   Automate the creation of wildcard certificates
.DESCRIPTION
   This script can automate the creation of wildcard certificates from an internal PKI infrastructure.
   The output PFX file will not have a password and it will be placed in the folder the PS1 script is located.
   You will need to have the SSL.INI file in the same folder as this script and you will need to run the script as a domain users.
   Use the function within this script by editing the line in the buttom.
.PARAMETER Path
  Path to where temporary files are stored
.PARAMETER PFXPath
  Path to where the PFX file is exported
.PARAMETER CAName
  Name of the Certificate authority    
.EXAMPLE
   New-WildcardCertificate
.EXAMPLE
   New-WildcardCertificate -Path C:\Temp -PFXPath "\\FILE01\Certificates" 
.EXAMPLE
   New-WildcardCertificate -Path C:\Temp -PFXPath "\\FILE01\Certificates" -CAName "DC01.Domain.Com\Domain-DC01-CA"
#>
Function New-WildcardCertificate {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$False,Position=1)]
       [string]$Path = "C:\Windows\Temp",
       [Parameter(Mandatory=$False,Position=2)]
       [string]$PFXPath	= ".",
       [Parameter(Mandatory=$False,Position=3)]
       [string]$CAName,
       [Parameter(Mandatory=$False,Position=4)]
       [string]$Password
    )
    Begin {
        $Domain = (Get-ItemProperty -path hklm:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name Domain).Domain
        If (!(Test-Path -Path $PSScriptRoot\ssl.ini)) {
            Write-Host "You don't have the SSL.INI file that is required to run this script" -ForegroundColor Red
            Break;
        }
        If (!(Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory
        }
        (Get-Content $PSScriptRoot\ssl.ini) | Foreach-Object {$_ -replace 'ServerFQDN',"*.$Domain"}  | Out-File .\Wildcard.ini
    }
    Process {
        If ($CAName -eq "") {
            Write-Verbose "Finding certificate authority"
            $CA = New-Object -ComObject CertificateAuthority.Config
            $CAName = $CA.GetConfig(0)            
        }
        Write-Verbose "Requesting certificate" 
        & c:\windows\system32\certreq.exe –new "Wildcard.ini" "$Path\wildcard.req"
        & c:\windows\system32\certreq.exe -config "$CAName" –submit "$Path\wildcard.req" "$Path\wildcard.cer"
 
        Write-Verbose "Installing certificate" 
        & c:\windows\system32\certreq.exe –accept "$Path\wildcard.cer"
 
        Write-Verbose "Exporting certificate and private key"
        $PFXPassword = ConvertTo-SecureString -String $Password -Force -AsPlainText
        $cert = new-object security.cryptography.x509certificates.x509certificate2 -arg "$Path\wildcard.cer"
        Get-item cert:\localmachine\my\$($cert.Thumbprint) | Export-PfxCertificate -FilePath "$PFXPath\Wildcard.pfx" -Password $PFXPassword 
        Write-Verbose "Certificate successfully exportert to wildcard.pfx"
    }   
    End {
        Write-Verbose "deleting exported certificat from computer store"
        Remove-Item -Path cert:\localmachine\my\$($Cert.Thumbprint) -DeleteKey 
        Remove-Item -Path $Path\wildcard.cer -Force
        Remove-Item -Path $Path\wildcard.req -Force
        Remove-Item -Path $Path\wildcard.rsp -Force
    }
}

New-WildcardCertificate -Path C:\Install -PFXPath "$PFXPath\xa\Certificates\" -Password "P@ssw0rd" -Verbose 

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
