{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the minimap                                       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (wmap_getMapTileAverage,             }
{  wmap_updateMinimapTile, the minimap of createMapAndMinimapSprites),         }
{  war_entities.c (the pixels of renderMinimap) and war_units.c                }
{  (wu_getUnitColorOnMinimap), (c) 2019 Alejandro Coto Gutierrez, zlib License }
{  (see Libs\War\LICENSE-war1.txt). This is an altered version.                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Minimap;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Graphics.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Fog;

type
  /// <summary>A color of the minimap, one byte for each channel</summary>
  TWarMinimapColor = record
    R: Byte;
    G: Byte;
    B: Byte;
  end;

  /// <summary>
  ///   The minimap as an image of bytes, 64 x 64 pixels of R, G, B, A (one pixel per tile). The terrain is made once
  ///   (the average color of each tile of the tileset image) and changes when a tile does; each time the minimap is
  ///   shown the frame takes the terrain where the player has seen, black elsewhere, and the units on top
  /// </summary>
  TWarMinimap = class
  strict private
    FTileset: TBytes;
    FTerrain: TBytes;
    FFrame: TBytes;
    procedure PutPixel(ABuffer: TBytes; AIndex: Integer; ARed, AGreen, ABlue, AAlpha: Byte);
  public
    /// <summary>The image of the tileset (512 x 256 pixels of 4 bytes, TWarTileset.Pixels); both frames start black</summary>
    constructor Create(const ATilesetPixels: TBytes);
    /// <summary>
    ///   wmap_getMapTileAverage: the average of the 16 x 16 pixels of the tile of the tileset; EWarException for a tile
    ///   the image does not have (the original read past the image)
    /// </summary>
    function TileAverage(ATileIndex: Integer): TWarMinimapColor;
    /// <summary>The terrain of createMapAndMinimapSprites: the average color of every tile of the visual map</summary>
    procedure BuildTerrain(const AVisual: TArray<Word>);
    /// <summary>
    ///   wmap_updateMinimapTile: the terrain pixel of a cell; black if the fog is on and the player has not seen the tile
    /// </summary>
    procedure UpdateTile(const AFog: TWarFogOfWar; const AVisual: TArray<Word>; AX, AY: Integer);
    /// <summary>
    ///   The pixels of renderMinimap: the frame takes the terrain of the tiles in sight or in fog (black elsewhere)
    ///   and then each unit that is not dying or collapsing and is in sight (even in part) or has been seen paints
    ///   its tiles with the color of wu_getUnitColorOnMinimap. A unit that reaches past the right edge wraps to the
    ///   next row (as in the original); one past the last row is EWarException
    /// </summary>
    procedure Compose(const AFog: TWarFogOfWar; const AUnits: TList<TWarMapUnit>);
    /// <summary>wu_getUnitColorOnMinimap: the town halls are yellow, the player green, the other three players red, the rest gray</summary>
    class function UnitColor(const AUnit: TWarMapUnit): TWarMinimapColor; static;
    /// <summary>The frame that is shown (frames[0])</summary>
    property Frame: TBytes read FFrame;
    /// <summary>The terrain (frames[1])</summary>
    property Terrain: TBytes read FTerrain;
  end;

implementation

const
  TILESET_BYTES = WAR_TILESET_WIDTH * WAR_TILESET_HEIGHT * WAR_PIXEL_SIZE;

{ TWarMinimap }

constructor TWarMinimap.Create(const ATilesetPixels: TBytes);
var
  LIndex: Integer;
begin
  inherited Create;
  if Length(ATilesetPixels) < TILESET_BYTES then
    raise EWarException.CreateFmt(SWarMapTilesetShort, [Length(ATilesetPixels), TILESET_BYTES]);
  FTileset := ATilesetPixels;
  SetLength(FTerrain, WAR_MINIMAP_BYTES);
  SetLength(FFrame, WAR_MINIMAP_BYTES);
  // make the frames black
  for LIndex := 0 to WAR_MINIMAP_SIZE * WAR_MINIMAP_SIZE - 1 do
  begin
    FTerrain[LIndex * 4 + 3] := 255;
    FFrame[LIndex * 4 + 3] := 255;
  end;
end;

procedure TWarMinimap.PutPixel(ABuffer: TBytes; AIndex: Integer; ARed, AGreen, ABlue, AAlpha: Byte);
begin
  ABuffer[AIndex * 4 + 0] := ARed;
  ABuffer[AIndex * 4 + 1] := AGreen;
  ABuffer[AIndex * 4 + 2] := ABlue;
  ABuffer[AIndex * 4 + 3] := AAlpha;
end;

function TWarMinimap.TileAverage(ATileIndex: Integer): TWarMinimapColor;
var
  LPixelX: Integer;
  LPixelY: Integer;
  LX: Integer;
  LY: Integer;
  LOffset: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
begin
  LPixelX := (ATileIndex mod WAR_TILESET_TILES_PER_ROW) * WAR_MEGA_TILE_SIZE;
  LPixelY := (ATileIndex div WAR_TILESET_TILES_PER_ROW) * WAR_MEGA_TILE_SIZE;
  if (ATileIndex < 0) or (LPixelY + WAR_MEGA_TILE_SIZE > WAR_TILESET_HEIGHT) then
    raise EWarException.CreateFmt(SWarMapTilesetTile, [ATileIndex]);
  LRed := 0;
  LGreen := 0;
  LBlue := 0;
  for LY := 0 to WAR_MEGA_TILE_SIZE - 1 do
    for LX := 0 to WAR_MEGA_TILE_SIZE - 1 do
    begin
      LOffset := ((LPixelY + LY) * WAR_TILESET_WIDTH + (LPixelX + LX)) * WAR_PIXEL_SIZE;
      Inc(LRed, FTileset[LOffset + 0]);
      Inc(LGreen, FTileset[LOffset + 1]);
      Inc(LBlue, FTileset[LOffset + 2]);
    end;
  Result.R := Byte(LRed div 256);
  Result.G := Byte(LGreen div 256);
  Result.B := Byte(LBlue div 256);
end;

procedure TWarMinimap.BuildTerrain(const AVisual: TArray<Word>);
var
  LIndex: Integer;
  LColor: TWarMinimapColor;
begin
  if Length(AVisual) < WAR_MAP_TILE_COUNT then
    raise EWarException.CreateFmt(SWarMapVisualShort, [Length(AVisual), WAR_MAP_TILE_COUNT]);
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
  begin
    LColor := TileAverage(AVisual[LIndex]);
    PutPixel(FTerrain, LIndex, LColor.R, LColor.G, LColor.B, 255);
  end;
end;

procedure TWarMinimap.UpdateTile(const AFog: TWarFogOfWar; const AVisual: TArray<Word>; AX, AY: Integer);
var
  LIndex: Integer;
  LColor: TWarMinimapColor;
begin
  LIndex := AY * WAR_MAP_TILES_WIDTH + AX;
  if (AX < 0) or (AX >= WAR_MAP_TILES_WIDTH) or (AY < 0) or (AY >= WAR_MAP_TILES_HEIGHT) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AX, AY]);
  LColor.R := 0;
  LColor.G := 0;
  LColor.B := 0;
  if (not AFog.Enabled) or (AFog.GetTile(AX, AY).State = wtsVisible) or (AFog.GetTile(AX, AY).State = wtsFog) then
    LColor := TileAverage(AVisual[LIndex]);
  PutPixel(FTerrain, LIndex, LColor.R, LColor.G, LColor.B, 255);
