{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - where a unit comes out of a building               }
{                                                                              }
{  Port of war1 (acoto87/war1), the use of wpath_findEmptyTile and             }
{  wu_setUnitCenterTile in war_state_machine_build.c, _train.c and             }
{  _repairing.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see          }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitPlacement;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context;

type
  /// <summary>Putting a unit on the nearest empty tile, as the buildings do with the units that they make and the workers that leave them</summary>
  TWarUnitPlacement = class
  public
    /// <summary>
    ///   The center of the unit goes to the center of the nearest empty tile to the center tile of AFrom (which can be the
    ///   same unit): the tile itself if it is empty
    /// </summary>
    class procedure PlaceNear(AContext: TWarModelContext; AFrom, AUnit: PWarEntity); static;
  end;

implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitGeometry;

{ TWarUnitPlacement }

class procedure TWarUnitPlacement.PlaceNear(AContext: TWarModelContext; AFrom, AUnit: PWarEntity);
var
  LTile: TWarVec2;
  LX: Integer;
  LY: Integer;
begin
  LTile := TWarUnitGeometry.CenterTile(AFrom);
  AContext.Probe.FindEmptyTile(Trunc(LTile.X), Trunc(LTile.Y), LX, LY);
  TWarUnitGeometry.SetCenterPosition(AUnit, TWarModelMath.TileToMap(TWarModelMath.Vec(LX, LY), True));
end;

end.
