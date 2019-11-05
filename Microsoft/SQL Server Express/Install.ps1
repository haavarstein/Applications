# PowerShell Wrapper for MDT, Standalone and Chocolatey Installation - (C)2015 xenappblog.com 

# Example 1: Start-Process "XenDesktopServerSetup.exe" -ArgumentList $unattendedArgs -Wait -Passthru

# Example 2 Powershell: Start-Process powershell.exe -ExecutionPolicy bypass -file $Destination

# Example 3 EXE (Always use ' '):
# $UnattendedArgs='/qn'
# (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

# Example 4 MSI (Always use " "):
# $UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
# (Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "SQL Server Express"
$Version = "2017"
$PackageName = "SQLEXPR_x64_ENU"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$URL = "https://download.microsoft.com/download/E/F/2/EF23C21D-7860-4F05-88CE-39AA114B014B/SQLEXPR_x64_ENU.exe"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

Write-Verbose "Setting Options" -Verbose

$OPTIONS = ""
$OPTIONS += " /Q"
$OPTIONS += " /ACTION=`"Install`""
$OPTIONS += " /FEATURES=`"SQL`"" 
$OPTIONS += " /INSTANCENAME=`"SQLEXPRESS`""
$OPTIONS += " /SQLSVCACCOUNT=`"NT AUTHORITY\NETWORK SERVICE`""
$OPTIONS += " /SQLSYSADMINACCOUNTS=`"$env:userdnsdomain\Administrator`" `"BUILTIN\Administrators`""
$OPTIONS += " /AGTSVCACCOUNT=`"NT AUTHORITY\NETWORK SERVICE`""
$OPTIONS += " /BROWSERSVCSTARTUPTYPE=`"Automatic`""
$OPTIONS += " /IACCEPTSQLSERVERLICENSETERMS"

If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null}
 
CD $Version
 
Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source}

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $Options -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
