{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the fog of war                                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (setInitialTileState, the            }
{  wmap_*TileState and wmap_is*TileIn* functions, determineFoWTypes), (c) 2019 }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Fog;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Math, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types;

type
  /// <summary>
  ///   What the player knows of each tile: unknown, seen before (fog) or in sight. All the tiles start unknown.
  ///   With the fog disabled (map->fowEnabled false) every tile is in sight and none is unknown or in fog
  /// </summary>
  TWarFogOfWar = class
  strict private
    FTiles: array[0..WAR_MAP_TILE_COUNT - 1] of TWarMapTile;
    FEnabled: Boolean;
    function IndexOf(AX, AY: Integer): Integer;
    function DisabledAnswer(AState: TWarMapTileState): Boolean;
    procedure ClipRectangle(var AStartX, AStartY, AWidth, AHeight: Integer);
  public
    /// <summary>setInitialTileState (fowEnabled is true when the map is entered)</summary>
    constructor Create;
    /// <summary>wmap_getMapTileState; EWarException outside the map (the original asserts)</summary>
    function GetTile(AX, AY: Integer): TWarMapTile;
    /// <summary>
    ///   wmap_setMapTileState: the state of a rectangle of tiles, without its four corners (a more round shape);
    ///   the end is cut at the edge of the map and a start before the map is moved to the
    ///   edge without shortening the width (so the area goes farther to the right or down, as in the original)
    /// </summary>
    procedure SetState(AStartX, AStartY, AWidth, AHeight: Integer; AState: TWarMapTileState);
    /// <summary>wmap_isTileInState</summary>
    function IsTileInState(AX, AY: Integer; AState: TWarMapTileState): Boolean;
    /// <summary>wmap_isAnyTileInStates</summary>
    function IsAnyTileInState(AStartX, AStartY, AWidth, AHeight: Integer; AState: TWarMapTileState): Boolean;
    /// <summary>wmap_areAllTilesInState (an empty rectangle gives true)</summary>
    function AreAllTilesInState(AStartX, AStartY, AWidth, AHeight: Integer; AState: TWarMapTileState): Boolean;
    function IsTileUnknown(AX, AY: Integer): Boolean;
    function IsTileFog(AX, AY: Integer): Boolean;
    function IsTileVisible(AX, AY: Integer): Boolean;
    /// <summary>wmap_isPositionVisible: a position in pixels of the map</summary>
    function IsPositionVisible(AX, AY: Single): Boolean;
    /// <summary>wmap_isUnitPartiallyVisible and the others of the family: some (or all) of the tiles of the unit in the state</summary>
    function IsUnitPartiallyIn(const AUnit: TWarMapUnit; AState: TWarMapTileState): Boolean;
    function IsUnitEntirelyIn(const AUnit: TWarMapUnit; AState: TWarMapTileState): Boolean;
    /// <summary>The start of updateFoW: every tile in sight becomes fog and the pieces of fog are cleared</summary>
    procedure BeginUpdate;
    /// <summary>determineFoWTypes: the piece of fog and the boundary of each tile from its eight neighbors; nothing if the fog is disabled</summary>
    procedure DetermineTypes;
    /// <summary>The tiles in the state (for the tests and the minimap)</summary>
    function CountState(AState: TWarMapTileState): Integer;
    /// <summary>map->fowEnabled</summary>
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

implementation

uses
  DelphiDoom.War.Autotile.Data;

const
  DIR_X: array[0..7] of Integer = (-1, 0, 1, 1, 1, 0, -1, -1);
  DIR_Y: array[0..7] of Integer = (-1, -1, -1, 0, 1, 1, 1, 0);

{ TWarFogOfWar }

constructor TWarFogOfWar.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  FEnabled := True;
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
  begin
    FTiles[LIndex].State := wtsUnknown;
    FTiles[LIndex].PieceType := 0;
    FTiles[LIndex].Boundary := wfbNone;
  end;
end;

function TWarFogOfWar.IndexOf(AX, AY: Integer): Integer;
begin
  if (AX < 0) or (AX >= WAR_MAP_TILES_WIDTH) or (AY < 0) or (AY >= WAR_MAP_TILES_HEIGHT) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AX, AY]);
  Result := AY * WAR_MAP_TILES_WIDTH + AX;
