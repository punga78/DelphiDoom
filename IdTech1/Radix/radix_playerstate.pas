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
//  Radix: what the craft of the pilot has more than the marine of Doom.
//  Rad-X added these fields to player_t; here they stand beside it, one record
//  for each player, so that player_t (and the savegames, the demos and the state
//  fingerprints of Doom) stays the one of the engine.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_playerstate;

interface

uses
  doomdef,
  d_player,
  m_fixed,
  p_mobj_h;

type
  // Radix weapons, in the nine slots of the weapons of Doom (wp_fist..wp_supershotgun)
  radixweapon_t = (
    rwp_neutroncannons,
    rwp_standardepc,
    rwp_plasmaspreader,
    rwp_seekingmissiles,
    rwp_nuke,
    rwp_phasetorpedoes,
    rwp_gravitywave,
    rwp_enchancedepc,
    rwp_superepc
  );

  radixpowerup_t = (
    rpu_rapidshield,
    rpu_rapidenergy,
    rpu_maneuverjets,
    rpu_nightvision,
    rpu_alds, // Automated Laser Defence System
    NUMRADIXPOWERUPS
  );

const
  MAXNEUTRONCANNONLEVEL = 7;

  // the level shown in the display for each level of the neutron cannons / spreader
  // (neutroncannoninfo[].firelevel of Rad-X)
  neutronfirelevel: array[0..MAXNEUTRONCANNONLEVEL - 1] of integer = (0, 1, 1, 2, 2, 2, 3);

  // weaponflags: which side fires next (PWF_???? of Rad-X)
  PWF_NEURONCANNON = 1;
  PWF_NUKE = 2;
  PWF_PHASETORPEDO = 4;
  PWF_NEURONSPREADER = 8;

  NUMRADIXWEAPONS = 9;

var
  PLAYERSPAWNARMOR: integer = 100;
  PLAYERSPAWNSHIELD: integer = 100;
  PLAYERSPAWNENERGY: integer = 100;
  GRAVITYWAVEENERGY: integer = 30;

type
  radixplayer_t = record
    energy: integer;                // Radix energy
    energy_reserve: integer;        // Added energy when refiring
    threat: boolean;                // Player in threat
    plasmaenergycountdown: integer; // How many plasma balls to drain energy
    energyweaponfiretics: integer;  // Energy weapon has been fired - wait to zero to regenerate
    thrustmomz: fixed_t;            // z momentum by forward/backward move
    radixpowers: array[0..Ord(NUMRADIXPOWERUPS) - 1] of integer;
    plasmabombs: integer;           // Number of plasma bombs
    neutroncannonlevel: integer;
    neutronspreaderlevel: integer;
    weaponflags: LongWord;          // Weapon firing sequence information
    scannerjam: boolean;            // When true can not see the radar in hud
    lastbonustime: integer;
    gravitywave: integer;           // Number of gravity wave shots
    plinetarget: Pmobj_t;           // For the crosshair target
    pcrosstic: integer;
    lastfire: array[0..NUMRADIXWEAPONS - 1] of integer; // Refire control (leveltime of the last shot)
    plasmabombcount: integer;       // Tics left of the flash of a plasma bomb
    floorslidetics: integer;        // Slide to floors/ceilings (A_PlayerFloorSlide)
    plasmabombdown: boolean;        // Plasma bomb key pressed
    afterburner: boolean;           // The afterburner worked at the last tic
  end;
  Pradixplayer_t = ^radixplayer_t;

var
  radixplayers: array[0..MAXPLAYERS - 1] of radixplayer_t;

//==============================================================================
//
// RX_PlayerState
// The Radix part of a player of the engine
//
//==============================================================================
function RX_PlayerState(const p: Pplayer_t): Pradixplayer_t;

//==============================================================================
//
// RX_ResetPlayerState
// The Radix part of a player that is born again (G_PlayerReborn of Rad-X)
//
//==============================================================================
procedure RX_ResetPlayerState(const p: Pplayer_t);

implementation

uses
  d_delphi,
  g_game;

//==============================================================================
//
// RX_PlayerState
//
//==============================================================================
function RX_PlayerState(const p: Pplayer_t): Pradixplayer_t;
begin
  result := @radixplayers[pDiff(p, @TGameSession.Players[0], SizeOf(player_t))];
end;

//==============================================================================
//
// RX_ResetPlayerState
//
//==============================================================================
procedure RX_ResetPlayerState(const p: Pplayer_t);
var
  rp: Pradixplayer_t;
begin
  rp := RX_PlayerState(p);
  ZeroMemory(rp, SizeOf(radixplayer_t));
  rp.energy := PLAYERSPAWNENERGY;
end;

end.
