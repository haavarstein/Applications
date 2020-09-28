$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Veeam Agent for Microsoft Windows'"
$app.Uninstall()

$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Microsoft SQL Server 2012 Express LocalDB '"
$app.Uninstall()

$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Microsoft SQL Server 2012 Management Objects  (x64)'"
$app.Uninstall()

$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Microsoft System CLR Types for SQL Server 2012 (x64)'"
$app.Uninstall()
