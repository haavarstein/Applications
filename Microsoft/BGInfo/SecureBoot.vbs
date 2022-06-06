Const HKEY_LOCAL_MACHINE = &H80000002 
strComputer = "."  
hDefKey = HKEY_LOCAL_MACHINE
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv") 
strKeyPath = "SYSTEM\CurrentControlSet\Control\SecureBoot\State" 
strValueName = "UEFISecureBootEnabled" 
oReg.GetDWORDValue hDefKey,strKeyPath,strValueName,dwValue 

If dwValue = 0 Then 
	Echo "OFF"
ElseIf dwValue = 1 Then 
	Echo "ON"
Else
	Echo "NA"
End If
