TrayIcon_GetInfo()
{
	DetectHiddenWindows (Setting_A_DetectHiddenWindows := A_DetectHiddenWindows) ? "On" : "Off"
	;systemTrayData := {}
	Global iconCheck
	Global trayIconDir
	Global systemTrayData
	Global trayReading

	trayArray := {"Shell_TrayWnd":"User Promoted Notification Area","NotifyIconOverflowWindow":"Overflow Notification Area"}

	for sTray,trayCall in trayArray
	{
		
		pidTaskbar := WinGetPID("ahk_class " sTray)		
		trayLookup := ControlGetHwnd(trayCall,"ahk_class " sTray)
		trayId := "ahk_id " trayLookup
		hProc := DllCall("OpenProcess", UInt, 0x38, Int, 0, UInt, pidTaskbar)
		pRB   := DllCall("VirtualAllocEx", Ptr, hProc, Ptr, 0, UPtr, 20, UInt, 0x1000, UInt, 0x4)

		TrayCount := SendMessage(0x418, 0, 0, ,trayId)   ; TB_BUTTONCOUNT

		szBtn := VarSetCapacity(btn, (A_Is64bitOS ? 32 : 20), 0)
		szNfo := VarSetCapacity(nfo, (A_Is64bitOS ? 32 : 24), 0)
		szTip := VarSetCapacity(tip, 128 * 2, 0)

		Index := 0

		Loop TrayCount
		{
			SendMessage(0x417, A_Index - 1, pRB, ,trayId)   ; TB_GETBUTTON

			DllCall("ReadProcessMemory", Ptr, hProc, Ptr, pRB, Ptr, &btn, UPtr, szBtn, UPtr, 0)

			iBitmap := NumGet(btn, 0, "Int")     
			;IDcmd   := NumGet(btn, 4, "Int")
			;statyle := NumGet(btn, 8)
			dwData  := NumGet(btn, (A_Is64bitOS ? 16 : 12))
			iString := NumGet(btn, (A_Is64bitOS ? 24 : 16), "Ptr")

			DllCall("ReadProcessMemory", Ptr, hProc, Ptr, dwData, Ptr, &nfo, UPtr, szNfo, UPtr, 0)

			hWnd  := NumGet(nfo, 0, "Ptr")
			uID   := NumGet(nfo, (A_Is64bitOS ? 8 : 4), "UInt")
			msgID := NumGet(nfo, (A_Is64bitOS ? 12 : 8))
			hIcon := NumGet(nfo, (A_Is64bitOS ? 24 : 20), "Ptr")

			sProcess :=  WinGetProcessName("ahk_id " hWnd)

			if(!sProcess)
			{
				continue
			}

			tip := ""

			DllCall("ReadProcessMemory", Ptr, hProc, Ptr, iString, Ptr, &tip, UPtr, szTip, UPtr, 0)

			sToolTip := StrGet(&tip, "UTF-16")

			if(!sToolTip)
			{
				sToolTip := sProcess
			}

			if(sProcess = "TaskMgr.exe" && sToolTip = "Task Manager")
			{
				continue
			}
			else if(sProcess = "steam.exe")
			{
				;SendRainmeterCommand("[!SetOption BtnSteam RightMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 3`"]`"`"`" wwing]")
			;	SendRainmeterCommand("[!SetOption BtnSteam RightMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 6`"]`"`"`" wwing]")
				continue
			}
			else if(sProcess = "explorer.exe")
			{
				if(uID = "100" )
				{ 
					continue
				}
				;else
			;	{
					;Msgbox systemTrayData[sTray,nTrayIcon,"Tooltip"] " | " systemTrayData[sTray,nTrayIcon,"uID"]
			;	}
			}

			Index := Index + 1					
			;Index := (systemTrayData.MaxIndex()>0 ? systemTrayData.MaxIndex()+1 : 1)
			;systemTrayData[sTray,Index,"idx"]     := A_Index - 1
			;systemTrayData[sTray,Index,"IDcmd"]   := IDcmd
			systemTrayData[sTray,Index,"uID"]     := uID
			systemTrayData[sTray,Index,"msgID"]   := msgID
			systemTrayData[sTray,Index,"hIcon"]   := hIcon
			systemTrayData[sTray,Index,"hWnd"]    := hWnd
			systemTrayData[sTray,Index,"Process"] := sProcess
			systemTrayData[sTray,Index,"Tooltip"] := sToolTip
			systemTrayData[sTray,Index,"Tray"]    := sTray

			if(!iconCheck[hIcon])
			{
				processIconFolder := TrayIconDir "\" sProcess
							
				iconBitmap := Gdip_CreateBitmapFromHICON(hIcon)

				if(!dirExist(processIconFolder))
				{
					dirCreate(processIconFolder)
				}

				if(!iconBitmap)
				{

					iconCheck[hIcon] := A_WorkingDir . "\missing.png"
					systemTrayData[sTray,Index,"Tooltip"] := systemTrayData[sTray,Index,"Tooltip"] "`r`n`r`n Icon missing - Middle click to replace"
					return
				}

				iconPixels := Gdip_GetPixels(iconBitmap)
				iconMD5 := MD5(iconPixels)
				iconCheck[hIcon] := iconMD5
				iconFile := processIconFolder "\" iconMD5 ".png"

				if(!FileExist(iconFile))
				{
					SaveHICONtoRainmeter(hIcon,iconFile,iconMD5)
				}

				iconCheck[hIcon] := iconFile
			}

			if(sProcess = "wwing.exe")
			{
				systemTrayData[sTray,Index,"IconFile"] := A_WorkingDir . "\wwing.png"
				systemTrayData[sTray,Index,"Tooltip"] := "WingPanel Clone for Windows"
			}
			else
			{
				systemTrayData[sTray,Index,"IconFile"] := iconCheck[hIcon]
			}
			
		}

		if(systemTrayData[sTray].length() > Index)
		{
			systemTrayData[sTray].RemoveAt(Index , (systemTrayData[sTray].length() - Index))
		}
	}

	DllCall("VirtualFreeEx", Ptr, hProc, Ptr, pProc, UPtr, 0, Uint, 0x8000)
	DllCall("CloseHandle", Ptr, hProc)
	DetectHiddenWindows Setting_A_DetectHiddenWindows
}

