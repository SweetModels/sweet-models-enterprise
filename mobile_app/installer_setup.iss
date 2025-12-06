; Sweet Models Enterprise - Inno Setup Script
; Genera instalador profesional para Windows con asistente multi-idioma

#define MyAppName "Sweet Models Enterprise"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Sweet Models"
#define MyAppURL "https://github.com/SweetModels/sweet-models-enterprise"
#define MyAppExeName "sweet_models_mobile.exe"

[Setup]
; Información básica
AppId={{8A9B7C6D-5E4F-3A2B-1C0D-9E8F7A6B5C4D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\LICENSE
InfoBeforeFile=README.md
OutputDir=build\windows\installer
OutputBaseFilename=SweetModelsEnterprise-Setup-{#MyAppVersion}
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin
DisableProgramGroupPage=yes
DisableWelcomePage=no
UninstallDisplayIcon={app}\{#MyAppExeName}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Sistema de gestión empresarial para Sweet Models
VersionInfoCopyright=Copyright (C) 2025 {#MyAppPublisher}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Ejecutable principal
Source: "build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; DLLs de Flutter
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
; Carpeta data (assets, fuentes, etc.)
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Menú Inicio
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Comment: "Gestión empresarial Sweet Models"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
; Escritorio (opcional)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; Comment: "Gestión empresarial Sweet Models"

[Run]
; Ejecutar al finalizar instalación
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Limpiar archivos de configuración al desinstalar
Type: filesandordirs; Name: "{userappdata}\sweet_models_mobile"
Type: filesandordirs; Name: "{localappdata}\sweet_models_mobile"

[Code]
// Verificar si hay versión previa instalada
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  UninstallPath: String;
begin
  Result := True;
  
  // Buscar instalación previa
  if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{8A9B7C6D-5E4F-3A2B-1C0D-9E8F7A6B5C4D}_is1', 'UninstallString', UninstallPath) then
  begin
    if MsgBox('Se detectó una versión anterior de Sweet Models Enterprise.' + #13#10 + 
              '¿Desea desinstalarla antes de continuar?' + #13#10#13#10 +
              'Recomendado: Sí', mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Ejecutar desinstalador silenciosamente
      if not Exec(RemoveQuotes(UninstallPath), '/SILENT', '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
      begin
        MsgBox('Error al desinstalar la versión anterior. Código: ' + IntToStr(ResultCode), mbError, MB_OK);
        Result := False;
      end;
    end;
  end;
end;

// Mostrar mensaje de éxito al finalizar
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Aquí podrías crear shortcuts adicionales, configuraciones, etc.
  end;
end;
