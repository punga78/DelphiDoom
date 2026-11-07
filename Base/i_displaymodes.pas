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
//  Enum display modes
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_displaymodes;

interface

uses
  DelphiDoom.Video.Intf;

type
  displaymode_t = record
    width, height: integer;
    bpp: integer;
  end;
  displaymode_tArray = array[0..$FF] of displaymode_t;
  Pdisplaymode_tArray = ^displaymode_tArray;

var
  displaymodes: Pdisplaymode_tArray = nil;
  numdisplaymodes: integer = 0;

//==============================================================================
//
// I_ConfigureDisplayModes
//
// The catalog of the modes is given by the composition root (ComposeEngine);
// without it the functions of this unit stop with I_Error.
//
//==============================================================================
procedure I_ConfigureDisplayModes(const ACatalog: IDisplayModeCatalog);

//==============================================================================
//
// I_DisplayModeIndex
//
//==============================================================================
function I_DisplayModeIndex(const w, h: integer): integer;

//==============================================================================
//
// I_NearestDisplayModeIndex
//
//==============================================================================
function I_NearestDisplayModeIndex(const w, h: integer): integer;

{$IFNDEF OPENGL}

//==============================================================================
//
// I_FindWindowSize
//
//==============================================================================
procedure I_FindWindowSize(const mode: integer);
{$ENDIF}

//==============================================================================
//
// I_EnumDisplayModes
//
//==============================================================================
procedure I_EnumDisplayModes;

//==============================================================================
//
// I_ClearDisplayModes
//
//==============================================================================
procedure I_ClearDisplayModes;

// JVAL: Not the right place to put fullscreen modes
const
  FULLSCREEN_SHARED = 0;
  FULLSCREEN_EXCLUSIVE = 1;
  FULLSCREEN_OFF = 2;
  NUMFULLSCREEN_MODES = 3;

implementation

uses
  Windows,
  d_delphi,
  doomdef,
  r_hires,
  {$IFDEF OPENGL}
  gl_main,
  {$ELSE}
  i_main,
  {$ENDIF}
  i_system;

var
  // given by the composition root (I_ConfigureDisplayModes)
  engine_displaymodes: IDisplayModeCatalog = nil;

//==============================================================================
//
// I_ConfigureDisplayModes
//
//==============================================================================
procedure I_ConfigureDisplayModes(const ACatalog: IDisplayModeCatalog);
begin
  engine_displaymodes := ACatalog;
end;

//==============================================================================
//
// DisplayModesCatalog
//
//==============================================================================
function DisplayModesCatalog: IDisplayModeCatalog;
begin
  if engine_displaymodes = nil then
    I_Error('I_ConfigureDisplayModes() was not called: the display modes are missing');
  result := engine_displaymodes;
end;

//==============================================================================
//
// I_DisplayModeIndex
//
//==============================================================================
function I_DisplayModeIndex(const w, h: integer): integer;
begin
  result := DisplayModesCatalog.IndexOf(w, h);
end;

//==============================================================================
//
// I_NearestDisplayModeIndex
//
//==============================================================================
function I_NearestDisplayModeIndex(const w, h: integer): integer;
begin
  result := DisplayModesCatalog.NearestIndex(w, h);
end;

//==============================================================================
//
// I_EnumDisplayModes
//
// The catalog chooses the modes; the menus read them from displaymodes[]
//
//==============================================================================
procedure I_EnumDisplayModes;
var
  i: integer;
  catalog: IDisplayModeCatalog;
begin
  catalog := DisplayModesCatalog;
  I_ClearDisplayModes;

  catalog.Refresh(MAXWIDTH, MAXHEIGHT);
  numdisplaymodes := catalog.Count;
  displaymodes := malloc(numdisplaymodes * SizeOf(displaymode_t));
  for i := 0 to numdisplaymodes - 1 do
  begin
    displaymodes[i].width := catalog.Modes[i].Width;
    displaymodes[i].height := catalog.Modes[i].Height;
    displaymodes[i].bpp := catalog.Modes[i].BitsPerPixel;
  end;
end;

{$IFNDEF OPENGL}

//==============================================================================
//
// I_FindWindowSize
//
//==============================================================================
procedure I_FindWindowSize(const mode: integer);
var
  w, h: integer;
begin
  if mode = FULLSCREEN_SHARED then
  begin
    WINDOWWIDTH := NATIVEWIDTH;
    WINDOWHEIGHT := NATIVEHEIGHT;
    exit;
  end;

  if DisplayModesCatalog.FindWindowSize(SCREENWIDTH, SCREENHEIGHT, w, h) then
  begin
    WINDOWWIDTH := w;
    WINDOWHEIGHT := h;
    exit;
  end;

  WINDOWWIDTH := GetSystemMetrics(SM_CXSCREEN);
  WINDOWHEIGHT := GetSystemMetrics(SM_CYSCREEN);
end;
{$ENDIF}

//==============================================================================
//
// I_ClearDisplayModes
//
//==============================================================================
procedure I_ClearDisplayModes;
begin
  if displaymodes <> nil then
    memfree(pointer(displaymodes), numdisplaymodes * SizeOf(displaymode_t));
  displaymodes := nil;
  numdisplaymodes := 0;
  if engine_displaymodes <> nil then
    engine_displaymodes.Clear;
end;

end.