renderSystrayIconTheme(workFile,renderTo)
{
    SendRainmeterCommand("[!SetOption magickmeter1 ExportTo `"" . renderTo . "`" wwing]")
    SendRainmeterCommand("[!SetOption magickmeter1 Image `"Rectangle 0,0,#vIconWidth#,#vIconHeight#  | Color 255,255,255,1  `"  wwing]")
    SendRainmeterCommand("[!SetOption magickmeter1 Image2 `"File " . workFile . " | RenderSize 24,24 | move ((#vIconWidth# - 24) / 2),((#vIconHeight# - 24) / 2)`"  wwing]")
    SendRainmeterCommand("[!UpdateMeasure magickmeter1 wwing]") 
}

updateCache(cacheObject,cacheString)
{
	if(!cacheObject["cache" cacheString] || cacheObject[cacheString] != cacheObject["cache" cacheString] )
	{
		cacheObject["cache" cacheString] = cacheObject[cacheString]
		return True
	}
}

LastSystrayCount := []

refreshSystemTray()
{
	Global systemTrayData
	Global LastSystrayCount
	Global rainIconName
	rainIconName := ["iconExpandedTray","iconSystray"]

	if(!systemTrayData)
	{
		return
	}

	for sTray in systemTrayData
	{
		TrayIndex := A_Index
		iconString := rainIconName[TrayIndex]
		TrayIconMax := 0

		for nTrayIcon in systemTrayData[sTray]
		{	
			iconSystray := iconString nTrayIcon		

			SendRainmeterCommand("[!SetOption `"" iconSystray "`" Hidden 0 wwing]")

			if(updateCache(systemTrayData[sTray,nTrayIcon],"hIcon"))
			{
				SendRainmeterCommand("[!SetOption " iconSystray " imagename `"" systemTrayData[sTray,nTrayIcon].IconFile "`" wwing]")
			}

			if(updateCache(systemTrayData[sTray,nTrayIcon],"Process"))
			{
				SendRainmeterCommand("[!SetOption " iconSystray " LeftMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 1`"]`"`"`" wwing]")
				SendRainmeterCommand("[!SetOption " iconSystray " MiddleMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 2`"]`"`"`" wwing]")
				SendRainmeterCommand("[!SetOption " iconSystray " RightMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 3`"]`"`"`" wwing]")
				SendRainmeterCommand("[!SetOption " iconSystray " LeftMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 4`"]`"`"`" wwing]")
				SendRainmeterCommand("[!SetOption " iconSystray " MiddleMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 5`"]`"`"`" wwing]")
				SendRainmeterCommand("[!SetOption " iconSystray " RightMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 6`"]`"`"`" wwing]")
			}

			if(updateCache(systemTrayData[sTray,nTrayIcon],"Tooltip") || updateCache(systemTrayData[sTray,nTrayIcon],"Process"))
			{
				SplitPath systemTrayData[sTray,nTrayIcon].Process , , , , sProcessName
				redirTooltip := systemTrayData[sTray,nTrayIcon].ToolTip
				if(sProcessName = "Explorer" || systemTrayData[sTray,nTrayIcon].Process = redirTooltip || sProcessName = redirTooltip)
				{
					sProcessName := redirTooltip
					redirTooltip := ""
				}
				SendRainmeterCommand("[!SetOption " iconSystray " MouseOverAction `"`"`"[!SetOption #CURRENTSECTION# SolidColor #vTooltipColor#][!UpdateMeter #CURRENTSECTION#][!Setoption MeterProcess Text `"" sProcessName "`" `"wwing\components\systray`"][!Setoption MeterTooltip Text `"" redirTooltip "`" `"wwing\components\systray`"][!Move `"([#CURRENTSECTION#:X] - ((#vSkinWidth#) / 2 - 24))`" `"40`" `"wwing\components\systray`"][!UpdateMeter `"MeterProcess`" `"wwing\components\systray`"][!UpdateMeter `"MeterTooltip`" `"wwing\components\systray`"][!Redraw `"wwing\components\systray`"][!Show `"wwing\components\systray`"]`"`"`" wwing]")
				SendRainmeterCommand("[!SetOption " iconSystray " MouseLeaveAction `"`"`"[!SetOption #CURRENTSECTION# SolidColor 0,0,0,1][!UpdateMeter #CURRENTSECTION#][!Hide `"wwing\components\systray`"]`"`"`" wwing]")
			}
			TrayIconMax := nTrayIcon
		}

		if(LastSystrayCount[TrayIndex] & LastSystrayCount[TrayIndex] != TrayIconMax)
		{
			if(LastSystrayCount[TrayIndex] > TrayIconMax)
			{			
				Loop (LastSystrayCount[TrayIndex] - TrayIconMax)
				{
					SendRainmeterCommand("[!HideMeter " iconString  (A_Index + TrayIconMax)  " wwing]")
				}
			}

		}
		LastSystrayCount[TrayIndex] := TrayIconMax
	}
}

