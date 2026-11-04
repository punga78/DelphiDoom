{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the numeric helpers of the glbsp port                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Util;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Util;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspUtil = class(TObject)
  public
    [Test]
    [TestCase('zero', '0,0')]
    [TestCase('uno', '1,1')]
    [TestCase('due', '2,2')]
    [TestCase('tre', '3,4')]
    [TestCase('cinque', '5,8')]
    [TestCase('otto', '8,8')]
    [TestCase('nove', '9,16')]
    [TestCase('1025', '1025,2048')]
    procedure TestRoundPow2(AValue, AExpected: Integer);

    [Test]
    [TestCase('est', '1,0,0')]
    [TestCase('nord', '0,1,90')]
    [TestCase('ovest', '-1,0,180')]
    [TestCase('sud', '0,-1,270')]
    [TestCase('nord-est', '1,1,45')]
    [TestCase('sud-est', '1,-1,315')]
    [TestCase('nord-ovest', '-1,1,135')]
    procedure TestComputeAngle(ADx, ADy, AExpected: Integer);

    [Test]
    procedure TestRoundToIntArrotondaLontanoDaZero;

    [Test]
    procedure TestAdler32DiWikipedia;
    [Test]
    procedure TestAdler32InPiuBlocchiEquivaleAUnBlocco;
    [Test]
    procedure TestAdler32DiNientePartendoDaUno;
  end;

implementation

{ TTestGlbspUtil }

procedure TTestGlbspUtil.TestRoundPow2(AValue, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TGlbspUtil.RoundPow2(AValue));
end;

procedure TTestGlbspUtil.TestComputeAngle(ADx, ADy, AExpected: Integer);
begin
  Assert.AreEqual(Double(AExpected), TGlbspUtil.ComputeAngle(ADx, ADy), 1E-9);
end;

procedure TTestGlbspUtil.TestRoundToIntArrotondaLontanoDaZero;
begin
  Assert.AreEqual(3, TGlbspUtil.RoundToInt(2.5));
  Assert.AreEqual(-3, TGlbspUtil.RoundToInt(-2.5));
  Assert.AreEqual(2, TGlbspUtil.RoundToInt(2.4));
  Assert.AreEqual(-2, TGlbspUtil.RoundToInt(-2.4));
  Assert.AreEqual(0, TGlbspUtil.RoundToInt(0.0));
end;

procedure TTestGlbspUtil.TestAdler32DiWikipedia;
var
  LData: TBytes;
  LCrc: Cardinal;
begin
  LData := TEncoding.ASCII.GetBytes('Wikipedia');

  LCrc := TGlbspUtil.Adler32AddBlock(TGlbspUtil.Adler32Begin, @LData[0], Length(LData));

  Assert.AreEqual(Cardinal($11E60398), LCrc);
end;

procedure TTestGlbspUtil.TestAdler32InPiuBlocchiEquivaleAUnBlocco;
var
  LData: TBytes;
  LCrc: Cardinal;
begin
  LData := TEncoding.ASCII.GetBytes('Wikipedia');

  LCrc := TGlbspUtil.Adler32AddBlock(TGlbspUtil.Adler32Begin, @LData[0], 4);
  LCrc := TGlbspUtil.Adler32AddBlock(LCrc, @LData[4], 5);

  Assert.AreEqual(Cardinal($11E60398), LCrc);
end;

procedure TTestGlbspUtil.TestAdler32DiNientePartendoDaUno;
begin
  Assert.AreEqual(Cardinal(1), TGlbspUtil.Adler32Begin);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspUtil);

end.
