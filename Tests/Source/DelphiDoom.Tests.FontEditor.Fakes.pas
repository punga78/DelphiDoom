{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the font editor - the fakes                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.FontEditor.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Font.Types,
  DelphiDoom.FontEditor.Types,
  DelphiDoom.FontEditor.Intf;

type
  /// <summary>A window that remembers what it was told</summary>
  TFakeFontView = class(TInterfacedObject, IFontEditorView)
  public
    GridCount: Integer;
    Grid: TFontImage;
    GridLines: Boolean;
    GridZoom: Integer;
    GridColumns: Integer;
    GridRows: Integer;
    PreviewCount: Integer;
    Preview: TFontImage;
    Title: string;
    Display: TFontEditorDisplay;
    State: TFontEditorState;
    RecentCaptions: TArray<string>;
    FontNames: TArray<string>;
    CloseCount: Integer;
    procedure ShowGrid(const AImage: TFontImage; AShowGrid: Boolean; AZoom, AColumns, ARows: Integer);
    procedure ShowPreview(const AImage: TFontImage);
    procedure ShowTitle(const ATitle: string);
    procedure ShowDisplay(const ADisplay: TFontEditorDisplay);
    procedure ShowState(const AState: TFontEditorState);
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    procedure ShowFontNames(const ANames: TArray<string>);
    procedure CloseWindow;
  end;

  /// <summary>Dialogs that answer what the test says</summary>
  TFakeFontDialogs = class(TInterfacedObject, IFontEditorDialogs)
  public
    OpenName: string;
    OpenResult: Boolean;
    SaveName: string;
    SaveResult: Boolean;
    SaveSuggested: string;
    WadName: string;
    WadResult: Boolean;
    ImageName: string;
    ImageResult: Boolean;
    PaletteName: string;
    PaletteResult: Boolean;
    FontFileName: string;
    FontFileResult: Boolean;
    ColorResult: Boolean;
    ColorValue: Integer;
    Confirmation: TFontEditorConfirmation;
    ConfirmCount: Integer;
    AboutCount: Integer;
    Messages: TList<string>;
    constructor Create;
    destructor Destroy; override;
    function PickProjectToOpen(out AFileName: string): Boolean;
    function PickProjectToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickWadToSave(out AFileName: string): Boolean;
    function PickImageToExport(out AFileName: string): Boolean;
    function PickPaletteFile(out AFileName: string): Boolean;
    function PickFontFile(out AFileName: string): Boolean;
    function PickColor(var AColor: Integer): Boolean;
    function AskSaveChanges: TFontEditorConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

  TFakeFontCatalog = class(TInterfacedObject, IFontCatalog)
  public
    Names: TArray<string>;
    function FontNames: TArray<string>;
  end;

  TFakeFontInstaller = class(TInterfacedObject, IFontInstaller)
  public
    Installed: TList<string>;
    FailInstall: Boolean;
    UninstallCount: Integer;
    /// <summary>The catalog that is told of the names that a font file brings (a font file does)</summary>
    Catalog: TFakeFontCatalog;
    BroughtName: string;
    constructor Create;
    destructor Destroy; override;
    function Install(const AFileName: string): Boolean;
    procedure UninstallAll;
  end;

  TFakeFontImageExporter = class(TInterfacedObject, IFontEditorImageExporter)
  public
    Exported: TList<string>;
    LastImage: TFontImage;
    Fail: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Export(const AFileName: string; const AImage: TFontImage): Boolean;
  end;

implementation

{ TFakeFontView }

procedure TFakeFontView.ShowGrid(const AImage: TFontImage; AShowGrid: Boolean; AZoom, AColumns, ARows: Integer);
begin
  Inc(GridCount);
  Grid := AImage;
  GridLines := AShowGrid;
  GridZoom := AZoom;
  GridColumns := AColumns;
  GridRows := ARows;
end;

procedure TFakeFontView.ShowPreview(const AImage: TFontImage);
begin
  Inc(PreviewCount);
  Preview := AImage;
end;

procedure TFakeFontView.ShowTitle(const ATitle: string);
begin
  Title := ATitle;
end;

procedure TFakeFontView.ShowDisplay(const ADisplay: TFontEditorDisplay);
begin
  Display := ADisplay;
end;

procedure TFakeFontView.ShowState(const AState: TFontEditorState);
begin
  State := AState;
end;

procedure TFakeFontView.ShowRecentFiles(const ACaptions: TArray<string>);
begin
  RecentCaptions := ACaptions;
end;

procedure TFakeFontView.ShowFontNames(const ANames: TArray<string>);
begin
  FontNames := ANames;
end;

procedure TFakeFontView.CloseWindow;
begin
  Inc(CloseCount);
end;

{ TFakeFontDialogs }

constructor TFakeFontDialogs.Create;
begin
  inherited Create;
  Messages := TList<string>.Create;
  Confirmation := fcNo;
end;

destructor TFakeFontDialogs.Destroy;
begin
  Messages.Free;
  inherited Destroy;
end;

function TFakeFontDialogs.PickProjectToOpen(out AFileName: string): Boolean;
begin
  AFileName := OpenName;
  Result := OpenResult;
end;

function TFakeFontDialogs.PickProjectToSave(const ASuggestedName: string; out AFileName: string): Boolean;
begin
  SaveSuggested := ASuggestedName;
  AFileName := SaveName;
  Result := SaveResult;
end;

function TFakeFontDialogs.PickWadToSave(out AFileName: string): Boolean;
begin
  AFileName := WadName;
  Result := WadResult;
end;

function TFakeFontDialogs.PickImageToExport(out AFileName: string): Boolean;
begin
  AFileName := ImageName;
  Result := ImageResult;
end;

function TFakeFontDialogs.PickPaletteFile(out AFileName: string): Boolean;
begin
  AFileName := PaletteName;
  Result := PaletteResult;
end;

function TFakeFontDialogs.PickFontFile(out AFileName: string): Boolean;
begin
  AFileName := FontFileName;
  Result := FontFileResult;
end;

function TFakeFontDialogs.PickColor(var AColor: Integer): Boolean;
begin
  Result := ColorResult;
  if Result then
    AColor := ColorValue;
end;

function TFakeFontDialogs.AskSaveChanges: TFontEditorConfirmation;
begin
  Inc(ConfirmCount);
  Result := Confirmation;
end;

procedure TFakeFontDialogs.ShowMessage(const AText: string);
begin
  Messages.Add(AText);
end;

procedure TFakeFontDialogs.ShowAbout;
begin
  Inc(AboutCount);
end;

{ TFakeFontCatalog }

function TFakeFontCatalog.FontNames: TArray<string>;
begin
  Result := Names;
end;

{ TFakeFontInstaller }

constructor TFakeFontInstaller.Create;
begin
  inherited Create;
  Installed := TList<string>.Create;
end;

destructor TFakeFontInstaller.Destroy;
begin
  Installed.Free;
  inherited Destroy;
end;

function TFakeFontInstaller.Install(const AFileName: string): Boolean;
begin
  Result := not FailInstall;
  if not Result then
    Exit;
  Installed.Add(AFileName);
  if Assigned(Catalog) and (BroughtName <> '') then
    Catalog.Names := Catalog.Names + [BroughtName];
end;

procedure TFakeFontInstaller.UninstallAll;
begin
  Inc(UninstallCount);
  Installed.Clear;
end;

{ TFakeFontImageExporter }

constructor TFakeFontImageExporter.Create;
begin
  inherited Create;
  Exported := TList<string>.Create;
end;

destructor TFakeFontImageExporter.Destroy;
begin
  Exported.Free;
  inherited Destroy;
end;

function TFakeFontImageExporter.Export(const AFileName: string; const AImage: TFontImage): Boolean;
begin
  Result := not Fail;
  if Result then
  begin
    Exported.Add(AFileName);
    LastImage := AImage;
  end;
end;

end.
