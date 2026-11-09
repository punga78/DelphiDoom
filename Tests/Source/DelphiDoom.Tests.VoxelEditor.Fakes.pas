{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel editor - the fakes                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Intf;

type
  /// <summary>A window that remembers what it was told</summary>
  TFakeVoxelView = class(TInterfacedObject, IVoxelEditorView)
  public
    PlaneCount: Integer;
    Plane: TVoxelEditorImage;
    PlaneSize: Integer;
    PlaneZoom: Integer;
    Title: string;
    State: TVoxelEditorState;
    StateCount: Integer;
    Palette: TVoxelEditorPalette;
    RecentCaptions: TArray<string>;
    PlaneNames: TArray<string>;
    SelectedPlane: Integer;
    ProgressTexts: TList<string>;
    ProgressPercents: TList<Integer>;
    CloseCount: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure ShowPlane(const AImage: TVoxelEditorImage; ASize, AZoom: Integer);
    procedure ShowTitle(const ATitle: string);
    procedure ShowState(const AState: TVoxelEditorState);
    procedure ShowPalette(const APalette: TVoxelEditorPalette);
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    procedure ShowPlanes(const ANames: TArray<string>; ASelected: Integer);
    procedure ShowProgress(const AText: string; APercent: Integer);
    procedure CloseWindow;
  end;

  /// <summary>Dialogs that answer what the test says</summary>
  TFakeVoxelDialogs = class(TInterfacedObject, IVoxelEditorDialogs)
  public
    Names: array[0..9] of string;
    Results: array[0..9] of Boolean;
    ConvertFiles: TArray<string>;
    ColorResult: Boolean;
    ColorValue: Cardinal;
    NewSizeResult: Boolean;
    NewSizeValue: Integer;
    RotationResult: Boolean;
    RotationValue: Double;
    HeightResult: Boolean;
    HeightMin, HeightMax: Integer;
    HeightTitle: string;
    PaletteResult: Boolean;
    PaletteKind: TVoxelEditorPaletteKind;
    Confirmation: TVoxelEditorConfirmation;
    ConfirmCount: Integer;
    AboutCount: Integer;
    Messages: TList<string>;
    constructor Create;
    destructor Destroy; override;
    function PickVoxelToOpen(out AFileName: string): Boolean;
    function PickVoxelToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickKvxToImport(out AFileName: string): Boolean;
    function PickVoxToImport(out AFileName: string): Boolean;
    function PickDdmeshToImport(out AFileName: string): Boolean;
    function PickVoxToExport(out AFileName: string): Boolean;
    function PickMeshToExport(out AFileName: string): Boolean;
    function PickImageToImport(out AFileName: string): Boolean;
    function PickImageToExport(out AFileName: string): Boolean;
    function PickPaletteFile(out AFileName: string): Boolean;
    function PickFilesToConvert(const AKind: string; out AFileNames: TArray<string>): Boolean;
    function PickColor(var AColor: Cardinal): Boolean;
    function AskNewSize(var ASize: Integer): Boolean;
    function AskRotation(var ADegrees: Double): Boolean;
    function AskHeightRange(const ATitle: string; const APreview: TVoxelEditorImage; ASize: Integer;
      var AMin, AMax: Integer): Boolean;
    function AskPaletteKind(out AKind: TVoxelEditorPaletteKind): Boolean;
    function AskSaveChanges: TVoxelEditorConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
    /// <summary>The answer of one of the file dialogs: 0 open, 1 save, 2 KVX, 3 VOX, 4 DDMESH, 5 export VOX, 6 export mesh, 7 image to import, 8 image to export, 9 palette</summary>
    procedure Answer(AKind: Integer; const AName: string; AResult: Boolean = True);
  end;

  TFakeVoxelClipboard = class(TInterfacedObject, IVoxelEditorClipboard)
  public
    Image: TVoxelEditorImage;
    Size: Integer;
    HasImage: Boolean;
    function TryGetImage(ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
    procedure SetImage(const AImage: TVoxelEditorImage; ASize: Integer);
  end;

  TFakeVoxelImageLoader = class(TInterfacedObject, IVoxelEditorImageLoader)
  public
    Width, Height: Integer;
    Fill: Cardinal;
    CanLoad: Boolean;
    function TryGetDimensions(const AFileName: string; out AWidth, AHeight: Integer): Boolean;
    function TryLoad(const AFileName: string; ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
  end;

  TFakeVoxelImageExporter = class(TInterfacedObject, IVoxelEditorImageExporter)
  public
    Names: TList<string>;
    Images: TList<TVoxelEditorImage>;
    Succeeds: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Export(const AFileName: string; const AImage: TVoxelEditorImage; ASize: Integer): Boolean;
  end;

implementation

{ TFakeVoxelView }

constructor TFakeVoxelView.Create;
begin
  inherited Create;
  ProgressTexts := TList<string>.Create;
  ProgressPercents := TList<Integer>.Create;
end;

destructor TFakeVoxelView.Destroy;
begin
  ProgressTexts.Free;
  ProgressPercents.Free;
  inherited Destroy;
end;

procedure TFakeVoxelView.ShowPlane(const AImage: TVoxelEditorImage; ASize, AZoom: Integer);
begin
  Inc(PlaneCount);
  Plane := AImage;
  PlaneSize := ASize;
  PlaneZoom := AZoom;
end;

procedure TFakeVoxelView.ShowTitle(const ATitle: string);
begin
  Title := ATitle;
end;

procedure TFakeVoxelView.ShowState(const AState: TVoxelEditorState);
begin
  Inc(StateCount);
  State := AState;
end;

procedure TFakeVoxelView.ShowPalette(const APalette: TVoxelEditorPalette);
begin
  Palette := APalette;
end;

procedure TFakeVoxelView.ShowRecentFiles(const ACaptions: TArray<string>);
begin
  RecentCaptions := ACaptions;
end;

procedure TFakeVoxelView.ShowPlanes(const ANames: TArray<string>; ASelected: Integer);
begin
  PlaneNames := ANames;
  SelectedPlane := ASelected;
end;

procedure TFakeVoxelView.ShowProgress(const AText: string; APercent: Integer);
begin
  ProgressTexts.Add(AText);
  ProgressPercents.Add(APercent);
end;

procedure TFakeVoxelView.CloseWindow;
begin
  Inc(CloseCount);
end;

{ TFakeVoxelDialogs }

constructor TFakeVoxelDialogs.Create;
begin
  inherited Create;
  Messages := TList<string>.Create;
  Confirmation := vecNo;
  ColorResult := True;
  NewSizeResult := True;
  NewSizeValue := 16;
  RotationResult := True;
  HeightResult := True;
  HeightMax := 255;
  PaletteResult := True;
end;

destructor TFakeVoxelDialogs.Destroy;
begin
  Messages.Free;
  inherited Destroy;
end;

procedure TFakeVoxelDialogs.Answer(AKind: Integer; const AName: string; AResult: Boolean);
begin
  Names[AKind] := AName;
  Results[AKind] := AResult;
end;

function TFakeVoxelDialogs.PickVoxelToOpen(out AFileName: string): Boolean;
begin
  AFileName := Names[0];
  Result := Results[0];
end;

function TFakeVoxelDialogs.PickVoxelToSave(const ASuggestedName: string; out AFileName: string): Boolean;
begin
  AFileName := Names[1];
  Result := Results[1];
end;

function TFakeVoxelDialogs.PickKvxToImport(out AFileName: string): Boolean;
begin
  AFileName := Names[2];
  Result := Results[2];
end;

function TFakeVoxelDialogs.PickVoxToImport(out AFileName: string): Boolean;
begin
  AFileName := Names[3];
  Result := Results[3];
end;

function TFakeVoxelDialogs.PickDdmeshToImport(out AFileName: string): Boolean;
begin
  AFileName := Names[4];
  Result := Results[4];
end;

function TFakeVoxelDialogs.PickVoxToExport(out AFileName: string): Boolean;
begin
  AFileName := Names[5];
  Result := Results[5];
end;

function TFakeVoxelDialogs.PickMeshToExport(out AFileName: string): Boolean;
begin
  AFileName := Names[6];
  Result := Results[6];
end;

function TFakeVoxelDialogs.PickImageToImport(out AFileName: string): Boolean;
begin
  AFileName := Names[7];
  Result := Results[7];
end;

function TFakeVoxelDialogs.PickImageToExport(out AFileName: string): Boolean;
begin
  AFileName := Names[8];
  Result := Results[8];
end;

function TFakeVoxelDialogs.PickPaletteFile(out AFileName: string): Boolean;
begin
  AFileName := Names[9];
  Result := Results[9];
end;

function TFakeVoxelDialogs.PickFilesToConvert(const AKind: string; out AFileNames: TArray<string>): Boolean;
begin
  AFileNames := ConvertFiles;
  Result := Length(ConvertFiles) > 0;
end;

function TFakeVoxelDialogs.PickColor(var AColor: Cardinal): Boolean;
begin
  Result := ColorResult;
  if Result then
    AColor := ColorValue;
end;

function TFakeVoxelDialogs.AskNewSize(var ASize: Integer): Boolean;
begin
  Result := NewSizeResult;
  if Result then
    ASize := NewSizeValue;
end;

function TFakeVoxelDialogs.AskRotation(var ADegrees: Double): Boolean;
begin
  Result := RotationResult;
  if Result then
    ADegrees := RotationValue;
end;

function TFakeVoxelDialogs.AskHeightRange(const ATitle: string; const APreview: TVoxelEditorImage; ASize: Integer;
  var AMin, AMax: Integer): Boolean;
begin
  HeightTitle := ATitle;
  Result := HeightResult;
  if Result then
  begin
    AMin := HeightMin;
    AMax := HeightMax;
  end;
end;

function TFakeVoxelDialogs.AskPaletteKind(out AKind: TVoxelEditorPaletteKind): Boolean;
begin
  AKind := PaletteKind;
  Result := PaletteResult;
end;

function TFakeVoxelDialogs.AskSaveChanges: TVoxelEditorConfirmation;
begin
  Inc(ConfirmCount);
  Result := Confirmation;
end;

procedure TFakeVoxelDialogs.ShowMessage(const AText: string);
begin
  Messages.Add(AText);
end;

procedure TFakeVoxelDialogs.ShowAbout;
begin
  Inc(AboutCount);
end;

{ TFakeVoxelClipboard }

function TFakeVoxelClipboard.TryGetImage(ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
var
  LIndex: Integer;
begin
  Result := HasImage;
  if not Result then
    Exit;
  // a picture of another size is stretched: here it is cut or repeated, enough to keep the size
  SetLength(AImage, ASize * ASize);
  for LIndex := 0 to High(AImage) do
    AImage[LIndex] := Image[LIndex mod Length(Image)];
end;

procedure TFakeVoxelClipboard.SetImage(const AImage: TVoxelEditorImage; ASize: Integer);
begin
  Image := Copy(AImage);
  Size := ASize;
  HasImage := True;
end;

{ TFakeVoxelImageLoader }

function TFakeVoxelImageLoader.TryGetDimensions(const AFileName: string; out AWidth, AHeight: Integer): Boolean;
begin
  AWidth := Width;
  AHeight := Height;
  Result := CanLoad;
end;

function TFakeVoxelImageLoader.TryLoad(const AFileName: string; ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
var
  LIndex: Integer;
begin
  Result := CanLoad;
  if not Result then
    Exit;
  SetLength(AImage, ASize * ASize);
  for LIndex := 0 to High(AImage) do
    AImage[LIndex] := Fill;
end;

{ TFakeVoxelImageExporter }

constructor TFakeVoxelImageExporter.Create;
begin
  inherited Create;
  Names := TList<string>.Create;
  Images := TList<TVoxelEditorImage>.Create;
  Succeeds := True;
end;

destructor TFakeVoxelImageExporter.Destroy;
begin
  Names.Free;
  Images.Free;
  inherited Destroy;
end;

function TFakeVoxelImageExporter.Export(const AFileName: string; const AImage: TVoxelEditorImage; ASize: Integer): Boolean;
begin
  Names.Add(AFileName);
  Images.Add(Copy(AImage));
  Result := Succeeds;
end;

end.
