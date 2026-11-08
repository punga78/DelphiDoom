{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the planes as the old code      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldPlanes;

// The statements of the functions are the ones of T_MovePlane (Doom, Heretic and Strife p_floor.pas),
// of TH_MovePlane and TH_FloorWaggle (udmf_floor.pas) before the library, copied as they were. Only
// what they call is replaced: the sector is a record with the same field names, P_ChangeSector and
// P_DynamicSlope go to a fake host and G_PlayingEngineVersion is a variable of the test. The tests
// run the old and the new code side by side on the same sectors
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Plane.Intf;

type
  fixed_t = Integer;

  sector_t = record
    floorheight: fixed_t;
    ceilingheight: fixed_t;
  end;
  Psector_t = ^sector_t;

  result_e = (
    ok,
    crushed,
    pastdest,
    RES_OK,
    RES_CRUSHED,
    RES_PASTDEST
  );

  /// <summary>floorWaggle_t of the old code, with the sector of the test</summary>
  TOldWaggle = record
    sector: Psector_t;
    originalHeight: fixed_t;
    accumulator: fixed_t;
    accDelta: fixed_t;
    targetScale: fixed_t;
    scale: fixed_t;
    scaleDelta: fixed_t;
    ticker: Integer;
    state: Integer;
    /// <summary>Set where the old code removes the thinker (and frees the sector)</summary>
    removed: Boolean;
  end;
  POldWaggle = ^TOldWaggle;

const
  VERSION115 = 115;
  WGLSTATE_EXPAND = 1;
  WGLSTATE_STABLE = 2;
  WGLSTATE_REDUCE = 3;

var
  /// <summary>What the old code asks (P_ChangeSector, P_DynamicSlope): set by the test before a call</summary>
  OldPlaneHost: IPlaneSectorHost;
  /// <summary>What G_PlayingEngineVersion gives</summary>
  OldEngineVersion: Integer = 207;
  /// <summary>The bobbing table of the old waggle (FloatBobOffsets): set by the test</summary>
  OldBobOffsets: array[0..63] of Integer;

function OldDoomMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
function OldHereticMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
function OldStrifeMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
function OldUdmfMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; dir: integer): result_e;
procedure OldFloorWaggle(waggle: POldWaggle);

implementation

uses
  DelphiDoom.MathCore.FixedMath;

const
  FRACBITS = 16;

function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;
begin
  Result := OldPlaneHost.ChangeSector(sector, crunch);
end;

procedure P_DynamicSlope(const sec: Psector_t);
begin
  OldPlaneHost.PlaneMoved(sec);
end;

function G_PlayingEngineVersion: Integer;
begin
  Result := OldEngineVersion;
end;

function FixedMul(const a, b: fixed_t): fixed_t;
begin
  Result := TFixedMath.Mul(a, b);
end;

function _SHR(const x: integer; const bits: integer): integer;
begin
  Result := TFixedMath.ShiftRight(x, bits);
end;


// from T_MovePlane (old_doom.txt)
function OldDoomMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
var
  lastpos: fixed_t;
  flag: boolean;
begin
  case floorOrCeiling of
    0:
      begin
        // FLOOR
        if direction = -1 then
        begin
        // DOWN
          if sector.floorheight - speed < dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := pastdest;
            exit;
          end
          else
          begin
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end;
          end;
        end
        else if direction = 1 then
        begin
        // UP
          if (G_PlayingEngineVersion > VERSION115) and (dest > sector.ceilingheight) then
            dest := sector.ceilingheight;

          if sector.floorheight + speed > dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := pastdest;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight + speed;
            flag := P_ChangeSector(sector, crush);
            if flag then
            begin
              if G_PlayingEngineVersion <= VERSION115 then
                if crush then
                begin
                  result := crushed;
                  exit;
                end;
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end
          end;
        end;
      end;
    1:
      begin
      // CEILING
        if direction = -1 then
        begin
        // DOWN
          if (G_PlayingEngineVersion > VERSION115) and (dest < sector.floorheight) then
            dest := sector.floorheight;

          if sector.ceilingheight - speed < dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := pastdest;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.ceilingheight;
            sector.ceilingheight := sector.ceilingheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              if crush then
              begin
                result := crushed;
                exit;
              end;
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end;
          end;
        end
        else if direction = 1 then
        begin
        // UP
          if sector.ceilingheight + speed > dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := pastdest;
            exit;
          end
          else
          begin
            sector.ceilingheight := sector.ceilingheight + speed;
            P_ChangeSector(sector, crush);
          end;
        end;
      end;
  end;
  P_DynamicSlope(sector); // JVAL: Slopes
  result := ok;
end;

// from T_MovePlane (old_heretic.txt)
function OldHereticMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
var
  lastpos: fixed_t;
begin
  case floorOrCeiling of
    0:
      begin
        // FLOOR
        if direction = -1 then
        begin
        // DOWN
          if sector.floorheight - speed < dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := pastdest;
            exit;
          end
          else
          begin
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end;
          end;
        end
        else if direction = 1 then
        begin
        // UP
          if sector.floorheight + speed > dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := pastdest;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight + speed;
            if P_ChangeSector(sector, crush) then
            begin
              if crush then
              begin
                result := crushed;
                exit;
              end;
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end
          end;
        end;
      end;
    1:
      begin
      // CEILING
        if direction = -1 then
        begin
        // DOWN
          if sector.ceilingheight - speed < dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := pastdest;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.ceilingheight;
            sector.ceilingheight := sector.ceilingheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              if crush then
              begin
                result := crushed;
                exit;
              end;
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end;
          end;
        end
        else if direction = 1 then
        begin
        // UP
          if sector.ceilingheight + speed > dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := pastdest;
            exit;
          end
          else
          begin
