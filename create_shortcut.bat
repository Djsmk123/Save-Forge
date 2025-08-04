@echo off
echo Creating shortcut with administrator privileges...
echo.

REM Create VBS script to create shortcut
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%USERPROFILE%\Desktop\Game Save Manager.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "powershell.exe" >> CreateShortcut.vbs
echo oLink.Arguments = "-NoProfile -ExecutionPolicy Bypass -File ""%~dp0run_as_admin.ps1""" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%~dp0" >> CreateShortcut.vbs
echo oLink.Description = "Game Save Manager - Run as Administrator" >> CreateShortcut.vbs
echo oLink.IconLocation = "%~dp0assets\icons\default.png,0" >> CreateShortcut.vbs
echo oLink.WindowStyle = 1 >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs

REM Run VBS script
cscript //nologo CreateShortcut.vbs

REM Clean up
del CreateShortcut.vbs

echo Shortcut created on desktop: "Game Save Manager.lnk"
echo Right-click the shortcut and select "Run as administrator"
pause 