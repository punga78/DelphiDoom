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
//  System specific network interface stuff.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_net;

// What is left of the facade of the network options (issue #185): the reading of the command line is
// TNetCommandLineReader of Libs\EngineSystem, given by ComposeEngine (I_ConfigureNetOptions).

interface

uses
  DelphiDoom.Net.Types,
  DelphiDoom.EngineSystem.Intf;

//==============================================================================
//
// I_ConfigureNetOptions
// Gives the unit the reader of the options of the network game. The composition root calls it
//
//==============================================================================
procedure I_ConfigureNetOptions(const AReader: INetCommandLineReader);

//==============================================================================
//
// I_InitNetwork
// Called by TEngineNetGame.Start: reads the options of the network game from the command line
//   -dup <n>, -extratic, -port <n>, -left, -right, -back, -drone and
//   -net <consoleplayer> <host> <host> ...
// The sockets are not opened here: they belong to the network library
//
//==============================================================================
procedure I_InitNetwork;

var
  // What the command line says: this node is node 0 and the hosts are the other nodes
  net_consoleplayer: integer = 0;
  net_numnodes: integer = 1;
  net_ticdup: integer = 1;
  net_extratics: integer = 0;
  net_port: integer = 5000 + $1d;
  net_peers: TArray<TNetNodeAddress>;

implementation

uses
  g_game,
  i_system,
  r_main,
  tables,
  DelphiDoom.EngineSystem.Types;

var
  // given by the composition root (I_ConfigureNetOptions)
  net_reader: INetCommandLineReader = nil;

//==============================================================================
//
// I_ConfigureNetOptions
//
//==============================================================================
procedure I_ConfigureNetOptions(const AReader: INetCommandLineReader);
begin
  net_reader := AReader;
end;

//==============================================================================
//
// I_InitNetwork
//
//==============================================================================
procedure I_InitNetwork;
var
  options: TNetCommandLineOptions;
begin
  if net_reader = nil then
    I_Error('I_InitNetwork(): the network options were not configured (ComposeEngine)');

  options := net_reader.Read(net_port);

  net_ticdup := options.TicDup;
  net_extratics := options.ExtraTics;
  net_port := options.Port;

  case options.Drone of
    ndvLeft: R_SetViewAngleOffset(ANG90);
    ndvRight: R_SetViewAngleOffset(ANG270);
    ndvBack: R_SetViewAngleOffset(ANG180);
  end;

  netgame := options.IsNetGame;
  net_consoleplayer := options.ConsolePlayer;
  net_numnodes := options.NumNodes;
  net_peers := options.Peers;
end;

end.
