{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the maps of KDREAMS.MAP                           }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CAL_SetupMapFile and CA_CacheMap of id_ca.c                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.MapSource;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   MAPHEAD gives the RLEW tag, where each map header is and the tile info; the header of a map and every
  ///   plane are Huffman data. A plane is a 16 bit number (the length of what the Huffman data give),
  ///   the Huffman data, that give a 16 bit number (the size of the plane) and the RLEW data of the plane
  /// </summary>
  /// <remarks>
  ///   Difference from the C: the size of a plane (Width * Height * 2) is an unsigned 16 bit number there
  ///   and wraps; here a map whose plane has more than 65535 bytes is refused
  /// </remarks>
  TKeenMapSource = class(TInterfacedObject, IKeenMapSource)
  strict private
    FHeader: TKeenMapFileHeader;
    FTileInfo: IKeenTileInfo;
    FHuffman: IKeenHuffman;
    FRlew: IKeenRlew;
    FStream: TStream;
    function ReadAt(APosition, ALength: Integer): TBytes;
    function ParseHeader(const ABytes: TBytes): TKeenMapHeader;
    function LoadPlane(AMapNumber, APlane: Integer; const AHeader: TKeenMapHeader): TArray<Word>;
  public
    /// <param name="AMapHeader">The bytes of MAPHEAD</param>
    /// <param name="AStream">KDREAMS.MAP; the source owns it and frees it</param>
    constructor Create(const AMapHeader: TBytes; const AHuffman: IKeenHuffman;
      const ARlew: IKeenRlew; AStream: TStream);
    destructor Destroy; override;
    function GetRlewTag: Word;
    function GetTileInfo: IKeenTileInfo;
    function HasMap(AIndex: Integer): Boolean;
    function MapNumbers: TArray<Integer>;
    function LoadMap(AIndex: Integer): IKeenMap;
  end;

implementation

uses
  DelphiDoom.Keen.LittleEndian, DelphiDoom.Keen.TileInfo, DelphiDoom.Keen.Map;

{ TKeenMapSource }

constructor TKeenMapSource.Create(const AMapHeader: TBytes; const AHuffman: IKeenHuffman;
  const ARlew: IKeenRlew; AStream: TStream);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AHuffman) then
    raise EArgumentNilException.Create('AHuffman');
  if not Assigned(ARlew) then
    raise EArgumentNilException.Create('ARlew');
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FHuffman := AHuffman;
  FRlew := ARlew;
  FStream := AStream;
  if Length(AMapHeader) < KEEN_MAPHEAD_PREFIX + KEEN_TINF_SIZE then
    raise EKeenDataException.CreateFmt(SKeenHeaderInvalid,
      ['MAPHEAD', Length(AMapHeader), KEEN_MAPHEAD_PREFIX + KEEN_TINF_SIZE]);
  FHeader.RlewTag := TKeenLittleEndian.ReadWord(AMapHeader, 0);
  for LIndex := 0 to KEEN_MAP_SLOTS - 1 do
  begin
    FHeader.HeaderOffsets[LIndex] := TKeenLittleEndian.ReadInt32(AMapHeader, 2 + LIndex * 4);
    FHeader.HeaderSizes[LIndex] := AMapHeader[2 + KEEN_MAP_SLOTS * 4 + LIndex];
  end;
  FTileInfo := TKeenTileInfo.Create(Copy(AMapHeader, KEEN_MAPHEAD_PREFIX, KEEN_TINF_SIZE));
end;

destructor TKeenMapSource.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

function TKeenMapSource.GetRlewTag: Word;
begin
  Result := FHeader.RlewTag;
end;

function TKeenMapSource.GetTileInfo: IKeenTileInfo;
begin
  Result := FTileInfo;
end;

function TKeenMapSource.HasMap(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < KEEN_MAP_SLOTS) and
    (FHeader.HeaderOffsets[AIndex] > 0);
end;

function TKeenMapSource.MapNumbers: TArray<Integer>;
var
  LIndex: Integer;
  LCount: Integer;
