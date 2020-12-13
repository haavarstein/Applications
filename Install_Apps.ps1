Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$LogPS = "${env:SystemRoot}" + "\Temp\Install_Apps.log"
$Path = "C:\Applications-master"

Start-Transcript $LogPS | Out-Null

Write-Verbose "Installing Modules" -Verbose
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
if (!(Test-Path -Path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget")) {Install-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies}
if (!(Get-Module -ListAvailable -Name Evergreen)) {Install-Module Evergreen -Force | Import-Module Evergreen}
Update-Module Evergreen

wget https://codeload.github.com/haavarstein/Applications/zip/master -OutFile c:\applications.zip -UseBasicParsing
Expand-Archive C:\applications.zip C:\

CD "$Path\Google\Chrome Enterprise"
.\Install.ps1

CD "$Path\Microsoft\Edge Enterprise"
.\Install.ps1

CD "$Path\Microsoft\Office 365"
.\Install.ps1

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript

