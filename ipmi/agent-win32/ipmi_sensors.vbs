' --------------------------------------------------------------
' IPMI Sensors parser for Windows
' Used as Plugin in Pandora FMS Monitoring System
' Written by Robert Nelson <robertn@the-nelsons.org> 2015
' Licensed under BSD Licence
' --------------------------------------------------------------

Option Explicit

On Error Resume Next

Dim VERSION

VERSION = "0.9.0"

Sub VersionMessage
	WScript.StdErr.WriteLine WScript.ScriptName & " Version " & VERSION
End Sub

Sub HelpMessage
	WScript.StdErr.WriteLine "usage: cscript //B " & WScript.ScriptName & " /h:<hostname> /u:<username> /p:<password> [/g:<modulegroup>]"
	WScript.StdErr.WriteLine ""
	WScript.StdErr.WriteLine "This agent plugin can be used for remote IPMI monitoring"
	WScript.StdErr.WriteLine "/h" & VBTab & "IPMI host name or IP address"
	WScript.StdErr.WriteLine "/u" & VBTab & "IPMI user name"
	WScript.StdErr.WriteLine "/p" & VBTab & "IPMI password"
	WScript.StdErr.WriteLine "The module can be assigned to a module group using:"
	WScript.StdErr.WriteLine "/g" & VBTab & "Module group (must already exist in PandoraFMS)"
End Sub

If WScript.Arguments.Named.Exists("?") Then
	VersionMessage
	HelpMessage
	WScript.Quit 1
End If

If WScript.Arguments.Named.Exists("v") Then
	VersionMessage
	WScript.Quit 1
End If

Dim strHostName, strUserName, strUserPassword, strModuleGroup

strHostName = WScript.Arguments.Named.Item("h")
strUserName = WScript.Arguments.Named.Item("u")
strUserPassword = WScript.Arguments.Named.Item("p")
strModuleGroup = WScript.Arguments.Named.Item("g")

If strHostName = "" or strUserName = "" or strUserPassword = "" Then
	WScript.StdErr.WriteLine "The /h, /u and /p options must be specified"
	HelpMessage
	WScript.Quit 1
End If


' Map Sensor type to module type and thresholds
' 0 = numeric, record has thresholds
' 1 = simple flag, 0 normal, > 0 critical
' 2 = complex flags, for now ignore alert settings
' 3 = string or unknown

Dim objSensorTypes

Set objSensorTypes = CreateObject("Scripting.Dictionary")

objSensorTypes.Add "Temperature", 0
objSensorTypes.Add "Voltage", 0
objSensorTypes.Add "Current", 0
objSensorTypes.Add "Fan", 0
objSensorTypes.Add "Physical Security", 1
objSensorTypes.Add "Platform Security Violation Attempt", 1
objSensorTypes.Add "Processor", 2
objSensorTypes.Add "Power Supply", 2
objSensorTypes.Add "Power Unit", 2
objSensorTypes.Add "Cooling Device", 0
objSensorTypes.Add "Other Units Based Sensor", 0
objSensorTypes.Add "Memory", 2
objSensorTypes.Add "Drive Slot", 3
objSensorTypes.Add "POST Memory Resize", 3
objSensorTypes.Add "System Firmware Progress", 1
objSensorTypes.Add "Event Logging Disabled", 2
objSensorTypes.Add "Watchdog 1", 2
objSensorTypes.Add "System Event", 2
objSensorTypes.Add "Critical Interrupt", 1
objSensorTypes.Add "Button Switch", 2
objSensorTypes.Add "Module Board", 3
objSensorTypes.Add "Microcontroller Coprocessor", 3
objSensorTypes.Add "Add In Card", 3
objSensorTypes.Add "Chassis", 3
objSensorTypes.Add "Chip Set", 3
objSensorTypes.Add "Other Fru", 3
objSensorTypes.Add "Cable Interconnect", 3
objSensorTypes.Add "Terminator", 3
objSensorTypes.Add "System Boot Initiated", 2
objSensorTypes.Add "Boot Error", 1
objSensorTypes.Add "OS Boot", 2
objSensorTypes.Add "OS Critical Stop", 1
objSensorTypes.Add "Slot Connector", 2
objSensorTypes.Add "System ACPI Power State", 2
objSensorTypes.Add "Watchdog 2", 2
objSensorTypes.Add "Platform Alert", 2
objSensorTypes.Add "Entity Presence", 2
objSensorTypes.Add "Monitor ASIC IC", 3
objSensorTypes.Add "LAN", 2
objSensorTypes.Add "Management Subsystem Health", 1
objSensorTypes.Add "Battery", 2
objSensorTypes.Add "Session Audit", 3
objSensorTypes.Add "Version Change", 3
objSensorTypes.Add "FRU State", 3
objSensorTypes.Add "OEM Reserved", 3

Dim strCommand, objShell, objExec

Set objShell = WScript.CreateObject("WScript.Shell")

strCommand = "..\freeipmi\ipmi-sensors -D LAN_2_0 -h " & strHostName & " -u " & strUserName & " -p " & strUserPassword & " -l user"
strCommand = strCommand & " --ignore-not-available-sensors --no-header-output --comma-separated-output --non-abbreviated-units --output-sensor-thresholds --output-event-bitmask --sdr-cache-directory=" & objShell.Environment("Process")("TEMP")

