{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the presenter of the main window                  }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Presenter;

interface

uses
  System.SysUtils,
  DelphiDoom.Tools.Intf,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model,
  DelphiDoom.VoxelEditor.Painter,
  DelphiDoom.VoxelEditor.Intf;

type
  /// <summary>
  ///   What the main window of DD_VOXEL (main.pas, more than 200 handlers) decided, without the window: the voxel
  ///   and the plane that is edited (a slice or one of the six views), the mouse tools, the commands on a plane
  ///   (copy, paste, flip, turn...) and on the whole voxel (rotate, crop, palette...), the files (DDVOX, and the
  ///   import and export of KVX, VOX and DDMESH), the undo and the recent files. The window tells it what
  ///   happens and draws what it says (IVoxelEditorView). The 3D preview of OpenGL, the export of sprites, the
  ///   LDraw import and the scripts of the old program are not here
  /// </summary>
  TVoxelEditorPresenter = class
  strict private
    FView: IVoxelEditorView;
    FDialogs: IVoxelEditorDialogs;
    FClipboard: IVoxelEditorClipboard;
    FLoader: IVoxelEditorImageLoader;
    FExporter: IVoxelEditorImageExporter;
    FFileSystem: IToolFileSystem;
    FBackup: IToolFileBackup;
    FStore: ISettingsStore;
    FRecentFiles: IRecentFiles;
    FUndo: IToolUndoHistory;
    FModel: TVoxelEditorModel;
    FPainter: TVoxelEditorPainter;
    FPlane: TVoxelEditorPlane;
    FLevels: array[veaX..veaZ] of Integer;
    FFileName: string;
    FChanged: Boolean;
    FZoom: Integer;
    FNewSize: Integer;
    FTool: TVoxelEditorTool;
    FStatus: string;
    FPalette: TVoxelEditorPalette;
    FRotationDegrees: Double;
    function GetColor1: Cardinal;
    function GetColor2: Cardinal;
    procedure SaveUndo;
    procedure Commit;
    procedure ResetDocument;
    procedure RefreshPlane;
    procedure RefreshState;
    procedure RefreshTitle;
    procedure RefreshRecentFiles;
    procedure RefreshPlanes;
    procedure RefreshAll;
    procedure SetPaletteColors(const APalette: TVoxelEditorPalette);
    procedure ApplyPlane(const APlane: TVoxelEditorPlane);
    procedure NewModel(ASize: Integer);
    function ReadFile(const AFileName: string; out ABytes: TBytes): Boolean;
    function WriteFile(const AFileName: string; const ABytes: TBytes): Boolean;
    procedure ShowError(const AMessage: string);
    function ImportFile(const AFileName: string; AKind: Integer): Boolean;
    function LoadVoxel(const AFileName: string): Boolean;
    function SaveTo(const AFileName: string): Boolean;
    procedure TransformPlane(AKind: Integer);
    procedure RotateModel(AHighQuality: Boolean);
    procedure ChangeLevel(ADelta: Integer);
    procedure CopyPlaneToClipboard(const APlane: TVoxelEditorPlane);
    procedure PasteFromClipboard(const APlane: TVoxelEditorPlane);
  public
    constructor Create(const AView: IVoxelEditorView; const ADialogs: IVoxelEditorDialogs;
      const AClipboard: IVoxelEditorClipboard; const ALoader: IVoxelEditorImageLoader;
      const AExporter: IVoxelEditorImageExporter; const AFileSystem: IToolFileSystem;
      const ABackup: IToolFileBackup; const AStore: ISettingsStore; const ARecentFiles: IRecentFiles;
      const AUndo: IToolUndoHistory);
    destructor Destroy; override;

    /// <summary>The window is ready: the settings come back, the voxel of the command line is opened, or a new one is made</summary>
    procedure Start(const ACommandLineFile: string);
    /// <summary>The window closes: the settings are saved</summary>
    procedure Shutdown;

    // the voxel and its files
    procedure NewVoxel;
    procedure OpenFile;
    procedure OpenVoxel(const AFileName: string);
    procedure OpenRecent(AIndex: Integer);
    procedure Save;
    procedure SaveAs;
    procedure ImportKvx;
    procedure ImportVox;
    procedure ImportDdmesh;
    procedure ExportVox;
    procedure ExportMesh;
    /// <summary>The picture of the plane that is edited to a file of the user</summary>
    procedure ExportPlaneImage;
    /// <summary>The picture of one of the six views to a file of the user</summary>
    procedure ExportViewImage(AView: TVoxelEditorView);
    procedure ConvertFiles(ABatch: TVoxelEditorBatch);
    function TryClose: Boolean;
    procedure RequestClose;
    procedure About;

    // pictures
    procedure ImportImage;
    procedure ImportHeightmap;
    procedure ApplyTerrainTexture;

    // the plane that is edited
    procedure Copy;
    procedure Cut;
    procedure Paste;
    procedure Clear;
    procedure CopyView(AView: TVoxelEditorView);
    procedure PasteView(AView: TVoxelEditorView);
    procedure FlipHorizontal;
    procedure FlipVertical;
    procedure RotateLeft;
    procedure RotateRight;
    procedure SelectView(AView: TVoxelEditorView);
    procedure SelectSlice(AAxis: TVoxelEditorAxis; ALevel: Integer);
    /// <summary>The plane of the list of the window by its place (the slices x, y and z, then the six views)</summary>
    procedure SelectPlaneByIndex(AIndex: Integer);
    procedure IncreaseLevel;
    procedure DecreaseLevel;

    // the whole voxel
    procedure RemoveNonVisible;
    procedure Rotate;
    procedure RotateHighQuality;
    procedure CropHeight;
    procedure ShrinkHeight;
    procedure CountColors;
    procedure ToGrayScale;
    procedure ConvertToPalette;
    procedure ShowGamePalette(AKind: TVoxelEditorPaletteKind);

    // the mouse and the colors
    procedure SelectTool(ATool: TVoxelEditorTool);
    procedure ChooseColor(AIndex: Integer);
    /// <summary>A click on a square of the palette: the color goes to the left or to the right button</summary>
    procedure PickPaletteColor(AIndex: Integer; AButton: TVoxelEditorMouseButton);
    procedure MouseDown(AButton: TVoxelEditorMouseButton; AX, AY: Integer);
    procedure MouseMove(AX, AY: Integer);
    procedure MouseUp;
    procedure ZoomIn;
    procedure ZoomOut;

    // edit
    procedure Undo;
    procedure Redo;

    property Model: TVoxelEditorModel read FModel;
    property Plane: TVoxelEditorPlane read FPlane;
    property FileName: string read FFileName;
    property Modified: Boolean read FChanged;
    property Zoom: Integer read FZoom;
    property Tool: TVoxelEditorTool read FTool;
    property Color1: Cardinal read GetColor1;
    property Color2: Cardinal read GetColor2;
    /// <summary>The colors of the palette of the window; the first square is "no voxel"</summary>
    property Palette: TVoxelEditorPalette read FPalette;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tools.PathText, DelphiDoom.Tools.Types,
  DelphiDoom.VoxelEditor.Views,
  DelphiDoom.VoxelEditor.Planes,
  DelphiDoom.VoxelEditor.Transforms,
  DelphiDoom.VoxelEditor.Operations,
  DelphiDoom.VoxelEditor.Rotator,
  DelphiDoom.VoxelEditor.Palettes,
  DelphiDoom.VoxelEditor.Quantizer,
  DelphiDoom.VoxelEditor.MeshOptimizer,
  DelphiDoom.VoxelEditor.Format.Ddvox,
  DelphiDoom.VoxelEditor.Format.Kvx,
  DelphiDoom.VoxelEditor.Format.Vox,
  DelphiDoom.VoxelEditor.Format.Ddmesh;

