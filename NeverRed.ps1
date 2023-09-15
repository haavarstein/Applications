[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
wget -uri "https://codeload.github.com/haavarstein/Applications/zip/refs/heads/master" -OutFile C:\Temp\Master.zip
Expand-Archive -Path C:\Temp\Master.zip -DestinationPath C:\Temp
ren "C:\Temp\Applications-master" "C:\Temp\Applications"
CD "C:\Temp\Applications\Misc\NeverRed"
.\Install.ps1
Start-ScheduledTask -TaskName "NeverRed"
