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
  public
    /// <summary>The lines written by the calls since the last Clear</summary>
    class var Lines: TStringList;
    /// <summary>The four values glGetIntegerv(GL_VIEWPORT) gives</summary>
    class var Viewport: array[0..3] of Integer;
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
    Move(TFakeGlLog.Viewport, params^, SizeOf(TFakeGlLog.Viewport));
end;

procedure FakeFinish; stdcall;
begin
  TFakeGlLog.Lines.Add('glFinish');
end;

procedure FakeFlush; stdcall;
begin
  TFakeGlLog.Lines.Add('glFlush');
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
  FInstalled := True;
  Clear;
end;

procedure TFakeGlLog.Restore;
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
