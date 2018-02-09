#Persistent
SendMode Input
SetTitleMatchMode "RegEx"
#SingleInstance force

SendRainmeterCommand("[!SetVariable AHKVersion " . A_AhkVersion . " wwing]")
SendRainmeterCommand("[!UpdateMeasure MeasureWindowMessage wwing]")
UserDir := EnvGet("USERPROFILE")
wwingDir := UserDir "\wwing"
trayIconDir := wwingDir "\trayIcons"
downloadDir := UserDir . "\Downloads\*.*"
iconTmp := EnvGet("TMP") "\wwing"
;FileDelete iconTmp . "\*.bmp"

if(!dirExist(iconTmp))
{
  dirCreate(iconTmp)
}
if(!dirExist(trayIconDir))
{
  dirCreate(trayIconDir)
}

AppVisibility := ComObjCreate(CLSID_AppVisibility := "{7E5FE3D9-985F-4908-91F9-EE19F9FD1514}", IID_IAppVisibility := "{2246EA2D-CAEA-4444-A3C4-6DE827E44313}")
OnMessage(16686, "OpenDownloads")
OnMessage(16685, "OpenSearch")
OnMessage(16684, "OpenStart")
OnMessage(16683, "OpenNotifications")
OnMessage(16682, "ClickSystray")
;OnMessage(16681, "systrayTooltip")
SetTimer "CheckForMaxedWindow", 150
SetTimer "CheckForDownloadsInProgress", 2000
#Include systray.ahk
;refreshSystemTray()
iconCheck := {}
trayIconList := {}

systrayCount := 0
exTrayCount := 0

SetTimer "refreshSystemTray", 2000

