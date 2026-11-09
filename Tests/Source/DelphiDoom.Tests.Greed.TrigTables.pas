{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedTrigTables - parity with RF_Startup of xGreed     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.TrigTables;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.TrigTables;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedTrigTables = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIValoriNotevoliDelCerchio;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelCodiceOriginale;
    [Test]
    procedure DovrebbePrendereLAngoloModulo1024;
  end;

implementation

uses
  DelphiDoom.Greed.Types;

const
  // g_PI and rint of the original (r_public_h.pas, r_refdef.pas), as they were
  g_PI = 3.14159265;

function OldRint(const x: double): integer;
begin
  Result := trunc(x + 0.5);
end;

{ TTestGreedTrigTables }

procedure TTestGreedTrigTables.DovrebbeDareIValoriNotevoliDelCerchio;
begin
  Assert.AreEqual(0, TGreedTrigTables.Sine(0));
  Assert.AreEqual(GREED_FRACUNIT, TGreedTrigTables.Cosine(0));
  // the pi of the original is a little short: 256 is not exactly 65536
  Assert.IsTrue(Abs(TGreedTrigTables.Sine(256) - GREED_FRACUNIT) <= 1);
  Assert.IsTrue(Abs(TGreedTrigTables.Cosine(512) + GREED_FRACUNIT) <= 1);
end;

procedure TTestGreedTrigTables.DovrebbeDareGliStessiValoriDelCodiceOriginale;
var
  LIndex: Integer;
  LAngle: double;
begin
  for LIndex := 0 to GREED_ANGLES do
  begin
    LAngle := (LIndex * g_PI * 2) / (GREED_ANGLES + 1);
    Assert.AreEqual(OldRint(sin(LAngle) * GREED_FRACUNIT), TGreedTrigTables.Sine(LIndex), 'sin ' + IntToStr(LIndex));
    Assert.AreEqual(OldRint(cos(LAngle) * GREED_FRACUNIT), TGreedTrigTables.Cosine(LIndex), 'cos ' + IntToStr(LIndex));
  end;
end;

procedure TTestGreedTrigTables.DovrebbePrendereLAngoloModulo1024;
begin
  Assert.AreEqual(TGreedTrigTables.Sine(5), TGreedTrigTables.Sine(5 + 1024));
  Assert.AreEqual(TGreedTrigTables.Cosine(1023), TGreedTrigTables.Cosine(-1));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedTrigTables);

end.
