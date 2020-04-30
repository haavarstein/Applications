Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$CustomerID = "XXX"
$ClientID = "XXX"
$ClientSecret = "XXX"

$Vendor = "Citrix"
$Product = "Cloud Connector"
$PackageName = "cwcconnector"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$url = "https://downloads.cloud.com/$CustomerID/connector/cwcconnector.exe"
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Start-Transcript $LogPS

Write-Verbose "Downloading $Vendor $Product $Version" -Verbose
If (!(Test-Path -Path $Source)) {
    Invoke-WebRequest -Uri $url -OutFile $Source
    $Version = (Get-Command .\$Source).FileVersionInfo.FileVersion
}

If (!(Test-Path -Path $Version)) {
    New-Item -ItemType directory -Path $Version | Out-Null
    Copy-Item $Source -Destination $Version
    Remove-Item $Source
}

# Using System Environment Variable Location to defect Resource Location - Set via Group Policy Preferences
Write-Verbose "Getting Resource Location" -Verbose

if (($env:Location -eq "HQ")) {

     Write-Verbose "Resource Location is $env:Location" -Verbose
     $UnattendedArgs = '/q /Customer:'+$CustomerID+' /ClientID:'+$ClientID+' /ClientSecret:'+$ClientSecret+' /ResourceLocationId:XXX /AcceptTermsOfService:true'
}

if (($env:Location -eq "Azure")) {

     Write-Verbose "Resource Location is $env:Location" -Verbose
     $UnattendedArgs = '/q /Customer:'+$CustomerID+' /ClientID:'+$ClientID+' /ClientSecret:'+$ClientSecret+' /ResourceLocationId:XXX /AcceptTermsOfService:true'
}

CD $Version

Write-Verbose "Starting Installation of $Vendor $Product $Version" -Verbose
(Start-Process "$PackageName.$InstallerType" $UnattendedArgs -Wait -Passthru).ExitCode

Write-Verbose "Customization" -Verbose

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
