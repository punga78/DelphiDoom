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
//   System specific interface stuff.
//   GDI DOOM graphics
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_video;

interface

uses
  SysUtils,
  Windows,
  d_delphi,
  DelphiDoom.Video.Intf,
  DelphiDoom.Engine.Video.FramePresenter.Intf;

//==============================================================================
//
// I_ConfigureVideoOutput
// Where the frame goes (the window) and who changes the resolution of the screen.
// The composition root calls it; without it I_InitGraphics stops with I_Error
//
//==============================================================================
procedure I_ConfigureVideoOutput(const APresenter: IEngineFramePresenter;
  const AResolution: IEngineDisplayResolution);

//==============================================================================
//
// I_ConfigureDisplayModes
// The catalog of the screen modes, filled when the graphics start and cleared when they stop.
// The composition root calls it; without it I_InitGraphics stops with I_Error
//
//==============================================================================
procedure I_ConfigureDisplayModes(const ACatalog: IDisplayModeCatalog);

//==============================================================================
// I_InitGraphics
//
// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
//
//==============================================================================
procedure I_InitGraphics;

//==============================================================================
//
// I_ChangeFullScreen
//
//==============================================================================
procedure I_ChangeFullScreen(const newmode: integer);

//==============================================================================
//
// I_ShutDownGraphics
//
//==============================================================================
procedure I_ShutDownGraphics;

//==============================================================================
// I_SetPalette
//
// Takes full 8 bit values.
//
//==============================================================================
procedure I_SetPalette(const palette: PByteArray);

//==============================================================================
//
// IV_SetPalette
//
//==============================================================================
procedure IV_SetPalette(const palette: PByteArray);

//==============================================================================
//
// I_BlitBuffer
//
//==============================================================================
procedure I_BlitBuffer;

//==============================================================================
//
// I_FinishUpdate
//
//==============================================================================
procedure I_FinishUpdate;

//==============================================================================
//
// I_ReadScreen32
//
//==============================================================================
procedure I_ReadScreen32(dest: pointer);

//==============================================================================
//
// I_SetPalette64
//
//==============================================================================
procedure I_SetPalette64;

var
  fixstallhack: boolean = true;
  r_blitmultiplier: integer = 1;

implementation

uses
  doomdef,
  mt_utils,
  i_system,
  i_main,
  i_mainwindow,
  r_hires,
  v_data,
  v_video,
  DelphiDoom.Video.Types;

var
  // given by the composition root (I_ConfigureDisplayModes)
  video_displaymodes: IDisplayModeCatalog = nil;
  // given by the composition root (I_ConfigureVideoOutput)
  video_presenter: IEngineFramePresenter = nil;
  video_resolution: IEngineDisplayResolution = nil;

//==============================================================================
//
// I_ConfigureVideoOutput
//
//==============================================================================
procedure I_ConfigureVideoOutput(const APresenter: IEngineFramePresenter;
  const AResolution: IEngineDisplayResolution);
begin
  video_presenter := APresenter;
  video_resolution := AResolution;
end;

//==============================================================================
//
// I_ConfigureDisplayModes
//
//==============================================================================
procedure I_ConfigureDisplayModes(const ACatalog: IDisplayModeCatalog);
begin
  video_displaymodes := ACatalog;
end;

//==============================================================================
//
// I_DisplayModes
//
//==============================================================================
function I_DisplayModes: IDisplayModeCatalog;
begin
  if video_displaymodes = nil then
    I_Error('I_ConfigureDisplayModes() was not called: the display modes are missing');
  result := video_displaymodes;
end;

//==============================================================================
//
// I_FindWindowSize
//
// The window of a mode: the exact or nearest mode of the catalog, else the screen
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

  if I_DisplayModes.FindWindowSize(SCREENWIDTH, SCREENHEIGHT, w, h) then
  begin
    WINDOWWIDTH := w;
    WINDOWHEIGHT := h;
    exit;
  end;

  WINDOWWIDTH := GetSystemMetrics(SM_CXSCREEN);
  WINDOWHEIGHT := GetSystemMetrics(SM_CYSCREEN);
end;

var
  graphics_started: boolean = false;
  // the screen was set to another resolution (the exclusive full screen mode)
  video_resolution_changed: boolean = false;
  dpi: integer;

var
  s_alttab_disabled: boolean = false;

