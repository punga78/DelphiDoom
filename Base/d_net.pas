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
//  DESCRIPTION:
//   Networking stuff.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit d_net;

// What is left of the network unit: the data that the game reads (issue #145). The loop of
// the game around the network (NetUpdate, D_CheckNetGame, D_RunMultipleTicks...) is the
// class TEngineNetGame (DelphiDoom.Engine.Net.Game) behind IEngineNetGame: the composition
// root gives it to d_main, g_game, r_main and i_system.

interface

uses
  m_base;

var
  // the tics run for each command (-dup), set when the network starts
  ticdup: integer;

var
  // the first display of a series of interpolated frames: the status bars draw it again
  firstinterpolation: boolean;

  S_ERR_DIF_NET: string = 'Different ' + APPNAME + ' versions cannot play a net game!';

implementation

end.