resourcestring
  SPresenterCrop = 'Crop heightmap';
  SPresenterShrink = 'Shrink heightmap';
  SPresenterConverting = 'Converting %s';

const
  IMPORT_KVX = 0;
  IMPORT_VOX = 1;
  IMPORT_DDMESH = 2;
  TRANSFORM_FLIP_HORIZONTAL = 0;
  TRANSFORM_FLIP_VERTICAL = 1;
  TRANSFORM_ROTATE_LEFT = 2;
  TRANSFORM_ROTATE_RIGHT = 3;

{ TVoxelEditorPresenter }

constructor TVoxelEditorPresenter.Create(const AView: IVoxelEditorView; const ADialogs: IVoxelEditorDialogs;
  const AClipboard: IVoxelEditorClipboard; const ALoader: IVoxelEditorImageLoader;
  const AExporter: IVoxelEditorImageExporter; const AFileSystem: IToolFileSystem;
  const ABackup: IToolFileBackup; const AStore: ISettingsStore; const ARecentFiles: IRecentFiles;
  const AUndo: IToolUndoHistory);
begin
  inherited Create;
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(ADialogs) then
    raise EArgumentNilException.Create('ADialogs');
  if not Assigned(AClipboard) then
    raise EArgumentNilException.Create('AClipboard');
  if not Assigned(ALoader) then
    raise EArgumentNilException.Create('ALoader');
  if not Assigned(AExporter) then
    raise EArgumentNilException.Create('AExporter');
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(ABackup) then
    raise EArgumentNilException.Create('ABackup');
  if not Assigned(AStore) then
    raise EArgumentNilException.Create('AStore');
  if not Assigned(ARecentFiles) then
    raise EArgumentNilException.Create('ARecentFiles');
  if not Assigned(AUndo) then
    raise EArgumentNilException.Create('AUndo');
  FView := AView;
  FDialogs := ADialogs;
  FClipboard := AClipboard;
  FLoader := ALoader;
  FExporter := AExporter;
  FFileSystem := AFileSystem;
  FBackup := ABackup;
  FStore := AStore;
  FRecentFiles := ARecentFiles;
  FUndo := AUndo;
  FZoom := 4;
  FNewSize := VOXEL_EDITOR_DEFAULT_SIZE;
  FModel := TVoxelEditorModel.Create(FNewSize);
  FPainter := TVoxelEditorPainter.Create(FModel);
  FPainter.OnBeforeChange := SaveUndo;
  FPainter.Color1 := $FFFFFF;
  FPlane := TVoxelEditorPlane.OfView(vevTop);
  FPalette := TVoxelEditorPalettes.OfGame(vepDoom);
end;

destructor TVoxelEditorPresenter.Destroy;
begin
  FPainter.Free;
  FModel.Free;
  inherited Destroy;
end;

// ---------------------------------------------------------------------------------------------------------------
// refreshing the window
// ---------------------------------------------------------------------------------------------------------------

