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

unit p_acs;




interface

uses
  d_delphi,
  d_think,
  p_mobj_h,
  r_defs,
  DelphiDoom.Acs.Intf,
  DelphiDoom.Acs.Machine.Intf;

type
  /// The thinker of a script that runs. The part after the thinker is a TAcsScript of the
  /// library (same layout: it is saved as it is); the machine works on it
  acs_t = record
    thinker: thinker_t;
    activator: Pmobj_t;
    line: Pline_t;
    side: integer;
    number: integer;
    infoIndex: integer;
    delayCount: integer;
    stack: array[0..31] of integer;
    stackPtr: integer;
    vars: array[0..9] of integer;
    ip: PInteger;
  end;
  Pacs_t = ^acs_t;

//==============================================================================
//
// P_PolyobjFinished
//
//==============================================================================
procedure P_PolyobjFinished(po: integer);

//==============================================================================
//
// P_TagFinished
//
//==============================================================================
procedure P_TagFinished(tag: integer);

//==============================================================================
//
// P_StartACS
//
//==============================================================================
function P_StartACS(number: integer; map: integer; args: PByteArray;
  activator: Pmobj_t; line: Pline_t; side: integer): boolean;

//==============================================================================
//
// P_SuspendACS
//
//==============================================================================
function P_SuspendACS(number: integer; map: integer): boolean;

//==============================================================================
//
// P_TerminateACS
//
//==============================================================================
function P_TerminateACS(number: integer; map: integer): boolean;

//==============================================================================
//
// P_StartLockedACS
//
//==============================================================================
function P_StartLockedACS(line: Pline_t; args: PByteArray; mo: Pmobj_t;
  side: integer): boolean;

//==============================================================================
//
// P_LoadACScripts
//
//==============================================================================
procedure P_LoadACScripts(const lump: integer);

var
  // where the object code of the map is: the saved scripts keep their position as an offset from here
  ActionCodeBase: PByteArray;

//==============================================================================
//
// P_ACSMachine
// The virtual machine of the scripts: the saved games read and write its state
//
//==============================================================================
function P_ACSMachine: IAcsMachine;

//==============================================================================
//
// TH_InterpretACS
//
//==============================================================================
procedure TH_InterpretACS(script: Pacs_t);

//==============================================================================
//
// P_CheckACSStore
//
//==============================================================================
procedure P_CheckACSStore;

//==============================================================================
//
// P_ACSInitNewGame
//
//==============================================================================
procedure P_ACSInitNewGame;

//==============================================================================
//
// P_ACSInit
//
//==============================================================================
procedure P_ACSInit;

//==============================================================================
//
// P_ACSShutDown
//
//==============================================================================
procedure P_ACSShutDown;

//==============================================================================
//
// P_ConfigureAcs
// Gives the unit the compiler of the scripts of the maps and the machine that runs them.
// The composition root calls it
//
//==============================================================================
procedure P_ConfigureAcs(const ACompiler: IAcsCompiler; const AMachine: IAcsMachine);

implementation

uses
  acs,
  DelphiDoom.Acs.Types,
  DelphiDoom.Acs.Machine.Types,
  doomdata,
  d_player,
  i_system,
  g_game,
  info_h,
  m_rnd,
  p_tick,
  p_inter,
  p_spec,
  p_setup,
  p_mobj,
  {$IFDEF HEXEN}
  p_things,
  {$ELSE}
  p_udmf,
  udmf_mobj,
  udmf_spec,
  udmf_things,
  {$ENDIF}
  po_man,
  r_data,
  s_sound,
  sounddata,
  sounds,
  {$IFDEF HEXEN}
  s_sndseq,
  xn_strings,
  {$ENDIF}
  doomdef,
  w_wad,
  z_zone;

const
  ACS_MAGIC = $534341;

var
  // given by the composition root (P_ConfigureAcs)
  acs_compiler: IAcsCompiler = nil;
  acs_vm: IAcsMachine = nil;

//==============================================================================
//
// ACS_Machine
//
//==============================================================================
function ACS_Machine: IAcsMachine;
begin
  if acs_vm = nil then
    I_Error('P_ACS: the ACS machine was not configured');
  result := acs_vm;
end;

//==============================================================================
//
// P_ACSMachine
//
//==============================================================================
function P_ACSMachine: IAcsMachine;
begin
  result := ACS_Machine;
end;

//==============================================================================
//
// ACS_LayoutIsValid
// The machine works on the memory of the thinker: the part after the thinker has to be laid out
// as the TAcsScript of the library
//
//==============================================================================
function ACS_LayoutIsValid: boolean;
var
  base: NativeUInt;
