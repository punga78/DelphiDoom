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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}


unit hu_lib;

// The widgets of the heads-up display (text line, scrolling text, input text) are the classes
// of Libs\Hud since issue #185 (slice 1a): THudTextLine, THudScrollingText, THudInputText, and
// the drawing is DelphiDoom.Engine.Hud.Drawer. The routines HUlib_* of the records have no
// caller left and are gone; what remains is the one routine that another unit calls.

interface

{$IFDEF STRIFE}

//==============================================================================
//
// HUlib_drawYellowText
//
// haleyjd 20100918: [STRIFE] New function.
//
//==============================================================================
procedure HUlib_drawYellowText(x, y: integer; txt: string; const scn: integer);
{$ENDIF}

implementation

{$IFDEF STRIFE}
uses
  hu_stuff;

//==============================================================================
//
// HUlib_drawYellowText
//
//==============================================================================
procedure HUlib_drawYellowText(x, y: integer; txt: string; const scn: integer);
begin
  HU_DrawYellowText(x, y, txt, scn);
end;
{$ENDIF}

end.
