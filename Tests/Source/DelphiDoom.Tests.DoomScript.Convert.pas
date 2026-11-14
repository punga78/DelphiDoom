{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptConvert      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Convert;

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.DoomScript.Types;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptConvert = class
  private
    FSavedMask: TArithmeticExceptionMask;
    function FromBits(const ABits: Cardinal): Single;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTroncareVersoLoZero;
    [Test]
    procedure DovrebbeDareIlMinimoSeNonEUnNumeroOFuoriIntervallo;
    [Test]
    procedure DovrebbeScrivereGliInteriSenzaDecimali;
    [Test]
    procedure DovrebbeScrivereLeFrazioniConSeiDecimali;
    [Test]
    procedure DovrebbeScrivereConDecimaliUnValoreEnorme;
    [Test]
    procedure DovrebbeArrotondareAlPariISecondi;
    [Test]
    procedure DovrebbeDareIlMinimoPerSecondiFuoriIntervallo;
    [Test]
    procedure DovrebbeConfrontareComeIlCConINaN;
    [Test]
    procedure DovrebbeTrattareLoZeroNegativoComeZero;
    [Test]
    procedure DovrebbeCostruireGliArgomentiDegliEventi;
  end;

implementation

procedure TTestDoomScriptConvert.Setup;
begin
  FSavedMask := SetExceptionMask(exAllArithmeticExceptions);
end;

procedure TTestDoomScriptConvert.TearDown;
begin
  SetExceptionMask(FSavedMask);
end;

function TTestDoomScriptConvert.FromBits(const ABits: Cardinal): Single;
begin
  PCardinal(@Result)^ := ABits;
end;

procedure TTestDoomScriptConvert.DovrebbeTroncareVersoLoZero;
var
  LValue: Single;
begin
  LValue := 1.9;
  Assert.AreEqual(1, TDoomScriptConvert.FloatToInt(LValue));
  LValue := -1.9;
  Assert.AreEqual(-1, TDoomScriptConvert.FloatToInt(LValue));
  LValue := 0;
  Assert.AreEqual(0, TDoomScriptConvert.FloatToInt(LValue));
  LValue := 2147483520.0;
  Assert.AreEqual(2147483520, TDoomScriptConvert.FloatToInt(LValue));
  LValue := -2147483648.0;
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.FloatToInt(LValue));
end;

procedure TTestDoomScriptConvert.DovrebbeDareIlMinimoSeNonEUnNumeroOFuoriIntervallo;
var
  LValue: Single;
begin
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.FloatToInt(FromBits($7FC00000)), 'NaN');
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.FloatToInt(FromBits($7F800000)), '+inf');
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.FloatToInt(FromBits($FF800000)), '-inf');
  LValue := 2147483648.0;
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.FloatToInt(LValue), '2^31');
  LValue := 3E9;
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.FloatToInt(LValue), '3e9');
  LValue := -3E9;
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.FloatToInt(LValue), '-3e9');
end;

procedure TTestDoomScriptConvert.DovrebbeScrivereGliInteriSenzaDecimali;
var
  LValue: Single;
begin
  LValue := 42;
  Assert.AreEqual('42', string(TDoomScriptConvert.FloatToString(LValue)));
  LValue := -3;
  Assert.AreEqual('-3', string(TDoomScriptConvert.FloatToString(LValue)));
  LValue := 0;
  Assert.AreEqual('0', string(TDoomScriptConvert.FloatToString(LValue)));
end;

procedure TTestDoomScriptConvert.DovrebbeScrivereLeFrazioniConSeiDecimali;
var
  LValue: Single;
begin
  LValue := 1.5;
  Assert.AreEqual('1.500000', string(TDoomScriptConvert.FloatToString(LValue)));
  LValue := -0.25;
  Assert.AreEqual('-0.250000', string(TDoomScriptConvert.FloatToString(LValue)));
end;

procedure TTestDoomScriptConvert.DovrebbeScrivereConDecimaliUnValoreEnorme;
var
  LValue: Single;
  LText: string;
begin
  // (int)1e30 does not fit: the value is not "whole" for the original, which writes it with "%f"
  // ("1000000015047466219876688855040.000000"). TIdStrings.FormatFixed gives the digits in another form for
  // a value this large, so only what is common to the two is checked here: it is not the "%d" form
  LValue := 1E30;
  LText := string(TDoomScriptConvert.FloatToString(LValue));
  Assert.AreNotEqual(IntToStr(Low(Integer)), LText);
  Assert.IsTrue(LText.StartsWith('1.0000000150474662') or LText.StartsWith('1000000015047466'), LText);
  // 2^31 is whole but does not fit either
  LValue := 2147483648.0;
  LText := string(TDoomScriptConvert.FloatToString(LValue));
  Assert.IsTrue(LText.StartsWith('2147483648.'), LText);
end;

procedure TTestDoomScriptConvert.DovrebbeArrotondareAlPariISecondi;
var
  LValue: Single;
