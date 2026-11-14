{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the occupation grid of the map                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_pathfinder.c (wpath_initPathFinder and the }
{  wpath_* functions of the grid), (c) 2019 Alejandro Coto Gutierrez, zlib     }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.PathGrid;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Types, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types;

const
  /// <summary>PATH_FINDER_DATA_EMPTY: nothing on the tile</summary>
  WAR_PATH_EMPTY = 0;
  /// <summary>PATH_FINDER_DATA_STATIC: something fixed (a tree, water, a building, a unit that stands)</summary>
  WAR_PATH_STATIC = 1;

type
  /// <summary>
  ///   What occupies each tile of the map (WarPathFinder.data): a 16 bit number per tile, the low 4 bits the kind
  ///   (empty, static) and the high 12 the id of the entity that stands there. The search of the paths (A star
  ///   and flow fields) is not here
  /// </summary>
  TWarPathGrid = class
  strict private
    FData: array[0..WAR_MAP_TILE_COUNT - 1] of Word;
    function IndexOf(AX, AY: Integer): Integer;
  public
    /// <summary>wpath_initPathFinder: wood (128) and water (64) of the passable map are static, the rest is empty</summary>
    constructor Create(const APassable: TArray<Word>);
    /// <summary>wpath_isInside</summary>
    class function IsInside(AX, AY: Integer): Boolean; static;
    /// <summary>wpath_getTileValue; EWarException outside the map (the original asserts)</summary>
    function GetTileValue(AX, AY: Integer): Word;
    /// <summary>
    ///   wpath_setTilesValue: the cells of the rectangle that are in the map (a start outside does nothing; the
    ///   rectangle is cut at the edge of the map)
    /// </summary>
    procedure SetTilesValue(AStartX, AStartY, AWidth, AHeight: Integer; AValue: Word);
    /// <summary>wpath_setFreeTiles</summary>
    procedure SetFreeTiles(AStartX, AStartY, AWidth, AHeight: Integer);
    /// <summary>wpath_setStaticEntity: the id in the high 12 bits (the number is cut to 16 bits as in the original)</summary>
    procedure SetStaticEntity(AStartX, AStartY, AWidth, AHeight: Integer; AId: Word);
    /// <summary>wpath_getTileValueType</summary>
    function GetTileValueType(AX, AY: Integer): Integer;
    /// <summary>wpath_getTileEntityId: the id stored in the tile (12 bits)</summary>
    function GetTileEntityId(AX, AY: Integer): Word;
    /// <summary>wpath_isEmpty</summary>
    function IsEmpty(AX, AY: Integer): Boolean;
    /// <summary>wpath_isStatic</summary>
    function IsStatic(AX, AY: Integer): Boolean;
    /// <summary>wpath_isTileAccesible: one of the eight neighbors is empty</summary>
    function IsTileAccessible(AX, AY: Integer): Boolean;
    /// <summary>
    ///   wpath_findEmptyTile: the tile itself if it is empty, else the first empty one in the breadth first order of the
    ///   original (the eight neighbors from the north, clockwise); the tile itself if the map has none
    /// </summary>
    function FindEmptyTile(AX, AY: Integer): TPoint;
    /// <summary>The 4096 values, row by row</summary>
    function ToArray: TArray<Word>;
  end;

implementation

const
  DIR_X: array[0..7] of Integer = (0, 1, 1, 1, 0, -1, -1, -1);
  DIR_Y: array[0..7] of Integer = (-1, -1, 0, 1, 1, 1, 0, -1);

{ TWarPathGrid }

constructor TWarPathGrid.Create(const APassable: TArray<Word>);
var
  LIndex: Integer;
begin
  inherited Create;
  if Length(APassable) < WAR_MAP_TILE_COUNT then
    raise EWarException.CreateFmt(SWarMapPassableShort, [Length(APassable), WAR_MAP_TILE_COUNT]);
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
    if (APassable[LIndex] = 128) or (APassable[LIndex] = 64) then
      FData[LIndex] := WAR_PATH_STATIC
    else
      FData[LIndex] := WAR_PATH_EMPTY;
end;

class function TWarPathGrid.IsInside(AX, AY: Integer): Boolean;
begin
  Result := (AX >= 0) and (AX < WAR_MAP_TILES_WIDTH) and (AY >= 0) and (AY < WAR_MAP_TILES_HEIGHT);
end;

function TWarPathGrid.IndexOf(AX, AY: Integer): Integer;
begin
  if not IsInside(AX, AY) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [AX, AY]);
  Result := AY * WAR_MAP_TILES_WIDTH + AX;
end;

