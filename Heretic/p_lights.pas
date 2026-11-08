//------------------------------------------------------------------------------
//
//  DelphiHeretic is a source port of the game Heretic and it is
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
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
// DESCRIPTION:
//  Handle Sector base lighting effects.
//  Muzzle flash?
//  The thinkers stay records in the zone memory (the savegames copy them as
//  they are); what they compute is in Libs\Thinkers (DelphiDoom.Thinkers.Light.*).
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_lights;

interface

uses
  p_spec,
  r_defs,
  z_zone;

//==============================================================================
//
// P_SpawnFireFlicker
//
//==============================================================================
procedure P_SpawnFireFlicker(sector: Psector_t);

//==============================================================================
//
// P_SpawnLightFlash
//
//==============================================================================
procedure P_SpawnLightFlash(sector: Psector_t);

//==============================================================================
//
// T_StrobeFlash
//
//==============================================================================
procedure T_StrobeFlash(flash: Pstrobe_t);

//==============================================================================
//
// P_SpawnStrobeFlash
//
//==============================================================================
procedure P_SpawnStrobeFlash(sector: Psector_t; fastOrSlow, inSync: integer);

//==============================================================================
//
// EV_StartLightStrobing
//
//==============================================================================
procedure EV_StartLightStrobing(line: Pline_t);

//==============================================================================
//
// EV_TurnTagLightsOff
//
//==============================================================================
procedure EV_TurnTagLightsOff(line: Pline_t);

//==============================================================================
//
// EV_LightTurnOn
//
//==============================================================================
procedure EV_LightTurnOn(line: Pline_t; bright: integer);

//==============================================================================
//
// T_Glow
//
//==============================================================================
procedure T_Glow(g: Pglow_t);

//==============================================================================
//
// P_SpawnGlowingLight
//
//==============================================================================
procedure P_SpawnGlowingLight(sector: Psector_t);

//==============================================================================
//
// T_LightFlash
//
//==============================================================================
procedure T_LightFlash(flash: Plightflash_t);

//==============================================================================
//
// T_FireFlicker
//
//==============================================================================
procedure T_FireFlicker(flick: Pfireflicker_t);

implementation

uses
  p_tick,
  p_setup,
  DelphiDoom.Thinkers.Light.Neighbors,
  DelphiDoom.Thinkers.Light.FireFlicker,
  DelphiDoom.Thinkers.Light.Flash,
  DelphiDoom.Thinkers.Light.Strobe,
  DelphiDoom.Thinkers.Light.Glow,
  DelphiDoom.Engine.Light.Sector,
  DelphiDoom.Engine.Light.Services;

//==============================================================================
//
// FIRELIGHT FLICKER
//
// T_FireFlicker
//
//==============================================================================
procedure T_FireFlicker(flick: Pfireflicker_t);
begin
  TLightFireFlicker.Tick(flick.count, flick.sector.lightlevel, flick.minlight, flick.maxlight,
    LightFlickerRules, LightRandom);
end;

//==============================================================================
//
// P_SpawnFireFlicker
//
//==============================================================================
procedure P_SpawnFireFlicker(sector: Psector_t);
var
  flick: Pfireflicker_t;
  maxlight: integer;
  minlight: integer;
  count: integer;
begin
  // Note that we are resetting sector attributes.
  // Nothing special about it during gameplay.
  sector.special := 0;

  flick := Z_Malloc(SizeOf(fireflicker_t), PU_LEVSPEC, nil);

  P_AddThinker(@flick.thinker);

  flick.thinker._function.acp1 := @T_FireFlicker;
  flick.sector := sector;
  TLightFireFlicker.Initialize(TEngineLightSector.Wrap(sector), LightFlickerRules,
    maxlight, minlight, count);
  flick.maxlight := maxlight;
  flick.minlight := minlight;
  flick.count := count;
end;

//==============================================================================
//
// BROKEN LIGHT FLASHING
//
// T_LightFlash
// Do flashing lights.
//
//==============================================================================
procedure T_LightFlash(flash: Plightflash_t);
begin
  TLightFlash.Tick(flash.count, flash.sector.lightlevel, flash.maxlight, flash.minlight,
    flash.maxtime, flash.mintime, LightRandom);
end;

//==============================================================================
//
// P_SpawnLightFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
//
//==============================================================================
procedure P_SpawnLightFlash(sector: Psector_t);
var
  flash: Plightflash_t;
  maxlight: integer;
  minlight: integer;
  maxtime: integer;
  mintime: integer;
  count: integer;
