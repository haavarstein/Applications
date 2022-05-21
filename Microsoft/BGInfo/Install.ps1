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

$Vendor = "Microsoft"
$Product = "BGInfo"
$PackageName = "BGInfo64"
$InstallerType = "exe"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$UnattendedArgs = "Bginfo64-Win10.bgi /nolicprompt /silent /timer:0"
$val = Get-ItemProperty -Path "hklm:software\microsoft\windows nt\currentversion\" -Name "InstallationType"
$Path = "C:\Program Files\BGInfo"

IWR -UseBasicParsing -Uri "https://download.sysinternals.com/files/BGInfo.zip" -OutFile BGInfo.zip
Expand-Archive -Path BGInfo.zip -DestinationPath . -Force

Start-Transcript $LogPS

if($val.InstallationType -eq 'Server')
{
    Write-Verbose "Starting Installation of $Vendor $Product" -Verbose
    If (!(Test-Path -Path $Path)) { New-Item -ItemType directory -Path $Path | Out-Null }
    Copy-Item -Path . -Destination "C:\Program Files\" -Recurse -Force
    CD $Path
    
    (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

    Write-Verbose "Customization" -Verbose
    $Shell = New-Object -ComObject ("WScript.Shell")
    $ShortCut = $Shell.CreateShortcut($env:PROGRAMDATA  + "\Microsoft\Windows\Start Menu\Programs\StartUp\BGInfo.lnk")
    $ShortCut.TargetPath="C:\Program Files\BGInfo\BGInfo64.exe"
    $ShortCut.Arguments="Bginfo64-Win10.bgi /nolicprompt /silent /timer:0"
    $ShortCut.WorkingDirectory = "C:\Program Files\BGInfo";
    $ShortCut.Save()
}

if($val.InstallationType -eq 'Client')
{
    Write-Verbose "Starting Installation of $Vendor $Product" -Verbose
    If (!(Test-Path -Path $Path)) { New-Item -ItemType directory -Path $Path | Out-Null }
    Copy-Item -Path . -Destination "C:\Program Files\" -Recurse -Force
    CD $Path
    
    (Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

    Write-Verbose "Customization" -Verbose
    $Shell = New-Object -ComObject ("WScript.Shell")
    $ShortCut = $Shell.CreateShortcut($env:PROGRAMDATA  + "\Microsoft\Windows\Start Menu\Programs\StartUp\BGInfo.lnk")
    $ShortCut.TargetPath="C:\Program Files\BGInfo\BGInfo64.exe"
    $ShortCut.Arguments="Bginfo64-Win10.bgi /nolicprompt /silent /timer:0"
    $ShortCut.WorkingDirectory = "C:\Program Files\BGInfo";
    $ShortCut.Save()
}

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript 

