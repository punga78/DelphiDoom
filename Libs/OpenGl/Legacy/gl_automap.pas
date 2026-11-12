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
//   OpenGL AutoMap
//   Facade: the items of a frame are kept by Libs\GlAutomap (IGlAutomapDisplayList)
//   and drawn by TEngineGlAutomapPainter (IGlAutomapPainter)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit gl_automap;

interface

uses
  r_defs,
  DelphiDoom.GlAutomap.Intf;

//==============================================================================
//
// gld_ConfigureAutomap
//
// The list of the items of a frame (Libs\GlAutomap) and what draws them: the
// composition root calls this, without it gld_InitAutomap stops with I_Error
//
//==============================================================================
procedure gld_ConfigureAutomap(const AList: IGlAutomapDisplayList; const APainter: IGlAutomapPainter);

//==============================================================================
//
// gld_InitAutomap
//
//==============================================================================
procedure gld_InitAutomap;

//==============================================================================
//
// gld_ShutDownAutomap
//
//==============================================================================
procedure gld_ShutDownAutomap;

//==============================================================================
//
// gld_ClearAMBuffer
//
//==============================================================================
procedure gld_ClearAMBuffer(const fw, fh: integer; const cc: LongWord);

//==============================================================================
//
// gld_AddAutomapLine
//
//==============================================================================
procedure gld_AddAutomapLine(const x1, y1, x2, y2: integer; const cc: LongWord);

//==============================================================================
//
// gld_AddAutomapPatch
//
//==============================================================================
procedure gld_AddAutomapPatch(const x, y: integer; const lump: integer);

procedure gld_AddAutomapTriangle(
  const x1, y1, u1, v1: integer;
  const x2, y2, u2, v2: integer;
  const x3, y3, u3, v3: integer;
  const cc: LongWord; const lump: integer; const sec: Psector_t);

//==============================================================================
//
// gld_DrawAutomap
//
//==============================================================================
procedure gld_DrawAutomap;

implementation

uses
  i_system,
  DelphiDoom.GlAutomap.Types;

var
  // given by the composition root (gld_ConfigureAutomap)
  gld_automaplist: IGlAutomapDisplayList = nil;
  gld_automappainter: IGlAutomapPainter = nil;

//==============================================================================
//
// gld_ConfigureAutomap
//
//==============================================================================
procedure gld_ConfigureAutomap(const AList: IGlAutomapDisplayList; const APainter: IGlAutomapPainter);
begin
  gld_automaplist := AList;
  gld_automappainter := APainter;
end;

//==============================================================================
//
// gld_InitAutomap
//
//==============================================================================
procedure gld_InitAutomap;
begin
  // checked here, once, and not at every line of the map
  if (gld_automaplist = nil) or (gld_automappainter = nil) then
    I_Error('gld_InitAutomap(): the automap is not configured (ComposeEngine was not called)');
  gld_automaplist.Clear;
end;

//==============================================================================
//
// gld_ShutDownAutomap
//
//==============================================================================
procedure gld_ShutDownAutomap;
begin
  if gld_automaplist <> nil then
    gld_automaplist.Release;
end;

//==============================================================================
//
// gld_ClearAMBuffer
//
//==============================================================================
procedure gld_ClearAMBuffer(const fw, fh: integer; const cc: LongWord);
begin
  gld_automaplist.AddBackground(fw, fh, cc);
end;

//==============================================================================
//
// gld_AddAutomapLine
//
//==============================================================================
procedure gld_AddAutomapLine(const x1, y1, x2, y2: integer; const cc: LongWord);
begin
  gld_automaplist.AddLine(x1, y1, x2, y2, cc);
end;

//==============================================================================
//
// gld_AddAutomapPatch
//
//==============================================================================
procedure gld_AddAutomapPatch(const x, y: integer; const lump: integer);
begin
  gld_automaplist.AddPatch(x, y, lump);
end;

procedure gld_AddAutomapTriangle(
  const x1, y1, u1, v1: integer;
  const x2, y2, u2, v2: integer;
  const x3, y3, u3, v3: integer;
  const cc: LongWord; const lump: integer; const sec: Psector_t);
var
  floor: TGlAutomapFloor;
begin
  // what the drawing read from the sector is read here: nothing moves between the two in a frame
  floor.Flat := sec.floorpic;
  floor.Ripples := sec.renderflags and SRF_RIPPLE_FLOOR <> 0;
{$IFDEF DOOM_OR_STRIFE}
  floor.OffsetX := sec.floor_xoffs;
  floor.OffsetY := sec.floor_yoffs;
{$ELSE}
  floor.OffsetX := 0;
  floor.OffsetY := 0;
{$ENDIF}
  floor.Angle := sec.floorangle;
  floor.AngleX := sec.flooranglex;
  floor.AngleY := sec.floorangley;

  gld_automaplist.AddTriangle(
    x1, y1, u1, v1,
    x2, y2, u2, v2,
    x3, y3, u3, v3,
    cc, lump, floor);
end;

//==============================================================================
//
// gld_DrawAutomap
//
//==============================================================================
procedure gld_DrawAutomap;
begin
  gld_automappainter.Paint(gld_automaplist.First, gld_automaplist.Count);
  gld_automaplist.Clear;
end;

end.
