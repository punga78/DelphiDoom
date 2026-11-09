{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - archives and lumps made in memory   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Builders;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>Builds the bytes of a GREED.BLO: header, lumps, table of the lumps and names</summary>
  TGreedBlo = class
  strict private
    FNames: TArray<string>;
    FLumps: TArray<TBytes>;
    FCompress: TArray<SmallInt>;
  public
    /// <summary>Adds a lump; an empty name is a lump without a name (name offset 0)</summary>
    function Add(const AName: string; const ABytes: TBytes; ACompress: SmallInt = 0): TGreedBlo;
    /// <summary>The bytes of the archive</summary>
    function Build: TBytes;
    /// <summary>The archive opened on a memory stream that it owns</summary>
    function Open(const AFixes: IGreedLumpFixes = nil): IGreedArchive;
  end;

  /// <summary>Lumps with known contents</summary>
  TGreedLumps = class
  public
    /// <summary>768 bytes: the color i has the 6 bit values i mod 64, (i + 1) mod 64, (i + 2) mod 64</summary>
    class function Palette: TBytes; static;
    /// <summary>pic_t: width, height, origin, then the pixels AFirst, AFirst + 1, ...</summary>
    class function Picture(AWidth, AHeight, AOriginX, AOriginY: Integer; AFirst: Byte = 1): TBytes; static;
    /// <summary>A flat whose pixel i is i mod 251 + 1</summary>
    class function Flat: TBytes; static;
    /// <summary>A wall of height AHeight4 * 4; the byte of the column x and the row y is x + y + 1</summary>
    class function Wall(AHeight4: Integer): TBytes; static;
    /// <summary>
    ///   A sprite with 3 columns: the first has the pixels 1, 2, 3 from the height 5 to 2, the second is empty,
    ///   the third has the pixel 9 from the height 2 to 1. Left offset 7
    /// </summary>
    class function Sprite: TBytes; static;
    /// <summary>The planes of a map: the byte i of the plane p is (p * 16 + i) mod 256, then ATrailer</summary>
    class function MapBytes(const ATrailer: TBytes): TBytes; static;
    class function Bytes(const AValues: array of Byte): TBytes; static;
    /// <summary>The CRC32 as 8 lower case hex digits; 00000000 for no bytes (as the golden files have it)</summary>
    class function CrcHex(const ABytes: TBytes): string; static;
    /// <summary>A little endian word</summary>
    class procedure PutWord(var ABytes: TBytes; AOffset: Integer; AValue: Integer); static;
  end;

  /// <summary>
  ///   An archive like the ones of the game: palette, "map" with 2 maps (one in the archive, one empty with the
  ///   name of a file), the groups of flats, walls and sprites, and one picture
  /// </summary>
  TGreedTestArchive = class
  public
    const
      LUMP_PALETTE = 0;
      LUMP_MAP = 1;
      LUMP_MAP0 = 2;
      LUMP_MAP1 = 3;
      LUMP_START_FLATS = 4;
      LUMP_FLAT1 = 5;
      LUMP_FLAT2 = 6;
      LUMP_END_FLATS = 7;
      LUMP_START_WALLS = 8;
      LUMP_WALL1 = 9;
      LUMP_WALL2 = 10;
      LUMP_END_WALLS = 11;
      LUMP_START_SPRITES = 12;
      LUMP_SPRITE1 = 13;
      LUMP_END_SPRITES = 14;
      LUMP_PICTURE = 15;
      LUMP_FONT = 16;
      LUMP_UNNAMED = 17;
      LUMP_COUNT = 18;
    /// <summary>The bytes of the archive</summary>
    class function Bytes: TBytes; static;
    /// <summary>The archive, opened on a memory stream that it owns</summary>
    class function Open(const AFixes: IGreedLumpFixes = nil): IGreedArchive; static;
    /// <summary>The lump of the first map, as the archive has it</summary>
    class function Map0: TBytes; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32, DelphiDoom.Greed.Factory;

{ TGreedBlo }

function TGreedBlo.Add(const AName: string; const ABytes: TBytes; ACompress: SmallInt): TGreedBlo;
begin
  SetLength(FNames, Length(FNames) + 1);
  SetLength(FLumps, Length(FLumps) + 1);
  SetLength(FCompress, Length(FCompress) + 1);
  FNames[High(FNames)] := AName;
  FLumps[High(FLumps)] := ABytes;
  FCompress[High(FCompress)] := ACompress;
  Result := Self;
end;

function TGreedBlo.Build: TBytes;
var
  LCount: Integer;
  LDataSize: Integer;
  LTableSize: Integer;
  LNamesSize: Integer;
  LIndex: Integer;
  LPosition: Integer;
  LNameOffset: Integer;
  LEntry: Integer;
  LName: AnsiString;
begin
  LCount := Length(FLumps);
  LDataSize := 0;
  LNamesSize := 0;
  for LIndex := 0 to LCount - 1 do
  begin
    Inc(LDataSize, Length(FLumps[LIndex]));
    if FNames[LIndex] <> '' then
      Inc(LNamesSize, Length(FNames[LIndex]) + 1);
  end;
  LTableSize := LCount * GREED_LUMPINFO_BYTES + LNamesSize;
  SetLength(Result, GREED_FILEINFO_BYTES + LDataSize + LTableSize);
  FillChar(Result[0], Length(Result), 0);
  TGreedLumps.PutWord(Result, 0, LCount);
  PInteger(@Result[2])^ := GREED_FILEINFO_BYTES + LDataSize;
  PInteger(@Result[6])^ := LTableSize;
  LPosition := GREED_FILEINFO_BYTES;
  LNameOffset := LCount * GREED_LUMPINFO_BYTES;
  for LIndex := 0 to LCount - 1 do
  begin
    LEntry := GREED_FILEINFO_BYTES + LDataSize + LIndex * GREED_LUMPINFO_BYTES;
    PInteger(@Result[LEntry])^ := LPosition;
    PInteger(@Result[LEntry + 4])^ := Length(FLumps[LIndex]);
    if FNames[LIndex] <> '' then
    begin
      TGreedLumps.PutWord(Result, LEntry + 8, LNameOffset);
      LName := AnsiString(FNames[LIndex]);
      Move(LName[1], Result[GREED_FILEINFO_BYTES + LDataSize + LNameOffset], Length(LName));
      Inc(LNameOffset, Length(LName) + 1);
    end;
    TGreedLumps.PutWord(Result, LEntry + 10, FCompress[LIndex]);
    if Length(FLumps[LIndex]) > 0 then
      Move(FLumps[LIndex][0], Result[LPosition], Length(FLumps[LIndex]));
    Inc(LPosition, Length(FLumps[LIndex]));
  end;
end;

function TGreedBlo.Open(const AFixes: IGreedLumpFixes): IGreedArchive;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create(Build);
  try
    Result := TGreedFactory.OpenArchive(LStream, True, AFixes);
  except
    LStream.Free;
    raise;
  end;
end;

{ TGreedLumps }

class function TGreedLumps.CrcHex(const ABytes: TBytes): string;
begin
  if Length(ABytes) = 0 then
    Exit('00000000');
  Result := TCrc32.ToHex(TCrc32.Calculate(ABytes[0], Length(ABytes)));
end;

class function TGreedLumps.Bytes(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

class procedure TGreedLumps.PutWord(var ABytes: TBytes; AOffset: Integer; AValue: Integer);
begin
  ABytes[AOffset] := Byte(AValue);
  ABytes[AOffset + 1] := Byte(AValue shr 8);
end;

class function TGreedLumps.Palette: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, GREED_PALETTE_BYTES);
  for LIndex := 0 to 255 do
  begin
    Result[LIndex * 3] := Byte(LIndex mod 64);
    Result[LIndex * 3 + 1] := Byte((LIndex + 1) mod 64);
    Result[LIndex * 3 + 2] := Byte((LIndex + 2) mod 64);
  end;
end;

class function TGreedLumps.Picture(AWidth, AHeight, AOriginX, AOriginY: Integer; AFirst: Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, GREED_PICTURE_HEADER_BYTES + AWidth * AHeight);
  PutWord(Result, 0, AWidth);
  PutWord(Result, 2, AHeight);
  PutWord(Result, 4, AOriginX);
  PutWord(Result, 6, AOriginY);
  for LIndex := 0 to AWidth * AHeight - 1 do
    Result[GREED_PICTURE_HEADER_BYTES + LIndex] := Byte(AFirst + LIndex);
end;

class function TGreedLumps.Flat: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, GREED_FLAT_BYTES);
  for LIndex := 0 to GREED_FLAT_BYTES - 1 do
    Result[LIndex] := Byte(LIndex mod 251 + 1);
