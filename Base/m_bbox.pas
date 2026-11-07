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

unit m_bbox;

interface

uses
  m_fixed;

// Bounding box coordinate storage.
const
  BOXTOP = 0;
  BOXBOTTOM = 1;
  BOXLEFT = 2;
  BOXRIGHT = 3;

//==============================================================================
// M_ClearBox
//
// Bounding box functions.
//
//==============================================================================
procedure M_ClearBox(box: Pfixed_tArray);

//==============================================================================
//
// M_AddToBox
//
//==============================================================================
procedure M_AddToBox(box: Pfixed_tArray; x: fixed_t; y: fixed_t);

implementation

uses
  DelphiDoom.MathCore.Types,
  DelphiDoom.MathCore.BoundingBox;

type
  // the box of the engine is a pointer to four fixed_t
  PBoundingBox = ^TBoundingBox;

//==============================================================================
//
// M_ClearBox
//
//==============================================================================
procedure M_ClearBox(box: Pfixed_tArray);
begin
  TBoundingBoxMath.Clear(PBoundingBox(box)^);
end;

//==============================================================================
//
// M_AddToBox
//
//==============================================================================
procedure M_AddToBox(box: Pfixed_tArray; x: fixed_t; y: fixed_t);
begin
  TBoundingBoxMath.AddPoint(PBoundingBox(box)^, x, y);
end;

end.