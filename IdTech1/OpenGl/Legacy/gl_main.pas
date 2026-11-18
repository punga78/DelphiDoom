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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  System specific interface stuff.
//  OpenGL DOOM graphics
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit gl_main;

interface

uses
  SysUtils,
  Windows,
  d_delphi,
  DelphiDoom.Engine.Console.Intf,
  DelphiDoom.Input.Intf,
  DelphiDoom.Video.Intf{$IFNDEF HEXEN},
  DelphiDoom.Engine.Endoom.Intf{$ENDIF};

//==============================================================================
//
// GL_ConfigureInput
// The poller of the input: the window tells it when it gains or loses the focus.
// The composition root calls it
//
//==============================================================================
procedure GL_ConfigureInput(const APoller: IInputPoller);

//==============================================================================
//
// GL_ConfigureDisplayModes
// The catalog of the screen modes, filled when the graphics start and cleared when they stop.
// The composition root calls it; without it GL_InitGraphics stops with I_Error
//
//==============================================================================
procedure GL_ConfigureDisplayModes(const ACatalog: IDisplayModeCatalog);

{$IFNDEF HEXEN}
//==============================================================================
//
// GL_ConfigureEndoom
// The end screen, shown in a texture. The composition root calls it
//
//==============================================================================
procedure GL_ConfigureEndoom(const AScreen: IEngineEndoomScreen);
{$ENDIF}

//==============================================================================
// GL_InitGraphics
//
// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
//
//==============================================================================
procedure GL_InitGraphics;

//==============================================================================
//
// GL_ChangeFullScreen
//
//==============================================================================
procedure GL_ChangeFullScreen(const full: boolean);

//==============================================================================
//
// GL_SetDisplayMode
//
//==============================================================================
function GL_SetDisplayMode(const newwidth, newheight: integer; const force: boolean = false): boolean;

//==============================================================================
//
// GL_NotifyDisplayMode
//
//==============================================================================
procedure GL_NotifyDisplayMode;

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
// I_FinishUpdate
//
//==============================================================================
procedure I_FinishUpdate;

//==============================================================================
//
// I_StartUpdate
//
//==============================================================================
procedure I_StartUpdate;

//==============================================================================
//
// I_ReadScreen32
//
//==============================================================================
procedure I_ReadScreen32(dest: pointer);

//==============================================================================
//
// I_ReverseScreen
//
//==============================================================================
procedure I_ReverseScreen(const p: PLongWordArray);

//==============================================================================
//
// I_RestoreWindowPos
//
//==============================================================================
procedure I_RestoreWindowPos;

var
  fixstallhack: boolean = true;

//==============================================================================
//
// GL_Initialized
// True once OpenGL was loaded by GL_InitGraphics (the renderer has resources to release)
//
//==============================================================================
function GL_Initialized: boolean;

//==============================================================================
//
// GL_SwapBuffers
// Shows the frame that was drawn
//
//==============================================================================
procedure GL_SwapBuffers;

//==============================================================================
//
// DoomMain
//
//==============================================================================
procedure DoomMain;

var
  NATIVEWIDTH: integer;
  NATIVEHEIGHT: integer;

//==============================================================================
//
// GL_ConfigureConsole
// The console, given by the composition root
//
//==============================================================================
procedure GL_ConfigureConsole(const AConsole: IEngineConsole);

implementation

uses
  Messages,
  am_map,
  c_con,
  doomdef,
  d_main,
  d_net,
  d_notifications,
  g_game,
  hu_stuff,
  {$IFDEF DOOM}
  r_draw,
  st_stuff,
  {$ENDIF}
  {$IFDEF STRIFE}
  f_fade,
  {$ELSE}
  f_wipe,
  {$ENDIF}
  r_main,
  mt_utils,
  r_hires,
  i_mainwindow,
  i_system,
  m_argv,
  m_menu,
  psi_overlay,
  dglOpenGL,
  gl_render, // JVAL OPENGL
  gl_tex,
  gl_defs,
  DelphiDoom.Engine.GlContext,
  DelphiDoom.Engine.GlFrameEnder,
  DelphiDoom.GlContext.DisplayModeClamp,
  v_data,
  v_video;

var
  // given by the composition root
  gl_console_ref: IEngineConsole = nil;

//==============================================================================
//
// GL_ConfigureConsole
//
//==============================================================================
procedure GL_ConfigureConsole(const AConsole: IEngineConsole);
begin
  gl_console_ref := AConsole;
