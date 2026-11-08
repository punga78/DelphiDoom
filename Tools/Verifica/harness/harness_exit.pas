// TEMPORARY HARNESS (issues #149, #152, #153, #154; not for the build of the game): ends the game by
// itself, with a clean exit, so that the parity reports (written in the finalization of the harness
// units) are produced, and before that runs an "activation sweep": the player stands still in the
// -warp runs, so at HARNESS_USE_TIC every line with a special is used and at HARNESS_CROSS_TIC every
// line with a special is crossed, by the player, to make doors, platforms and teleports move.
// G_Ticker calls HarnessExitCheck(gametic). Change the constants to run longer or to move the sweeps.

{$I Doom32.inc}

unit harness_exit;

interface

const
  /// Tic at which the game quits (WM_DESTROY, the normal way out): 3000 for Hexen (no demos)
{$IFDEF HEXEN}
  HARNESS_EXIT_TIC = 3000;
{$ELSE}
  HARNESS_EXIT_TIC = 4000;
{$ENDIF}
  /// Tic of the sweep that uses every line with a special
  HARNESS_USE_TIC = 100;
  /// Tic of the sweep that crosses every line with a special
  HARNESS_CROSS_TIC = 200;

procedure HarnessExitCheck(ATic: integer);

implementation

uses
  SysUtils,
  i_system,
  doomdata,
  d_event,
  d_player,
  g_game,
  p_mobj_h,
  p_setup,
  r_defs,
{$IFNDEF HEXEN}
  p_switch,
{$ENDIF}
  p_spec;

var
  harness_posted: boolean = false;
  harness_use_done: boolean = false;
  harness_cross_done: boolean = false;
  harness_use_count: integer = 0;
  harness_cross_count: integer = 0;
  harness_errors: integer = 0;
  harness_exits: integer = 0;

procedure HarnessWriteSweep;
var
  f: TextFile;
begin
  AssignFile(f, 'harness_sweep.txt');
  Rewrite(f);
  writeln(f, 'use lines=', harness_use_count, ' cross lines=', harness_cross_count,
    ' exceptions=', harness_errors, ' exitsundone=', harness_exits);
  CloseFile(f);
end;

procedure HarnessSweep(AUse: boolean);
var
  i: integer;
  mo: Pmobj_t;
  action: gameaction_t;
begin
  mo := players[0].mo;
  if mo = nil then
    exit;
  for i := 0 to numlines - 1 do
  begin
    if lines[i].special = 0 then
      continue;
    action := gameaction;
    try
      if AUse then
      begin
{$IFDEF HEXEN}
        P_ActivateLine(@lines[i], mo, 0, SPAC_USE);
{$ELSE}
        P_UseSpecialLine(mo, @lines[i], 0);
{$ENDIF}
        inc(harness_use_count);
      end
      else
      begin
{$IFDEF HEXEN}
        P_ActivateLine(@lines[i], mo, 0, SPAC_CROSS);
{$ELSE}
        P_CrossSpecialLine(i, 0, mo);
{$ENDIF}
        inc(harness_cross_count);
      end;
    except
      inc(harness_errors);
    end;
    // an exit line (or a map teleport) asks G_ExitLevel: gameaction = ga_completed is run at the start of
    // the next G_Ticker, before any thinker ticks, and the level would be over: undo it, the sweep
    // is for the thinkers (the exit lines are counted all the same)
    if gameaction <> action then
    begin
      gameaction := action;
      inc(harness_exits);
    end;
    // a teleport or a death moves or removes the player: take the new one
    mo := players[0].mo;
    if mo = nil then
      break;
  end;
  HarnessWriteSweep;
end;

procedure HarnessExitCheck(ATic: integer);
begin
  if (ATic >= HARNESS_USE_TIC) and not harness_use_done then
  begin
    harness_use_done := true;
    HarnessSweep(true);
  end;
  if (ATic >= HARNESS_CROSS_TIC) and not harness_cross_done then
  begin
    harness_cross_done := true;
    HarnessSweep(false);
  end;
  if (ATic >= HARNESS_EXIT_TIC) and not harness_posted then
  begin
    harness_posted := true;
    I_Quit;
  end;
end;

end.
