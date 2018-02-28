OpenDesktops(){
  send "#{tab}"
}

goToDesktop(wParam, lParam){
  switchToDesktop(wParam)
}

getWindowDesktopId(hWnd) 
{
	Global iVirtualDesktopManager
	
	desktopId := ""
	VarSetCapacity(desktopID, 16, 0)

	Error := DllCall(NumGet(NumGet(iVirtualDesktopManager+0), 4*A_PtrSize), "Ptr", iVirtualDesktopManager, "Ptr", hWnd, "Ptr", &desktopID)			
	return &desktopID
}

getCurrentDesktopId()
{
	Global GuiObj
	Global interrupt_getCurrentDesktopId

	if(WinGetClass("A") = "MultitaskingViewFrame")
    {
		exit
    }

	if(interrupt_getCurrentDesktopId)
	{
		interrupt_getCurrentDesktopId := false
		SetTimer("getCurrentDesktopId","off")
		SetTimer("getCurrentDesktopId","on")
		exit
	}

	SetTimer("getCurrentDesktopId","off")

	hwnd := GuiObj.Hwnd
	GuiObj.show("NoActivate")
	WinWait "ahk_id " hwnd,,0.5
	GuiObj.opt("-ToolWindow")
	thisDesktopID := SubStr(RegExReplace(Guid_ToStr(getWindowDesktopId(hWnd)), "[-{}]"), 17)
	GuiObj.opt("+ToolWindow")

	GuiObj.hide
	if(thisDesktopID < 1)
	{
		SetTimer("getCurrentDesktopId","on")
		exit
	}
	
	Global currentDesktopN
	Global currentDesktopID
	Global desktops
	thisDesktopN := indexOf(desktops, thisDesktopID)
	if(currentDesktopN != thisDesktopN)
	{
		currentDesktopN := thisDesktopN
		setDesktopIndicator(thisDesktopN)
	}

	SetTimer("getCurrentDesktopId","on")
	
}


listDesktops()
{
	regIdLength := 32
	DesktopList := RegRead("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops", "VirtualDesktopIDs")	
	desktops := []
	rainmeterCommand := ""
	while true
	{
		desktopId := SubStr(DesktopList, ((A_index-1) * regIdLength) + 1, regIdLength)
		if(desktopId) 
		{
			if(A_index = 1)
			{
				rainmeterCommand := "[!ShowMeter BtnDesktops wwing]"
			}
			rainmeterCommand := rainmeterCommand . "[!ShowMeter BtnDesktop" A_Index " wwing]"
			desktops.push(SubStr(desktopId, 17))
		} 
		else
		{
			break
		}
	}
	if(desktops.length() > 1)
	{
		SendRainmeterCommand(rainmeterCommand)
	}
	
	return desktops
}	

setDesktopIndicator(desktopN)
{
	SendRainmeterCommand("[!SetOption BtnDesktopIndicator x `"[BtnDesktop" desktopN ":x]`" wwing][!UpdateMeter BtnDesktopIndicator wwing][!ShowMeter BtnDesktopIndicator wwing][!Redraw wwing]")
}

pauseRaindock()
{
	if(winExist("raindock.ahk - AutoHotkey v2.0-a083-97803ae"))
	{
		Send_WM_COPYDATA("pauseRaindock","raindock.ahk - AutoHotkey v2.0-a083-97803ae")
	}
}

resumeRaindock()
{
	if(winExist("raindock.ahk - AutoHotkey v2.0-a083-97803ae"))
	{
		Send_WM_COPYDATA("resumeRaindock","raindock.ahk - AutoHotkey v2.0-a083-97803ae")
	}
}

switchToDesktop(selectedDesktopN)
{
	
	Global desktops
	Global currentDesktopID
	Global currentDesktopN
	Global interrupt_getCurrentDesktopId
	previousDesktopN := currentDesktopN

	if(currentDesktopID = desktops[selectedDesktopN])
	{
		return
	}
	else 
	{
		pauseRaindock()
		interrupt_getCurrentDesktopId := true
		currentDesktopN := selectedDesktopN
		if(previousDesktopN > selectedDesktopN)
		{
			loop (previousDesktopN - selectedDesktopN)
			{
				send "#^{Left}"
				Sleep 100
			}
		}
		else
		{
			loop (selectedDesktopN - previousDesktopN)
			{
				send "#^{Right}"
				Sleep 100
			}
		}
		resumeRaindock()
	}
}


currentDesktopID := ""
currentDesktopN := ""
GuiObj := GuiCreate("Disabled Toolwindow","VirtualDesktopSwitcher")
GuiObj.show
GuiObj.hide
iVirtualDesktopManager := ComObjCreate("{aa509086-5ca9-4c25-8f95-589d3c07b48a}", "{a5cd92ff-29be-454c-8d04-d82879fb3f1b}")
desktops := listDesktops()