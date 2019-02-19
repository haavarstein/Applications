# Applications
Automation Framework Applications set leveraging evergreen installation scripts to download latest version from the vendors software repository.

This is a similar approched to #winops used by Chocolatey but doesn't require moderator's approval.

# Download and Extract

'[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"'
'wget -uri https://github.com/haavarstein/Applications/archive/master.zip -OutFile C:\Windows\Temp\Master.zip'
'Expand-Archive -Path C:\Windows\Temp\Master.zip -DestinationPath C:\'
