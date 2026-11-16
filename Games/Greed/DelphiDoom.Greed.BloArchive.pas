{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the archive GREED.BLO                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): CA_InitFile, CA_*NamedNum,  }
{  CA_CacheLump and CA_ReadLump of d_disk.pas                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.BloArchive;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The archive: a header of 10 bytes (fileinfo_t), the lumps, and at the end the table of the lumps
  ///   (12 bytes each, lumpinfo_t) followed by their names as strings that end with a zero. The table is read
  ///   when the archive is opened and checked: a name outside it, or a table past the end of the file, is
  ///   EGreedDataException (the original read whatever was there). The bytes of a lump are read from the file
  ///   when they are asked, not kept
  /// </summary>
  TGreedBloArchive = class(TInterfacedObject, IGreedArchive)
  strict private
    FStream: TStream;
    FOwnsStream: Boolean;
    FFixes: IGreedLumpFixes;
    FInfos: TArray<TGreedLumpInfo>;
    FNames: TArray<string>;
    FFirstIndex: TDictionary<string, Integer>;
    procedure CheckIndex(AIndex: Integer);
    class function FoldCase(const AName: string): string; static;
    function ReadBytes(AIndex: Integer): TBytes;
  public
    /// <param name="AStream">The file; the stream is owned if AOwnsStream</param>
    /// <param name="AFixes">The corrections of the data applied by ReadLump; nil for none</param>
    constructor Create(AStream: TStream; AOwnsStream: Boolean; const AFixes: IGreedLumpFixes);
    destructor Destroy; override;
    function GetLumpCount: Integer;
    function GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpSize(AIndex: Integer): Integer;
    function IndexOf(const AName: string): Integer;
    function RequireIndexOf(const AName: string): Integer;
    function ReadLump(AIndex: Integer): TBytes;
    function ReadLumpRaw(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Greed.LittleEndian;

{ TGreedBloArchive }

constructor TGreedBloArchive.Create(AStream: TStream; AOwnsStream: Boolean; const AFixes: IGreedLumpFixes);
var
  LHeader: TBytes;
  LTable: TBytes;
  LCount: Integer;
  LTableOffset: Integer;
  LTableSize: Integer;
  LStreamSize: Int64;
  LIndex: Integer;
  LOffset: Integer;
  LEnd: Integer;
  LName: string;
  LCharIndex: Integer;
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FStream := AStream;
  FOwnsStream := AOwnsStream;
  FFixes := AFixes;
  FFirstIndex := TDictionary<string, Integer>.Create;
  try
    LStreamSize := FStream.Size;
    if LStreamSize < GREED_FILEINFO_BYTES then
      raise EGreedDataException.CreateFmt(SGreedArchiveTooShort, [LStreamSize, GREED_FILEINFO_BYTES]);
    SetLength(LHeader, GREED_FILEINFO_BYTES);
    FStream.Position := 0;
    FStream.ReadBuffer(LHeader[0], GREED_FILEINFO_BYTES);
    LCount := TGreedLittleEndian.ReadSmallInt(LHeader, 0);
    LTableOffset := TGreedLittleEndian.ReadInt32(LHeader, 2);
    LTableSize := TGreedLittleEndian.ReadInt32(LHeader, 6);
    if (LCount < 0) or (LTableOffset < 0) or (LTableSize < 0) or (Int64(LCount) * GREED_LUMPINFO_BYTES > LTableSize) then
      raise EGreedDataException.CreateFmt(SGreedArchiveHeader, [LCount, LTableSize, LTableOffset]);
    if Int64(LTableOffset) + LTableSize > LStreamSize then
      raise EGreedDataException.CreateFmt(SGreedArchiveTable, [LTableSize, LTableOffset, LStreamSize]);
    SetLength(LTable, LTableSize);
    if LTableSize > 0 then
    begin
      FStream.Position := LTableOffset;
      FStream.ReadBuffer(LTable[0], LTableSize);
    end;
    SetLength(FInfos, LCount);
    SetLength(FNames, LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      FInfos[LIndex].FilePosition := TGreedLittleEndian.ReadInt32(LTable, LIndex * GREED_LUMPINFO_BYTES);
      FInfos[LIndex].Size := Cardinal(TGreedLittleEndian.ReadInt32(LTable, LIndex * GREED_LUMPINFO_BYTES + 4));
      FInfos[LIndex].NameOffset := TGreedLittleEndian.ReadSmallInt(LTable, LIndex * GREED_LUMPINFO_BYTES + 8);
      FInfos[LIndex].Compress := TGreedLittleEndian.ReadSmallInt(LTable, LIndex * GREED_LUMPINFO_BYTES + 10);
      LOffset := FInfos[LIndex].NameOffset;
      if LOffset = 0 then
        Continue;
      // the name is a C string inside the table (pOp(infotable, nameofs) of the original)
      if (LOffset < 0) or (LOffset >= LTableSize) then
        raise EGreedDataException.CreateFmt(SGreedArchiveName, [LIndex, LOffset, LTableSize]);
      LEnd := LOffset;
      while (LEnd < LTableSize) and (LTable[LEnd] <> 0) do
        Inc(LEnd);
      if LEnd >= LTableSize then
        raise EGreedDataException.CreateFmt(SGreedArchiveName, [LIndex, LOffset, LTableSize]);
      SetLength(LName, LEnd - LOffset);
      for LCharIndex := 1 to LEnd - LOffset do
        LName[LCharIndex] := Char(LTable[LOffset + LCharIndex - 1]);
      FNames[LIndex] := LName;
      // the first lump with a name is the one that a search finds
      if not FFirstIndex.ContainsKey(FoldCase(LName)) then
        FFirstIndex.Add(FoldCase(LName), LIndex);
    end;
  except
    FFirstIndex.Free;
    FFirstIndex := nil;
    if FOwnsStream then
      FStream.Free;
    FStream := nil;
    raise;
  end;
end;

destructor TGreedBloArchive.Destroy;
begin
  FFirstIndex.Free;
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;

class function TGreedBloArchive.FoldCase(const AName: string): string;
var
  LIndex: Integer;
begin
  // only the ASCII letters: the names of the lumps are bytes, not text of a language
  Result := AName;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

procedure TGreedBloArchive.CheckIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Length(FInfos)) then
    raise EGreedNotFoundException.CreateFmt(SGreedLumpInvalid, [AIndex, Length(FInfos)]);
end;

function TGreedBloArchive.GetLumpCount: Integer;
begin
  Result := Length(FInfos);
end;

function TGreedBloArchive.GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
begin
  CheckIndex(AIndex);
  Result := FInfos[AIndex];
end;

function TGreedBloArchive.GetLumpName(AIndex: Integer): string;
begin
  CheckIndex(AIndex);
  Result := FNames[AIndex];
end;

function TGreedBloArchive.GetLumpSize(AIndex: Integer): Integer;
begin
  CheckIndex(AIndex);
  Result := Integer(FInfos[AIndex].Size);
end;

function TGreedBloArchive.IndexOf(const AName: string): Integer;
begin
  if not FFirstIndex.TryGetValue(FoldCase(AName), Result) then
    Result := -1;
end;

function TGreedBloArchive.RequireIndexOf(const AName: string): Integer;
begin
  Result := IndexOf(AName);
  if Result < 0 then
    raise EGreedNotFoundException.CreateFmt(SGreedLumpNotFound, [AName]);
end;

function TGreedBloArchive.ReadBytes(AIndex: Integer): TBytes;
var
  LInfo: TGreedLumpInfo;
begin
  CheckIndex(AIndex);
  LInfo := FInfos[AIndex];
  if (LInfo.Size > Cardinal(High(Integer))) or (LInfo.FilePosition < 0) or
    (Int64(LInfo.FilePosition) + LInfo.Size > FStream.Size) then
    raise EGreedDataException.CreateFmt(SGreedLumpOutside, [AIndex, LInfo.Size, LInfo.FilePosition, FStream.Size]);
  SetLength(Result, LInfo.Size);
  if LInfo.Size > 0 then
  begin
    FStream.Position := LInfo.FilePosition;
    FStream.ReadBuffer(Result[0], LInfo.Size);
  end;
end;

function TGreedBloArchive.ReadLump(AIndex: Integer): TBytes;
begin
  Result := ReadBytes(AIndex);
  if Assigned(FFixes) then
    Result := FFixes.Apply(Result);
end;

function TGreedBloArchive.ReadLumpRaw(AIndex: Integer): TBytes;
begin
  Result := ReadBytes(AIndex);
end;

end.
