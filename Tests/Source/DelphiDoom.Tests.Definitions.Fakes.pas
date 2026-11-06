{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the fakes                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.Fakes;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Logging.Intf, DelphiDoom.Definitions.Intf;

type
  /// <summary>
  ///   The flats and the textures of the game as two lists of names: the number of a name is
  ///   its position (the names are compared in capitals, like the lumps)
  /// </summary>
  TFakeCatalog = class(TInterfacedObject, IDefAnimNameCatalog, IDefTextureLookup)
  private
    FFlats: TStringList;
    FTextures: TStringList;
  public
    constructor Create(const AFlats, ATextures: array of string);
    destructor Destroy; override;
    function HasFlat(const AName: string): Boolean;
    function HasTexture(const AName: string): Boolean;
    function CheckTextureNumForName(const AName: string): Integer;
    function FlatIndex(const AName: string): Integer;
    function TextureIndex(const AName: string): Integer;
    procedure SetFlats(const ANames: TArray<string>);
    procedure SetTextures(const ANames: TArray<string>);
  end;

  /// <summary>Keeps the warnings, one for each call, as they were written</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  private
    FWarnings: TStringList;
    function GetCount: Integer;
    function GetWarning(AIndex: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    function Joined: string;
    property Count: Integer read GetCount;
    property Warnings[AIndex: Integer]: string read GetWarning; default;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

function NameIndex(const ANames: TStringList; const AName: string): Integer;
begin
  Result := ANames.IndexOf(TScannerStrings.UpperAscii(AName));
end;

{ TFakeCatalog }

constructor TFakeCatalog.Create(const AFlats, ATextures: array of string);
var
  LName: string;
begin
  inherited Create;
  FFlats := TStringList.Create;
  FTextures := TStringList.Create;
  for LName in AFlats do
    FFlats.Add(TScannerStrings.UpperAscii(LName));
  for LName in ATextures do
    FTextures.Add(TScannerStrings.UpperAscii(LName));
end;

destructor TFakeCatalog.Destroy;
begin
  FFlats.Free;
  FTextures.Free;
  inherited Destroy;
end;

procedure TFakeCatalog.SetFlats(const ANames: TArray<string>);
var
  LName: string;
begin
  FFlats.Clear;
  for LName in ANames do
    FFlats.Add(TScannerStrings.UpperAscii(LName));
end;

procedure TFakeCatalog.SetTextures(const ANames: TArray<string>);
var
  LName: string;
begin
  FTextures.Clear;
  for LName in ANames do
    FTextures.Add(TScannerStrings.UpperAscii(LName));
end;

function TFakeCatalog.FlatIndex(const AName: string): Integer;
begin
  Result := NameIndex(FFlats, AName);
end;

function TFakeCatalog.TextureIndex(const AName: string): Integer;
begin
  Result := NameIndex(FTextures, AName);
end;

function TFakeCatalog.HasFlat(const AName: string): Boolean;
begin
  Result := FlatIndex(AName) >= 0;
end;

function TFakeCatalog.HasTexture(const AName: string): Boolean;
begin
  Result := TextureIndex(AName) >= 0;
end;

function TFakeCatalog.CheckTextureNumForName(const AName: string): Integer;
begin
  Result := TextureIndex(AName);
end;

{ TFakeLog }

constructor TFakeLog.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor TFakeLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

function TFakeLog.GetCount: Integer;
begin
  Result := FWarnings.Count;
end;

function TFakeLog.GetWarning(AIndex: Integer): string;
begin
  Result := FWarnings[AIndex];
end;

procedure TFakeLog.Info(const AText: string);
begin
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
end;

procedure TFakeLog.Error(const AText: string);
begin
end;

function TFakeLog.Joined: string;
var
  LText: string;
begin
  Result := '';
  for LText in FWarnings do
    Result := Result + LText;
end;

end.
