// TEMPORARY HARNESS (savegame comparison; not for the build of the game): the state machine of the
// hook that G_Ticker calls. It depends only on units that exist in the old commit 31ee71e3 as well as
// in master (no parity unit), so the same hook builds the OLD and the NEW executable.
//
//  - leveltime 100: every line with a special is USED by the player; leveltime 200: every line with a
//    special is CROSSED (an exit asked by a line is undone: gameaction is put back);
//  - leveltime 600, 1000, 1500, 2500: a savegame is written ("save_lt_<N>"); with -hload <what> the first
//    tic loads <what> and only 1500 and 2500 are saved, as "load_lt_<N>";
//  - leveltime 2600: I_Quit (clean exit).
// Writing and loading are done by the game unit (callbacks): G_DoSaveGameInFile, G_DoSaveGame(path),
// SV_SaveGame..., because they are not exported by g_game.

{$I Doom32.inc}

unit harness_sweep;

interface

type
  /// ABaseName is save_lt_<N> or load_lt_<N>; ASlot is 0..3 for save_lt and 4..5 for load_lt (Hexen)
  THarnessSaveProc = procedure(const ABaseName: string; ASlot: integer);
  /// AArgument is what follows -hload on the command line
  THarnessLoadProc = procedure(const AArgument: string);

procedure HarnessTick(AGameTic, ALevelTime: integer; ASave: THarnessSaveProc; ALoad: THarnessLoadProc);

type
  THarnessPathProc = procedure(const APath: string);

/// Writes a trace, makes the directory, calls ASaver in a try/except and writes a trace after
procedure HarnessSaveDirectory(const ADirectory: string; ASaver: THarnessPathProc);

procedure HarnessMakeDirectory(const AName: string);

function HarnessToInteger(const AText: string): integer;

implementation

uses
  SysUtils,
  i_system,
  m_argv,
  doomdata,
  doomdef,
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

const
  SAVE_TIMES: array[0..3] of integer = (600, 1000, 1500, 2500);
  QUIT_TIME = 2600;
  USE_TIME = 100;
  CROSS_TIME = 200;

var
  hs_init: boolean = false;
  hs_loadargument: string = '';
  hs_loaded: boolean = false;
  hs_use_done: boolean = false;
  hs_cross_done: boolean = false;
  hs_quit_posted: boolean = false;
  hs_saved: array[0..3] of boolean;
  hs_use_count: integer = 0;
  hs_cross_count: integer = 0;
  hs_errors: integer = 0;
  hs_exits: integer = 0;

procedure HarnessMakeDirectory(const AName: string);
begin
  if not DirectoryExists(AName) then
    CreateDir(AName);
end;

function HarnessToInteger(const AText: string): integer;
begin
  result := StrToIntDef(AText, 0);
end;

procedure HarnessWriteSweep;
var
  f: TextFile;
begin
  AssignFile(f, 'harness_sweep.txt');
  Rewrite(f);
  writeln(f, 'use lines=', hs_use_count, ' cross lines=', hs_cross_count,
    ' exceptions=', hs_errors, ' exitsundone=', hs_exits);
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
        inc(hs_use_count);
      end
      else
      begin
{$IFDEF HEXEN}
        P_ActivateLine(@lines[i], mo, 0, SPAC_CROSS);
{$ELSE}
        P_CrossSpecialLine(i, 0, mo);
{$ENDIF}
        inc(hs_cross_count);
      end;
    except
      inc(hs_errors);
    end;
    // an exit line asks G_ExitLevel: the level would be over before any thinker ticks
    if gameaction <> action then
    begin
      gameaction := action;
      inc(hs_exits);
    end;
    mo := players[0].mo;
    if mo = nil then
      break;
  end;
  HarnessWriteSweep;
end;

var
  hs_trace_last: integer = -1;

// harness_trace.txt: a line every 100 of leveltime, and one for every save, so that a run that
// does not reach a save can be understood afterwards (gamestate 0 = GS_LEVEL)
procedure HarnessTrace(const AText: string);
var
  f: TextFile;
begin
  AssignFile(f, 'harness_trace.txt');
  if FileExists('harness_trace.txt') then
    Append(f)
  else
    Rewrite(f);
  writeln(f, AText);
  CloseFile(f);
end;

procedure HarnessSaveDirectory(const ADirectory: string; ASaver: THarnessPathProc);
begin
  HarnessTrace('before mkdir ' + ADirectory + ' cwd=' + GetCurrentDir);
  try
    // not ForceDirectories: with a relative name of one component it raises "Unable to create directory"
    if not DirectoryExists(ADirectory) then
      CreateDir(ADirectory);
    HarnessTrace('after mkdir exists=' + IntToStr(Ord(DirectoryExists(ADirectory))));
    ASaver(ADirectory);
    HarnessTrace('after save');
  except
    on E: Exception do
      HarnessTrace('EXCEPTION ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure HarnessTick(AGameTic, ALevelTime: integer; ASave: THarnessSaveProc; ALoad: THarnessLoadProc);
var
  i, p: integer;
begin
  if ALevelTime div 100 <> hs_trace_last then
  begin
    hs_trace_last := ALevelTime div 100;
    HarnessTrace(Format('gametic=%d leveltime=%d gamestate=%d gameaction=%d',
      [AGameTic, ALevelTime, Ord(gamestate), Ord(gameaction)]));
  end;

  if not hs_init then
  begin
    hs_init := true;
    p := M_CheckParm('-hload');
    if (p > 0) and (p < myargc - 1) then
      hs_loadargument := myargv[p + 1];
  end;

  if (hs_loadargument <> '') and not hs_loaded then
  begin
    if AGameTic <= 2 then
    begin
      hs_loaded := true;
      ALoad(hs_loadargument);
    end;
    exit;
  end;

  if (hs_loadargument = '') and (ALevelTime >= USE_TIME) and not hs_use_done then
  begin
    hs_use_done := true;
    HarnessSweep(true);
  end;
  if (hs_loadargument = '') and (ALevelTime >= CROSS_TIME) and not hs_cross_done then
  begin
    hs_cross_done := true;
    HarnessSweep(false);
  end;

  for i := 0 to High(SAVE_TIMES) do
    if (ALevelTime >= SAVE_TIMES[i]) and not hs_saved[i] then
    begin
      hs_saved[i] := true;
      HarnessTrace(Format('save %d at leveltime=%d gametic=%d', [SAVE_TIMES[i], ALevelTime, AGameTic]));
      if hs_loadargument = '' then
        ASave('save_lt_' + IntToStr(SAVE_TIMES[i]), i)
      else if i >= 2 then
        ASave('load_lt_' + IntToStr(SAVE_TIMES[i]), i + 2);
    end;

  if (ALevelTime >= QUIT_TIME) and not hs_quit_posted then
  begin
    hs_quit_posted := true;
    I_Quit;
  end;
end;

end.
