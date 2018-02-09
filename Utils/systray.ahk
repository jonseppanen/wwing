; ----------------------------------------------------------------------------------------------------------------------
; Name ..........: TrayIcon library
; Description ...: Provide some useful functions to deal with Tray icons.
; AHK Version ...: AHK_L 1.1.22.02 x32/64 Unicode
; Original Author: Sean (http://goo.gl/dh0xIX) (http://www.autohotkey.com/forum/viewtopic.php?t=17314)
; Update Author .: Cyruz (http://ciroprincipe.info) (http://ahkscript.org/boards/viewtopic.php?f=6&t=1229)
; Mod Authors ...: Fanatic Guru, RiseUp
; License .......: WTFPL - http://www.wtfpl.net/txt/copying/
; Version Date...: 2017 - 11 - 24
; Note ..........: Many people have updated Sean's original work including me but Cyruz's version seemed the most straight
; ...............: forward update for 64 bit so I adapted it with some of the features from my Fanatic Guru version.
; Update 20160120: Went through all the data types in the DLL and NumGet and matched them up to MSDN which fixed IDcmd.
; Update 20160308: Fix for Windows 10 NotifyIconOverflowWindow
; Update 20171124: (RiseUp) Added extra Shell_TrayWnd to account for odd numbering (N) in ToolbarWindow32N
; Update 20180204: (Ashtefere) Rewrote for AHK V2
; ----------------------------------------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------------------------------------
; Function ......: TrayIcon_GetInfo
; Description ...: Get a series of useful information about tray icons.
; Parameters ....: sExeName  - The exe for which we are searching the tray icon data. Leave it empty to receive data for 
; ...............:             all tray icons.
; Return ........: oTrayIcon_GetInfo - An array of objects containing tray icons data. Any entry is structured like this:
; ...............:             oTrayIcon_GetInfo[A_Index].idx     - 0 based tray icon index.
; ...............:             oTrayIcon_GetInfo[A_Index].IDcmd   - Command identifier associated with the button.
; ...............:             oTrayIcon_GetInfo[A_Index].pID     - Process ID.
; ...............:             oTrayIcon_GetInfo[A_Index].uID     - Application defined identifier for the icon.
; ...............:             oTrayIcon_GetInfo[A_Index].msgID   - Application defined callback message.
; ...............:             oTrayIcon_GetInfo[A_Index].hIcon   - Handle to the tray icon.
; ...............:             oTrayIcon_GetInfo[A_Index].hWnd    - Window handle.
; ...............:             oTrayIcon_GetInfo[A_Index].Class   - Window class.
; ...............:             oTrayIcon_GetInfo[A_Index].Process - Process executable.
; ...............:             oTrayIcon_GetInfo[A_Index].Tray    - Tray Type (Shell_TrayWnd or NotifyIconOverflowWindow).
; ...............:             oTrayIcon_GetInfo[A_Index].tooltip - Tray icon tooltip.
; Info ..........: TB_BUTTONCOUNT message - http://goo.gl/DVxpsg
; ...............: TB_GETBUTTON message   - http://goo.gl/2oiOsl
; ...............: TBBUTTON structure     - http://goo.gl/EIE21Z
; ----------------------------------------------------------------------------------------------------------------------




TrayIcon_GetInfo()
{
	DetectHiddenWindows (Setting_A_DetectHiddenWindows := A_DetectHiddenWindows) ? "On" : "Off"
	oTrayIcon_GetInfo := {}
	Global iconCheck
	Global trayIconDir

	trayArray := {"Shell_TrayWnd":"User Promoted Notification Area","NotifyIconOverflowWindow":"Overflow Notification Area"}

	for sTray,trayCall in trayArray
	{
		;sTray := "Shell_TrayWnd"
		;trayCall := "User Promoted Notification Area"

		pidTaskbar := WinGetPID("ahk_class " sTray)		

		hProc := DllCall("OpenProcess", UInt, 0x38, Int, 0, UInt, pidTaskbar)
		pRB   := DllCall("VirtualAllocEx", Ptr, hProc, Ptr, 0, UPtr, 20, UInt, 0x1000, UInt, 0x4)

		TrayCount := SendMessage(0x418, 0, 0, trayCall, "ahk_class " sTray)   ; TB_BUTTONCOUNT

		szBtn := VarSetCapacity(btn, (A_Is64bitOS ? 32 : 20), 0)
		szNfo := VarSetCapacity(nfo, (A_Is64bitOS ? 32 : 24), 0)
		szTip := VarSetCapacity(tip, 128 * 2, 0)
		
		Loop TrayCount
		{
			SendMessage(0x417, A_Index - 1, pRB, trayCall, "ahk_class " sTray)   ; TB_GETBUTTON
			DllCall("ReadProcessMemory", Ptr, hProc, Ptr, pRB, Ptr, &btn, UPtr, szBtn, UPtr, 0)
			
			iBitmap := NumGet(btn, 0, "Int")     
			IDcmd   := NumGet(btn, 4, "Int")
			statyle := NumGet(btn, 8)
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
						
			Index := (oTrayIcon_GetInfo.MaxIndex()>0 ? oTrayIcon_GetInfo.MaxIndex()+1 : 1)
			oTrayIcon_GetInfo[Index,"idx"]     := A_Index - 1
			oTrayIcon_GetInfo[Index,"IDcmd"]   := IDcmd
			oTrayIcon_GetInfo[Index,"uID"]     := uID
			oTrayIcon_GetInfo[Index,"msgID"]   := msgID
			oTrayIcon_GetInfo[Index,"hIcon"]   := hIcon
			oTrayIcon_GetInfo[Index,"hWnd"]    := hWnd
			oTrayIcon_GetInfo[Index,"Process"] := sProcess
			oTrayIcon_GetInfo[Index,"Tooltip"] := sToolTip
			oTrayIcon_GetInfo[Index,"Tray"]    := sTray

			

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
					if(sProcess = "DiscordPTB.exe")
					{	
						iconCheck[hIcon] := processIconFolder "\6ac067679afa62c7fd0b9ae6819653a8.png"
					}
					else
					{
						iconCheck[hIcon] := processIconFolder "\e35e69ea0dabfb97b82f60f7314fd783.png"
					}
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

			oTrayIcon_GetInfo[Index,"IconFile"] := iconCheck[hIcon]
		}
	}

	DllCall("VirtualFreeEx", Ptr, hProc, Ptr, pProc, UPtr, 0, Uint, 0x8000)
	DllCall("CloseHandle", Ptr, hProc)
	DetectHiddenWindows Setting_A_DetectHiddenWindows
	Return oTrayIcon_GetInfo
}

Gdip_CreateBitmapFromHICON(hIcon)
{
	pBitmap := ""
	DllCall("gdiplus\GdipCreateBitmapFromHICON", A_PtrSize ? "UPtr" : "UInt", hIcon, A_PtrSize ? "UPtr*" : "uint*", pBitmap)
	return pBitmap
}

Gdip_GetPixels(pBitmap, size:=16)
{
	ARGB := 0
	x:=0
	pixelString := ""
	while x < size
	{
		y:=0
		while y < size
		{
			DllCall("gdiplus\GdipBitmapGetPixel", A_PtrSize ? "UPtr" : "UInt", pBitmap, "int", x, "int", y, "uint*", ARGB)
			y+=1
			if(ARGB)
			{
				pixelString := pixelString . ARGB
			}
		}
		x+=1
	}
	return pixelString
}

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

Gdip_Startup()
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	pToken := 0

	if !DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
		DllCall("LoadLibrary", "str", "gdiplus")
	VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
	DllCall("gdiplus\GdiplusStartup", A_PtrSize ? "UPtr*" : "uint*", pToken, Ptr, &si, Ptr, 0)
	return pToken
}
Gdip_Shutdown(pToken)
{
	Ptr := A_PtrSize ? "UPtr" : "UInt"

	DllCall("gdiplus\GdiplusShutdown", Ptr, pToken)
	if hModule := DllCall("GetModuleHandle", "str", "gdiplus", Ptr)
		DllCall("FreeLibrary", Ptr, hModule)
	return 0
}

If !pToken := Gdip_Startup()
{
	MsgBox "Gdiplus failed to start. Please ensure you have gdiplus on your system"
	ExitApp
}
OnExit("ExitFunc")

ExitFunc()
{
   global pToken
   Gdip_Shutdown(pToken)
}

SaveHICONtoRainmeter(hicon, iconFile, icoMD5)
{
	workFile := EnvGet("TMP") "\wwing\" icoMD5 ".ico"
	FileDelete iconFile
	SaveHICONtoFile( hicon, workFile )

	while(!FileExist(workFile))
	{
		Sleep 10
	}

	renderSystrayIconTheme(workFile,iconFile)
}

renderSystrayIconTheme(workFile,renderTo){
    SendRainmeterCommand("[!SetOption magickmeter1 ExportTo `"" . renderTo . "`" wwing]")
    SendRainmeterCommand("[!SetOption magickmeter1 Image `"Rectangle 0,0,#vIconWidth#,#vIconHeight#  | Color 255,255,255,1  `"  wwing]")
    SendRainmeterCommand("[!SetOption magickmeter1 Image2 `"File " . workFile . " | RenderSize 24,24 | move ((#vIconWidth# - 24) / 2),((#vIconHeight# - 24) / 2)`"  wwing]")
    SendRainmeterCommand("[!UpdateMeasure magickmeter1 wwing]") 
}



SaveHICONtoFile( hicon, iconFile ) ; By SKAN | 06-Sep-2017 | goo.gl/8NqmgJ
{                                
	Static CI_FLAGS:=0x2008                                             ; LR_CREATEDIBSECTION | LR_COPYDELETEORG
	Local  File, Var, mDC, sizeofRGBQUAD, ICONINFO:=[], BITMAP:=[], BITMAPINFOHEADER:=[]

	File := FileOpen( iconFile,"rw" )
	If ( ! IsObject(File) )
	{
		Return 0
	}
	Else File.Length := 0                                             ; Delete (any existing) file contents                                                   
	
	VarSetCapacity(Var,32,0)                                      ; ICONINFO Structure
	If ! DllCall( "GetIconInfo", "Ptr",hicon, "Ptr",&Var )
		Return ( File.Close() >> 64 , 0)

	ICONINFO.fIcon      := NumGet(Var, 0,"UInt")
	ICONINFO.xHotspot   := NumGet(Var, 4,"UInt")
	ICONINFO.yHotspot   := NumGet(Var, 8,"UInt")
	ICONINFO.hbmMask    := NumGet(Var, A_PtrSize=8 ? 16:12, "UPtr")
	ICONINFO.hbmMask    := DllCall( "CopyImage"                       ; Create a DIBSECTION for hbmMask
									, "Ptr",ICONINFO.hbmMask 
									, "UInt",0                          ; IMAGE_BITMAP
									, "Int",0, "Int",0, "UInt",CI_FLAGS, "Ptr" ) 
	ICONINFO.hbmColor   := NumGet(Var, A_PtrSize=8 ? 24:16, "UPtr") 
	ICONINFO.hbmColor   := DllCall( "CopyImage"                       ; Create a DIBSECTION for hbmColor
									, "Ptr",ICONINFO.hbmColor
									, "UInt",0                          ; IMAGE_BITMAP
									, "Int",0, "Int",0, "UInt",CI_FLAGS, "Ptr" ) 

	VarSetCapacity(Var,A_PtrSize=8 ? 104:84,0)                        ; DIBSECTION of hbmColor
	DllCall( "GetObject", "Ptr",ICONINFO.hbmColor, "Int",A_PtrSize=8 ? 104:84, "Ptr",&Var )

	BITMAP.bmType       := NumGet(Var, 0,"UInt") 
	BITMAP.bmWidth      := NumGet(Var, 4,"UInt")
	BITMAP.bmHeight     := NumGet(Var, 8,"UInt")
	BITMAP.bmWidthBytes := NumGet(Var,12,"UInt")
	BITMAP.bmPlanes     := NumGet(Var,16,"UShort")
	BITMAP.bmBitsPixel  := NumGet(Var,18,"UShort")
	BITMAP.bmBits       := NumGet(Var,A_PtrSize=8 ? 24:20,"Ptr")
	
	BITMAPINFOHEADER.biClrUsed := NumGet(Var,32+(A_PtrSize=8 ? 32:24),"UInt")
																		
	File.WriteUINT(0x00010000)                                        ; ICONDIR.idReserved and ICONDIR.idType 
	File.WriteUSHORT(1)                                               ; ICONDIR.idCount (No. of images)
	File.WriteUCHAR(BITMAP.bmWidth  < 256 ? BITMAP.bmWidth  : 0)      ; ICONDIRENTRY.bWidth
	File.WriteUCHAR(BITMAP.bmHeight < 256 ? BITMAP.bmHeight : 0)      ; ICONDIRENTRY.bHeight 
	File.WriteUCHAR(BITMAPINFOHEADER.biClrUsed < 256                  ; ICONDIRENTRY.bColorCount
					? BITMAPINFOHEADER.biClrUsed : 0)
	File.WriteUCHAR(0)                                                ; ICONDIRENTRY.bReserved
	File.WriteUShort(BITMAP.bmPlanes)                                 ; ICONDIRENTRY.wPlanes
	File.WriteUSHORT(BITMAP.bmBitsPixel)                              ; ICONDIRENTRY.wBitCount
	File.WriteUINT(0)                                                 ; ICONDIRENTRY.dwBytesInRes (filled later) 
	File.WriteUINT(22)                                                ; ICONDIRENTRY.dwImageOffset  


	NumPut( BITMAP.bmHeight*2, Var, 8+(A_PtrSize=8 ? 32:24),"UInt")   ; BITMAPINFOHEADER.biHeight should be 
																		; modified to double the BITMAP.bmHeight  

	File.RawWrite( &Var + (A_PtrSize=8 ? 32:24), 40)                  ; Writing BITMAPINFOHEADER (40  bytes)               
	File.RawWrite(BITMAP.bmBits, BITMAP.bmWidthBytes*BITMAP.bmHeight) ; Writing BITMAP bits (hbmColor)

	VarSetCapacity(Var,A_PtrSize=8 ? 104:84,0)                        ; DIBSECTION of hbmMask
	DllCall( "GetObject", "Ptr",ICONINFO.hbmMask, "Int",A_PtrSize=8 ? 104:84, "Ptr",&Var )

	BITMAP := []
	BITMAP.bmHeight     := NumGet(Var, 8,"UInt")
	BITMAP.bmWidthBytes := NumGet(Var,12,"UInt")
	BITMAP.bmBits       := NumGet(Var,A_PtrSize=8 ? 24:20,"Ptr")

	File.RawWrite(BITMAP.bmBits, BITMAP.bmWidthBytes*BITMAP.bmHeight) ; Writing BITMAP bits (hbmMask)
	File.Seek(14,0)                                                   ; Seeking ICONDIRENTRY.dwBytesInRes
	File.WriteUINT(File.Length()-22)                                  ; Updating ICONDIRENTRY.dwBytesInRes
	File.Close()
	DllCall( "DeleteObject", "Ptr",ICONINFO.hbmMask  )  
	DllCall( "DeleteObject", "Ptr",ICONINFO.hbmColor )
	Return True
}


TrayIcon_ButtonIndex(trayObject, buttonIndex, sButton := "LBUTTONUP")
{
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
	msgID  := trayObject[buttonIndex].msgID
	uID    := trayObject[buttonIndex].uID
	hWnd   := trayObject[buttonIndex].hWnd

;	idTrayWindow := wingetid("ahk_class Shell_TrayWnd")
	;	idControl := ControlGetHwnd("Button2", "ahk_id " idTrayWindow)
	;	SendMessage( 0x00F5 ,0,0,,"ahk_id " idControl) 
		
	Sleep 100
	SendMessage(msgID, uID, %sButton%, , "ahk_id " hWnd)
	;Sleep 50
	;SendMessage(msgID, uID, %sButton%, , "ahk_id " hWnd)

	DetectHiddenWindows Setting_A_DetectHiddenWindows
	return
}
