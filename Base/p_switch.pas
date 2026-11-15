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
//  Switches, buttons. Two-state animation. Exits.
//
//  One copy for the four games (issue #185, step 2g): the list of the buttons
//  and P_StartButton. The changes of texture, the use of the special lines and
//  the list of the switches are different in every game and stay in the unit
//  DelphiDoom.Engine.World.SwitchRules of the folder of the game.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_switch;

interface

uses
  r_defs,
  p_spec_h;

var
  buttonlist: array[0..MAXBUTTONS - 1] of button_t;

//==============================================================================
//
// P_StartButton
//
// Start a button counting down till it turns off.
//
//==============================================================================
procedure P_StartButton(line: Pline_t; w: bwhere_e; texture: integer; time: integer);

implementation

uses
  i_system,
  p_mobj_h;

//==============================================================================
//
// P_StartButton
//
//==============================================================================
procedure P_StartButton(line: Pline_t; w: bwhere_e; texture: integer; time: integer);
var
  i: integer;
begin
  // See if button is already pressed
  for i := 0 to MAXBUTTONS - 1 do
    if (buttonlist[i].btimer <> 0) and (buttonlist[i].line = line) then
      exit;

  for i := 0 to MAXBUTTONS - 1 do
  begin
    if buttonlist[i].btimer = 0 then
    begin
      buttonlist[i].line := line;
      buttonlist[i].where := w;
      buttonlist[i].btexture := texture;
      buttonlist[i].btimer := time;
      buttonlist[i].soundorg := Pmobj_t(@line.frontsector.soundorg);
      exit;
    end;
  end;

  I_Error('P_StartButton(): no button slots left!');
end;

end.
