[Setup]
AppId={{B7F3E2A1-5C8D-4F6E-9A1B-3D7C2E8F4A5B}
AppName=Project Command Center
AppVersion=1.0.0
AppVerName=Project Command Center 1.0.0
AppPublisher=A2H
AppPublisherURL=https://frenchbt79.github.io/A2H-PROJECT-COMMAND-CENTER/
DefaultDirName={autopf}\Project Command Center
DefaultGroupName=Project Command Center
AllowNoIcons=yes
OutputDir=build\installer
OutputBaseFilename=ProjectCommandCenter_Setup_1.0.0
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\project_command_center.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Project Command Center"; Filename: "{app}\project_command_center.exe"; IconFilename: "{app}\project_command_center.exe"
Name: "{group}\{cm:UninstallProgram,Project Command Center}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Project Command Center"; Filename: "{app}\project_command_center.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\project_command_center.exe"; Description: "{cm:LaunchProgram,Project Command Center}"; Flags: nowait postinstall skipifsilent
