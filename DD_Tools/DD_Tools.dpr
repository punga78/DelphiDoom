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
  DelphiDoom.Platform.Types in '..\Libs\Platform\DelphiDoom.Platform.Types.pas',
  DelphiDoom.Platform.DataFolder.Intf in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.Intf.pas',
  DelphiDoom.Platform.DataFolder in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.pas',
  DelphiDoom.Platform.DataFolder.Disk in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.Disk.pas',
  DelphiDoom.Platform.DataFolder.Factory in '..\Libs\Platform\DelphiDoom.Platform.DataFolder.Factory.pas',
  System.SysUtils,
  Vcl.Forms,
  DelphiDoom.Tools.Types in '..\Libs\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.Intf in '..\Libs\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Tools.PathText in '..\Libs\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Tools.UndoHistory in '..\Libs\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in '..\Libs\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in '..\Libs\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in '..\Libs\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in '..\Libs\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Tools.Factory in '..\Libs\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Endoom.Types in '..\Libs\Endoom\DelphiDoom.Endoom.Types.pas',
  DelphiDoom.Endoom.Intf in '..\Libs\Endoom\DelphiDoom.Endoom.Intf.pas',
  DelphiDoom.Endoom.Renderer in '..\Libs\Endoom\DelphiDoom.Endoom.Renderer.pas',
  DelphiDoom.Endoom.Session in '..\Libs\Endoom\DelphiDoom.Endoom.Session.pas',
  DelphiDoom.Endoom.DosFont in '..\Libs\Endoom\DelphiDoom.Endoom.DosFont.pas',
  DelphiDoom.Endoom.FontSource in '..\Libs\Endoom\DelphiDoom.Endoom.FontSource.pas',
  DelphiDoom.Endoom.ColorQuantizer in '..\Libs\Endoom\DelphiDoom.Endoom.ColorQuantizer.pas',
  DelphiDoom.Endoom.Screen in '..\Libs\Endoom\DelphiDoom.Endoom.Screen.pas',
  DelphiDoom.Endoom.Drawing in '..\Libs\Endoom\DelphiDoom.Endoom.Drawing.pas',
  DelphiDoom.Endoom.TextPaste in '..\Libs\Endoom\DelphiDoom.Endoom.TextPaste.pas',
  DelphiDoom.Endoom.ScreenImage in '..\Libs\Endoom\DelphiDoom.Endoom.ScreenImage.pas',
  DelphiDoom.Endoom.Factory in '..\Libs\Endoom\DelphiDoom.Endoom.Factory.pas',
  DelphiDoom.Endoom.EditorFactory in '..\Libs\Endoom\DelphiDoom.Endoom.EditorFactory.pas',
  DelphiDoom.Endoom.TextArt.Types in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Types.pas',
  DelphiDoom.Endoom.TextArt.Intf in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Intf.pas',
  DelphiDoom.Endoom.TextArt.BackgroundOnly in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundOnly.pas',
  DelphiDoom.Endoom.TextArt.BackgroundForeground in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundForeground.pas',
  DelphiDoom.Endoom.TextArt.Dither in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Dither.pas',
  DelphiDoom.Endoom.TextArt.SpecialChars in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.SpecialChars.pas',
  DelphiDoom.Endoom.TextArt.Converter in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Converter.pas',
  DelphiDoom.Endoom.TextArt.Factory in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Factory.pas',
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Imaging.Resampler in '..\Libs\Imaging\DelphiDoom.Imaging.Resampler.pas',
  DelphiDoom.EndoomEditor.Types in '..\Libs\EndoomEditor\DelphiDoom.EndoomEditor.Types.pas',
  DelphiDoom.EndoomEditor.Intf in '..\Libs\EndoomEditor\DelphiDoom.EndoomEditor.Intf.pas',
  DelphiDoom.EndoomEditor.Presenter in '..\Libs\EndoomEditor\DelphiDoom.EndoomEditor.Presenter.pas',
  DelphiDoom.Tools.Win.FileSystem in '..\DD_Tools\DelphiDoom.Tools.Win.FileSystem.pas',
  DelphiDoom.Tools.Win.Bitmaps in '..\DD_Tools\DelphiDoom.Tools.Win.Bitmaps.pas',
  DelphiDoom.Tools.Win.EndoomClipboard in '..\DD_Tools\DelphiDoom.Tools.Win.EndoomClipboard.pas',
  DelphiDoom.Tools.Win.ImageExporter in '..\DD_Tools\DelphiDoom.Tools.Win.ImageExporter.pas',
  DelphiDoom.Tools.Win.EndoomDialogs in '..\DD_Tools\DelphiDoom.Tools.Win.EndoomDialogs.pas',
  DelphiDoom.Tools.Vcl.EndoomPanel in '..\DD_Tools\DelphiDoom.Tools.Vcl.EndoomPanel.pas',
  DelphiDoom.Tools.Composition in '..\DD_Tools\DelphiDoom.Tools.Composition.pas',
  frm_textartmethod in '..\DD_Tools\frm_textartmethod.pas',
  frm_toolsmain in '..\DD_Tools\frm_toolsmain.pas',
  DelphiDoom.Tools.Win.FontDialogs in '..\DD_Tools\DelphiDoom.Tools.Win.FontDialogs.pas',
  DelphiDoom.Tools.Win.FontCatalog in '..\DD_Tools\DelphiDoom.Tools.Win.FontCatalog.pas',
  DelphiDoom.Tools.Win.FontInstaller in '..\DD_Tools\DelphiDoom.Tools.Win.FontInstaller.pas',
  DelphiDoom.Tools.Win.FontImageExporter in '..\DD_Tools\DelphiDoom.Tools.Win.FontImageExporter.pas',
  DelphiDoom.Tools.Win.FontRasterizer in '..\DD_Tools\DelphiDoom.Tools.Win.FontRasterizer.pas',
  DelphiDoom.FontEditor.Intf in '..\Libs\FontEditor\DelphiDoom.FontEditor.Intf.pas',
  DelphiDoom.FontEditor.Presenter in '..\Libs\FontEditor\DelphiDoom.FontEditor.Presenter.pas',
  DelphiDoom.Wad.Factory in '..\Libs\Wad\DelphiDoom.Wad.Factory.pas',
  DelphiDoom.Font.Intf in '..\Libs\Font\DelphiDoom.Font.Intf.pas',
  DelphiDoom.Font.Factory in '..\Libs\Font\DelphiDoom.Font.Factory.pas',
  DelphiDoom.FontEditor.Types in '..\Libs\FontEditor\DelphiDoom.FontEditor.Types.pas',
  DelphiDoom.Font.Types in '..\Libs\Font\DelphiDoom.Font.Types.pas',
  DelphiDoom.Font.Settings in '..\Libs\Font\DelphiDoom.Font.Settings.pas',
  DelphiDoom.Palette.GamePalettes in '..\Libs\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Font.SettingsFormat in '..\Libs\Font\DelphiDoom.Font.SettingsFormat.pas',
  DelphiDoom.Font.LumpNames in '..\Libs\Font\DelphiDoom.Font.LumpNames.pas',
  DelphiDoom.Wad.Types in '..\Libs\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Intf in '..\Libs\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Pak.Intf in '..\Libs\Wad\DelphiDoom.Wad.Pak.Intf.pas',
  DelphiDoom.Wad.Directory in '..\Libs\Wad\DelphiDoom.Wad.Directory.pas',
  DelphiDoom.Wad.LumpCache in '..\Libs\Wad\DelphiDoom.Wad.LumpCache.pas',
  DelphiDoom.Wad.Builder in '..\Libs\Wad\DelphiDoom.Wad.Builder.pas',
  DelphiDoom.Wad.Source.Wad in '..\Libs\Wad\DelphiDoom.Wad.Source.Wad.pas',
  DelphiDoom.Wad.Source.Wad2 in '..\Libs\Wad\DelphiDoom.Wad.Source.Wad2.pas',
  DelphiDoom.Wad.Source.Pak in '..\Libs\Wad\DelphiDoom.Wad.Source.Pak.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Libs\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Source.Zip in '..\Libs\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Wad.Source.Folder in '..\Libs\Wad\DelphiDoom.Wad.Source.Folder.pas',
  DelphiDoom.Wad.Source.SingleFile in '..\Libs\Wad\DelphiDoom.Wad.Source.SingleFile.pas',
  DelphiDoom.Wad.Pak.Index in '..\Libs\Wad\DelphiDoom.Wad.Pak.Index.pas',
  DelphiDoom.Wad.Pak.PathResolver in '..\Libs\Wad\DelphiDoom.Wad.Pak.PathResolver.pas',
  DelphiDoom.Palette.ColorMatcher in '..\Libs\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Imaging.PatchWriter in '..\Libs\Imaging\DelphiDoom.Imaging.PatchWriter.pas',
  DelphiDoom.Font.TextComposer in '..\Libs\Font\DelphiDoom.Font.TextComposer.pas',
  DelphiDoom.Font.GridComposer in '..\Libs\Font\DelphiDoom.Font.GridComposer.pas',
  DelphiDoom.Font.Exporter in '..\Libs\Font\DelphiDoom.Font.Exporter.pas',
  DelphiDoom.Font.WadGenerator in '..\Libs\Font\DelphiDoom.Font.WadGenerator.pas',
  DelphiDoom.Palette.Types in '..\Libs\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.GamePaletteData in '..\Libs\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Wad.Pak.Types in '..\Libs\Wad\DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Name in '..\Libs\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Indicators in '..\Libs\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\Libs\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Pak.Names in '..\Libs\Wad\DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Palette.Intf in '..\Libs\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Font.GlyphCropper in '..\Libs\Font\DelphiDoom.Font.GlyphCropper.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Libs\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.Font.Colorizer in '..\Libs\Font\DelphiDoom.Font.Colorizer.pas',
  DelphiDoom.Font.PerlinNoise in '..\Libs\Font\DelphiDoom.Font.PerlinNoise.pas',
  frm_fonteditor in '..\DD_Tools\frm_fonteditor.pas',
  DelphiDoom.VoxelEditor.Types in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Types.pas',
  DelphiDoom.VoxelEditor.Model in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Model.pas',
  DelphiDoom.VoxelEditor.Views in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Views.pas',
  DelphiDoom.VoxelEditor.Planes in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Planes.pas',
  DelphiDoom.VoxelEditor.Transforms in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Transforms.pas',
  DelphiDoom.VoxelEditor.Palettes in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Palettes.pas',
  DelphiDoom.VoxelEditor.Operations in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Operations.pas',
  DelphiDoom.VoxelEditor.Rotator in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Rotator.pas',
  DelphiDoom.VoxelEditor.Quantizer in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Quantizer.pas',
  DelphiDoom.VoxelEditor.ByteReader in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.ByteReader.pas',
  DelphiDoom.VoxelEditor.Format.SlabPalette in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.SlabPalette.pas',
  DelphiDoom.VoxelEditor.Format.Ddvox in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddvox.pas',
  DelphiDoom.VoxelEditor.Format.Kvx in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Kvx.pas',
  DelphiDoom.VoxelEditor.Format.Vox in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Vox.pas',
  DelphiDoom.VoxelEditor.Format.Ddmesh in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddmesh.pas',
  DelphiDoom.VoxelEditor.MeshOptimizer in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.MeshOptimizer.pas',
  DelphiDoom.VoxelEditor.Painter in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Painter.pas',
  DelphiDoom.VoxelEditor.Intf in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Intf.pas',
  DelphiDoom.VoxelEditor.Presenter in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Presenter.pas',
  DelphiDoom.Tools.Win.VoxelBitmaps in '..\DD_Tools\DelphiDoom.Tools.Win.VoxelBitmaps.pas',
  DelphiDoom.Tools.Win.VoxelClipboard in '..\DD_Tools\DelphiDoom.Tools.Win.VoxelClipboard.pas',
  DelphiDoom.Tools.Win.VoxelImageFiles in '..\DD_Tools\DelphiDoom.Tools.Win.VoxelImageFiles.pas',
  DelphiDoom.Tools.Win.VoxelDialogs in '..\DD_Tools\DelphiDoom.Tools.Win.VoxelDialogs.pas',
  frm_voxeleditor in '..\DD_Tools\frm_voxeleditor.pas';

begin
  Application.Initialize;
  Application.Title := 'DelphiDoom Tools';
  Application.CreateForm(TToolsMainForm, ToolsMainForm);
  // the composition root: the main window owns the services from here on
  ToolsMainForm.Configure(TToolsServices.Create(Application.Title));
  // a project of the font editor (.ddp) opens that module, any other file is a text screen of the endoom editor
  if (ParamCount > 0) and SameText(ExtractFileExt(ParamStr(1)), '.ddp') then
  begin
    ToolsMainForm.Start('');
    ToolsMainForm.ShowFontEditor(ParamStr(1));
  end
  // a voxel of the voxel editor (.ddvox) opens that module
  else if (ParamCount > 0) and SameText(ExtractFileExt(ParamStr(1)), '.ddvox') then
  begin
    ToolsMainForm.Start('');
    ToolsMainForm.ShowVoxelEditor(ParamStr(1));
  end
  else if ParamCount > 0 then
    ToolsMainForm.Start(ParamStr(1))
  else
    ToolsMainForm.Start('');
  Application.Run;
end.