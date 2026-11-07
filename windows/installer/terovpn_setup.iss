#define MyAppName "TeroVPN"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "TeroVPN"
#define MyAppURL "https://github.com/smartworldarafath/TeroVPN"
#define MyAppExeName "terovpn.exe"

[Setup]
AppId={{E1584288-A4B7-44E2-8F28-0DAA2199F394}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\..\dist
OutputBaseFilename=TeroVPN-v1.2.0-Windows-Setup
SetupIconFile=..\..\app\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\dist\TeroVPN-v1.2.0-Windows-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "netsh.exe"; Parameters: "advfirewall firewall add rule name=""TeroVPN"" dir=in action=allow program=""{app}\{#MyAppExeName}"" enable=yes profile=any"; Flags: runhidden
Filename: "netsh.exe"; Parameters: "advfirewall firewall add rule name=""TeroVPN"" dir=out action=allow program=""{app}\{#MyAppExeName}"" enable=yes profile=any"; Flags: runhidden
Filename: "netsh.exe"; Parameters: "advfirewall firewall add rule name=""TeroVPN Core"" dir=in action=allow program=""{app}\core\terovpn-core.exe"" enable=yes profile=any"; Flags: runhidden; Check: CoreExists
Filename: "netsh.exe"; Parameters: "advfirewall firewall add rule name=""TeroVPN Core"" dir=out action=allow program=""{app}\core\terovpn-core.exe"" enable=yes profile=any"; Flags: runhidden; Check: CoreExists
Filename: "{app}\core\terovpn-tun.exe"; Parameters: "install"; Flags: runhidden; Check: TunExists
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "netsh.exe"; Parameters: "advfirewall firewall delete rule name=""TeroVPN"""; Flags: runhidden
Filename: "netsh.exe"; Parameters: "advfirewall firewall delete rule name=""TeroVPN Core"""; Flags: runhidden
Filename: "{app}\core\terovpn-tun.exe"; Parameters: "uninstall"; Flags: runhidden; Check: TunExists

[Code]
function CoreExists: Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\core\terovpn-core.exe'));
end;

function TunExists: Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\core\terovpn-tun.exe'));
end;