end;

class function TGreedLumps.Wall(AHeight4: Integer): TBytes;
var
  LHeight: Integer;
  LX: Integer;
  LY: Integer;
begin
  LHeight := AHeight4 * 4;
  SetLength(Result, GREED_WALL_HEADER_BYTES + GREED_WALL_WIDTH * LHeight);
  FillChar(Result[0], Length(Result), 0);
  Result[0] := Byte(AHeight4);
  for LX := 0 to GREED_WALL_WIDTH - 1 do
    for LY := 0 to LHeight - 1 do
      Result[GREED_WALL_HEADER_BYTES + LHeight * LX + LY] := Byte(LX + LY + 1);
end;

class function TGreedLumps.Sprite: TBytes;
begin
  // left offset 7, width 3; columns at 10 and 15 (the second is 0); post 1: top 5, bottom 2, pixels 1 2 3;
  // post 3: top 2, bottom 1, pixel 9
  Result := Bytes([7, 0, 3, 0,  10, 0,  0, 0,  15, 0,  5, 2, 1, 2, 3,  2, 1, 9]);
end;

class function TGreedLumps.MapBytes(const ATrailer: TBytes): TBytes;
var
  LPlane: Integer;
  LIndex: Integer;
begin
  SetLength(Result, GREED_MAP_BYTES + Length(ATrailer));
  for LPlane := 0 to GREED_MAP_PLANES - 1 do
    for LIndex := 0 to GREED_MAP_TILES - 1 do
      Result[LPlane * GREED_MAP_TILES + LIndex] := Byte(LPlane * 16 + LIndex);
  if Length(ATrailer) > 0 then
    Move(ATrailer[0], Result[GREED_MAP_BYTES], Length(ATrailer));
