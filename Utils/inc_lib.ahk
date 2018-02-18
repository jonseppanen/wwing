;=======================================================================
;                   Determine if winID is on nMonitor
;=======================================================================
getIsOnMonitor(winID, nMonitor := "")
{
  MonitorGetWorkArea(nMonitor, monLeft, monTop, monRight, monBottom)
  WinGetPos(winX,winY,Width,Height,"ahk_id " winID)

  if((Width - 8) <= monRight && (winX + 4) >= monLeft && (winY + 4) >= monTop && (Height + 8) <= monBottom)
  {
    return True
  }
  else
  {
    return false
  }
}


;=======================================================================
;                   Get User's profile PIC if win10
;=======================================================================
userProfileIconCheck()
{
    if(SubStr(A_OSVersion,1,2) < 10)
    {
        return
    }
    
    Global UserDir
    if(!FileExist(UserDir . "\wwing\profile.bmp"))
    {
        Loop Files, UserDir . "\AppData\Roaming\Microsoft\Windows\AccountPictures\*" 
        {
            if(A_LoopFileExt = "accountpicture-ms")
            {
            RunWait("AccountPicConverter.exe " . A_LoopFileFullPath,,hide)
            FileDelete "*-448.bmp"
            FileMove "*-96.bmp", UserDir . "\wwing\profile.bmp",true
            break
            }
        }
    }

}


;=======================================================================
;            Check if a directory exists, and if not, build
;=======================================================================
dirCheck(targetDir)
{
    if(!dirExist(targetDir))
    {
        dirCreate(targetDir)
    }
    return targetDir
}


;=======================================================================
;            One Liner to check if start menu is open
;=======================================================================
AppVisibility := ComObjCreate(CLSID_AppVisibility := "{7E5FE3D9-985F-4908-91F9-EE19F9FD1514}", IID_IAppVisibility := "{2246EA2D-CAEA-4444-A3C4-6DE827E44313}")


;=======================================================================
;            Check if the window is a cloaked metro window
;=======================================================================
IsWindowCloaked(hwnd) {
    static gwa := DllCall("GetProcAddress", "ptr", DllCall("LoadLibrary", "str", "dwmapi", "ptr"), "astr", "DwmGetWindowAttribute", "ptr")
    return (gwa && DllCall(gwa, "ptr", hwnd, "int", 14, "int*", cloaked, "int", 4) = 0) ? cloaked : 0
}


;=======================================================================
;            Various File and directory handlers...
;=======================================================================
OpenDownloads(){
  global UserDir
  If(WinExist(Downloads))
  {
      WinActivate
  }
  else{
      Run(explore UserDir . "\Downloads")
  }
}

OpenSearch(){
  Global isStartOpen := true
  send "#s"
}

OpenStart(){
  Global isStartOpen := true
  sendinput "{LWin}"
}

OpenNotifications(){
  sendinput "#a"
}


;=======================================================================
;            Check progress of any downloading files
;=======================================================================
CheckForDownloadsInProgress(){
  Global downloadDir
  Loop files, downloadDir 
  {        
      If (a_LoopFileExt = "part" || a_LoopFileExt = "partial" || a_LoopFileExt = "crdownload")
      {
          SendRainmeterCommand("[!SetVariable Downloading 1 wwing]")
          return
      }
      else
      {
          SendRainmeterCommand("[!SetVariable Downloading 0 wwing]")
      }
  }
}

;=======================================================================
;            Send a command to rainmeter
;=======================================================================
SendRainmeterCommand(command) {
    if(Send_WM_COPYDATA(command, "ahk_class RainmeterMeterWindow") = 1)
    {
        WinShow("ahk_class Shell_TrayWnd")
        WinShow("ahk_class Start Button")
        ExitApp
    }
    else{
        WinHide("ahk_class Shell_TrayWnd")
        WinHide("ahk_class Start Button")
    }
}


;=======================================================================
;            Send a Window Message
;=======================================================================
Send_WM_COPYDATA(ByRef StringToSend, ByRef TargetWindowClass)  
{
    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)  ; Set up the structure's memory area.
    ; First set the structure's cbData member to the size of the string, including its zero terminator:
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(1, CopyDataStruct) ; Per example at https://docs.rainmeter.net/developers/
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)  ; OS requires that this be done.
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)  ; Set lpData to point to the string itself.
    SendMessage(0x4a, 0, &CopyDataStruct,, "ahk_class " TargetWindowClass)  ; 0x4a is WM_COPYDATA. Must use Send not Post.
    return ErrorLevel  ; Return SendMessage's reply back to our caller.
}


;=======================================================================
;            MD5 check a string
;=======================================================================
MD5(string, case := False)    ; by SKAN | rewritten by jNizM
{
    static MD5_DIGEST_LENGTH := 16
    hModule := DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
    , VarSetCapacity(MD5_CTX, 104, 0), DllCall("advapi32\MD5Init", "Ptr", &MD5_CTX)
    , DllCall("advapi32\MD5Update", "Ptr", &MD5_CTX, "AStr", string, "UInt", StrLen(string))
    , DllCall("advapi32\MD5Final", "Ptr", &MD5_CTX)
    loop (MD5_DIGEST_LENGTH)
    { 
		   o .= Format("{:02" (case ? "X" : "x") "}", NumGet(MD5_CTX, 87 + A_Index, "UChar"))
	}
	DllCall("FreeLibrary", "Ptr", hModule)
    return o
}

;=======================================================================
;            setTimerAndFire, does as it says
;=======================================================================
SetTimerAndFire(timedFunction, timedDuration)
{
    %timedFunction%()
    SetTimer timedFunction, timedDuration
}

;=======================================================================
;            :D
;=======================================================================
EmptyMem(PIDtoEmpty)
{   
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", PIDtoEmpty)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
}