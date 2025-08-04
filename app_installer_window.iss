[Setup]
AppName=Save Forge
AppVersion=__VERSION__
DefaultDirName={autopf}\Save Forge
DefaultGroupName=Save Forge
UninstallDisplayIcon={app}\SaveForge.exe
Compression=lzma
SolidCompression=yes
OutputDir=installer
OutputBaseFilename=SaveForgeInstaller_{#SetupSetting("AppVersion")}
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=__ROOT_PATH__\windows\runner\resources\app_icon.ico

[Files]
Source: "__ROOT_PATH__\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Save Forge"; Filename: "{app}\SaveForge.exe"
Name: "{group}\Uninstall Save Forge"; Filename: "{uninstallexe}"
Name: "{userdesktop}\Save Forge"; Filename: "{app}\SaveForge.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"
