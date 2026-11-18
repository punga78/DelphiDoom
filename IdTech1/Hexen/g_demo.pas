//------------------------------------------------------------------------------
//
//  DelphiHexen is a source port of the game Hexen and it is
//  based on original Linux Doom as published by "id Software", on
//  Hexen source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit g_demo;

interface

uses
  DelphiDoom.Engine.Platform.Intf,
  d_ticcmd;

//==============================================================================
//
// G_FinishedDemoPlayback
//
//==============================================================================
procedure G_FinishedDemoPlayback;

//==============================================================================
//
// G_DoPlayDemo
//
//==============================================================================
procedure G_DoPlayDemo;

//==============================================================================
//
// G_ReadDemoTiccmd
//
//==============================================================================
procedure G_ReadDemoTiccmd(cmd: Pticcmd_t);

//==============================================================================
//
// G_WriteDemoTiccmd
//
//==============================================================================
procedure G_WriteDemoTiccmd(cmd: Pticcmd_t);

//==============================================================================
//
// G_DeferedPlayDemo
//
//==============================================================================
function G_DeferedPlayDemo(const name: string): boolean;

//==============================================================================
//
// G_CmdPlayDemo
//
//==============================================================================
procedure G_CmdPlayDemo(const name: string);

{ Only called by startup code. }

//==============================================================================
//
// G_RecordDemo
//
//==============================================================================
procedure G_RecordDemo(const name: string);

//==============================================================================
//
// G_BeginRecording
//
//==============================================================================
procedure G_BeginRecording;

//==============================================================================
//
// G_TimeDemo
//
//==============================================================================
procedure G_TimeDemo(const name: string);

//==============================================================================
//
// G_CheckDemoStatus
//
//==============================================================================
function G_CheckDemoStatus: boolean;

var
  demoversion: byte;

//==============================================================================
//
// G_ConfigureFiles
// The files, given by the composition root
//
//==============================================================================
procedure G_ConfigureFiles(const AFiles: IEngineFiles);

implementation

uses
  DelphiDoom.Demo.Types,
  DelphiDoom.Demo.Profiles,
  DelphiDoom.Demo.HeaderCodec,
  DelphiDoom.Demo.CommandCodec,
  d_delphi,
  c_cmds,
  d_main,
  d_event,
  g_game,
  i_system,
  info,
  m_rnd,
  m_argv,
  p_mobj_h,
  doomdef,
  w_wad,
  z_zone;

var
  // given by the composition root
  g_files_ref: IEngineFiles = nil;

//==============================================================================
//
// G_ConfigureFiles
//
//==============================================================================
procedure G_ConfigureFiles(const AFiles: IEngineFiles);
begin
  g_files_ref := AFiles;
end;

//==============================================================================
//
// G_Files
//
//==============================================================================
function G_Files: IEngineFiles;
begin
  if g_files_ref = nil then
    I_Error('G_ConfigureFiles() was not called: the files are missing');
  result := g_files_ref;
end;

//
// DEMO PLAYBACK
//
const
  DEMOMARKER = $80;

var
  compatibility_done: boolean;

var
  demoname: string;
  demobuffer: PByteArray;
  demo_p: PByteArray;
  demoend: PByte;

//==============================================================================
//
// G_FinishedDemoPlayback
//
//==============================================================================
procedure G_FinishedDemoPlayback;
begin
  TGameSession.DemoPlayback := false;
  // Restore old compatibility mode
  TGameSession.CompatibilityMode := TGameSession.OldCompatibilityMode;
end;

(*
===================
=
= G_CheckDemoStatus
=
= Called after a death or level completion to allow demos to be cleaned up
= Returns true if a new demo loop action will take place
===================
*)

//==============================================================================
//
// G_CheckDemoStatus
//
//==============================================================================
function G_CheckDemoStatus: boolean;
var
  endtime: integer;
