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

Write-Verbose "Installing Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}
Update-Module Evergreen

$Vendor = "Misc"
$Product = "BISF"
$PackageName = "setup-BIS-F"
$Repo = "https://api.github.com/repos/EUCweb/BIS-F/releases/latest"
$Evergreen = Get-EvergreenApp -Name BISF
$Version = $Evergreen.Version
$URL = $Evergreen.uri
$InstallerType = "msi"
$Source = "$PackageName" + "." + "$InstallerType"
$SourceCTX = "CitrixOptimizer.zip"
$SourceTools = "Tools.zip"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$ctx = "http://xenapptraining.s3.amazonaws.com/Hydration/CitrixOptimizer.zip"
$tools = "http://xenapptraining.s3.amazonaws.com/Hydration/Tools.zip"
$ProgressPreference = 'SilentlyContinue'
$UnattendedArgs = "/i $PackageName.$InstallerType ALLUSERS=1 /qn /liewa $LogApp"

Start-Transcript $LogPS

If (!(Test-Path -Path $Version)) {New-Item -ItemType directory -Path $Version | Out-Null}

CD $Version

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $Source    
    Write-Verbose "Downloading Citrix Optimizer" -Verbose
    Invoke-WebRequest -Uri $ctx -OutFile $SourceCTX
    Expand-Archive -Path $SourceCTX -DestinationPath .\CitrixOptimizer
    Write-Verbose "Downloading Tools" -Verbose
    Invoke-WebRequest -Uri $tools -OutFile $SourceTools
    Expand-Archive -Path $SourceTools -DestinationPath .\Tools
             }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
         }

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process msiexec.exe -ArgumentList $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose
If (!(Test-Path -Path "C:\Program Files\Citrix Optimizer")) {New-Item -ItemType directory -Path "C:\Program Files\Citrix Optimizer" | Out-Null}
Copy-Item -Path .\CitrixOptimizer\* -Destination "C:\Program Files\Citrix Optimizer\" -Recurse -Force
CD..
Copy-Item -Path .\Templates\* -Destination "C:\Program Files\Citrix Optimizer\Templates" -Recurse -Force
Copy-Item -Path .\Tools\* -Destination $env:SystemRoot\System32 -Recurse -Force
Copy-Item -Path .\*.json -Destination "C:\Program Files (x86)\Base Image Script Framework (BIS-F)" -Recurse -Force

#Copy-Item -Path $PSScriptRoot\PREP_custom\*.ps1 -Destination "C:\Program Files (x86)\Base Image Script Framework (BIS-F)\Framework\SubCall\Preparation\Custom" -Recurse -Force
#Copy-Item -Path $PSScriptRoot\PERS_custom\*.ps1 -Destination "C:\Program Files (x86)\Base Image Script Framework (BIS-F)\Framework\SubCall\Personalization\Custom" -Recurse -Force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript 
