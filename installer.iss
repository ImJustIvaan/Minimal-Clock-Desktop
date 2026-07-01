[Setup]
AppName=Minimal Clock
AppVersion=1.0.0
AppPublisher=ImJustIvaan
AppPublisherURL=https://github.com/ImJustIvaan/Minimal-Clock-Desktop
DefaultDirName={autopf}\Minimal Clock
DefaultGroupName=Minimal Clock
OutputDir=.
OutputBaseFilename=MinimalClockSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Minimal Clock"; Filename: "{app}\minimal_clock_desktop.exe"
Name: "{commondesktop}\Minimal Clock"; Filename: "{app}\minimal_clock_desktop.exe"

[Run]
Filename: "{app}\minimal_clock_desktop.exe"; Description: "Launch Minimal Clock"; Flags: postinstall nowait
