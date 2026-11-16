{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the picture in the window with OpenGL       }
{  Port of the OpenGL class of OpenXcom (Engine\OpenGL.cpp, itself copied from  }
{  the ruby library of bsnes, public domain) on WGL: OpenGL only presents the   }
{  finished picture, the game stays at 8 bits with a palette                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.OpenGlVideoDevice;

interface

uses
  Winapi.Windows, System.Types, System.SysUtils, System.Math, dglOpenGL, DelphiDoom.Logging.Intf,
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Win.Window,
  DelphiDoom.GameHost.Win.WindowDevice, DelphiDoom.GameHost.Win.OpenGlProgram, DelphiDoom.GameHost.TrueColor.Intf;

type
  /// <summary>
  ///   The display of a game on OpenGL (Options::useOpenGL of OpenXcom). SetMode makes a WGL context in the window
  ///   and raises EGameHostVideoDeviceException, with the reason, when it cannot. The picture is turned into colors
  ///   with its palette, loaded in a texture and drawn in the rectangle the GDI display uses (the picture rectangle
  ///   of a full screen window, the black bands of the screen), with the nearest pixel or the linear filter and the
  ///   vertical sync of the filter, through the GLSL program of the shader of the filter when there is one (a
  ///   shader says by itself whether it wants the linear filter). When the device goes away the window handle goes
  ///   with it: a window that had an OpenGL pixel format cannot be drawn by GDI again. The floating point
  ///   exceptions are masked while OpenGL is called and only then. A picture of colors
  ///   (IGameHostTrueColorDisplay) is loaded in the same texture as it is and fills the rectangle
  /// </summary>
  TGameHostWinOpenGlVideoDevice = class(TGameHostWinWindowDevice, IGameHostFilteredDisplay,
    IGameHostTrueColorDisplay)
  strict private
    FLog: ILog;
    FShaders: IGameHostShaderLoader;
    FProgram: TGameHostWinOpenGlProgram;
    FContextWindow: HWND;
    FDeviceContext: HDC;
    FContext: HGLRC;
    FTexture: GLuint;
    FTextureWidth: Integer;
    FTextureHeight: Integer;
    FBuffer: TArray<Cardinal>;
    FLinear: Boolean;
    FWanted: TGameHostDisplayFilter;
    FActive: TGameHostDisplayFilter;
    class constructor Create;
    class function LastErrorText: string; static;
    procedure LogInfo(const AMessage: string);
    procedure LogError(const AMessage: string);
    procedure CreateContext;
    procedure DestroyContext;
    procedure InitializeState;
    procedure ApplyFilter;
    function LoadShader(const APath: string): Boolean;
    procedure ResizeTexture(AWidth, AHeight: Integer);
    procedure Draw(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette;
      ADisplayWidth, ADisplayHeight: Integer; const ABands: TGameHostBlackBands);
    procedure DrawColors(AColors: Pointer; AWidth, AHeight, ADisplayWidth, ADisplayHeight: Integer;
      const ABands: TGameHostBlackBands);
  public
    /// <param name="AWindow">The window of the game; not owned</param>
    /// <param name="AShaders">Gives the shader that the filter names; nil: no shader is ever used</param>
    /// <param name="ALog">Where the version of OpenGL and the problems go; nil for nowhere</param>
    constructor Create(AWindow: TGameHostWinWindow; const AShaders: IGameHostShaderLoader = nil;
      const ALog: ILog = nil);
    destructor Destroy; override;
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean); override;
    /// <summary>The picture already scaled by the screen: it fills the rectangle, no bands</summary>
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette); override;
    procedure SetDisplayFilter(const AFilter: TGameHostDisplayFilter);
    function DisplayFilter: TGameHostDisplayFilter;
    function PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette;
      ADisplayWidth, ADisplayHeight: Integer; const ABands: TGameHostBlackBands): Boolean;
    function PresentTrueColor(const APixels: TGameHostTrueColorPixels; AWidth, AHeight: Integer): Boolean;
  end;

implementation

const
  SNoShaderSupport = 'This OpenGL has no GLSL programs: the shader is not used';
  SShaderInUse = 'OpenGL shader in use: %s';
  SShaderIncomplete = 'OpenGL shader in use without the part that did not compile: %s';
  SNoLibrary = 'opengl32.dll could not be loaded';
  SNoDeviceContext = 'GetDC failed: %s';
  SNoPixelFormat = 'ChoosePixelFormat found no OpenGL pixel format: %s';
  SSetPixelFormat = 'SetPixelFormat failed: %s';
  SNoContext = 'wglCreateContext failed: %s';
  SMakeCurrent = 'wglMakeCurrent failed: %s';
  SContextInfo = 'OpenGL %s, renderer "%s", vendor "%s"';
  // the masks the run time library starts with; see the class constructor
  DEFAULT_EXCEPTION_MASK = [exDenormalized, exUnderflow, exPrecision];

