[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{28D373B2-8F55-4C82-87F7-22005A32B94A}
AppName=Daily Focus
AppVersion=1.0.0
;AppVerName=Daily Focus 1.0.0
AppPublisher=Gangasaikumar
AppPublisherURL=https://github.com/Gangasaikumar/Todo_App_flutter
AppSupportURL=https://github.com/Gangasaikumar/Todo_App_flutter
AppUpdatesURL=https://github.com/Gangasaikumar/Todo_App_flutter
DefaultDirName={autopf}\Daily Focus
DisableProgramGroupPage=yes
; The [Icons] section uses the "common" constants, to create entries in the Start Menu common to all users.
; If you want to create per-user shortcuts, use the "user" constants, for example {userprograms}.
LicenseFile=
;InfoBeforeFile=
;InfoAfterFile=
; Remove the following line to run in administrative install mode (install for all users.)
PrivilegesRequired=lowest
OutputDir=installers
OutputBaseFilename=daily_focus_setup
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\daily_focus.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\Daily Focus"; Filename: "{app}\daily_focus.exe"
Name: "{autodesktop}\Daily Focus"; Filename: "{app}\daily_focus.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\daily_focus.exe"; Description: "{cm:LaunchProgram,Daily Focus}"; Flags: nowait postinstall skipifsilent
