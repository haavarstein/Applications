Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Microsoft"
$Product = "Remove UWP Apps"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product PS Wrapper.log"

Start-Transcript $LogPS

# ----------------------------------------------------------------------------
# Script: Remove UWP Apps
# Version: 1.0
# Author: Mike Galvin
# Contact: mike@gal.vin or twitter.com/mikegalvin_
# Date: 2019-08-19
# ----------------------------------------------------------------------------

# Configure the apps to be removed
$AppsList = "Microsoft.BingWeather",
            "Microsoft.DesktopAppInstaller",
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.HEIFImageExtension",
            "Microsoft.Messaging",
            "Microsoft.Microsoft3DViewer",
            "Microsoft.MicrosoftOfficeHub",
            "Microsoft.MicrosoftSolitaireCollection",
            "Microsoft.MicrosoftStickyNotes",
            "Microsoft.MixedReality.Portal",
            "Microsoft.MSPaint",
            "Microsoft.Office.OneNote",
            "Microsoft.OneConnect",
            "Microsoft.People",
            "Microsoft.Print3D",
            "Microsoft.ScreenSketch",
            "Microsoft.SkypeApp",
            "Microsoft.StorePurchaseApp",
            "Microsoft.VP9VideoExtensions",
            "Microsoft.Wallet",
            "Microsoft.WebMediaExtensions",
            "Microsoft.WebpImageExtension",
            "Microsoft.Windows.Photos",
            "Microsoft.WindowsAlarms",
            "Microsoft.WindowsCalculator",
            "Microsoft.WindowsCamera",
            "microsoft.windowscommunicationsapps",
            "Microsoft.WindowsFeedbackHub",
            "Microsoft.WindowsMaps",
            "Microsoft.WindowsSoundRecorder",
            "Microsoft.WindowsStore",
            "Microsoft.Xbox.TCUI",
            "Microsoft.XboxApp",
            "Microsoft.XboxGameOverlay",
            "Microsoft.XboxGamingOverlay",
            "Microsoft.XboxIdentityProvider",
            "Microsoft.XboxSpeechToTextOverlay",
            "Microsoft.YourPhone",
            "Microsoft.ZuneMusic",
            "Microsoft.ZuneVideo"

# Remove the Apps listed above or report if app not present
ForEach ($App in $AppsList)
{
    $PackageFullName = (Get-AppxPackage $App).PackageFullName
    $ProPackageFullName = (Get-AppxProvisionedPackage -Online | Where-Object {$_.Displayname -eq $App}).PackageName

    If ($PackageFullName)
    {
        Write-Host "Removing Package: $App"
        Remove-AppxPackage -Package $PackageFullName
    }

    Else
    {
        Write-Host "Unable to find package: $App"
    }

    If ($ProPackageFullName)
    { 
        Write-Host "Removing Provisioned Package: $ProPackageFullName"
        Remove-AppxProvisionedPackage -Online -PackageName $ProPackageFullName 
    }
     
    Else 
    { 
        Write-Host "Unable to find provisioned package: $App" 
    }
}

# End

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
