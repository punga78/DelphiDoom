{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - fakes and helpers                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DelphiDoom.Nodes.Intf;

type
  /// <summary>A directory of lumps held in memory; it counts the reads of each lump</summary>
  TFakeLumpSource = class(TInterfacedObject, INodesLumpSource)
  strict private
    FNames: TList<string>;
    FData: TList<TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AData: TBytes); overload;
    procedure Add(const AName: string); overload;
    /// <summary>Adds the lumps of a WAD file (all of its directory)</summary>
    procedure AddWad(const ABytes: TBytes);
    function GetLumpCount: Integer;
    function LumpName(ALump: Integer): string;
    function LumpLength(ALump: Integer): Integer;
    function ReadLump(ALump: Integer): TBytes;
    function FindLump(const AName: string): Integer;
  end;

  /// <summary>Files of Tests\Data and the digest used by the golden files</summary>
  TNodesTestData = class sealed
  public
    class function DataDir: string; static;
    class function ReadFile(const AName: string): TBytes; static;
    /// <summary>FNV-1a 64 bit of the bytes, as 16 hex digits</summary>
    class function Fingerprint(const ABytes: TBytes): string; static;
    class function FingerprintOf(const AData; ASize: Integer): string; static;
    /// <summary>The value of a "name=value" line of a golden file</summary>
    class function Golden(const AFile, AName: string): string; static;
  end;

implementation

{ TFakeLumpSource }

constructor TFakeLumpSource.Create;
begin
  inherited Create;
  FNames := TList<string>.Create;
  FData := TList<TBytes>.Create;
end;

destructor TFakeLumpSource.Destroy;
begin
  FNames.Free;
  FData.Free;
  inherited;
end;

procedure TFakeLumpSource.Add(const AName: string; const AData: TBytes);
begin
  FNames.Add(AName);
  FData.Add(AData);
end;

procedure TFakeLumpSource.Add(const AName: string);
begin
  Add(AName, nil);
end;

procedure TFakeLumpSource.AddWad(const ABytes: TBytes);
var
  LCount: Integer;
  LOffset: Integer;
  LIndex: Integer;
  LEntry: Integer;
  LPosition: Integer;
  LSize: Integer;
  LName: string;
  LChar: Integer;
  LData: TBytes;
begin
  LCount := PInteger(@ABytes[4])^;
  LOffset := PInteger(@ABytes[8])^;
  for LIndex := 0 to LCount - 1 do
  begin
    LEntry := LOffset + LIndex * 16;
    LPosition := PInteger(@ABytes[LEntry])^;
    LSize := PInteger(@ABytes[LEntry + 4])^;
    LName := '';
    for LChar := 0 to 7 do
      if ABytes[LEntry + 8 + LChar] <> 0 then
        LName := LName + Char(ABytes[LEntry + 8 + LChar]);
    SetLength(LData, LSize);
    if LSize > 0 then
      Move(ABytes[LPosition], LData[0], LSize);
    Add(LName, LData);
  end;
end;

function TFakeLumpSource.GetLumpCount: Integer;
begin
  Result := FNames.Count;
end;

function TFakeLumpSource.LumpName(ALump: Integer): string;
begin
  if (ALump < 0) or (ALump >= FNames.Count) then
    Result := ''
  else
    Result := FNames[ALump];
end;

function TFakeLumpSource.LumpLength(ALump: Integer): Integer;
begin
  if (ALump < 0) or (ALump >= FNames.Count) then
    raise EArgumentOutOfRangeException.Create('ALump');
  Result := Length(FData[ALump]);
end;

function TFakeLumpSource.ReadLump(ALump: Integer): TBytes;
begin
  if (ALump < 0) or (ALump >= FNames.Count) then
    raise EArgumentOutOfRangeException.Create('ALump');
  Result := Copy(FData[ALump]);
end;

function TFakeLumpSource.FindLump(const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := FNames.Count - 1 downto 0 do
    if SameText(FNames[LIndex], AName) then
      Exit(LIndex);
  Result := -1;
end;

{ TNodesTestData }

class function TNodesTestData.DataDir: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\'));
end;

class function TNodesTestData.ReadFile(const AName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(TPath.Combine(DataDir, AName));
end;

class function TNodesTestData.FingerprintOf(const AData; ASize: Integer): string;
var
  LHash: UInt64;
  LIndex: Integer;
begin
  {$Q-}
  {$R-}
  LHash := UInt64($CBF29CE484222325);
  for LIndex := 0 to ASize - 1 do
    LHash := (LHash xor PByte(NativeUInt(@AData) + NativeUInt(LIndex))^) * UInt64($100000001B3);
  Result := IntToHex(LHash, 16);
end;

class function TNodesTestData.Fingerprint(const ABytes: TBytes): string;
var
  LEmpty: Byte;
begin
  LEmpty := 0;
  if Length(ABytes) = 0 then
    Result := FingerprintOf(LEmpty, 0)
  else
    Result := FingerprintOf(ABytes[0], Length(ABytes));
end;

class function TNodesTestData.Golden(const AFile, AName: string): string;
var
  LLines: TStringList;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.NameValueSeparator := '=';
    LLines.LoadFromFile(TPath.Combine(TPath.Combine(DataDir, 'Nodes'), AFile));
    LIndex := LLines.IndexOfName(AName);
    if LIndex < 0 then
      raise Exception.CreateFmt('The case "%s" is not in %s', [AName, AFile]);
    Result := LLines.ValueFromIndex[LIndex];
  finally
    LLines.Free;
  end;
end;

end.
