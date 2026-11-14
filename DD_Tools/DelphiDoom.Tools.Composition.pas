{******************************************************************************}
{                                                                              }
{  DD_Tools: the composition root of the tools                                  }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Composition;

interface

uses
  System.SysUtils,
  DelphiDoom.Tools.Intf,
  DelphiDoom.EndoomEditor.Intf,
  DelphiDoom.EndoomEditor.Presenter,
  DelphiDoom.FontEditor.Intf,
  DelphiDoom.FontEditor.Presenter,
  DelphiDoom.VoxelEditor.Intf,
  DelphiDoom.VoxelEditor.Presenter;

type
  /// <summary>
  ///   The one place that knows the classes of Windows and of the libraries and makes them: the program creates it,
  ///   gives it to the main window (which asks it for the presenter of each module) and frees it when it closes.
  ///   The windows only know the interfaces of the libraries
  /// </summary>
  TToolsServices = class
  strict private
    FTitle: string;
    FFileSystem: IToolFileSystem;
    /// <summary>One store of settings for every module: each one writes its own sections to the same file</summary>
    FSettings: ISettingsStore;
    FClipboard: IEndoomEditorClipboard;
    FExporter: IEndoomEditorImageExporter;
    FDialogs: IEndoomEditorDialogs;
    FFontDialogs: IFontEditorDialogs;
    FVoxelDialogs: IVoxelEditorDialogs;
  public
    constructor Create(const ATitle: string);
    /// <summary>
    ///   The presenter of the endoom editor for a window. The caller owns it and frees it before the window is gone.
    ///   AFont gets the picture of the font that the screen is drawn with
    /// </summary>
    function CreateEndoomEditor(const AView: IEndoomEditorView; out AFont: TBytes): TEndoomEditorPresenter;
    /// <summary>The presenter of the font editor for a window. The caller owns it and frees it before the window is gone</summary>
    function CreateFontEditor(const AView: IFontEditorView): TFontEditorPresenter;
    /// <summary>The presenter of the voxel editor for a window. The caller owns it and frees it before the window is gone</summary>
    function CreateVoxelEditor(const AView: IVoxelEditorView): TVoxelEditorPresenter;
    /// <summary>The version of the program, from its version resource</summary>
    function VersionText: string;
    property Title: string read FTitle;
  end;

implementation

uses
  DelphiDoom.Platform.DataFolder.Factory,
  DelphiDoom.Tools.Factory, DelphiDoom.Tools.Types, DelphiDoom.VoxelEditor.Types,
  DelphiDoom.Endoom.Intf, DelphiDoom.Endoom.EditorFactory,
  DelphiDoom.Endoom.TextArt.Types, DelphiDoom.Endoom.TextArt.Intf, DelphiDoom.Endoom.TextArt.Factory,
  DelphiDoom.Imaging.Resampler,
  DelphiDoom.Wad.Factory, DelphiDoom.Font.Intf, DelphiDoom.Font.Factory,
  DelphiDoom.Tools.Win.FileSystem, DelphiDoom.Tools.Win.EndoomDialogs, DelphiDoom.Tools.Win.EndoomClipboard,
  DelphiDoom.Tools.Win.ImageExporter, DelphiDoom.Tools.Win.FontRasterizer, DelphiDoom.Tools.Win.FontCatalog,
  DelphiDoom.Tools.Win.FontInstaller, DelphiDoom.Tools.Win.FontDialogs, DelphiDoom.Tools.Win.FontImageExporter,
  DelphiDoom.Tools.Win.VoxelDialogs, DelphiDoom.Tools.Win.VoxelClipboard, DelphiDoom.Tools.Win.VoxelImageFiles;

{ TToolsServices }

constructor TToolsServices.Create(const ATitle: string);
begin
  inherited Create;
  FTitle := ATitle;
  FFileSystem := TWindowsToolFileSystem.Create;
  FSettings := TToolsFactory.CreateSettings(FFileSystem, TDataFolderFactory.CreateLocator.Locate(ExtractFilePath(ParamStr(0)), '') +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini'));
  FClipboard := TVclEndoomEditorClipboard.Create;
  FExporter := TVclEndoomImageExporter.Create;
  FDialogs := TVclEndoomEditorDialogs.Create(ATitle, VersionText);
  FFontDialogs := TVclFontEditorDialogs.Create('DelphiDoom Font Creator', VersionText);
  FVoxelDialogs := TVclVoxelEditorDialogs.Create(VOXEL_EDITOR_TITLE, VersionText);
end;

function TToolsServices.VersionText: string;
var
  LVersion: Cardinal;
begin
  LVersion := GetFileVersion(ParamStr(0));
  if LVersion = Cardinal(-1) then
    Result := '1.0'
  else
    Result := Format('%d.%d', [LVersion shr 16, LVersion and $FFFF]);
end;

function TToolsServices.CreateEndoomEditor(const AView: IEndoomEditorView; out AFont: TBytes): TEndoomEditorPresenter;
var
  LFontSource: IEndoomFontSource;
begin
  LFontSource := TEndoomEditorFactory.CreateEditorFontSource;
  AFont := LFontSource.GetFont;
  Result := TEndoomEditorPresenter.Create(AView, FDialogs, FClipboard, FExporter, FFileSystem,
    TToolsFactory.CreateFileBackup(FFileSystem),
    FSettings, TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT),
    TToolsFactory.CreateUndoHistory(TOOLS_UNDO_LIMIT), TEndoomEditorFactory.CreateScreen, TEndoomEditorFactory.CreateScreenImage, LFontSource,
    TEndoomTextArtFactory.CreateConverter(TImagingLanczosResampler.Create),
    function(AKind: TEndoomTextArtKind): IEndoomTextArtMethod
    begin
      Result := TEndoomTextArtFactory.CreateMethod(AKind);
    end);
end;

function TToolsServices.CreateFontEditor(const AView: IFontEditorView): TFontEditorPresenter;
var
  LRasterizer: IFontRasterizer;
begin
  LRasterizer := TVclFontRasterizer.Create;
  Result := TFontEditorPresenter.Create(AView, FFontDialogs, TWindowsFontCatalog.Create, TWindowsFontInstaller.Create,
    TVclFontImageExporter.Create, FFileSystem, TToolsFactory.CreateFileBackup(FFileSystem), FSettings,
    TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT), TToolsFactory.CreateUndoHistory(TOOLS_UNDO_LIMIT),
    TFontFactory.CreateGridComposer(LRasterizer), TFontFactory.CreateTextComposer(LRasterizer),
    TFontFactory.CreateWadGenerator(LRasterizer, TWadFactory.CreateBuilder));
end;

function TToolsServices.CreateVoxelEditor(const AView: IVoxelEditorView): TVoxelEditorPresenter;
begin
  Result := TVoxelEditorPresenter.Create(AView, FVoxelDialogs, TVclVoxelEditorClipboard.Create,
    TVclVoxelImageLoader.Create, TVclVoxelImageExporter.Create, FFileSystem,
    TToolsFactory.CreateFileBackup(FFileSystem), FSettings, TToolsFactory.CreateRecentFiles(TOOLS_RECENT_FILES_LIMIT),
    TToolsFactory.CreateUndoHistory(TOOLS_UNDO_LIMIT));
end;

end.
