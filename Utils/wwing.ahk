#Persistent
SendMode Input
SetTitleMatchMode "RegEx"
#SingleInstance force
TraySetIcon(A_WorkingDir . "\wwing.ico")

SendRainmeterCommand("[!SetVariable AHKVersion " . A_AhkVersion . " wwing]")
SendRainmeterCommand("[!UpdateMeasure MeasureWindowMessage wwing]")
UserDir := EnvGet("USERPROFILE")
userProfileIconCheck()
downloadDir := UserDir . "\Downloads\*.*"
wwingDir := dirCheck(UserDir "\wwing")
trayIconDir := dirCheck(wwingDir "\trayIcons")
iconTmp := dirCheck(EnvGet("TMP") "\wwing")
iconCheck := {}
trayIconList := {}
lastMinMax := 0
systrayCount := 0
exTrayCount := 0
trayReading := 0
systemTrayData := {}



#Include inc_graphics.ahk
#Include inc_lib.ahk
#Include inc_systray.ahk

OnMessage(16686, "OpenDownloads")
OnMessage(16685, "OpenSearch")
OnMessage(16684, "OpenStart")
OnMessage(16683, "OpenNotifications")
OnMessage(16682, "SystrayClickNormal")
OnMessage(16681, "SystrayClickExtended")

SetTimerAndFire("cleanSystrayMemory",30000)
SetTimerAndFire("CheckForMaxedWindow", 150)
SetTimerAndFire("CheckForDownloadsInProgress", 2000)
SetTimerAndFire("TrayIcon_GetInfo", 250)
SetTimer("refreshSystemTray", 250)


showBackBar()
{
  CoordMode "Pixel", "Screen" 
  Sleep 200
  PixelColorHex := PixelGetColor(6,46)
  PixelColor := SplitRGBColor(PixelColorHex)        
  SendRainmeterCommand("[!SetOption ImageBackground SolidColor `"" PixelColor "`" wwing\components\background]")
  SendRainmeterCommand("[!Redraw wwing\components\background]")
  Sleep 100
  SendRainmeterCommand("[!ShowFade wwing\components\background]")
}

CheckForMaxedWindow()
{
  Global lastMinMax
  active_id := WinGetID("A")
  isminMax := WinGetMinMax("A")

  if(lastMinMax != isminMax)
  {
    if(isminMax = 1 && !IsWindowCloaked(active_id) && getIsOnMonitor(active_id))
    {
      showBackBar()
    }
    else
    {
      SendRainmeterCommand("[!HideFade wwing\components\background]")
    }
  }
  lastMinMax := isminMax
}





