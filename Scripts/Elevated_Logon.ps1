Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Set"
$Product = "Elevated Logon"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product.log"

Start-Transcript $LogPS

$MyConfigFileloc = ("$env:Settings\Applications\Settings.xml")
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$ElevatedUser = $MyConfigFile.Settings.MDT.ElevatedUser
$PasswordFile = $MyConfigFile.Settings.MDT.PasswordFile
$KeyFile = $MyConfigFile.Settings.MDT.KeyFile

Write-Verbose "Getting Encrypted Password from KeyFile" -Verbose
$SecurePassword = ((Get-Content $PasswordFile) | ConvertTo-SecureString -Key (Get-Content $KeyFile))
$SecurePasswordInMemory = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword) 
$PasswordAsString = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecurePasswordInMemory)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($SecurePasswordInMemory) 

Write-Verbose "Creating Elevated AutoLogon"
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d $ElevatedUser /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /t REG_SZ /d $env:USERDOMAIN /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d $PasswordAsString /f

#Start-Process "C:\Windows\System32\autologon.exe" -ArgumentList "/accepteula", $ElevatedUser, $env:USERDOMAIN, $PasswordAsString -Wait

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
