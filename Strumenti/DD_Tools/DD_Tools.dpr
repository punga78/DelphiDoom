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

{$R 'DD_Tools_Icon.res' 'DD_Tools_Icon.rc'}

uses
  DelphiDoom.Platform.Types in '..\..\Framework\Platform\DelphiDoom.Platform.Types.pas',
  DelphiDoom.Platform.DataFolder.Intf in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Intf.pas',
  DelphiDoom.Platform.DataFolder in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.pas',
  DelphiDoom.Platform.DataFolder.Disk in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Disk.pas',
  DelphiDoom.Platform.DataFolder.Factory in '..\..\Framework\Platform\DelphiDoom.Platform.DataFolder.Factory.pas',
  System.SysUtils,
  Vcl.Forms,
  DelphiDoom.Tools.Types in '..\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.Intf in '..\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Tools.PathText in '..\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Tools.UndoHistory in '..\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in '..\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in '..\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in '..\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in '..\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Tools.Factory in '..\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Endoom.Types in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.Types.pas',
  DelphiDoom.Endoom.Intf in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.Intf.pas',
  DelphiDoom.Endoom.Renderer in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.Renderer.pas',
  DelphiDoom.Endoom.Session in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.Session.pas',
  DelphiDoom.Endoom.DosFont in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.DosFont.pas',
  DelphiDoom.Endoom.FontSource in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.FontSource.pas',
  DelphiDoom.Endoom.ColorQuantizer in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.ColorQuantizer.pas',
  DelphiDoom.Endoom.Screen in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.Screen.pas',
  DelphiDoom.Endoom.Drawing in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.Drawing.pas',
  DelphiDoom.Endoom.TextPaste in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextPaste.pas',
  DelphiDoom.Endoom.ScreenImage in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.ScreenImage.pas',
  DelphiDoom.Endoom.Factory in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.Factory.pas',
  DelphiDoom.Endoom.EditorFactory in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.EditorFactory.pas',
  DelphiDoom.Endoom.TextArt.Types in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.Types.pas',
  DelphiDoom.Endoom.TextArt.Intf in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.Intf.pas',
  DelphiDoom.Endoom.TextArt.BackgroundOnly in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.BackgroundOnly.pas',
  DelphiDoom.Endoom.TextArt.BackgroundForeground in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.BackgroundForeground.pas',
  DelphiDoom.Endoom.TextArt.Dither in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.Dither.pas',
  DelphiDoom.Endoom.TextArt.SpecialChars in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.SpecialChars.pas',
  DelphiDoom.Endoom.TextArt.Converter in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.Converter.pas',
  DelphiDoom.Endoom.TextArt.Factory in '..\..\IdTech1\Endoom\DelphiDoom.Endoom.TextArt.Factory.pas',
  DelphiDoom.Imaging.Types in '..\..\Framework\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\..\Framework\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Imaging.Resampler in '..\..\Framework\Imaging\DelphiDoom.Imaging.Resampler.pas',
  DelphiDoom.EndoomEditor.Types in '..\EndoomEditor\DelphiDoom.EndoomEditor.Types.pas',
  DelphiDoom.EndoomEditor.Intf in '..\EndoomEditor\DelphiDoom.EndoomEditor.Intf.pas',
  DelphiDoom.EndoomEditor.Presenter in '..\EndoomEditor\DelphiDoom.EndoomEditor.Presenter.pas',
  DelphiDoom.Tools.Win.FileSystem in 'DelphiDoom.Tools.Win.FileSystem.pas',
  DelphiDoom.Tools.Win.Bitmaps in 'DelphiDoom.Tools.Win.Bitmaps.pas',
  DelphiDoom.Tools.Win.EndoomClipboard in 'DelphiDoom.Tools.Win.EndoomClipboard.pas',
  DelphiDoom.Tools.Win.ImageExporter in 'DelphiDoom.Tools.Win.ImageExporter.pas',
  DelphiDoom.Tools.Win.EndoomDialogs in 'DelphiDoom.Tools.Win.EndoomDialogs.pas',
  DelphiDoom.Tools.Vcl.EndoomPanel in 'DelphiDoom.Tools.Vcl.EndoomPanel.pas',
  DelphiDoom.Tools.Composition in 'DelphiDoom.Tools.Composition.pas',
  frm_textartmethod in 'frm_textartmethod.pas',
  frm_toolsmain in 'frm_toolsmain.pas',
  DelphiDoom.Tools.Win.FontDialogs in 'DelphiDoom.Tools.Win.FontDialogs.pas',
  DelphiDoom.Tools.Win.FontCatalog in 'DelphiDoom.Tools.Win.FontCatalog.pas',
  DelphiDoom.Tools.Win.FontInstaller in 'DelphiDoom.Tools.Win.FontInstaller.pas',
  DelphiDoom.Tools.Win.FontImageExporter in 'DelphiDoom.Tools.Win.FontImageExporter.pas',
  DelphiDoom.Tools.Win.FontRasterizer in 'DelphiDoom.Tools.Win.FontRasterizer.pas',
  DelphiDoom.FontEditor.Intf in '..\FontEditor\DelphiDoom.FontEditor.Intf.pas',
  DelphiDoom.FontEditor.Presenter in '..\FontEditor\DelphiDoom.FontEditor.Presenter.pas',
  DelphiDoom.Wad.Factory in '..\..\Framework\Wad\DelphiDoom.Wad.Factory.pas',
  DelphiDoom.Font.Intf in '..\Font\DelphiDoom.Font.Intf.pas',
  DelphiDoom.Font.Factory in '..\Font\DelphiDoom.Font.Factory.pas',
  DelphiDoom.FontEditor.Types in '..\FontEditor\DelphiDoom.FontEditor.Types.pas',
  DelphiDoom.Font.Types in '..\Font\DelphiDoom.Font.Types.pas',
  DelphiDoom.Font.Settings in '..\Font\DelphiDoom.Font.Settings.pas',
  DelphiDoom.Palette.GamePalettes in '..\..\Framework\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Font.SettingsFormat in '..\Font\DelphiDoom.Font.SettingsFormat.pas',
  DelphiDoom.Font.LumpNames in '..\Font\DelphiDoom.Font.LumpNames.pas',
  DelphiDoom.Wad.Types in '..\..\Framework\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Intf in '..\..\Framework\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Pak.Intf in '..\..\Framework\Wad\DelphiDoom.Wad.Pak.Intf.pas',
  DelphiDoom.Wad.Directory in '..\..\Framework\Wad\DelphiDoom.Wad.Directory.pas',
  DelphiDoom.Wad.LumpCache in '..\..\Framework\Wad\DelphiDoom.Wad.LumpCache.pas',
  DelphiDoom.Wad.Builder in '..\..\Framework\Wad\DelphiDoom.Wad.Builder.pas',
  DelphiDoom.Wad.Source.Wad in '..\..\Framework\Wad\DelphiDoom.Wad.Source.Wad.pas',
  DelphiDoom.Wad.Source.Wad2 in '..\..\Framework\Wad\DelphiDoom.Wad.Source.Wad2.pas',
  DelphiDoom.Wad.Source.Pak in '..\..\Framework\Wad\DelphiDoom.Wad.Source.Pak.pas',
  DelphiDoom.Wad.Zip.Intf in '..\..\Framework\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Source.Zip in '..\..\Framework\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Wad.Source.Folder in '..\..\Framework\Wad\DelphiDoom.Wad.Source.Folder.pas',
  DelphiDoom.Wad.Source.SingleFile in '..\..\Framework\Wad\DelphiDoom.Wad.Source.SingleFile.pas',
  DelphiDoom.Wad.Pak.Index in '..\..\Framework\Wad\DelphiDoom.Wad.Pak.Index.pas',
  DelphiDoom.Wad.Pak.PathResolver in '..\..\Framework\Wad\DelphiDoom.Wad.Pak.PathResolver.pas',
  DelphiDoom.Palette.ColorMatcher in '..\..\Framework\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Palette.NearestColor in '..\..\Framework\Palette\DelphiDoom.Palette.NearestColor.pas',
  DelphiDoom.Imaging.PatchWriter in '..\..\Framework\Imaging\DelphiDoom.Imaging.PatchWriter.pas',
  DelphiDoom.Font.TextComposer in '..\Font\DelphiDoom.Font.TextComposer.pas',
  DelphiDoom.Font.GridComposer in '..\Font\DelphiDoom.Font.GridComposer.pas',
  DelphiDoom.Font.Exporter in '..\Font\DelphiDoom.Font.Exporter.pas',
  DelphiDoom.Font.WadGenerator in '..\Font\DelphiDoom.Font.WadGenerator.pas',
  DelphiDoom.Palette.Types in '..\..\Framework\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.GamePaletteData in '..\..\Framework\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Wad.Pak.Types in '..\..\Framework\Wad\DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Name in '..\..\Framework\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Indicators in '..\..\Framework\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\..\Framework\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Pak.Names in '..\..\Framework\Wad\DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Palette.Intf in '..\..\Framework\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Font.GlyphCropper in '..\Font\DelphiDoom.Font.GlyphCropper.pas',
  DelphiDoom.MathCore.SoftExtended in '..\..\Framework\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.Font.Colorizer in '..\Font\DelphiDoom.Font.Colorizer.pas',
  DelphiDoom.Font.PerlinNoise in '..\Font\DelphiDoom.Font.PerlinNoise.pas',
  frm_fonteditor in 'frm_fonteditor.pas',
  DelphiDoom.VoxelEditor.Types in '..\VoxelEditor\DelphiDoom.VoxelEditor.Types.pas',
  DelphiDoom.VoxelEditor.Model in '..\VoxelEditor\DelphiDoom.VoxelEditor.Model.pas',
  DelphiDoom.VoxelEditor.Views in '..\VoxelEditor\DelphiDoom.VoxelEditor.Views.pas',
  DelphiDoom.VoxelEditor.Planes in '..\VoxelEditor\DelphiDoom.VoxelEditor.Planes.pas',
  DelphiDoom.VoxelEditor.Transforms in '..\VoxelEditor\DelphiDoom.VoxelEditor.Transforms.pas',
  DelphiDoom.VoxelEditor.Palettes in '..\VoxelEditor\DelphiDoom.VoxelEditor.Palettes.pas',
  DelphiDoom.VoxelEditor.Operations in '..\VoxelEditor\DelphiDoom.VoxelEditor.Operations.pas',
  DelphiDoom.VoxelEditor.Rotator in '..\VoxelEditor\DelphiDoom.VoxelEditor.Rotator.pas',
  DelphiDoom.VoxelEditor.Quantizer in '..\VoxelEditor\DelphiDoom.VoxelEditor.Quantizer.pas',
  DelphiDoom.Bytes.Types in '..\..\Framework\Bytes\DelphiDoom.Bytes.Types.pas',
  DelphiDoom.Bytes.Reader in '..\..\Framework\Bytes\DelphiDoom.Bytes.Reader.pas',
  DelphiDoom.VoxelEditor.ByteReader in '..\VoxelEditor\DelphiDoom.VoxelEditor.ByteReader.pas',
  DelphiDoom.VoxelEditor.Format.SlabPalette in '..\VoxelEditor\DelphiDoom.VoxelEditor.Format.SlabPalette.pas',
  DelphiDoom.VoxelEditor.Format.Ddvox in '..\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddvox.pas',
  DelphiDoom.VoxelEditor.Format.Kvx in '..\VoxelEditor\DelphiDoom.VoxelEditor.Format.Kvx.pas',
  DelphiDoom.VoxelEditor.Format.Vox in '..\VoxelEditor\DelphiDoom.VoxelEditor.Format.Vox.pas',
  DelphiDoom.VoxelEditor.Format.Ddmesh in '..\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddmesh.pas',
  DelphiDoom.VoxelEditor.MeshOptimizer in '..\VoxelEditor\DelphiDoom.VoxelEditor.MeshOptimizer.pas',
  DelphiDoom.VoxelEditor.Painter in '..\VoxelEditor\DelphiDoom.VoxelEditor.Painter.pas',
  DelphiDoom.VoxelEditor.Intf in '..\VoxelEditor\DelphiDoom.VoxelEditor.Intf.pas',
  DelphiDoom.VoxelEditor.Presenter in '..\VoxelEditor\DelphiDoom.VoxelEditor.Presenter.pas',
  DelphiDoom.Tools.Win.VoxelBitmaps in 'DelphiDoom.Tools.Win.VoxelBitmaps.pas',
  DelphiDoom.Tools.Win.VoxelClipboard in 'DelphiDoom.Tools.Win.VoxelClipboard.pas',
  DelphiDoom.Tools.Win.VoxelImageFiles in 'DelphiDoom.Tools.Win.VoxelImageFiles.pas',
  DelphiDoom.Tools.Win.VoxelDialogs in 'DelphiDoom.Tools.Win.VoxelDialogs.pas',
  frm_voxeleditor in 'frm_voxeleditor.pas';

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
