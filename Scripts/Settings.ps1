$ScriptFile = $MyInvocation.MyCommand.Name
$ScriptLocation  = Split-Path $MyInvocation.MyCommand.Path -Parent
$Path = $TSEnv:DeployRoot

[Environment]::SetEnvironmentVariable("Settings", "$Path", "Machine")
