{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the ceilings of Heretic as the  }
{  old code                                                                    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldCeilingsHeretic;

// The statements are the ones of T_MoveCeiling and of the case of EV_DoCeiling of Heretic
// (p_ceilng.pas) before the library, copied as they were, on the records and with the
// replacements of OldCeilings. Heretic has its own enumeration of the kinds (fewer values) and
// its ceiling_t has no fields for the changers of Boom: the copy uses the record of the test
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Tests.Thinkers.OldCeilings;

type
  /// <summary>ceiling_e of Heretic</summary>
  heretic_ceiling_e = (
    lowerToFloor,
    raiseToHighest,
    lowerAndCrush,
    crushAndRaise,
    fastCrushAndRaise,
    CLEV_LOWERTOFLOOR,
    CLEV_RAISETOHIGHEST
  );

/// <summary>T_MoveCeiling of Heretic; AType is the kind of the ceiling (the record keeps the one of Doom)</summary>
procedure OldHereticMoveCeiling(ceiling: Pceiling_t; AType: heretic_ceiling_e);
/// <summary>The case of EV_DoCeiling of Heretic on a new ceiling (crush already false)</summary>
procedure OldHereticSpawnCeiling(ceiling: Pceiling_t; sec: Psector_t; _type: heretic_ceiling_e);
/// <summary>The head of EV_DoCeiling of Heretic: the line wakes up its stopped ceilings</summary>
function OldHereticWakesUp(_type: heretic_ceiling_e): Boolean;

implementation

function T_MovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
begin
  Result := OldCeilingMovePlane(sector, speed, dest, crush, floorOrCeiling, direction);
end;

procedure S_StartSound(origin: Pointer; sound: Integer);
begin
  OldCeilingLogSound(sound);
end;

procedure P_RemoveActiveCeiling(c: Pceiling_t);
begin
  OldCeilingLogRemove;
end;

function leveltime: Integer;
begin
  Result := OldCeilingLevelTime;
end;

function P_FindHighestCeilingSurrounding(sec: Psector_t): fixed_t;
begin
  Result := OldHighestCeilingSurrounding;
end;

procedure OldHereticMoveCeiling(ceiling: Pceiling_t; AType: heretic_ceiling_e);
var
  res: result_e;
begin
  case ceiling.direction of
    0:
    // IN STASIS
      begin
      end;
    1:
    // UP
      begin
        res := T_MovePlane(ceiling.sector,
          ceiling.speed,
          ceiling.topheight,
          false, 1, ceiling.direction);

        if leveltime and 7 = 0 then
          S_StartSound(@ceiling.sector.soundorg, Ord(sfx_dormov));

        if res = pastdest then
        begin
          case AType of
            raiseToHighest:
              P_RemoveActiveCeiling(ceiling);
            fastCrushAndRaise,
            crushAndRaise:
              ceiling.direction := -1;
          end;
        end;
      end;
   -1:
    // DOWN
      begin
        res := T_MovePlane(ceiling.sector,
          ceiling.speed,
          ceiling.bottomheight,
          ceiling.crush, 1, ceiling.direction);

        if leveltime and 7 = 0 then
          S_StartSound(@ceiling.sector.soundorg, Ord(sfx_dormov));

        if res = pastdest then
        begin
          case AType of
            crushAndRaise:
              begin
                ceiling.speed := CEILSPEED;
                ceiling.direction := 1;
              end;
            fastCrushAndRaise:
              begin
                ceiling.direction := 1;
              end;
            lowerAndCrush,
            lowerToFloor:
              P_RemoveActiveCeiling(ceiling);
          end;
        end
        else // ( res <> pastdest )
        begin
          if res = crushed then
          begin
            case AType of
              crushAndRaise,
              lowerAndCrush:
                ceiling.speed := CEILSPEED div 8;
            end;
          end;
        end;
      end;
  end;
end;

procedure OldHereticSpawnCeiling(ceiling: Pceiling_t; sec: Psector_t; _type: heretic_ceiling_e);
begin
    case _type of
      fastCrushAndRaise:
        begin
          ceiling.crush := true;
          ceiling.topheight := sec.ceilingheight;
          ceiling.bottomheight := sec.floorheight + (8 * FRACUNIT);
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED * 2;
        end;

      crushAndRaise:
        begin
          ceiling.crush := true;
          ceiling.topheight := sec.ceilingheight;
          ceiling.bottomheight := sec.floorheight;
          if _type <> lowerToFloor then
            ceiling.bottomheight := ceiling.bottomheight + 8 * FRACUNIT;
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
        end;
      lowerAndCrush,
      lowerToFloor:
        begin
          ceiling.bottomheight := sec.floorheight;
          if _type <> lowerToFloor then
            ceiling.bottomheight := ceiling.bottomheight + 8 * FRACUNIT;
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
        end;

      raiseToHighest:
        begin
          ceiling.topheight := P_FindHighestCeilingSurrounding(sec);
          ceiling.direction := 1;
          ceiling.speed := CEILSPEED;
        end;
    end;
end;

function OldHereticWakesUp(_type: heretic_ceiling_e): Boolean;
begin
  // Reactivate in-stasis ceilings...for certain types.
  result := false;
  case _type of
    fastCrushAndRaise,
    crushAndRaise:
      result := true;
  end;
end;

end.
