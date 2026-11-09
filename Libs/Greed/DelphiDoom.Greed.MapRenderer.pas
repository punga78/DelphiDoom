{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a map seen from above                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): a way to look at the data,  }
{  not a part of the game                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MapRenderer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

const
  /// <summary>Pixels of the side of a tile in the picture of a map</summary>
  GREED_MAP_TILE_PIXELS = 8;

type
  /// <summary>
  ///   Each tile is 8 x 8 pixels: the floor flat of the tile every 8 pixels, a row of the color of the wall on its
  ///   north side and a column on its west side (the walls of the plane are only on those two sides). The
  ///   flats are the lump startflats + the number of the plane, the walls startwalls + the number, as the game
  ///   finds them; a number that does not exist leaves the tile as it is. It is a way to see that the planes
  ///   are right, not a rendering of the game
  /// </summary>
  TGreedMapRenderer = class(TInterfacedObject, IGreedMapRenderer)
  strict private
    FArchive: IGreedArchive;
    FFlatDecoder: IGreedImageDecoder;
    FWallDecoder: IGreedImageDecoder;
    FFlatCache: TDictionary<Integer, TGreedImage>;
    FWallCache: TDictionary<Integer, TGreedImage>;
    function FlatImage(AFirstFlat, ALastFlat, APicture: Integer; out AImage: TGreedImage): Boolean;
    function WallColor(AFirstWall, ALastWall, AWall: Integer; out AColor: Byte): Boolean;
  public
    constructor Create(const AArchive: IGreedArchive; const AFlatDecoder, AWallDecoder: IGreedImageDecoder);
    destructor Destroy; override;
    function Render(const AMap: IGreedMap): TGreedImage;
  end;

implementation

{ TGreedMapRenderer }

constructor TGreedMapRenderer.Create(const AArchive: IGreedArchive; const AFlatDecoder,
  AWallDecoder: IGreedImageDecoder);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(AFlatDecoder) then
    raise EArgumentNilException.Create('AFlatDecoder');
  if not Assigned(AWallDecoder) then
    raise EArgumentNilException.Create('AWallDecoder');
  FArchive := AArchive;
  FFlatDecoder := AFlatDecoder;
  FWallDecoder := AWallDecoder;
  FFlatCache := TDictionary<Integer, TGreedImage>.Create;
  FWallCache := TDictionary<Integer, TGreedImage>.Create;
end;

destructor TGreedMapRenderer.Destroy;
begin
  FFlatCache.Free;
  FWallCache.Free;
  inherited Destroy;
end;

function TGreedMapRenderer.FlatImage(AFirstFlat, ALastFlat, APicture: Integer;
  out AImage: TGreedImage): Boolean;
var
  LLump: Integer;
begin
  Result := False;
  LLump := AFirstFlat + APicture;
  if (AFirstFlat < 0) or (APicture <= 0) or (LLump >= ALastFlat) then
    Exit;
  if not FFlatCache.TryGetValue(LLump, AImage) then
  begin
    AImage := FFlatDecoder.Decode(FArchive.ReadLump(LLump));
    FFlatCache.Add(LLump, AImage);
  end;
  Result := True;
end;

function TGreedMapRenderer.WallColor(AFirstWall, ALastWall, AWall: Integer; out AColor: Byte): Boolean;
var
  LLump: Integer;
  LImage: TGreedImage;
begin
  Result := False;
  LLump := AFirstWall + AWall;
  if (AFirstWall < 0) or (AWall <= 0) or (LLump >= ALastWall) then
    Exit;
  if not FWallCache.TryGetValue(LLump, LImage) then
  begin
    LImage := FWallDecoder.Decode(FArchive.ReadLump(LLump));
    FWallCache.Add(LLump, LImage);
  end;
  AColor := LImage.Pixels[(LImage.Height div 2) * LImage.Width + LImage.Width div 2];
  Result := True;
end;

function TGreedMapRenderer.Render(const AMap: IGreedMap): TGreedImage;
var
  LSide: Integer;
  LFirstFlat: Integer;
  LLastFlat: Integer;
  LFirstWall: Integer;
  LLastWall: Integer;
  LFloor: TBytes;
  LNorth: TBytes;
  LWest: TBytes;
  LTileX: Integer;
  LTileY: Integer;
  LTile: Integer;
  LFlat: TGreedImage;
  LHasFlat: Boolean;
  LColor: Byte;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  LSide := GREED_MAP_SIZE * GREED_MAP_TILE_PIXELS;
  Result.Width := LSide;
  Result.Height := LSide;
  Result.OriginX := 0;
  Result.OriginY := 0;
  SetLength(Result.Pixels, LSide * LSide);
  FillChar(Result.Pixels[0], Length(Result.Pixels), 0);
  LFirstFlat := FArchive.IndexOf(GREED_LUMP_START_FLATS);
  LLastFlat := FArchive.IndexOf(GREED_LUMP_END_FLATS);
  LFirstWall := FArchive.IndexOf(GREED_LUMP_START_WALLS);
  LLastWall := FArchive.IndexOf(GREED_LUMP_END_WALLS);
  LFloor := AMap.Planes[gpFloorPic];
  LNorth := AMap.Planes[gpNorthWall];
  LWest := AMap.Planes[gpWestWall];
  for LTileY := 0 to GREED_MAP_SIZE - 1 do
    for LTileX := 0 to GREED_MAP_SIZE - 1 do
    begin
      LTile := LTileY * GREED_MAP_SIZE + LTileX;
      LHasFlat := FlatImage(LFirstFlat, LLastFlat, LFloor[LTile], LFlat);
      if LHasFlat then
        for LDeltaY := 0 to GREED_MAP_TILE_PIXELS - 1 do
          for LDeltaX := 0 to GREED_MAP_TILE_PIXELS - 1 do
            Result.Pixels[(LTileY * GREED_MAP_TILE_PIXELS + LDeltaY) * LSide + LTileX * GREED_MAP_TILE_PIXELS + LDeltaX] :=
              LFlat.Pixels[(LDeltaY * GREED_MAP_TILE_PIXELS) * LFlat.Width + LDeltaX * GREED_MAP_TILE_PIXELS];
      if WallColor(LFirstWall, LLastWall, LNorth[LTile], LColor) then
        for LDeltaX := 0 to GREED_MAP_TILE_PIXELS - 1 do
          Result.Pixels[LTileY * GREED_MAP_TILE_PIXELS * LSide + LTileX * GREED_MAP_TILE_PIXELS + LDeltaX] := LColor;
      if WallColor(LFirstWall, LLastWall, LWest[LTile], LColor) then
        for LDeltaY := 0 to GREED_MAP_TILE_PIXELS - 1 do
          Result.Pixels[(LTileY * GREED_MAP_TILE_PIXELS + LDeltaY) * LSide + LTileX * GREED_MAP_TILE_PIXELS] := LColor;
    end;
end;

end.