var
  screen: PLongWordArray;
  oscreen: pointer;

//==============================================================================
//
// I_RestoreWindowPos
//
//==============================================================================
procedure I_RestoreWindowPos(const mode: integer);
var
  dw, dh: integer;
begin
  if mode = FULLSCREEN_OFF then
  begin
    SetWindowLong(hMainWnd, GWL_STYLE, WINDOW_STYLE_W);
    SetWindowPos(hMainWnd, HWND_TOP, windowxpos, windowypos, WINDOWWIDTH, WINDOWHEIGHT, SWP_SHOWWINDOW);
    I_GetWindowClientOffset(dw, dh);
    SetWindowPos(hMainWnd, HWND_TOP, windowxpos, windowypos, WINDOWWIDTH + dw, WINDOWHEIGHT + dh, SWP_SHOWWINDOW);
  end
  else
  begin
    SetWindowLong(hMainWnd, GWL_STYLE, WINDOW_STYLE_FS);
    SetWindowPos(hMainWnd, HWND_TOP, 0, 0, WINDOWWIDTH, WINDOWHEIGHT, SWP_SHOWWINDOW);
  end;
end;

//==============================================================================
//
// I_DisableAltTab
//
//==============================================================================
procedure I_DisableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
    Exit;

  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if isLibrary then
      RegisterHotKey(0, $C000, MOD_ALT, VK_TAB)
    else
      RegisterHotKey(0, 0, MOD_ALT, VK_TAB)
  end
  else
    SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @old, 0);

  s_alttab_disabled := true;
end;

//==============================================================================
//
// I_EnableAltTab
//
//==============================================================================
procedure I_EnableAltTab;
var
  old: Boolean;
begin
  if s_alttab_disabled then
  begin
    if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
      if isLibrary then
        UnregisterHotKey(0, $C000)
      else
        UnregisterHotKey(0, 0)
    end
    else
      SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @old, 0);

    s_alttab_disabled := false;
  end;
end;

var
  allocscreensize: integer;

//==============================================================================
//
// I_ShutDownGraphics
//
//==============================================================================
procedure I_ShutDownGraphics;
begin
  // the screen goes back to the resolution of the desktop
  if video_resolution_changed and (video_resolution <> nil) then
    video_resolution.Restore;
  video_resolution_changed := false;
  graphics_started := false;
  I_EnableAltTab;
  if video_displaymodes <> nil then
    video_displaymodes.Clear;
  memfree(oscreen, allocscreensize);
end;

var
  stallhack: boolean;

var
  curpal64: array[0..$FFFF] of Int64;

//==============================================================================
// I_SetPalette64
//
// JVAL: Create extended pallete of int64 values for fast update in 8 bid color mode
//
//==============================================================================
procedure I_SetPalette64;
var
  idx: twobytes_t;
  pitem: twolongwords_t;
  i, j: integer;
begin
  for i := 0 to 255 do
  begin
    idx.byte1 := i;
    pitem.longword1 := curpal[i];
    for j := 0 to 255 do
    begin
      idx.byte2 := j;
      pitem.longword2 := curpal[j];
      curpal64[PWord(@idx)^] := PInt64(@pitem)^;
    end;
  end;
end;

//==============================================================================
//
// I_FinishUpdate8_64
//
//==============================================================================
procedure I_FinishUpdate8_64;
var
  dest: PInt64;
  src: PWord;
  srcstop: PByte;
begin
  src := @(screens[SCN_FG][0]);
  srcstop := @(screens[SCN_FG][SCREENWIDTH * SCREENHEIGHT - 1]);

  dest := @screen[0];
  while NativeInt(src) < NativeInt(srcstop) do
  begin
    dest^ := curpal64[src^];
    inc(dest);
    inc(src);
  end;
end;

type
  finishupdate8param_t = record
    start, finish: integer;
  end;
  Pfinishupdate8param_t = ^finishupdate8param_t;

//==============================================================================
//
// I_FinishUpdate8_64a
//
//==============================================================================
function I_FinishUpdate8_64a(p: pointer): integer; stdcall;
var
  dest: PInt64;
  src: PWord;
  srcstop: PByte;
begin
  src := @(screens[SCN_FG][Pfinishupdate8param_t(p).start]);
  srcstop := @(screens[SCN_FG][Pfinishupdate8param_t(p).finish]);

  dest := @screen[Pfinishupdate8param_t(p).start];
  while NativeInt(src) < NativeInt(srcstop) do
  begin
    dest^ := curpal64[src^];
    inc(dest);
    inc(src);
  end;
  result := 0;
