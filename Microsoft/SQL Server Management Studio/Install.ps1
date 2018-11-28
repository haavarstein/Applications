Function Get-MicrosoftSsmsVersion {
    <#
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
    #>
    [CmdletBinding()]
    [OutputType([Version])]
    param(
        [ValidateSet("GAFull","GAUpdate","Preview")]
        [string] $Release = "GAFull"
    )

    $url = "https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-2017"
    
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to SMSS: $url with error $_."
        Break
    }
    finally {
        $interestingLinks = $response.links  | Where-Object {$_.outerHTML -like "*Download SQL Server Management Studio*"}
        switch ($Release) { 
            "GAFull" {
                $thislink = $interestingLinks | Where-Object {$_.outerHTML -notlike "*preview*" -and $_.outerHTML -notlike "*upgrade*"}
            };
            "GAUpdate" {
                $thislink = $interestingLinks | Where-Object {$_.outerHTML -like "*upgrade*"}
            };
            "Preview" {
                $thislink = $interestingLinks | Where-Object {$_.outerHTML -like "*preview*"}
            };
        }
        $thislink.outerHTML -match "(\d+\.)+\d+" | Out-Null
        Write-Output ([version]::new($matches[0]))
    }
}

Function Get-MicrosoftSsmsUri {
    <#
        .NOTES
            Author: Bronson Magnan
            Twitter: @cit_bronson
    #>
    [CmdletBinding()]
    [Outputtype([string])]
    param(
        [ValidateSet("GAFull","GAUpdate","Preview")]
        [string] $Release = "GAFull"
    )

    $url = "https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-2017"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to SSMS: $url with error $_."
        Break
    }
    finally {
        $interestingLinks = $response.links  | Where-Object {$_.outerHTML -like "*Download SQL Server Management Studio*"}
        switch ($Release) { 
            "GAFull" {
                $thislink = $interestingLinks | Where-Object {$_.outerHTML -notlike "*preview*" -and $_.outerHTML -notlike "*upgrade*"}
            };
            "GAUpdate" {
                $thislink = $interestingLinks | Where-Object {$_.outerHTML -like "*upgrade*"}
            };
            "Preview" {
                $thislink = $interestingLinks | Where-Object {$_.outerHTML -like "*preview*"}
            };
        }

        Write-Output $thislink.href 
    }
}

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
$Product = "SQL Server Management Studio"
$Version = "$(Get-MicrosoftSsmsVersion)"
$PackageName = "SSMS-Setup-ENU"
$InstallerType = "exe"
$Source = "$PackageName" + "." + "$InstallerType"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
$LogApp = "${env:SystemRoot}" + "\Temp\$PackageName.log"
$Destination = "${env:ChocoRepository}" + "\$Vendor\$Product\$Version\$packageName.$installerType"
$UnattendedArgs='/q'
$url = "$(Get-MicrosoftSsmsUri)"
$ProgressPreference = 'SilentlyContinue'

Start-Transcript $LogPS

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

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