end;

//==============================================================================
//
// GL_Console
//
//==============================================================================
function GL_Console: IEngineConsole;
begin
  if gl_console_ref = nil then
    I_Error('GL_ConfigureConsole() was not called: the console is missing');
  result := gl_console_ref;
end;


var
  // given by the composition root (GL_ConfigureInput, GL_ConfigureDisplayModes, GL_ConfigureEndoom)
  gl_input: IInputPoller = nil;
  gl_displaymodes: IDisplayModeCatalog = nil;
{$IFNDEF HEXEN}
  gl_endoom: IEngineEndoomScreen = nil;
{$ENDIF}

//==============================================================================
//
// GL_ConfigureInput
//
//==============================================================================
procedure GL_ConfigureInput(const APoller: IInputPoller);
begin
  gl_input := APoller;
end;

//==============================================================================
//
// GL_ConfigureDisplayModes
//
//==============================================================================
procedure GL_ConfigureDisplayModes(const ACatalog: IDisplayModeCatalog);
begin
  gl_displaymodes := ACatalog;
end;

{$IFNDEF HEXEN}
//==============================================================================
//
// GL_ConfigureEndoom
//
//==============================================================================
procedure GL_ConfigureEndoom(const AScreen: IEngineEndoomScreen);
begin
  gl_endoom := AScreen;
end;
{$ENDIF}

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
procedure I_RestoreWindowPos;
var
  dw, dh: integer;
begin
  if not fullscreen then
  begin
    SetWindowLong(hMainWnd, GWL_STYLE, Longint(WINDOW_STYLE_W));
    SetWindowPos(hMainWnd, HWND_TOP, windowxpos, windowypos, SCREENWIDTH, SCREENHEIGHT, SWP_SHOWWINDOW);
    I_GetWindowClientOffset(dw, dh);
    SetWindowPos(hMainWnd, HWND_TOP, windowxpos, windowypos, SCREENWIDTH + dw, SCREENHEIGHT + dh, SWP_SHOWWINDOW);
  end
  else
  begin
    SetWindowLong(hMainWnd, GWL_STYLE, WINDOW_STYLE_FS);
    SetWindowPos(hMainWnd, HWND_NOTOPMOST, 0, 0, SCREENWIDTH, SCREENHEIGHT, SWP_SHOWWINDOW);
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

var
  // the window and the rendering context: created by GL_InitGraphics, released by I_ShutDownGraphics, freed
  // when the program ends (R_ShutDownOpenGL still asks GL_Initialized after the context was released)
  gl_context: TEngineGlContext = nil;

//==============================================================================
//
// GL_Initialized
//
//==============================================================================
function GL_Initialized: boolean;
begin
  result := (gl_context <> nil) and gl_context.Initialized;
end;

//==============================================================================
//
// GL_SwapBuffers
//
//==============================================================================
procedure GL_SwapBuffers;
begin
  gl_context.SwapBuffers;
end;

var
  // the end of a frame (overlay, wipe, ENDOOM): created by GL_InitGraphics, freed when the program ends
  gl_frameender: TEngineGlFrameEnder = nil;

//==============================================================================
//
// I_ShutDownGraphics
//
//==============================================================================
procedure I_ShutDownGraphics;
begin
  gld_ShutDownTextures;
  if gl_frameender <> nil then
    gl_frameender.ReleaseTextures;
  if gl_context <> nil then
    gl_context.Close;
  I_EnableAltTab;
  if gl_displaymodes <> nil then
    gl_displaymodes.Clear;
  memfree(oscreen, allocscreensize);
end;

{$IFNDEF HEXEN}
var
  enterendoom: boolean = false;
{$ENDIF}

var
  wipe: boolean = false;

//==============================================================================
//
// I_StartUpdate
//
//==============================================================================
procedure I_StartUpdate;
begin
  if not wipe then
  begin
    if Ord(TGameSession.GameState) <> wipegamestate then
      {$IFNDEF HEXEN}
      if TGameSession.GameState <> GS_ENDOOM then
      {$ENDIF}
      begin
        wipe := true;
        {$IFDEF STRIFE}fade_StartScreen{$ELSE}wipe_StartScreen{$ENDIF};
        wipegamestate := Ord(TGameSession.GameState);
      end;
  end;
//  else
//    printf('I_StartUpdate(): fuck!');
end;

var
  oldfullscreen: integer = -1;

