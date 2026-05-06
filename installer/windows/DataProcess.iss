#define MyAppName "DataProcess"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "DataProcess"

[Setup]
AppId={{E4D8F9A1-2B3C-5D6E-7F80-91A2B3C4D5E6}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
PrivilegesRequired=admin
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=DataProcess_Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "staging\convert_cli.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "ensure_libreoffice.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\ensure_libreoffice.ps1"""; \
  StatusMsg: "Checking LibreOffice..."; \
  Flags: postinstall waituntilterminated
