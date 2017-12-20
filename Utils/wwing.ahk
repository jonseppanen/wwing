#Persistent
SendMode Input
SetTitleMatchMode "RegEx"
#SingleInstance force

downloadDir := "C:\Users\" . A_UserName . "\Downloads\*.*"
WatchState := 10
AppVisibility := ComObjCreate(CLSID_AppVisibility := "{7E5FE3D9-985F-4908-91F9-EE19F9FD1514}", IID_IAppVisibility := "{2246EA2D-CAEA-4444-A3C4-6DE827E44313}")
OnMessage(16687, "HeartBeat")
OnMessage(16686, "OpenDownloads")
OnMessage(16685, "OpenSearch")
OnMessage(16684, "OpenStart")
OnMessage(16683, "OpenNotifications")
SetTimer "CheckForMaxedWindow", 150
SetTimer "CheckForDownloadsInProgress", 2000

if(!FileExist("C:\Users\" . A_UserName . "\profile.bmp"))
{
  Loop Files, "C:\Users\" . A_UserName . "\AppData\Roaming\Microsoft\Windows\AccountPictures\*" 
  {
    if(A_LoopFileExt = "accountpicture-ms")
    {
      RunWait("AccountPicConverter.exe " . A_LoopFileFullPath,,hide)
      FileDelete "*-448.bmp"
      FileMove "*-96.bmp", "C:\Users\" . A_UserName . "\profile.bmp",true
      break
    }
  }
}
return

OpenDownloads(){
  If(WinExist(Downloads))
  {
      WinActivate
  }
  else{
      Run(explore "C:\Users\" . A_UserName . "\Downloads")
  }
}

OpenSearch(){
  send "#s"
}

OpenStart(){
  SendRainmeterCommand("[!SetVariable MinMax 1]")
  sendinput "{LWin}"
}

OpenNotifications(){
  sendinput "#a"
}

HeartBeat(wParam, lParam) { 
global WatchState
  If (wParam = 2) {
    WatchState := 10
    ;MsgBox(lParam)
  }
}

IsWindowCloaked(hwnd) {
    static gwa := DllCall("GetProcAddress", "ptr", DllCall("LoadLibrary", "str", "dwmapi", "ptr"), "astr", "DwmGetWindowAttribute", "ptr")
    return (gwa && DllCall(gwa, "ptr", hwnd, "int", 14, "int*", cloaked, "int", 4) = 0) ? cloaked : 0
}

SendRainmeterCommand(command) {
  id := WinGetList("ahk_class RainmeterMeterWindow",,,)
  Loop id.Length()
  {
      thisId := id[A_Index]
      WinGetPos(X,Y,,H,"ahk_id " thisId)
      if(H = 40 && X = 0 && Y = 0){
          Send_WM_COPYDATA(command, "ahk_id " thisId)
          break
      }
  }
}

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

CheckForMaxedWindow(){
  Global WatchState
  Global AppVisibility
  WatchState--

  If (WatchState < 1) {
    WinShow("ahk_class Shell_TrayWnd")
    WinShow("ahk_class Start Button")
    ExitApp
  }
  else
  {
    WinHide("ahk_class Shell_TrayWnd")
    WinHide("ahk_class Start Button")
    MinMaxVariable := 0
    id := WinGetList(,, "Program Manager|^$")
    Loop id.Length()
    {
      thisId := id[A_Index]
      minMax := WinGetMinMax("ahk_id " thisId)
      WinGetPos(,,, Height,"ahk_id " thisId)      
      If ((minMax = 1 && Height && !IsWindowCloaked(thisId))|| (DllCall(NumGet(NumGet(AppVisibility+0)+4*A_PtrSize), "Ptr", AppVisibility, "Int*", fVisible) >= 0) && fVisible = 1 )
      {
        MinMaxVariable := 1
        break
      }
    }
    SendRainmeterCommand("[!SetVariable MinMax " . MinMaxVariable .  "]")
  }
}

CheckForDownloadsInProgress(){
  Global downloadDir
  Loop files, downloadDir 
  {        
      If (a_LoopFileExt = "part" || a_LoopFileExt = "partial" || a_LoopFileExt = "crdownload")
      {
          SendRainmeterCommand("[!SetVariable Downloading 1]")
          return
      }
      else
      {
          SendRainmeterCommand("[!SetVariable Downloading 0]")
      }
  }
}