function TVoxelEditorPresenter.GetColor1: Cardinal;
begin
  Result := FPainter.Color1;
end;

function TVoxelEditorPresenter.GetColor2: Cardinal;
begin
  Result := FPainter.Color2;
end;

procedure TVoxelEditorPresenter.SaveUndo;
begin
  FUndo.Save(FModel.Snapshot);
end;

procedure TVoxelEditorPresenter.Commit;
begin
  FChanged := True;
  FPainter.RefreshDepth;
  RefreshPlane;
  RefreshState;
  RefreshTitle;
end;

procedure TVoxelEditorPresenter.RefreshPlane;
begin
  FView.ShowPlane(TVoxelEditorPlanes.Read(FModel, FPlane), FModel.Size, FZoom);
end;

procedure TVoxelEditorPresenter.RefreshState;
var
  LState: TVoxelEditorState;
begin
  LState.CanUndo := FUndo.CanUndo;
  LState.CanRedo := FUndo.CanRedo;
  LState.CanElevate := FPlane.Axis = veaNone;
  LState.Tool := FTool;
  LState.Color1 := FPainter.Color1;
  LState.Color2 := FPainter.Color2;
  LState.Zoom := FZoom;
  LState.Size := FModel.Size;
  LState.StatusText := FStatus;
  FView.ShowState(LState);
end;

procedure TVoxelEditorPresenter.RefreshTitle;
var
  LTitle: string;
begin
  LTitle := VOXEL_EDITOR_TITLE;
  if FFileName <> '' then
    LTitle := LTitle + ' - ' + TToolPathText.Shorten(FFileName, TOOLS_SHORT_NAME_LIMIT);
  FView.ShowTitle(LTitle);
end;

procedure TVoxelEditorPresenter.RefreshRecentFiles;
var
  LCaptions: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LCaptions, FRecentFiles.Count);
  for LIndex := 0 to FRecentFiles.Count - 1 do
    LCaptions[LIndex] := FRecentFiles.MenuCaption(LIndex);
  FView.ShowRecentFiles(LCaptions);
end;

procedure TVoxelEditorPresenter.RefreshPlanes;
const
  VIEW_NAMES: array[vevFront..vevDown] of string = ('front', 'back', 'left', 'right', 'top', 'down');
var
  LNames: TArray<string>;
  LAxis: TVoxelEditorAxis;
  LLevel, LView, LCount, LSelected: Integer;
begin
  SetLength(LNames, 3 * FModel.Size + 6);
  LCount := 0;
  for LAxis := veaX to veaZ do
    for LLevel := 0 to FModel.Size - 1 do
    begin
      LNames[LCount] := Chr(Ord('x') + Ord(LAxis) - Ord(veaX)) + IntToStr(LLevel);
      Inc(LCount);
    end;
  for LView := Ord(vevFront) to Ord(vevDown) do
  begin
    LNames[LCount] := VIEW_NAMES[TVoxelEditorView(LView)];
    Inc(LCount);
  end;
  if FPlane.Axis <> veaNone then
    LSelected := (Ord(FPlane.Axis) - Ord(veaX)) * FModel.Size + FPlane.Level
  else
    LSelected := 3 * FModel.Size + Ord(FPlane.View) - Ord(vevFront);
  FView.ShowPlanes(LNames, LSelected);
end;

procedure TVoxelEditorPresenter.RefreshAll;
begin
  FPainter.Plane := FPlane;
  FPainter.Zoom := FZoom;
  FPainter.RefreshDepth;
  RefreshPlane;
  RefreshPlanes;
  RefreshState;
  RefreshTitle;
  FView.ShowPalette(FPalette);
end;

// the palette of the window: the first square is "no voxel", then the colors of the palette without repeats (a
// palette that has all of its 256 colors different gives its nearest color to black to the empty square)
procedure TVoxelEditorPresenter.SetPaletteColors(const APalette: TVoxelEditorPalette);
var
  LSource: TVoxelEditorPalette;
  LColors: TArray<Cardinal>;
  LIndex, LCount: Integer;

  function Contains(AColor: Cardinal): Boolean;
  var
    LItem: Integer;
  begin
    for LItem := 0 to LCount - 1 do
      if LColors[LItem] = AColor then
        Exit(True);
    Result := False;
  end;

  procedure Collect;
  var
    LItem: Integer;
  begin
    LCount := 0;
    SetLength(LColors, 256);
    if LSource[0] = 0 then
    begin
      for LItem := 1 to 255 do
      begin
        LColors[LCount] := LSource[LItem];
        Inc(LCount);
      end;
    end
    else
      for LItem := 0 to 255 do
        if (LSource[LItem] <> 0) and not Contains(LSource[LItem]) then
        begin
          LColors[LCount] := LSource[LItem];
          Inc(LCount);
        end;
  end;

begin
  LSource := APalette;
  Collect;
  if LCount = 256 then
  begin
    LSource[TVoxelEditorPalettes.FindApproximateIndex(LSource, 0)] := 0;
    Collect;
  end;
  FillChar(FPalette, SizeOf(FPalette), 0);
  for LIndex := 0 to LCount - 1 do
    if LIndex + 1 <= 255 then
      FPalette[LIndex + 1] := LColors[LIndex];
  FView.ShowPalette(FPalette);
end;

