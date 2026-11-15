{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the number formats of printf (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.CFormat;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotCFormat = class
  public
    [Test]
    procedure DovrebbeScrivereSeiDecimali;
    [Test]
    procedure DovrebbeArrotondareComeLaLibreriaDelC;
    [Test]
    procedure DovrebbeConservareIlSegnoDiUnNegativoCheArrotondaAZero;
    [Test]
    procedure DovrebbeScrivereNanEInfinitiComeIlRuntimeDelC;
    [Test]
    procedure DovrebbeScrivereUnInteroConSegno;
    [Test]
    procedure DovrebbeScrivereUnDecimaleArrotondandoAlPariSeEAMeta;
    [Test]
    procedure DovrebbeScrivereUnDecimaleConSegnoNanEInfiniti;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.BotAi.Text.CFormat;

{ TTestBotCFormat }

procedure TTestBotCFormat.DovrebbeScrivereSeiDecimali;
begin
  Assert.AreEqual('1.500000', string(TBotCFormat.Fixed6(1.5)));
  Assert.AreEqual('0.000000', string(TBotCFormat.Fixed6(0)));
  Assert.AreEqual('-3.250000', string(TBotCFormat.Fixed6(-3.25)));
end;

procedure TTestBotCFormat.DovrebbeArrotondareComeLaLibreriaDelC;
begin
  // a float is promoted to a double: 0.1f is 0.100000001490116...
  Assert.AreEqual('0.100000', string(TBotCFormat.Fixed6(Single(0.1))));
  Assert.AreEqual('123456792.000000', string(TBotCFormat.Fixed6(Single(123456789))));
end;

procedure TTestBotCFormat.DovrebbeConservareIlSegnoDiUnNegativoCheArrotondaAZero;
begin
  Assert.AreEqual('-0.000000', string(TBotCFormat.Fixed6(-0.0000001)));
end;

procedure TTestBotCFormat.DovrebbeScrivereNanEInfinitiComeIlRuntimeDelC;
begin
  Assert.AreEqual('nan', string(TBotCFormat.Fixed6(NaN)));
  Assert.AreEqual('inf', string(TBotCFormat.Fixed6(Infinity)));
  Assert.AreEqual('-inf', string(TBotCFormat.Fixed6(NegInfinity)));
end;

procedure TTestBotCFormat.DovrebbeScrivereUnInteroConSegno;
begin
  Assert.AreEqual('-12', string(TBotCFormat.Int(-12)));
  Assert.AreEqual('0', string(TBotCFormat.Int(0)));
end;

procedure TTestBotCFormat.DovrebbeScrivereUnDecimaleArrotondandoAlPariSeEAMeta;
begin
  // printf rounds the exact value of the double: x.25 and x.75 are exact, so they go to the even decimal
  Assert.AreEqual('0.2', string(TBotCFormat.Fixed1(0.25)));
  Assert.AreEqual('0.8', string(TBotCFormat.Fixed1(0.75)));
  Assert.AreEqual('1.2', string(TBotCFormat.Fixed1(1.25)));
  Assert.AreEqual('-0.2', string(TBotCFormat.Fixed1(-0.25)));
  Assert.AreEqual('-0.8', string(TBotCFormat.Fixed1(-0.75)));
  Assert.AreEqual('1.5', string(TBotCFormat.Fixed1(1.5)));
  Assert.AreEqual('0.3', string(TBotCFormat.Fixed1(0.26)));
end;

procedure TTestBotCFormat.DovrebbeScrivereUnDecimaleConSegnoNanEInfiniti;
begin
  Assert.AreEqual('-0.0', string(TBotCFormat.Fixed1(-0.0001)));
  Assert.AreEqual('nan', string(TBotCFormat.Fixed1(NaN)));
  Assert.AreEqual('inf', string(TBotCFormat.Fixed1(Infinity)));
  Assert.AreEqual('-inf', string(TBotCFormat.Fixed1(NegInfinity)));
end;

end.