end;

//==============================================================================
//
// I_BlitBuffer
//
//==============================================================================
procedure I_BlitBuffer;
var
  p1, p2, p3, p4, p5, p6, p7, p8: finishupdate8param_t;
begin
  if (hMainWnd = 0) or (screens[SCN_FG] = nil) or (screen32 = nil) then
    exit;

  // In 32 bit mode the renderer draws directly in the frame: nothing to do.
  // The desktop depth does not matter: GDI converts the 32 bit frame when it shows it
  if videomode <> vm32bit then
  begin
    if usemultithread then
    begin
      if I_GetNumCPUs <= 2 then
      begin
        p1.start := 0;
        p1.finish := (SCREENWIDTH * SCREENHEIGHT div 2) and not 3;
        p2.start := p1.finish + 1;
        p2.finish := SCREENWIDTH * SCREENHEIGHT - 1;
        MT_Execute(
          @I_FinishUpdate8_64a, @p1,
          @I_FinishUpdate8_64a, @p2
        );
      end
      else if I_GetNumCPUs <= 4 then
      begin
        p1.start := 0;
        p1.finish := (SCREENWIDTH * SCREENHEIGHT div 3) and not 3;
        p2.start := p1.finish + 1;
        p2.finish := (2 * SCREENWIDTH * SCREENHEIGHT div 3) and not 3;
        p3.start := p2.finish + 1;
        p3.finish := SCREENWIDTH * SCREENHEIGHT - 1;
        MT_Execute(
          @I_FinishUpdate8_64a, @p1,
          @I_FinishUpdate8_64a, @p2,
          @I_FinishUpdate8_64a, @p3
        );
      end
      else if I_GetNumCPUs <= 6 then
      begin
        p1.start := 0;
        p1.finish := (SCREENWIDTH * SCREENHEIGHT div 4) and not 3;
        p2.start := p1.finish + 1;
        p2.finish := (2 * SCREENWIDTH * SCREENHEIGHT div 4) and not 3;
        p3.start := p2.finish + 1;
        p3.finish := (3 * SCREENWIDTH * SCREENHEIGHT div 4) and not 3;
        p4.start := p3.finish + 1;
        p4.finish := SCREENWIDTH * SCREENHEIGHT - 1;
        MT_Execute(
          @I_FinishUpdate8_64a, @p1,
          @I_FinishUpdate8_64a, @p2,
          @I_FinishUpdate8_64a, @p3,
          @I_FinishUpdate8_64a, @p4
        );
      end
      else
      begin
        p1.start := 0;
        p1.finish := (SCREENWIDTH * SCREENHEIGHT div 8) and not 3;
        p2.start := p1.finish + 1;
        p2.finish := (2 * SCREENWIDTH * SCREENHEIGHT div 8) and not 3;
        p3.start := p2.finish + 1;
        p3.finish := (3 * SCREENWIDTH * SCREENHEIGHT div 8) and not 3;
        p4.start := p3.finish + 1;
        p4.finish := (4 * SCREENWIDTH * SCREENHEIGHT div 8) and not 3;
        p5.start := p4.finish + 1;
        p5.finish := (5 * SCREENWIDTH * SCREENHEIGHT div 8) and not 3;
        p6.start := p5.finish + 1;
        p6.finish := (6 * SCREENWIDTH * SCREENHEIGHT div 8) and not 3;
        p7.start := p6.finish + 1;
        p7.finish := (7 * SCREENWIDTH * SCREENHEIGHT div 8) and not 3;
        p8.start := p7.finish + 1;
        p8.finish := SCREENWIDTH * SCREENHEIGHT - 1;
        MT_Execute(
          @I_FinishUpdate8_64a, @p1,
          @I_FinishUpdate8_64a, @p2,
          @I_FinishUpdate8_64a, @p3,
          @I_FinishUpdate8_64a, @p4,
          @I_FinishUpdate8_64a, @p5,
          @I_FinishUpdate8_64a, @p6,
          @I_FinishUpdate8_64a, @p7,
          @I_FinishUpdate8_64a, @p8
        );
      end
    end
    else
      I_FinishUpdate8_64;
  end;
end;