//==============================================================================
//
// I_FinishUpdate
//
//==============================================================================
procedure I_FinishUpdate;
var
  wipestart: integer;
  nowtime: integer;
  tics: integer;
  done: boolean;
begin
  if (hMainWnd = 0) or (screens[SCN_FG] = nil) or (screen32 = nil) then
    exit;

  if intval(fullscreen) <> oldfullscreen then
  begin
    D_NotifyGLDisplayMode;
    oldfullscreen := intval(fullscreen);
  end;

  if not fullscreen then
    I_GetWindowPosition(windowxpos, windowypos);

  {$IFNDEF HEXEN}
  if (TGameSession.GameState = GS_ENDOOM) or enterendoom then
  begin
    enterendoom := true;
    gl_frameender.FinishEndoom;
    exit;
  end;
  {$ENDIF}

  gl_frameender.FinishOverlay(not wipe);  // Will also flush

  if not wipe then
    exit;

  // wipe update
  {$IFDEF STRIFE}
  fade_EndScreen;
  {$ELSE}
  wipe_EndScreen;
  {$ENDIF}

  wipedisplay := true;
  wipestart := I_GetTime - 1;

  firstinterpolation := true;

  repeat
    repeat
      nowtime := I_GetTime;
      tics := nowtime - wipestart;
      I_WaitVBL(1);
    until tics <> 0;
    wipestart := nowtime;
    done := {$IFDEF STRIFE}fade_Ticker{$ELSE}wipe_Ticker{$ENDIF}(tics);
    MT_ZeroMemory(screen32, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) * 4);
    M_Drawer;         // Menu is drawn even on top of wipes
    GL_Console.Draw;         // Console draw on top of wipes and menus
    gl_frameender.FinishWipe;
    HU_DoFPSStuff;
  until done;
  {$IFDEF STRIFE}
  fade_ClearMemory;
  {$ELSE}
  wipe_ClearMemory;
  {$ENDIF}
  wipedisplay := false;
  wipe := false;
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
end;

//==============================================================================
//
// I_AdjustWindowMode
//
//==============================================================================
function I_AdjustWindowMode: boolean;
begin
  result := I_VideoServices.SizeLimiter.Limit(SCREENWIDTH, SCREENHEIGHT);
end;

const
  ERROR_OFFSET = 20;

//==============================================================================
//
// WindowProc
//
//==============================================================================
function WindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall; export;
begin
  if not I_GameFinished then
  begin
    case Msg of
      WM_SETCURSOR:
        begin
          SetCursor(0);
        end;
      WM_SYSCOMMAND:
        begin
          if (wParam = SC_SCREENSAVE) or (wParam = SC_MINIMIZE) then
          begin
            result := 0;
            exit;
          end;
          if fullscreen and (wParam = SC_TASKLIST) then
          begin
            result := 0;
            exit;
          end;
        end;
      WM_SIZE:
        begin
//          glResizeWnd;
          result := 0;
          exit;
        end;
      WM_ACTIVATE:
        begin
          InBackground := (LOWORD(wparam) = WA_INACTIVE) or (HIWORD(wparam) <> 0);
          if gl_input <> nil then
            gl_input.Synchronize(not InBackground);
        end;
      WM_CLOSE:
        begin
          result := 0; // Preserve closing window by pressing Alt + F4
          exit;
        end;
      WM_DESTROY:
        begin
          result := 0;
          ShowWindow(hWnd, SW_HIDE);
          I_Destroy(0);
          exit;
        end;
    end;
  end;

  result := DefWindowProc(hWnd, Msg, WParam, LParam);
end;