class constructor TGameHostWinOpenGlVideoDevice.Create;
begin
  // The initialization of dglOpenGL masks every floating point exception for the whole program, only because the
  // unit is linked. The game must compute as it does without OpenGL (the display in memory, the GDI one): the
  // masks of the run time library come back here, and this class masks the exceptions around its own calls
  SetExceptionMask(DEFAULT_EXCEPTION_MASK);
{$IFDEF CPUX86}
  // setting the control word again also makes it the one the threads started later take (the loader of the data)
  Set8087CW(Get8087CW);
{$ENDIF}
end;

class function TGameHostWinOpenGlVideoDevice.LastErrorText: string;
var
  LCode: Cardinal;
begin
  LCode := GetLastError;
  Result := Format('%s (%d)', [SysErrorMessage(LCode), LCode]);
end;

constructor TGameHostWinOpenGlVideoDevice.Create(AWindow: TGameHostWinWindow;
  const AShaders: IGameHostShaderLoader; const ALog: ILog);
begin
  inherited Create(AWindow);
  FShaders := AShaders;
  FLog := ALog;
end;

destructor TGameHostWinOpenGlVideoDevice.Destroy;
var
  LMask: TArithmeticExceptionMask;
begin
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    DestroyContext;
  finally
    SetExceptionMask(LMask);
  end;
  inherited Destroy;
end;

procedure TGameHostWinOpenGlVideoDevice.LogInfo(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Info(AMessage);
end;

procedure TGameHostWinOpenGlVideoDevice.LogError(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Error(AMessage);
end;

procedure TGameHostWinOpenGlVideoDevice.CreateContext;
var
  LFormat: TPixelFormatDescriptor;
  LFormatIndex: Integer;
begin
  if (GL_LibHandle = nil) and not InitOpenGL then
    raise EGameHostVideoDeviceException.Create(SNoLibrary);
  FContextWindow := Window.Handle;
  FDeviceContext := GetDC(FContextWindow);
  if FDeviceContext = 0 then
    raise EGameHostVideoDeviceException.CreateFmt(SNoDeviceContext, [LastErrorText]);
  FillChar(LFormat, SizeOf(LFormat), 0);
  LFormat.nSize := SizeOf(LFormat);
  LFormat.nVersion := 1;
  LFormat.dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  LFormat.iPixelType := PFD_TYPE_RGBA;
  LFormat.cColorBits := 32;
  LFormat.iLayerType := PFD_MAIN_PLANE;
  LFormatIndex := ChoosePixelFormat(FDeviceContext, @LFormat);
  if LFormatIndex = 0 then
    raise EGameHostVideoDeviceException.CreateFmt(SNoPixelFormat, [LastErrorText]);
  if not SetPixelFormat(FDeviceContext, LFormatIndex, @LFormat) then
    raise EGameHostVideoDeviceException.CreateFmt(SSetPixelFormat, [LastErrorText]);
  FContext := dglOpenGL.wglCreateContext(FDeviceContext);
  if FContext = 0 then
    raise EGameHostVideoDeviceException.CreateFmt(SNoContext, [LastErrorText]);
  if not dglOpenGL.wglMakeCurrent(FDeviceContext, FContext) then
    raise EGameHostVideoDeviceException.CreateFmt(SMakeCurrent, [LastErrorText]);
  // the entry points of the version and of the extensions of this context
  ReadExtensions;
  LogInfo(Format(SContextInfo, [string(AnsiString(glGetString(GL_VERSION))),
    string(AnsiString(glGetString(GL_RENDERER))), string(AnsiString(glGetString(GL_VENDOR)))]));
  InitializeState;
end;

procedure TGameHostWinOpenGlVideoDevice.DestroyContext;
begin
  if FContext <> 0 then
  begin
    // the program is deleted in its context
    FreeAndNil(FProgram);
    if FTexture <> 0 then
      glDeleteTextures(1, @FTexture);
    dglOpenGL.wglMakeCurrent(0, 0);
    dglOpenGL.wglDeleteContext(FContext);
  end;
  FTexture := 0;
  FTextureWidth := 0;
  FTextureHeight := 0;
  FContext := 0;
  if FContextWindow <> 0 then
  begin
    if FDeviceContext <> 0 then
      ReleaseDC(FContextWindow, FDeviceContext);
    // the pixel format of a window is set once: the next display starts from a new handle
    if Window.Handle = FContextWindow then
      Window.DestroyHandle;
  end;
  FDeviceContext := 0;
  FContextWindow := 0;
  FActive := Default(TGameHostDisplayFilter);
end;

procedure TGameHostWinOpenGlVideoDevice.InitializeState;
begin
  // OpenGL::init
  glDisable(GL_ALPHA_TEST);
  glDisable(GL_BLEND);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_POLYGON_SMOOTH);
  glDisable(GL_STENCIL_TEST);
  glEnable(GL_DITHER);
  glEnable(GL_TEXTURE_2D);
end;

procedure TGameHostWinOpenGlVideoDevice.ApplyFilter;
begin
  // Screen::resetDisplay after OpenGL::init
  FActive := FWanted;
  FActive.UseOpenGL := True;
  // the smoothing of the options; a shader file that is used says it instead
  FLinear := FWanted.Smoothing;
  FreeAndNil(FProgram);
  if (FWanted.Shader <> '') and not LoadShader(FWanted.Shader) then
    FActive.Shader := '';
  // OpenGL::setVSync
  if Assigned(wglSwapIntervalEXT) then
    wglSwapIntervalEXT(Ord(FWanted.VSync));
end;

function TGameHostWinOpenGlVideoDevice.LoadShader(const APath: string): Boolean;
var
  LSource: TGameHostShaderSource;
begin
  // OpenGL::set_shader: false when there is no program to draw with (the screen then forgets the shader)
  Result := False;
  if not Assigned(FShaders) then
    Exit;
  if not TGameHostWinOpenGlProgram.IsSupported then
  begin
    LogError(SNoShaderSupport);
    Exit;
  end;
  // a loader that has no such shader, or cannot read it, has said so itself
  if not FShaders.TryLoad(APath, LSource) then
    Exit;
  FProgram := TGameHostWinOpenGlProgram.Create(FLog);
  if not FProgram.Build(LSource) then
  begin
    FreeAndNil(FProgram);
    Exit;
  end;
  FLinear := LSource.Linear;
  if FProgram.Incomplete then
    LogError(Format(SShaderIncomplete, [APath]))
  else
    LogInfo(Format(SShaderInUse, [APath]));
  Result := True;
end;

procedure TGameHostWinOpenGlVideoDevice.ResizeTexture(AWidth, AHeight: Integer);
begin
  // OpenGL::resize
  if FTexture = 0 then
    glGenTextures(1, @FTexture);
  FTextureWidth := AWidth;
  FTextureHeight := AHeight;
  SetLength(FBuffer, AWidth * AHeight);
  glBindTexture(GL_TEXTURE_2D, FTexture);
  glPixelStorei(GL_UNPACK_ROW_LENGTH, AWidth);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, AWidth, AHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, @FBuffer[0]);
