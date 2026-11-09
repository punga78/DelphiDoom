// TEMPORARY HARNESS of issue #153 (not for the build of the game): runs the OLD code of T_MovePlane
// (copied as it was before Libs\Thinkers: the one of the game and the one of udmf_floor.pas) next
// to the NEW one, the facades T_MovePlane (p_floor.pas, not Hexen) and TH_MovePlane (udmf_floor.pas),
// on copies of engine sectors and the same cases. P_ChangeSector and P_DynamicSlope are replaced
// by a fake host that blocks a sector when its gap is smaller than a given height and writes
// every call in a log. See docs\RUN-153.md. PP_Run replaces the host of the planes and ends the program.
//
// For each case: old code on a copy of the sector -> new code (the facade) on another copy ->
// compare result, heights and the log of the calls. A report is written to plane_parity.txt.

{$I Doom32.inc}

unit plane_parity;

{$Q-}
{$R-}

interface

/// Runs every comparison, writes plane_parity.txt (the last line is "mismatches=N") and halts
procedure PP_Run;

implementation

uses
  SysUtils,
  d_delphi,
  doomdef,
  m_fixed,
  r_defs,
  p_spec,
{$IFNDEF HEXEN}
  p_floor,
{$ENDIF}
{$IFDEF DOOM}
  g_game,
{$ENDIF}
  udmf_floor,
  DelphiDoom.Thinkers.Plane.Intf,
  DelphiDoom.Engine.Plane.Services;

type
  TPPMoveFunction = function(sector: Psector_t; speed: fixed_t; dest: fixed_t;
    crush: boolean; floorOrCeiling: integer; direction: integer): result_e;

  TPPHost = class(TInterfacedObject, IPlaneSectorHost)
  public
    BlockAll: boolean;
    ThingHeight: integer;
    Log: string;
    function ChangeSector(ASector: Pointer; ACrush: Boolean): Boolean;
    procedure PlaneMoved(ASector: Pointer);
  end;

var
  pp_old_host: TPPHost;
  pp_new_host: TPPHost;
  pp_report: TextFile;
  pp_mismatches: integer = 0;

function TPPHost.ChangeSector(ASector: Pointer; ACrush: Boolean): Boolean;
var
  s: Psector_t;
begin
  s := Psector_t(ASector);
  result := BlockAll or (s.ceilingheight - s.floorheight < ThingHeight);
  Log := Log + Format('C%d/%d/%d>%d;', [s.floorheight, s.ceilingheight, Ord(ACrush), Ord(result)]);
end;

procedure TPPHost.PlaneMoved(ASector: Pointer);
begin
  Log := Log + 'M;';
end;

// what the old code called
function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;
begin
  result := pp_old_host.ChangeSector(sector, crunch);
end;

procedure P_DynamicSlope(const sec: Psector_t);
begin
  pp_old_host.PlaneMoved(sec);
end;

{$IFDEF DOOM}
// the old code of the game: old_doom.txt
function PPOld_GameMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
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
{$ENDIF}

{$IFDEF HERETIC}
// the old code of the game: old_heretic.txt
function PPOld_GameMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
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
{$ENDIF}

{$IFDEF STRIFE}
// the old code of the game: old_strife.txt
function PPOld_GameMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
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
{$ENDIF}

