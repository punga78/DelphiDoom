{******************************************************************************}
{                                                                              }
{  DelphiDoom: map info library - the speed of the monsters of a new game      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.SkillSpeed;

interface

type
  /// <summary>What a new game does to the speed of the monsters</summary>
  TSkillSpeedChange = (sscNone, sscFast, sscNormal);

  /// <summary>
  ///   The part of G_InitNew that decides, the same in the four games, whether the monsters become
  ///   fast (nightmare or -fast) or go back to their normal speed after a nightmare game
  /// </summary>
  TSkillSpeed = class sealed
  public
    /// <summary>
    ///   Tells which change the tables of the monsters need
    /// </summary>
    /// <param name="AFastParameter">The program was started with -fast</param>
    /// <param name="ANewIsNightmare">The new game is on nightmare</param>
    /// <param name="AOldIsNightmare">The game that was played was on nightmare</param>
    class function Change(const AFastParameter, ANewIsNightmare, AOldIsNightmare: Boolean): TSkillSpeedChange; static;

    /// <summary>Monsters come back to life: nightmare, or -respawn</summary>
    class function RespawnMonsters(const ANewIsNightmare, ARespawnParameter: Boolean): Boolean; static;
  end;

implementation

{ TSkillSpeed }

class function TSkillSpeed.Change(const AFastParameter, ANewIsNightmare,
  AOldIsNightmare: Boolean): TSkillSpeedChange;
begin
  if AFastParameter or (ANewIsNightmare and not AOldIsNightmare) then
    Result := sscFast
  else if (not ANewIsNightmare) and AOldIsNightmare then
    Result := sscNormal
  else
    Result := sscNone;
end;

class function TSkillSpeed.RespawnMonsters(const ANewIsNightmare, ARespawnParameter: Boolean): Boolean;
begin
  Result := ANewIsNightmare or ARespawnParameter;
end;

end.