begin
  LValue := 0.5;
  Assert.AreEqual(500, TDoomScriptConvert.SecToMs(LValue));
  // 62.5 and 187.5 are exact: ties go to the even integer
  LValue := 0.0625;
  Assert.AreEqual(62, TDoomScriptConvert.SecToMs(LValue));
  LValue := 0.1875;
  Assert.AreEqual(188, TDoomScriptConvert.SecToMs(LValue));
  LValue := -0.0625;
  Assert.AreEqual(-62, TDoomScriptConvert.SecToMs(LValue));
  LValue := 0;
  Assert.AreEqual(0, TDoomScriptConvert.SecToMs(LValue));
end;

procedure TTestDoomScriptConvert.DovrebbeDareIlMinimoPerSecondiFuoriIntervallo;
var
  LValue: Single;
begin
  LValue := 3E9;
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.SecToMs(LValue));
  LValue := -3E9;
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.SecToMs(LValue));
  Assert.AreEqual(Low(Integer), TDoomScriptConvert.SecToMs(FromBits($7FC00000)));
end;

procedure TTestDoomScriptConvert.DovrebbeConfrontareComeIlCConINaN;
var
  LNaN: Single;
  LOne: Single;
  LTwo: Single;
begin
  LNaN := FromBits($7FC00000);
  LOne := 1;
  LTwo := 2;
  Assert.IsFalse(TDoomScriptConvert.FloatEq(LNaN, LNaN));
  Assert.IsFalse(TDoomScriptConvert.FloatEq(LNaN, LOne));
  Assert.IsFalse(TDoomScriptConvert.FloatEq(LOne, LNaN));
  Assert.IsTrue(TDoomScriptConvert.FloatEq(LOne, LOne));
  Assert.IsFalse(TDoomScriptConvert.FloatEq(LOne, LTwo));
  Assert.IsFalse(TDoomScriptConvert.FloatLt(LNaN, LOne));
  Assert.IsFalse(TDoomScriptConvert.FloatLt(LOne, LNaN));
  Assert.IsTrue(TDoomScriptConvert.FloatLt(LOne, LTwo));
  Assert.IsFalse(TDoomScriptConvert.FloatLt(LTwo, LTwo));
  Assert.IsFalse(TDoomScriptConvert.FloatLe(LNaN, LNaN));
  Assert.IsFalse(TDoomScriptConvert.FloatLe(LOne, LNaN));
  Assert.IsFalse(TDoomScriptConvert.FloatLe(LNaN, LOne));
  Assert.IsTrue(TDoomScriptConvert.FloatLe(LTwo, LTwo));
  Assert.IsFalse(TDoomScriptConvert.FloatLe(LTwo, LOne));
  Assert.IsTrue(TDoomScriptConvert.FloatNonZero(LNaN));
  Assert.IsTrue(TDoomScriptConvert.FloatNonZero(LOne));
end;

procedure TTestDoomScriptConvert.DovrebbeTrattareLoZeroNegativoComeZero;
var
  LZero: Single;
  LMinusZero: Single;
begin
  LZero := 0;
  LMinusZero := FromBits($80000000);
  Assert.IsFalse(TDoomScriptConvert.FloatNonZero(LMinusZero));
  Assert.IsFalse(TDoomScriptConvert.FloatNonZero(LZero));
  Assert.IsTrue(TDoomScriptConvert.FloatEq(LZero, LMinusZero));
  Assert.IsTrue(TDoomScriptConvert.FloatLe(LZero, LMinusZero));
  Assert.IsFalse(TDoomScriptConvert.FloatLt(LMinusZero, LZero));
  // a denormal is not zero
  Assert.IsTrue(TDoomScriptConvert.FloatNonZero(FromBits($00000001)));
  Assert.AreEqual(0, TDoomScriptConvert.FloatToInt(LMinusZero));
end;

procedure TTestDoomScriptConvert.DovrebbeCostruireGliArgomentiDegliEventi;
var
  LArg: TDoomScriptEventArg;
  LFloat: Single;
begin
  LArg := TDoomScriptConvert.EntityArg(7);
  Assert.AreEqual('e', string(AnsiString(LArg.Kind)));
  Assert.AreEqual(7, LArg.IntValue);
  LArg := TDoomScriptConvert.IntArg(-3);
  Assert.AreEqual('d', string(AnsiString(LArg.Kind)));
  Assert.AreEqual(-3, LArg.IntValue);
  LFloat := 2.5;
  LArg := TDoomScriptConvert.FloatArg(LFloat);
  Assert.AreEqual('f', string(AnsiString(LArg.Kind)));
  Assert.IsTrue(LArg.FloatValue = LFloat);
  LArg := TDoomScriptConvert.StringArg('abc');
  Assert.AreEqual('s', string(AnsiString(LArg.Kind)));
  Assert.AreEqual('abc', string(LArg.StringValue));
  LArg := TDoomScriptConvert.VectorArg(TIdVec3.Create(1, 2, 3));
  Assert.AreEqual('v', string(AnsiString(LArg.Kind)));
  Assert.IsTrue((LArg.VectorValue.X = 1) and (LArg.VectorValue.Y = 2) and (LArg.VectorValue.Z = 3));
  Assert.AreEqual(0, LArg.IntValue);
  Assert.AreEqual('', string(LArg.StringValue));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptConvert);

end.