function TWarPathGrid.GetTileValue(AX, AY: Integer): Word;
begin
  Result := FData[IndexOf(AX, AY)];
end;

procedure TWarPathGrid.SetTilesValue(AStartX, AStartY, AWidth, AHeight: Integer; AValue: Word);
var
  LEndX: Integer;
  LEndY: Integer;
  LX: Integer;
  LY: Integer;
begin
  if not IsInside(AStartX, AStartY) then
    Exit;
  if AStartX + AWidth >= WAR_MAP_TILES_WIDTH then
    AWidth := WAR_MAP_TILES_WIDTH - AStartX;
  if AStartY + AHeight >= WAR_MAP_TILES_HEIGHT then
    AHeight := WAR_MAP_TILES_HEIGHT - AStartY;
  LEndX := AStartX + AWidth;
  LEndY := AStartY + AHeight;
  for LY := AStartY to LEndY - 1 do
    for LX := AStartX to LEndX - 1 do
      FData[LY * WAR_MAP_TILES_WIDTH + LX] := AValue;
end;

procedure TWarPathGrid.SetFreeTiles(AStartX, AStartY, AWidth, AHeight: Integer);
begin
  SetTilesValue(AStartX, AStartY, AWidth, AHeight, WAR_PATH_EMPTY);
end;

procedure TWarPathGrid.SetStaticEntity(AStartX, AStartY, AWidth, AHeight: Integer; AId: Word);
begin
  SetTilesValue(AStartX, AStartY, AWidth, AHeight, Word((Cardinal(AId) shl 4) or WAR_PATH_STATIC));
end;

function TWarPathGrid.GetTileValueType(AX, AY: Integer): Integer;
begin
  Result := GetTileValue(AX, AY) and $000F;
end;

function TWarPathGrid.GetTileEntityId(AX, AY: Integer): Word;
begin
  Result := (GetTileValue(AX, AY) and $FFF0) shr 4;
end;

function TWarPathGrid.IsEmpty(AX, AY: Integer): Boolean;
begin
  Result := GetTileValueType(AX, AY) = WAR_PATH_EMPTY;
end;

function TWarPathGrid.IsStatic(AX, AY: Integer): Boolean;
begin
  Result := GetTileValueType(AX, AY) = WAR_PATH_STATIC;
end;

function TWarPathGrid.IsTileAccessible(AX, AY: Integer): Boolean;
var
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
begin
  for LDirection := 0 to 7 do
  begin
    LX := AX + DIR_X[LDirection];
    LY := AY + DIR_Y[LDirection];
    if IsInside(LX, LY) and IsEmpty(LX, LY) then
      Exit(True);
  end;
  Result := False;
end;

function TWarPathGrid.FindEmptyTile(AX, AY: Integer): TPoint;
var
  LQueue: array[0..WAR_MAP_TILE_COUNT - 1] of Integer;
  LSeen: array[0..WAR_MAP_TILE_COUNT - 1] of Boolean;
  LCount: Integer;
  LIndex: Integer;
  LDirection: Integer;
  LX: Integer;
  LY: Integer;
  LNextX: Integer;
  LNextY: Integer;
begin
  if IsEmpty(AX, AY) then
    Exit(Point(AX, AY));
  FillChar(LSeen, SizeOf(LSeen), 0);
  LQueue[0] := AY * WAR_MAP_TILES_WIDTH + AX;
  LSeen[LQueue[0]] := True;
  LCount := 1;
  LIndex := 0;
  while LIndex < LCount do
  begin
    LX := LQueue[LIndex] mod WAR_MAP_TILES_WIDTH;
    LY := LQueue[LIndex] div WAR_MAP_TILES_WIDTH;
    if IsEmpty(LX, LY) then
      Exit(Point(LX, LY));
    for LDirection := 0 to 7 do
    begin
      LNextX := LX + DIR_X[LDirection];
      LNextY := LY + DIR_Y[LDirection];
      if IsInside(LNextX, LNextY) and not LSeen[LNextY * WAR_MAP_TILES_WIDTH + LNextX] then
      begin
        LSeen[LNextY * WAR_MAP_TILES_WIDTH + LNextX] := True;
        LQueue[LCount] := LNextY * WAR_MAP_TILES_WIDTH + LNextX;
        Inc(LCount);
      end;
    end;
    Inc(LIndex);
  end;
  Result := Point(AX, AY);
end;

function TWarPathGrid.ToArray: TArray<Word>;
var
  LIndex: Integer;
begin
  SetLength(Result, WAR_MAP_TILE_COUNT);
  for LIndex := 0 to WAR_MAP_TILE_COUNT - 1 do
    Result[LIndex] := FData[LIndex];
end;

end.
