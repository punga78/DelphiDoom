{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the graphics by kind: tables, pictures, tiles     }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CAL_SetupGrFile and the chunk numbers of graphkdr.h                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Graphics;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Gives a name to the chunks of the graphics file: the three tables (pictures, masked pictures, sprites)
  ///   that CA_Startup expands at once, the pictures, the sprites (without the shifted copies that
  ///   CAL_CacheSprite makes: those are for the drawing) and the tiles. Everything is planar EGA data
  /// </summary>
  /// <remarks>
  ///   Difference from the C: CA_Startup expands the masked picture table with the size of the picture
  ///   table (NUMPICS * 4 bytes in a buffer of NUMPICM * 4); here every table has the length that its
  ///   chunk says
  /// </remarks>
  TKeenGraphics = class(TInterfacedObject, IKeenGraphics)
  strict private
    FChunks: IKeenChunkSource;
    FPictures: TArray<TKeenPictureEntry>;
    FMaskedPictures: TArray<TKeenPictureEntry>;
    FSprites: TArray<TKeenSpriteEntry>;
    FTile8: TBytes;
    FTile8Masked: TBytes;
    function ReadPictureTable(AChunk: Integer): TArray<TKeenPictureEntry>;
    function ReadTile(AFirstChunk, ACount, AIndex: Integer): TBytes;
    function ReadPicture(AIndex, AFirstChunk, ACount, APlanes: Integer;
      const ATable: TArray<TKeenPictureEntry>): TBytes;
    function Slice(const ASource: TBytes; AIndex, ABlock, ACount: Integer): TBytes;
  public
    constructor Create(const AChunks: IKeenChunkSource);
    function GetChunks: IKeenChunkSource;
    function GetPictureTable: TArray<TKeenPictureEntry>;
    function GetMaskedPictureTable: TArray<TKeenPictureEntry>;
    function GetSpriteTable: TArray<TKeenSpriteEntry>;
    function PicturePlanar(AIndex: Integer): TBytes;
    function MaskedPicturePlanar(AIndex: Integer): TBytes;
    function SpritePlanar(AIndex: Integer): TBytes;
    function Tile8(AIndex: Integer): TBytes;
    function Tile8Masked(AIndex: Integer): TBytes;
    function Tile16(AIndex: Integer): TBytes;
    function Tile16Masked(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.LittleEndian;

{ TKeenGraphics }

constructor TKeenGraphics.Create(const AChunks: IKeenChunkSource);
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AChunks) then
    raise EArgumentNilException.Create('AChunks');
  FChunks := AChunks;
  if AChunks.ChunkCount < KEEN_STARTTILE32 then
    raise EKeenDataException.CreateFmt(SKeenChunkInvalid, [KEEN_STARTTILE32 - 1, AChunks.ChunkCount]);
  FPictures := ReadPictureTable(KEEN_STRUCTPIC);
  FMaskedPictures := ReadPictureTable(KEEN_STRUCTPICM);
  LBytes := AChunks.Read(KEEN_STRUCTSPRITE);
  SetLength(FSprites, Length(LBytes) div SizeOf(TKeenSpriteEntry));
  for LIndex := 0 to High(FSprites) do
  begin
    FSprites[LIndex].Width := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18);
    FSprites[LIndex].Height := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 2);
    FSprites[LIndex].OriginX := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 4);
    FSprites[LIndex].OriginY := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 6);
    FSprites[LIndex].XL := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 8);
    FSprites[LIndex].YL := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 10);
    FSprites[LIndex].XH := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 12);
    FSprites[LIndex].YH := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 14);
    FSprites[LIndex].Shifts := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 18 + 16);
  end;
end;

function TKeenGraphics.ReadPictureTable(AChunk: Integer): TArray<TKeenPictureEntry>;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := FChunks.Read(AChunk);
  SetLength(Result, Length(LBytes) div SizeOf(TKeenPictureEntry));
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Width := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 4);
    Result[LIndex].Height := TKeenLittleEndian.ReadSmallInt(LBytes, LIndex * 4 + 2);
  end;
end;

function TKeenGraphics.GetChunks: IKeenChunkSource;
begin
  Result := FChunks;
end;