// ---------------------------------------------------------------------------------------------------------------
// the plane
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorPresenter.ApplyPlane(const APlane: TVoxelEditorPlane);
begin
  FPlane := APlane;
  if (FPlane.Axis <> veaNone) and (FTool = vetElevate) then
    FTool := vetFreeDraw;
  RefreshAll;
end;

procedure TVoxelEditorPresenter.SelectView(AView: TVoxelEditorView);
begin
  ApplyPlane(TVoxelEditorPlane.OfView(AView));
end;

procedure TVoxelEditorPresenter.SelectSlice(AAxis: TVoxelEditorAxis; ALevel: Integer);
begin
  if AAxis = veaNone then
    Exit;
  FLevels[AAxis] := EnsureRange(ALevel, 0, FModel.Size - 1);
  ApplyPlane(TVoxelEditorPlane.Slice(AAxis, FLevels[AAxis]));
end;

procedure TVoxelEditorPresenter.SelectPlaneByIndex(AIndex: Integer);
var
  LSize: Integer;
begin
  LSize := FModel.Size;
  if (AIndex < 0) or (AIndex >= 3 * LSize + 6) then
    Exit;
  if AIndex >= 3 * LSize then
    SelectView(TVoxelEditorView(Ord(vevFront) + AIndex - 3 * LSize))
  else
    SelectSlice(TVoxelEditorAxis(Ord(veaX) + AIndex div LSize), AIndex mod LSize);
end;

procedure TVoxelEditorPresenter.ChangeLevel(ADelta: Integer);
var
  LLevel: Integer;
begin
  if FPlane.Axis = veaNone then
    Exit;
  LLevel := FLevels[FPlane.Axis] + ADelta;
  if (LLevel < 0) or (LLevel > FModel.Size - 1) then
    Exit;
  SelectSlice(FPlane.Axis, LLevel);
end;

procedure TVoxelEditorPresenter.IncreaseLevel;
begin
  ChangeLevel(1);
end;

procedure TVoxelEditorPresenter.DecreaseLevel;
begin
  ChangeLevel(-1);
end;

procedure TVoxelEditorPresenter.CopyPlaneToClipboard(const APlane: TVoxelEditorPlane);
begin
  FClipboard.SetImage(TVoxelEditorPlanes.Read(FModel, APlane), FModel.Size);
end;

procedure TVoxelEditorPresenter.PasteFromClipboard(const APlane: TVoxelEditorPlane);
var
  LImage: TVoxelEditorImage;
begin
  if not APlane.IsValid then
    Exit;
  if not FClipboard.TryGetImage(FModel.Size, LImage) then
    Exit;
  SaveUndo;
  TVoxelEditorPlanes.Write(FModel, APlane, LImage);
  Commit;
end;

procedure TVoxelEditorPresenter.Copy;
begin
  CopyPlaneToClipboard(FPlane);
end;

procedure TVoxelEditorPresenter.Cut;
begin
  if not FPlane.IsValid then
    Exit;
  SaveUndo;
  CopyPlaneToClipboard(FPlane);
  TVoxelEditorPlanes.Erase(FModel, FPlane);
  Commit;
end;

procedure TVoxelEditorPresenter.Paste;
begin
  PasteFromClipboard(FPlane);
end;

procedure TVoxelEditorPresenter.Clear;
begin
  if not FPlane.IsValid then
    Exit;
  SaveUndo;
  TVoxelEditorPlanes.Erase(FModel, FPlane);
  Commit;
end;

procedure TVoxelEditorPresenter.CopyView(AView: TVoxelEditorView);
begin
  CopyPlaneToClipboard(TVoxelEditorPlane.OfView(AView));
end;

procedure TVoxelEditorPresenter.PasteView(AView: TVoxelEditorView);
begin
  PasteFromClipboard(TVoxelEditorPlane.OfView(AView));
end;

procedure TVoxelEditorPresenter.TransformPlane(AKind: Integer);
var
  LImage: TVoxelEditorImage;
begin
  if not FPlane.IsValid then
    Exit;
  SaveUndo;
  LImage := TVoxelEditorPlanes.Read(FModel, FPlane);
  case AKind of
    TRANSFORM_FLIP_HORIZONTAL:
      LImage := TVoxelEditorTransforms.FlipHorizontal(LImage, FModel.Size);
    TRANSFORM_FLIP_VERTICAL:
      LImage := TVoxelEditorTransforms.FlipVertical(LImage, FModel.Size);
    TRANSFORM_ROTATE_LEFT:
      LImage := TVoxelEditorTransforms.RotateCounterClockwise(LImage, FModel.Size);
    TRANSFORM_ROTATE_RIGHT:
      LImage := TVoxelEditorTransforms.RotateClockwise(LImage, FModel.Size);
  end;
  TVoxelEditorPlanes.Write(FModel, FPlane, LImage);
  Commit;
end;

procedure TVoxelEditorPresenter.FlipHorizontal;
begin
  TransformPlane(TRANSFORM_FLIP_HORIZONTAL);
end;

procedure TVoxelEditorPresenter.FlipVertical;
begin
  TransformPlane(TRANSFORM_FLIP_VERTICAL);
end;

procedure TVoxelEditorPresenter.RotateLeft;
begin
  TransformPlane(TRANSFORM_ROTATE_LEFT);
end;

