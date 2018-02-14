systrayPID := 0

TrayIcon_GetInfo()
{
	DetectHiddenWindows (Setting_A_DetectHiddenWindows := A_DetectHiddenWindows) ? "On" : "Off"
	;systemTrayData := {}
	Global iconCheck
	Global trayIconDir
	Global systemTrayData
	Global trayReading
	Global systrayPID

	trayArray := {"Shell_TrayWnd":"User Promoted Notification Area","NotifyIconOverflowWindow":"Overflow Notification Area"}

	for sTray,trayCall in trayArray
	{
		pidTaskbar := WinGetPID("ahk_class " sTray)		
		systrayPID := pidTaskbar
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

			;iBitmap := NumGet(btn, 0, "Int")     
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

			if(!hWnd)
			{
				PostMessage(0x12, 0, 0, , trayId)
				Sleep 250
				Run "explorer.exe"
				Sleep 250
				return
			}
			
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
			else if(sProcess = "wwing.exe")
			{
				sToolTip := "WingPanel Clone for Windows"
			}

			if((sProcess = "TaskMgr.exe" && sToolTip = "Task Manager") || sProcess = "spotify.exe")
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
				processIconFolder := dirCheck(TrayIconDir "\" sProcess)
							
				iconBitmap := Gdip_CreateBitmapFromHICON(hIcon)

				if(!iconBitmap)
				{
					iconCheck[hIcon] := A_WorkingDir . "\missing.png"
					systemTrayData[sTray,Index,"Tooltip"] := systemTrayData[sTray,Index,"Tooltip"] "`r`n`r`n Icon missing - Middle click to replace"
					return
				}

				iconPixels := Gdip_GetPixels(iconBitmap)
				iconMD5 := MD5(iconPixels)
				iconFilePNG := processIconFolder "\" iconMD5 ".png"
				iconFileICO := processIconFolder "\" iconMD5 ".ico"

				if(sProcess = "wwing.exe")
				{
					iconCheck[hIcon] := A_WorkingDir . "\wwing.png"
				}
				else if(FileExist(iconFilePNG))
				{
					iconCheck[hIcon] := iconFilePNG
				}
				else 
				{	
					if(!FileExist(iconFileICO))
					{
						SaveHICONtoFile(hicon,iconFileICO)
					}

					iconCheck[hIcon] := iconFileICO
				}			
			}
			systemTrayData[sTray,Index,"IconFile"] := iconCheck[hIcon]
		}

		if(TrayCount & !systemTrayData[sTray])
		{
			return
		}

		if(!systemTrayData[sTray])
		{
			return
		}

		if(systemTrayData[sTray].length() > Index)
		{
			systemTrayData[sTray].RemoveAt((Index + 1), (systemTrayData[sTray].length() - Index))
		}	

	}

	DllCall("VirtualFreeEx", Ptr, pRB, Ptr, hProc, Ptr, pProc, UPtr, 0, Uint, MEM_RELEASE)
	DllCall("CloseHandle", Ptr, hProc)
	DetectHiddenWindows Setting_A_DetectHiddenWindows
}

cleanSystrayMemory()
{
	Global systrayPID
	EmptyMem(systrayPID)
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
		cacheObject["cache" cacheString] := cacheObject[cacheString]
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
		RainMeterCommand := ""
		loop 20
		{
			nTrayIcon := A_Index
			iconSystray := iconString nTrayIcon		

			if(!systemTrayData[sTray,nTrayIcon])
			{
				RainMeterCommand := RainMeterCommand  "[!SetOption `"" iconSystray "`" Hidden 1 wwing]"
				continue
			}

			RainMeterCommand := RainMeterCommand "[!SetOption `"" iconSystray "`" Hidden 0 wwing]"

			if(updateCache(systemTrayData[sTray,nTrayIcon],"hIcon"))
			{
				SplitPath systemTrayData[sTray,nTrayIcon].IconFile , , ,iconExt

				if(iconExt = "ico")
				{
					varStyle := " | styleSystrayIconUnstyled"
				}
				else
				{
					varStyle := ""
				}
				
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " imagename `"" systemTrayData[sTray,nTrayIcon].IconFile "`" wwing]"
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " MeterStyle `" #iconStyleSystray" TrayIndex "# " varStyle " `" wwing]"
			}

			if(updateCache(systemTrayData[sTray,nTrayIcon],"Process"))
			{
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " LeftMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 1`"]`"`"`" wwing]"
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " LeftMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 1`"]`"`"`" wwing]"
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " RightMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 3`"]`"`"`" wwing]"
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " LeftMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 4`"]`"`"`" wwing]"
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " MiddleMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 5`"]`"`"`" wwing]"
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " RightMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 1668" TrayIndex " " nTrayIcon " 6`"]`"`"`" wwing]"
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
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " MouseOverAction `"`"`"[!SetOption #CURRENTSECTION# SolidColor #vTooltipColor#][!UpdateMeter #CURRENTSECTION#][!Setoption MeterProcess Text `"" sProcessName "`" `"wwing\components\systray`"][!Setoption MeterTooltip Text `"" redirTooltip "`" `"wwing\components\systray`"][!Move `"([#CURRENTSECTION#:X] - ((#vSkinWidth#) / 2 - 24))`" `"40`" `"wwing\components\systray`"][!UpdateMeter `"MeterProcess`" `"wwing\components\systray`"][!UpdateMeter `"MeterTooltip`" `"wwing\components\systray`"][!Redraw `"wwing\components\systray`"][!Show `"wwing\components\systray`"]`"`"`" wwing]"
				RainMeterCommand := RainMeterCommand "[!SetOption " iconSystray " MouseLeaveAction `"`"`"[!SetOption #CURRENTSECTION# SolidColor 0,0,0,1][!UpdateMeter #CURRENTSECTION#][!Hide `"wwing\components\systray`"]`"`"`" wwing]"
			}
		}

		SendRainmeterCommand(RainMeterCommand)
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
			SendRainmeterCommand("[!UpdateMeter iconSystray" wParam " wwing]")
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
