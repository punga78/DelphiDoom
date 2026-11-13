{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the visual map of a game                          }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (wmap_getMapTileIndex,               }
{  wmap_setMapTileIndex), (c) 2019 Alejandro Coto Gutierrez, zlib License (see }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.TilePainter;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Map.Minimap;

type
  /// <summary>
  ///   The tile of the tileset in each cell of the map of a game: a copy of the visual map of the level (the original
  ///   changes the record of the level itself, here the level stays as it was read) that a change writes, and the
  ///   minimap pixel that goes with it
  /// </summary>
  TWarMapTilePainter = class(TInterfacedObject, IWarTilePainter)
  strict private
    FVisual: TArray<Word>;
    FMinimap: TWarMinimap;
    FFog: TWarFogOfWar;
  public
    /// <summary>AVisual is copied; the minimap and the fog are the ones of the map (not owned)</summary>
    constructor Create(const AVisual: TArray<Word>; const AMinimap: TWarMinimap; const AFog: TWarFogOfWar);
    /// <summary>wmap_getMapTileIndex</summary>
    function GetTileIndex(AX, AY: Integer): Integer;
    /// <summary>wmap_setMapTileIndex: the tile must be 0..65535 (the original asserts)</summary>
    procedure SetTileIndex(AX, AY, ATile: Integer);
    function GetVisual: TArray<Word>;
  end;

implementation

{ TWarMapTilePainter }

constructor TWarMapTilePainter.Create(const AVisual: TArray<Word>; const AMinimap: TWarMinimap; const AFog: TWarFogOfWar);
begin
  inherited Create;
  if Length(AVisual) < WAR_MAP_TILE_COUNT then
    raise EWarException.CreateFmt(SWarMapVisualShort, [Length(AVisual), WAR_MAP_TILE_COUNT]);
  FVisual := Copy(AVisual, 0, WAR_MAP_TILE_COUNT);
  FMinimap := AMinimap;
  FFog := AFog;
end;

function TWarMapTilePainter.GetTileIndex(AX, AY: Integer): Integer;
begin
  if (AX < 0) or (AX >= WAR_MAP_TILES_WIDTH) or (AY < 0) or (AY >= WAR_MAP_TILES_HEIGHT) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AX, AY]);
  Result := FVisual[AY * WAR_MAP_TILES_WIDTH + AX];
end;

function TWarMapTilePainter.GetVisual: TArray<Word>;
begin
  Result := Copy(FVisual);
end;

procedure TWarMapTilePainter.SetTileIndex(AX, AY, ATile: Integer);
begin
  if (AX < 0) or (AX >= WAR_MAP_TILES_WIDTH) or (AY < 0) or (AY >= WAR_MAP_TILES_HEIGHT) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AX, AY]);
  if (ATile < 0) or (ATile > $FFFF) then
    raise EWarException.CreateFmt(SWarMapTilesetTile, [ATile]);
  FVisual[AY * WAR_MAP_TILES_WIDTH + AX] := Word(ATile);
  FMinimap.UpdateTile(FFog, FVisual, AX, AY);
end;

end.
