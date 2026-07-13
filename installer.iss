#ifndef Arch
  #define Arch "x64"
#endif

[Setup]
AppName=Minimal Clock
AppVersion=1.0.0
AppPublisher=ImJustIvaan
AppPublisherURL=https://github.com/ImJustIvaan/Minimal-Clock-Desktop
DefaultDirName={autopf}\Minimal Clock
DefaultGroupName=Minimal Clock
OutputDir=.
OutputBaseFilename=MinimalClock-{#Arch}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico
#if Arch == "arm64"
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif

[Files]
Source: "build\windows\{#Arch}\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Minimal Clock"; Filename: "{app}\minimal_clock.exe"
Name: "{commondesktop}\Minimal Clock"; Filename: "{app}\minimal_clock.exe"

[Registry]
Root: HKCU; Subkey: "Software\Classes\minimalclock"; ValueType: string; ValueName: ""; ValueData: "URL:Minimal Clock Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\minimalclock"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\minimalclock\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\minimal_clock.exe"" ""%1"""

[Run]
Filename: "{app}\minimal_clock.exe"; Description: "Launch Minimal Clock"; Flags: postinstall nowait