procedure TVoxelEditorPresenter.RotateRight;
begin
  TransformPlane(TRANSFORM_ROTATE_RIGHT);
end;

// ---------------------------------------------------------------------------------------------------------------
// files
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorPresenter.ShowError(const AMessage: string);
begin
  FDialogs.ShowMessage(AMessage);
end;

function TVoxelEditorPresenter.ReadFile(const AFileName: string; out ABytes: TBytes): Boolean;
begin
  Result := FFileSystem.FileExists(AFileName) and FFileSystem.TryReadAllBytes(AFileName, ABytes);
  if not Result then
    ShowError(Format(SVoxelEditorFileNotFound, [TToolPathText.Shorten(AFileName, TOOLS_SHORT_NAME_LIMIT)]));
end;

function TVoxelEditorPresenter.WriteFile(const AFileName: string; const ABytes: TBytes): Boolean;
begin
  FBackup.Backup(AFileName);
  Result := FFileSystem.TryWriteAllBytes(AFileName, ABytes);
  if not Result then
    ShowError(Format(SVoxelEditorCannotWrite, [AFileName]));
end;

procedure TVoxelEditorPresenter.NewModel(ASize: Integer);
begin
  FModel.Reset(ASize);
  ResetDocument;
end;

// the cube is what it is: the document around it starts again (no file, no undo, nothing changed, the top view)
procedure TVoxelEditorPresenter.ResetDocument;
begin
  FUndo.Clear;
  FFileName := '';
  FChanged := False;
  FLevels[veaX] := 0;
  FLevels[veaY] := 0;
  FLevels[veaZ] := 0;
  FPlane := TVoxelEditorPlane.OfView(vevTop);
  FStatus := '';
  RefreshAll;
end;

procedure TVoxelEditorPresenter.Start(const ACommandLineFile: string);
begin
  FStore.Load;
  FRecentFiles.LoadFrom(FStore, VOXEL_EDITOR_SECTION_HISTORY);
  FZoom := EnsureRange(FStore.ReadInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_ZOOM, 4),
    VOXEL_EDITOR_MIN_ZOOM, VOXEL_EDITOR_MAX_ZOOM);
  FNewSize := FStore.ReadInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_SIZE, VOXEL_EDITOR_DEFAULT_SIZE);
  if (FNewSize < 1) or (FNewSize > VOXEL_EDITOR_MAX_SIZE) then
    FNewSize := VOXEL_EDITOR_DEFAULT_SIZE;
  FPainter.Color1 := Cardinal(FStore.ReadInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_COLOR1, $FFFFFF));
  FPainter.Color2 := Cardinal(FStore.ReadInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_COLOR2, 0));
  SetPaletteColors(TVoxelEditorPalettes.OfGame(vepDoom));
  NewModel(FNewSize);
  if (ACommandLineFile <> '') and FFileSystem.FileExists(ACommandLineFile) then
    LoadVoxel(ACommandLineFile);
  RefreshRecentFiles;
end;

procedure TVoxelEditorPresenter.Shutdown;
begin
  FStore.WriteInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_ZOOM, FZoom);
  FStore.WriteInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_SIZE, FNewSize);
  FStore.WriteInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_COLOR1, Integer(FPainter.Color1));
  FStore.WriteInteger(VOXEL_EDITOR_SECTION_OPTIONS, VOXEL_EDITOR_SETTING_COLOR2, Integer(FPainter.Color2));
  FRecentFiles.SaveTo(FStore, VOXEL_EDITOR_SECTION_HISTORY);
  FStore.Save;
end;

function TVoxelEditorPresenter.TryClose: Boolean;
begin
  Result := True;
  if not FChanged then
    Exit;
  case FDialogs.AskSaveChanges of
    vecCancel:
      Result := False;
    vecYes:
      begin
        Save;
        Result := not FChanged;
      end;
  end;
end;

procedure TVoxelEditorPresenter.RequestClose;
begin
  if TryClose then
    FView.CloseWindow;
end;

procedure TVoxelEditorPresenter.About;
begin
  FDialogs.ShowAbout;
end;

procedure TVoxelEditorPresenter.NewVoxel;
var
  LSize: Integer;
begin
  if not TryClose then
    Exit;
  LSize := FModel.Size;
  if FDialogs.AskNewSize(LSize) then
  begin
    FNewSize := LSize;
    NewModel(LSize);
  end;
end;

function TVoxelEditorPresenter.LoadVoxel(const AFileName: string): Boolean;
var
  LBytes: TBytes;
begin
  Result := False;
  if not ReadFile(AFileName, LBytes) then
    Exit;
  try
    FUndo.Clear;
    TVoxelEditorDdvoxFormat.Read(LBytes, FModel);
  except
    on E: EVoxelEditorException do
    begin
      NewModel(FModel.Size);
      ShowError(E.Message);
      Exit;
    end;
  end;
  FRecentFiles.Add(AFileName);
  ResetDocument;
  FFileName := AFileName;
  RefreshTitle;
  RefreshRecentFiles;
  Result := True;
end;

procedure TVoxelEditorPresenter.OpenFile;
var
  LFileName: string;
begin
  if TryClose and FDialogs.PickVoxelToOpen(LFileName) then
    LoadVoxel(LFileName);
end;

procedure TVoxelEditorPresenter.OpenVoxel(const AFileName: string);
begin
  if TryClose then
    LoadVoxel(AFileName);
