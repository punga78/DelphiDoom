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
  DelphiDoom.Video.BlitSlices,
  DelphiDoom.Video.Factory,
  DelphiDoom.Video.ModeChanger.Intf,
  DelphiDoom.Video.ScreenLayout,
  DelphiDoom.Video.Types,
  DelphiDoom.Engine.Video.ModeHost;

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

var
  graphics_started: boolean = false;
  // the sequences of the full screen modes (DelphiDoom.Video.ModeChanger): made at the first use, they need the
  // display modes and the resolution given by the composition root
  video_modechanger: IVideoModeChanger = nil;

var
  screen: PLongWordArray;
  oscreen: pointer;

var
  allocscreensize: integer;

//==============================================================================
//
// I_ModeChanger
//
//==============================================================================
function I_ModeChanger: IVideoModeChanger;
begin
  if video_modechanger = nil then
  begin
    if video_resolution = nil then
      I_Error('I_ConfigureVideoOutput() was not called: the video output is missing');
    video_modechanger := TVideoFactory.CreateModeChanger(
      TEngineVideoModeHost.Create(I_DisplayModes, video_resolution,
        function: Boolean
        begin
          Result := fixstallhack;
        end));
  end;
  Result := video_modechanger;
end;

//==============================================================================
//
// I_ShutDownGraphics
//
//==============================================================================
procedure I_ShutDownGraphics;
begin
  // the screen goes back to the resolution of the desktop
  if video_modechanger <> nil then
    video_modechanger.Release;
  graphics_started := false;
  if video_displaymodes <> nil then
    video_displaymodes.Clear;
  memfree(oscreen, allocscreensize);
end;

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
  p: array[0..7] of finishupdate8param_t;
  slicecount: integer;
  slice: TVideoBlitSlice;
  i: integer;
begin
  if (hMainWnd = 0) or (screens[SCN_FG] = nil) or (screen32 = nil) then
    exit;

  // In 32 bit mode the renderer draws directly in the frame: nothing to do.
  // The desktop depth does not matter: GDI converts the 32 bit frame when it shows it
  if videomode <> vm32bit then
  begin
    if usemultithread then
    begin
      // The bounds of the slices are TVideoBlitSlices (Framework\Video); the conversion loops stay here
      slicecount := TVideoBlitSlices.SliceCount(I_GetNumCPUs);
      for i := 0 to slicecount - 1 do
      begin
        slice := TVideoBlitSlices.Slice(SCREENWIDTH * SCREENHEIGHT, slicecount, i);
        p[i].start := slice.Start;
        p[i].finish := slice.Finish;
      end;
      case slicecount of
        2:
          MT_Execute(
            @I_FinishUpdate8_64a, @p[0],
            @I_FinishUpdate8_64a, @p[1]
          );
        3:
          MT_Execute(
            @I_FinishUpdate8_64a, @p[0],
            @I_FinishUpdate8_64a, @p[1],
            @I_FinishUpdate8_64a, @p[2]
          );
        4:
          MT_Execute(
            @I_FinishUpdate8_64a, @p[0],
            @I_FinishUpdate8_64a, @p[1],
            @I_FinishUpdate8_64a, @p[2],
            @I_FinishUpdate8_64a, @p[3]
          );
      else
        MT_Execute(
          @I_FinishUpdate8_64a, @p[0],
          @I_FinishUpdate8_64a, @p[1],
          @I_FinishUpdate8_64a, @p[2],
          @I_FinishUpdate8_64a, @p[3],
          @I_FinishUpdate8_64a, @p[4],
          @I_FinishUpdate8_64a, @p[5],
          @I_FinishUpdate8_64a, @p[6],
          @I_FinishUpdate8_64a, @p[7]
        );
      end;
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

  // the window, the full screen mode and the resolution: DelphiDoom.Video.ModeChanger
  I_ModeChanger.Initialize(fullscreen);

  // The frame is always 32 bits: GDI converts it to the depth of the desktop
  allocscreensize := TVideoScreenLayout.FrameBufferSize(SCREENWIDTH, SCREENHEIGHT);
  screen := mallocA(allocscreensize, $10000, oscreen); // JVAL: Memory padding may increase performance until 4%
  screen32 := screen;

  graphics_started := true;
end;

//==============================================================================
//
// I_ChangeFullScreen
//
//==============================================================================
procedure I_ChangeFullScreen(const newmode: integer);
begin
  I_ModeChanger.ChangeFullScreen(newmode, fullscreen);
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