function TKeenGraphics.GetPictureTable: TArray<TKeenPictureEntry>;
begin
  Result := Copy(FPictures);
end;

function TKeenGraphics.GetMaskedPictureTable: TArray<TKeenPictureEntry>;
begin
  Result := Copy(FMaskedPictures);
end;

function TKeenGraphics.GetSpriteTable: TArray<TKeenSpriteEntry>;
begin
  Result := Copy(FSprites);
end;

function TKeenGraphics.ReadPicture(AIndex, AFirstChunk, ACount, APlanes: Integer;
  const ATable: TArray<TKeenPictureEntry>): TBytes;
var
  LExpected: Integer;
begin
  if (AIndex < 0) or (AIndex >= ACount) or (AIndex >= Length(ATable)) then
    raise EKeenDataException.CreateFmt(SKeenPictureInvalid, [AIndex, Length(ATable)]);
  Result := FChunks.Read(AFirstChunk + AIndex);
  LExpected := ATable[AIndex].Width * ATable[AIndex].Height * APlanes;
  if Length(Result) <> LExpected then
    raise EKeenDataException.CreateFmt(SKeenPlanarTooShort, [LExpected, Length(Result)]);
end;

function TKeenGraphics.PicturePlanar(AIndex: Integer): TBytes;
begin
  Result := ReadPicture(AIndex, KEEN_STARTPICS, KEEN_NUMPICS, KEEN_EGA_PLANES,
    FPictures);
end;

function TKeenGraphics.MaskedPicturePlanar(AIndex: Integer): TBytes;
begin
  Result := ReadPicture(AIndex, KEEN_STARTPICM, KEEN_NUMPICM, KEEN_EGA_PLANES + 1,
    FMaskedPictures);
end;

function TKeenGraphics.SpritePlanar(AIndex: Integer): TBytes;
var
  LExpected: Integer;
begin
  if (AIndex < 0) or (AIndex >= KEEN_NUMSPRITES) or (AIndex >= Length(FSprites)) then
    raise EKeenDataException.CreateFmt(SKeenPictureInvalid, [AIndex, Length(FSprites)]);
  Result := FChunks.Read(KEEN_STARTSPRITES + AIndex);
  LExpected := FSprites[AIndex].Width * FSprites[AIndex].Height * (KEEN_EGA_PLANES + 1);
  // the C reads the expanded length of the chunk and then expands Width * Height * 5 bytes: they must agree
  if Length(Result) <> LExpected then
    raise EKeenDataException.CreateFmt(SKeenPlanarTooShort, [LExpected, Length(Result)]);
end;

function TKeenGraphics.Slice(const ASource: TBytes; AIndex, ABlock, ACount: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise EKeenDataException.CreateFmt(SKeenTileInvalid, [AIndex, ACount]);
  Result := Copy(ASource, AIndex * ABlock, ABlock);
end;

function TKeenGraphics.Tile8(AIndex: Integer): TBytes;
begin
  if Length(FTile8) = 0 then
    FTile8 := FChunks.Read(KEEN_STARTTILE8);
  Result := Slice(FTile8, AIndex, KEEN_TILE8_BYTES, KEEN_NUMTILE8);
end;

function TKeenGraphics.Tile8Masked(AIndex: Integer): TBytes;
begin
  if Length(FTile8Masked) = 0 then
    FTile8Masked := FChunks.Read(KEEN_STARTTILE8M);
  Result := Slice(FTile8Masked, AIndex, KEEN_TILE8M_BYTES, KEEN_NUMTILE8M);
end;

function TKeenGraphics.ReadTile(AFirstChunk, ACount, AIndex: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise EKeenDataException.CreateFmt(SKeenTileInvalid, [AIndex, ACount]);
  Result := FChunks.Read(AFirstChunk + AIndex);
end;

function TKeenGraphics.Tile16(AIndex: Integer): TBytes;
begin
  Result := ReadTile(KEEN_STARTTILE16, KEEN_NUMTILE16, AIndex);
end;

function TKeenGraphics.Tile16Masked(AIndex: Integer): TBytes;
begin
  Result := ReadTile(KEEN_STARTTILE16M, KEEN_NUMTILE16M, AIndex);
end;

end.