end;

function TWarFogOfWar.GetTile(AX, AY: Integer): TWarMapTile;
begin
  Result := FTiles[IndexOf(AX, AY)];
end;

function TWarFogOfWar.DisabledAnswer(AState: TWarMapTileState): Boolean;
begin
  Result := AState = wtsVisible;
end;

procedure TWarFogOfWar.ClipRectangle(var AStartX, AStartY, AWidth, AHeight: Integer);
begin
  if AStartX <= 0 then
    AStartX := 0;
  if AStartY <= 0 then
    AStartY := 0;
  if AStartX + AWidth >= WAR_MAP_TILES_WIDTH then
    AWidth := WAR_MAP_TILES_WIDTH - AStartX;
  if AStartY + AHeight >= WAR_MAP_TILES_HEIGHT then
    AHeight := WAR_MAP_TILES_HEIGHT - AStartY;
end;

procedure TWarFogOfWar.SetState(AStartX, AStartY, AWidth, AHeight: Integer; AState: TWarMapTileState);
var
  LEndX: Integer;
  LEndY: Integer;
  LX: Integer;
  LY: Integer;
begin
  ClipRectangle(AStartX, AStartY, AWidth, AHeight);
  LEndX := AStartX + AWidth;
  LEndY := AStartY + AHeight;
  for LY := AStartY to LEndY - 1 do
    for LX := AStartX to LEndX - 1 do
    begin
      // exclude the corners of the area to get a more "rounded" shape
      if ((LY = AStartY) or (LY = LEndY - 1)) and ((LX = AStartX) or (LX = LEndX - 1)) then
        Continue;
      FTiles[IndexOf(LX, LY)].State := AState;
    end;
end;

function TWarFogOfWar.IsTileInState(AX, AY: Integer; AState: TWarMapTileState): Boolean;
begin
  if not FEnabled then
    Exit(DisabledAnswer(AState));
  Result := FTiles[IndexOf(AX, AY)].State = AState;
end;

function TWarFogOfWar.IsAnyTileInState(AStartX, AStartY, AWidth, AHeight: Integer; AState: TWarMapTileState): Boolean;
var
  LEndX: Integer;
  LEndY: Integer;
  LX: Integer;
  LY: Integer;
begin
  if not FEnabled then
    Exit(DisabledAnswer(AState));
  ClipRectangle(AStartX, AStartY, AWidth, AHeight);
  LEndX := AStartX + AWidth;
  LEndY := AStartY + AHeight;
  for LY := AStartY to LEndY - 1 do
    for LX := AStartX to LEndX - 1 do
      if FTiles[IndexOf(LX, LY)].State = AState then
        Exit(True);
  Result := False;
end;

function TWarFogOfWar.AreAllTilesInState(AStartX, AStartY, AWidth, AHeight: Integer; AState: TWarMapTileState): Boolean;
var
  LEndX: Integer;
  LEndY: Integer;
  LX: Integer;
  LY: Integer;
begin
  if not FEnabled then
    Exit(DisabledAnswer(AState));
  ClipRectangle(AStartX, AStartY, AWidth, AHeight);
  LEndX := AStartX + AWidth;
  LEndY := AStartY + AHeight;
  for LY := AStartY to LEndY - 1 do
    for LX := AStartX to LEndX - 1 do
      if FTiles[IndexOf(LX, LY)].State <> AState then
        Exit(False);
  Result := True;
end;

function TWarFogOfWar.IsTileUnknown(AX, AY: Integer): Boolean;
begin
  Result := IsTileInState(AX, AY, wtsUnknown);
end;

function TWarFogOfWar.IsTileFog(AX, AY: Integer): Boolean;
begin
  Result := IsTileInState(AX, AY, wtsFog);
end;

function TWarFogOfWar.IsTileVisible(AX, AY: Integer): Boolean;
begin
  Result := IsTileInState(AX, AY, wtsVisible);
end;

function TWarFogOfWar.IsPositionVisible(AX, AY: Single): Boolean;
var
  LTileX: Integer;
  LTileY: Integer;
