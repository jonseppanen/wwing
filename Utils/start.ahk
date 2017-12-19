SendRainmeterCommand(command) {
  Send_WM_COPYDATA(command, "RainmeterMeterWindow")
}

Send_WM_COPYDATA(ByRef StringToSend, ByRef TargetWindowClass)  
; ByRef saves a little memory in this case.
; This function sends the specified string to the specified window and returns the reply.
; Cribbed from https://www.autohotkey.com/docs/commands/OnMessage.htm
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

SendRainmeterCommand("[!SetVariable MinMax 1]")

sendinput "{LWin}"
