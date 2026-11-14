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
//  Player related stuff.
//  Bobbing POV/weapon, movement.
//  Pending weapon.
//
//  One copy for the four games (issue #185, step 2f-1). What a game does
//  differently is in TUserGameRules, the class of the unit
//  DelphiDoom.Engine.World.UserRules of the folder of the game (chosen by
//  the project: static calls, no virtual call and no interface in this path).
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_user;

interface

uses
  m_fixed,
  tables,
  p_mobj_h,
  d_player;

//==============================================================================
//
// P_PlayerThink
//
//==============================================================================
procedure P_PlayerThink(player: Pplayer_t);

//==============================================================================
//
// P_CalcHeight
//
//==============================================================================
procedure P_CalcHeight(player: Pplayer_t);

//==============================================================================
//
// P_Thrust
//
//==============================================================================
procedure P_Thrust(player: Pplayer_t; angle: angle_t; const move: fixed_t);

implementation

uses
  DelphiDoom.Engine.World.UserRules;

//==============================================================================
//
// P_PlayerThink
//
//==============================================================================
procedure P_PlayerThink(player: Pplayer_t);
begin
  TUserGameRules.PlayerThink(player);
end;

//==============================================================================
//
// P_CalcHeight
// Calculate the walking / running height adjustment
//
//==============================================================================
procedure P_CalcHeight(player: Pplayer_t);
begin
  TUserGameRules.CalcHeight(player);
end;

//==============================================================================
//
// P_Thrust
// Moves the given origin along a given angle.
//
//==============================================================================
procedure P_Thrust(player: Pplayer_t; angle: angle_t; const move: fixed_t);
begin
  TUserGameRules.Thrust(player, angle, move);
end;

end.
