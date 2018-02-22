GuiObj := GuiCreate("Disabled","VirtualDesktopSwitcher")
GuiObj.show
GuiObj.hide
iVirtualDesktopManager := ComObjCreate("{aa509086-5ca9-4c25-8f95-589d3c07b48a}", "{a5cd92ff-29be-454c-8d04-d82879fb3f1b}")
desktops := listDesktops()
setDesktopIndicator()

Guid_ToStr(ByRef VarOrAddress)
{
	pGuid := IsByRef(VarOrAddress) ? &VarOrAddress : VarOrAddress
	VarSetCapacity(sGuid, 78) ; (38 + 1) * 2
	if !DllCall("ole32\StringFromGUID2", "Ptr", pGuid, "Ptr", &sGuid, "Int", 39)
		throw Exception("Invalid GUID", -1, Format("<at {1:p}>", pGuid))
	return StrGet(&sGuid, "UTF-16")
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
	GuiObj.show("NoActivate")
	hwnd := GuiObj.Hwnd
	WinWait "ahk_id " hwnd
	desktopId := SubStr(RegExReplace(Guid_ToStr(getWindowDesktopId(hWnd)), "[-{}]"), 17)
	GuiObj.hide
	;WinWaitClose "ahk_id " hwnd
	;sleep 50 
	return desktopId
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

setDesktopIndicator(desktopN := 0)
{
	if(desktopN = 0)
	{
		Global desktops
		desktopId := getCurrentDesktopId()
		currentDesktopN := indexOf(desktops,desktopId)
	}
	else
	{
		currentDesktopN := desktopN
	}

	SendRainmeterCommand("[!SetOption BtnDesktopIndicator x `"[BtnDesktop" currentDesktopN ":x]`" wwing][!UpdateMeter BtnDesktopIndicator wwing][!ShowMeter BtnDesktopIndicator wwing]")
}

indexOf(obj, item)
{
	for i, val in obj {
		if (val = item)
		{
			return i
		}
	}
}

switchToDesktop(desktopN)
{
	
	Global desktops

	thisDesktop := getCurrentDesktopId()
	thisDesktopN := indexOf(desktops, thisDesktop)

	if(thisDesktop = desktops[desktopN])
	{
		return
	}
	else if(thisDesktopN > desktopN)
	{
		setDesktopIndicator(desktopN)
		loop (thisDesktopN - desktopN)
		{
			send "#^{Left}"
			Sleep 50
		}
	}
	else
	{
		setDesktopIndicator(desktopN)
		loop (desktopN - thisDesktopN)
		{
			send "#^{Right}"
			Sleep 50
		}
	}
}