ReplaceIcon(wParam, lParam, sTray)
{
	Global systemTrayData
	SelectedIcon := FileSelect(1, systemTrayData[sTray,wParam].IconFile, "Select the System Tray Icon for this Process that you wish to replace","(*.png)")
	if(SelectedIcon)
	{
		ReplacementIcon := FileSelect(1, , "Select the new Icon you wish to use","(*.png)")
		if(ReplacementIcon)
		{
			FileCopy  ReplacementIcon, SelectedIcon, 1
			SendRainmeterCommand("[!UpdateMeter iconSystray" nTrayIcon " wwing]")
		}
	}
}

SystrayClickNormal(wParam, lParam)
{
	ClickSystray(wParam, lParam, "Shell_TrayWnd")
}

SystrayClickExtended(wParam, lParam)
{
	ClickSystray(wParam, lParam, "NotifyIconOverflowWindow")
}

ClickSystray(wParam, lParam, systemTrayData)
{
  if(lParam = 1)
  {
    SendSystrayClick(systemTrayData,wParam,"LBUTTONDOWN")
  }
  else if(lParam = 2)
  {
	ReplaceIcon(wParam, lParam, systemTrayData)
  }
  else if(lParam = 3)
  {
    SendSystrayClick(systemTrayData,wParam,"RBUTTONDOWN")
  }
  else if(lParam = 4)
  {
    SendSystrayClick(systemTrayData,wParam,"LBUTTONUP")
  }
  else if(lParam = 6)
  {
    SendSystrayClick(systemTrayData,wParam,"RBUTTONUP")
  }
}

SendSystrayClick(trayObject, buttonIndex, sButton := "LBUTTONUP")
{
	Global systemTrayData	
	DetectHiddenWindows (Setting_A_DetectHiddenWindows := A_DetectHiddenWindows) ? "On" : "Off"
	WM_MOUSEMOVE	  := 0x0200
	WM_LBUTTONDOWN	  := 0x0201
	WM_LBUTTONUP	  := 0x0202
	WM_LBUTTONDBLCLK := 0x0203
	WM_RBUTTONDOWN	  := 0x0204
	WM_RBUTTONUP	  := 0x0205
	WM_RBUTTONDBLCLK := 0x0206
	WM_MBUTTONDOWN	  := 0x0207
	WM_MBUTTONUP	  := 0x0208
	WM_MBUTTONDBLCLK := 0x0209
	sButton := "WM_" sButton
	msgID  := systemTrayData[trayObject,buttonIndex].msgID
	uID    := systemTrayData[trayObject,buttonIndex].uID
	hWnd   := systemTrayData[trayObject,buttonIndex].hWnd
		
	Sleep 30
	SendMessage(msgID, uID, %sButton%, , "ahk_id " hWnd)

	DetectHiddenWindows Setting_A_DetectHiddenWindows
	return
}
