{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - values, session and switch  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.Session;

interface

uses
  System.Classes, System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.Intf;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSession = class(TObject)
  strict private
    FStream: TMemoryStream;
    FRecorder: IGlCallRecorder;
    function Written: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereLeChiamateNelRegistratore;
    [Test]
    procedure DovrebbeNonScrivereDopoStop;
    [Test]
    procedure DovrebbeNonFallireSenzaSessione;
    [Test]
    procedure DovrebbeSostituireLaSessioneAlloStart;
    [Test]
    procedure DovrebbeSeguireLoStatoAncheFuoriDaUnFotogramma;
    [Test]
    procedure DovrebbeDareZeroFunzioniSostituiteSenzaGlrecord;
    [Test]
    procedure DovrebbeDareUnElencoVuotoDelleMancantiSenzaGlrecord;
    [Test]
    procedure DovrebbeSaperePerQualeBuildEStatoCompilato;
  end;

  [TestFixture]
  [Category('opengl')]
  TTestOpenGlValue = class(TObject)
  public
    [Test]
    procedure DovrebbeTenereIFloatConIloroBit;
    [Test]
    procedure DovrebbeTenereIDoubleConIloroBit;
    [Test]
    procedure DovrebbeDareUnConteggioDaUnIntero;
    [Test]
    procedure DovrebbeDareZeroPerUnConteggioNegativo;
    [Test]
    procedure DovrebbeDareZeroPerUnConteggioTroppoGrande;
    [Test]
    procedure DovrebbeDareZeroComeInteroPerUnFloat;
  end;

implementation

uses
  DelphiDoom.OpenGl.Recorder.CallRecorder, DelphiDoom.OpenGl.Recorder.Hook, DelphiDoom.OpenGl.Recorder.Session,
  DelphiDoom.OpenGl.Recorder.Types;

{ TTestOpenGlSession }

procedure TTestOpenGlSession.Setup;
begin
  FStream := TMemoryStream.Create;
  FRecorder := TGlCallRecorder.Create(FStream);
end;

procedure TTestOpenGlSession.TearDown;
begin
  GlSessionStop;
  FRecorder := nil;
  FStream.Free;
end;

function TTestOpenGlSession.Written: string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, FStream.Size);
  if FStream.Size > 0 then
    Move(FStream.Memory^, LBytes[0], FStream.Size);
  Result := TEncoding.ASCII.GetString(LBytes);
end;