//==============================================================================
//
// I_FinishUpdate
//
//==============================================================================
procedure I_FinishUpdate;
var
  destrect: TRect;
begin
  I_BlitBuffer;

  if video_presenter = nil then
    I_Error('I_ConfigureVideoOutput() was not called: the video output is missing');

  r_blitmultiplier := GetIntegerInRange(r_blitmultiplier, 1, 4);

  // the frame goes to the client area of the window, stretched when the window has another size
  destrect.Left := 0;
  destrect.Top := 0;
  destrect.Right := WINDOWWIDTH;
  destrect.Bottom := WINDOWHEIGHT;

  // the position of the window is saved in the configuration
  if fullscreen = FULLSCREEN_OFF then
    I_GetWindowPosition(windowxpos, windowypos);

  video_presenter.Present(screen32, SCREENWIDTH, SCREENHEIGHT, destrect, r_blitmultiplier);
end;

//==============================================================================
//
// Palette stuff.
//
// I_SetPalette
//
//==============================================================================
procedure I_SetPalette(const palette: PByteArray);
begin
  I_VideoServices.Palette.Convert(System.PByte(palette), System.PByte(@gammatable[usegamma]), System.PCardinal(@curpal[0]));
  if videomode = vm8bit then
    I_SetPalette64;
end;

//==============================================================================
//
// IV_SetPalette
//
//==============================================================================
procedure IV_SetPalette(const palette: PByteArray);
begin
  I_VideoServices.Palette.Convert(System.PByte(palette), System.PByte(@gammatable[usegamma]), System.PCardinal(@curpal[0]));
  if videomode = vm8bit then
    I_SetPalette64;
  V_SetPalette(palette);
end;

//==============================================================================
//
// I_AdjustWindowMode
//
//==============================================================================
function I_AdjustWindowMode: boolean;
begin
  result := I_VideoServices.SizeLimiter.Limit(WINDOWWIDTH, WINDOWHEIGHT);
end;

//==============================================================================
//
// I_MemoryStallHack
//
//==============================================================================
function I_MemoryStallHack: boolean;
// JVAL: Memory stall can dramatically reduce performance in inc operation of
// esi register of value 4096 etc
// e.g.
//  mov [esp], 4096 (=SCREENWIDTH(=1024) * SizeOf(LongWord)(=4)
//  add esi, [esp]
// The above code is dramatically slower than:
//  mov [esp], 4088 (=SCREENWIDTH(=1022) * SizeOf(LongWord)(=4)
//  add esi, [esp]
// It's crazy!
begin
  result := I_VideoServices.StallHack.Apply(SCREENWIDTH, fixstallhack);
  stallhack := result;
end;

const
  ERROR_OFFSET = 20;

