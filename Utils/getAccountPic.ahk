Loop Files, "C:\Users\" . A_UserName . "\AppData\Roaming\Microsoft\Windows\AccountPictures\*" 
{
    if(A_LoopFileExt = "accountpicture-ms"){
		RunWait("AccountPicConverter.exe " . A_LoopFileFullPath,,hide)
		FileDelete "*-448.bmp"
		FileMove "*-96.bmp", "C:\Users\" . A_UserName . "\profile.bmp",true
		break
	}
}