//==============================================================================
// GL_InitGraphics
//
// Called by D_DoomMain,
// determines the hardware configuration
// and sets up the video mode
//
//==============================================================================
procedure GL_InitGraphics;
begin
  printf('GL_InitGraphics: Initializing OpenGL.'#13#10);

  if gl_displaymodes = nil then
    I_Error('GL_ConfigureDisplayModes() was not called: the display modes are missing');
  gl_displaymodes.Refresh(MAXWIDTH, MAXHEIGHT);

  if gl_context = nil then
    gl_context := TEngineGlContext.Create;
  gl_context.Open(TFNWndProc(@WindowProc));

  if gl_frameender = nil then
    gl_frameender := TEngineGlFrameEnder.Create(GL_Console{$IFNDEF HEXEN}, gl_endoom{$ENDIF});

  // Ensure the OpenGL window is resized properly
  TEngineGlContext.ResizeViewport;
  TEngineGlContext.InitState;

  gld_Init(SCREENWIDTH, SCREENHEIGHT);

  allocscreensize := 2048 * (1536 + ERROR_OFFSET) * SizeOf(LongWord) and not (4095);
  screen := mallocA(allocscreensize, $10000, oscreen); // JVAL: Memory padding may increase performance until 4%
  screen32 := screen;
  // malloc does not clear the memory: the overlay texture (GLDRAWTEXWIDTH x GLDRAWTEXHEIGHT) is uploaded
  // from the start of this buffer and its size is bigger than the part the engine draws on, so
  // the rest of the texture was whatever the heap had (it changed from a run to another)
  ZeroMemory(screen, allocscreensize - $10000);

  gl_frameender.CreateOverlayTexture;
  gl_frameender.ResetHudFilter;

  GL_NotifyDisplayMode;
end;

//==============================================================================
//
// GL_ChangeFullScreen
//
//==============================================================================
procedure GL_ChangeFullScreen(const full: boolean);
begin
  I_RestoreWindowPos;
  gl_context.ApplyFullScreen(full);
  I_RestoreWindowPos;
end;

//==============================================================================
//
// GL_SetDisplayMode
//
//==============================================================================
function GL_SetDisplayMode(const newwidth, newheight: integer; const force: boolean = false): boolean;
var
  nwidth, nheight: integer;
  limits: TGlDisplayModeLimits;
begin
  result := false;

  if not force then
    if (SCREENWIDTH = newwidth) and (SCREENHEIGHT = newheight) then
      exit;

  limits.MinWidth := MINWIDTH;
  limits.MaxWidth := MAXWIDTH;
  limits.MinHeight := MINHEIGHT;
  limits.MaxHeight := MAXHEIGHT;
  TGlDisplayModeClamp.Clamp(newwidth, newheight, limits, nwidth, nheight);

  if force or (SCREENWIDTH <> nwidth) or (SCREENHEIGHT <> nheight) then
  begin
    MT_WaitTasks;           // Wait for running tasks to stop
    AM_Stop;                // Stop the automap

    SCREENWIDTH := nwidth;
    SCREENHEIGHT := nheight;

    V_ReInit;
    gl_frameender.DeleteOverlayTexture;
    gl_frameender.CreateOverlayTexture;

    GL_ChangeFullScreen(fullscreen);

    TEngineGlContext.ResizeViewport;
    TEngineGlContext.InitState;
    glViewport(0, 0, SCREENWIDTH, SCREENHEIGHT);

    AM_Start;               // Start the automap
    GL_Console.AdjustScreenSize;
    R_ExecuteSetViewSize;   // Set-up new SCREENWIDTH & SCREENHEIGHT
    overlay.ReCalcOverlayLookUp;
    result := true;
  end;
end;

//==============================================================================
//
// GL_NotifyDisplayMode
//
//==============================================================================
procedure GL_NotifyDisplayMode;
begin
  GL_ChangeFullScreen(fullscreen);

  TEngineGlContext.ResizeViewport;
  TEngineGlContext.InitState;
  glViewport(0, 0, SCREENWIDTH, SCREENHEIGHT);
end;

//==============================================================================
//
// I_ReadScreen32
//
//==============================================================================
procedure I_ReadScreen32(dest: pointer);
begin
  glReadPixels(0, 0, SCREENWIDTH, SCREENHEIGHT, GL_BGRA, GL_UNSIGNED_BYTE, dest);
end;

//==============================================================================
//
// I_ReverseScreen
//
//==============================================================================
procedure I_ReverseScreen(const p: PLongWordArray);
var
  src, dest: PLongWordArray;
  buf: LongWord;
  i, j: integer;
begin
  for i := 0 to SCREENHEIGHT div 2 do
  begin
    src := @p[i * SCREENWIDTH];
    dest := @p[(SCREENHEIGHT - i - 1) * SCREENWIDTH];
    for j := 0 to SCREENWIDTH - 1 do
    begin
      buf := dest[j];
      dest[j] := src[j];
      src[j] := buf;
    end;
  end;
end;

//==============================================================================
//
// DoomMain
//
//==============================================================================
procedure DoomMain;
begin
  I_SetDPIAwareness;

  NATIVEWIDTH := I_ScreenWidth;
  NATIVEHEIGHT := I_ScreenHeight;

  TMainRoutines.D_DoomMain;
end;

initialization

finalization
  FreeAndNil(gl_frameender);
  FreeAndNil(gl_context);

end.
