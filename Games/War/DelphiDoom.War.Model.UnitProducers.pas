{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - who trains each unit                               }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c (wu_getProducerUnitOfType,          }
{  wu_isValidUnitType), (c) 2019 Alejandro Coto Gutierrez, zlib License (see    }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitProducers;

interface

type
  /// <summary>
  ///   The building that trains a unit. The table is DelphiDoom.War.Ai.Tables.Data (generated from the output of the original)
  /// </summary>
  TWarUnitProducers = class
  public
    /// <summary>
    ///   wu_getProducerUnitOfType: the unit type of the building that trains AType (the town hall for the workers, the barracks for
    ///   the soldiers, ...), -1 for a type that nothing trains (the original logs a warning)
    /// </summary>
    class function ProducerOf(AType: Integer): Integer; static;
    /// <summary>wu_isValidUnitType: a unit type from the footman to the last one (-1, "none", is not)</summary>
    class function IsValidType(AType: Integer): Boolean; static; inline;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Ai.Tables.Data;

{ TWarUnitProducers }

class function TWarUnitProducers.ProducerOf(AType: Integer): Integer;
begin
  if (AType < 0) or (AType >= WAR_UNIT_COUNT) then
    Exit(-1);
  Result := WAR_UNIT_PRODUCERS[AType];
end;

class function TWarUnitProducers.IsValidType(AType: Integer): Boolean;
begin
  Result := (AType >= WAR_UNIT_FOOTMAN) and (AType < WAR_UNIT_COUNT);
end;

end.
