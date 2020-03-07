# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 
# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru
# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination
# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Adobe"
$Product = "Acrobat Pro"
$PackageName = "AcroPro"
$Version = "17.011.30138"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$MST = "AcroPro.mst"
$MSP1 = "Acrobat2017Upd1701130138.msp"
$MSP2 = "Acrobat2017Upd1701130140_incr.msp"
$UnattendedArgs = "/i $PackageName.$InstallerType TRANSFORMS=$MST IGNOREVCRT64=1 ALLUSERS=1 /qn /liewa $LogApp"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS | Out-Null

CD $Version

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Patching $Vendor $Product" -Verbose
$UnattendedArgs1 = "/p $MSP1 /norestart /qn /liewa ${env:SystemRoot}\Temp\$MSP.log"
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs1 -Wait -Passthru).ExitCode

Write-Verbose "Patching $Vendor $Product" -Verbose
$UnattendedArgs2 = "/p $MSP2 /norestart /qn /liewa ${env:SystemRoot}\Temp\$MSP.log"
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs2 -Wait -Passthru).ExitCode

Write-Verbose "Customization and Active License" -Verbose
Unregister-ScheduledTask -TaskName "Adobe Acrobat Update Task" -Confirm:$false
sc.exe config AdobeARMservice start= disabled
#.\adobe_prtk.exe --tool=Serialize --leid="V7{}AcrobatESR-17-Win-GM" --serial="1118-1264-1730-5471-8265-9270" --regsuppress=ss --eulasuppress
#.\adobe_prtk.exe --tool=VolumeSerialize --generate --serial="1118-1264-1730-5471-8265-9270" --leid="V7{}AcrobatESR-17-Win-GM" --regsuppress=ss --eulasuppress --provfile=prov.xml
Copy-Item prov.xml -Destination "C:\Program Files (x86)\Adobe\Acrobat 2017"
.\adobe_prtk.exe --tool=VolumeSerialize --provfile="C:\Program Files (x86)\Adobe\Acrobat 2017\prov.xml" --stream

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript  | Out-Null