Set objExec = objShell.Exec(strCommand)

If Err.Number <> 0 Then
	WScript.StdErr.WriteLine WScript.ScriptName & ": Error executing - " & strCommand
	WScript.StdErr.WriteLine Err.Source & ": " & Err.Description
	WScript.Quit 1
End If

If objExec.ExitCode = 0 Then
	Dim strSensor, strName, strType, strValue, strUnits, strLowerNR, strLowerC, strLowerNC, strUpperNC, strUpperC, strUpperNR, strEventMask 
	Dim strModuleName, strModuleType, strModuleWarnMin, strModuleWarnMax, strModuleWarnInvert, strModuleCriticalMin, strModuleCriticalMax, strModuleCriticalInvert
	Dim strLine, arrayFields

	While Not objExec.StdOut.AtEndOfStream
		strLine = objExec.StdOut.ReadLine

		arrayFields = Split(strLine, ",")
		If (UBound(arrayFields) = 11) Then
			strSensor = arrayFields(0)
			strName = arrayFields(1)
			strType = arrayFields(2)
			strValue = arrayFields(3)
			strUnits = arrayFields(4)
			strLowerNR = arrayFields(5)
			strLowerC = arrayFields(6)
			strLowerNC = arrayFields(7)
			strUpperNC = arrayFields(8)
			strUpperC = arrayFields(9)
			strUpperNR = arrayFields(10)
			strEventMask = arrayFields(11)

			strModuleName = strType & ": " & strName

			strModuleWarnMin = Empty
			strModuleWarnMax = Empty
			strModuleWarnInvert = Empty
			strModuleCriticalMin = Empty
			strModuleCriticalMax = Empty
			strModuleCriticalInvert = Empty

			Select Case objSensorTypes(strType)
				Case 0
					strModuleType = "generic_data"	
					If (strLowerC <> "N/A" and strUpperC <> "N/A") Then
						strModuleCriticalMin = strLowerC
						strModuleCriticalMax = strUpperC
						strModuleCriticalInvert = "1"
					End If
					If (strLowerNC <> "N/A" and strUpperNC <> "N/A") Then
						strModuleWarnMin = strLowerNC
						strModuleWarnMax = strUpperNC
						strModuleWarnInvert = "1"
					End If
				Case 1
					strModuleType = "generic_data"
					strModuleCriticalMin = "1"
					strModuleCriticalMax = "0"
				Case 2
					strModuleType = "generic_data"
				Case 3
					strModuleType = "generic_data_string"
				Case Else
					strModuleType = "generic_data_string"
			End Select

			WScript.StdOut.WriteLine "<module>"
			WScript.StdOut.WriteLine "	<name><![CDATA[" & strModuleName & "]]></name>"
			WScript.StdOut.WriteLine "	<type><![CDATA[" & strModuleType & "]]></type>"
			if (strModuleGroup <> "") Then
				WScript.StdOut.WriteLine "	<type><![CDATA[" & strModuleGroup & "]]></type>"
			End If
			If (strValue <> "N/A") Then
				WScript.StdOut.WriteLine "	<data><![CDATA[" & strValue & "]]></data>"
			Else
				WScript.StdOut.WriteLine "	<data><![CDATA[" & CInt("&H" & Left(strEventMask, Len(strEventMask) - 1)) & "]]></data>"
			End If
			If (strUnits <> "N/A") Then
				WScript.StdOut.WriteLine "	<unit><![CDATA[" & strUnits & "]]></unit>"
			End If
			If (Not IsEmpty(strModuleWarnMin)) Then
				WScript.StdOut.WriteLine "	<min_warning>" & strModuleWarnMin & "</min_warning>"
			End If
			If (Not IsEmpty(strModuleWarnMax)) Then
				WScript.StdOut.WriteLine "	<max_warning>" & strModuleWarnMax & "</max_warning>"
			End If
			If (Not IsEmpty(strModuleWarnInvert)) Then
				WScript.StdOut.WriteLine "	<warning_inverse>" & strModuleWarnInvert & "</warning_inverse>"
			End If
			If (Not IsEmpty(strModuleCriticalMin)) Then
				WScript.StdOut.WriteLine "	<min_critical>" & strModuleCriticalMin & "</min_critical>"
			End If
			If (Not IsEmpty(strModuleCriticalMax)) Then
				WScript.StdOut.WriteLine "	<max_critical>" & strModuleCriticalMax & "</max_critical>"
			End If
			If (Not IsEmpty(strModuleCriticalInvert)) Then
				WScript.StdOut.WriteLine "	<critical_inverse>" & strModuleCriticalInvert & "</critical_inverse>"
			End If
			WScript.StdOut.WriteLine "</module>"
		Else
			WScript.StdErr.WriteLine WScript.ScriptName & ": Unexpected number of fields in response - " & strLine
			WScript.Quit 1
		End If
	Wend

	WScript.Quit 0
Else
	WScript.StdErr.WriteLine WScript.ScriptName & ": Error Executing - " & strCommand
	WScript.StdErr.Write objExec.StdErr.ReadAll
	WScript.Quit 1
End If
