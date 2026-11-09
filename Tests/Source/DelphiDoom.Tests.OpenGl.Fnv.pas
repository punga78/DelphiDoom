{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - the FNV-1a hash             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.Fnv;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.Fnv;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlFnv = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLaBaseSeNonCiSonoByte;
    [Test]
    procedure DovrebbeDareIlValoreNotoDiUnaLettera;
    [Test]
    procedure DovrebbeDareIlValoreNotoDiFoobar;
    [Test]
    procedure DovrebbeDareLoStessoValoreDalTestoEDaiByte;
    [Test]
    procedure DovrebbeDareLoStessoValoreSeLaSequenzaESpezzata;
    [Test]
    procedure DovrebbeScrivereSedicicifreEsadecimaliMinuscole;
    [Test]
    procedure DovrebbeIgnorareUnBufferVuoto;
  end;

implementation

{ TTestOpenGlFnv }

procedure TTestOpenGlFnv.DovrebbeDareLaBaseSeNonCiSonoByte;
begin
  Assert.AreEqual('cbf29ce484222325', TGlFnv.ToHex(TGlFnv.Start));
end;

procedure TTestOpenGlFnv.DovrebbeDareIlValoreNotoDiUnaLettera;
begin
  Assert.AreEqual('af63dc4c8601ec8c', TGlFnv.ToHex(TGlFnv.UpdateText(TGlFnv.Start, 'a')));
end;

procedure TTestOpenGlFnv.DovrebbeDareIlValoreNotoDiFoobar;
begin
  Assert.AreEqual('85944171f73967e8', TGlFnv.ToHex(TGlFnv.UpdateText(TGlFnv.Start, 'foobar')));
end;

procedure TTestOpenGlFnv.DovrebbeDareLoStessoValoreDalTestoEDaiByte;
var
  LBytes: array[0..5] of Byte;
begin
  LBytes[0] := Ord('f');
  LBytes[1] := Ord('o');
  LBytes[2] := Ord('o');
  LBytes[3] := Ord('b');
  LBytes[4] := Ord('a');
  LBytes[5] := Ord('r');
  Assert.AreEqual(
    TGlFnv.ToHex(TGlFnv.UpdateText(TGlFnv.Start, 'foobar')),
    TGlFnv.ToHex(TGlFnv.UpdateBuffer(TGlFnv.Start, @LBytes[0], 6)));
end;

procedure TTestOpenGlFnv.DovrebbeDareLoStessoValoreSeLaSequenzaESpezzata;
var
  LHash: UInt64;
begin
  LHash := TGlFnv.UpdateText(TGlFnv.Start, 'foo');
  LHash := TGlFnv.UpdateText(LHash, 'bar');
  Assert.AreEqual('85944171f73967e8', TGlFnv.ToHex(LHash));
end;

procedure TTestOpenGlFnv.DovrebbeScrivereSedicicifreEsadecimaliMinuscole;
begin
  Assert.AreEqual('00000000000000ab', TGlFnv.ToHex($AB));
end;

procedure TTestOpenGlFnv.DovrebbeIgnorareUnBufferVuoto;
var
  LByte: Byte;
begin
  LByte := 7;
  Assert.AreEqual(TGlFnv.OFFSET_BASIS, TGlFnv.UpdateBuffer(TGlFnv.Start, @LByte, 0));
end;

end.
