# Determine where to do the logging
$logPS = "C:\Windows\Temp\Configure_FAS.log"

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

Start-Transcript $LogPS

$ADCA = $MyConfigFile.Settings.Microsoft.ADCA

Add-PSSnapin Citrix.Authentication.FederatedAuthenticationService.V1

cd "C:\Program Files\Citrix\Federated Authentication Service\CertificateTemplates"

$template = [System.IO.File]::ReadAllBytes("$Pwd\Citrix_SmartcardLogon.certificatetemplate")
$CertEnrol = New-Object -ComObject X509Enrollment.CX509EnrollmentPolicyWebService
$CertEnrol.InitializeImport($template)
$comtemplate = $CertEnrol.GetTemplates().ItemByIndex(0)

$writabletemplate = New-Object -ComObject X509Enrollment.CX509CertificateTemplateADWritable
$writabletemplate.Initialize($comtemplate)
$writabletemplate.Commit(1, $NULL)  

$template = [System.IO.File]::ReadAllBytes("$Pwd\Citrix_RegistrationAuthority_ManualAuthorization.certificatetemplate")
$CertEnrol = New-Object -ComObject X509Enrollment.CX509EnrollmentPolicyWebService
$CertEnrol.InitializeImport($template)
$comtemplate = $CertEnrol.GetTemplates().ItemByIndex(0)

$writabletemplate = New-Object -ComObject X509Enrollment.CX509CertificateTemplateADWritable
$writabletemplate.Initialize($comtemplate)
$writabletemplate.Commit(1, $NULL)  

$template = [System.IO.File]::ReadAllBytes("$Pwd\Citrix_RegistrationAuthority.certificatetemplate")
$CertEnrol = New-Object -ComObject X509Enrollment.CX509EnrollmentPolicyWebService
$CertEnrol.InitializeImport($template)
$comtemplate = $CertEnrol.GetTemplates().ItemByIndex(0)

$writabletemplate = New-Object -ComObject X509Enrollment.CX509CertificateTemplateADWritable
$writabletemplate.Initialize($comtemplate)
$writabletemplate.Commit(1, $NULL)  

Invoke-Command -ComputerName $ADCA -ScriptBlock { Add-CATemplate -Name Citrix_SmartcardLogon -Force }
Invoke-Command -ComputerName $ADCA -ScriptBlock { Add-CATemplate -Name Citrix_RegistrationAuthority_ManualAuthorization -Force }
Invoke-Command -ComputerName $ADCA -ScriptBlock { Add-CATemplate -Name Citrix_RegistrationAuthority -Force }

$CitrixFasAddress=(Get-FasServer)[0].Address
$DefaultCA=(Get-FasMsCertificateAuthority -Default).Address
New-FasAuthorizationCertificate -CertificateAuthority $DefaultCA -CertificateTemplate "Citrix_RegistrationAuthority" -AuthorizationTemplate "Citrix_RegistrationAuthority_ManualAuthorization"

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
