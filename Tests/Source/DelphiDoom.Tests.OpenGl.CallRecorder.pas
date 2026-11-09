{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - the recorder of frames      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.CallRecorder;

interface

uses
  System.Classes, System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.Intf;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlCallRecorder = class(TObject)
  strict private
    FStream: TMemoryStream;
    FRecorder: IGlCallRecorder;
    function Written: string;
    function SumOf(const AText: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereLeRigheEPoiLaSomma;
    [Test]
    procedure DovrebbeScrivereLaSommaDiUnFotogrammaVuoto;
    [Test]
    procedure DovrebbeIgnorareLeChiamateFuoriDaUnFotogramma;
    [Test]
    procedure DovrebbeNonScrivereUnFotogrammaScartato;
    [Test]
    procedure DovrebbeRipartireDaZeroAOgniFotogramma;
    [Test]
    procedure DovrebbeContareISoliFotogrammiScritti;
    [Test]
    procedure DovrebbeDireSeUnFotogrammaEAperto;
    [Test]
    procedure DovrebbeDareLoStessoFlussoPerLeStesseChiamate;
    [Test]
    procedure DovrebbeDareUnaSommaDiversaSeUnaChiamataCambia;
    [Test]
    procedure DovrebbeDareUnaSommaDiversaSeLOrdineCambia;
    [Test]
    procedure DovrebbeDareLoStreamChiHaPassato;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFotogrammaEGiaAperto;
    [Test]
    procedure DovrebbeSollevareUnErroreSeNonCEUnFotogrammaDaChiudere;
    [Test]
    procedure DovrebbeSollevareUnErroreSeNonCEUnFotogrammaDaScartare;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLoStreamEMancante;
  end;

implementation

uses
  DelphiDoom.OpenGl.Recorder.CallRecorder, DelphiDoom.OpenGl.Recorder.Fnv, DelphiDoom.OpenGl.Recorder.Types;

{ TTestOpenGlCallRecorder }

procedure TTestOpenGlCallRecorder.Setup;
begin
  FStream := TMemoryStream.Create;
  FRecorder := TGlCallRecorder.Create(FStream);
end;

procedure TTestOpenGlCallRecorder.TearDown;
begin
  FRecorder := nil;
  FStream.Free;
end;

function TTestOpenGlCallRecorder.Written: string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, FStream.Size);
  if FStream.Size > 0 then
    Move(FStream.Memory^, LBytes[0], FStream.Size);
  Result := TEncoding.ASCII.GetString(LBytes);
end;

function TTestOpenGlCallRecorder.SumOf(const AText: string): string;
begin
  Result := TGlFnv.ToHex(TGlFnv.UpdateText(TGlFnv.Start, AText));
end;

procedure TTestOpenGlCallRecorder.DovrebbeScrivereLeRigheEPoiLaSomma;
begin
  FRecorder.BeginFrame;
  FRecorder.Call('glClear($4100)');
  FRecorder.Call('glEnd()');
  FRecorder.EndFrame('tic=35');
  Assert.AreEqual('glClear($4100)'#10'glEnd()'#10'FRAME tic=35 calls=2 sum=' + SumOf('glClear($4100)'#10'glEnd()'#10)
    + #10, Written);
end;

procedure TTestOpenGlCallRecorder.DovrebbeScrivereLaSommaDiUnFotogrammaVuoto;
begin
  FRecorder.BeginFrame;
  FRecorder.EndFrame('x');
  Assert.AreEqual('FRAME x calls=0 sum=cbf29ce484222325'#10, Written);
end;

procedure TTestOpenGlCallRecorder.DovrebbeIgnorareLeChiamateFuoriDaUnFotogramma;
begin
  FRecorder.Call('glClear($4100)');
  FRecorder.BeginFrame;
  FRecorder.EndFrame('x');
  FRecorder.Call('glEnd()');
  Assert.AreEqual('FRAME x calls=0 sum=cbf29ce484222325'#10, Written);
end;

procedure TTestOpenGlCallRecorder.DovrebbeNonScrivereUnFotogrammaScartato;
begin
  FRecorder.BeginFrame;
  FRecorder.Call('glClear($4100)');
  FRecorder.DiscardFrame;
  Assert.AreEqual('', Written);
  Assert.AreEqual(0, FRecorder.FrameCount);
  Assert.IsFalse(FRecorder.InFrame);
end;

procedure TTestOpenGlCallRecorder.DovrebbeRipartireDaZeroAOgniFotogramma;
begin
  FRecorder.BeginFrame;
  FRecorder.Call('a()');
  FRecorder.DiscardFrame;
  FRecorder.BeginFrame;
  FRecorder.Call('b()');
  FRecorder.EndFrame('t');
  Assert.AreEqual('b()'#10'FRAME t calls=1 sum=' + SumOf('b()'#10) + #10, Written);
end;

procedure TTestOpenGlCallRecorder.DovrebbeContareISoliFotogrammiScritti;
begin
  FRecorder.BeginFrame;
  FRecorder.EndFrame('1');
  FRecorder.BeginFrame;
  FRecorder.DiscardFrame;
  FRecorder.BeginFrame;
  FRecorder.EndFrame('2');
  Assert.AreEqual(2, FRecorder.FrameCount);
end;

procedure TTestOpenGlCallRecorder.DovrebbeDireSeUnFotogrammaEAperto;
begin
  Assert.IsFalse(FRecorder.InFrame);
  FRecorder.BeginFrame;
  Assert.IsTrue(FRecorder.InFrame);
  FRecorder.EndFrame('x');
  Assert.IsFalse(FRecorder.InFrame);
end;

procedure TTestOpenGlCallRecorder.DovrebbeDareLoStessoFlussoPerLeStesseChiamate;
var
  LOtherStream: TMemoryStream;
  LOther: IGlCallRecorder;
  LFirst: string;
begin
  FRecorder.BeginFrame;
  FRecorder.Call('a()');
  FRecorder.EndFrame('t');
  LFirst := Written;
  LOtherStream := TMemoryStream.Create;
  try
    LOther := TGlCallRecorder.Create(LOtherStream);
    LOther.BeginFrame;
    LOther.Call('a()');
    LOther.EndFrame('t');
    Assert.AreEqual(Int64(FStream.Size), LOtherStream.Size);
    Assert.IsTrue(CompareMem(FStream.Memory, LOtherStream.Memory, FStream.Size));
    Assert.AreNotEqual('', LFirst);
  finally
    LOther := nil;
    LOtherStream.Free;
  end;
end;

procedure TTestOpenGlCallRecorder.DovrebbeDareUnaSommaDiversaSeUnaChiamataCambia;
var
  LFirst: string;
begin
  FRecorder.BeginFrame;
  FRecorder.Call('glVertex3f(#3F800000)');
  FRecorder.EndFrame('t');
  LFirst := Written;
  FStream.Clear;
  FRecorder.BeginFrame;
  FRecorder.Call('glVertex3f(#3F800001)');
  FRecorder.EndFrame('t');
  Assert.AreNotEqual(LFirst.Substring(LFirst.IndexOf('sum=')), Written.Substring(Written.IndexOf('sum=')));
end;

procedure TTestOpenGlCallRecorder.DovrebbeDareUnaSommaDiversaSeLOrdineCambia;
begin
  Assert.AreNotEqual(SumOf('a()'#10'b()'#10), SumOf('b()'#10'a()'#10));
  FRecorder.BeginFrame;
  FRecorder.Call('b()');
  FRecorder.Call('a()');
  FRecorder.EndFrame('t');
  Assert.IsTrue(Written.EndsWith('sum=' + SumOf('b()'#10'a()'#10) + #10));
end;

procedure TTestOpenGlCallRecorder.DovrebbeDareLoStreamChiHaPassato;
begin
  Assert.AreSame(TObject(FStream), TObject(FRecorder.Stream));
end;

procedure TTestOpenGlCallRecorder.DovrebbeSollevareUnErroreSeIlFotogrammaEGiaAperto;
begin
  FRecorder.BeginFrame;
  Assert.WillRaise(
    procedure
    begin
      FRecorder.BeginFrame;
    end, EGlRecorderException);
end;

procedure TTestOpenGlCallRecorder.DovrebbeSollevareUnErroreSeNonCEUnFotogrammaDaChiudere;
begin
  Assert.WillRaise(
    procedure
    begin
      FRecorder.EndFrame('x');
    end, EGlRecorderException);
end;

procedure TTestOpenGlCallRecorder.DovrebbeSollevareUnErroreSeNonCEUnFotogrammaDaScartare;
begin
  Assert.WillRaise(
    procedure
    begin
      FRecorder.DiscardFrame;
    end, EGlRecorderException);
end;

procedure TTestOpenGlCallRecorder.DovrebbeSollevareUnErroreSeLoStreamEMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlCallRecorder.Create(nil);
    end, EArgumentNilException);
end;

end.
