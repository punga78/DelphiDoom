{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the floors as the old code      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldFloors;

// The statements are the ones of the case of EV_DoFloor of Doom and of Strife, of the changes
// of T_MoveFloor at the destination (the same text in the two games) and of the values of
// EV_BuildStairs (p_floor.pas of each game) before the library, copied as they were. Only what
// they touch is replaced: sector, side and floor are records of the test with the same field
// names, the heights around the sector, the model sector and the version of the engine are
// variables of the test. floor_e is the one of Strife, which has every name of the one of Doom
{$Q-}
{$R-}

interface

type
  fixed_t = Integer;

  Psector_t = ^sector_t;
  sector_t = record
    floorheight: fixed_t;
    ceilingheight: fixed_t;
    floorpic: Integer;
    special: Integer;
    oldspecial: Integer;
    linecount: Integer;
    tag: Integer;
  end;

  Pside_t = ^side_t;
  side_t = record
    bottomtexture: Integer;
  end;

  Pline_t = ^line_t;
  line_t = record
    frontsector: Psector_t;
  end;

  floor_e = (
    lowerFloor,
    lowerFloorToLowest,
    turboLower,
    raiseFloor,
    raiseFloorToNearest,
    lowerFloorToNearest,
    lowerFloor24,
    lowerFloor32Turbo,
    raiseToTexture,
    lowerAndChange,
    raiseFloor64,
    raiseFloor24,
    raiseFloor32Turbo,
    raiseFloor24AndChange,
    raiseFloorCrush,
    raiseFloorTurbo,
    donutRaise,
    raiseFloor512,
    raiseFloor512AndChange,
    genFloor,
    genFloorChg,
    genFloorChg0,
    genFloorChgT,
    buildStair,
    genBuildStair,
    FLEV_LOWERFLOOR
  );

  stair_e = (
    build8,
    turbo16,
    buildDown16,
    stairOther
  );

  Pfloormove_t = ^floormove_t;
  floormove_t = record
    _type: floor_e;
    crush: boolean;
    sector: Psector_t;
    direction: integer;
    newspecial: integer;
    oldspecial: smallint;
    texture: smallint;
    floordestheight: fixed_t;
    speed: fixed_t;
  end;

const
  FRACUNIT = 65536;
  FLOORSPEED = FRACUNIT;
  VERSION115 = 115;
  MAXINT = $7fffffff;
  OLD_FLOOR_SIDES = 4;

var
  /// <summary>What G_PlayingEngineVersion gives</summary>
  OldFloorEngineVersion: Integer = 207;
  /// <summary>What the P_Find... of the old code give</summary>
  OldFloorHighestFloor: fixed_t;
  OldFloorLowestFloor: fixed_t;
  OldFloorNextLowestFloor: fixed_t;
  OldFloorNextHighestFloor: fixed_t;
  OldFloorLowestCeiling: fixed_t;
  /// <summary>The model sector of lowerAndChange (nil: none)</summary>
  OldFloorModelSector: Psector_t;
  /// <summary>The lines of the sector: two sided or not, and the lower textures of their two sides</summary>
  OldFloorTwoSided: array[0..OLD_FLOOR_SIDES - 1] of Boolean;
  OldFloorSides: array[0..OLD_FLOOR_SIDES - 1, 0..1] of side_t;
  /// <summary>The heights of the textures</summary>
  textureheight: array[0..7] of fixed_t;

/// <summary>The case of EV_DoFloor of Doom on a new floor (kind set, crush false)</summary>
procedure OldDoomSpawnFloor(floor: Pfloormove_t; sec: Psector_t; line: Pline_t; floortype: floor_e);
/// <summary>The case of EV_DoFloor of Strife on a new floor (kind set, crush false)</summary>
procedure OldStrifeSpawnFloor(floor: Pfloormove_t; sec: Psector_t; line: Pline_t; floortype: floor_e);
/// <summary>What T_MoveFloor of Doom and of Strife does to the sector of a floor that arrived</summary>
procedure OldFloorArrival(floor: Pfloormove_t);
/// <summary>The values of EV_BuildStairs of Doom: first and next are two zeroed floors</summary>
procedure OldDoomStairs(_type: stair_e; first, next: Pfloormove_t; out speed, stairsize: fixed_t);
/// <summary>The values of EV_BuildStairs of Strife: first and next are two zeroed floors</summary>
procedure OldStrifeStairs(_type: stair_e; first, next: Pfloormove_t; out speed, stairsize: fixed_t);

implementation

uses
  DelphiDoom.MathCore.FixedMath;

var
  sectors: Psector_t = nil;

function G_PlayingEngineVersion: Integer;
begin
  Result := OldFloorEngineVersion;
end;

function FixedInt(const x: integer): integer;
begin
  Result := TFixedMath.ToInteger(x);
end;

function P_FindHighestFloorSurrounding(sec: Psector_t): fixed_t;
begin
  Result := OldFloorHighestFloor;
end;

function P_FindLowestFloorSurrounding(sec: Psector_t): fixed_t;
begin
  Result := OldFloorLowestFloor;
end;

function P_FindNextLowestFloor(sec: Psector_t; currentheight: fixed_t): fixed_t;
begin
  Result := OldFloorNextLowestFloor;
end;

function P_FindNextHighestFloor(sec: Psector_t; currentheight: integer): fixed_t;
begin
  Result := OldFloorNextHighestFloor;
end;

function P_FindLowestCeilingSurrounding(sec: Psector_t): fixed_t;
begin
  Result := OldFloorLowestCeiling;
end;

function P_FindModelFloorSector(floordestheight: fixed_t; secnum: integer): Psector_t;
begin
  Result := OldFloorModelSector;
end;

function pDiff(const p1, p2: Pointer; const size: Integer): Integer;
begin
  Result := 0;
end;

function twoSided(sector: integer; line: integer): boolean;
begin
  Result := OldFloorTwoSided[line];
end;

function getSide(currentSector: integer; line: integer; side: integer): Pside_t;
begin
  Result := @OldFloorSides[line, side];
end;
procedure OldDoomSpawnFloor(floor: Pfloormove_t; sec: Psector_t; line: Pline_t; floortype: floor_e);
var
  i: integer;
  minsize: integer;
  side: Pside_t;
  secnum: integer;
begin
  secnum := 0;
    case floortype of
      lowerFloor:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindHighestFloorSurrounding(sec);
        end;
      //jff 02/03/30 support lowering floor by 24 absolute
      lowerFloor24:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 24 * FRACUNIT;
        end;
      //jff 02/03/30 support lowering floor by 32 absolute (fast)
      lowerFloor32Turbo:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := floor.sector.floorheight + 32 * FRACUNIT;
        end;
      lowerFloorToLowest:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindLowestFloorSurrounding(sec);
        end;
      //jff 02/03/30 support lowering floor to next lowest floor
      lowerFloorToNearest:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindNextLowestFloor(sec, floor.sector.floorheight);
        end;
      turboLower:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := P_FindHighestFloorSurrounding(sec);
          if floor.floordestheight <> sec.floorheight then
            floor.floordestheight := floor.floordestheight + 8 * FRACUNIT;
        end;
      raiseFloorCrush,
      raiseFloor:
        begin
          if floortype = raiseFloorCrush then
            floor.crush := true;
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindLowestCeilingSurrounding(sec);
          if floor.floordestheight > sec.ceilingheight then
            floor.floordestheight := sec.ceilingheight;
          if floortype = raiseFloorCrush then // if floor.crush then
            floor.floordestheight := floor.floordestheight - 8 * FRACUNIT;
        end;
      raiseFloorTurbo:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := P_FindNextHighestFloor(sec, sec.floorheight);
        end;
      raiseFloorToNearest:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindNextHighestFloor(sec, sec.floorheight);
        end;
      raiseFloor24:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 24 * FRACUNIT;
        end;
      // jff 2/03/30 support straight raise by 32 (fast)
      raiseFloor32Turbo:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := floor.sector.floorheight + 32 * FRACUNIT;
        end;
      raiseFloor512:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 512 * FRACUNIT;
        end;
      raiseFloor24AndChange:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 24 * FRACUNIT;
          sec.floorpic := line.frontsector.floorpic;
          sec.special := line.frontsector.special;
          //jff 3/14/98 transfer both old and new special
          sec.oldspecial := line.frontsector.oldspecial;
        end;
      raiseToTexture:
        begin
          if G_PlayingEngineVersion > VERSION115 then
            minsize := 32000 * FRACUNIT // Don't overflow
          else
            minsize := MAXINT;
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          for i := 0 to sec.linecount - 1 do
          begin
            if twoSided(secnum, i) then
            begin
              side := getSide(secnum, i, 0);
              if side.bottomtexture >= 0 then
                if textureheight[side.bottomtexture] < minsize then
                  minsize := textureheight[side.bottomtexture];
              side := getSide(secnum, i, 1);
              if side.bottomtexture >= 0 then
                if textureheight[side.bottomtexture] < minsize then
                  minsize := textureheight[side.bottomtexture];
            end;
          end;
          if G_PlayingEngineVersion <= VERSION115 then
            floor.floordestheight := floor.sector.floorheight + minsize
          else
          begin
            floor.floordestheight := FixedInt(floor.sector.floorheight) + FixedInt(minsize);
            if floor.floordestheight > 32000 then
              floor.floordestheight := 32000 * FRACUNIT
            else
              floor.floordestheight := floor.floordestheight * FRACUNIT;
          end;
        end;
      lowerAndChange:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindLowestFloorSurrounding(sec);
          floor.texture := sec.floorpic;

          // jff 1/24/98 make sure floor.newspecial gets initialized
          // in no surrounding sector is at floordestheight
          // -. should not affect compatibility <--
          floor.newspecial := sec.special;
          //jff 3/14/98 transfer both old and new special
          floor.oldspecial := sec.oldspecial;

          //jff 5/23/98 use model subroutine to unify fixes and handling
          sec := P_FindModelFloorSector(floor.floordestheight, pDiff(sec, sectors, SizeOf(sector_t)));
          if sec <> nil then
          begin
            floor.texture := sec.floorpic;
            floor.newspecial := sec.special;
            //jff 3/14/98 transfer both old and new special
            floor.oldspecial := sec.oldspecial;
          end;
        end;
    end;
end;

procedure OldStrifeSpawnFloor(floor: Pfloormove_t; sec: Psector_t; line: Pline_t; floortype: floor_e);
var
  i: integer;
  minsize: integer;
  side: Pside_t;
  secnum: integer;
begin
  secnum := 0;
    case floortype of
      lowerFloor:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindHighestFloorSurrounding(sec);
        end;
      //jff 02/03/30 support lowering floor by 24 absolute
      lowerFloor24:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 24 * FRACUNIT;
        end;
      //jff 02/03/30 support lowering floor by 32 absolute (fast)
      lowerFloor32Turbo:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := floor.sector.floorheight + 32 * FRACUNIT;
        end;
      lowerFloorToLowest:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindLowestFloorSurrounding(sec);
        end;
      //jff 02/03/30 support lowering floor to next lowest floor
      lowerFloorToNearest:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindNextLowestFloor(sec, floor.sector.floorheight);
        end;
      turboLower:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := P_FindHighestFloorSurrounding(sec);
        end;
      raiseFloorCrush,
      raiseFloor:
        begin
          if floortype = raiseFloorCrush then
            floor.crush := true;
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindLowestCeilingSurrounding(sec);
          if floor.floordestheight > sec.ceilingheight then
            floor.floordestheight := sec.ceilingheight;
          if floortype = raiseFloorCrush then // if floor.crush then
            floor.floordestheight := floor.floordestheight - 8 * FRACUNIT;
        end;
      raiseFloorTurbo:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := P_FindNextHighestFloor(sec, sec.floorheight);
        end;
      raiseFloorToNearest:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindNextHighestFloor(sec, sec.floorheight);
        end;
      raiseFloor64:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 64 * FRACUNIT;
        end;
      raiseFloor24:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 24 * FRACUNIT;
        end;
      // jff 2/03/30 support straight raise by 32 (fast)
      raiseFloor32Turbo:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED * 4;
          floor.floordestheight := floor.sector.floorheight + 32 * FRACUNIT;
        end;
      raiseFloor512:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 512 * FRACUNIT;
        end;
      raiseFloor24AndChange:
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 24 * FRACUNIT;
          sec.floorpic := line.frontsector.floorpic;
          sec.special := line.frontsector.special;
          //jff 3/14/98 transfer both old and new special
          sec.oldspecial := line.frontsector.oldspecial;
        end;
      raiseFloor512AndChange: // [STRIFE] New floor type
        begin
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := floor.sector.floorheight + 512 * FRACUNIT;
          sec.floorpic := line.frontsector.floorpic;
          sec.special := line.frontsector.special;
        end;
      raiseToTexture:
        begin
          minsize := 32000 * FRACUNIT; // Don't overflow
          floor.direction := 1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          for i := 0 to sec.linecount - 1 do
          begin
            if twoSided(secnum, i) then
            begin
              side := getSide(secnum, i, 0);
              if side.bottomtexture >= 0 then
                if textureheight[side.bottomtexture] < minsize then
                  minsize := textureheight[side.bottomtexture];
              side := getSide(secnum, i, 1);
              if side.bottomtexture >= 0 then
                if textureheight[side.bottomtexture] < minsize then
                  minsize := textureheight[side.bottomtexture];
            end;
          end;
          floor.floordestheight := FixedInt(floor.sector.floorheight) + FixedInt(minsize);
          if floor.floordestheight > 32000 then
            floor.floordestheight := 32000 * FRACUNIT
          else
            floor.floordestheight := floor.floordestheight * FRACUNIT;
        end;
      lowerAndChange:
        begin
          floor.direction := -1;
          floor.sector := sec;
          floor.speed := FLOORSPEED;
          floor.floordestheight := P_FindLowestFloorSurrounding(sec);
          floor.texture := sec.floorpic;

          // jff 1/24/98 make sure floor.newspecial gets initialized
          // in no surrounding sector is at floordestheight
          // -. should not affect compatibility <--
          floor.newspecial := sec.special;
          //jff 3/14/98 transfer both old and new special
          floor.oldspecial := sec.oldspecial;

          //jff 5/23/98 use model subroutine to unify fixes and handling
          sec := P_FindModelFloorSector(floor.floordestheight, pDiff(sec, sectors, SizeOf(sector_t)));
          if sec <> nil then
          begin
            floor.texture := sec.floorpic;
            floor.newspecial := sec.special;
            //jff 3/14/98 transfer both old and new special
            floor.oldspecial := sec.oldspecial;
          end;
        end;
    end;
end;

procedure OldFloorArrival(floor: Pfloormove_t);
begin
    if floor.direction = 1 then
    begin
      case floor._type of
        donutRaise:
          begin
            floor.sector.special := floor.newspecial;
            floor.sector.floorpic := floor.texture;
          end;
        genFloorChgT,
        genFloorChg0,
        genFloorChg:
          begin
            if floor._type <> genFloorChg then
            begin
              floor.sector.special := floor.newspecial;
              //jff add to fix bug in special transfers from changes
              floor.sector.oldspecial := floor.oldspecial;
            end;
            //fall thru
            floor.sector.floorpic := floor.texture;
          end;
      end;
    end
    else if floor.direction = -1 then
    begin
      case floor._type of
        lowerAndChange:
          begin
            floor.sector.special := floor.newspecial;
            floor.sector.floorpic := floor.texture;
          end;
        genFloorChgT,
        genFloorChg0,
        genFloorChg:
          begin
            if floor._type <> genFloorChg then
            begin
              floor.sector.special := floor.newspecial;
              //jff add to fix bug in special transfers from changes
              floor.sector.oldspecial := floor.oldspecial;
            end;
            //fall thru
            floor.sector.floorpic := floor.texture;
          end;
      end;
    end;

end;

procedure OldDoomStairs(_type: stair_e; first, next: Pfloormove_t; out speed, stairsize: fixed_t);
var
  floor: Pfloormove_t;
begin
  floor := first;
    floor.direction := 1;
    floor._type := buildStair;
    case _type of
      build8:
        begin
          speed := FLOORSPEED div 4;
          stairsize := 8 * FRACUNIT;
          if G_PlayingEngineVersion > VERSION115 then
            floor.crush := false;
        end;
      turbo16:
        begin
          speed := FLOORSPEED * 4;
          stairsize := 16 * FRACUNIT;
          if G_PlayingEngineVersion > VERSION115 then
            floor.crush := true;
        end;
      else
      begin
        speed := 0;
        stairsize := 0;
      end;
    end;
    floor.speed := speed;

  floor := next;
        floor.direction := 1;
        floor.speed := speed;
        floor._type := buildStair;
        if G_PlayingEngineVersion > VERSION115 then
          floor.crush := _type <> build8;
end;

procedure OldStrifeStairs(_type: stair_e; first, next: Pfloormove_t; out speed, stairsize: fixed_t);
var
  floor: Pfloormove_t;
  direction: integer;
begin
  case _type of
    build8:
      begin
        speed := FLOORSPEED div 4;
        stairsize := 8 * FRACUNIT;
        direction := 1;
      end;
    turbo16:
      begin
        speed := FLOORSPEED * 4;
        stairsize := 16 * FRACUNIT;
        direction := 1;
      end;
    buildDown16: // [STRIFE] New stair type
      begin
        speed := FLOORSPEED;
        stairsize := -16 * FRACUNIT;
        direction := -1;
      end;
  else
    begin
      speed := 0;
      stairsize := 0;
      direction := 0;
    end;
  end;

  floor := first;
    floor.direction := direction;
    floor.speed := speed;

  floor := next;
        floor.direction := direction;
        floor.speed := speed;
        floor._type := buildStair;
        floor.crush := _type <> build8;
end;

end.
