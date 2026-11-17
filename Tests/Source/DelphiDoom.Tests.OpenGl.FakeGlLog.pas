{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL scene - fake OpenGL functions that log      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.FakeGlLog;

interface

uses
  System.Classes;

type
  /// <summary>
  ///   Puts in the function variables of dglOpenGL the few calls that the light painter makes, each one
  ///   writing a line in a list (floats as the hexadecimal bits, so a difference of one bit is seen), and
  ///   gives the real variables back: no context, no window, no driver
  /// </summary>
  TFakeGlLog = class(TObject)
  strict private
    FSavedPushMatrix: Pointer;
    FSavedPopMatrix: Pointer;
    FSavedTranslatef: Pointer;
    FSavedRotatef: Pointer;
    FSavedBegin: Pointer;
    FSavedEnd: Pointer;
    FSavedColor4f: Pointer;
    FSavedVertex3f: Pointer;
    FSavedMatrixMode: Pointer;
    FSavedDepthMask: Pointer;
    FSavedEnable: Pointer;
    FSavedDisable: Pointer;
    FSavedBlendFunc: Pointer;
    FSavedLoadIdentity: Pointer;
    FSavedOrtho: Pointer;
    FSavedGetIntegerv: Pointer;
    FSavedFinish: Pointer;
    FSavedFlush: Pointer;
    FInstalled: Boolean;
    FHookTargets: array of PPointer;
    FHookSaved: array of Pointer;
    /// <summary>Puts a fake in a function variable, remembering the real one for Restore</summary>
    procedure Hook(const ATarget: PPointer; const AFake: Pointer);
  public
    /// <summary>The lines written by the calls since the last Clear</summary>
    class var Lines: TStringList;
    /// <summary>The four values glGetIntegerv(GL_VIEWPORT) gives</summary>
    class var Viewport: array[0..3] of Integer;
    /// <summary>What glGetIntegerv(GL_MAX_TEXTURE_SIZE) and (GL_MAX_3D_TEXTURE_SIZE) give</summary>
    class var MaxTextureSize: Integer;
    class var MaxTexture3DSize: Integer;
    /// <summary>What glGetString(GL_VENDOR), (GL_RENDERER), (GL_VERSION) and (GL_EXTENSIONS) give</summary>
    class var Vendor: AnsiString;
    class var Renderer: AnsiString;
    class var Version: AnsiString;
    class var Extensions: AnsiString;
    /// <summary>What wglGetProcAddress gives for every name (nil: the extension function is missing)</summary>
    class var ExtensionProc: Pointer;
    /// <summary>Installs the fakes; the calls go to Lines</summary>
    procedure Install;
    /// <summary>Gives the real variables back</summary>
    procedure Restore;
    /// <summary>Empties Lines</summary>
    class procedure Clear; static;
  end;

implementation

uses
  System.SysUtils,
  dglOpenGL;

type
  TFloatQuad = array[0..3] of Single;
  PFloatQuad = ^TFloatQuad;

function Bits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

function BitsD(const AValue: Double): string;
begin
  Result := IntToHex(PInt64(@AValue)^, 16);
end;

procedure FakePushMatrix; stdcall;
begin
  TFakeGlLog.Lines.Add('glPushMatrix');
end;

procedure FakePopMatrix; stdcall;
begin
  TFakeGlLog.Lines.Add('glPopMatrix');
end;

procedure FakeTranslatef(x, y, z: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glTranslatef ' + Bits(x) + ' ' + Bits(y) + ' ' + Bits(z));
end;

procedure FakeRotatef(angle, x, y, z: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glRotatef ' + Bits(angle) + ' ' + Bits(x) + ' ' + Bits(y) + ' ' + Bits(z));
end;

procedure FakeBegin(mode: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glBegin ' + IntToHex(mode, 4));
end;

procedure FakeEnd; stdcall;
begin
  TFakeGlLog.Lines.Add('glEnd');
end;

procedure FakeColor4f(red, green, blue, alpha: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glColor4f ' + Bits(red) + ' ' + Bits(green) + ' ' + Bits(blue) + ' ' + Bits(alpha));
end;

procedure FakeVertex3f(x, y, z: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glVertex3f ' + Bits(x) + ' ' + Bits(y) + ' ' + Bits(z));
end;

procedure FakeMatrixMode(mode: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glMatrixMode ' + IntToHex(mode, 4));
end;

procedure FakeDepthMask(flag: GLboolean); stdcall;
begin
  TFakeGlLog.Lines.Add('glDepthMask ' + IntToStr(Ord(flag <> False)));
end;

procedure FakeEnable(cap: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glEnable ' + IntToHex(cap, 4));
end;

procedure FakeDisable(cap: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glDisable ' + IntToHex(cap, 4));
end;

procedure FakeBlendFunc(sfactor, dfactor: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glBlendFunc ' + IntToHex(sfactor, 4) + ' ' + IntToHex(dfactor, 4));
end;

procedure FakeLoadIdentity; stdcall;
begin
  TFakeGlLog.Lines.Add('glLoadIdentity');
end;

procedure FakeOrtho(left, right, bottom, top, zNear, zFar: GLdouble); stdcall;
begin
  TFakeGlLog.Lines.Add('glOrtho ' + BitsD(left) + ' ' + BitsD(right) + ' ' + BitsD(bottom) + ' ' +
    BitsD(top) + ' ' + BitsD(zNear) + ' ' + BitsD(zFar));
end;

procedure FakeGetIntegerv(pname: GLenum; params: PGLint); stdcall;
begin
  TFakeGlLog.Lines.Add('glGetIntegerv ' + IntToHex(pname, 4));
  if pname = GL_VIEWPORT then
    Move(TFakeGlLog.Viewport, params^, SizeOf(TFakeGlLog.Viewport))
  else if pname = GL_MAX_TEXTURE_SIZE then
    params^ := TFakeGlLog.MaxTextureSize
  else if pname = GL_MAX_3D_TEXTURE_SIZE then
    params^ := TFakeGlLog.MaxTexture3DSize;
end;

function FakeGetString(name: GLenum): PAnsiChar; stdcall;
begin
  TFakeGlLog.Lines.Add('glGetString ' + IntToHex(name, 4));
  case name of
    GL_VENDOR: Result := PAnsiChar(TFakeGlLog.Vendor);
    GL_RENDERER: Result := PAnsiChar(TFakeGlLog.Renderer);
    GL_VERSION: Result := PAnsiChar(TFakeGlLog.Version);
    GL_EXTENSIONS: Result := PAnsiChar(TFakeGlLog.Extensions);
  else
    Result := nil;
  end;
end;

function FakeGetProcAddress(ProcName: PAnsiChar): Pointer; stdcall;
begin
  TFakeGlLog.Lines.Add('wglGetProcAddress ' + string(AnsiString(ProcName)));
  Result := TFakeGlLog.ExtensionProc;
end;

procedure FakeViewport(x, y: GLint; width, height: GLsizei); stdcall;
begin
  TFakeGlLog.Lines.Add('glViewport ' + IntToStr(x) + ' ' + IntToStr(y) + ' ' + IntToStr(width) + ' ' + IntToStr(height));
end;

procedure FakeScissor(x, y: GLint; width, height: GLsizei); stdcall;
begin
  TFakeGlLog.Lines.Add('glScissor ' + IntToStr(x) + ' ' + IntToStr(y) + ' ' + IntToStr(width) + ' ' + IntToStr(height));
end;

procedure FakeClear(mask: GLbitfield); stdcall;
begin
  TFakeGlLog.Lines.Add('glClear ' + IntToHex(mask, 8));
end;

procedure FakeClearColor(red, green, blue, alpha: GLclampf); stdcall;
begin
  TFakeGlLog.Lines.Add('glClearColor ' + Bits(red) + ' ' + Bits(green) + ' ' + Bits(blue) + ' ' + Bits(alpha));
end;

procedure FakeClearDepth(depth: GLclampd); stdcall;
begin
  TFakeGlLog.Lines.Add('glClearDepth ' + BitsD(depth));
end;

procedure FakeHint(target, mode: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glHint ' + IntToHex(target, 4) + ' ' + IntToHex(mode, 4));
end;

procedure FakePixelStorei(pname: GLenum; param: GLint); stdcall;
begin
  TFakeGlLog.Lines.Add('glPixelStorei ' + IntToHex(pname, 4) + ' ' + IntToStr(param));
end;

procedure FakeDepthFunc(func: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glDepthFunc ' + IntToHex(func, 4));
end;

procedure FakeAlphaFunc(func: GLenum; ref: GLclampf); stdcall;
begin
  TFakeGlLog.Lines.Add('glAlphaFunc ' + IntToHex(func, 4) + ' ' + Bits(ref));
end;

procedure FakeTexEnvf(target, pname: GLenum; param: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glTexEnvf ' + IntToHex(target, 4) + ' ' + IntToHex(pname, 4) + ' ' + Bits(param));
end;

procedure FakeTexGenf(coord, pname: GLenum; param: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glTexGenf ' + IntToHex(coord, 4) + ' ' + IntToHex(pname, 4) + ' ' + Bits(param));
end;

procedure FakeTexGenfv(coord, pname: GLenum; const params: PGLfloat); stdcall;
var
  LValues: PFloatQuad;
begin
  // GL_EYE_PLANE (the only vector the scene sets) has four floats
  LValues := PFloatQuad(params);
  TFakeGlLog.Lines.Add('glTexGenfv ' + IntToHex(coord, 4) + ' ' + IntToHex(pname, 4) + ' ' + Bits(LValues[0]) +
    ' ' + Bits(LValues[1]) + ' ' + Bits(LValues[2]) + ' ' + Bits(LValues[3]));
end;

procedure FakeFogi(pname: GLenum; param: GLint); stdcall;
begin
  TFakeGlLog.Lines.Add('glFogi ' + IntToHex(pname, 4) + ' ' + IntToStr(param));
end;

procedure FakeShadeModel(mode: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glShadeModel ' + IntToHex(mode, 4));
end;

procedure FakeMultMatrixd(const m: PGLdouble); stdcall;
var
  LIndex: Integer;
  LLine: string;
begin
  LLine := 'glMultMatrixd';
  for LIndex := 0 to 15 do
    LLine := LLine + ' ' + BitsD(PDouble(PByte(m) + LIndex * SizeOf(Double))^);
  TFakeGlLog.Lines.Add(LLine);
end;

procedure FakePolygonMode(face, mode: GLenum); stdcall;
begin
  TFakeGlLog.Lines.Add('glPolygonMode ' + IntToHex(face, 4) + ' ' + IntToHex(mode, 4));
end;

procedure FakeBindTexture(target: GLenum; texture: GLuint); stdcall;
begin
  TFakeGlLog.Lines.Add('glBindTexture ' + IntToHex(target, 4) + ' ' + IntToStr(texture));
end;

procedure FakeVertex2f(x, y: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glVertex2f ' + Bits(x) + ' ' + Bits(y));
end;

procedure FakeColor3f(red, green, blue: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glColor3f ' + Bits(red) + ' ' + Bits(green) + ' ' + Bits(blue));
end;

procedure FakeFinish; stdcall;
begin
  TFakeGlLog.Lines.Add('glFinish');
end;

procedure FakeFlush; stdcall;
begin
  TFakeGlLog.Lines.Add('glFlush');
end;

procedure FakeFogf(pname: GLenum; param: GLfloat); stdcall;
begin
  TFakeGlLog.Lines.Add('glFogf ' + IntToHex(pname, 4) + ' ' + Bits(param));
end;

procedure FakeFogfv(pname: GLenum; params: PGLfloat); stdcall;
var
  LValues: PFloatQuad;
begin
  // GL_FOG_COLOR (the only vector the scene sets) has four floats
  LValues := PFloatQuad(params);
  TFakeGlLog.Lines.Add('glFogfv ' + IntToHex(pname, 4) + ' ' + Bits(LValues[0]) + ' ' + Bits(LValues[1]) + ' ' +
    Bits(LValues[2]) + ' ' + Bits(LValues[3]));
end;

{ TFakeGlLog }

procedure TFakeGlLog.Install;
begin
  if FInstalled then
    Exit;
  if not Assigned(Lines) then
    Lines := TStringList.Create;
  FSavedPushMatrix := @glPushMatrix;
  FSavedPopMatrix := @glPopMatrix;
  FSavedTranslatef := @glTranslatef;
  FSavedRotatef := @glRotatef;
  FSavedBegin := @glBegin;
  FSavedEnd := @glEnd;
  FSavedColor4f := @glColor4f;
  FSavedVertex3f := @glVertex3f;
  FSavedMatrixMode := @glMatrixMode;
  FSavedDepthMask := @glDepthMask;
  FSavedEnable := @glEnable;
  FSavedDisable := @glDisable;
  FSavedBlendFunc := @glBlendFunc;
  FSavedLoadIdentity := @glLoadIdentity;
  FSavedOrtho := @glOrtho;
  FSavedGetIntegerv := @glGetIntegerv;
  FSavedFinish := @glFinish;
  FSavedFlush := @glFlush;
  glPushMatrix := @FakePushMatrix;
  glPopMatrix := @FakePopMatrix;
  glTranslatef := @FakeTranslatef;
  glRotatef := @FakeRotatef;
  glBegin := @FakeBegin;
  glEnd := @FakeEnd;
  glColor4f := @FakeColor4f;
  glVertex3f := @FakeVertex3f;
  glMatrixMode := @FakeMatrixMode;
  glDepthMask := @FakeDepthMask;
  glEnable := @FakeEnable;
  glDisable := @FakeDisable;
  glBlendFunc := @FakeBlendFunc;
  glLoadIdentity := @FakeLoadIdentity;
  glOrtho := @FakeOrtho;
  glGetIntegerv := @FakeGetIntegerv;
  glFinish := @FakeFinish;
  glFlush := @FakeFlush;
  Hook(@@glFogf, @FakeFogf);
  Hook(@@glFogfv, @FakeFogfv);
  Hook(@@glGetString, @FakeGetString);
  Hook(@@wglGetProcAddress, @FakeGetProcAddress);
  Hook(@@glViewport, @FakeViewport);
  Hook(@@glScissor, @FakeScissor);
  Hook(@@glClear, @FakeClear);
  Hook(@@glClearColor, @FakeClearColor);
  Hook(@@glClearDepth, @FakeClearDepth);
  Hook(@@glHint, @FakeHint);
  Hook(@@glPixelStorei, @FakePixelStorei);
  Hook(@@glDepthFunc, @FakeDepthFunc);
  Hook(@@glAlphaFunc, @FakeAlphaFunc);
  Hook(@@glTexEnvf, @FakeTexEnvf);
  Hook(@@glTexGenf, @FakeTexGenf);
  Hook(@@glTexGenfv, @FakeTexGenfv);
  Hook(@@glFogi, @FakeFogi);
  Hook(@@glShadeModel, @FakeShadeModel);
  Hook(@@glMultMatrixd, @FakeMultMatrixd);
  Hook(@@glPolygonMode, @FakePolygonMode);
  Hook(@@glBindTexture, @FakeBindTexture);
  Hook(@@glVertex2f, @FakeVertex2f);
  Hook(@@glColor3f, @FakeColor3f);
  FInstalled := True;
  Clear;
end;

procedure TFakeGlLog.Hook(const ATarget: PPointer; const AFake: Pointer);
var
  LCount: Integer;
begin
  LCount := Length(FHookTargets);
  SetLength(FHookTargets, LCount + 1);
  SetLength(FHookSaved, LCount + 1);
  FHookTargets[LCount] := ATarget;
  FHookSaved[LCount] := ATarget^;
  ATarget^ := AFake;
end;

procedure TFakeGlLog.Restore;
var
  LIndex: Integer;
begin
  if not FInstalled then
    Exit;
  glPushMatrix := FSavedPushMatrix;
  glPopMatrix := FSavedPopMatrix;
  glTranslatef := FSavedTranslatef;
  glRotatef := FSavedRotatef;
  glBegin := FSavedBegin;
  glEnd := FSavedEnd;
  glColor4f := FSavedColor4f;
  glVertex3f := FSavedVertex3f;
  glMatrixMode := FSavedMatrixMode;
  glDepthMask := FSavedDepthMask;
  glEnable := FSavedEnable;
  glDisable := FSavedDisable;
  glBlendFunc := FSavedBlendFunc;
  glLoadIdentity := FSavedLoadIdentity;
  glOrtho := FSavedOrtho;
  glGetIntegerv := FSavedGetIntegerv;
  glFinish := FSavedFinish;
  glFlush := FSavedFlush;
  for LIndex := High(FHookTargets) downto 0 do
    FHookTargets[LIndex]^ := FHookSaved[LIndex];
  FHookTargets := nil;
  FHookSaved := nil;
  FInstalled := False;
end;

class procedure TFakeGlLog.Clear;
begin
  if Assigned(Lines) then
    Lines.Clear;
end;

initialization

finalization
  FreeAndNil(TFakeGlLog.Lines);

end.