begin
  base := SizeOf(thinker_t);
  result :=
    (NativeUInt(@Pacs_t(nil).activator) = base) and
    (SizeOf(acs_t) = base + SizeOf(TAcsScript)) and
    (NativeUInt(@Pacs_t(nil).line) = base + NativeUInt(@PAcsScript(nil).Line)) and
    (NativeUInt(@Pacs_t(nil).side) = base + NativeUInt(@PAcsScript(nil).Side)) and
    (NativeUInt(@Pacs_t(nil).number) = base + NativeUInt(@PAcsScript(nil).Number)) and
    (NativeUInt(@Pacs_t(nil).infoIndex) = base + NativeUInt(@PAcsScript(nil).InfoIndex)) and
    (NativeUInt(@Pacs_t(nil).delayCount) = base + NativeUInt(@PAcsScript(nil).DelayCount)) and
    (NativeUInt(@Pacs_t(nil).stack) = base + NativeUInt(@PAcsScript(nil).Stack)) and
    (NativeUInt(@Pacs_t(nil).stackPtr) = base + NativeUInt(@PAcsScript(nil).StackPtr)) and
    (NativeUInt(@Pacs_t(nil).vars) = base + NativeUInt(@PAcsScript(nil).Vars)) and
    (NativeUInt(@Pacs_t(nil).ip) = base + NativeUInt(@PAcsScript(nil).Ip));
end;

//==============================================================================
//
// P_ConfigureAcs
//
//==============================================================================
procedure P_ConfigureAcs(const ACompiler: IAcsCompiler; const AMachine: IAcsMachine);
begin
  if not ACS_LayoutIsValid then
    I_Error('P_ConfigureAcs(): acs_t does not have the layout of TAcsScript');
  acs_compiler := ACompiler;
  acs_vm := AMachine;
end;

//==============================================================================
//
// TH_InterpretACS
//
//==============================================================================
procedure TH_InterpretACS(script: Pacs_t);
begin
  ACS_Machine.Execute(PAcsScript(System.PByte(script) + SizeOf(thinker_t)));
end;

//==============================================================================
//
// P_CompileACSScript
// The text of the lump becomes the object code of the script. A wrong script is a fatal
// error, as it was with the old compiler
//
//==============================================================================
function P_CompileACSScript(const lump: integer; out size: integer): pointer;
var
  src: string;
  source: System.TArray<Byte>;
  obj: System.TArray<Byte>;
  i: integer;
begin
  if acs_compiler = nil then
    I_Error('P_CompileACSScript(): the ACS compiler was not configured');

  src := W_TextLumpNum(lump);
  SetLength(source, Length(src));
  for i := 1 to Length(src) do
    source[i - 1] := Byte(Ord(src[i]));

  try
    obj := acs_compiler.Compile(itoa(lump) + '.acs', source);
  except
    on E: EAcsCompileException do
      I_Error('%s', [E.Message]);
  end;

  size := Length(obj);
  Result := Z_Malloc(Length(obj), PU_LEVEL, nil);
  Move(obj[0], Result^, Length(obj));
end;

//==============================================================================
//
// P_LoadACScripts
//
//==============================================================================
procedure P_LoadACScripts(const lump: integer);
var
  header: PInteger;
  size: integer;
  needscompile: boolean;
begin
  ActionCodeBase := nil;

  if lump >= W_NumLumps then
  begin
    ACS_Machine.Unload;
    exit;
  end;

  size := W_LumpLength(lump);
  needscompile := size < SizeOf(integer);
  header := W_CacheLumpNum(lump, PU_LEVEL);
  if not needscompile then
    needscompile := header^ <> ACS_MAGIC;

  if needscompile then
  begin
    if acc_isscriptlump(lump) then
      header := P_CompileACSScript(lump, size)
    else if acc_isscriptlump(lump + 1) then
      header := P_CompileACSScript(lump + 1, size);
  end;

  // not an object code (the lump is some other lump of the map): no scripts
  if (header = nil) or (size < SizeOf(integer) * 3) or (header^ <> ACS_MAGIC) then
  begin
    ACS_Machine.Unload;
    exit;
  end;

  ACS_Machine.Load(System.PByte(header), size);
  ActionCodeBase := PByteArray(ACS_Machine.CodeBase);
end;

//==============================================================================
//
// P_StartACS
//
//==============================================================================
function P_StartACS(number: integer; map: integer; args: PByteArray;
  activator: Pmobj_t; line: Pline_t; side: integer): boolean;