begin
  // nothing special about it during gameplay
  sector.special := 0;

  flash := Z_Malloc(SizeOf(lightflash_t), PU_LEVSPEC, nil);

  P_AddThinker(@flash.thinker);

  flash.thinker._function.acp1 := @T_LightFlash;
  flash.sector := sector;
  TLightFlash.Initialize(TEngineLightSector.Wrap(sector), LightRandom,
    maxlight, minlight, maxtime, mintime, count);
  flash.maxlight := maxlight;
  flash.minlight := minlight;
  flash.maxtime := maxtime;
  flash.mintime := mintime;
  flash.count := count;
end;

//==============================================================================
//
// STROBE LIGHT FLASHING
//
// T_StrobeFlash
//
//==============================================================================
procedure T_StrobeFlash(flash: Pstrobe_t);
begin
  TLightStrobe.Tick(flash.count, flash.sector.lightlevel, flash.minlight, flash.maxlight,
    flash.darktime, flash.brighttime);
end;

//==============================================================================
//
// P_SpawnStrobeFlash
// After the map has been loaded, scan each sector
// for specials that spawn thinkers
//
//==============================================================================
procedure P_SpawnStrobeFlash(sector: Psector_t; fastOrSlow, inSync: integer);
var
  flash: Pstrobe_t;
  maxlight: integer;
  minlight: integer;
  darktime: integer;
  brighttime: integer;
  count: integer;
begin
  flash := Z_Malloc(SizeOf(strobe_t), PU_LEVSPEC, nil);

  P_AddThinker(@flash.thinker);

  flash.sector := sector;
  TLightStrobe.Initialize(TEngineLightSector.Wrap(sector), fastOrSlow, inSync <> 0, LightRandom,
    maxlight, minlight, darktime, brighttime, count);
  flash.darktime := darktime;
  flash.brighttime := brighttime;
  flash.thinker._function.acp1 := @T_StrobeFlash;
  flash.maxlight := maxlight;
  flash.minlight := minlight;

  // nothing special about it during gameplay
  sector.special := 0;

  flash.count := count;
end;

//==============================================================================
// EV_StartLightStrobing
//
// Start strobing lights (usually from a trigger)
//
//==============================================================================
procedure EV_StartLightStrobing(line: Pline_t);
var
  secnum: integer;
  sec: Psector_t;
begin
  secnum := -1;
  repeat
    secnum := P_FindSectorFromLineTag(line, secnum);

    if secnum >= 0 then
    begin
      sec := @sectors[secnum];
      if sec.specialdata = nil then
        P_SpawnStrobeFlash(sec, SLOWDARK, 0);
    end;
  until secnum < 0;
end;

//==============================================================================
// EV_TurnTagLightsOff
//
// TURN LINE'S TAG LIGHTS OFF
//
//==============================================================================
procedure EV_TurnTagLightsOff(line: Pline_t);
var
  i: integer;
  sector: Psector_t;
begin
  for i := 0 to numsectors - 1 do
  begin
    sector := @sectors[i];
    if sector.tag = line.tag then
    begin
      // the lowest light level among the sector and its neighbors
      sector.lightlevel := TLightNeighbors.Lowest(TEngineLightSector.Wrap(sector), sector.lightlevel);
    end;
  end;
end;

//==============================================================================
// EV_LightTurnOn
//
// TURN LINE'S TAG LIGHTS ON
//
//==============================================================================
procedure EV_LightTurnOn(line: Pline_t; bright: integer);
var
  i: integer;
  sector: Psector_t;
begin
  for i := 0 to numsectors - 1 do
  begin
    sector := @sectors[i];
    if sector.tag = line.tag then
    begin
      // bright = 0 means to search
      // for highest light level
      // surrounding sector
      if bright = 0 then
        bright := TLightNeighbors.HighestAbove(TEngineLightSector.Wrap(sector), bright);
      sector.lightlevel := bright;
    end;
  end;
end;

//==============================================================================
// T_Glow
//
// Spawn glowing light
//
//==============================================================================
procedure T_Glow(g: Pglow_t);
begin
  TLightGlow.Tick(g.sector.lightlevel, g.minlight, g.maxlight, g.direction);
end;

//==============================================================================
//
// P_SpawnGlowingLight
//
//==============================================================================
procedure P_SpawnGlowingLight(sector: Psector_t);
var
  g: Pglow_t;
  minlight: integer;
  maxlight: integer;
  direction: integer;
begin
  g := Z_Malloc(SizeOf(glow_t), PU_LEVSPEC, nil);

  P_AddThinker(@g.thinker);

  g.sector := sector;
  TLightGlow.Initialize(TEngineLightSector.Wrap(sector), minlight, maxlight, direction);
  g.minlight := minlight;
  g.maxlight := maxlight;
  g.thinker._function.acp1 := @T_Glow;
  g.direction := direction;

  sector.special := 0;
end;

end.