begin
  SetLength(Result, KEEN_MAP_SLOTS);
  LCount := 0;
  for LIndex := 0 to KEEN_MAP_SLOTS - 1 do
    if HasMap(LIndex) then
    begin
      Result[LCount] := LIndex;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

function TKeenMapSource.ReadAt(APosition, ALength: Integer): TBytes;
begin
  if (APosition < 0) or (ALength < 0) or (Int64(APosition) + ALength > FStream.Size) then
    raise EKeenDataException.CreateFmt(SKeenReadPastEnd, [ALength, APosition, Integer(FStream.Size)]);
  SetLength(Result, ALength);
  if ALength > 0 then
  begin
    FStream.Position := APosition;
    FStream.ReadBuffer(Result[0], ALength);
  end;
end;

function TKeenMapSource.ParseHeader(const ABytes: TBytes): TKeenMapHeader;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    Result.PlaneStart[LIndex] := TKeenLittleEndian.ReadInt32(ABytes, LIndex * 4);
    Result.PlaneLength[LIndex] := TKeenLittleEndian.ReadWord(ABytes, 12 + LIndex * 2);
  end;
  Result.Width := TKeenLittleEndian.ReadWord(ABytes, 18);
  Result.Height := TKeenLittleEndian.ReadWord(ABytes, 20);
  for LIndex := 0 to 15 do
    Result.Name[LIndex] := AnsiChar(ABytes[22 + LIndex]);
end;

function TKeenMapSource.LoadPlane(AMapNumber, APlane: Integer;
  const AHeader: TKeenMapHeader): TArray<Word>;
var
  LCompressed: TBytes;
  LHuffmanLength: Integer;
  LExpanded: TBytes;
  LSize: Integer;
  LRle: TBytes;
  LIndex: Integer;
begin
  LSize := Integer(AHeader.Width) * Integer(AHeader.Height) * 2;
  LCompressed := ReadAt(AHeader.PlaneStart[APlane], AHeader.PlaneLength[APlane]);
  if Length(LCompressed) < 2 then
    raise EKeenDataException.CreateFmt(SKeenMapBadPlane, [APlane, AMapNumber, 'no length']);
  // unhuffman: the plane starts with a word, the length of what the Huffman data give
  LHuffmanLength := TKeenLittleEndian.ReadWord(LCompressed, 0);
  LExpanded := FHuffman.Expand(LCompressed, 2, LHuffmanLength);
  // unRLEW: skip the word with the expanded length that the RLEW data have first (the C does not use it)
  LRle := FRlew.Expand(LExpanded, 2, LSize, FHeader.RlewTag);
  SetLength(Result, LSize div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := TKeenLittleEndian.ReadWord(LRle, LIndex * 2);
end;

function TKeenMapSource.LoadMap(AIndex: Integer): IKeenMap;
var
  LHeaderBytes: TBytes;
  LHeader: TKeenMapHeader;
  LPlanes: array[0..2] of TArray<Word>;
  LPlane: Integer;
begin
  if not HasMap(AIndex) then
    raise EKeenDataException.CreateFmt(SKeenMapInvalid, [AIndex]);
  LHeaderBytes := FHuffman.Expand(
    ReadAt(FHeader.HeaderOffsets[AIndex], FHeader.HeaderSizes[AIndex]), 0, SizeOf(TKeenMapHeader));
  LHeader := ParseHeader(LHeaderBytes);
  if (LHeader.Width = 0) or (LHeader.Height = 0) or
    (Integer(LHeader.Width) * Integer(LHeader.Height) * 2 > $FFFF) then
    raise EKeenDataException.CreateFmt(SKeenMapBadHeader, [AIndex, LHeader.Width, LHeader.Height]);
  for LPlane := 0 to 2 do
    LPlanes[LPlane] := LoadPlane(AIndex, LPlane, LHeader);
  Result := TKeenMap.Create(AIndex, LHeader, LPlanes);
end;

end.
