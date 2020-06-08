'******************************************************************
' This script will statically assign an IP Address to the network adapter when
' booting into WinPE using either MDT or SCCM.
'
' We derive the IP Configuration directly from the MAC Address section of the
' Bootstrap.ini file using the following keys:
' - OSDAdapterCount
' - OSDAdapter0EnableDHCP
' - OSDAdapter0IPAddressList
' - OSDAdapter0SubnetMask
' - OSDAdapter0Gateways
' - OSDAdapter0DNSServerList
' - OSDAdapter0DNSSuffix
'
' Using the netsh interface command line
' - netsh interface ipv4 set address name=Ethernet static strIPAddress mask=strSubnetMask gateway=strDefaultGateway
' - netsh interface ip add dns name="Ethernet" addr=arrDNSServers(0) index=1
' - netsh interface ip add dns name="Ethernet" addr=arrDNSServers(1) index=2
' - netsh interface ip add dns name="Ethernet" addr=arrDNSServers(2) index=3
' - netsh interface ip add dns name="Ethernet" addr=arrDNSServers(3) index=4
'
' Setting/Adding the DNS Suffixes:
' - Is not supported by the netsh interface command line
' - Setting them directly via the HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\SearchList registry value will require a reboot to take effect.
' - Therefore you must set them using the Win32_NetworkAdapterConfiguration WMi Class
'
' Since we need to set the DNS Suffixes via WMI this script has been written to apply all required
' IP settings via WMI.
'
' Script name: SetStaticIP.vbs
' Author: Jeremy Saunders (Jeremy@jhouseconsulting.com)
' Version 1.1
' Date: 2nd March 2018
'
'******************************************************************

Option Explicit

Dim sScriptFullName, sScriptPath, strIniFileName, blnProcessFromINI, strComputer
Dim objFSO, strMACAddress, strNetConnectionID, strDHCPEnabled, arrIPAddress
Dim arrSubnetMask, arrDefaultGateway, arrGatewayMetric, arrDNSServers, arrDNSSuffix
Dim intNetBIOSSetting, objWMIService, colNetAdapters, ObjNetAdapter, strIndex
Dim intError, objNetworkSettings

' It is important that this script is run using the cscript engine, so we run a check for this,
' and automatically change the "engine". Otherwise, if you are running it in an RDP session
' using wscript, you will lose control, and will need to use the server console to regain
' access.
Call checkengine()

