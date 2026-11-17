{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGl2dMode - OpenGL call flow against the text    }
{  of gl_render.pas of before the class                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.Gl2dMode;

interface

uses
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Tests.OpenGl.FakeGlLog;

type
  /// <summary>
  ///   The 2D mode only calls OpenGL (fake functions that log, no context) and reads the size of the screen
  ///   and the option of the hack: the calls are compared with the old gld_Enable2D, gld_Disable2D,
  ///   gld_Set2DMode and gld_Finish, copied here from the text of before the class
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlGl2dMode = class(TObject)
  strict private
    FFakeGl: TFakeGlLog;
    function LinesCopy: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerEnable;
    [Test]
    procedure DovrebbeUsareLeMisureDellaViewportPerLaProiezione;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerDisable;
    [Test]
    procedure DovrebbeRimettereLeTreMatriciNellOrdineDiEnable;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerSetModeSuTutteLeMisure;
    [Test]
    procedure DovrebbeSpegnereLaProfonditaInSetMode;
    [Test]
    procedure DovrebbeFareIlFinishSoloSeLOpzioneLoChiede;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerFinish;
    [Test]
    procedure DovrebbeScambiareIBufferComeUltimaChiamata;
  end;

implementation

uses
  System.SysUtils,
  dglOpenGL,
  doomdef,
  gl_defs,
  gl_main,
  DelphiDoom.Engine.Gl2dMode;

// The text of before the classes (gl_render.pas, commit before ondata2-177-1), only the names of the
// locals and of the swap changed: SwapBuffers(h_DC) becomes the same hook the class uses.

procedure OldEnable2D;
var
  vPort: array[0..3] of GLInt;
begin
  glGetIntegerv(GL_VIEWPORT, @vPort);

  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;

  glOrtho(0, vPort[2], 0, vPort[3], -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;

  glMatrixMode(GL_TEXTURE);
  glPushMatrix;
  glLoadIdentity;
end;

procedure OldDisable2D;
begin
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;
  glMatrixMode(GL_TEXTURE);
  glPopMatrix;
end;

procedure OldSet2DMode;
begin
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(
    0,
    SCREENWIDTH,
    SCREENHEIGHT,
    0,
    -1.0,
    1.0
  );
  glDisable(GL_DEPTH_TEST);
end;

procedure OldFinish;
begin
  OldSet2DMode;
  if not gl_no_glfinish_hack then
    glFinish;
  glFlush;
  GL_SwapBuffers;
end;

procedure LogSwap;
begin
  TFakeGlLog.Lines.Add('SwapBuffers');
end;

{ TTestOpenGlGl2dMode }

procedure TTestOpenGlGl2dMode.Setup;
begin
  FFakeGl := TFakeGlLog.Create;
  FFakeGl.Install;
  TFakeGlLog.Viewport[0] := 0;
  TFakeGlLog.Viewport[1] := 0;
  TFakeGlLog.Viewport[2] := 800;
  TFakeGlLog.Viewport[3] := 600;
  SCREENWIDTH := 640;
  SCREENHEIGHT := 400;
  gl_no_glfinish_hack := True;
  SwapBuffersHook := LogSwap;
end;

procedure TTestOpenGlGl2dMode.TearDown;
begin
  SwapBuffersHook := nil;
  gl_no_glfinish_hack := True;
  FFakeGl.Restore;
  FreeAndNil(FFakeGl);
end;

function TTestOpenGlGl2dMode.LinesCopy: TStringList;
begin
  Result := TStringList.Create;
  Result.AddStrings(TFakeGlLog.Lines);
end;

procedure TTestOpenGlGl2dMode.DovrebbeDareLeStesseChiamateDelVecchioPerEnable;
var
  LOld: TStringList;
begin
  TFakeGlLog.Clear;
  OldEnable2D;
  LOld := LinesCopy;
  try
    TFakeGlLog.Clear;
    TEngineGl2dMode.Enable;
    Assert.AreEqual(LOld.Text, TFakeGlLog.Lines.Text);
    Assert.AreEqual<Integer>(11, LOld.Count);
  finally
    LOld.Free;
  end;
end;

procedure TTestOpenGlGl2dMode.DovrebbeUsareLeMisureDellaViewportPerLaProiezione;
begin
  TFakeGlLog.Viewport[2] := 1024;
  TFakeGlLog.Viewport[3] := 768;
  TFakeGlLog.Clear;
  TEngineGl2dMode.Enable;
  Assert.AreEqual('glGetIntegerv 0BA2', TFakeGlLog.Lines[0]);
  Assert.IsTrue(Pos('glOrtho 0000000000000000 4090000000000000 0000000000000000 4088000000000000',
    TFakeGlLog.Lines.Text) > 0, 'ortho 0..1024 x 0..768');
end;

procedure TTestOpenGlGl2dMode.DovrebbeDareLeStesseChiamateDelVecchioPerDisable;
var
  LOld: TStringList;
begin
  TFakeGlLog.Clear;
  OldDisable2D;
  LOld := LinesCopy;
  try
    TFakeGlLog.Clear;
    TEngineGl2dMode.Disable;
    Assert.AreEqual(LOld.Text, TFakeGlLog.Lines.Text);
  finally
    LOld.Free;
  end;
end;

procedure TTestOpenGlGl2dMode.DovrebbeRimettereLeTreMatriciNellOrdineDiEnable;
var
  LPushes, LPops: TStringList;
  LIndex: Integer;
begin
  LPushes := TStringList.Create;
  LPops := TStringList.Create;
  try
    TFakeGlLog.Clear;
    TEngineGl2dMode.Enable;
    for LIndex := 0 to TFakeGlLog.Lines.Count - 2 do
      if TFakeGlLog.Lines[LIndex + 1] = 'glPushMatrix' then
        LPushes.Add(TFakeGlLog.Lines[LIndex]);
    TFakeGlLog.Clear;
    TEngineGl2dMode.Disable;
    for LIndex := 0 to TFakeGlLog.Lines.Count - 2 do
      if TFakeGlLog.Lines[LIndex + 1] = 'glPopMatrix' then
        LPops.Add(TFakeGlLog.Lines[LIndex]);
    Assert.AreEqual(LPushes.Text, LPops.Text);
    Assert.AreEqual<Integer>(3, LPushes.Count);
  finally
    LPops.Free;
    LPushes.Free;
  end;
end;

procedure TTestOpenGlGl2dMode.DovrebbeDareLeStesseChiamateDelVecchioPerSetModeSuTutteLeMisure;
const
  WIDTHS: array[0..4] of Integer = (320, 640, 800, 1280, 1920);
  HEIGHTS: array[0..4] of Integer = (200, 400, 600, 1024, 1080);
var
  LWidth, LHeight: Integer;
  LOld: TStringList;
begin
  for LWidth := 0 to High(WIDTHS) do
    for LHeight := 0 to High(HEIGHTS) do
    begin
      SCREENWIDTH := WIDTHS[LWidth];
      SCREENHEIGHT := HEIGHTS[LHeight];
      TFakeGlLog.Clear;
      OldSet2DMode;
      LOld := LinesCopy;
      try
        TFakeGlLog.Clear;
        TEngineGl2dMode.SetMode;
        Assert.AreEqual(LOld.Text, TFakeGlLog.Lines.Text);
      finally
        LOld.Free;
      end;
    end;
end;

procedure TTestOpenGlGl2dMode.DovrebbeSpegnereLaProfonditaInSetMode;
begin
  TFakeGlLog.Clear;
  TEngineGl2dMode.SetMode;
  Assert.AreEqual('glDisable 0B71', TFakeGlLog.Lines[TFakeGlLog.Lines.Count - 1]);
end;

procedure TTestOpenGlGl2dMode.DovrebbeFareIlFinishSoloSeLOpzioneLoChiede;
begin
  gl_no_glfinish_hack := True;
  TFakeGlLog.Clear;
  TEngineGl2dMode.Finish;
  Assert.AreEqual<Integer>(-1, TFakeGlLog.Lines.IndexOf('glFinish'));
  Assert.IsTrue(TFakeGlLog.Lines.IndexOf('glFlush') >= 0);
  gl_no_glfinish_hack := False;
  TFakeGlLog.Clear;
  TEngineGl2dMode.Finish;
  Assert.IsTrue(TFakeGlLog.Lines.IndexOf('glFinish') >= 0);
  Assert.IsTrue(TFakeGlLog.Lines.IndexOf('glFinish') < TFakeGlLog.Lines.IndexOf('glFlush'));
end;

procedure TTestOpenGlGl2dMode.DovrebbeDareLeStesseChiamateDelVecchioPerFinish;
var
  LHack: Integer;
  LOld: TStringList;
begin
  for LHack := 0 to 1 do
  begin
    gl_no_glfinish_hack := LHack = 1;
    TFakeGlLog.Clear;
    OldFinish;
    LOld := LinesCopy;
    try
      TFakeGlLog.Clear;
      TEngineGl2dMode.Finish;
      Assert.AreEqual(LOld.Text, TFakeGlLog.Lines.Text);
    finally
      LOld.Free;
    end;
  end;
end;

procedure TTestOpenGlGl2dMode.DovrebbeScambiareIBufferComeUltimaChiamata;
begin
  TFakeGlLog.Clear;
  TEngineGl2dMode.Finish;
  Assert.AreEqual('SwapBuffers', TFakeGlLog.Lines[TFakeGlLog.Lines.Count - 1]);
end;

end.