var
  arguments: TAcsArguments;
begin
  FillChar(arguments, SizeOf(arguments), 0);
  if args <> nil then
    PInteger(@arguments)^ := PInteger(args)^;
  try
    result := ACS_Machine.StartScript(number, map, arguments, activator, line, side);
  except
    on E: EAcsMachineException do
    begin
      I_Error('P_StartACS(): %s', [E.Message]);
      result := false;
    end;
  end;
end;

//==============================================================================
//
// P_CheckACSStore
//
// Scans the ACS store and executes all scripts belonging to the current
// map.
//
//==============================================================================
procedure P_CheckACSStore;
begin
  ACS_Machine.CheckStore;
end;

//==============================================================================
//
// P_StartLockedACS
//
//==============================================================================
function P_StartLockedACS(line: Pline_t; args: PByteArray; mo: Pmobj_t;
  side: integer): boolean;
var
  i: integer;
  lock: integer;
  newArgs: array[0..4] of byte;
  LockedBuffer: string;
begin
  if mo.player = nil then
  begin
    result := false;
    exit;
  end;

  lock := args[4];
  if lock <> 0 then
  begin
    {$IFDEF DOOM_OR_STRIFE}
    if not IsIntegerInRange(lock, 1, Ord(NUMCARDS)) or not Pplayer_t(mo.player).cards[lock - 1] then
    {$ENDIF}
    {$IFDEF HERETIC}
    if not IsIntegerInRange(lock, 1, Ord(NUMKEYCARDS)) or not Pplayer_t(mo.player).keys[lock - 1] then
    {$ENDIF}
    {$IFDEF HEXEN}
    if Pplayer_t(mo.player).keys and _SHL(1, lock - 1) = 0 then
    {$ENDIF}
    begin
      {$IFDEF DOOM_OR_STRIFE}
      if not IsIntegerInRange(lock, 1, Ord(NUMCARDS)) then
        LockedBuffer := 'YOU NEED A KEY'
      else
      {$ENDIF}
      {$IFDEF HERETIC}
      if not IsIntegerInRange(lock, 1, Ord(NUMKEYCARDS)) then
        LockedBuffer := 'YOU NEED A KEY'
      else
      {$ENDIF}
      sprintf(LockedBuffer, 'YOU NEED THE %s', [TextKeyMessages[lock - 1]]);
      {$IFDEF HEXEN}
      P_SetMessage(mo.player, LockedBuffer, true);
      {$ELSE}
      Pplayer_t(mo.player)._message := LockedBuffer;
      {$ENDIF}
      {$IFDEF DOOM_OR_STRIFE}
      S_StartSound(mo, Ord(sfx_oof));
      {$ENDIF}
      {$IFDEF HERETIC}
      S_StartSound(mo, Ord(sfx_plroof));
      {$ENDIF}
      {$IFDEF HEXEN}
      S_StartSound(mo, Ord(SFX_DOOR_LOCKED));
      {$ENDIF}
      result := false;
      exit;
    end;
  end;
  for i := 0 to 3 do
    newArgs[i] := args[i];

  newArgs[4] := 0;
  result := P_StartACS(newArgs[0], newArgs[1], @newArgs[2], mo, line, side);
end;


//==============================================================================
//
// P_TerminateACS
//
//==============================================================================
function P_TerminateACS(number: integer; map: integer): boolean;
begin
  result := ACS_Machine.TerminateScript(number);
end;

//==============================================================================
//
// P_SuspendACS
//
//==============================================================================
function P_SuspendACS(number: integer; map: integer): boolean;
begin
  result := ACS_Machine.SuspendScript(number);
end;

//==============================================================================
// P_ACSInitNewGame
//
// P_Init
//
//==============================================================================
procedure P_ACSInitNewGame;
begin
  ACS_Machine.InitNewGame;
end;

//==============================================================================
//
// P_TagFinished
//
//==============================================================================
procedure P_TagFinished(tag: integer);
begin
  ACS_Machine.TagFinished(tag);
end;

//==============================================================================
//
// P_PolyobjFinished
//
//==============================================================================
procedure P_PolyobjFinished(po: integer);
begin
  ACS_Machine.PolyobjectFinished(po);
end;

//==============================================================================
//
// P_ACSInit
//
//==============================================================================
procedure P_ACSInit;
begin
  ACS_Machine.Unload;
end;

//==============================================================================
//
// P_ACSShutDown
//
//==============================================================================
procedure P_ACSShutDown;
begin
  if acs_vm <> nil then
    acs_vm.Unload;
end;

end.