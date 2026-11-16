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
// DESCRIPTION:
//  Radix: the sounds of the craft (RX_PlayerEngineSound and the siren of
//  RX_PlayerThink, radix_player.pas of Rad-X): the engine, that plays again
//  when it ends (another sound with the afterburner or the maneuver jets), and
//  the siren of a craft with little shield and an enemy that can see it.
//  Rad-X gave each sound a thing of the map (ENGINESOUND, a new AMBIENTSOUND
//  for every siren) as its place. Here the place is a point that follows the
//  craft, as the sounds of the sectors have: no thing is born, so the random
//  numbers of the game and the saved games do not change.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_pilotsound;

interface

uses
  d_player,
  radix_playerstate;

//==============================================================================
//
// RX_PilotSoundsReset
// A level starts: the engines play from their beginning
//
//==============================================================================
procedure RX_PilotSoundsReset;

//==============================================================================
//
// RX_PilotEngineSound
// To call at every tic for a living craft
//
//==============================================================================
procedure RX_PilotEngineSound(const pnum: integer; const p: Pplayer_t; const rp: Pradixplayer_t);

//==============================================================================
//
// RX_PilotSiren
// To call at every tic for a living craft
//
//==============================================================================
procedure RX_PilotSiren(const pnum: integer; const p: Pplayer_t; const rp: Pradixplayer_t);

//==============================================================================
//
// RX_PilotMessageOrigin
// The place of the voice of a message, where the craft is now (messagesoundtarget
// of Rad-X): a place of its own, so that the voice and the weapons of the craft
// do not cut each other
//
//==============================================================================
function RX_PilotMessageOrigin(const pnum: integer; const p: Pplayer_t): pointer;

//==============================================================================
//
// RX_PilotSoundIndex
// The number of a sound of RADIX.DAT; -1 when the table does not have it
//
//==============================================================================
function RX_PilotSoundIndex(const name: string): integer;

implementation

uses
  d_delphi,
  d_think,
  doomdef,
  m_fixed,
  p_mobj,
  p_mobj_h,
  p_sight,
  p_tick,
  r_defs,
  s_sound,
  radix_logic,
  DelphiDoom.Radix.SoundPart;

const
  SND_ENGINE = 'SndEngine';
  SND_ENGINEAFTER = 'SndEngineAfter';
  SND_SIREN = 'SndSiren';
  // a sound whose length is not known is asked again after a second
  UNKNOWNDURATIONTICS = TICRATE;
  ATTACKINGWARNRANGE = 2048;

var
  engineorigins: array[0..MAXPLAYERS - 1] of degenmobj_t;
  sirenorigins: array[0..MAXPLAYERS - 1] of degenmobj_t;
  messageorigins: array[0..MAXPLAYERS - 1] of degenmobj_t;
  enginetics: array[0..MAXPLAYERS - 1] of integer;
  snd_engine_id: integer = -2;
  snd_engineafter_id: integer = -2;
  snd_siren_id: integer = -2;

//==============================================================================
//
// RX_PilotSoundIndex
//
//==============================================================================
function RX_PilotSoundIndex(const name: string): integer;
var
  names: TArray<string>;
  i: integer;
begin
  names := TRadixSoundPart.SoundNames;
  for i := 0 to High(names) do
    if names[i] = name then
    begin
      result := i;
      exit;
    end;
  result := -1;
end;

//==============================================================================
//
// RX_PilotSoundIds
//
//==============================================================================
procedure RX_PilotSoundIds;
begin
  if snd_engine_id <> -2 then
    exit;
  snd_engine_id := RX_PilotSoundIndex(SND_ENGINE);
  snd_engineafter_id := RX_PilotSoundIndex(SND_ENGINEAFTER);
  snd_siren_id := RX_PilotSoundIndex(SND_SIREN);
end;

//==============================================================================
//
// RX_PilotSoundsReset
//
//==============================================================================
procedure RX_PilotSoundsReset;
begin
  ZeroMemory(@enginetics, SizeOf(enginetics));
end;

//==============================================================================
//
// RX_PilotEngineSound
//
//==============================================================================
procedure RX_PilotEngineSound(const pnum: integer; const p: Pplayer_t; const rp: Pradixplayer_t);
var
  sndid: integer;
  duration: integer;
begin
  RX_PilotSoundIds;

  engineorigins[pnum].x := p.mo.x;
  engineorigins[pnum].y := p.mo.y;
  engineorigins[pnum].z := p.mo.z;

  if enginetics[pnum] <= 0 then
  begin
    if (rp.radixpowers[Ord(rpu_maneuverjets)] > 0) or rp.afterburner then
      sndid := snd_engineafter_id
    else
      sndid := snd_engine_id;

    if sndid >= 0 then
      S_StartSound(@engineorigins[pnum], RX_SoundName(sndid));
    duration := RX_SoundDuration(sndid);
    if duration <= 0 then
      duration := UNKNOWNDURATIONTICS;
    enginetics[pnum] := duration;
  end;

  dec(enginetics[pnum]);
end;

//==============================================================================
//
// RX_PilotMessageOrigin
//
//==============================================================================
function RX_PilotMessageOrigin(const pnum: integer; const p: Pplayer_t): pointer;
begin
  messageorigins[pnum].x := p.mo.x;
  messageorigins[pnum].y := p.mo.y;
  messageorigins[pnum].z := p.mo.z;
  result := @messageorigins[pnum];
end;

//==============================================================================
//
// RX_AttackingEnemyNear
// A living enemy that can attack, within the range, that sees the craft
//
//==============================================================================
function RX_AttackingEnemyNear(const pmo: Pmobj_t): boolean;
var
  think: Pthinker_t;
  mo: Pmobj_t;
begin
  result := true;
  think := TTickState.ThinkerCap.next;
  while think <> @TTickState.ThinkerCap do
  begin
    if @think._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(think);
      if (mo.flags and MF_COUNTKILL <> 0) and (mo.health > 0) and (mo.flags2_ex and MF2_EX_FRIEND = 0) then
        if (mo.info.missilestate > 0) or (mo.info.meleestate > 0) then
          if (abs(mo.x - pmo.x) <= ATTACKINGWARNRANGE * FRACUNIT) and
             (abs(mo.y - pmo.y) <= ATTACKINGWARNRANGE * FRACUNIT) then
            if P_CheckSight(mo, pmo) then
              exit;
    end;
    think := think.next;
  end;
  result := false;
end;

//==============================================================================
//
// RX_PilotSiren
// JVAL: 20200514 - Siren when on low health and enemies near
//
//==============================================================================
procedure RX_PilotSiren(const pnum: integer; const p: Pplayer_t; const rp: Pradixplayer_t);
var
  duration: integer;
begin
  if not rp.threat then
    exit;

  RX_PilotSoundIds;
  if snd_siren_id < 0 then
    exit;
  duration := RX_SoundDuration(snd_siren_id);
  if duration < 0 then
    duration := UNKNOWNDURATIONTICS;
  if TTickState.LevelTime mod (duration + 1) <> 0 then
    exit;

  if RX_AttackingEnemyNear(p.mo) then
  begin
    sirenorigins[pnum].x := p.mo.x;
    sirenorigins[pnum].y := p.mo.y;
    sirenorigins[pnum].z := p.mo.z;
    S_StartSound(@sirenorigins[pnum], RX_SoundName(snd_siren_id));
  end;
end;

end.
