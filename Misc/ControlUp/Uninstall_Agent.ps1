$ServiceName = "cuagent"
Set-Service -Name $serviceName -StartupType Disabled -Status Stopped
(gwmi win32_service -filter "name='$serviceName'").delete()
taskkill /IM "cuAgent*" /F
remove-item -path "C:\Program Files\Smart-X" -Force -Recurse
Remove-Item -path "HKLM:\Software\Smart-X\*" -Recurse
Get-CimInstance -Class Win32_Product -Filter "Name='ControlUpAgent'" | Invoke-CimMethod -MethodName Uninstall
