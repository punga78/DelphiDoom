{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - the generated thunks        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.Thunks;

// The thunks replace the real variables of dglOpenGL. Here the variables hold fake functions of the
// test (no driver, no context): the thunks have to pass the arguments to them and to write the call.

interface

uses
  System.Classes, System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.Intf,
  DelphiDoom.OpenGl.Recorder.Installer;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlThunks = class(TObject)
  strict private
    FStream: TMemoryStream;
    FRecorder: IGlCallRecorder;
    FInstaller: TGlHookInstaller;
    FSaved: array[0..3] of Pointer;
    function Written: string;
    procedure Hook;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereUnaThunkPerOgniFunzioneUsataDalRenderer;
    [Test]
    procedure DovrebbeAvereNomiDiversi;
    [Test]
    procedure DovrebbeAvereTuttiGliIndirizzi;
    [Test]
    procedure DovrebbeChiamareLOriginaleConGliStessiArgomenti;
    [Test]
    procedure DovrebbeScrivereLaChiamataPrimaDiEseguirla;
    [Test]
    procedure DovrebbeDareIlRisultatoDellOriginale;
    [Test]
    procedure DovrebbeScrivereGliEnumEGliInteri;
    [Test]
    procedure DovrebbeFareLImpronteDeiPixelDiTexImage2D;
    [Test]
    procedure DovrebbeRimettereLeFunzioniDopoUninstall;
    [Test]
    procedure DovrebbeNonSostituireLeFunzioniChePiuNonCe;
  end;

implementation

uses
  dglOpenGL, DelphiDoom.OpenGl.Recorder.CallRecorder, DelphiDoom.OpenGl.Recorder.Fnv,
  DelphiDoom.OpenGl.Recorder.Session, DelphiDoom.OpenGl.Recorder.Thunks;

var
  GVertexCalls: Integer;
  GVertexX: GLfloat;
  GVertexY: GLfloat;
  GVertexZ: GLfloat;
  GEnableCap: GLenum;
  GTexImagePixels: Pointer;
  GTexImageCalls: Integer;
  GFrameOpenAtVertex: Boolean;
  GRecorderAtVertex: IGlCallRecorder;

procedure FakeVertex3f(x: GLfloat; y: GLfloat; z: GLfloat); stdcall;
begin
  Inc(GVertexCalls);
  GVertexX := x;
  GVertexY := y;
  GVertexZ := z;
end;

procedure FakeEnable(cap: GLenum); stdcall;
begin
  GEnableCap := cap;
  // the thunk writes the call before it calls the original: the line is already there
  GFrameOpenAtVertex := Assigned(GRecorderAtVertex) and GRecorderAtVertex.InFrame;
end;

function FakeGetString(name: GLenum): PAnsiChar; stdcall;
begin
  if name = GL_VENDOR then
    Result := 'fake vendor'
  else
    Result := nil;
end;

procedure FakeTexImage2D(target: GLenum; level: GLint; internalformat: GLint; width: GLsizei; height: GLsizei;
  border: GLint; format: GLenum; _type: GLenum; const pixels: PGLvoid); stdcall;
begin
  Inc(GTexImageCalls);
  GTexImagePixels := pixels;
end;

{ TTestOpenGlThunks }

procedure TTestOpenGlThunks.Setup;
begin
  FStream := TMemoryStream.Create;
  FRecorder := TGlCallRecorder.Create(FStream);
  GVertexCalls := 0;
  GTexImageCalls := 0;
  GTexImagePixels := nil;
  GRecorderAtVertex := FRecorder;
  FSaved[0] := @glVertex3f;
  FSaved[1] := @glEnable;
  FSaved[2] := @glGetString;
  FSaved[3] := @glTexImage2D;
  glVertex3f := FakeVertex3f;
  glEnable := FakeEnable;
  glGetString := FakeGetString;
  glTexImage2D := FakeTexImage2D;
end;

procedure TTestOpenGlThunks.TearDown;
begin
  if Assigned(FInstaller) then
  begin
    FInstaller.Uninstall;
    FreeAndNil(FInstaller);
  end;
  GlSessionStop;
  glVertex3f := TglVertex3f(FSaved[0]);
  glEnable := TglEnable(FSaved[1]);
  glGetString := TglGetString(FSaved[2]);
  glTexImage2D := TglTexImage2D(FSaved[3]);
  GRecorderAtVertex := nil;
  FRecorder := nil;
  FStream.Free;
end;

function TTestOpenGlThunks.Written: string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, FStream.Size);
  if FStream.Size > 0 then
    Move(FStream.Memory^, LBytes[0], FStream.Size);
  Result := TEncoding.ASCII.GetString(LBytes);
end;

procedure TTestOpenGlThunks.Hook;
begin
  GlSessionStart(FRecorder);
  FInstaller := TGlHookInstaller.Create(CreateGlHookTable);
  FInstaller.Install;
end;

procedure TTestOpenGlThunks.DovrebbeAvereUnaThunkPerOgniFunzioneUsataDalRenderer;
var
  LTable: IGlHookTable;
