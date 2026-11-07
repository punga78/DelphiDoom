{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the translation of the specials of the lines           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.LineSpecialTranslator;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Udmf.Apply.Intf;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfLineSpecialTranslator = class(TObject)
  private
    FTranslator: IUdmfLineSpecialTranslator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLasciareZeroInvariato;
    [Test]
    procedure DovrebbeSpostareUnoSpecialNormaleNelloIntervalloUdmf;
    [Test]
    procedure DovrebbeSpostareUnoSpecialUdmfNelloIntervalloNormale;
    [Test]
    procedure DovrebbeTrattareIlBordoComuneComeSpecialNormale;
    [Test]
    procedure DovrebbeTenereIBitSopraIl1023;
    [Test]
    procedure DovrebbeLasciareUnoSpecialFuoriDagliIntervalli;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Udmf.Apply.Factory;

const
  SPECIAL_START = 700;
  NORMAL_ADD = 300;

function OldInRange(const test, f1, f2: Integer): Boolean;
begin
  if f1 < f2 then
    Result := (test >= f1) and (test <= f2)
  else
    Result := (test >= f2) and (test <= f1);
end;

// the translation of UDMF_DoMakeLine as it was before the port
function OldTranslate(ASpecial: Integer): Integer;
begin
  Result := ASpecial;
  if OldInRange(Result and 1023, 1, NORMAL_ADD) then
    Result := (Result and 1023 + SPECIAL_START) or (Result and not 1023)
  else if OldInRange(Result and 1023, NORMAL_ADD, SPECIAL_START + NORMAL_ADD) then
    Result := (Result and 1023 - NORMAL_ADD) or (Result and not 1023);
end;

{ TTestUdmfLineSpecialTranslator }

procedure TTestUdmfLineSpecialTranslator.Setup;
begin
  FTranslator := TUdmfApplyFactory.CreateLineSpecialTranslator(SPECIAL_START, NORMAL_ADD);
end;

procedure TTestUdmfLineSpecialTranslator.TearDown;
begin
  FTranslator := nil;
end;

procedure TTestUdmfLineSpecialTranslator.DovrebbeLasciareZeroInvariato;
begin
  Assert.AreEqual(0, FTranslator.Translate(0));
end;

procedure TTestUdmfLineSpecialTranslator.DovrebbeSpostareUnoSpecialNormaleNelloIntervalloUdmf;
begin
  Assert.AreEqual(711, FTranslator.Translate(11));
  Assert.AreEqual(701, FTranslator.Translate(1));
end;

procedure TTestUdmfLineSpecialTranslator.DovrebbeSpostareUnoSpecialUdmfNelloIntervalloNormale;
begin
  Assert.AreEqual(400, FTranslator.Translate(700));
  Assert.AreEqual(700, FTranslator.Translate(1000));
end;

procedure TTestUdmfLineSpecialTranslator.DovrebbeTrattareIlBordoComuneComeSpecialNormale;
begin
  Assert.AreEqual(1000, FTranslator.Translate(300));
end;

procedure TTestUdmfLineSpecialTranslator.DovrebbeTenereIBitSopraIl1023;
begin
  Assert.AreEqual(2048 + 711, FTranslator.Translate(2048 + 11));
  Assert.AreEqual(1024 + 400, FTranslator.Translate(1024 + 700));
end;

procedure TTestUdmfLineSpecialTranslator.DovrebbeLasciareUnoSpecialFuoriDagliIntervalli;
begin
  Assert.AreEqual(1001, FTranslator.Translate(1001));
  Assert.AreEqual(1023, FTranslator.Translate(1023));
  Assert.AreEqual(1024, FTranslator.Translate(1024));
end;

procedure TTestUdmfLineSpecialTranslator.DovrebbeDareLeStesseRisposteDelVecchioCodice;
var
  LSpecial: Integer;
begin
  for LSpecial := 0 to 8191 do
    Assert.AreEqual(OldTranslate(LSpecial), FTranslator.Translate(LSpecial),
      Format('special %d', [LSpecial]));
end;

end.
