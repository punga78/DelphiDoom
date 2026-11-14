{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the ceilings as the old code    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldCeilings;

// The statements are the ones of T_MoveCeiling (Doom and Strife p_ceilng.pas: the same text) and
// of the case of EV_DoCeiling of Doom and of Strife before the library, copied as they were. Only
// what they call is replaced: the sector is a record of the test with the same field names, the
// step of the plane is the library one on a fake host (it has its own parity tests), sounds and
// removal are written in a log, the heights around the sector are variables of the test. The
// Heretic copy is in OldCeilingsHeretic (its enumeration has the same names with other values)
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Plane.Types, DelphiDoom.Thinkers.Plane.Intf;

type
  fixed_t = Integer;

  Psector_t = ^sector_t;
  sector_t = record
    // the first two fields are the ones that the fake host of the planes reads
    floorheight: fixed_t;
    ceilingheight: fixed_t;
    special: Integer;
    oldspecial: Integer;
    ceilingpic: Integer;
    soundorg: Integer;
  end;

  result_e = (ok, crushed, pastdest);

  ceiling_e = (
    lowerToFloor,
    raiseToHighest,
    lowerToLowest,
    lowerToMaxFloor,
    lowerAndCrush,
    crushAndRaise,
    fastCrushAndRaise,
    silentCrushAndRaise,
    genCeiling,
    genCeilingChg,
    genCeilingChg0,
    genCeilingChgT,
    genCrusher,
    genSilentCrusher,
    CLEV_LOWERTOFLOOR,
    CLEV_RAISETOHIGHEST
  );

  Pceiling_t = ^ceiling_t;
  ceiling_t = record
    _type: ceiling_e;
    sector: Psector_t;
    bottomheight: fixed_t;
    topheight: fixed_t;
    speed: fixed_t;
    oldspeed: fixed_t;
    crush: boolean;
    direction: integer;
    newspecial: integer;
    oldspecial: smallint;
    texture: smallint;
    tag: integer;
    olddirection: integer;
  end;

const
  FRACUNIT = 65536;
  CEILSPEED = FRACUNIT;
  sfx_stnmov = 22;
  sfx_pstop = 19;
  sfx_dormov = 61;

var
  /// <summary>leveltime of the old code</summary>
  OldCeilingLevelTime: Integer;
  /// <summary>What happens when a plane moves (P_ChangeSector): set by the test</summary>
  OldCeilingHost: IPlaneSectorHost;
  /// <summary>The rules of T_MovePlane of the game under test</summary>
  OldCeilingRules: TPlaneMoveRules;
  /// <summary>Sounds and removals of the old code, in order</summary>
  OldCeilingLog: string;
  /// <summary>What the P_Find... of the old code give</summary>
  OldHighestCeilingSurrounding: fixed_t;
  OldLowestCeilingSurrounding: fixed_t;
  OldHighestFloorSurrounding: fixed_t;

/// <summary>T_MovePlane for the old code and for the test of the new one: the library step</summary>
function OldCeilingMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
/// <summary>A line of the log, as S_StartSound of the old code writes it</summary>
procedure OldCeilingLogSound(sound: Integer);
/// <summary>A line of the log, as P_RemoveActiveCeiling of the old code writes it</summary>
procedure OldCeilingLogRemove;

/// <summary>T_MoveCeiling of Doom and of Strife</summary>
procedure OldDoomMoveCeiling(ceiling: Pceiling_t);
/// <summary>The case of EV_DoCeiling of Doom on a new ceiling (crush already false)</summary>
procedure OldDoomSpawnCeiling(ceiling: Pceiling_t; sec: Psector_t; _type: ceiling_e);
/// <summary>The case of EV_DoCeiling of Strife on a new ceiling (crush already false)</summary>
procedure OldStrifeSpawnCeiling(ceiling: Pceiling_t; sec: Psector_t; _type: ceiling_e);
/// <summary>The head of EV_DoCeiling of Doom and of Strife: 1 if the line wakes up its stopped ceilings</summary>
function OldDoomWakesUp(_type: ceiling_e): Boolean;

implementation

uses
  System.SysUtils, DelphiDoom.Thinkers.Plane.Mover;

function OldCeilingMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
var
  LResult: TPlaneMoveResult;
begin
  if floorOrCeiling = 1 then
    LResult := TPlaneMover.Move(sector.ceilingheight, sector.floorheight, speed, dest, crush,
      TPlaneKind.Ceiling, direction, OldCeilingRules, OldCeilingHost, sector)
  else
    LResult := TPlaneMover.Move(sector.floorheight, sector.ceilingheight, speed, dest, crush,
      TPlaneKind.Floor, direction, OldCeilingRules, OldCeilingHost, sector);
  case LResult of
    TPlaneMoveResult.Crushed:
      Result := crushed;
    TPlaneMoveResult.PastDest:
      Result := pastdest;
  else
    Result := ok;
  end;
end;

procedure OldCeilingLogSound(sound: Integer);
begin
  OldCeilingLog := OldCeilingLog + 'S' + IntToStr(sound) + ';';
end;

procedure OldCeilingLogRemove;
begin
  OldCeilingLog := OldCeilingLog + 'R;';
end;

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

function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;
begin
  Result := OldLowestCeilingSurrounding;
end;

function P_FindHighestFloorSurrounding(sec: Psector_t): fixed_t;
begin
  Result := OldHighestFloorSurrounding;
end;

procedure OldDoomMoveCeiling(ceiling: Pceiling_t);
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
        begin
          if (ceiling._type <> silentCrushAndRaise) and
             (ceiling._type <> genSilentCrusher) then
            S_StartSound(@ceiling.sector.soundorg, Ord(sfx_stnmov));
        end;

        if res = pastdest then
        begin
          case ceiling._type of
            raiseToHighest,
            genCeiling:
              P_RemoveActiveCeiling(ceiling);
            genCeilingChgT,
            genCeilingChg0,
            genCeilingChg:
              begin
                if ceiling._type <> genCeilingChg then
                begin
                  ceiling.sector.special := ceiling.newspecial;
                  //jff 3/14/98 transfer old special field as well
                  ceiling.sector.oldspecial := ceiling.oldspecial;
                end;
                ceiling.sector.ceilingpic := ceiling.texture;
                P_RemoveActiveCeiling(ceiling);
              end;

            silentCrushAndRaise:
              begin
                S_StartSound(@ceiling.sector.soundorg, Ord(sfx_pstop));
                ceiling.direction := -1;
              end;
            fastCrushAndRaise,
            crushAndRaise,
            genSilentCrusher,
            genCrusher:
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
        begin
          if (ceiling._type <> silentCrushAndRaise) and
             (ceiling._type <> genSilentCrusher) then
            S_StartSound(@ceiling.sector.soundorg, Ord(sfx_stnmov));
        end;

        if res = pastdest then
        begin
          case ceiling._type of
          // 02/09/98 jff change slow crushers' speed back to normal
          // start back up
            genSilentCrusher,
            genCrusher:
              begin
                if ceiling.oldspeed < CEILSPEED * 3 then
                  ceiling.speed := ceiling.oldspeed;
                ceiling.direction := 1; //jff 2/22/98 make it go back up!
              end;
            silentCrushAndRaise:
              begin
                S_StartSound(@ceiling.sector.soundorg, Ord(sfx_pstop));
                ceiling.speed := CEILSPEED;
                ceiling.direction := 1;
              end;
            crushAndRaise:
              begin
                ceiling.speed := CEILSPEED;
                ceiling.direction := 1;
              end;
            fastCrushAndRaise:
              begin
                ceiling.direction := 1;
              end;
          // in the of ceiling mover/changer, change the texture
          // then remove the active ceiling
            genCeilingChgT,
            genCeilingChg0,
            genCeilingChg:
              begin
                if ceiling._type <> genCeilingChg then
                begin
                  ceiling.sector.special := ceiling.newspecial;
                  //jff add to fix bug in special transfers from changes
                  ceiling.sector.oldspecial := ceiling.oldspecial;
                end;
                ceiling.sector.ceilingpic := ceiling.texture;
                P_RemoveActiveCeiling(ceiling);
              end;
            lowerAndCrush,
            lowerToFloor,
            lowerToLowest,
            lowerToMaxFloor,
            genCeiling:
              P_RemoveActiveCeiling(ceiling);
          end;
        end
        else // ( res <> pastdest )
        begin
          if res = crushed then
          begin
            case ceiling._type of
            //jff 02/08/98 slow down slow crushers on obstacle
              genCrusher,
              genSilentCrusher:
                if ceiling.oldspeed < CEILSPEED * 3 then
                  ceiling.speed := CEILSPEED div 8;
              silentCrushAndRaise,
              crushAndRaise,
              lowerAndCrush:
                ceiling.speed := CEILSPEED div 8;
            end;
          end;
        end;
      end;
  end;
end;

procedure OldDoomSpawnCeiling(ceiling: Pceiling_t; sec: Psector_t; _type: ceiling_e);
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

      silentCrushAndRaise,
      crushAndRaise:
        begin
          ceiling.crush := true;
          ceiling.topheight := sec.ceilingheight;
          ceiling.bottomheight := sec.floorheight;
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

      lowerToLowest:
        begin
          ceiling.bottomheight := P_FindLowestCeilingSurrounding(sec);
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
        end;

      lowerToMaxFloor:
        begin
          ceiling.bottomheight := P_FindHighestFloorSurrounding(sec);
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
        end;
    end;
end;

procedure OldStrifeSpawnCeiling(ceiling: Pceiling_t; sec: Psector_t; _type: ceiling_e);
begin
    case _type of
      fastCrushAndRaise:
        begin
          // [STRIFE]: Speed of fast crushers increased by 2x!
          ceiling.crush := true;
          ceiling.topheight := sec.ceilingheight;
          ceiling.bottomheight := sec.floorheight + (8 * FRACUNIT);
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED * 4; // [STRIFE]
        end;

      lowerAndCrush:
        begin
          // [STRIFE] lowerAndCrush doesn't seem to have crushed in DOOM,
          // but it was certainly made to do so in Strife! It is also
          // changed to lower all the way to the floor.
          ceiling.crush := true;
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
          ceiling.bottomheight := sec.floorheight;
        end;

      silentCrushAndRaise,
      crushAndRaise:
        begin
          ceiling.topheight := sec.ceilingheight;
          ceiling.bottomheight := sec.floorheight;
          if _type <> lowerToFloor then
            ceiling.bottomheight := ceiling.bottomheight + 8 * FRACUNIT;
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
        end;
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

      lowerToLowest:
        begin
          ceiling.bottomheight := P_FindLowestCeilingSurrounding(sec);
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
        end;

      lowerToMaxFloor:
        begin
          ceiling.bottomheight := P_FindHighestFloorSurrounding(sec);
          ceiling.direction := -1;
          ceiling.speed := CEILSPEED;
        end;
    end;
end;

function OldDoomWakesUp(_type: ceiling_e): Boolean;
begin
  // Reactivate in-stasis ceilings...for certain types.
  case _type of
    fastCrushAndRaise,
    silentCrushAndRaise,
    crushAndRaise:
      result := true;
  else
    result := false;
  end;
end;

end.
