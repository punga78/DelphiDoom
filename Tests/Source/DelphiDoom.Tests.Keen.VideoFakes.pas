{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - fakes for the video and the refresh  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.VideoFakes;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

const
  /// <summary>Tiles of the fake background and foreground that have data (the others are sparse)</summary>
  FAKE_TILES = 64;
  FAKE_MASKED_TILES = 32;

type
  /// <summary>
  ///   Graphics made of random bytes: tiles, masked tiles (the data are 0 where the mask is 1, as in the real
  ///   files), pictures and 4 sprites (width 3 with 4 shifts, 2 with 2, 2 with 1, and one with an origin)
  /// </summary>
  TFakeKeenGraphics = class(TInterfacedObject, IKeenGraphics)
  strict private
    FSeed: Cardinal;
    FSprites: TArray<TKeenSpriteEntry>;
    function Random(AKey, ACount: Integer): TBytes;
    function MaskedRandom(AKey, AMaskBytes, APlaneBytes: Integer): TBytes;
  public
    constructor Create(ASeed: Cardinal);
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

  /// <summary>A clock that moves forward when the code waits for it</summary>
  TFakeKeenClock = class(TInterfacedObject, IKeenClock)
  strict private
    FTimeCount: Integer;
    FIdleStep: Integer;
    FIdleCalls: Integer;
  public
    constructor Create(AIdleStep: Integer = 1);
    function GetTimeCount: Integer;
    procedure SetTimeCount(AValue: Integer);
    procedure Idle;
    property IdleCalls: Integer read FIdleCalls;
  end;

  TFakeKeenPixels = class
  public
    /// <summary>The color of the pixel (AX, AY) of a screen that starts at AOffset with rows of ALineWidth bytes</summary>
    class function Pixel(const AMemory: IKeenEgaMemory; AOffset, ALineWidth, AX, AY: Integer): Byte; static;
    /// <summary>The Fowler-Noll-Vo hash of the 4 planes of the memory (to compare two memories)</summary>
    class function MemoryHash(const AMemory: IKeenEgaMemory): Cardinal; static;
    /// <summary>The same hash for a picture</summary>
    class function ImageHash(const AImage: TKeenChunkyImage): Cardinal; static;
  end;

  TFakeKeenTiles = class
  public
    /// <summary>A tile info table with nothing animating: set the bytes with the constants KEEN_TINF_*</summary>
    class function EmptyTable: TBytes; static;
  end;

implementation

{ TFakeKeenGraphics }

constructor TFakeKeenGraphics.Create(ASeed: Cardinal);
var
  LEntry: TKeenSpriteEntry;
begin
  inherited Create;
  FSeed := ASeed;
  SetLength(FSprites, 4);
  FillChar(LEntry, SizeOf(LEntry), 0);
  LEntry.Width := 3;
  LEntry.Height := 20;
  LEntry.Shifts := 4;
  FSprites[0] := LEntry;
  LEntry.Width := 2;
  LEntry.Height := 10;
  LEntry.Shifts := 2;
  FSprites[1] := LEntry;
  LEntry.Width := 2;
  LEntry.Height := 8;
  LEntry.Shifts := 1;
  FSprites[2] := LEntry;
  LEntry.Width := 3;
  LEntry.Height := 12;
  LEntry.OriginX := -40;
  LEntry.OriginY := 72;
  LEntry.Shifts := 4;
  FSprites[3] := LEntry;
end;

function TFakeKeenGraphics.Random(AKey, ACount: Integer): TBytes;
var
  LState: Cardinal;
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  LState := FSeed * Cardinal(2654435761) + Cardinal(AKey) * 40503 + 12345;
  for LIndex := 0 to ACount - 1 do
  begin
    LState := LState * 1664525 + 1013904223;
    Result[LIndex] := Byte(LState shr 24);
  end;
end;

function TFakeKeenGraphics.MaskedRandom(AKey, AMaskBytes, APlaneBytes: Integer): TBytes;
var
  LPlane: Integer;
  LIndex: Integer;
begin
  Assert(AMaskBytes = APlaneBytes);
  Result := Random(AKey, APlaneBytes * 5);
  // a mask of mostly 1s (the screen stays) so the shapes are small; the data are 0 where the mask is 1
  for LIndex := 0 to AMaskBytes - 1 do
  begin
    Result[LIndex] := Result[LIndex] or Result[(LIndex + 7) mod AMaskBytes];
    for LPlane := 1 to KEEN_EGA_PLANES do
      Result[LPlane * APlaneBytes + LIndex] := Result[LPlane * APlaneBytes + LIndex] and not Result[LIndex];
  end;
end;

function TFakeKeenGraphics.GetChunks: IKeenChunkSource;
begin
  Result := nil;
end;

function TFakeKeenGraphics.GetPictureTable: TArray<TKeenPictureEntry>;
begin
  SetLength(Result, KEEN_NUMPICS);
  FillChar(Result[0], SizeOf(Result[0]) * Length(Result), 0);
  Result[0].Width := 3;
  Result[0].Height := 8;
  Result[1].Width := 2;
  Result[1].Height := 5;
end;

function TFakeKeenGraphics.GetMaskedPictureTable: TArray<TKeenPictureEntry>;
begin
  SetLength(Result, KEEN_NUMPICM);
  Result[0].Width := 1;
  Result[0].Height := 6;
  Result[1].Width := 3;
  Result[1].Height := 4;
end;

function TFakeKeenGraphics.GetSpriteTable: TArray<TKeenSpriteEntry>;
begin
  Result := Copy(FSprites);
end;

function TFakeKeenGraphics.PicturePlanar(AIndex: Integer): TBytes;
var
  LTable: TArray<TKeenPictureEntry>;
begin
  LTable := GetPictureTable;
  Result := Random(1000 + AIndex, LTable[AIndex].Width * LTable[AIndex].Height * 4);
end;

function TFakeKeenGraphics.MaskedPicturePlanar(AIndex: Integer): TBytes;
var
  LTable: TArray<TKeenPictureEntry>;
begin
  LTable := GetMaskedPictureTable;
  Result := MaskedRandom(2000 + AIndex, LTable[AIndex].Width * LTable[AIndex].Height,
    LTable[AIndex].Width * LTable[AIndex].Height);
end;

function TFakeKeenGraphics.SpritePlanar(AIndex: Integer): TBytes;
begin
  Result := MaskedRandom(3000 + AIndex, FSprites[AIndex].Width * FSprites[AIndex].Height,
    FSprites[AIndex].Width * FSprites[AIndex].Height);
end;

function TFakeKeenGraphics.Tile8(AIndex: Integer): TBytes;
begin
  Result := Random(4000 + AIndex, KEEN_TILE8_BYTES);
end;

function TFakeKeenGraphics.Tile8Masked(AIndex: Integer): TBytes;
begin
  Result := MaskedRandom(5000 + AIndex, 8, 8);
end;

function TFakeKeenGraphics.Tile16(AIndex: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex >= KEEN_NUMTILE16) then
    raise EKeenDataException.CreateFmt(SKeenTileInvalid, [AIndex, KEEN_NUMTILE16]);
  // the tiles past the first FAKE_TILES have no data (sparse)
  if AIndex >= FAKE_TILES then
    Exit(nil);
  Result := Random(6000 + AIndex, KEEN_TILE16_BYTES);
end;

function TFakeKeenGraphics.Tile16Masked(AIndex: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex >= KEEN_NUMTILE16M) then
    raise EKeenDataException.CreateFmt(SKeenTileInvalid, [AIndex, KEEN_NUMTILE16M]);
  if AIndex >= FAKE_MASKED_TILES then
    Exit(nil);
  Result := MaskedRandom(7000 + AIndex, 32, 32);
end;

{ TFakeKeenClock }

constructor TFakeKeenClock.Create(AIdleStep: Integer);
begin
  inherited Create;
  FIdleStep := AIdleStep;
end;

function TFakeKeenClock.GetTimeCount: Integer;
begin
  Result := FTimeCount;
end;

procedure TFakeKeenClock.SetTimeCount(AValue: Integer);
begin
  FTimeCount := AValue;
end;

procedure TFakeKeenClock.Idle;
begin
  Inc(FTimeCount, FIdleStep);
  Inc(FIdleCalls);
end;

{ TFakeKeenPixels }

class function TFakeKeenPixels.Pixel(const AMemory: IKeenEgaMemory; AOffset, ALineWidth, AX,
  AY: Integer): Byte;
var
  LPlane: Integer;
  LByte: Integer;
begin
  Result := 0;
  LByte := AOffset + AY * ALineWidth + AX div 8;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    Result := Byte(Result or (((AMemory.ReadByte(LPlane, LByte) shr (7 - (AX and 7))) and 1) shl LPlane));
end;

class function TFakeKeenPixels.MemoryHash(const AMemory: IKeenEgaMemory): Cardinal;
var
  LPlane: Integer;
  LIndex: Integer;
begin
  Result := 2166136261;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    for LIndex := 0 to KEEN_EGA_PLANE_BYTES - 1 do
      Result := (Result xor AMemory.ReadByte(LPlane, LIndex)) * 16777619;
end;

class function TFakeKeenPixels.ImageHash(const AImage: TKeenChunkyImage): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 0 to High(AImage.Pixels) do
    Result := (Result xor AImage.Pixels[LIndex]) * 16777619;
end;

{ TFakeKeenTiles }

class function TFakeKeenTiles.EmptyTable: TBytes;
begin
  SetLength(Result, KEEN_TINF_SIZE);
end;

end.
