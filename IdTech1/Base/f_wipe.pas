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
//  Mission start screen wipe/melt, special effects.
//  Mission begin melt/wipe screen special effect.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit f_wipe;

interface

uses
  d_delphi,
  DelphiDoom.Imaging.Intf;

//==============================================================================
//
// wipe_Configure
// The melt of LibsImaging, given by the composition root
//
//==============================================================================
procedure wipe_Configure(const AMelt: IImagingMeltWipe);

//==============================================================================
//
// wipe_StartScreen
//
//==============================================================================
procedure wipe_StartScreen;

//==============================================================================
//
// wipe_EndScreen
//
//==============================================================================
procedure wipe_EndScreen;

//==============================================================================
//
// wipe_Ticker
//
//==============================================================================
function wipe_Ticker(ticks: integer): boolean;

type
  // The wipe of a game that does not melt the screen (Radix fades): it draws on dest (count pixels)
  // what the wipe shows after ticks more tics, between the screen before (scr_start) and the screen
  // after (scr_end); first is true at the first call of a wipe; true when the wipe is over
  wipe_custom_t = function(const scr_start, scr_end, dest: PLongWordArray; const count, ticks: integer;
    const first: boolean): boolean;

//==============================================================================
//
// wipe_ConfigureCustom
//
// Given by the part of the composition of a game with its own wipe (software
// renderer only). Without it, and for every other game, the screen melts.
//
//==============================================================================
procedure wipe_ConfigureCustom(const custom: wipe_custom_t);

type
  wipe_t = (
    // simple gradual pixel change for 8-bit only
    wipe_ColorXForm,
    // weird screen melt
    wipe_Melt,
    wipe_NUMWIPES
  );

{$IFDEF OPENGL}
var
  WIPESCREENWIDTH: integer;
  WIPESCREENHEIGHT: integer;

var
  w_screen32: PLongWordArray = nil;

//==============================================================================
//
// wipe_ClearMemory
//
//==============================================================================
procedure wipe_ClearMemory;
{$ENDIF}

implementation

uses
  doomdef,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_video,
{$ENDIF}
  i_system,
  DelphiDoom.Imaging.Types,
  v_data,
  v_video;

//
//                       SCREEN WIPE PACKAGE
//
// The melt is TImagingMeltWipe of Framework\Imaging (given by the composition
// root with wipe_Configure): here stay the reading of the screen, the
// buffers and the state of the wipe in progress.
//

var
  wipe_scr_start: PLongWordArray;
  wipe_scr_end: PLongWordArray;

var
  melt_wipe: IImagingMeltWipe = nil;

//==============================================================================
//
// wipe_Configure
//
//==============================================================================
procedure wipe_Configure(const AMelt: IImagingMeltWipe);
begin
  melt_wipe := AMelt;
end;

{$IFDEF OPENGL}

//==============================================================================
//
// wipe_glsize
//
//==============================================================================
function wipe_glsize(const value: integer): integer;
begin
  result := 1;
  while result < value do
    result := result * 2;
end;
{$ENDIF}

//==============================================================================
//
// wipe_initMelt
//
//==============================================================================
procedure wipe_initMelt;
var
  settings: TImagingWipeSettings;
begin
  if melt_wipe = nil then
    I_Error('wipe_initMelt(): wipe_Configure() has not been called');

  settings.Width := SCREENWIDTH;
  settings.Height := SCREENHEIGHT;
{$IFDEF OPENGL}
  WIPESCREENWIDTH := wipe_glsize(SCREENWIDTH);
  WIPESCREENHEIGHT := wipe_glsize(SCREENHEIGHT);
  if w_screen32 = nil then
    w_screen32 := malloc(WIPESCREENWIDTH * WIPESCREENHEIGHT * SizeOf(LongWord));
  settings.DestinationPitch := WIPESCREENWIDTH;
  settings.AlphaMask := $FF000000;
  melt_wipe.StartOnBuffers(settings, @wipe_scr_start[0], @wipe_scr_end[0], @w_screen32[0]);
{$ELSE}
  settings.DestinationPitch := SCREENWIDTH;
  settings.AlphaMask := 0;
  melt_wipe.StartOnBuffers(settings, @wipe_scr_start[0], @wipe_scr_end[0], @screen32[0]);
{$ENDIF}
end;

//==============================================================================
//
// wipe_exitMelt
//
//==============================================================================
procedure wipe_exitMelt;
begin
  memfree(pointer(wipe_scr_start), SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
  memfree(pointer(wipe_scr_end), SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
end;

{$IFDEF OPENGL}

//==============================================================================
//
// wipe_ClearMemory
//
//==============================================================================
procedure wipe_ClearMemory;
begin
  if w_screen32 <> nil then
    memfree(pointer(w_screen32), WIPESCREENWIDTH * WIPESCREENHEIGHT * SizeOf(LongWord));
end;
{$ENDIF}

//==============================================================================
//
// wipe_StartScreen
//
//==============================================================================
procedure wipe_StartScreen;
begin
  wipe_scr_start := malloc(SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
  I_ReadScreen32(wipe_scr_start);
{$IFDEF OPENGL}
  I_ReverseScreen(wipe_scr_start);
{$ENDIF}
end;

//==============================================================================
//
// wipe_EndScreen
//
//==============================================================================
procedure wipe_EndScreen;
begin
  wipe_scr_end := malloc(SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
  I_ReadScreen32(wipe_scr_end);
{$IFDEF OPENGL}
  I_ReverseScreen(wipe_scr_end);
{$ENDIF}
end;

var
  wiping: boolean = false;
  wipe_custom: wipe_custom_t = nil;

//==============================================================================
//
// wipe_ConfigureCustom
//
//==============================================================================
procedure wipe_ConfigureCustom(const custom: wipe_custom_t);
begin
  wipe_custom := custom;
end;

//==============================================================================
// wipe_Ticker
//
// when zero, stop the wipe
//
//==============================================================================
function wipe_Ticker(ticks: integer): boolean;
{$IFNDEF OPENGL}
var
  first: boolean;
{$ENDIF}
begin
{$IFNDEF OPENGL}
  if Assigned(wipe_custom) then
  begin
    first := not wiping;
    wiping := true;
    if wipe_custom(wipe_scr_start, wipe_scr_end, screen32, SCREENWIDTH * SCREENHEIGHT, ticks, first) then
    begin
      wiping := false;
      memfree(pointer(wipe_scr_start), SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
      memfree(pointer(wipe_scr_end), SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
    end;
    result := not wiping;
    exit;
  end;
{$ENDIF}

  // initial stuff
  if not wiping then
  begin
    wiping := true;
    wipe_initMelt;
  end;

  // do a piece of wipe-in
  if melt_wipe.Advance(ticks) then
  begin
    // final stuff
    wiping := false;
    wipe_exitMelt;
  end;

  result := not wiping;
end;

end.
