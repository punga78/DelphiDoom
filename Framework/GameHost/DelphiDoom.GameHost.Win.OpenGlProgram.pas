{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the GLSL program of the display filter      }
{  Port of the second half of OpenGL::set_shader, of createShader and of the    }
{  uniforms of OpenGL::refresh of OpenXcom (Engine\OpenGL.cpp)                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.OpenGlProgram;

interface

uses
  System.SysUtils, dglOpenGL, DelphiDoom.Logging.Intf, DelphiDoom.GameHost.Types;

type
  /// <summary>
  ///   A GLSL program made of the fragment and vertex shaders of a shader file. Every method wants the OpenGL
  ///   context of the display current, the destructor too. As in the C++, a shader that does not compile is said
  ///   in the log with what the driver answers and left out, and only a program that does not link is a failure
  /// </summary>
  TGameHostWinOpenGlProgram = class
  strict private
    FLog: ILog;
    FProgram: GLuint;
    FIncomplete: Boolean;
    procedure Log(const AMessage: string);
    function CompileShader(AKind: GLenum; const AText: RawByteString): GLuint;
    procedure Attach(AKind: GLenum; const AText: RawByteString);
    procedure SetSize(const AName: AnsiString; AWidth, AHeight: Integer);
    procedure Release;
  public
    /// <param name="ALog">Where the answers of the compiler of the driver go; nil for nowhere</param>
    constructor Create(const ALog: ILog = nil);
    destructor Destroy; override;
    /// <summary>The context has every entry point the program needs (shader_support of the C++)</summary>
    class function IsSupported: Boolean; static;
    /// <summary>Compiles and links; false when there is no program to use (nothing is left behind)</summary>
    function Build(const ASource: TGameHostShaderSource): Boolean;
    /// <summary>
    ///   Makes the program the current one and gives it the sizes that the shaders of bsnes read: rubyInputSize,
    ///   rubyOutputSize and rubyTextureSize
    /// </summary>
    procedure Use(AInputWidth, AInputHeight, AOutputWidth, AOutputHeight, ATextureWidth, ATextureHeight: Integer);
    /// <summary>Back to the fixed pipeline</summary>
    procedure Unuse;
    /// <summary>The program was linked without a shader of the file, because it did not compile</summary>
    property Incomplete: Boolean read FIncomplete;
  end;

implementation

const
  SNoProgram = 'Failed to create GLSL shader program';
  SCompileNoLog = 'OpenGL shader compilation failed: No log returned from driver';
  SCompileFailed = 'OpenGL shader compilation failed: "%s"';
  SLinkNoLog = 'OpenGL shader link failed: No log returned from driver';
  SLinkFailed = 'OpenGL shader link failed "%s"';

constructor TGameHostWinOpenGlProgram.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

destructor TGameHostWinOpenGlProgram.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TGameHostWinOpenGlProgram.Log(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Error(AMessage);
end;

class function TGameHostWinOpenGlProgram.IsSupported: Boolean;
begin
  Result := Assigned(glCreateProgram) and Assigned(glDeleteProgram) and Assigned(glUseProgram) and
    Assigned(glCreateShader) and Assigned(glDeleteShader) and Assigned(glShaderSource) and
    Assigned(glCompileShader) and Assigned(glAttachShader) and Assigned(glLinkProgram) and
    Assigned(glGetUniformLocation) and Assigned(glUniform2fv) and Assigned(glGetShaderiv) and
    Assigned(glGetShaderInfoLog) and Assigned(glGetProgramiv) and Assigned(glGetProgramInfoLog);
end;

procedure TGameHostWinOpenGlProgram.Release;
begin
  if FProgram <> 0 then
    glDeleteProgram(FProgram);
  FProgram := 0;
end;

function TGameHostWinOpenGlProgram.CompileShader(AKind: GLenum; const AText: RawByteString): GLuint;
var
  LText: PAnsiChar;
  LStatus: GLint;
  LLength: GLint;
  LInfo: RawByteString;
begin
  // createShader
  Result := glCreateShader(AKind);
  LText := PAnsiChar(AText);
  glShaderSource(Result, 1, @LText, nil);
  glCompileShader(Result);
  LStatus := 0;
  glGetShaderiv(Result, GL_COMPILE_STATUS, @LStatus);
  if LStatus <> 0 then
    Exit;
  LLength := 0;
  glGetShaderiv(Result, GL_INFO_LOG_LENGTH, @LLength);
  if LLength <= 0 then
    Log(SCompileNoLog)
  else
  begin
    SetLength(LInfo, LLength);
    glGetShaderInfoLog(Result, LLength, nil, PAnsiChar(LInfo));
    Log(Format(SCompileFailed, [string(AnsiString(PAnsiChar(LInfo)))]));
  end;
  glDeleteShader(Result);
  Result := 0;
end;

procedure TGameHostWinOpenGlProgram.Attach(AKind: GLenum; const AText: RawByteString);
var
  LShader: GLuint;
begin
  if AText = '' then
    Exit;
  LShader := CompileShader(AKind, AText);
  if LShader = 0 then
  begin
    FIncomplete := True;
    Exit;
  end;
  glAttachShader(FProgram, LShader);
  // the program keeps it until it is deleted itself
  glDeleteShader(LShader);
end;

function TGameHostWinOpenGlProgram.Build(const ASource: TGameHostShaderSource): Boolean;
var
  LStatus: GLint;
  LLength: GLint;
  LInfo: RawByteString;
begin
  Release;
  FIncomplete := False;
  Result := False;
  if not IsSupported then
    Exit;
  FProgram := glCreateProgram;
  if FProgram = 0 then
  begin
    Log(SNoProgram);
    Exit;
  end;
  if ASource.IsGlsl then
  begin
    Attach(GL_FRAGMENT_SHADER, ASource.Fragment);
    Attach(GL_VERTEX_SHADER, ASource.Vertex);
  end;
  glLinkProgram(FProgram);
  LStatus := 0;
  glGetProgramiv(FProgram, GL_LINK_STATUS, @LStatus);
  if LStatus = 0 then
  begin
    LLength := 0;
    glGetProgramiv(FProgram, GL_INFO_LOG_LENGTH, @LLength);
    if LLength <= 0 then
      Log(SLinkNoLog)
    else
    begin
      SetLength(LInfo, LLength);
      glGetProgramInfoLog(FProgram, LLength, nil, PAnsiChar(LInfo));
      Log(Format(SLinkFailed, [string(AnsiString(PAnsiChar(LInfo)))]));
    end;
    Release;
  end;
  Result := FProgram <> 0;
end;

procedure TGameHostWinOpenGlProgram.SetSize(const AName: AnsiString; AWidth, AHeight: Integer);
var
  LSize: array[0..1] of GLfloat;
begin
  LSize[0] := AWidth;
  LSize[1] := AHeight;
  // a shader that does not read the size has no such uniform (-1): the call is then ignored by OpenGL
  glUniform2fv(glGetUniformLocation(FProgram, PAnsiChar(AName)), 1, @LSize[0]);
end;

procedure TGameHostWinOpenGlProgram.Use(AInputWidth, AInputHeight, AOutputWidth, AOutputHeight, ATextureWidth,
  ATextureHeight: Integer);
begin
  if FProgram = 0 then
    Exit;
  glUseProgram(FProgram);
  SetSize('rubyInputSize', AInputWidth, AInputHeight);
  SetSize('rubyOutputSize', AOutputWidth, AOutputHeight);
  SetSize('rubyTextureSize', ATextureWidth, ATextureHeight);
end;

procedure TGameHostWinOpenGlProgram.Unuse;
begin
  if FProgram <> 0 then
    glUseProgram(0);
end;

end.