begin
  // wmap_mapToTileCoordinatesV floors the division, then the position is cast to s32
  LTileX := Floor(AX / WAR_MEGA_TILE_SIZE);
  LTileY := Floor(AY / WAR_MEGA_TILE_SIZE);
  if (LTileX < 0) or (LTileX >= WAR_MAP_TILES_WIDTH) or (LTileY < 0) or (LTileY >= WAR_MAP_TILES_HEIGHT) then
    Exit(False);
  Result := IsTileVisible(LTileX, LTileY);
end;

function TWarFogOfWar.IsUnitPartiallyIn(const AUnit: TWarMapUnit; AState: TWarMapTileState): Boolean;
begin
  Result := IsAnyTileInState(AUnit.TileX, AUnit.TileY, AUnit.SizeX, AUnit.SizeY, AState);
end;

function TWarFogOfWar.IsUnitEntirelyIn(const AUnit: TWarMapUnit; AState: TWarMapTileState): Boolean;
begin
  Result := AreAllTilesInState(AUnit.TileX, AUnit.TileY, AUnit.SizeX, AUnit.SizeY, AState);
end;

procedure TWarFogOfWar.BeginUpdate;
var
  LIndex: Integer;
begin
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
  begin
    FTiles[LIndex].PieceType := 0;
    FTiles[LIndex].Boundary := wfbNone;
    if FTiles[LIndex].State = wtsVisible then
      FTiles[LIndex].State := wtsFog;
  end;
end;

procedure TWarFogOfWar.DetermineTypes;
var
  LX: Integer;
  LY: Integer;
  LDirection: Integer;
  LNeighborX: Integer;
  LNeighborY: Integer;
  LIndex: Integer;
  LUnknownCount: Integer;
  LFogCount: Integer;
  LNeighbor: TWarMapTile;
  LTile: PWarMapTile;
begin
  if not FEnabled then
    Exit;
  for LY := 0 to WAR_MAP_TILES_HEIGHT - 1 do
    for LX := 0 to WAR_MAP_TILES_WIDTH - 1 do
    begin
      LTile := @FTiles[LY * WAR_MAP_TILES_WIDTH + LX];
      LIndex := 0;
      LUnknownCount := 0;
      LFogCount := 0;
      for LDirection := 0 to 7 do
      begin
        LNeighborX := LX + DIR_X[LDirection];
        LNeighborY := LY + DIR_Y[LDirection];
        if (LNeighborX < 0) or (LNeighborX >= WAR_MAP_TILES_WIDTH) or (LNeighborY < 0) or
          (LNeighborY >= WAR_MAP_TILES_HEIGHT) then
          Continue;
        LNeighbor := FTiles[LNeighborY * WAR_MAP_TILES_WIDTH + LNeighborX];
        case LTile^.State of
          wtsVisible:
            if LNeighbor.State = wtsVisible then
              LIndex := LIndex or (1 shl LDirection)
            else if LNeighbor.State = wtsFog then
              Inc(LFogCount)
            else
              Inc(LUnknownCount);
        else
          // a tile in fog or unknown looks at the neighbors that are in sight or in fog
          if (LNeighbor.State = wtsVisible) or (LNeighbor.State = wtsFog) then
            LIndex := LIndex or (1 shl LDirection)
          else
            Inc(LUnknownCount);
        end;
      end;
      case LTile^.State of
        wtsVisible:
          begin
            if LIndex <> $FF then
              LTile^.PieceType := WAR_FOG_TILE_TYPE_MAP[LIndex];
            if LFogCount > 0 then
              LTile^.Boundary := wfbFog
            else if LUnknownCount > 0 then
              LTile^.Boundary := wfbUnknown;
          end;
        wtsFog:
          begin
            if LIndex <> $FF then
              LTile^.PieceType := WAR_FOG_TILE_TYPE_MAP[LIndex];
            if LUnknownCount > 0 then
              LTile^.Boundary := wfbUnknown;
          end;
      else
        // an unknown tile surrounded by tiles that are not unknown
        if LIndex = $FF then
          LTile^.PieceType := WAR_FOG_TILE_TYPE_MAP[LIndex];
      end;
    end;
end;

function TWarFogOfWar.CountState(AState: TWarMapTileState): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
    if FTiles[LIndex].State = AState then
      Inc(Result);
end;

end.