// the old code of udmf_floor.pas
function PPOld_UdmfMovePlane(sector: Psector_t; speed: fixed_t; dest: fixed_t;
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


//==============================================================================
//
// PP_ResultCode
//
//==============================================================================
function PP_ResultCode(r: result_e): integer;
begin
{$IFDEF HEXEN}
  case r of
    RES_CRUSHED: result := 1;
    RES_PASTDEST: result := 2;
  else
    result := 0;
  end;
{$ELSE}
  case r of
    crushed, RES_CRUSHED: result := 1;
    pastdest, RES_PASTDEST: result := 2;
  else
    result := 0;
  end;
{$ENDIF}
end;

//==============================================================================
//
// PP_Next
//
//==============================================================================
function PP_Next(var state: cardinal; amin, amax: integer): integer;
begin
  state := cardinal(state * cardinal(1664525) + cardinal(1013904223));
  result := amin + integer((state shr 8) mod cardinal(amax - amin + 1));
end;

//==============================================================================
//
// PP_Compare
//
// 20000 random single steps and 300 complete movements for the pair of functions
//
//==============================================================================
procedure PP_Compare(const name: string; oldproc, newproc: TPPMoveFunction; seed: cardinal);
var
  state: cardinal;
  i, step, kind, dir, speed, dest, start: integer;
  crush: boolean;
  so, sn: sector_t;
  ro, rn: integer;
  total, bad: integer;

  procedure _Check(const what: string);
  begin
    inc(total);
    if (ro <> rn) or (so.floorheight <> sn.floorheight) or (so.ceilingheight <> sn.ceilingheight) or
       (pp_old_host.Log <> pp_new_host.Log) then
    begin
      inc(bad);
      inc(pp_mismatches);
      if bad <= 20 then
        writeln(pp_report, Format('%s MISMATCH %s: result %d/%d floor %d/%d ceiling %d/%d old=[%s] new=[%s]',
          [name, what, ro, rn, so.floorheight, sn.floorheight, so.ceilingheight, sn.ceilingheight,
           pp_old_host.Log, pp_new_host.Log]));
    end;
  end;

  procedure _Both(const what: string);
  begin
    pp_old_host.Log := '';
    pp_new_host.Log := '';
    ro := PP_ResultCode(oldproc(@so, speed, dest, crush, kind, dir));
    rn := PP_ResultCode(newproc(@sn, speed, dest, crush, kind, dir));
    _Check(what);
  end;

begin
  state := seed;
  total := 0;
  bad := 0;
  FillChar(so, SizeOf(so), 0);
  FillChar(sn, SizeOf(sn), 0);
  pp_old_host.ThingHeight := 3 * FRACUNIT;
  pp_new_host.ThingHeight := 3 * FRACUNIT;

  for i := 1 to 20000 do
  begin
    so.floorheight := PP_Next(state, -8 * FRACUNIT, 8 * FRACUNIT);
    so.ceilingheight := so.floorheight + PP_Next(state, 0, 8 * FRACUNIT);
    sn := so;
    speed := PP_Next(state, 0, 4 * FRACUNIT);
    dest := PP_Next(state, -10 * FRACUNIT, 10 * FRACUNIT);
    crush := PP_Next(state, 0, 1) = 1;
    kind := PP_Next(state, 0, 2);
    dir := PP_Next(state, -2, 2);
    pp_old_host.BlockAll := PP_Next(state, 0, 4) = 0;
    pp_new_host.BlockAll := pp_old_host.BlockAll;
    _Both(Format('single %d (kind %d, dir %d)', [i, kind, dir]));
  end;

  for i := 1 to 300 do
  begin
    so.floorheight := PP_Next(state, -4 * FRACUNIT, 4 * FRACUNIT);
    so.ceilingheight := so.floorheight + PP_Next(state, 0, 8 * FRACUNIT);
    sn := so;
    kind := PP_Next(state, 0, 1);
    speed := PP_Next(state, 1, 2 * FRACUNIT);
    dest := PP_Next(state, -10 * FRACUNIT, 10 * FRACUNIT);
    crush := PP_Next(state, 0, 1) = 1;
    pp_old_host.BlockAll := PP_Next(state, 0, 6) = 0;
    pp_new_host.BlockAll := pp_old_host.BlockAll;
    if kind = 0 then
      start := so.floorheight
    else
      start := so.ceilingheight;
    if dest >= start then
      dir := 1
    else
      dir := -1;
    for step := 1 to 400 do
    begin
      _Both(Format('movement %d step %d', [i, step]));
      if rn = 2 then
        break;
    end;
  end;

  writeln(pp_report, Format('%s: %d cases, %d different', [name, total, bad]));
end;

//==============================================================================
//
// PP_Run
//
//==============================================================================
procedure PP_Run;
var
  newintf: IPlaneSectorHost;
begin
  AssignFile(pp_report, 'plane_parity.txt');
  Rewrite(pp_report);
  pp_old_host := TPPHost.Create;
  pp_old_host._AddRef;
  pp_new_host := TPPHost.Create;
  newintf := pp_new_host;
  // from now on the facades of the engine ask the fake host
  P_ConfigurePlanes(newintf);
  try
{$IFNDEF HEXEN}
{$IFDEF DOOM}
    demoplayback := false;
    PP_Compare('game (modern)', PPOld_GameMovePlane, T_MovePlane, 1);
    demoplayback := true; // demoversion is 0 here: an old version of the engine
    PP_Compare('game (old version)', PPOld_GameMovePlane, T_MovePlane, 2);
    demoplayback := false;
{$ELSE}
    PP_Compare('game', PPOld_GameMovePlane, T_MovePlane, 1);
{$ENDIF}
{$ENDIF}
    PP_Compare('udmf', PPOld_UdmfMovePlane, TH_MovePlane, 3);
    writeln(pp_report, Format('mismatches=%d', [pp_mismatches]));
  finally
    CloseFile(pp_report);
  end;
  Halt(0);
end;

end.
