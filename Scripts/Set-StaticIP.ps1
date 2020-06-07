# Needs to run as PowerShell and NOT as an Application in the Task Sequence (Module is not loaded)

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "Config"
$Product = "Set Static IP Address"
$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product PS Wrapper.log"

Start-Transcript $LogPS

Write-Verbose "Importing PowerShell Module" -Verbose
Import-Module ZTIUtility.psm1

Write-Verbose "Using COM interop to access the TSEnvironment object" -Verbose
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment

Write-Verbose "Getting Task Sequence Variables" -Verbose
$DeployRoot      = $TSEnv.Value("DeployRoot")
$OSDComputerName = $TSEnv.Value("OSDComputerName")
$MachineObjectOU = $TSEnv.Value("MachineObjectOU")
$MacAddress  = $TSEnv.Value("MacAddress")
$IPAddress  = $TSEnv.Value("OSDAdapter0IPAddressList")
$Subnet  = $TSEnv.Value("OSDAdapter0SubnetMask")
$Gateway  = $TSEnv.Value("OSDAdapter0Gateways")
$DNS  = $TSEnv.Value("OSDAdapter0DNSServerList")
$FQDN  = $TSEnv.Value("OSDAdapter0DNSSuffi")

Write-Verbose "Listing Task Sequence Variables" -Verbose
Write-Host $DeployRoot
Write-Host $OSDComputerName
Write-Host $MachineObjectOU
Write-Host $MacAddress
Write-Host $IPAddress
Write-Host $Subnet
Write-Host $Gateway
Write-Host $DNS
Write-Host $FQDN

Write-Verbose "Getting Static IP Address" -Verbose
New-NetIPAddress -InterfaceAlias Ethernet0 -IPv4Address $IPAddress -PrefixLength 24 -DefaultGateway $Gateway

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose
Stop-Transcript