end;

{ TGreedTestArchive }

class function TGreedTestArchive.Map0: TBytes;
begin
  Result := TGreedLumps.MapBytes(TGreedLumps.Bytes([65, 66, 67]));
end;

function BuildTestBlo: TGreedBlo;
begin
  Result := TGreedBlo.Create;
  Result.Add('palette', TGreedLumps.Palette)
    .Add('map', nil)
    .Add('level1.lay', TGreedTestArchive.Map0)
    .Add('level2.lay', nil)
    .Add('startflats', nil)
    .Add('floor1', TGreedLumps.Flat)
    .Add('floor2', TGreedLumps.Flat)
    .Add('endflats', nil)
    .Add('startwalls', nil)
    .Add('wall1', TGreedLumps.Wall(2))
    .Add('wall2', TGreedLumps.Wall(16))
    .Add('endwalls', nil)
    .Add('startsprites', nil)
    .Add('sprite1', TGreedLumps.Sprite)
    .Add('endsprites', nil)
    .Add('menu', TGreedLumps.Picture(3, 2, 1, 1))
    .Add('font1', TGreedLumps.Bytes([1, 2, 3]))
    .Add('', TGreedLumps.Bytes([9, 9]));
end;

class function TGreedTestArchive.Bytes: TBytes;
var
  LBlo: TGreedBlo;
begin
  LBlo := BuildTestBlo;
  try
    Result := LBlo.Build;
  finally
    LBlo.Free;
  end;
end;

class function TGreedTestArchive.Open(const AFixes: IGreedLumpFixes): IGreedArchive;
var
  LBlo: TGreedBlo;
begin
  LBlo := BuildTestBlo;
  try
    Result := LBlo.Open(AFixes);
  finally
    LBlo.Free;
  end;
end;

end.