end;

procedure TVoxelEditorPresenter.OpenRecent(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FRecentFiles.Count) then
    OpenVoxel(FRecentFiles[AIndex]);
end;

function TVoxelEditorPresenter.SaveTo(const AFileName: string): Boolean;
begin
  Result := WriteFile(AFileName, TVoxelEditorDdvoxFormat.Write(FModel));
  if Result then
  begin
    FFileName := AFileName;
    FChanged := False;
    FRecentFiles.Add(AFileName);
    RefreshTitle;
    RefreshRecentFiles;
  end;
end;

procedure TVoxelEditorPresenter.Save;
begin
  if FFileName = '' then
    SaveAs
  else
    SaveTo(FFileName);
end;

procedure TVoxelEditorPresenter.SaveAs;
var
  LFileName: string;
begin
  if FDialogs.PickVoxelToSave(FFileName, LFileName) then
    SaveTo(LFileName);
end;

function TVoxelEditorPresenter.ImportFile(const AFileName: string; AKind: Integer): Boolean;
var
  LBytes: TBytes;
begin
  Result := False;
  if not ReadFile(AFileName, LBytes) then
    Exit;
  try
    case AKind of
      IMPORT_KVX:
        TVoxelEditorKvxFormat.Read(LBytes, FModel);
      IMPORT_VOX:
        TVoxelEditorVoxFormat.Read(LBytes, FModel);
    else
      TVoxelEditorDdmeshFormat.Read(LBytes, FModel);
    end;
  except
    on E: EVoxelEditorException do
    begin
      ShowError(E.Message);
      NewModel(FModel.Size);
      Exit;
    end;
  end;
  // the old editor made a new, unnamed document of the voxel it had read
  ResetDocument;
  Result := True;
end;

procedure TVoxelEditorPresenter.ImportKvx;
var
  LFileName: string;
begin
  if TryClose and FDialogs.PickKvxToImport(LFileName) then
    ImportFile(LFileName, IMPORT_KVX);
end;

procedure TVoxelEditorPresenter.ImportVox;
var
  LFileName: string;
begin
  if TryClose and FDialogs.PickVoxToImport(LFileName) then
    ImportFile(LFileName, IMPORT_VOX);
end;

procedure TVoxelEditorPresenter.ImportDdmesh;
var
  LFileName: string;
begin
  if TryClose and FDialogs.PickDdmeshToImport(LFileName) then
    ImportFile(LFileName, IMPORT_DDMESH);
end;

procedure TVoxelEditorPresenter.ExportVox;
var
  LFileName: string;
begin
  if FDialogs.PickVoxToExport(LFileName) then
    WriteFile(LFileName, TVoxelEditorVoxFormat.Write(FModel));
end;

procedure TVoxelEditorPresenter.ExportMesh;
var
  LFileName: string;
  LMesh: TVoxelEditorMeshOptimizer;
begin
  if not FDialogs.PickMeshToExport(LFileName) then
    Exit;
  LMesh := TVoxelEditorMeshOptimizer.Create;
  try
    LMesh.LoadVoxel(FModel);
    LMesh.Optimize;
    if WriteFile(LFileName, LMesh.ToBytes) and (LMesh.Message <> '') then
      FDialogs.ShowMessage(LMesh.Message);
  finally
    LMesh.Free;
  end;
end;

procedure TVoxelEditorPresenter.ExportPlaneImage;
var
  LFileName: string;