begin
  if TGameSession.TimingDemo then
  begin
    endtime := I_GetTime;
    // The result goes to the log and the program ends like after a single demo: with I_Error it was a
    // message box that waited for a click while the worker threads kept running (#147)
    printf('G_CheckDemoStatus(): timed %d gametics in %d realtics'#13#10, [TGameSession.GameTic, endtime - starttime]);
    TGameSession.TimingDemo := false;
    TGameSession.SingleDemo := true;
  end;

  if TGameSession.DemoPlayback then
  begin
    if TGameSession.SingleDemo then
      I_Quit;

    Z_Free(demoBuffer);
    G_FinishedDemoPlayback;
    TGameSession.ResetForNewGame;
    TMainRoutines.D_AdvanceDemo;
    result := true;
    exit;
  end;

  if TGameSession.DemoRecording then
  begin
    demo_p[0] := DEMOMARKER;
    demo_p := @demo_p[1];

    G_Files.WriteFile(demoname, demobuffer, pDiff(demo_p, demobuffer, SizeOf(byte)));
    Z_Free(demobuffer);
    TGameSession.DemoRecording := false;
    I_Error('G_CheckDemoStatus(): Demo %s recorded', [demoname]);
  end;

  result := false;
end;

//==============================================================================
//
// G_ReadDemoTiccmd
//
//==============================================================================
procedure G_ReadDemoTiccmd(cmd: Pticcmd_t);
var
  LPosition: System.PByte;
  LCommand: TDemoCommand;
begin
  if demo_p[0] = DEMOMARKER then
  begin
    // end of demo data stream
    G_CheckDemoStatus;
    exit;
  end;

  LPosition := System.PByte(demo_p);
  TDemoCommandCodec.Read(LPosition, dlHeretic, demoversion, false, LCommand);
  demo_p := PByteArray(LPosition);

  cmd.forwardmove := LCommand.ForwardMove;
  cmd.sidemove := LCommand.SideMove;
  cmd.angleturn := LCommand.AngleTurn;
  cmd.buttons := LCommand.Buttons;
  cmd.lookfly := LCommand.LookFly;
  cmd.arti := LCommand.Arti;
  cmd.lookleftright := LCommand.LookLeftRight;
  cmd.jump_crouch := LCommand.JumpCrouch;
  cmd.lookupdown16 := LCommand.LookUpDown16; // JVAL Smooth Look Up/Down
  cmd.lookupdown := LCommand.LookUpDown; // JVAL unused :)
end;

//==============================================================================
// G_IncreaseDemoBuffer
//
// DEMO RECORDING
//
// Increase the size of the demo buffer to allow unlimited demos
//
//==============================================================================
procedure G_IncreaseDemoBuffer;
var
  current_length: integer;
  new_demobuffer: PByteArray;
  new_demop: PByteArray;
  new_length: integer;
begin
  // Find the current size

  current_length := NativeInt(demoend) - NativeInt(demobuffer);

  // Generate a new buffer twice the size
  new_length := current_length + $80000;

  new_demobuffer := Z_Malloc2(new_length, PU_STATIC, nil);
  if new_demobuffer = nil then
    G_CheckDemoStatus;

  new_demop := @new_demobuffer[NativeInt(demo_p) - NativeInt(demobuffer)];

  // Copy over the old data

  memcpy(new_demobuffer, demobuffer, current_length);

  // Free the old buffer and point the demo pointers at the new buffer.

  Z_Free(demobuffer);

  demobuffer := new_demobuffer;
  demo_p := new_demop;
  demoend := @demobuffer[new_length];
end;

//==============================================================================
//
// G_WriteDemoTiccmd
//
//==============================================================================
procedure G_WriteDemoTiccmd(cmd: Pticcmd_t);
var
  LCommand: TDemoCommand;
begin
  if gamekeydown[Ord('q')] then // press q to end demo recording
    G_CheckDemoStatus;

  LCommand := Default(TDemoCommand);
  LCommand.ForwardMove := cmd.forwardmove;
  LCommand.SideMove := cmd.sidemove;
  LCommand.AngleTurn := cmd.angleturn;
  LCommand.Buttons := cmd.buttons;
  LCommand.LookFly := cmd.lookfly;
  LCommand.Arti := cmd.arti;
  LCommand.LookLeftRight := cmd.lookleftright;
  LCommand.JumpCrouch := cmd.jump_crouch;
  LCommand.LookUpDown16 := cmd.lookupdown16; // JVAL Smooth Look Up/Down
  TDemoCommandCodec.Write(System.PByte(demo_p), dlHeretic, LCommand);

  if NativeInt(demo_p) >= NativeInt(demoend) - 2 * SizeOf(ticcmd_t) then
    G_IncreaseDemoBuffer;

  G_ReadDemoTiccmd(cmd);  // make SURE it is exactly the same
end;

//==============================================================================
//
// G_RecordDemo
//
//==============================================================================
procedure G_RecordDemo(const name: string);
var
  i: integer;
  maxsize: integer;
begin
  TGameSession.UserGame := false;
  demoname := name;
  if CharPos('.', demoname) = 0 then
    demoname := demoname + '.lmp';

  i := M_CheckParm ('-maxdemo');
  if (i <> 0) and (i < myargc - 1) then
    maxsize := atoi(myargv[i + 1]) * 1024
  else
    maxsize := SAVEGAMESIZE;

  repeat
    demobuffer := Z_Malloc2(maxsize, PU_STATIC, nil);
    if demobuffer = nil then
      maxsize := maxsize * 3 div 4;
  until demobuffer <> nil;

  demoend := @demobuffer[maxsize];

  TGameSession.DemoRecording := true;
  Info_Init(true); // JVAL: Start thinkers

end;

//==============================================================================
//
// G_BeginRecording
//
//==============================================================================
procedure G_BeginRecording;
var
  i: integer;
  LPosition: System.PByte;
  LHeader: TDemoHeader;
begin
  demo_p := demobuffer;
  demoversion := VERSION;

  LHeader := Default(TDemoHeader);
  LHeader.Version := VERSION;
  LHeader.Skill := Ord(TGameSession.GameSkill);
  LHeader.Episode := TGameSession.GameEpisode;
  LHeader.Map := TGameSession.GameMap;
  LHeader.Deathmatch := TGameSession.DeathMatch;
  LHeader.Respawn := TGameSession.RespawnParm;
  LHeader.Fast := TGameSession.FastParm;
  LHeader.NoMonsters := TGameSession.NoMonsters;
  LHeader.Compatibility := TGameSession.CompatibilityMode;
  LHeader.SpawnRandomMonsters := spawnrandommonsters;
  LHeader.Seed := M_GetSystemRandomSeed;
  LHeader.ConsolePlayer := TGameSession.ConsolePlayer;
  for i := 0 to MAXPLAYERS - 1 do
    LHeader.PlayersInGame[i] := TGameSession.PlayerInGame[i];

  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.Write(LPosition, TDemoProfiles.Hexen(MAXPLAYERS), LHeader);
  demo_p := PByteArray(LPosition);
end;

//
// G_PlayDemo
//
var
  defdemoname: string;
  externaldemo: boolean = false;

//==============================================================================
//
// G_DoPlayExternalDemo
//
//==============================================================================
function G_DoPlayExternalDemo(const name: string): boolean;
var
  dmname: string;
begin
  dmname := name;
  if not fexists(dmname) then
    if M_CheckParmCDROM then
      dmname := CD_WORKDIR + dmname;
  if fexists(dmname) then
  begin
    externaldemo := true;
    defdemoname := dmname;
    TGameSession.GameAction := ga_playdemo;
    printf('Playing demo %s'#13#10, [defdemoname]);
    result := true;
    exit;
  end;
  result := false;
end;

//==============================================================================
//
// G_DeferedPlayDemo
//
//==============================================================================
function G_DeferedPlayDemo(const name: string): boolean;
var
  dmname: string;
  dmname2: string;
  defdemoname8: char8_t;
  i: integer;
  pdot: integer;
begin
  dmname := name;
  for i := 0 to 9 do
    if itoa(i) = name then
    begin
      sprintf(dmname, 'demo%d', [i]);
      break;
    end;

  pdot := CharPos('.', dmname);
  if ((Length(dmname) <= 8) and (pdot = 0)) or ((pdot < 9) and (pdot <> 0)) then
  begin
    TWadRoutines.ExtractFileBase8(dmname, defdemoname8);
    defdemoname := TWadRoutines.char8tostring(defdemoname8);
    if TWadRoutines.W_CheckNumForName(defdemoname) >= 0 then
    begin
      externaldemo := false;
      TGameSession.GameAction := ga_playdemo;
      printf('Playing demo %s'#13#10, [defdemoname]);
      result := true;
      exit;
    end;
  end;

  // JVAL
  // Playdemo command also looks for a filename in current or CD_WORK directory
  dmname2 := dmname;
  if pdot = 0 then
    dmname := dmname + '.lmp';
  if G_DoPlayExternalDemo(dmname) then
  begin
    result := true;
    exit;
  end;

  if pdot = 0 then
  begin
    dmname := dmname2 + '.dem';
    if G_DoPlayExternalDemo(dmname) then
    begin
      result := true;
      exit;
    end;
  end;

  I_Warning('G_DeferedPlayDemo(): Can not find demo %s.'#13#10, [defdemoname]);
  result := false;
end;

//==============================================================================
//
// G_CmdPlayDemo
//
//==============================================================================
procedure G_CmdPlayDemo(const name: string);
begin
  if G_DeferedPlayDemo(name) then
    C_ExecuteCmd('closeconsole', '1');
end;

//==============================================================================
//
// G_DoPlayDemo
//
//==============================================================================
procedure G_DoPlayDemo;
var
  skill: skill_t;
  i, episode, map: integer;
  lump: integer;
  len: integer;
  oldspawnrandommonsters: boolean;
  LProfile: TDemoHeaderProfile;
  LPosition: System.PByte;
  LHeader: TDemoHeader;
begin
  TGameSession.GameAction := ga_nothing;
  if externaldemo then
    len := G_Files.ReadFile(defdemoname, pointer(demobuffer))
  else
  begin
    lump := TWadRoutines.W_GetNumForName(defdemoname);
    demobuffer := TWadRoutines.W_CacheLumpNum(lump, PU_STATIC);
    len := TWadRoutines.W_LumpLength(lump);
  end;

  demo_p := demobuffer;
  demoend := @demo_p[len];

  LProfile := TDemoProfiles.Hexen(MAXPLAYERS);
  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.ReadVersion(LPosition, LProfile.Magic, demoversion);
  demo_p := PByteArray(LPosition);

  if demoversion < VERSION142 then
  begin
    I_Warning('G_DoPlayDemo(): Demo is from an unsupported game version = %d.%.*d' + #13#10,
      [demo_p[0] div 100, 2, demo_p[0] mod 100]);
    TGameSession.GameAction := ga_nothing;
    exit;
  end
  else if demoversion <> VERSION then
    I_Warning('G_DoPlayDemo(): Demo is from a partial supported game version = %d.%.*d' + #13#10,
      [demo_p[0] div 100, 2, demo_p[0] mod 100]);

  LPosition := System.PByte(demo_p);
  TDemoHeaderCodec.Read(LPosition, LProfile, false, LHeader);
  demo_p := PByteArray(LPosition);

  skill := skill_t(LHeader.Skill);
  episode := LHeader.Episode;
  map := LHeader.Map;
  TGameSession.DeathMatch := LHeader.Deathmatch;
  TGameSession.RespawnParm := LHeader.Respawn;
  TGameSession.FastParm := LHeader.Fast;
  TGameSession.NoMonsters := LHeader.NoMonsters;

  TGameSession.OldCompatibilityMode := TGameSession.CompatibilityMode;
  TGameSession.CompatibilityMode := LHeader.Compatibility;

  oldspawnrandommonsters := spawnrandommonsters;
  spawnrandommonsters := LHeader.SpawnRandomMonsters;

  if LHeader.HasSeed then
    M_SetSystemRandomSeed(LHeader.Seed)
  else
    M_SetSystemRandomSeed(0);

  TGameSession.ConsolePlayer := LHeader.ConsolePlayer;

  for i := 0 to MAXPLAYERS - 1 do
    TGameSession.PlayerInGame[i] := LHeader.PlayersInGame[i];

  if TGameSession.PlayerInGame[1] then
  begin
    TGameSession.NetGame := true;
    TGameSession.NetDemo := true;
  end;

  TGameSession.PreparingDemoPlayback := true;
  // don't spend a lot of time in loadlevel if not singledemo
  TGameSession.Precache := TGameSession.SingleDemo; // JVAL original code: precache := false
  G_InitNew(skill, episode, map);
  TGameSession.PreparingDemoPlayback := false;
  spawnrandommonsters := oldspawnrandommonsters;  // Back to default
  TGameSession.Precache := true;
  TGameSession.UserGame := false;
  TGameSession.DemoPlayback := true;
  Info_Init(true); // JVAL: Start thinkers

  compatibility_done := false;

end;

//==============================================================================
//
// G_TimeDemo
//
//==============================================================================
procedure G_TimeDemo(const name: string);
begin
  TGameSession.TimingDemo := true;
  singletics := true;

  defdemoname := name;
  TGameSession.GameAction := ga_playdemo;
end;

end.
