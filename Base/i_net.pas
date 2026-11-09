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

interface

uses
  DelphiDoom.Net.Types;

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
  d_delphi,
  g_game,
  m_argv,
  r_main,
  tables,
  DelphiDoom.Net.NodeListParser;

//==============================================================================
//
// CheckIfDrone
//
//==============================================================================
procedure CheckIfDrone;
begin
  if M_CheckParm('-left') > 0 then
    R_SetViewAngleOffset(ANG90)
  else if M_CheckParm('-right') > 0 then
    R_SetViewAngleOffset(ANG270)
  else if M_CheckParm('-back') > 0 then
    R_SetViewAngleOffset(ANG180);
end;

//==============================================================================
//
// I_InitNetwork
//
//==============================================================================
procedure I_InitNetwork;
var
  i: integer;
  p: integer;
  arguments: TArray<string>;
  nodeno: integer;
begin
  // set up for network
  net_ticdup := 1;
  i := M_CheckParm('-dup');
  if (i > 0) and (i < myargc - 1) then
  begin
    net_ticdup := Ord(myargv[i + 1][1]) - Ord('0');
    if net_ticdup < 1 then
      net_ticdup := 1
    else if net_ticdup > 9 then
      net_ticdup := 9;
  end;

  if M_CheckParm('-extratic') > 0 then
    net_extratics := 1
  else
    net_extratics := 0;

  p := M_CheckParm('-port');
  if (p > 0) and (p < myargc - 1) then
  begin
    net_port := atoi(myargv[p + 1]);
    printf('Using Port %d'#13#10, [net_port]);
  end;

  CheckIfDrone;

  // parse network game options,
  //  -net <consoleplayer> <host> <host> ...
  i := M_CheckParm('-net');
  if i = 0 then
  begin
    // single player game
    netgame := false;
    net_numnodes := 1;
    net_consoleplayer := 0;
    net_peers := nil;
    exit;
  end;

  netgame := true;

  // parse player number and host list
  net_consoleplayer := Ord(myargv[i + 1][1]) - Ord('1');
  printf('console player number: %d'#13#10, [net_consoleplayer]);

  SetLength(arguments, myargc);
  for nodeno := 0 to myargc - 1 do
    arguments[nodeno] := myargv[nodeno];
  net_peers := TNetNodeListParser.Parse(arguments, i + 2, net_port);
  net_numnodes := 1 + Length(net_peers);

  for nodeno := 0 to Length(net_peers) - 1 do
    if net_peers[nodeno].IsLiteral then
      printf('Node number %d address %s'#13#10, [nodeno + 1, net_peers[nodeno].Host])
    else
      printf('Node number %d hostname %s'#13#10, [nodeno + 1, net_peers[nodeno].Host]);
  printf('Total number of players : %d'#13#10, [net_numnodes]);
end;

end.
