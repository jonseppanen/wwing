If(WinExist(Downloads))
{
    WinActivate
}
else{
    Run(explore "C:\Users\" . A_UserName . "\Downloads")
}