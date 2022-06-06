Const HKEY_LOCAL_MACHINE  = &H80000002
strComputer = "."
hDefKey = HKEY_LOCAL_MACHINE
strKeyPath = "SYSTEM\CurrentControlSet\Control\SecureBoot\State"
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

If oReg.EnumKey(hDefKey, strKeyPath, arrSubKeys) = 0 Then
  echo "UEFI"
Else
  echo "BIOS"
End If