//            lastpos := sector.ceilingheight;
            sector.ceilingheight := sector.ceilingheight + speed;
            P_ChangeSector(sector, crush);
// UNUSED
//#if 0
//    if (flag == true)
//    {
//        sector->ceilingheight = lastpos;
//        P_ChangeSector(sector,crush);
//        return crushed;
//    }
//#endif
          end;
        end;
      end;
  end;
  P_DynamicSlope(sector); // JVAL: Slopes
  result := ok;
end;

// from T_MovePlane (old_strife.txt)
function OldStrifeMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; direction: integer): result_e;
var
  lastpos: fixed_t;
  flag: boolean;
begin
  case floorOrCeiling of
    0:
      begin
        // FLOOR
        if direction = -1 then
        begin
        // DOWN
          if sector.floorheight - speed < dest then
          begin
            //lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
            {  sector.floorheight := lastpos;
              P_ChangeSector(sector, crush); }
            //return crushed;
            end;
            result := pastdest;
            exit;
          end
          else
          begin
            //lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
{              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;  }
            end;
          end;
        end
        else if direction = 1 then
        begin
        // UP
          if dest > sector.ceilingheight then
            dest := sector.ceilingheight;

          if sector.floorheight + speed > dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := pastdest;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight + speed;
            flag := P_ChangeSector(sector, crush);
            if flag then
            begin
              if crush then
              begin
                result := crushed;
                exit;
              end;
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end
          end;
        end;
      end;
    1:
      begin
      // CEILING
        if direction = -1 then
        begin
        // DOWN
          if dest < sector.floorheight then
            dest := sector.floorheight;

          if sector.ceilingheight - speed < dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := pastdest;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.ceilingheight;
            sector.ceilingheight := sector.ceilingheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              if crush then
              begin
                result := crushed;
                exit;
              end;
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
              result := crushed;
              exit;
            end;
          end;
        end
        else if direction = 1 then
        begin
        // UP
          if sector.ceilingheight + speed > dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := pastdest;
            exit;
          end
          else
          begin
            sector.ceilingheight := sector.ceilingheight + speed;
            P_ChangeSector(sector, crush);
          end;
        end;
      end;
  end;
  P_DynamicSlope(sector); // JVAL: Slopes
  result := ok;
end;

// from TH_MovePlane (old_udmf.txt)
function OldUdmfMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
  crush: boolean; floorOrCeiling: integer; dir: integer): result_e;
var
  lastpos: fixed_t;
begin
  case floorOrCeiling of
    0:
      begin
        // FLOOR
        if dir = -1 then
        begin
        // DOWN
          if sector.floorheight - speed < dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := RES_CRUSHED;
              exit;
            end;
          end;
        end
        else if dir = 1 then
        begin
        // UP
          if sector.floorheight + speed > dest then
          begin
            lastpos := sector.floorheight;
            sector.floorheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.floorheight;
            sector.floorheight := sector.floorheight + speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.floorheight := lastpos;
              P_ChangeSector(sector, crush);
              result := RES_CRUSHED;
              exit;
            end
          end;
        end;
      end;
    1:
      begin
      // CEILING
        if dir = -1 then
        begin
        // DOWN
          if sector.ceilingheight - speed < dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
          // COULD GET CRUSHED
            lastpos := sector.ceilingheight;
            sector.ceilingheight := sector.ceilingheight - speed;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
              result := RES_CRUSHED;
              exit;
            end;
          end;
        end
        else if dir = 1 then
        begin
        // UP
          if sector.ceilingheight + speed > dest then
          begin
            lastpos := sector.ceilingheight;
            sector.ceilingheight := dest;
            if P_ChangeSector(sector, crush) then
            begin
              sector.ceilingheight := lastpos;
              P_ChangeSector(sector, crush);
            //return crushed;
            end;
            result := RES_PASTDEST;
            exit;
          end
          else
          begin
            sector.ceilingheight := sector.ceilingheight + speed;
            P_ChangeSector(sector, crush);
          end;
        end;
      end;
  end;
  P_DynamicSlope(sector); // JVAL: Slopes
  result := RES_OK;
end;

// TH_FloorWaggle of udmf_floor.pas: the body is the old one; what it called after the end of
// the waggle (the specialdata of the sector, P_TagFinished, P_RemoveThinker) is the flag "removed"
procedure OldFloorWaggle(waggle: POldWaggle);
const
  FloatBobOffsetsMask = 63;
begin
  case waggle.state of
    WGLSTATE_EXPAND:
      begin
        waggle.scale := waggle.scale + waggle.scaleDelta;
        if waggle.scale >= waggle.targetScale then
        begin
          waggle.scale := waggle.targetScale;
          waggle.state := WGLSTATE_STABLE;
        end;
      end;
    WGLSTATE_REDUCE:
      begin
        waggle.scale := waggle.scale - waggle.scaleDelta;
        if waggle.scale <= 0 then
        begin // Remove
          waggle.sector.floorheight := waggle.originalHeight;
          P_ChangeSector(waggle.sector, true);
          waggle.removed := true;
          exit;
        end;
      end;
    WGLSTATE_STABLE:
      begin
        if waggle.ticker <> -1 then
        begin
          dec(waggle.ticker); // JVAL SOS
          if waggle.ticker <> 0 then
            waggle.state := WGLSTATE_REDUCE;
        end;
      end;
  end;

  waggle.accumulator := waggle.accumulator + waggle.accDelta;
  waggle.sector.floorheight := waggle.originalHeight +
    FixedMul(OldBobOffsets[_SHR(waggle.accumulator, FRACBITS) and FloatBobOffsetsMask], waggle.scale);
  P_ChangeSector(waggle.sector, true);
end;

end.
