{******************************************************************************}
{                                                                              }
{  DD_Tools: DelphiDoom Tools (ENDEDIT, and the modules to come)                }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DD_Tools;

{$DESCRIPTION 'DelphiDoom Tools'}

uses
  Vcl.Forms,
  DelphiDoom.Tools.Types in 'Libs\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.Intf in 'Libs\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Tools.PathText in 'Libs\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Tools.UndoHistory in 'Libs\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in 'Libs\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in 'Libs\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in 'Libs\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in 'Libs\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Tools.Factory in 'Libs\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Endoom.Types in 'Libs\Endoom\DelphiDoom.Endoom.Types.pas',
  DelphiDoom.Endoom.Intf in 'Libs\Endoom\DelphiDoom.Endoom.Intf.pas',
  DelphiDoom.Endoom.Renderer in 'Libs\Endoom\DelphiDoom.Endoom.Renderer.pas',
  DelphiDoom.Endoom.Session in 'Libs\Endoom\DelphiDoom.Endoom.Session.pas',
  DelphiDoom.Endoom.DosFont in 'Libs\Endoom\DelphiDoom.Endoom.DosFont.pas',
  DelphiDoom.Endoom.FontSource in 'Libs\Endoom\DelphiDoom.Endoom.FontSource.pas',
  DelphiDoom.Endoom.ColorQuantizer in 'Libs\Endoom\DelphiDoom.Endoom.ColorQuantizer.pas',
  DelphiDoom.Endoom.Screen in 'Libs\Endoom\DelphiDoom.Endoom.Screen.pas',
  DelphiDoom.Endoom.Drawing in 'Libs\Endoom\DelphiDoom.Endoom.Drawing.pas',
  DelphiDoom.Endoom.TextPaste in 'Libs\Endoom\DelphiDoom.Endoom.TextPaste.pas',
  DelphiDoom.Endoom.ScreenImage in 'Libs\Endoom\DelphiDoom.Endoom.ScreenImage.pas',
  DelphiDoom.Endoom.Factory in 'Libs\Endoom\DelphiDoom.Endoom.Factory.pas',
  DelphiDoom.Endoom.TextArt.Types in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.Types.pas',
  DelphiDoom.Endoom.TextArt.Intf in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.Intf.pas',
  DelphiDoom.Endoom.TextArt.BackgroundOnly in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundOnly.pas',
  DelphiDoom.Endoom.TextArt.BackgroundForeground in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundForeground.pas',
  DelphiDoom.Endoom.TextArt.Dither in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.Dither.pas',
  DelphiDoom.Endoom.TextArt.SpecialChars in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.SpecialChars.pas',
  DelphiDoom.Endoom.TextArt.Converter in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.Converter.pas',
  DelphiDoom.Endoom.TextArt.Factory in 'Libs\Endoom\DelphiDoom.Endoom.TextArt.Factory.pas',
  DelphiDoom.Imaging.Types in 'Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in 'Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Imaging.Resampler in 'Libs\Imaging\DelphiDoom.Imaging.Resampler.pas',
  DelphiDoom.EndoomEditor.Types in 'Libs\EndoomEditor\DelphiDoom.EndoomEditor.Types.pas',
  DelphiDoom.EndoomEditor.Intf in 'Libs\EndoomEditor\DelphiDoom.EndoomEditor.Intf.pas',
  DelphiDoom.EndoomEditor.Presenter in 'Libs\EndoomEditor\DelphiDoom.EndoomEditor.Presenter.pas',
  DelphiDoom.Tools.Win.FileSystem in 'DD_Tools\DelphiDoom.Tools.Win.FileSystem.pas',
  DelphiDoom.Tools.Win.Bitmaps in 'DD_Tools\DelphiDoom.Tools.Win.Bitmaps.pas',
  DelphiDoom.Tools.Win.EndoomClipboard in 'DD_Tools\DelphiDoom.Tools.Win.EndoomClipboard.pas',
  DelphiDoom.Tools.Win.ImageExporter in 'DD_Tools\DelphiDoom.Tools.Win.ImageExporter.pas',
  DelphiDoom.Tools.Win.EndoomDialogs in 'DD_Tools\DelphiDoom.Tools.Win.EndoomDialogs.pas',
  DelphiDoom.Tools.Vcl.EndoomPanel in 'DD_Tools\DelphiDoom.Tools.Vcl.EndoomPanel.pas',
  DelphiDoom.Tools.Composition in 'DD_Tools\DelphiDoom.Tools.Composition.pas',
  frm_textartmethod in 'DD_Tools\frm_textartmethod.pas',
  frm_toolsmain in 'DD_Tools\frm_toolsmain.pas';

begin
  Application.Initialize;
  Application.Title := 'DelphiDoom Tools';
  Application.CreateForm(TToolsMainForm, ToolsMainForm);
  // the composition root: the main window owns the services from here on
  ToolsMainForm.Configure(TToolsServices.Create(Application.Title));
  if ParamCount > 0 then
    ToolsMainForm.Start(ParamStr(1))
  else
    ToolsMainForm.Start('');
  Application.Run;
end.