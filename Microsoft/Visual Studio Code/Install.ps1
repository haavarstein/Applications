
Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)
 
$Vendor = "Microsoft"
$Product = "Visual Studio Code"
$Version = "1.32.3"
$PackageName = "VSCode_x64"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs = '/verysilent /suppressmsgboxes /mergetasks=!runcode'
$url = "https://go.microsoft.com/fwlink/?Linkid=852157"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS | Out-Null
 
if( -Not (Test-Path -Path $Version ) )
{
    New-Item -ItemType directory -Path $Version
}
 
CD $Version
 
Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -Uri $url -OutFile $Source
         }
        Else {
            Write-Verbose "File exists. Skipping Download." -Verbose
         }
 
Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode
 
Write-Verbose "Customization" -Verbose
CD "C:\Program Files (x86)\Microsoft VS Code\bin\"
code --install-extension ms-vscode.powershell -force
code --install-extension coenraads.bracket-pair-colorizer -force

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript | Out-Null
