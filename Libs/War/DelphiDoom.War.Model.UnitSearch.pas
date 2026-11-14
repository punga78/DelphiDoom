{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - looking for a unit among the others               }
{                                                                              }
{  Port of war1 (acoto87/war1), we_findClosestUnitOfType of war_entities.c and }
{  wu_getTownHallOfRace of war_units.c, (c) 2019 Alejandro Coto Gutierrez,     }
{  zlib License (see Libs\War\LICENSE-war1.txt). This is an altered version,   }
{  not the original.                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitSearch;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context;

type
  TWarUnitSearch = class
  public
    /// <summary>
    ///   we_findClosestUnitOfType: the slot of the unit of that type that is closest (in tiles, to its nearest tile) to
    ///   the entity, the first in the order of the list if two are as far; 0 if there is none. Dying or collapsing
    ///   buildings count, as in the original
    /// </summary>
    class function FindClosestOfType(AContext: TWarModelContext; ASlot, AUnitType: Integer): Integer; static;
    /// <summary>wu_getTownHallOfRace: the town hall of the humans for every race but the orcs</summary>
    class function TownHallOfRace(ARace: TWarRace): Integer; static;
  end;

implementation

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.UnitRange;

{ TWarUnitSearch }

class function TWarUnitSearch.FindClosestOfType(AContext: TWarModelContext; ASlot, AUnitType: Integer): Integer;
var
  LUnits: TArray<Integer>;
  LIndex: Integer;
  LEntity: PWarEntity;
  LTarget: PWarEntity;
  LDistance: Integer;
  LMinimum: Integer;
begin
  Result := 0;
  LMinimum := High(Integer);
  LEntity := AContext.Pool.Slots[ASlot];
  LUnits := AContext.Pool.OfType[WAR_ENTITY_UNIT].ToArray;
  for LIndex := 0 to High(LUnits) do
  begin
    LTarget := AContext.Pool.Slots[LUnits[LIndex]];
    if LTarget^.HasUnit and (LTarget^.UnitData.UnitType = AUnitType) then
    begin
      LDistance := TWarUnitRange.DistanceInTiles(LEntity, LTarget);
      if LDistance < LMinimum then
      begin
        Result := LUnits[LIndex];
        LMinimum := LDistance;
      end;
    end;
  end;
end;

class function TWarUnitSearch.TownHallOfRace(ARace: TWarRace): Integer;
begin
  if ARace = wraOrcs then
    Result := WAR_UNIT_TOWNHALL_ORCS
  else
    Result := WAR_UNIT_TOWNHALL_HUMANS;
end;

end.
