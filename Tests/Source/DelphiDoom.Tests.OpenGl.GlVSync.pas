{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlVSync - OpenGL call flow against the text of  }
{  gl_render.pas of before the class                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.GlVSync;

interface

uses
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Tests.OpenGl.FakeGlLog;

type
  /// <summary>
  ///   The vertical sync calls the functions of the swap interval extension: the fakes keep an interval and
  ///   log what is asked, the warnings go to a list; the sequences are compared with the old gld_VSync and
  ///   with the sync part of gld_Init and gld_StartDrawScene, copied here from the text of before the class
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlVSync = class(TObject)
  strict private
    FFakeGl: TFakeGlLog;
    FWarnings: TStringList;
    procedure RunOld(AInterval: Integer; AInitialSync: Boolean; const AToggles: string);
    procedure RunNew(AInterval: Integer; AInitialSync: Boolean; const AToggles: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareFalsoESegnalareUnaVoltaSolaSenzaEstensione;
    [Test]
    procedure DovrebbeCambiareLIntervalloSoloSeDiverso;
    [Test]
    procedure DovrebbeSeguireLaScelta;
    [Test]
    procedure DovrebbeRipetereLImpostazioneAlPrimoFotogramma;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioSuSequenzeCasuali;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioSenzaEstensione;
  end;

implementation

uses
  System.SysUtils,
  dglOpenGL,
  gl_defs,
  i_system,
  DelphiDoom.Engine.GlVSync;

var
  FakeInterval: GLint;

function FakeGetSwapInterval: GLint; stdcall;
begin
  TFakeGlLog.Lines.Add('wglGetSwapIntervalEXT');
  Result := FakeInterval;
end;

function FakeSwapInterval(interval: GLint): Boolean; stdcall;
begin
  TFakeGlLog.Lines.Add('wglSwapIntervalEXT ' + IntToStr(interval));
  FakeInterval := interval;
  Result := True;
end;

var
  SavedGetSwapInterval: TwglGetSwapIntervalEXT;
  SavedSwapInterval: TwglSwapIntervalEXT;
  SavedExtension: Boolean;
  OldWarned: Boolean;
  OldLastSync: Boolean;
  OldDidFirstSync: Boolean;

// The text of gld_VSync of before the class (the warning flag was a global of gl_render)
function OldVSync(ASync: Boolean): Boolean;
var
  i: Integer;
begin
  if WGL_EXT_swap_control then
  begin
    Result := True;
    i := wglGetSwapIntervalEXT;
    if ASync then
    begin
      if i <> 1 then
        wglSwapIntervalEXT(1);
    end
    else
    begin
      if i <> 0 then
        wglSwapIntervalEXT(0);
    end;
  end
  else
  begin
    Result := False;
    if not OldWarned then
    begin
      I_Warning('gld_VSync(): wglSwapIntervalEXT() not assigned'#13#10);
      OldWarned := True;
    end;
  end;
end;

// The sync part of gld_Init of before the class
procedure OldInitSync;
begin
  OldVSync(gl_screensync);
  OldLastSync := gl_screensync;
end;

// The sync part of gld_StartDrawScene of before the class
procedure OldStartDrawSync;
var
  syncret: Boolean;
begin
  if (OldLastSync <> gl_screensync) or not OldDidFirstSync then
  begin
    if gl_screensync then
    begin
      syncret := OldVSync(True);
      if not OldDidFirstSync then
      begin
        OldVSync(False);
        OldVSync(True);
      end;
    end
    else
    begin
      syncret := OldVSync(False);
      if not OldDidFirstSync then
      begin
        OldVSync(True);
        OldVSync(False);
      end;
    end;
    OldLastSync := gl_screensync;
    OldDidFirstSync := syncret;
  end;
end;

{ TTestOpenGlVSync }

procedure TTestOpenGlVSync.Setup;
begin
  FFakeGl := TFakeGlLog.Create;
  FFakeGl.Install;
  SavedGetSwapInterval := wglGetSwapIntervalEXT;
  SavedSwapInterval := wglSwapIntervalEXT;
  SavedExtension := WGL_EXT_swap_control;
  wglGetSwapIntervalEXT := FakeGetSwapInterval;
  wglSwapIntervalEXT := FakeSwapInterval;
  WGL_EXT_swap_control := True;
  FakeInterval := 0;
  gl_screensync := True;
  FWarnings := TStringList.Create;
  i_system.WarningLog := FWarnings;
end;

procedure TTestOpenGlVSync.TearDown;
begin
  i_system.WarningLog := nil;
  FreeAndNil(FWarnings);
  wglGetSwapIntervalEXT := SavedGetSwapInterval;
  wglSwapIntervalEXT := SavedSwapInterval;
  WGL_EXT_swap_control := SavedExtension;
  gl_screensync := True;
  FFakeGl.Restore;
  FreeAndNil(FFakeGl);
end;

// AToggles: one character per frame, '1' = the option changes before that frame
procedure TTestOpenGlVSync.RunOld(AInterval: Integer; AInitialSync: Boolean; const AToggles: string);
var
  LIndex: Integer;
begin
  FakeInterval := AInterval;
  gl_screensync := AInitialSync;
  OldWarned := False;
  OldDidFirstSync := False;
  TFakeGlLog.Clear;
  FWarnings.Clear;
  OldInitSync;
  for LIndex := 1 to Length(AToggles) do
  begin
    if AToggles[LIndex] = '1' then
      gl_screensync := not gl_screensync;
    OldStartDrawSync;
  end;
end;

procedure TTestOpenGlVSync.RunNew(AInterval: Integer; AInitialSync: Boolean; const AToggles: string);
var
  LVSync: TEngineGlVSync;
  LIndex: Integer;
begin
  FakeInterval := AInterval;
  gl_screensync := AInitialSync;
  TFakeGlLog.Clear;
  FWarnings.Clear;
  LVSync := TEngineGlVSync.Create;
  try
    LVSync.Start;
    for LIndex := 1 to Length(AToggles) do
    begin
      if AToggles[LIndex] = '1' then
        gl_screensync := not gl_screensync;
      LVSync.Update;
    end;
  finally
    LVSync.Free;
  end;
end;

procedure TTestOpenGlVSync.DovrebbeDareFalsoESegnalareUnaVoltaSolaSenzaEstensione;
var
  LVSync: TEngineGlVSync;
begin
  WGL_EXT_swap_control := False;
  LVSync := TEngineGlVSync.Create;
  try
    TFakeGlLog.Clear;
    Assert.IsFalse(LVSync.Apply(vsmSync));
    Assert.IsFalse(LVSync.Apply(vsmNoSync));
    Assert.AreEqual<Integer>(1, FWarnings.Count);
    Assert.AreEqual<Integer>(0, TFakeGlLog.Lines.Count);
  finally
    LVSync.Free;
  end;
end;

procedure TTestOpenGlVSync.DovrebbeCambiareLIntervalloSoloSeDiverso;
var
  LVSync: TEngineGlVSync;
begin
  LVSync := TEngineGlVSync.Create;
  try
    FakeInterval := 1;
    TFakeGlLog.Clear;
    Assert.IsTrue(LVSync.Apply(vsmSync));
    Assert.AreEqual<Integer>(1, TFakeGlLog.Lines.Count);
    Assert.AreEqual('wglGetSwapIntervalEXT', TFakeGlLog.Lines[0]);
    TFakeGlLog.Clear;
    LVSync.Apply(vsmNoSync);
    Assert.AreEqual<Integer>(1, TFakeGlLog.Lines.IndexOf('wglSwapIntervalEXT 0'));
    Assert.AreEqual<Integer>(0, FakeInterval);
  finally
    LVSync.Free;
  end;
end;

procedure TTestOpenGlVSync.DovrebbeSeguireLaScelta;
var
  LVSync: TEngineGlVSync;
begin
  LVSync := TEngineGlVSync.Create;
  try
    gl_screensync := False;
    FakeInterval := 1;
    LVSync.Start;
    Assert.AreEqual<Integer>(0, FakeInterval);
    LVSync.Update;
    gl_screensync := True;
    LVSync.Update;
    Assert.AreEqual<Integer>(1, FakeInterval);
  finally
    LVSync.Free;
  end;
end;

procedure TTestOpenGlVSync.DovrebbeRipetereLImpostazioneAlPrimoFotogramma;
var
  LVSync: TEngineGlVSync;
  LSwaps: Integer;
  LIndex: Integer;
begin
  LVSync := TEngineGlVSync.Create;
  try
    gl_screensync := True;
    FakeInterval := 0;
    LVSync.Start;
    TFakeGlLog.Clear;
    LVSync.Update;
    // first frame: sync, then no sync, then sync again; the interval changes at each step
    LSwaps := 0;
    for LIndex := 0 to TFakeGlLog.Lines.Count - 1 do
      if Pos('wglSwapIntervalEXT', TFakeGlLog.Lines[LIndex]) = 1 then
        Inc(LSwaps);
    Assert.AreEqual<Integer>(2, LSwaps);
    Assert.AreEqual<Integer>(1, FakeInterval);
    TFakeGlLog.Clear;
    LVSync.Update;
    Assert.AreEqual<Integer>(0, TFakeGlLog.Lines.Count);
  finally
    LVSync.Free;
  end;
end;

procedure TTestOpenGlVSync.DovrebbeDareLeStesseChiamateDelVecchioSuSequenzeCasuali;
var
  LCase: Integer;
  LToggles: string;
  LStep: Integer;
  LInterval: Integer;
  LSync: Boolean;
  LOldLines: string;
  LOldWarnings: string;
begin
  RandSeed := 248;
  for LCase := 1 to 300 do
  begin
    LInterval := Random(2);
    LSync := Random(2) = 1;
    LToggles := '';
    for LStep := 1 to 1 + Random(14) do
      LToggles := LToggles + Chr(Ord('0') + Ord(Random(3) = 0));
    RunOld(LInterval, LSync, LToggles);
    LOldLines := TFakeGlLog.Lines.Text;
    LOldWarnings := FWarnings.Text;
    RunNew(LInterval, LSync, LToggles);
    Assert.AreEqual(LOldLines, TFakeGlLog.Lines.Text, 'calls, case ' + IntToStr(LCase));
    Assert.AreEqual(LOldWarnings, FWarnings.Text, 'warnings, case ' + IntToStr(LCase));
  end;
end;

procedure TTestOpenGlVSync.DovrebbeDareLeStesseChiamateDelVecchioSenzaEstensione;
var
  LOldLines: string;
  LOldWarnings: string;
begin
  WGL_EXT_swap_control := False;
  RunOld(0, True, '0101100');
  LOldLines := TFakeGlLog.Lines.Text;
  LOldWarnings := FWarnings.Text;
  RunNew(0, True, '0101100');
  Assert.AreEqual(LOldLines, TFakeGlLog.Lines.Text);
  Assert.AreEqual(LOldWarnings, FWarnings.Text);
  Assert.AreEqual<Integer>(1, FWarnings.Count, 'one warning for the whole run');
end;

end.
