# Requires permissions, use Elevated Logon prior
# EASY : Set TS env DomainJoin to blank and JoinWorkGroup=Workgroup - Prevent VM from Joining the Domain

Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Join"
$Product = "Workgroup"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product.log"

Start-Transcript $LogPS

Remove-computer -WorkgroupName Workgroup

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
