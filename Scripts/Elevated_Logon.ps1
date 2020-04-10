# Use the Automation Framework PowerShell Module to create an enncrypted key file
# Get-Help Protect-Passowrd -Examples
# Protect-Password
# Copy the 2 key files to .\Applications\Scripts and change line 16-18

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Enable"
$Product = "Elevated Logon"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product.log"

Start-Transcript $LogPS

$ElevatedUser = "xenappblog\svc-elevated"
$PasswordFile = "elevated.txt"
$KeyFile = "elevated.key"

Write-Verbose "Getting Encrypted Password from KeyFile" -Verbose
$SecurePassword = ((Get-Content $PasswordFile) | ConvertTo-SecureString -Key (Get-Content $KeyFile))
$SecurePasswordInMemory = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword) 
$PasswordAsString = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecurePasswordInMemory)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($SecurePasswordInMemory) 

Write-Verbose "Creating Elevated AutoLogon" -Verbose
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d $ElevatedUser /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /t REG_SZ /d $env:USERDOMAIN /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d $PasswordAsString /f

Write-Verbose "Adding $ElevatedUser to Local Admin Group" -Verbose
Add-LocalGroupMember -Group "Administrators" -Member $ElevatedUser

Write-Verbose "Disable UAC temporarily" -Verbose
reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
