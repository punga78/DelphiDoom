//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//
// DESCRIPTION:
//  ACTORDEF lump parser (Custom defined enemies)
//  SNDINFO lump parser (Sound aliases)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit sc_actordef;

interface

uses
  System.SysUtils,
  d_delphi,
  info_h,
  DelphiDoom.ActorDef.Intf;

//==============================================================================
//
// SC_ParseSndInfoLumps
//
//==============================================================================
procedure SC_ParseSndInfoLumps;

//==============================================================================
//
// SC_ParseActordefLumps
//
//==============================================================================
procedure SC_ParseActordefLumps;

//==============================================================================
//
// SC_ParseActordefLump
//
//==============================================================================
procedure SC_ParseActordefLump(const in_text: string);

//==============================================================================
//
// SC_Init
//
//==============================================================================
procedure SC_Init;

//==============================================================================
//
// SC_ShutDown
//
//==============================================================================
procedure SC_ShutDown;

//==============================================================================
//
// SC_ConfigureActorDef
//
//==============================================================================
procedure SC_ConfigureActorDef(const AParser: IActorDefParser; const AParseSoundInfo: TProc<string>;
  const ASounds: IActorDefSoundResolver);

//==============================================================================
//
// SC_SoundAlias
//
//==============================================================================
function SC_SoundAlias(const snd: string): string;


//==============================================================================
//
// SC_GetActordefDeclaration
//
//==============================================================================
function SC_GetActordefDeclaration(const m: Pmobjinfo_t): string;

var
  decorate_as_actordef: boolean = true;

implementation

uses
  TypInfo,
  doomdef,
  {$IFDEF DOOM_OR_STRIFE}
  d_items,
  {$ENDIF}
  {$IFDEF HERETIC}
  p_pspr_h,
  {$ENDIF}
  d_main,
  c_cmds,
  deh_base,
  deh_main,
  m_fixed,
  i_system,
  {$IFNDEF FPC}
  i_startup,
  {$ENDIF}
  info,
  info_common,
  r_renderstyle,
  r_translations,
  {$IFDEF HEXEN}
  sounddata,
  {$ENDIF}
  sounds,
  sc_consts,
  sc_engine,
  sc_states,
  sc_tokens,
  sc_evaluate_actor,
  sc_utils,
  p_pspr,
  p_spec,
  p_mobj_h,
  p_gender,
  ps_main,
  w_pak,
  w_wad;

const
  ACTORDEFLUMPNAME = 'ACTORDEF';
  DECORATELUMPNAME = 'DECORATE';
  SNDINFOLUMPNAME = 'SNDINFO';

var
  GActorDefParser: IActorDefParser;
  GParseSoundInfo: TProc<string>;
  GSounds: IActorDefSoundResolver;
  sound_tx: string;

//==============================================================================
//
// SC_ConfigureActorDef
//
//==============================================================================
procedure SC_ConfigureActorDef(const AParser: IActorDefParser; const AParseSoundInfo: TProc<string>;
  const ASounds: IActorDefSoundResolver);
begin
  GActorDefParser := AParser;
  GParseSoundInfo := AParseSoundInfo;
  GSounds := ASounds;
end;

//==============================================================================
//
// SC_SoundAlias
//
//==============================================================================
function SC_SoundAlias(const snd: string): string;
begin
  if not Assigned(GSounds) then
    I_Error('SC_SoundAlias(): the sound aliases are not configured (ComposeEngine was not called)');
  Result := GSounds.Resolve(snd);
end;

//==============================================================================
//
// SC_ParseActordefLump
//
//==============================================================================
procedure SC_ParseActordefLump(const in_text: string);
begin
  if not Assigned(GActorDefParser) then
    I_Error('SC_ParseActordefLump(): the ACTORDEF parser is not configured (ComposeEngine was not called)');
  GActorDefParser.Parse(in_text);
end;

//==============================================================================
//
// SC_RetrieveSndInfo
//
//==============================================================================
procedure SC_RetrieveSndInfo(const in_text: string);
var
  LText: string;
begin
  LText := SC_Preprocess(in_text, false);
  if sound_tx = '' then
    sound_tx := LText
  else
    sound_tx := sound_tx + #13#10 + LText;
