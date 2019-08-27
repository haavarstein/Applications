# Bronson Magnan - https://twitter.com/CIT_Bronson - This will download the Adobe Stuff
 
$ftp = "ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/"
 
# We have to use .NET to read a directory listing from FTP, it is different than downloading a file.
# Original C# code at https://docs.microsoft.com/en-us/dotnet/framework/network-programming/how-to-list-directory-contents-with-ftp
 
$request = [System.Net.FtpWebRequest]::Create($ftp);
$request.Credentials = [System.Net.NetworkCredential]::new("anonymous", "password");
$request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails;
[System.Net.FtpWebResponse]$response = [System.Net.FtpWebResponse]$request.GetResponse();
[System.IO.Stream]$responseStream = $response.GetResponseStream();
[System.IO.StreamReader]$reader = [System.IO.StreamReader]::new($responseStream);
$DirList = $reader.ReadToEnd()
$reader.Close()
$response.close()
 
# Split into Lines, currently it is one big string.
$DirByLine = $DirList.split("`n")
 
# Get the token containing the folder name.
$folders = @()
foreach ($line in $DirByLine ) { 
    $endtoken = ($line.split(' '))[-1]
    #filter out non version folder names
    if ($endtoken -match "[0-9]") {
        $folders += $endtoken
    }
}
 
# Sort the folders by newest first, and select the first 1, and remove the newline whitespace at the end.
$currentfolder = ($folders | sort -Descending | select -First 1).trim()

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
$Product = "Reader DC"
$PackageName = "AcroRead"
$Version = "$currentfolder"
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"
$BaseVersion = "1901220036"
$Baseurl = "ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/1901220036/AcroRdrDC1901220036_en_US.exe"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS | Out-Null

if( -Not (Test-Path -Path $BaseVersion ) )
{
    New-Item -ItemType directory -Path $BaseVersion | Out-Null
    CD $BaseVersion
    Write-Verbose "Downloading $Vendor $Product Base $BaseVersion" -Verbose
    Invoke-WebRequest -UseBasicParsing -Uri $baseurl -OutFile AcroRdrDC.exe
    .\AcroRdrDC.exe -sfx_o -sfx_o"C:\Temp\Adobe\1" -sfx_ne
    Start-Sleep -s 60
    Copy-Item -Path C:\Temp\Adobe\1\* -Destination .
    CD..
}

CD $BaseVersion
Write-Verbose "Starting Installation of $Vendor $Product Base $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode
CD..
 
if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version | Out-Null
    $Version | Out-File -FilePath ".\Version.txt" -Force
}
 
CD $Version
 
If (!(Test-Path -Path AcroRdrDCUpd$($Version).msp)) {
    Write-Verbose "Downloading $Vendor $Product MSP Patch $Version" -Verbose
    $MSPDownload = "$($ftp)$($currentfolder)`/AcroRdrDCUpd$($currentfolder).msp"
    $filename = ($MSPDownload.split("/"))[-1]
    wget -uri $MSPDownload -outfile $filename
}
Else {
    Write-Verbose "File Exists. Skipping Download." -Verbose
}

Write-Verbose "Patching $Vendor $Product with $Version" -Verbose
$MSPDownload = "$($ftp)$($currentfolder)`/AcroRdrDCUpd$($currentfolder).msp"
$filename = ($MSPDownload.split("/"))[-1]
$UnattendedArgs = "/p $filename /norestart /qn /liewa ${env:SystemRoot}\Temp\$filename.log"
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript  | Out-Null
