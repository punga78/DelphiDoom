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
//  Speed Haste: the keys of the car that the marine of Doom has not (the part of
//  G_BuildTiccmd and m_defs that the fork changed) and the options of the race
//  that go in the configuration file (the rows of m_defs of the fork).
//  The ticcmd is the one of Doom: the gear up and the gear down are two free
//  bits of jump_crouch (CMD_GAMEKEY1_MASK, CMD_GAMEKEY2_MASK), the same that a
//  script of commands (-autoscript) writes with the words afterburner and bomb.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_controls;

interface

uses
  d_ticcmd;

const
  // the bits of ticcmd_t.jump_crouch (BT2_GEARUP and BT2_GEARDOWN of the fork)
  SHCMD_GEARUP = CMD_GAMEKEY1_MASK;
  SHCMD_GEARDOWN = CMD_GAMEKEY2_MASK;
  // the kinds of game of speed_gametype
  SH_GAME_CHAMPIONSHIP = 0;
  SH_GAME_SINGLERACE = 1;
  SH_GAME_PRACTICE = 2;

var
  key_gearup: integer = Ord('a');
  key_geardown: integer = Ord('z');
  // the options of the race (-car, -laps, -manual and -practice on the command line win over them)
  speed_car: integer = 1;
  speed_laps: integer = 2;
  speed_transmission: integer = 0; // 0 automatic, 1 manual
  speed_gametype: integer = SH_GAME_SINGLERACE;
  speed_pilotname: string = 'PILOT';

//==============================================================================
//
// SH_TiccmdKeys
// The extension of G_BuildTiccmd (G_ConfigureTiccmdExtension): the gear keys in
// the ticcmd of the console player
//
//==============================================================================
procedure SH_TiccmdKeys(cmd: Pticcmd_t);

implementation

uses
  doomdef,
  g_game,
  DelphiDoom.Engine.Configuration.Table;

//==============================================================================
//
// SH_TiccmdKeys
//
//==============================================================================
procedure SH_TiccmdKeys(cmd: Pticcmd_t);
begin
  if (key_gearup >= 0) and (key_gearup < NUMKEYS) and gamekeydown[key_gearup] then
    cmd.jump_crouch := cmd.jump_crouch or SHCMD_GEARUP;
  if (key_geardown >= 0) and (key_geardown < NUMKEYS) and gamekeydown[key_geardown] then
    cmd.jump_crouch := cmd.jump_crouch or SHCMD_GEARDOWN;
end;

initialization
  // the table of the options is built before the game is composed, so the rows are registered here
  TEngineConfigurationTable.RegisterExtraKey('key_gearup', @key_gearup, Ord('a'));
  TEngineConfigurationTable.RegisterExtraKey('key_geardown', @key_geardown, Ord('z'));
  TEngineConfigurationTable.RegisterExtraKey('speed_car', @speed_car, 1);
  TEngineConfigurationTable.RegisterExtraKey('speed_laps', @speed_laps, 2);
  TEngineConfigurationTable.RegisterExtraKey('speed_transmission', @speed_transmission, 0);
  TEngineConfigurationTable.RegisterExtraKey('speed_gametype', @speed_gametype, SH_GAME_SINGLERACE);

end.
