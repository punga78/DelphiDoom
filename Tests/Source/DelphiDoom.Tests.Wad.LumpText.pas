{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TWadLumpText                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.LumpText;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('wad')]
  TTestWadLumpText = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnaStringaVuotaSeIlBufferEVuoto;
    [Test]
    procedure DovrebbeDareUnaStringaVuotaSeIlPuntatoreENil;
    [Test]
    procedure DovrebbeDareUnaStringaVuotaSeIlConteggioENonPositivo;
    [Test]
    procedure DovrebbeCopiareUnCarattereAPerByte;
    [Test]
    procedure DovrebbeSostituireIlByteZeroConUnoSpazio;
    [Test]
    procedure DovrebbeTenereIByteSopraAscii127;
    [Test]
    procedure DovrebbeLeggereSoloIlNumeroDiByteRichiesto;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDalPuntatoreEDaTBytes;
  end;

implementation

uses
  DelphiDoom.Wad.Text;

{ TTestWadLumpText }

procedure TTestWadLumpText.DovrebbeDareUnaStringaVuotaSeIlBufferEVuoto;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 0);
  Assert.AreEqual('', TWadLumpText.FromBuffer(LBytes));
end;

procedure TTestWadLumpText.DovrebbeDareUnaStringaVuotaSeIlPuntatoreENil;
begin
  Assert.AreEqual('', TWadLumpText.FromBuffer(nil, 5));
end;

procedure TTestWadLumpText.DovrebbeDareUnaStringaVuotaSeIlConteggioENonPositivo;
var
  LByte: Byte;
begin
  LByte := 65;
  Assert.AreEqual('', TWadLumpText.FromBuffer(@LByte, 0));
  Assert.AreEqual('', TWadLumpText.FromBuffer(@LByte, -3));
end;

procedure TTestWadLumpText.DovrebbeCopiareUnCarattereAPerByte;
var
  LBytes: TBytes;
begin
  LBytes := TBytes.Create(Ord('A'), Ord('c'), Ord('t'), Ord('o'), Ord('r'));
  Assert.AreEqual('Actor', TWadLumpText.FromBuffer(LBytes));
end;

procedure TTestWadLumpText.DovrebbeSostituireIlByteZeroConUnoSpazio;
var
  LBytes: TBytes;
begin
  LBytes := TBytes.Create(Ord('a'), 0, Ord('b'), 0, 0);
  Assert.AreEqual('a b  ', TWadLumpText.FromBuffer(LBytes));
end;

procedure TTestWadLumpText.DovrebbeTenereIByteSopraAscii127;
var
  LBytes: TBytes;
  LText: string;
begin
  LBytes := TBytes.Create($E8, $FF, $80);
  LText := TWadLumpText.FromBuffer(LBytes);
  Assert.AreEqual(3, Length(LText));
  Assert.AreEqual($E8, Ord(LText[1]));
  Assert.AreEqual($FF, Ord(LText[2]));
  Assert.AreEqual($80, Ord(LText[3]));
end;

procedure TTestWadLumpText.DovrebbeLeggereSoloIlNumeroDiByteRichiesto;
var
  LBytes: TBytes;
begin
  LBytes := TBytes.Create(Ord('x'), Ord('y'), Ord('z'));
  Assert.AreEqual('xy', TWadLumpText.FromBuffer(@LBytes[0], 2));
end;

procedure TTestWadLumpText.DovrebbeDareLoStessoRisultatoDalPuntatoreEDaTBytes;
var
  LBytes: TBytes;
begin
  LBytes := TBytes.Create(1, 0, 255, 32, 0, 126);
  Assert.AreEqual(TWadLumpText.FromBuffer(LBytes),
    TWadLumpText.FromBuffer(@LBytes[0], Length(LBytes)));
end;

end.
