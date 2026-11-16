{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a flow field                                      }
{                                                                              }
{  Port of war1 (acoto87/war1), war_pathfinder.h, WarMapFlowField and          }
{  wpath_flowFieldSample, (c) 2019 Alejandro Coto Gutierrez, zlib License      }
{  (see Games\War\LICENSE-war1.txt). This is an altered version, not the       }
{  original.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Path.FlowField;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Path.Types;

type
  /// <summary>
  ///   WarMapFlowField: for every tile of the map the cost of the way to the goal (in hundredths of a tile) and the
  ///   direction of the first step. The goal and the tiles that cannot be reached have no direction
  /// </summary>
  TWarFlowField = class
  strict private
    FCost: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of Integer;
    FDirs: array[0..WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1] of Byte;
    class var
      FUnitVectors: array[0..WAR_PATH_DIRECTION_COUNT - 1] of TWarVec2;
    class constructor Create;
    function GetCost(AIndex: Integer): Integer;
    function GetDirection(AIndex: Integer): Integer;
  public
    /// <summary>Every tile not reached: cost INT32_MAX, no direction (the start of wpath_computeFlowField)</summary>
    procedure Clear;
    /// <summary>Sets the direction and the cost of the tile number AIndex (y * 64 + x)</summary>
    procedure SetTile(AIndex, ACost, ADirection: Integer);
    /// <summary>
    ///   wpath_flowFieldSample: the unit vector of the direction of the tile, the zero vector if it has none; a tile
    ///   outside the map is the zero vector too
    /// </summary>
    function Sample(ATileX, ATileY: Integer): TWarVec2;
    /// <summary>The cost of the tile number AIndex (y * 64 + x)</summary>
    property Cost[AIndex: Integer]: Integer read GetCost;
    /// <summary>The direction (0..7, 8 for none) of the tile number AIndex</summary>
    property Direction[AIndex: Integer]: Integer read GetDirection;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.PathGrid,
  DelphiDoom.War.Model.Math;

{ TWarFlowField }

class constructor TWarFlowField.Create;
var
  LDirection: Integer;
  LVector: TWarVec2;
begin
  // vec2_normalize(vec2i(dirX, dirY)): the same function as the rest of the model, computed once
  for LDirection := 0 to WAR_PATH_DIRECTION_COUNT - 1 do
  begin
    LVector.X := WAR_PATH_DIR_X[LDirection];
    LVector.Y := WAR_PATH_DIR_Y[LDirection];
    FUnitVectors[LDirection] := TWarModelMath.Normalize(LVector);
  end;
end;

procedure TWarFlowField.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT - 1 do
  begin
    FCost[LIndex] := WAR_FLOW_UNREACHED;
    FDirs[LIndex] := WAR_FLOW_NO_DIRECTION;
  end;
end;

procedure TWarFlowField.SetTile(AIndex, ACost, ADirection: Integer);
begin
  FCost[AIndex] := ACost;
  FDirs[AIndex] := Byte(ADirection);
end;

function TWarFlowField.GetCost(AIndex: Integer): Integer;
begin
  Result := FCost[AIndex];
end;

function TWarFlowField.GetDirection(AIndex: Integer): Integer;
begin
  Result := FDirs[AIndex];
end;

function TWarFlowField.Sample(ATileX, ATileY: Integer): TWarVec2;
var
  LIndex: Integer;
  LDirection: Integer;
begin
  Result.X := 0;
  Result.Y := 0;
  if not TWarPathGrid.IsInside(ATileX, ATileY) then
    raise EWarException.CreateFmt(SWarMapTileOutside, [ATileX, ATileY]);
  LIndex := ATileY * WAR_MAP_TILES_WIDTH + ATileX;
  LDirection := FDirs[LIndex];
  if LDirection >= WAR_FLOW_NO_DIRECTION then
    Exit;
  // the original smooths nothing (a TODO there): the unit moves along the grid
  Result := FUnitVectors[LDirection];
end;

end.