procedure TTestOpenGlSession.DovrebbeScrivereLeChiamateNelRegistratore;
begin
  GlSessionStart(FRecorder);
  FRecorder.BeginFrame;
  GlSessionRecord('glVertex2i', [TGlValue.FromInteger(3), TGlValue.FromInteger(-4)]);
  FRecorder.EndFrame('t');
  Assert.IsTrue(Written.StartsWith('glVertex2i(3,-4)'#10'FRAME t calls=1'));
end;

procedure TTestOpenGlSession.DovrebbeNonScrivereDopoStop;
begin
  GlSessionStart(FRecorder);
  GlSessionStop;
  FRecorder.BeginFrame;
  GlSessionRecord('glEnd', []);
  FRecorder.EndFrame('t');
  Assert.IsTrue(Written.StartsWith('FRAME t calls=0'));
end;

procedure TTestOpenGlSession.DovrebbeNonFallireSenzaSessione;
begin
  GlSessionStop;
  Assert.WillNotRaiseAny(
    procedure
    begin
      GlSessionRecord('glEnd', []);
    end);
end;

procedure TTestOpenGlSession.DovrebbeSostituireLaSessioneAlloStart;
var
  LOtherStream: TMemoryStream;
  LOther: IGlCallRecorder;
begin
  LOtherStream := TMemoryStream.Create;
  try
    LOther := TGlCallRecorder.Create(LOtherStream);
    GlSessionStart(FRecorder);
    GlSessionStart(LOther);
    LOther.BeginFrame;
    GlSessionRecord('glEnd', []);
    LOther.EndFrame('t');
    Assert.AreEqual(Int64(0), Int64(FStream.Size));
    Assert.AreNotEqual(Int64(0), Int64(LOtherStream.Size));
  finally
    GlSessionStop;
    LOther := nil;
    LOtherStream.Free;
  end;
end;

procedure TTestOpenGlSession.DovrebbeSeguireLoStatoAncheFuoriDaUnFotogramma;
var
  LPixels: array[0..17] of Byte;
begin
  FillChar(LPixels, SizeOf(LPixels), 1);
  GlSessionStart(FRecorder);
  // l'allineamento e dato fuori da un fotogramma: vale anche nel fotogramma dopo
  GlSessionRecord('glPixelStorei', [TGlValue.FromEnum(GLR_UNPACK_ALIGNMENT), TGlValue.FromInteger(1)]);
  FRecorder.BeginFrame;
  GlSessionRecord('glTexImage2D', [TGlValue.FromEnum($0DE1), TGlValue.FromInteger(0), TGlValue.FromInteger(3),
    TGlValue.FromInteger(3), TGlValue.FromInteger(2), TGlValue.FromInteger(0), TGlValue.FromEnum($1907),
    TGlValue.FromEnum($1401), TGlValue.FromPointer(@LPixels[0])]);
  FRecorder.EndFrame('t');
  Assert.IsTrue(Written.Contains('/18)'));
end;

procedure TTestOpenGlSession.DovrebbeDareZeroFunzioniSostituiteSenzaGlrecord;
begin
  if GL_RECORDER_COMPILED then
    Assert.Pass('compilato con GLRECORD: la sostituzione e provata dai test dei thunk')
  else
    Assert.AreEqual(0, GlRecorderInstall(FRecorder));
end;

procedure TTestOpenGlSession.DovrebbeDareUnElencoVuotoDelleMancantiSenzaGlrecord;
begin
  if not GL_RECORDER_COMPILED then
    Assert.AreEqual('', GlRecorderMissing)
  else
    Assert.Pass('compilato con GLRECORD');
end;

procedure TTestOpenGlSession.DovrebbeSaperePerQualeBuildEStatoCompilato;
begin
{$IFDEF GLRECORD}
  Assert.IsTrue(GL_RECORDER_COMPILED);
{$ELSE}
  Assert.IsFalse(GL_RECORDER_COMPILED);
{$ENDIF}
end;

{ TTestOpenGlValue }

procedure TTestOpenGlValue.DovrebbeTenereIFloatConIloroBit;
begin
  Assert.AreEqual(Int64($3F800000), TGlValue.FromSingle(1.0).Bits);
  Assert.AreEqual(Int64($C0400000), TGlValue.FromSingle(-3.0).Bits);
  Assert.IsTrue(TGlValue.FromSingle(1.0).Kind = vkSingle);
end;

procedure TTestOpenGlValue.DovrebbeTenereIDoubleConIloroBit;
begin
  Assert.AreEqual(Int64($3FF0000000000000), TGlValue.FromDouble(1.0).Bits);
  Assert.IsTrue(TGlValue.FromDouble(1.0).Kind = vkDouble);
end;

procedure TTestOpenGlValue.DovrebbeDareUnConteggioDaUnIntero;
begin
  Assert.AreEqual(12, TGlValue.FromInteger(12).AsCount);
  Assert.AreEqual(12, TGlValue.FromEnum(12).AsCount);
end;

procedure TTestOpenGlValue.DovrebbeDareZeroPerUnConteggioNegativo;
begin
  Assert.AreEqual(0, TGlValue.FromInteger(-1).AsCount);
end;

procedure TTestOpenGlValue.DovrebbeDareZeroPerUnConteggioTroppoGrande;
begin
  Assert.AreEqual(0, TGlValue.FromInteger(Int64(High(Integer)) + 1).AsCount);
end;

procedure TTestOpenGlValue.DovrebbeDareZeroComeInteroPerUnFloat;
begin
  Assert.AreEqual(Int64(0), TGlValue.FromSingle(5.0).AsInteger);
  Assert.AreEqual(Int64(0), TGlValue.FromPointer(nil).AsInteger);
end;

end.
