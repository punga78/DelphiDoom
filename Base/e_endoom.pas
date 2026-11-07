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

unit e_endoom;

interface

uses
  d_delphi,
  d_event,
  DelphiDoom.Endoom.Intf;

//-----------------------------------------------------------------------------
//
// DESCRIPTION:
// Game completion, endoom screen
//
//-----------------------------------------------------------------------------
var
{$IFDEF DOOM}
  EndLumpName: string = 'ENDOOM';
{$ENDIF}
{$IFDEF HERETIC}
  EndLumpName: string = 'ENDTEXT';
{$ENDIF}
{$IFDEF STRIFE}
  EndLumpName: string = 'ENDSTRF';
{$ENDIF}
  displayendscreen: boolean;

//==============================================================================
//
// E_ConfigureEndoom
//
// Gives the renderer of the screen (the composition root does it). Without it
// E_Init stops with an error.
//
//==============================================================================
procedure E_ConfigureEndoom(const ARenderer: IEndoomRenderer);

//==============================================================================
//
// E_Responder
//
//==============================================================================
function E_Responder(ev: Pevent_t): boolean;

//==============================================================================
//
// E_Init
//
//==============================================================================
procedure E_Init;

//==============================================================================
//
// E_Drawer
//
//==============================================================================
procedure E_Drawer;

//==============================================================================
//
// E_ShutDown
//
//==============================================================================
procedure E_ShutDown;

//==============================================================================
//
// E_Ticker
//
//==============================================================================
procedure E_Ticker;

{$IFDEF OPENGL}
const
  ESCREENWIDTH = 1024;
  ESCREENHEIGHT = 256;

var
  e_screen32: PLongWordArray = nil;
{$ENDIF}

implementation

uses
  doomdef,
  DelphiDoom.Endoom.Types,
  i_system,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_video,
{$ENDIF}
  v_data,
  v_video,
  w_wad,
  z_zone;

var
  e_tick: integer = 0;
  e_ticks: integer = 0;
  e_blink: boolean = true;
  e_needsupdate: boolean = true;
  e_renderer: IEndoomRenderer = nil;

//==============================================================================
//
// E_ConfigureEndoom
//
//==============================================================================
procedure E_ConfigureEndoom(const ARenderer: IEndoomRenderer);
begin
  e_renderer := ARenderer;
end;

//==============================================================================
//
// E_Responder
//
//==============================================================================
function E_Responder(ev: Pevent_t): boolean;
begin
  if ev._type <> ev_keyup then
  begin
    result := false;
    exit;
  end;

  if gamestate = GS_ENDOOM then
  begin
    result := e_ticks > TICRATE div 2;
    if result then
      I_Quit;
  end
  else
    result := false;
end;

var
  e_screen: TArray<Byte>;
  dosfont: TArray<Byte>;
  fontpalcolors: TArray<Byte>;
{$IFDEF OPENGL}
  e_screen32data: TArray<LongWord>;
{$ENDIF}

//==============================================================================
//
// E_Init
//
//==============================================================================
procedure E_Init;
var
  dosfontlump: integer;
  i: integer;
  pal: PByteArray;
  src: pointer;
begin
  if e_renderer = nil then
    I_Error('E_Init(): the ENDOOM renderer is not configured');

  e_ticks := 1;
  dosfontlump := W_CheckNumForName('DOSFONT');
  if dosfontlump >= 0 then
  begin
    SetLength(dosfont, W_LumpLength(dosfontlump));
    if Length(dosfont) > 0 then
    begin
      src := W_CacheLumpNum(dosfontlump, PU_STATIC);
      Move(src^, dosfont[0], Length(dosfont));
      Z_ChangeTag(src, PU_CACHE);
    end;
  end
  else
  begin
    I_Warning('E_Init(): Can not find DOSFONT lump'#13#10);
    SetLength(dosfont, 0);
  end;

  pal := V_ReadPalette(PU_STATIC);
  V_SetPalette(pal);
  I_SetPalette(pal);
  Z_ChangeTag(pal, PU_CACHE);

  SetLength(fontpalcolors, ENDOOM_COLOR_COUNT);
  for i := 0 to ENDOOM_COLOR_COUNT - 1 do
    fontpalcolors[i] := V_FindAproxColorIndex(@curpal, ENDOOM_COLORS[i]);

  e_needsupdate := true;
end;

//==============================================================================
//
// E_Drawer
//
//==============================================================================
procedure E_Drawer;
var
  endoomlump: integer;
  endoomdata: TArray<Byte>;
  src: pointer;
  pal: PByteArray;
{$IFDEF OPENGL}
  ix: integer;
  palette: array[0..ENDOOM_PALETTE_SIZE - 1] of LongWord;
{$ENDIF}
begin
  pal := V_ReadPalette(PU_STATIC);
  V_SetPalette(pal);
  I_SetPalette(pal);
  Z_ChangeTag(pal, PU_CACHE);

  if e_needsupdate then
  begin
    endoomlump := W_GetNumForName(EndLumpName);
    SetLength(endoomdata, W_LumpLength(endoomlump));
    if Length(endoomdata) > 0 then
    begin
      src := W_CacheLumpNum(endoomlump, PU_STATIC);
      Move(src^, endoomdata[0], Length(endoomdata));
      Z_ChangeTag(src, PU_CACHE);
    end;
    e_renderer.RenderIndexed(endoomdata, dosfont, fontpalcolors, e_blink, e_screen);
    e_needsupdate := false;
  end;

{$IFDEF OPENGL}
  // the texture is 1024x256: the renderer fills the first 200 rows, the rest stays at zero
  if Length(e_screen32data) = 0 then
    SetLength(e_screen32data, ESCREENWIDTH * ESCREENHEIGHT);
  for ix := 0 to ENDOOM_PALETTE_SIZE - 1 do
    palette[ix] := videopal[ix];
  e_renderer.ConvertToRgb32(e_screen, palette, ESCREENWIDTH, e_screen32data);
  e_screen32 := PLongWordArray(@e_screen32data[0]);
{$ELSE}
  V_CopyCustomScreen(PByteArray(@e_screen[0]), ENDOOM_WIDTH, ENDOOM_HEIGHT, SCN_FG);
{$ENDIF}
end;

//==============================================================================
//
// E_ShutDown
//
//==============================================================================
procedure E_ShutDown;
begin
  SetLength(e_screen, 0);
  SetLength(dosfont, 0);
{$IFDEF OPENGL}
  e_screen32 := nil;
  SetLength(e_screen32data, 0);
{$ENDIF}
end;

//==============================================================================
//
// E_Ticker
//
//==============================================================================
procedure E_Ticker;
var
  blink: boolean;
begin
  if e_ticks > 0 then
  begin
    inc(e_ticks);
    if e_ticks > 10 * TICRATE then
      I_Quit;
    inc(e_tick);
    if e_tick >= TICRATE then
      e_tick := 0;
    blink := e_tick > TICRATE div 2;
    if blink <> e_blink then
    begin
      e_blink := not e_blink;
      e_needsupdate := true;
    end;
  end;
end;

end.