refreshSystemTray()
{
  Global trayIconList
  Global iconTmp
  Global systrayCount
  Global exTrayCount

  trayIconListCheck := TrayIcon_GetInfo()
  L1Counter := 0
  L2Counter := 0

 /* trayIconListCount := trayIconList ? trayIconList.length() : 0
  trayIconListCheckCount := trayIconListCheck.length()

  if(trayIconListCount != trayIconListCheckCount)
    {
        if(trayIconListCount > trayIconListCheckCount)
        {
            Loop (trayIconListCount - trayIconListCheckCount)
            {
                SendRainmeterCommand("!SetOption Task" .  (A_Index + trayIconListCheckCount) . " ImageName `"`" ")
                SendRainmeterCommand("!HideMeter Task" .  (A_Index + trayIconListCheckCount) . " ")
            }
        }
        ShiftDock(trayIconListCount,trayIconListCheckCount)
    }
*/

  for nTrayIcon in trayIconListCheck
  {
    if(trayIconListCheck[nTrayIcon,"Process"] = "steam.exe")
    {
      SendRainmeterCommand("[!SetOption BtnSteam RightMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 3`"]`"`"`" wwing]")
      SendRainmeterCommand("[!SetOption BtnSteam RightMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 6`"]`"`"`" wwing]")
      continue
    }
    if(trayIconListCheck[nTrayIcon,"Process"] = "explorer.exe")
    {
      if(trayIconListCheck[nTrayIcon,"uID"] = "100" || trayIconListCheck[nTrayIcon,"uID"] = "49486")
      { 
        continue
      }
      ;else
     ; {
     ;   Msgbox trayIconListCheck[nTrayIcon,"Tooltip"] " | " trayIconListCheck[nTrayIcon,"uID"]
    ;  }
     
    }

    if(trayIconListCheck[nTrayIcon,"Tray"] = "Shell_TrayWnd")
    {
      L1Counter := L1Counter + 1
      iconSystray := "iconSystray" L1Counter
    }
    else
    {
      L2Counter := L2Counter + 1
      iconSystray := "iconExpandedTray" L2Counter
    }
    
    SendRainmeterCommand("[!SetOption `"" iconSystray "`" Hidden 0 wwing]")
    
    ;Get systray images...
    if(!trayIconList || trayIconListCheck[nTrayIcon,"IconFile"] != trayIconList[nTrayIcon,"IconFile"] )
    {
      SendRainmeterCommand("[!SetOption " iconSystray " imagename `"" trayIconListCheck[nTrayIcon].IconFile "`" wwing]")
    }
    
    ;Get systray click handlers...
    if(!trayIconList || trayIconListCheck[nTrayIcon,"Process"] != trayIconList[nTrayIcon,"Process"] )
    {
      SendRainmeterCommand("[!SetOption " iconSystray " LeftMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 1`"]`"`"`" wwing]")
      SendRainmeterCommand("[!SetOption " iconSystray " MiddleMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 2`"]`"`"`" wwing]")
      SendRainmeterCommand("[!SetOption " iconSystray " RightMouseDownAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 3`"]`"`"`" wwing]")
      SendRainmeterCommand("[!SetOption " iconSystray " LeftMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 4`"]`"`"`" wwing]")
      SendRainmeterCommand("[!SetOption " iconSystray " MiddleMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 5`"]`"`"`" wwing]")
      SendRainmeterCommand("[!SetOption " iconSystray " RightMouseUpAction `"`"`"[!CommandMeasure MeasureWindowMessage `"SendMessage 16682 " nTrayIcon " 6`"]`"`"`" wwing]")
    }

    ;Get text and tooltip info...
    if(!trayIconList || trayIconListCheck[nTrayIcon,"Process"] != trayIconList[nTrayIcon,"Process"] || trayIconListCheck[nTrayIcon,"ToolTip"] != trayIconList[nTrayIcon,"ToolTip"])
    {
      SplitPath trayIconListCheck[nTrayIcon].Process , , , , sProcessName


      redirTooltip := trayIconListCheck[nTrayIcon,"ToolTip"]
      if(sProcessName = "Explorer" || trayIconListCheck[nTrayIcon].Process = redirTooltip || sProcessName = redirTooltip)
      {
        sProcessName := redirTooltip
        redirTooltip := ""
      }
      SendRainmeterCommand("[!SetOption " iconSystray " MouseOverAction `"`"`"[!SetOption #CURRENTSECTION# SolidColor #vTooltipColor#][!UpdateMeter #CURRENTSECTION#][!Setoption MeterProcess Text `"" sProcessName "`" `"wwing\components\systray`"][!Setoption MeterTooltip Text `"" redirTooltip "`" `"wwing\components\systray`"][!Move `"([#CURRENTSECTION#:X] - ((#vSkinWidth#) / 2 - 24))`" `"40`" `"wwing\components\systray`"][!UpdateMeter `"MeterProcess`" `"wwing\components\systray`"][!UpdateMeter `"MeterTooltip`" `"wwing\components\systray`"][!Redraw `"wwing\components\systray`"][!Show `"wwing\components\systray`"]`"`"`" wwing]")
      SendRainmeterCommand("[!SetOption " iconSystray " MouseLeaveAction `"`"`"[!SetOption #CURRENTSECTION# SolidColor 0,0,0,1][!UpdateMeter #CURRENTSECTION#][!Hide `"wwing\components\systray`"]`"`"`" wwing]")
    }
  }

  if(systrayCount != L1Counter)
  {
      if(systrayCount > L1Counter)
      {
          Loop (systrayCount - L1Counter)
          {
              SendRainmeterCommand("[!HideMeter iconSystray" .  (A_Index + L1Counter) . " wwing]")
          }
          SendRainmeterCommand("[!UpdateMeterGroup Level1 wwing]")
      }
  }

  if(exTrayCount != L2Counter)
  {
      if(exTrayCount > L2Counter)
      {
          Loop (exTrayCount - L2Counter)
          {
              SendRainmeterCommand("[!HideMeter iconExpandedTray" .  (A_Index + L2Counter) . " wwing]")
          }
          SendRainmeterCommand("[!UpdateMeterGroup Level2 wwing]")
      }
  }

  systrayCount := L1Counter
  exTrayCount := L2Counter
  trayIconList := trayIconListCheck  
}


ClickSystray(wParam, lParam)
{
  Global trayIconList
  if(lParam = 1)
  {
    TrayIcon_ButtonIndex(trayIconList,wParam,"LBUTTONDOWN")
  }
  else if(lParam = 2)
  {
    SelectedIcon := FileSelect(1, trayIconList[wParam].IconFile, "Select the System Tray Icon for this Process that you wish to replace","(*.png)")
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
  else if(lParam = 3)
  {
    TrayIcon_ButtonIndex(trayIconList,wParam,"RBUTTONDOWN")
  }
  else if(lParam = 4)
  {
    TrayIcon_ButtonIndex(trayIconList,wParam,"LBUTTONUP")
  }
  else if(lParam = 6)
  {
    TrayIcon_ButtonIndex(trayIconList,wParam,"RBUTTONUP")
  }
}

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
return

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
  send "#s"
}

OpenStart(){
  SendRainmeterCommand("[!SetVariable MinMax 1 wwing]")
  sendinput "{LWin}"
}

OpenNotifications(){
  sendinput "#a"
}

IsWindowCloaked(hwnd) {
    static gwa := DllCall("GetProcAddress", "ptr", DllCall("LoadLibrary", "str", "dwmapi", "ptr"), "astr", "DwmGetWindowAttribute", "ptr")
    return (gwa && DllCall(gwa, "ptr", hwnd, "int", 14, "int*", cloaked, "int", 4) = 0) ? cloaked : 0
}

SendRainmeterCommand(command) {
    if(Send_WM_COPYDATA(command, "ahk_class RainmeterMeterWindow") = 1){
        WinShow("ahk_class Shell_TrayWnd")
        WinShow("ahk_class Start Button")
        ExitApp
    }
    else{
        WinHide("ahk_class Shell_TrayWnd")
        WinHide("ahk_class Start Button")
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
  Global AppVisibility
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
  SendRainmeterCommand("[!SetVariable MinMax " . MinMaxVariable .  " wwing]")
}

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



