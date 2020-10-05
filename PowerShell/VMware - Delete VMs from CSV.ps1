## CSV has column VMName

Write-Verbose "Importing VMware PowerCli Module" -Verbose
Import-Module VMware.DeployAutomation

$CSV = "$env:Settings\Applications\PowerShell\VMList.csv"
Import-Csv -Path $CSV | ForEach-Object {

    $oThisVM = Get-VM -Name $_.VMName

    if ($oThisVM.PowerState -eq "PoweredOn") {Stop-VM -Confirm:$false -VM $oThisVM}

    $oThisVM | Remove-VM -DeletePermanently -Confirm:$false -RunAsync

} ## end foreach-object
