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
//  Handling interactions (i.e., collisions): pickups, damage, death.
//
//  One copy for the four games (issue #185, step 2f-2). What a game does
//  differently is in TInterGameRules, the class of the unit
//  DelphiDoom.Engine.World.InterRules of the folder of the game (chosen by
//  the project: static calls, no virtual call and no interface in this path).
//  What only one game has (the Hexen mana, the Heretic artifacts, the Strife
//  cards...) and the tables of the game (maxammo, p_maxhealth...) stay in that
//  unit, with the routines that use them.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_inter;

interface

uses
  p_mobj_h;

//==============================================================================
//
// P_TouchSpecialThing
//
//==============================================================================
procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);

//==============================================================================
//
// P_DamageMobj
// Damages both enemies and players
//
//==============================================================================
procedure P_DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);

//==============================================================================
//
// P_CmdSuicide
//
//==============================================================================
procedure P_CmdSuicide;

implementation

uses
  c_cmds,
  d_delphi,
  d_player,
  doomdef,
  doomstat,
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
  g_game,
  i_system,
  DelphiDoom.Engine.World.InterRules;

//==============================================================================
//
// P_TouchSpecialThing
//
//==============================================================================
procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
begin
  TInterGameRules.TouchSpecialThing(special, toucher);
end;

//==============================================================================
//
// P_DamageMobj
//
//==============================================================================
procedure P_DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);
begin
  TInterGameRules.DamageMobj(target, inflictor, source, damage);
end;

//==============================================================================
//
// P_CmdSuicide
//
//==============================================================================
procedure P_CmdSuicide;
begin
  if demoplayback then
  begin
    I_Warning('P_CmdSuicide(): You can''t suicide during demo playback.'#13#10);
    exit;
  end;
  if demorecording then
  begin
    I_Warning('P_CmdSuicide(): You can''t suicide during demo recording.'#13#10);
    exit;
  end;

  if (gamestate = GS_LEVEL) and (players[consoleplayer].mo <> nil) then
  begin
    if players[consoleplayer].health > 0 then
    begin
      C_ExecuteCmd('closeconsole');
      P_DamageMobj(players[consoleplayer].mo, nil, nil, 1000);
      players[consoleplayer]._message := 'You give up too easy';
    end
    else
      printf('You''re already dead.'#13#10);
  end
  else
    I_Warning('P_CmdSuicide(): You can''t suicide if you aren''t playing.'#13#10);
end;

end.
