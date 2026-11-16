program Launcher;

uses
  DelphiDoom.Platform.Types in '..\..\Framework\Platform\DelphiDoom.Platform.Types.pas',
  DelphiDoom.Platform.DataFolder.Intf in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Intf.pas',
  DelphiDoom.Platform.DataFolder in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.pas',
  DelphiDoom.Platform.DataFolder.Disk in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Disk.pas',
  DelphiDoom.Platform.DataFolder.Factory in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Factory.pas',
  DelphiDoom.Launcher.Engines in 'DelphiDoom.Launcher.Engines.pas',
  Forms,
  Launcher_main in 'Launcher_main.pas' {Form1},
  Launcher_utils in 'Launcher_utils.pas',
  Launcher_wads in 'Launcher_wads.pas',
  Launcher_defs in 'Launcher_defs.pas',
  Launcher_about in 'Launcher_about.pas' {AboutForm},
  Launcher_options in 'Launcher_options.pas' {OptionsForm},
  Launcher_gameproperties in 'Launcher_gameproperties.pas' {GamePropertiesForm};

{$R *.res}
{$R 'Launcher_Icon.res' 'Launcher_Icon.rc'}

begin
  //I_SetDPIAwareness;

  Application.Initialize;
  Application.Title := 'DelphiDoom Launcher';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