end;

//==============================================================================
//
// SC_ParseSndInfoLumps
//
//==============================================================================
procedure SC_ParseSndInfoLumps;
var
  i: integer;
begin
  if not Assigned(GParseSoundInfo) then
    I_Error('SC_ParseSndInfoLumps(): SNDINFO is not configured (ComposeEngine was not called)');

// Retrive sndinfo lumps for sound alias list
  sound_tx := '';
  for i := 0 to W_NumLumps - 1 do
  begin
    if char8tostring(W_GetNameForNum(i)) = SNDINFOLUMPNAME then
    begin
      if sound_tx = '' then
        sound_tx := W_TextLumpNum(i)
      else
        sound_tx := sound_tx + #13#10 + W_TextLumpNum(i);
    end;
  end;

  PAK_StringIterator(SNDINFOLUMPNAME, SC_RetrieveSndInfo);
  PAK_StringIterator(SNDINFOLUMPNAME + '.txt', SC_RetrieveSndInfo);

  GParseSoundInfo(sound_tx);
end;

//==============================================================================
//
// SC_ParseActordefLumps
//
//==============================================================================
procedure SC_ParseActordefLumps;
var
  i: integer;
  lumplist: TDNumberList;
begin
  SC_ParseStatedefLump;

  {$IFNDEF FPC}
  SUC_Disable;
  {$ENDIF}

// Retrive actordef lumps
  lumplist := TDNumberList.Create;
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = ACTORDEFLUMPNAME then
      lumplist.Add(i);

  if decorate_as_actordef then
    for i := 0 to W_NumLumps - 1 do
      if char8tostring(W_GetNameForNum(i)) = DECORATELUMPNAME then
        lumplist.Add(i);

  {$IFNDEF FPC}
  SUC_SecondaryProgressInit(lumplist.Count);
  {$ENDIF}

  for i := 0 to lumplist.Count - 1 do
  begin
    {$IFNDEF FPC}
    SUC_SecondaryProgress(i);
    {$ENDIF}
    SC_ParseActordefLump(W_TextLumpNum(lumplist[i]));
  end;

  {$IFNDEF FPC}
  SUC_SecondaryProgressDone;
  {$ENDIF}
  PAK_StringIterator(ACTORDEFLUMPNAME, SC_ParseActordefLump);
  PAK_StringIterator(ACTORDEFLUMPNAME + '.txt', SC_ParseActordefLump);

  if decorate_as_actordef then
  begin
    PAK_StringIterator(DECORATELUMPNAME, SC_ParseActordefLump);
    PAK_StringIterator(DECORATELUMPNAME + '.txt', SC_ParseActordefLump);
  end;

  lumplist.Free;

  {$IFNDEF FPC}
  SUC_Enable;
  {$ENDIF}
end;

//==============================================================================
//
// SC_Init
//
//==============================================================================
procedure SC_Init;
begin
  SC_InitActorEvaluator;
  SC_InitConsts;
  C_AddCmd('DEH_PrintActordef, PrintActordef', @DEH_PrintActordef);
  C_AddCmd('DEH_SaveActordef, SaveActordef', @DEH_SaveActordef);
  C_AddCmd('DEH_PrintWeapondef, PrintWeapondef', @DEH_PrintWeapondef);
  C_AddCmd('DEH_SaveWeapondef, SaveWeapondef', @DEH_SaveWeapondef);
  C_AddCmd('DEH_PrintStateOwners, PrintStateOwners', @DEH_PrintStateOwners);
  C_AddCmd('DEH_SaveStateOwners, SaveStateOwners', @DEH_SaveStateOwners);
end;

//==============================================================================
//
// SC_ShutDown
//
//==============================================================================
procedure SC_ShutDown;
begin
  statenames.Free;
  SC_ShutDownConsts;
  SC_ShutDownActorEvaluator;
end;

//==============================================================================
//
// SC_GetActordefDeclaration
//
//==============================================================================
function SC_GetActordefDeclaration(const m: Pmobjinfo_t): string;
begin
  result := DEH_ActorDeclaration(pDiff(m, mobjinfo, SizeOf(mobjinfo_t)));
end;

end.