'Get Script Path
sScriptFullName = WScript.ScriptFullName
sScriptPath = Left(sScriptFullName, InStrRev(sScriptFullName, "\"))

blnProcessFromINI = TRUE
strIniFileName = "Bootstrap.ini"

Set objFSO = CreateObject("scripting.filesystemobject")

If objfso.FileExists(sScriptPath & strIniFileName) Then

  strNetConnectionID = "Ethernet"
  strMACAddress = GetMACAddress(strNetConnectionID)
  If IsNull(strMacAddress) OR strMacAddress = "" Then
    strNetConnectionID = "Ethernet0"
    strMACAddress = GetMACAddress(strNetConnectionID)
  End If
  If IsNull(strMacAddress) OR strMacAddress = "" Then
    strNetConnectionID = ""
    strMACAddress = "00:00:00:00:00:00"
  End If

  strDHCPEnabled = "TRUE"

  If blnProcessFromINI Then
    strDHCPEnabled = ReadIni( sScriptPath & strIniFileName, strMACAddress, "OSDAdapter0EnableDHCP" )
  Else
    strDHCPEnabled = GetMDTVariable(OSDAdapter0EnableDHCP)
  End If

  If (UCase(strDHCPEnabled) = "FALSE") Then

    ' 0 = Use setting from DHCP
    ' 1 = Enable
    ' 2 = Disable
    intNetBIOSSetting = 2
    arrGatewayMetric = Array("1")

    If blnProcessFromINI Then
      arrIPAddress = Array(ReadIni( sScriptPath & strIniFileName, strMACAddress, "OSDAdapter0IPAddressList" ))
      arrSubnetMask = Array(ReadIni( sScriptPath & strIniFileName, strMACAddress, "OSDAdapter0SubnetMask" ))
      arrDefaultGateway = Array(ReadIni( sScriptPath & strIniFileName, strMACAddress, "OSDAdapter0Gateways" ))
      arrDNSServers = split(ReadIni( sScriptPath & strIniFileName, strMACAddress, "OSDAdapter0DNSServerList" ),",")
      arrDNSSuffix = split(ReadIni( sScriptPath & strIniFileName, strMACAddress, "OSDAdapter0DNSSuffix" ),",")
    Else
      arrIPAddress = Array(GetMDTVariable(OSDAdapter0IPAddressList))
      arrSubnetMask = Array(GetMDTVariable(OSDAdapter0SubnetMask))
      arrDefaultGateway = Array(GetMDTVariable(OSDAdapter0Gateways))
      arrDNSServers = split(GetMDTVariable(OSDAdapter0DNSServerList),",")
      arrDNSSuffix = split(GetMDTVariable(OSDAdapter0DNSSuffix),",")
    End If

    strComputer = "."
    set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

    If strNetConnectionID <> "" Then
      set colNetAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionID='" & strNetConnectionID & "'")
    Else
      set colNetAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionID > ''")
    End If

    For Each ObjNetAdapter In colNetAdapters
      strIndex = ObjNetAdapter.Index
    Next

    Set colNetAdapters = Nothing

    set colNetAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE Index='" & strIndex & "'")

    For Each ObjNetAdapter In colNetAdapters

      intError = ObjNetAdapter.EnableStatic(arrIPAddress, arrSubnetMask)
      Call CheckForError(intError,"IP Address and Subnet Mask")

      ' Need to wait 1 second otherwise the default gateway may fail to be set.
      wscript.sleep 1000

      intError = ObjNetAdapter.SetGateways(arrDefaultGateway, arrGatewayMetric)
      Call CheckForError(intError,"Default Gateway")

      intError = objNetAdapter.SetDNSServerSearchOrder(arrDNSServers)
      Call CheckForError(intError,"DNS Server(s)")

      intError = objNetAdapter.SetTCPIPNetBIOS(intNetBIOSSetting)
      Call CheckForError(intError,"NetBIOS over Tcpip")

    Next

    Set objNetworkSettings = objWMIService.Get("Win32_NetworkAdapterConfiguration")

    intError = objNetworkSettings.SetDNSSuffixSearchOrder(arrDNSSuffix)
    Call CheckForError(intError,"DNS Suffix(s)")

    ' Waiting 2 seconds before exiting so that the new IP Address will be picked up by BGInfo
    wscript.sleep 2000

  End If

  Set ObjNetAdapter = Nothing
  set objWMIService = Nothing
  Set colNetAdapters = Nothing
  Set objNetworkSettings = Nothing
  Set objFSO = Nothing

End If

wscript.quit(0)

Sub CheckForError(intError,strDescription)
  If intError = 0 Then
    WScript.Echo "Success! Configured the " & strDescription & ". No reboot required."
  ElseIf intError = 1 Then
    WScript.Echo "Success! Configured the " & strDescription & ". Reboot required."
  Else
    WScript.Echo "Error! Unable to replace configure the " & strDescription
  End If
End Sub

Sub checkengine()
  Dim strEngine, WshShell, strArgs, i, strCmd, objDebug, intExitCode
  strEngine = LCase(Mid(WScript.FullName, InstrRev(WScript.FullName,"\")+1))
  If strEngine <> "cscript.exe" Then
    strArgs = ""
    If WScript.Arguments.Count > 0 Then
      For i = 0 To WScript.Arguments.Count - 1
        strArgs = strArgs & " " & chr(34) & WScript.Arguments(i) & chr(34)
      Next
    End If
    strCmd = "CSCRIPT.EXE //NoLogo " & chr(34) & WScript.ScriptFullName & chr(34) & " " & strArgs
    Set WshShell = CreateObject("WScript.Shell")
    Set objDebug = WshShell.Exec(strCmd)
    Do While objDebug.Status = 0
      WScript.Sleep 100
    Loop
    intExitCode = objDebug.ExitCode
    Set WshShell = Nothing
    Set objDebug = Nothing
    WScript.Quit(intExitCode)
  End If
End Sub

Function GetMACAddress(strNetConnectionID)
  Dim strMACAddress, strComputer, objWMIService, colNetAdapters, ObjNetAdapter, strIndex
  strComputer = "."
  set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
  'set colNetAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter")
  set colNetAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionID='" & strNetConnectionID & "'")
  For Each ObjNetAdapter In colNetAdapters
    strIndex = ObjNetAdapter.Index
  Next
  Set colNetAdapters = Nothing
  set colNetAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE Index='" & strIndex & "'")
  For Each objNetAdapter In colNetAdapters
    If objNetAdapter.MACAddress <> "" Then  
      strMACAddress = UCase(objNetAdapter.MACAddress)
    End If
  Next
  Set objWMIService = Nothing
  Set colNetAdapters = Nothing
  GetMACAddress = strMACAddress
End Function

Function GetMDTVariable(strVar)
  Dim oTSEnv
  set oTSEnv = CreateObject("Microsoft.SMS.TSEnvironment")
  GetMDTVariable = oTSEnv(strVar)
  set oTSEnv = Nothing
End Function

Function IsTaskSequence()
  Dim oTSEnv
  On Error Resume Next
  set oTSEnv = CreateObject("Microsoft.SMS.TSEnvironment")
  If (Err.Number <> 0)   Then
    wscript.echo "Unable to load ComObject [Microsoft.SMS.TSEnvironment]. Therefore, script is not currently running from an MDT or SCCM Task Sequence."
    IsTaskSequence = False
  Else
    wscript.echo "Successfully loaded ComObject [Microsoft.SMS.TSEnvironment]. Therefore, script is currently running from an MDT or SCCM Task Sequence."
    IsTaskSequence = True
  End If
  set oTSEnv = Nothing
  Err.Clear
  On Error GoTo 0
End Function

Function ReadIni( myFilePath, mySection, myKey )
    ' This function returns a value read from an INI file
    '
    ' Arguments:
    ' myFilePath  [string]  the (path and) file name of the INI file
    ' mySection   [string]  the section in the INI file to be searched
    ' myKey       [string]  the key whose value is to be returned
    '
    ' Returns:
    ' the [string] value for the specified key in the specified section
    '
    ' CAVEAT:     Will return a space if key exists but value is blank
    '
    ' Written by Keith Lacelle
    ' Modified by Denis St-Pierre and Rob van der Woude

    Const ForReading   = 1
    Const ForWriting   = 2
    Const ForAppending = 8

    Dim intEqualPos
    Dim objFSO, objIniFile
    Dim strFilePath, strKey, strLeftString, strLine, strSection

    Set objFSO = CreateObject( "Scripting.FileSystemObject" )

    ReadIni     = ""
    strFilePath = Trim( myFilePath )
    strSection  = Trim( mySection )
    strKey      = Trim( myKey )

    If objFSO.FileExists( strFilePath ) Then
        Set objIniFile = objFSO.OpenTextFile( strFilePath, ForReading, False )
        Do While objIniFile.AtEndOfStream = False
            strLine = Trim( objIniFile.ReadLine )

            ' Check if section is found in the current line
            If LCase( strLine ) = "[" & LCase( strSection ) & "]" Then
                strLine = Trim( objIniFile.ReadLine )

                ' Parse lines until the next section is reached
                Do While Left( strLine, 1 ) <> "["
                    ' Find position of equal sign in the line
                    intEqualPos = InStr( 1, strLine, "=", 1 )
                    If intEqualPos > 0 Then
                        strLeftString = Trim( Left( strLine, intEqualPos - 1 ) )
                        ' Check if item is found in the current line
                        If LCase( strLeftString ) = LCase( strKey ) Then
                            ReadIni = Trim( Mid( strLine, intEqualPos + 1 ) )
                            ' In case the item exists but value is blank
                            If ReadIni = "" Then
                                ReadIni = " "
                            End If
                            ' Abort loop when item is found
                            Exit Do
                        End If
                    End If

                    ' Abort if the end of the INI file is reached
                    If objIniFile.AtEndOfStream Then Exit Do

                    ' Continue with next line
                    strLine = Trim( objIniFile.ReadLine )
                Loop
            Exit Do
            End If
        Loop
        objIniFile.Close
    Else
        WScript.Echo strFilePath & " doesn't exists. Exiting..."
        Wscript.Quit 1
    End If
End Function