end;

class function TWarMinimap.UnitColor(const AUnit: TWarMapUnit): TWarMinimapColor;
begin
  Result.R := 211;
  Result.G := 211;
  Result.B := 211;
  if (AUnit.UnitType = WAR_UNIT_TOWNHALL_HUMANS) or (AUnit.UnitType = WAR_UNIT_TOWNHALL_ORCS) then
  begin
    Result.R := 255;
    Result.G := 255;
    Result.B := 0;
  end
  else if AUnit.Player = 0 then
  begin
    Result.R := 0;
    Result.G := 199;
    Result.B := 0;
  end
  else if AUnit.Player < 4 then
  begin
    Result.R := 199;
    Result.G := 0;
    Result.B := 0;
  end;
end;

procedure TWarMinimap.Compose(const AFog: TWarFogOfWar; const AUnits: TList<TWarMapUnit>);
var
  LIndex: Integer;
  LUnit: TWarMapUnit;
  LColor: TWarMinimapColor;
  LX: Integer;
  LY: Integer;
  LPixel: Integer;
  LTile: TWarMapTile;
begin
  // copy the terrain where the player has seen
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
  begin
    LTile := AFog.GetTile(LIndex mod WAR_MAP_TILES_WIDTH, LIndex div WAR_MAP_TILES_WIDTH);
    if (not AFog.Enabled) or (LTile.State = wtsVisible) or (LTile.State = wtsFog) then
      Move(FTerrain[LIndex * 4], FFrame[LIndex * 4], 4)
    else
      PutPixel(FFrame, LIndex, 0, 0, 0, 255);
  end;
  for LUnit in AUnits do
  begin
    if LUnit.IsGone or (LUnit.UnitType = WAR_UNIT_HUMAN_CORPSE) or (LUnit.UnitType = WAR_UNIT_ORC_CORPSE) then
      Continue;
    if not (AFog.IsUnitPartiallyIn(LUnit, wtsVisible) or LUnit.HasBeenSeen) then
      Continue;
    LColor := UnitColor(LUnit);
    for LY := 0 to LUnit.SizeY - 1 do
      for LX := 0 to LUnit.SizeX - 1 do
      begin
        LPixel := (LUnit.TileY + LY) * WAR_MINIMAP_SIZE + (LUnit.TileX + LX);
        if (LPixel < 0) or (LPixel >= WAR_MINIMAP_SIZE * WAR_MINIMAP_SIZE) then
          raise EWarException.CreateFmt(SWarMapPixelOutside, [LPixel]);
        FFrame[LPixel * 4 + 0] := LColor.R;
        FFrame[LPixel * 4 + 1] := LColor.G;
        FFrame[LPixel * 4 + 2] := LColor.B;
      end;
  end;
end;

end.