end;

procedure TGameHostWinOpenGlVideoDevice.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
var
  LMask: TArithmeticExceptionMask;
begin
  inherited SetMode(AWidth, AHeight, AFullscreen);
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    if FContext = 0 then
      try
        CreateContext;
      except
        // the window may already have the pixel format: it goes away with what was made of the context
        DestroyContext;
        raise;
      end;
    ApplyFilter;
  finally
    SetExceptionMask(LMask);
  end;
end;

procedure TGameHostWinOpenGlVideoDevice.SetDisplayFilter(const AFilter: TGameHostDisplayFilter);
begin
  FWanted := AFilter;
end;

function TGameHostWinOpenGlVideoDevice.DisplayFilter: TGameHostDisplayFilter;
begin
  Result := FActive;
end;

procedure TGameHostWinOpenGlVideoDevice.Draw(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette; ADisplayWidth, ADisplayHeight: Integer; const ABands: TGameHostBlackBands);
var
  LColors: array[0..255] of Cardinal;
  LIndex: Integer;
begin
  // the palette as the pixels of the texture: blue, green, red and alpha from the low byte
  for LIndex := 0 to 255 do
    LColors[LIndex] := $FF000000 or (Cardinal(APalette[LIndex].Red) shl 16) or
      (Cardinal(APalette[LIndex].Green) shl 8) or Cardinal(APalette[LIndex].Blue);
  if (FTexture = 0) or (FTextureWidth <> AWidth) or (FTextureHeight <> AHeight) then
    ResizeTexture(AWidth, AHeight);
  for LIndex := 0 to AWidth * AHeight - 1 do
    FBuffer[LIndex] := LColors[APixels[LIndex]];
  DrawColors(@FBuffer[0], AWidth, AHeight, ADisplayWidth, ADisplayHeight, ABands);
end;

