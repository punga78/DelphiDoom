{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixThingSpawnRules                           }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of what P_SpawnMapThing and P_SpawnPlayer of Rad-X (p_mobj.pas) did    }
{  with the extra data of a thing of Radix (the lump RTHINGS)                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Thing.Spawn;

interface

type
  /// <summary>How a thing of the map of a level of Radix is put in the level</summary>
  TRadixThingSpawnRules = class
  public
    const
      /// <summary>The skill of a thing that is always there in a net game</summary>
      NET_GAME_SKILL = 4;
      /// <summary>The identifier of a thing that RADIX.DAT does not name</summary>
      NO_THING_ID = 0;
  public
    /// <summary>
    ///   True when a thing of that skill is in a game of AGameSkill (0..4): the skill of the game
    ///   must reach the one of the thing; a net game also has the things of the highest skill
    /// </summary>
    class function IsSpawnedAtSkill(ARadixSkill, AGameSkill: Integer; ANetGame: Boolean): Boolean; static;
    /// <summary>
    ///   The height (fixed point) where the thing is put: the craft of a player at its height of
    ///   RADIX.DAT but not under the floor, the others at their height above the floor
    /// </summary>
    class function Height(AExtraZ: Integer; AFloorHeight: Integer; AIsPlayer: Boolean): Integer; static;
    /// <summary>
    ///   The identifier that the engine keeps for a thing with that number of RADIX.DAT (the
    ///   actions of the levels name the enemies with it); NO_THING_ID for a negative number
    /// </summary>
    class function ThingId(ARadixId: Integer): Integer; static;
    /// <summary>The number of RADIX.DAT back from the identifier; -1 for NO_THING_ID</summary>
    class function RadixId(AThingId: Integer): Integer; static;
  end;

implementation

const
  FIXED_UNIT = 65536;

{ TRadixThingSpawnRules }

class function TRadixThingSpawnRules.IsSpawnedAtSkill(ARadixSkill, AGameSkill: Integer;
  ANetGame: Boolean): Boolean;
begin
  Result := (ARadixSkill <= AGameSkill) or (ANetGame and (ARadixSkill = NET_GAME_SKILL));
end;

class function TRadixThingSpawnRules.Height(AExtraZ: Integer; AFloorHeight: Integer; AIsPlayer: Boolean): Integer;
begin
  if AIsPlayer then
  begin
    Result := AExtraZ * FIXED_UNIT;
    if Result < AFloorHeight then
      Result := AFloorHeight;
  end
  else
    Result := AFloorHeight + AExtraZ * FIXED_UNIT;
end;

class function TRadixThingSpawnRules.ThingId(ARadixId: Integer): Integer;
begin
  if ARadixId < 0 then
    Result := NO_THING_ID
  else
    Result := ARadixId + 1;
end;

class function TRadixThingSpawnRules.RadixId(AThingId: Integer): Integer;
begin
  Result := AThingId - 1;
end;

end.
