//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the window and the OpenGL rendering context of the OpenGL games
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.GlContext;

interface

uses
  Winapi.Windows;

type
  /// <summary>
  ///   The game window and its OpenGL rendering context: the window class, the full screen mode, the device
  ///   context, the pixel format, the rendering context and their release (it was the windowing part of
  ///   GL_InitGraphics, glKillWnd, GL_ChangeFullScreen, glResizeWnd and glInit of gl_main.pas, and the
  ///   SwapBuffers of gld_Finish)
  /// </summary>
  /// <remarks>
  ///   A plain class, no interface and no virtual method: it is created once by gl_main and the only call that
  ///   runs every frame (SwapBuffers) is a direct one. It reads the historical globals of the window (the
  ///   handle of the main window, the size of the screen, the full screen flag) like the code it replaces
  /// </remarks>
  TEngineGlContext = class(TObject)
  strict private
    FDeviceContext: HDC;
    FRenderContext: HGLRC;
    FInitialized: Boolean;
  public
    /// <summary>
    ///   Loads OpenGL, registers the window class, goes full screen if asked, creates the window, the device
    ///   context, the pixel format and the rendering context, makes it current and reads the extensions; the
    ///   window is then shown and takes the focus. A failure undoes what was done and stops the game with I_Error
    /// </summary>
    procedure Open(const AWindowProc: TFNWndProc);
    /// <summary>Back to the desktop mode, releases the rendering context and the device context</summary>
    procedure Close;
    /// <summary>Enters (or leaves) the full screen display mode; the window is moved by the caller</summary>
    procedure ApplyFullScreen(const AFull: Boolean);
    /// <summary>The viewport and the perspective of the whole screen (it was glResizeWnd)</summary>
    class procedure ResizeViewport; static;
    /// <summary>The state OpenGL starts every video mode with (it was glInit)</summary>
    class procedure InitState; static;
    /// <summary>Shows the frame that was drawn</summary>
    procedure SwapBuffers;
    /// <summary>True once OpenGL was loaded; the resources of the renderer exist from then on</summary>
    property Initialized: Boolean read FInitialized;
  end;

implementation

uses
  d_delphi,
  d_main,
  dglOpenGL,
  doomdef,
  i_mainwindow,
  i_system,
  v_video,
  DelphiDoom.GlContext.FullScreenMode,
  DelphiDoom.GlContext.PixelFormat;

{ TEngineGlContext }

procedure TEngineGlContext.Open(const AWindowProc: TFNWndProc);
var
  WindowClass: TWndClass;
  dwStyle: DWORD;              // Window styles
  dwExStyle: DWORD;            // Extended window styles
  dmScreenSettings: DEVMODE;   // Screen settings (fullscreen, etc...)
  PixelFormat: GLuint;         // Settings for the OpenGL rendering
  h_Instance: HINST;           // Current instance
  pfd: TPIXELFORMATDESCRIPTOR;  // Settings for the OpenGL window
  caption: string;