begin
  if not FDialogs.PickImageToExport(LFileName) then
    Exit;
  FBackup.Backup(LFileName);
  if not FExporter.Export(LFileName, TVoxelEditorPlanes.Read(FModel, FPlane), FModel.Size) then
    ShowError(Format(SVoxelEditorCannotWrite, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
end;

procedure TVoxelEditorPresenter.ExportViewImage(AView: TVoxelEditorView);
var
  LFileName: string;
begin
  if (AView = vevNone) or not FDialogs.PickImageToExport(LFileName) then
    Exit;
  FBackup.Backup(LFileName);
  if not FExporter.Export(LFileName, TVoxelEditorViews.GetView(FModel, AView), FModel.Size) then
    ShowError(Format(SVoxelEditorCannotWrite, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
end;

procedure TVoxelEditorPresenter.ConvertFiles(ABatch: TVoxelEditorBatch);
var
  LFiles: TArray<string>;
  LIndex: Integer;
  LBytes, LOutput: TBytes;
  LTarget, LKind: string;
  LTemp: TVoxelEditorModel;
  LMesh: TVoxelEditorMeshOptimizer;
begin
  if ABatch = vebKvxToDdmesh then
    LKind := 'kvx'
  else
    LKind := 'ddvox';
  if not FDialogs.PickFilesToConvert(LKind, LFiles) then
    Exit;
  LTemp := TVoxelEditorModel.Create(1);
  try
    for LIndex := 0 to High(LFiles) do
    begin
      FView.ShowProgress(Format(SPresenterConverting, [TToolPathText.Shorten(LFiles[LIndex], TOOLS_SHORT_NAME_LIMIT)]),
        LIndex * 100 div Length(LFiles));
      // a file that is not there or is not good is left out, as it was
      if not (FFileSystem.FileExists(LFiles[LIndex]) and FFileSystem.TryReadAllBytes(LFiles[LIndex], LBytes)) then
        Continue;
      try
        if ABatch = vebKvxToDdmesh then
          TVoxelEditorKvxFormat.Read(LBytes, LTemp)
        else
          TVoxelEditorDdvoxFormat.Read(LBytes, LTemp);
        if ABatch = vebDdvoxToVox then
        begin
          LTarget := ChangeFileExt(LFiles[LIndex], '.vox');
          LOutput := TVoxelEditorVoxFormat.Write(LTemp);
        end
        else
        begin
          LTarget := ChangeFileExt(LFiles[LIndex], '.ddmesh');
          LMesh := TVoxelEditorMeshOptimizer.Create;
          try
            LMesh.LoadVoxel(LTemp);
            LMesh.Optimize;
            LOutput := LMesh.ToBytes;
          finally
            LMesh.Free;
          end;
        end;
        FBackup.Backup(LTarget);
        FFileSystem.TryWriteAllBytes(LTarget, LOutput);
      except
        on EVoxelEditorException do
          Continue;
      end;
    end;
  finally
    LTemp.Free;
    FView.ShowProgress('', -1);
  end;
end;

// ---------------------------------------------------------------------------------------------------------------
// pictures
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorPresenter.ImportImage;
var
  LFileName: string;
  LImage: TVoxelEditorImage;
begin
  if not FPlane.IsValid or not FDialogs.PickImageToImport(LFileName) then
    Exit;
  if not FLoader.TryLoad(LFileName, FModel.Size, LImage) then
  begin
    ShowError(Format(SVoxelEditorFileNotFound, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  SaveUndo;
  TVoxelEditorPlanes.Write(FModel, FPlane, LImage);
  Commit;
end;

procedure TVoxelEditorPresenter.ImportHeightmap;
var
  LFileName: string;
  LWidth, LHeight, LSize: Integer;
  LImage: TVoxelEditorImage;
begin
  if not TryClose or not FDialogs.PickImageToImport(LFileName) then
    Exit;
  if not (FLoader.TryGetDimensions(LFileName, LWidth, LHeight) and (LWidth > 0) and (LHeight > 0)) then
  begin
    ShowError(Format(SVoxelEditorFileNotFound, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  LSize := TVoxelEditorOperations.HeightmapSize(LWidth, LHeight);
  if not FLoader.TryLoad(LFileName, LSize, LImage) then
  begin
    ShowError(Format(SVoxelEditorFileNotFound, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  NewModel(LSize);
  // the picture has its top row first, the cube its bottom plane: the picture is flipped
  TVoxelEditorOperations.BuildHeightmap(FModel, TVoxelEditorTransforms.FlipVertical(LImage, LSize));
  Commit;
end;

procedure TVoxelEditorPresenter.ApplyTerrainTexture;
var
  LFileName: string;
  LImage: TVoxelEditorImage;
begin
  if not FDialogs.PickImageToImport(LFileName) then
    Exit;
  if not FLoader.TryLoad(LFileName, FModel.Size, LImage) then
  begin
    ShowError(Format(SVoxelEditorFileNotFound, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  SaveUndo;
  TVoxelEditorOperations.ApplyTerrainTexture(FModel, TVoxelEditorTransforms.FlipVertical(LImage, FModel.Size));
  Commit;
end;

// ---------------------------------------------------------------------------------------------------------------
// the whole voxel
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorPresenter.RemoveNonVisible;
begin
  SaveUndo;
  TVoxelEditorOperations.RemoveNonVisible(FModel);
  Commit;
end;

procedure TVoxelEditorPresenter.RotateModel(AHighQuality: Boolean);
begin
  if not FDialogs.AskRotation(FRotationDegrees) then
    Exit;
  SaveUndo;
  if AHighQuality then
    TVoxelEditorRotator.RotateHighQuality(FModel, FRotationDegrees / 360 * (2 * Pi))
  else
    TVoxelEditorRotator.Rotate(FModel, FRotationDegrees / 360 * (2 * Pi));
  TVoxelEditorOperations.RemoveNonVisible(FModel);
  Commit;
end;

procedure TVoxelEditorPresenter.Rotate;
begin
  RotateModel(False);
end;

procedure TVoxelEditorPresenter.RotateHighQuality;
begin
  RotateModel(True);
end;

procedure TVoxelEditorPresenter.CropHeight;
var
  LMin, LMax: Integer;
begin
  LMin := 0;
  LMax := 255;
  if FDialogs.AskHeightRange(SPresenterCrop, TVoxelEditorViews.GetView(FModel, vevFront), FModel.Size, LMin, LMax) then
  begin
    SaveUndo;
    TVoxelEditorOperations.CropHeight(FModel, LMin, LMax);
    Commit;
  end;
end;

procedure TVoxelEditorPresenter.ShrinkHeight;
var
  LMin, LMax: Integer;
begin
  LMin := 0;
  LMax := 255;
  if FDialogs.AskHeightRange(SPresenterShrink, TVoxelEditorViews.GetView(FModel, vevFront), FModel.Size, LMin, LMax) then
  begin
    SaveUndo;
    TVoxelEditorOperations.ShrinkHeight(FModel, LMin, LMax);
    Commit;
  end;
end;

procedure TVoxelEditorPresenter.CountColors;
begin
  FDialogs.ShowMessage(Format(SVoxelEditorUniqueColors, [TVoxelEditorOperations.CountColors(FModel)]));
end;

procedure TVoxelEditorPresenter.ToGrayScale;
var
  LBefore: TBytes;
begin
  LBefore := FModel.Snapshot;
  if TVoxelEditorOperations.ToGrayScale(FModel) then
  begin
    FUndo.Save(LBefore);
    Commit;
  end;
  SetPaletteColors(TVoxelEditorPalettes.Gray);
end;

procedure TVoxelEditorPresenter.ShowGamePalette(AKind: TVoxelEditorPaletteKind);
begin
  SetPaletteColors(TVoxelEditorPalettes.OfGame(AKind));
end;

procedure TVoxelEditorPresenter.ConvertToPalette;
var
  LKind: TVoxelEditorPaletteKind;
  LFileName: string;
  LBytes, LBefore: TBytes;
  LPalette: TVoxelEditorPalette;
begin
  if not FDialogs.AskPaletteKind(LKind) then
    Exit;
  case LKind of
    vepOctree:
      begin
        SaveUndo;
        TVoxelEditorQuantizer.Quantize(FModel, 255);
        Commit;
        Exit;
      end;
    vepFile:
      begin
        if not FDialogs.PickPaletteFile(LFileName) then
          Exit;
        // a file that cannot be read gives the gray ramp, as it did
        LBytes := nil;
        if FFileSystem.FileExists(LFileName) then
          FFileSystem.TryReadAllBytes(LFileName, LBytes);
        LPalette := TVoxelEditorPalettes.FromFileBytes(LBytes);
      end;
  else
    LPalette := TVoxelEditorPalettes.OfGame(LKind);
  end;
  SetPaletteColors(LPalette);
  LBefore := FModel.Snapshot;
  if TVoxelEditorOperations.ApplyPalette(FModel, LPalette) then
  begin
    FUndo.Save(LBefore);
    Commit;
  end;
end;

// ---------------------------------------------------------------------------------------------------------------
// the mouse and the colors
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorPresenter.SelectTool(ATool: TVoxelEditorTool);
begin
  if (ATool = vetElevate) and (FPlane.Axis <> veaNone) then
    Exit;
  FTool := ATool;
  FPainter.Tool := ATool;
  RefreshState;
end;

procedure TVoxelEditorPresenter.ChooseColor(AIndex: Integer);
var
  LColor: Cardinal;
begin
  if AIndex = 1 then
    LColor := FPainter.Color1
  else
    LColor := FPainter.Color2;
  if not FDialogs.PickColor(LColor) then
    Exit;
  if AIndex = 1 then
    FPainter.Color1 := LColor
  else
    FPainter.Color2 := LColor;
  RefreshState;
end;

procedure TVoxelEditorPresenter.PickPaletteColor(AIndex: Integer; AButton: TVoxelEditorMouseButton);
var
  LColor: Cardinal;
begin
  if (AIndex < 0) or (AIndex > 255) then
    Exit;
  LColor := FPalette[AIndex];
  if AButton = vebLeft then
    FPainter.Color1 := LColor
  else
    FPainter.Color2 := LColor;
  RefreshState;
end;

procedure TVoxelEditorPresenter.MouseDown(AButton: TVoxelEditorMouseButton; AX, AY: Integer);
begin
  FPainter.Plane := FPlane;
  FPainter.Zoom := FZoom;
  FPainter.Tool := FTool;
  FPainter.Changed := False;
  FPainter.MouseDown(AButton, AX, AY);
  FStatus := FPainter.StatusAt(AX, AY);
  if FPainter.Changed then
    Commit
  else
    RefreshState;
end;

procedure TVoxelEditorPresenter.MouseMove(AX, AY: Integer);
begin
  FPainter.Changed := False;
  FPainter.MouseMove(AX, AY);
  FStatus := FPainter.StatusAt(AX, AY);
  if FPainter.Changed then
  begin
    FChanged := True;
    RefreshPlane;
    RefreshTitle;
  end;
  RefreshState;
end;

procedure TVoxelEditorPresenter.MouseUp;
begin
  FPainter.MouseUp;
  RefreshState;
end;

procedure TVoxelEditorPresenter.ZoomIn;
begin
  if FZoom < VOXEL_EDITOR_MAX_ZOOM then
  begin
    Inc(FZoom);
    FPainter.Zoom := FZoom;
    RefreshPlane;
    RefreshState;
  end;
end;

procedure TVoxelEditorPresenter.ZoomOut;
begin
  if FZoom > VOXEL_EDITOR_MIN_ZOOM then
  begin
    Dec(FZoom);
    FPainter.Zoom := FZoom;
    RefreshPlane;
    RefreshState;
  end;
end;

// ---------------------------------------------------------------------------------------------------------------
// edit
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorPresenter.Undo;
var
  LSize: Integer;
begin
  if not FUndo.CanUndo then
    Exit;
  LSize := FModel.Size;
  FModel.Restore(FUndo.Undo(FModel.Snapshot));
  FChanged := True;
  if FModel.Size <> LSize then
    RefreshAll
  else
    Commit;
end;

procedure TVoxelEditorPresenter.Redo;
var
  LSize: Integer;
begin
  if not FUndo.CanRedo then
    Exit;
  LSize := FModel.Size;
  FModel.Restore(FUndo.Redo(FModel.Snapshot));
  FChanged := True;
  if FModel.Size <> LSize then
    RefreshAll
  else
    Commit;
end;

end.
