{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - the arithmetic                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.Arithmetic;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Acs.Machine.Arithmetic;

type
  [TestFixture]
  [Category('acs')]
  TTestAcsArithmetic = class(TObject)
  public
    [Test]
    [TestCase('divide', '7,2,3')]
    [TestCase('divide negative', '-7,2,-3')]
    [TestCase('divide by zero', '5,0,0')]
    [TestCase('divide by minus one', '9,-1,-9')]
    procedure DovrebbeDividere(ADividend, ADivisor, AExpected: Integer);

    [Test]
    procedure DovrebbeDividereIlNumeroPiuPiccoloPerMenoUnoSenzaEccezione;

    [Test]
    [TestCase('modulo', '7,3,1')]
    [TestCase('modulo negative', '-7,2,-1')]
    [TestCase('modulo by zero', '5,0,0')]
    [TestCase('modulo by minus one', '5,-1,0')]
    procedure DovrebbeCalcolareIlResto(ADividend, ADivisor, AExpected: Integer);

    [Test]
    [TestCase('shift one', '1,4,16')]
    [TestCase('shift to the sign', '1,31,-2147483648')]
    [TestCase('shift uses five bits', '1,33,2')]
    procedure DovrebbeSpostareASinistra(AValue, ACount, AExpected: Integer);

    [Test]
    [TestCase('shift right', '256,4,16')]
    [TestCase('shift right negative', '-8,1,-4')]
    [TestCase('shift right negative a lot', '-1,31,-1')]
    [TestCase('shift right uses five bits', '64,34,16')]
    procedure DovrebbeSpostareADestraConservandoIlSegno(AValue, ACount, AExpected: Integer);
  end;

implementation

{ TTestAcsArithmetic }

procedure TTestAcsArithmetic.DovrebbeDividere(ADividend, ADivisor, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TAcsArithmetic.Divide(ADividend, ADivisor));
end;

procedure TTestAcsArithmetic.DovrebbeDividereIlNumeroPiuPiccoloPerMenoUnoSenzaEccezione;
begin
  Assert.AreEqual(Low(Integer), TAcsArithmetic.Divide(Low(Integer), -1));
end;

procedure TTestAcsArithmetic.DovrebbeCalcolareIlResto(ADividend, ADivisor, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TAcsArithmetic.Modulo(ADividend, ADivisor));
end;

procedure TTestAcsArithmetic.DovrebbeSpostareASinistra(AValue, ACount, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TAcsArithmetic.ShiftLeft(AValue, ACount));
end;

procedure TTestAcsArithmetic.DovrebbeSpostareADestraConservandoIlSegno(AValue, ACount,
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TAcsArithmetic.ShiftRight(AValue, ACount));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAcsArithmetic);

end.
