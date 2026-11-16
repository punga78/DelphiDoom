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
//  Radix: the keys of the craft that the marine of Doom has not (the part of
//  G_BuildTiccmd and of m_defs that Rad-X changed). Rad-X had buttons2, flyup
//  and flydown in its ticcmd; here the ticcmd is the one of Doom:
//   - fly up and fly down are the jump and the crouch keys of the engine (the
//     rows key_flyup and key_flydown of the configuration file write the same
//     variables as key_jump and key_crouch);
//   - the afterburner and the plasma bomb are two free bits of jump_crouch.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_controls;

interface

uses
  d_ticcmd;

const
  // the bits of ticcmd_t.jump_crouch (BT2_AFTERBURNER and BT2_PLASMABOMB of Rad-X)
  RXCMD_AFTERBURNER = CMD_GAMEKEY1_MASK;
  RXCMD_PLASMABOMB = CMD_GAMEKEY2_MASK;

var
  key_plasmabomb: integer = Ord('b');
  key_afterburner: integer = 47;

//==============================================================================
//
// RX_TiccmdKeys
// The extension of G_BuildTiccmd (G_ConfigureTiccmdExtension): the keys of the
// afterburner and of the plasma bomb in the ticcmd of the console player
//
//==============================================================================
procedure RX_TiccmdKeys(cmd: Pticcmd_t);

implementation

uses
  doomdef,
  d_player,
  g_game,
  radix_playerstate,
  DelphiDoom.Engine.Configuration.Table,
  DelphiDoom.Radix.Control.Rules;

//==============================================================================
//
// RX_TiccmdKeys
//
//==============================================================================
procedure RX_TiccmdKeys(cmd: Pticcmd_t);
var
  key: integer;
begin
  key := key_afterburner;
  if (key >= 0) and (key < NUMKEYS) then
    if TRadixControlRules.AfterburnerOn(gamekeydown[key], radixplayers[TGameSession.ConsolePlayer].energy,
         cmd.forwardmove, cmd.sidemove) then
      cmd.jump_crouch := cmd.jump_crouch or RXCMD_AFTERBURNER;

  key := key_plasmabomb;
  if (key >= 0) and (key < NUMKEYS) then
    if gamekeydown[key] then
      cmd.jump_crouch := cmd.jump_crouch or RXCMD_PLASMABOMB;
end;

initialization
  // the names and the values of m_defs of Rad-X; the table of the options is built before the
  // game is composed, so the rows are registered here
  TEngineConfigurationTable.RegisterExtraKey('key_flyup', @key_jump, 101);
  TEngineConfigurationTable.RegisterExtraKey('key_flydown', @key_crouch, 113);
  TEngineConfigurationTable.RegisterExtraKey('key_plasmabomb', @key_plasmabomb, Ord('b'));
  TEngineConfigurationTable.RegisterExtraKey('key_afterburner', @key_afterburner, 47);

end.
