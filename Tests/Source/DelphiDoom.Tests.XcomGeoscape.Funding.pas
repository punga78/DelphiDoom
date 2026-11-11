{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom basescape library - the format of the funds    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.Funding;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomBasescape.Funding;

type
  [TestFixture]
  [Category('XcomBasescape')]
  TTestXcomFunding = class
  public
    [TestCase('zero', '0,$0')]
    [TestCase('tre cifre', '999,$999')]
    [TestCase('migliaia', '6008000,$6'#$A0'008'#$A0'000')]
    [TestCase('mille', '1000,$1'#$A0'000')]
    [TestCase('negativo', '-1500,-$1'#$A0'500')]
    procedure DovrebbeSeparareLeMigliaiaConLoSpazioDelTesto(AValue: Int64; const AExpected: string);
    [Test]
    procedure DovrebbeFormattareUnNumeroSenzaValuta;
  end;

implementation

procedure TTestXcomFunding.DovrebbeSeparareLeMigliaiaConLoSpazioDelTesto(AValue: Int64; const AExpected: string);
begin
  Assert.AreEqual(AExpected, TXcomFunding.Format(AValue));
end;

procedure TTestXcomFunding.DovrebbeFormattareUnNumeroSenzaValuta;
begin
  Assert.AreEqual('12'#$A0'345', TXcomFunding.FormatNumber(12345, ''));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomFunding);

end.
