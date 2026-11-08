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
//  The lights of the scripted specials and the phased lights. The thinkers stay
//  records in the zone memory (the savegames copy them as they are); what they
//  compute is in Libs\Thinkers (see DelphiDoom.Thinkers.Light.*).
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit udmf_lights;

interface

uses
  d_delphi,
  d_think,
  r_defs;

type
  lighttype_t = (
    LITE_RAISEBYVALUE,
    LITE_LOWERBYVALUE,
    LITE_CHANGETOVALUE,
    LITE_FADE,
    LITE_GLOW,
    LITE_FLICKER,
    LITE_STROBE,
    // JVAL: 20220227 - Added new light types
    LITE_MAXNEIGHTBOR,
    LITE_MINNEIGHTBOR,
    LITE_STROBEDOOM
  );

//==============================================================================
//
// EVH_SpawnLight
//
//==============================================================================
function EVH_SpawnLight(line: Pline_t; arg: PByteArray; _type: lighttype_t): boolean;

//==============================================================================
//
// P_SpawnPhasedLight
//
//==============================================================================
procedure P_SpawnPhasedLight(sector: Psector_t; base: integer; index: integer);

//==============================================================================
//
// P_SpawnLightSequence
//
//==============================================================================
procedure P_SpawnLightSequence(sector: Psector_t; indexStep: integer);

type
  light_t = record
    thinker: thinker_t;
    sector: Psector_t;
    _type: lighttype_t;
    value1: integer;
    value2: integer;
    tics1: integer;
    tics2: integer;
    count: integer;
  end;
  Plight_t = ^light_t;

//==============================================================================
//
// TH_Light
//
//==============================================================================
procedure TH_Light(light: Plight_t);

type
  phase_t = record
    thinker: thinker_t;
    sector: Psector_t;
    index: integer;
    base: integer;
  end;
  Pphase_t = ^phase_t;

//==============================================================================
//
// TH_Phase
//
//==============================================================================
procedure TH_Phase(phase: Pphase_t);

const
  {$IFDEF DOOM_OR_STRIFE}
  LIGHT_SEQUENCE_START = 22;
  LIGHT_SEQUENCE = 23;
  LIGHT_SEQUENCE_ALT = 24;
  {$ENDIF}
  {$IFDEF HERETIC}
  LIGHT_SEQUENCE_START = 52;
  LIGHT_SEQUENCE = 53;
  LIGHT_SEQUENCE_ALT = 54;
  {$ENDIF}
  {$IFDEF HEXEN}
  LIGHT_SEQUENCE_START = 2;
  LIGHT_SEQUENCE = 3;
  LIGHT_SEQUENCE_ALT = 4;
  {$ENDIF}

implementation

uses
  p_tick,
  p_spec,
  {$IFNDEF HEXEN}
  udmf_spec,
  {$ENDIF}
  p_setup,
  z_zone,
  DelphiDoom.Thinkers.Light.Types,
  DelphiDoom.Thinkers.Light.Scripted,
  DelphiDoom.Thinkers.Light.Phase,
  DelphiDoom.Thinkers.Light.Sequence,
  DelphiDoom.Engine.Light.Sector,
  DelphiDoom.Engine.Light.Services;

//==============================================================================
//
//  TH_Light
//
//==============================================================================
procedure TH_Light(light: Plight_t);
begin
  if TLightScripted.Tick(TLightKind(Ord(light._type)), light.value1, light.value2,
    light.tics1, light.tics2, light.count, light.sector.lightlevel, LightRandom) then
    P_RemoveThinker(@light.thinker);
end;

//==============================================================================
//
//  EVH_SpawnLight
//
//==============================================================================
function EVH_SpawnLight(line: Pline_t; arg: PByteArray; _type: lighttype_t): boolean;
var
  light: Plight_t;
  secNum: integer;
  arguments: TLightArguments;
  state: TLightScriptedState;
  outcome: TLightScriptedOutcome;
begin
  result := false;

  arguments.Arg1 := arg[1];
  arguments.Arg2 := arg[2];
  arguments.Arg3 := arg[3];
  arguments.Arg4 := arg[4];

  secNum := -1;
  while P_FindSectorFromTag2(arg[0], secNum) >= 0 do
  begin
    outcome := TLightScripted.Spawn(TLightKind(Ord(_type)),
      TEngineLightSector.Wrap(@sectors[secNum]), arguments, LightRandom, state);
    result := outcome <> TLightScriptedOutcome.Invalid;

    if outcome = TLightScriptedOutcome.Thinker then
    begin
      light := Z_Malloc(sizeof(light_t), PU_LEVSPEC, nil);
      light._type := _type;
      light.sector := @sectors[secNum];
      light.value1 := state.Value1;
      light.value2 := state.Value2;
      light.tics1 := state.Tics1;
      light.tics2 := state.Tics2;
      light.count := state.Count;
      P_AddThinker(@light.thinker);
      light.thinker._function.acp1 := @TH_Light;
    end;
  end;
end;

//==============================================================================
//
// TH_Phase
//
//==============================================================================
procedure TH_Phase(phase: Pphase_t);
begin
  TLightPhase.Tick(phase.index, phase.base, phase.sector.lightlevel);
end;

//==============================================================================
//
// P_SpawnPhasedLight
//
//==============================================================================
procedure P_SpawnPhasedLight(sector: Psector_t; base: integer; index: integer);
var
  phase: Pphase_t;
  phaseindex: integer;
  phasebase: integer;
begin
  phase := Z_Malloc(SizeOf(phase_t), PU_LEVSPEC, nil);
  P_AddThinker(@phase.thinker);
  phase.sector := sector;
  TLightPhase.Initialize(TEngineLightSector.Wrap(sector), base, index, LightSequenceProfile,
    phaseindex, phasebase);
  phase.index := phaseindex;
  phase.base := phasebase;
  phase.thinker._function.acp1 := @TH_Phase;
end;

//==============================================================================
//
// P_SpawnLightSequence
//
//==============================================================================
procedure P_SpawnLightSequence(sector: Psector_t; indexStep: integer);
begin
  TLightSequence.Spawn(TEngineLightSector.Wrap(sector), indexStep, LightSequenceProfile,
    LightPhaseSpawner);
end;

end.
