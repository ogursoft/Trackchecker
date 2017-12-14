; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "TrackChecker Notifier"
#define MyAppVersion "1.0"
#define MyAppPublisher "Ogursoft"
#define MyAppURL "http://www.ogursoft.ru"
#define MyAppExeName "trchkn.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{7B428E90-C341-4E04-865B-80782FD1FE84}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=D:\Projects\Trackchecker\setup
OutputBaseFilename=trchkn_setup
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "D:\Projects\Trackchecker\Win32\Release\trchkn.exe"; DestDir: "{app}"; Flags: ignoreversion; Check: not IsWin64
Source: "D:\Projects\Trackchecker\Win32\Release\libeay32.dll"; DestDir: "{app}"; Check: not IsWin64
Source: "D:\Projects\Trackchecker\Win32\Release\ssleay32.dll"; DestDir: "{app}"; Check: not IsWin64
Source: "D:\Projects\Trackchecker\Win64\Release\trchkn.exe"; DestDir: "{app}"; Flags: ignoreversion; Check: IsWin64
Source: "D:\Projects\Trackchecker\Win64\Release\libeay32.dll"; DestDir: "{app}"; Check: IsWin64
Source: "D:\Projects\Trackchecker\Win64\Release\ssleay32.dll"; DestDir: "{app}"; Check: IsWin64
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
Source: "..\Win64\Release\pushbullet.exe"; DestDir: "{app}"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: "HKLM"; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run\"; ValueType: string; ValueName: "TrackChecker Notifier"; ValueData: "{app}\{#MyAppExeName}"