begin
  InitOpenGL;                               // New call to initialize and bind the OpenGL dll
  FInitialized := True;

  h_Instance := GetModuleHandle(nil);       //Grab An Instance For Our Window
  ZeroMemory(@WindowClass, SizeOf(TWndClass));  // Clear the window class structure

  with WindowClass do                    // Set up the window class
  begin
    style         := CS_HREDRAW or    // Redraws entire window if length changes
                     CS_VREDRAW or    // Redraws entire window if height changes
                     CS_OWNDC;        // Unique device context for the window
    lpfnWndProc   := AWindowProc;     // Set the window procedure to our func WndProc
    hbrBackground := GetStockObject(BLACK_BRUSH); // Black background
    hInstance     := h_Instance;
    hCursor       := LoadCursor(0, IDC_ARROW);
    lpszClassName := 'Doom32';
  end;

  if RegisterClass(WindowClass) = 0 then  // Attemp to register the window class
  begin
    I_Error('GL_InitGraphics(): Failed to register the window class!');
    Exit;
  end;

  // Change to fullscreen if so desired
  if fullscreen then
  begin
    TGlFullScreenMode.Describe(SCREENWIDTH, SCREENHEIGHT, dmScreenSettings);

    // Try to change screen mode to fullscreen
    if ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN) = DISP_CHANGE_FAILED then
    begin
      I_Error('GL_InitGraphics(): Unable to switch to fullscreen!');
      fullscreen := False;
    end;
  end;

  dwStyle := 0;
  dwExStyle := WINDOW_STYLE_FS;

  ShowCursor(False);  // Turn of the cursor (gets in the way)

  caption := D_Version + ' - ' + D_VersionBuilt;

  // Attempt to create the actual window
  hMainWnd := CreateWindowEx(
    dwExStyle,      // Extended window styles
    WindowClass.lpszClassName,
    PChar(caption),
    dwStyle,        // Window styles
    0, 0,           // Window position
    SCREENWIDTH,
    SCREENHEIGHT,
    0,              // No parent window
    0,              // No menu
    h_Instance,     // Instance
    nil             // Pass nothing to WM_CREATE
  );

  if hMainWnd = 0 then
  begin
    Close;                    // Undo all the settings we've changed
    I_Error('GL_InitGraphics(): Unable to create window!');
    Exit;
  end;

  // Try to get a device context
  FDeviceContext := GetDC(hMainWnd);
  if FDeviceContext = 0 then
  begin
    Close;
    I_Error('GL_InitGraphics(): Unable to get a device context!');
    Exit;
  end;

  // Settings for the OpenGL window
  TGlPixelFormat.Describe(pfd);

  // Attempts to find the pixel format supported by a device context that is the best match to a given pixel format specification.
  PixelFormat := ChoosePixelFormat(FDeviceContext, @pfd);
  if PixelFormat = 0 then
  begin
    Close;
    I_Error('GL_InitGraphics(): Unable to find a suitable pixel format');
    Exit;
  end;

  // Sets the specified device context's pixel format to the format specified by the PixelFormat.
  if not SetPixelFormat(FDeviceContext, PixelFormat, @pfd) then
  begin
    Close;
    I_Error('GL_InitGraphics(): Unable to set the pixel format');
    Exit;
  end;

  // Create a OpenGL rendering context
  FRenderContext := wglCreateContext(FDeviceContext);
  if FRenderContext = 0 then
  begin
    Close;
    I_Error('GL_InitGraphics(): Unable to create an OpenGL rendering context');
    Exit;
  end;

  // Makes the specified OpenGL rendering context the calling thread's current rendering context
  if not wglMakeCurrent(FDeviceContext, FRenderContext) then
  begin
    Close;
    I_Error('GL_InitGraphics(): Unable to activate OpenGL rendering context');
    Exit;
  end;
  // Read And Assign Extentions
  ReadExtensions;
  ReadImplementationProperties;

  // Settings to ensure that the window is the topmost window
  ShowWindow(hMainWnd, SW_SHOW);
  SetForegroundWindow(hMainWnd);
  SetFocus(hMainWnd);
end;

procedure TEngineGlContext.Close;
begin
  if fullscreen then             // Change back to non fullscreen
    ChangeDisplaySettings(devmode(nil^), 0);

  if FInitialized then
  begin
    // Makes current rendering context not current, and releases the device
    // context that is used by the rendering context.
    if not wglMakeCurrent(FDeviceContext, 0) then
      I_Warning('glKillWnd(): Release of DC and RC failed!'#13#10);

    // Attempts to delete the rendering context
    if not wglDeleteContext(FRenderContext) then
    begin
      I_Warning('glKillWnd(): Release of rendering context failed!'#13#10);
      FRenderContext := 0;
    end;
  end;

  // Attemps to release the device context
  if (FDeviceContext > 0) and (ReleaseDC(hMainWnd, FDeviceContext) = 0) then
  begin
    I_Warning('glKillWnd(): Release of device context failed!'#13#10);
    FDeviceContext := 0;
  end;
end;

procedure TEngineGlContext.ApplyFullScreen(const AFull: Boolean);
var
  dmScreenSettings: DEVMODE;   // Screen settings (fullscreen, etc...)
begin
  fullscreen := AFull;
  // Change to fullscreen if so desired
  if fullscreen then
  begin
    TGlFullScreenMode.Describe(SCREENWIDTH, SCREENHEIGHT, dmScreenSettings);

    // Try to change screen mode to fullscreen
    if ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN) = DISP_CHANGE_FAILED then
      I_Warning('GL_ChangeFullScreen(): Can not change to fullscreen mode'#13#10);
  end
  else
    ChangeDisplaySettings(devmode(nil^), 0);
end;

class procedure TEngineGlContext.ResizeViewport;
begin
  glViewport(0, 0, SCREENWIDTH, SCREENHEIGHT);    // Set the viewport for the OpenGL window
  glMatrixMode(GL_PROJECTION);        // Change Matrix Mode to Projection
  glLoadIdentity;                     // Reset View
  gluPerspective(45.0, SCREENWIDTH / SCREENHEIGHT, 1.0, 100.0);  // Do the perspective calculations. Last value = max clipping depth

  glMatrixMode(GL_MODELVIEW);         // Return to the modelview matrix
  glLoadIdentity;                     // Reset View
end;

class procedure TEngineGlContext.InitState;
begin
  glClearColor(0.0, 0.0, 0.0, 0.0);        // Black Background
  glShadeModel(GL_SMOOTH);                 // Enables Smooth Color Shading
  glClearDepth(1.0);                       // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST);                 // Enable Depth Buffer
  glDepthFunc(GL_LESS);                    // The Type Of Depth Test To Do
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);   //Realy Nice perspective calculations
  glEnable(GL_TEXTURE_2D);                     // Enable Texture Mapping
end;

procedure TEngineGlContext.SwapBuffers;
begin
  Winapi.Windows.SwapBuffers(FDeviceContext);
end;

end.