procedure TGameHostWinOpenGlVideoDevice.DrawColors(AColors: Pointer; AWidth, AHeight, ADisplayWidth,
  ADisplayHeight: Integer; const ABands: TGameHostBlackBands);
var
  LOutput: TRect;
  LClient: TRect;
  LFilter: GLint;
begin
  if (FTexture = 0) or (FTextureWidth <> AWidth) or (FTextureHeight <> AHeight) then
    ResizeTexture(AWidth, AHeight);
  LOutput := Window.OutputRect;
  if not GetClientRect(FContextWindow, LClient) then
    LClient := LOutput;
  // OpenGL::refresh; the errors left by somebody else are thrown away first
  while glGetError <> GL_NO_ERROR do
    ;
  glViewport(0, 0, LClient.Right, LClient.Bottom);
  glClearColor(0.0, 0.0, 0.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  // the output size the shader computes with is the one in real pixels (a full screen picture is stretched)
  if Assigned(FProgram) then
    FProgram.Use(AWidth, AHeight, LOutput.Width, LOutput.Height, FTextureWidth, FTextureHeight);
  if FLinear then
    LFilter := GL_LINEAR
  else
    LFilter := GL_NEAREST;
  glBindTexture(GL_TEXTURE_2D, FTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, LFilter);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, LFilter);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  // the units are the pixels of the display the screen asked for; the viewport stretches them to the rectangle of
  // the picture (the same one of the GDI display), whose origin is at the bottom in OpenGL
  glOrtho(0, ADisplayWidth, 0, ADisplayHeight, -1.0, 1.0);
  glViewport(LOutput.Left, LClient.Bottom - LOutput.Bottom, LOutput.Width, LOutput.Height);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glPixelStorei(GL_UNPACK_ROW_LENGTH, AWidth);
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, AWidth, AHeight, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, AColors);
  // the vertices turn the picture over: its first row is the top one
  if ABands.Left + ABands.Right + ABands.Top + ABands.Bottom = 0 then
  begin
    // one triangle twice as large as the display: no diagonal seam across the picture
    glBegin(GL_TRIANGLES);
    glTexCoord2f(0, 0);
    glVertex3i(0, ADisplayHeight, 0);
    glTexCoord2f(2, 0);
    glVertex3i(ADisplayWidth * 2, ADisplayHeight, 0);
    glTexCoord2f(0, 2);
    glVertex3i(0, -ADisplayHeight, 0);
    glEnd;
  end
  else
  begin
    glBegin(GL_TRIANGLE_STRIP);
    glTexCoord2f(0, 0);
    glVertex3i(ABands.Left, ADisplayHeight - ABands.Top, 0);
    glTexCoord2f(1, 0);
    glVertex3i(ADisplayWidth - ABands.Right, ADisplayHeight - ABands.Top, 0);
    glTexCoord2f(0, 1);
    glVertex3i(ABands.Left, ABands.Bottom, 0);
    glTexCoord2f(1, 1);
    glVertex3i(ADisplayWidth - ABands.Right, ABands.Bottom, 0);
    glEnd;
  end;
  if Assigned(FProgram) then
    FProgram.Unuse;
  SwapBuffers(FDeviceContext);
end;

function TGameHostWinOpenGlVideoDevice.PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette; ADisplayWidth, ADisplayHeight: Integer; const ABands: TGameHostBlackBands): Boolean;
var
  LMask: TArithmeticExceptionMask;
begin
  Result := (FContext <> 0) and (AWidth > 0) and (AHeight > 0) and (Length(APixels) >= AWidth * AHeight);
  if not Result then
    Exit;
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    Draw(APixels, AWidth, AHeight, APalette, ADisplayWidth, ADisplayHeight, ABands);
  finally
    SetExceptionMask(LMask);
  end;
end;

function TGameHostWinOpenGlVideoDevice.PresentTrueColor(const APixels: TGameHostTrueColorPixels; AWidth,
  AHeight: Integer): Boolean;
var
  LMask: TArithmeticExceptionMask;
begin
  Result := (FContext <> 0) and (AWidth > 0) and (AHeight > 0) and (Length(APixels) >= AWidth * AHeight);
  if not Result then
    Exit;
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    // the picture is already what the display shows: it fills the rectangle, no bands
    DrawColors(@APixels[0], AWidth, AHeight, AWidth, AHeight, Default(TGameHostBlackBands));
  finally
    SetExceptionMask(LMask);
  end;
end;

procedure TGameHostWinOpenGlVideoDevice.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette);
begin
  PresentUnscaled(APixels, AWidth, AHeight, APalette, AWidth, AHeight, Default(TGameHostBlackBands));
end;

end.