begin
  LTable := CreateGlHookTable;
  // il generatore (Genera-Thunks.ps1) ne ha trovate 81 quando e stato scritto questo test
  Assert.IsTrue(LTable.Count >= 80, 'funzioni: ' + IntToStr(LTable.Count));
end;

procedure TTestOpenGlThunks.DovrebbeAvereNomiDiversi;
var
  LTable: IGlHookTable;
  LIndex: Integer;
  LNames: TStringList;
begin
  LTable := CreateGlHookTable;
  LNames := TStringList.Create;
  try
    LNames.Sorted := True;
    LNames.Duplicates := dupError;
    for LIndex := 0 to LTable.Count - 1 do
      LNames.Add(LTable.Name(LIndex));
    Assert.AreEqual(LTable.Count, LNames.Count);
  finally
    LNames.Free;
  end;
end;

procedure TTestOpenGlThunks.DovrebbeAvereTuttiGliIndirizzi;
var
  LTable: IGlHookTable;
  LIndex: Integer;
begin
  LTable := CreateGlHookTable;
  for LIndex := 0 to LTable.Count - 1 do
  begin
    Assert.IsTrue(LTable.Slot(LIndex) <> nil, LTable.Name(LIndex));
    Assert.IsTrue(LTable.Thunk(LIndex) <> nil, LTable.Name(LIndex));
    Assert.IsTrue(Copy(LTable.Name(LIndex), 1, 2) = 'gl', LTable.Name(LIndex));
  end;
end;

procedure TTestOpenGlThunks.DovrebbeChiamareLOriginaleConGliStessiArgomenti;
begin
  Hook;
  glVertex3f(1.5, -2.25, 3.0);
  Assert.AreEqual(1, GVertexCalls);
  Assert.IsTrue(GVertexX = 1.5);
  Assert.IsTrue(GVertexY = -2.25);
  Assert.IsTrue(GVertexZ = 3.0);
end;

procedure TTestOpenGlThunks.DovrebbeScrivereLaChiamataPrimaDiEseguirla;
begin
  Hook;
  FRecorder.BeginFrame;
  glEnable(GL_TEXTURE_2D);
  FRecorder.EndFrame('t');
  Assert.IsTrue(GEnableCap = GL_TEXTURE_2D);
  Assert.IsTrue(GFrameOpenAtVertex);
  Assert.IsTrue(Written.StartsWith('glEnable($0DE1)'#10'FRAME t calls=1'));
end;

procedure TTestOpenGlThunks.DovrebbeDareIlRisultatoDellOriginale;
var
  LVendor: PAnsiChar;
begin
  Hook;
  LVendor := glGetString(GL_VENDOR);
  Assert.AreEqual('fake vendor', string(AnsiString(LVendor)));
  Assert.IsTrue(glGetString(GL_RENDERER) = nil);
end;

procedure TTestOpenGlThunks.DovrebbeScrivereGliEnumEGliInteri;
begin
  Hook;
  FRecorder.BeginFrame;
  glVertex3f(1.0, 0.0, 2.0);
  FRecorder.EndFrame('t');
  Assert.IsTrue(Written.StartsWith('glVertex3f(#3F800000,#00000000,#40000000)'#10));
end;

procedure TTestOpenGlThunks.DovrebbeFareLImpronteDeiPixelDiTexImage2D;
var
  LPixels: array[0..15] of Byte;
  LIndex: Integer;
  LHash: string;
begin
  for LIndex := 0 to 15 do
    LPixels[LIndex] := LIndex * 3;
  LHash := 'h:' + TGlFnv.ToHex(TGlFnv.UpdateBuffer(TGlFnv.Start, @LPixels[0], 16)) + '/16';
  Hook;
  FRecorder.BeginFrame;
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 2, 2, 0, GL_RGBA, GL_UNSIGNED_BYTE, @LPixels[0]);
  FRecorder.EndFrame('t');
  Assert.AreEqual(1, GTexImageCalls);
  Assert.IsTrue(GTexImagePixels = @LPixels[0]);
  Assert.IsTrue(Written.StartsWith('glTexImage2D($0DE1,0,6408,2,2,0,$1908,$1401,' + LHash + ')'#10));
end;

procedure TTestOpenGlThunks.DovrebbeRimettereLeFunzioniDopoUninstall;
begin
  Hook;
  FInstaller.Uninstall;
  glVertex3f(0, 0, 0);
  Assert.AreEqual(1, GVertexCalls);
  Assert.IsTrue(@glVertex3f = @FakeVertex3f);
end;

procedure TTestOpenGlThunks.DovrebbeNonSostituireLeFunzioniChePiuNonCe;
var
  LSavedBegin: Pointer;
begin
  // glBegin non e stata assegnata dal test: e nil e la thunk non deve prenderne il posto
  LSavedBegin := @glBegin;
  glBegin := nil;
  try
    Hook;
    Assert.IsFalse(Assigned(glBegin));
    Assert.IsTrue(Length(FInstaller.Missing) >= 1);
  finally
    glBegin := TglBegin(LSavedBegin);
  end;
end;

end.
