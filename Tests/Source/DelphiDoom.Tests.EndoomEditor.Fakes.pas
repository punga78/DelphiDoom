{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the endoom editor - the fakes                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EndoomEditor.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.EndoomEditor.Types,
  DelphiDoom.EndoomEditor.Intf;

type
  /// <summary>A window that remembers what it was told</summary>
  TFakeEditorView = class(TInterfacedObject, IEndoomEditorView)
  public
    PictureCount: Integer;
    Pixels: TArray<Cardinal>;
    Overlay: TEndoomEditorOverlay;
    Title: string;
    Status: string;
    State: TEndoomEditorState;
    RecentCaptions: TArray<string>;
    Tool: TEndoomEditorTool;
    Foreground: Integer;
    Background: Integer;
    Special1: Integer;
    Special2: Integer;
    CloseCount: Integer;
    procedure ShowPicture(const APixels: TArray<Cardinal>; const AOverlay: TEndoomEditorOverlay);
    procedure ShowTitle(const ATitle: string);
    procedure ShowStatus(const AText: string);
    procedure ShowState(const AState: TEndoomEditorState);
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    procedure ShowChoices(ATool: TEndoomEditorTool; AForeground, ABackground, ASpecial1, ASpecial2: Integer);
    procedure CloseWindow;
  end;

  /// <summary>Dialogs that answer what the test says</summary>
  TFakeEditorDialogs = class(TInterfacedObject, IEndoomEditorDialogs)
  public
    OpenName: string;
    OpenResult: Boolean;
    SaveName: string;
    SaveResult: Boolean;
    SaveSuggested: string;
    ExportName: string;
    ExportResult: Boolean;
    MethodResult: Boolean;
    MethodKind: TEndoomTextArtKind;
    Confirmation: TEndoomConfirmation;
    ConfirmCount: Integer;
    AboutCount: Integer;
    Messages: TList<string>;
    constructor Create;
    destructor Destroy; override;
    function PickFileToOpen(out AFileName: string): Boolean;
    function PickFileToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickImageToExport(out AFileName: string): Boolean;
    function PickTextArtMethod(var AKind: TEndoomTextArtKind): Boolean;
    function AskSaveChanges: TEndoomConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

  TFakeEditorClipboard = class(TInterfacedObject, IEndoomEditorClipboard)
  public
    Text: string;
    ImagePixels: TArray<Cardinal>;
    ImageWidth: Integer;
    ImageHeight: Integer;
    SetImageCount: Integer;
    function HasText: Boolean;
    function HasImage: Boolean;
    function GetText: string;
    function TryGetImage(out APixels: TArray<Cardinal>; out AWidth, AHeight: Integer): Boolean;
    procedure SetImage(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
  end;

  TFakeEditorExporter = class(TInterfacedObject, IEndoomEditorImageExporter)
  public
    Succeeds: Boolean;
    Calls: Integer;
    FileName: string;
    Pixels: TArray<Cardinal>;
    Width: Integer;
    Height: Integer;
    constructor Create;
    function Export(const AFileName: string; const APixels: TArray<Cardinal>; AWidth, AHeight: Integer): Boolean;
  end;

  /// <summary>A resampler that gives a fixed picture (160x50) whatever it gets</summary>
  TFakeEditorResampler = class(TInterfacedObject, IImagingResampler)
  public
    Fill: Cardinal;
    Calls: Integer;
    function Resample(const ASource: TArray<Cardinal>; ASourceWidth, ASourceHeight,
      ADestinationWidth, ADestinationHeight: Integer): TArray<Cardinal>;
  end;

implementation

{ TFakeEditorView }

procedure TFakeEditorView.ShowPicture(const APixels: TArray<Cardinal>; const AOverlay: TEndoomEditorOverlay);
begin
  Inc(PictureCount);
  Pixels := APixels;
  Overlay := AOverlay;
end;

procedure TFakeEditorView.ShowTitle(const ATitle: string);
begin
  Title := ATitle;
end;

procedure TFakeEditorView.ShowStatus(const AText: string);
begin
  Status := AText;
end;

procedure TFakeEditorView.ShowState(const AState: TEndoomEditorState);
begin
  State := AState;
end;

procedure TFakeEditorView.ShowRecentFiles(const ACaptions: TArray<string>);
begin
  RecentCaptions := ACaptions;
end;

procedure TFakeEditorView.ShowChoices(ATool: TEndoomEditorTool; AForeground, ABackground, ASpecial1,
  ASpecial2: Integer);
begin
  Tool := ATool;
  Foreground := AForeground;
  Background := ABackground;
  Special1 := ASpecial1;
  Special2 := ASpecial2;
end;

procedure TFakeEditorView.CloseWindow;
begin
  Inc(CloseCount);
end;

{ TFakeEditorDialogs }

constructor TFakeEditorDialogs.Create;
begin
  inherited Create;
  Messages := TList<string>.Create;
  Confirmation := ecNo;
end;

destructor TFakeEditorDialogs.Destroy;
begin
  Messages.Free;
  inherited Destroy;
end;

function TFakeEditorDialogs.PickFileToOpen(out AFileName: string): Boolean;
begin
  AFileName := OpenName;
  Result := OpenResult;
end;

function TFakeEditorDialogs.PickFileToSave(const ASuggestedName: string; out AFileName: string): Boolean;
begin
  SaveSuggested := ASuggestedName;
  AFileName := SaveName;
  Result := SaveResult;
end;

function TFakeEditorDialogs.PickImageToExport(out AFileName: string): Boolean;
begin
  AFileName := ExportName;
  Result := ExportResult;
end;

function TFakeEditorDialogs.PickTextArtMethod(var AKind: TEndoomTextArtKind): Boolean;
begin
  Result := MethodResult;
  if Result then
    AKind := MethodKind;
end;

function TFakeEditorDialogs.AskSaveChanges: TEndoomConfirmation;
begin
  Inc(ConfirmCount);
  Result := Confirmation;
end;

procedure TFakeEditorDialogs.ShowMessage(const AText: string);
begin
  Messages.Add(AText);
end;

procedure TFakeEditorDialogs.ShowAbout;
begin
  Inc(AboutCount);
end;

{ TFakeEditorClipboard }

function TFakeEditorClipboard.HasText: Boolean;
begin
  Result := Text <> '';
end;

function TFakeEditorClipboard.HasImage: Boolean;
begin
  Result := Length(ImagePixels) > 0;
end;

function TFakeEditorClipboard.GetText: string;
begin
  Result := Text;
end;

function TFakeEditorClipboard.TryGetImage(out APixels: TArray<Cardinal>; out AWidth, AHeight: Integer): Boolean;
begin
  Result := Length(ImagePixels) > 0;
  APixels := ImagePixels;
  AWidth := ImageWidth;
  AHeight := ImageHeight;
end;

procedure TFakeEditorClipboard.SetImage(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
begin
  Inc(SetImageCount);
  ImagePixels := APixels;
  ImageWidth := AWidth;
  ImageHeight := AHeight;
end;

{ TFakeEditorExporter }

constructor TFakeEditorExporter.Create;
begin
  inherited Create;
  Succeeds := True;
end;

function TFakeEditorExporter.Export(const AFileName: string; const APixels: TArray<Cardinal>; AWidth,
  AHeight: Integer): Boolean;
begin
  Inc(Calls);
  FileName := AFileName;
  Pixels := APixels;
  Width := AWidth;
  Height := AHeight;
  Result := Succeeds;
end;

{ TFakeEditorResampler }

function TFakeEditorResampler.Resample(const ASource: TArray<Cardinal>; ASourceWidth, ASourceHeight,
  ADestinationWidth, ADestinationHeight: Integer): TArray<Cardinal>;
var
  LIndex: Integer;
begin
  Inc(Calls);
  SetLength(Result, ADestinationWidth * ADestinationHeight);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Fill;
end;

end.