//==============================================================================
// I_InitGraphics
//
// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
//
//==============================================================================
procedure I_InitGraphics;
begin
  if graphics_started then
    exit;

  if (video_presenter = nil) or (video_resolution = nil) then
    I_Error('I_ConfigureVideoOutput() was not called: the video output is missing');

  ShowWindow(hMainWnd, SW_SHOW);
  UpdateWindow(hMainWnd);

  printf('I_InitGraphics: Initializing the GDI display.'#13#10);

  I_DisplayModes.Refresh(MAXWIDTH, MAXHEIGHT);

  fullscreen := fullscreen mod NUMFULLSCREEN_MODES;

  if fullscreen = FULLSCREEN_EXCLUSIVE then
  begin
    I_FindWindowSize(fullscreen);

    // Set the video mode to WINDOWWIDTH x WINDOWHEIGHT x 32
    if video_resolution.Change(WINDOWWIDTH, WINDOWHEIGHT) then
    begin
      video_resolution_changed := true;
      I_RestoreWindowPos(fullscreen);
      I_DisableAltTab;
    end
    else
    begin
    // Fullscreen mode failed, trying window mode
      fullscreen := FULLSCREEN_SHARED;

      I_AdjustWindowMode;
      I_RestoreWindowPos(fullscreen);

      I_Warning('SetDisplayMode(): Failed to fullscreen %dx%dx%d, trying window mode...'#13#10,
        [WINDOWWIDTH, WINDOWHEIGHT, 32]);
      printf('Window Mode %dx%d'#13#10, [SCREENWIDTH, SCREENHEIGHT]);
    end;
  end
  else
  begin
    I_FindWindowSize(fullscreen);
    I_AdjustWindowMode;
    I_RestoreWindowPos(fullscreen);
  end;

  if I_MemoryStallHack then
    V_ReInit;

  // The frame is always 32 bits: GDI converts it to the depth of the desktop
  allocscreensize := SCREENWIDTH * (SCREENHEIGHT + ERROR_OFFSET) * SizeOf(LongWord) and not (4095);
  screen := mallocA(allocscreensize, $10000, oscreen); // JVAL: Memory padding may increase performance until 4%
  screen32 := screen;

  graphics_started := true;

  dpi := I_GetWindowDPI(hMainWnd);
end;

const
  NUMSTDRESOLUTIONS = 11;
  STANDARDSCREENRESOLUTIONS: array[0..NUMSTDRESOLUTIONS - 1, 0..1] of integer = (
    (1920, 1080), (1366, 768), (1280, 1024), (1280, 800), (1024, 768), (800, 600), (640, 480), (600, 400), (512, 384), (400, 300), (320, 200)
  );

//==============================================================================
//
// I_ChangeFullScreen
//
//==============================================================================
procedure I_ChangeFullScreen(const newmode: integer);

  procedure I_ChangeFullScreenError(full: boolean);
  begin
    if full then
      I_Warning('I_ChangeFullScreen(): Can not change to fullscreen mode'#13#10)
    else
      I_Warning('I_ChangeFullScreen(): Can not change to window mode'#13#10);
  end;

var
  i: integer;
  changed: boolean;

begin
  if video_resolution = nil then
    I_Error('I_ConfigureVideoOutput() was not called: the video output is missing');

  WINDOWWIDTH := SCREENWIDTH;
  WINDOWHEIGHT := SCREENHEIGHT;

  I_FindWindowSize(newmode);
  I_AdjustWindowMode;
  I_RestoreWindowPos(newmode);

  if newmode = FULLSCREEN_EXCLUSIVE then
    changed := video_resolution.Change(WINDOWWIDTH, WINDOWHEIGHT)
  else
  begin
    // the desktop resolution is the native one
    video_resolution.Restore;
    video_resolution_changed := false;
    changed := true;
  end;

  if not changed then
  begin
    i := 0;

    // Determine a standard screen resolution
    WINDOWWIDTH := STANDARDSCREENRESOLUTIONS[NUMSTDRESOLUTIONS - 1, 0];
    WINDOWHEIGHT := STANDARDSCREENRESOLUTIONS[NUMSTDRESOLUTIONS - 1, 1];
    while i < NUMSTDRESOLUTIONS - 1 do
    begin
      if (WINDOWWIDTH <= STANDARDSCREENRESOLUTIONS[i, 0]) and
         (WINDOWHEIGHT <= STANDARDSCREENRESOLUTIONS[i, 1]) and
         (WINDOWWIDTH >= STANDARDSCREENRESOLUTIONS[i + 1, 0]) then
      begin
        WINDOWWIDTH := STANDARDSCREENRESOLUTIONS[i, 0];
        WINDOWHEIGHT := STANDARDSCREENRESOLUTIONS[i, 1];
        break;
      end;
      inc(i);
    end;

    if not video_resolution.Change(WINDOWWIDTH, WINDOWHEIGHT) then
    begin
      I_ChangeFullScreenError(fullscreen <> FULLSCREEN_OFF);
      exit;
    end;
  end;

  if newmode = FULLSCREEN_EXCLUSIVE then
  begin
    video_resolution_changed := true;
    // the system may have moved the window when the resolution changed
    I_RestoreWindowPos(newmode);
  end;

  fullscreen := newmode;

  dpi := I_GetWindowDPI(hMainWnd);
end;

//==============================================================================
//
// I_ReadScreen32
//
//==============================================================================
procedure I_ReadScreen32(dest: pointer);
var
  i: integer;
  destl: PLongWord;
  src: PByte;
begin
  if videomode = vm8bit then
  begin
    src := @(screens[SCN_FG]^);
    destl := dest;
    for i := 0 to SCREENWIDTH * SCREENHEIGHT - 1 do
    begin
      destl^ := curpal[src^];
      inc(destl);
      inc(src);
    end;
  end
  else
    MT_memcpy(dest, screen32, SCREENWIDTH * SCREENHEIGHT * SizeOf(LongWord));
end;

end.
