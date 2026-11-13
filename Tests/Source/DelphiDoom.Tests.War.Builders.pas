{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - archives made in memory              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Builders;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Intf;

type
  /// <summary>A fake of the file: the bytes in memory and a count of the reads</summary>
  TWarBytesSource = class(TInterfacedObject, IWarSource)
  strict private
    FBytes: TBytes;
    FReads: Integer;
  public
    constructor Create(const ABytes: TBytes);
    function GetSize: Int64;
    procedure ReadAt(AOffset: Int64; var ABuffer; ACount: Integer);
    property Reads: Integer read FReads;
  end;

  /// <summary>Writes the compressed data of a record item by item (the inverse of the decompression)</summary>
  TWarTokenWriter = class
  strict private
    FBytes: TBytes;
    FItemCount: Integer;
    FMaskIndex: Integer;
    procedure BeginItem;
  public
    /// <summary>An uncompressed byte (mask bit 1)</summary>
    procedure Literal(AValue: Byte);
    /// <summary>A copy of ACount (3..18) bytes from AWindowPosition (0..4095) of the window</summary>
    procedure Copy(AWindowPosition, ACount: Integer);
    function ToBytes: TBytes;
  end;

  /// <summary>Lays out an archive: the header, the table of the offsets and the records</summary>
  TWarArchiveBuilder = class
  strict private
    FRecords: TList<TBytes>;
    FOffsetOverrides: TDictionary<Integer, Cardinal>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A record: the 4 byte field and then the payload; the index it gets</summary>
    function AddRaw(ALengthField: Cardinal; const APayload: TBytes): Integer;
    /// <summary>A record that is not compressed</summary>
    function AddUncompressed(const AData: TBytes): Integer;
    /// <summary>A record that is compressed to APayload and AExpandedLength bytes long</summary>
    function AddCompressed(const APayload: TBytes; AExpandedLength: Cardinal): Integer;
    /// <summary>An entry of the table with no data (the offset is AValue)</summary>
    function AddPlaceholder(AValue: Cardinal): Integer;
    /// <summary>The offset of the table of the record AIndex is AValue, wherever it is</summary>
    procedure OverrideOffset(AIndex: Integer; AValue: Cardinal);
    function Build(AArchiveId: Cardinal): TBytes;
  end;

/// <summary>The bytes of a string of ASCII characters</summary>
function WarBytesOf(const AText: AnsiString): TBytes;

implementation

function WarBytesOf(const AText: AnsiString): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AText));
  for LIndex := 1 to Length(AText) do
    Result[LIndex - 1] := Byte(AText[LIndex]);
end;

procedure PutCardinal(var ABytes: TBytes; AOffset: Integer; AValue: Cardinal);
begin
  ABytes[AOffset] := Byte(AValue);
  ABytes[AOffset + 1] := Byte(AValue shr 8);
  ABytes[AOffset + 2] := Byte(AValue shr 16);
  ABytes[AOffset + 3] := Byte(AValue shr 24);
end;

{ TWarBytesSource }

constructor TWarBytesSource.Create(const ABytes: TBytes);
begin
  inherited Create;
  FBytes := ABytes;
end;

function TWarBytesSource.GetSize: Int64;
begin
  Result := Length(FBytes);
end;

procedure TWarBytesSource.ReadAt(AOffset: Int64; var ABuffer; ACount: Integer);
begin
  Inc(FReads);
  if (AOffset < 0) or (AOffset + ACount > Length(FBytes)) then
    raise EWarException.CreateFmt(SWarReadPastEnd, [ACount, AOffset, Length(FBytes)]);
  if ACount > 0 then
    Move(FBytes[AOffset], ABuffer, ACount);
end;

{ TWarTokenWriter }

procedure TWarTokenWriter.BeginItem;
begin
  if FItemCount mod 8 = 0 then
  begin
    SetLength(FBytes, Length(FBytes) + 1);
    FMaskIndex := Length(FBytes) - 1;
  end;
end;

procedure TWarTokenWriter.Literal(AValue: Byte);
begin
  BeginItem;
  FBytes[FMaskIndex] := FBytes[FMaskIndex] or Byte(1 shl (FItemCount mod 8));
  SetLength(FBytes, Length(FBytes) + 1);
  FBytes[High(FBytes)] := AValue;
  Inc(FItemCount);
end;

procedure TWarTokenWriter.Copy(AWindowPosition, ACount: Integer);
var
  LValue: Word;
begin
  BeginItem;
  LValue := Word(((ACount - 3) shl 12) or AWindowPosition);
  SetLength(FBytes, Length(FBytes) + 2);
  FBytes[High(FBytes) - 1] := Byte(LValue);
  FBytes[High(FBytes)] := Byte(LValue shr 8);
  Inc(FItemCount);
end;

function TWarTokenWriter.ToBytes: TBytes;
begin
  Result := System.Copy(FBytes, 0, Length(FBytes));
end;

{ TWarArchiveBuilder }

constructor TWarArchiveBuilder.Create;
begin
  inherited Create;
  FRecords := TList<TBytes>.Create;
  FOffsetOverrides := TDictionary<Integer, Cardinal>.Create;
end;

destructor TWarArchiveBuilder.Destroy;
begin
  FOffsetOverrides.Free;
  FRecords.Free;
  inherited Destroy;
end;

function TWarArchiveBuilder.AddRaw(ALengthField: Cardinal; const APayload: TBytes): Integer;
var
  LRecord: TBytes;
begin
  SetLength(LRecord, 4 + Length(APayload));
  PutCardinal(LRecord, 0, ALengthField);
  if Length(APayload) > 0 then
    Move(APayload[0], LRecord[4], Length(APayload));
  Result := FRecords.Add(LRecord);
end;

function TWarArchiveBuilder.AddUncompressed(const AData: TBytes): Integer;
begin
  Result := AddRaw(Cardinal(Length(AData)), AData);
end;

function TWarArchiveBuilder.AddCompressed(const APayload: TBytes; AExpandedLength: Cardinal): Integer;
begin
  Result := AddRaw(AExpandedLength or $20000000, APayload);
end;

function TWarArchiveBuilder.AddPlaceholder(AValue: Cardinal): Integer;
begin
  Result := FRecords.Add(nil);
  FOffsetOverrides.Add(Result, AValue);
end;

procedure TWarArchiveBuilder.OverrideOffset(AIndex: Integer; AValue: Cardinal);
begin
  FOffsetOverrides.AddOrSetValue(AIndex, AValue);
end;

function TWarArchiveBuilder.Build(AArchiveId: Cardinal): TBytes;
var
  LIndex: Integer;
  LPosition: Integer;
  LTableSize: Integer;
  LValue: Cardinal;
  LRecord: TBytes;
begin
  LTableSize := FRecords.Count * 4;
  LPosition := 8 + LTableSize;
  for LIndex := 0 to FRecords.Count - 1 do
    Inc(LPosition, Length(FRecords[LIndex]));
  SetLength(Result, LPosition);
  PutCardinal(Result, 0, AArchiveId);
  PutCardinal(Result, 4, Cardinal(FRecords.Count));
  LPosition := 8 + LTableSize;
  for LIndex := 0 to FRecords.Count - 1 do
  begin
    LRecord := FRecords[LIndex];
    if not FOffsetOverrides.TryGetValue(LIndex, LValue) then
      LValue := Cardinal(LPosition);
    PutCardinal(Result, 8 + LIndex * 4, LValue);
    if Length(LRecord) > 0 then
      Move(LRecord[0], Result[LPosition], Length(LRecord));
    Inc(LPosition, Length(LRecord));
  end;
end;

end.
