{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the warning of the battlescape (WarningMessage)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.WarningMessage;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.ManualClock,
  DelphiDoom.XcomBattleStates.WarningMessage;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomWarningMessage = class
  strict private
    FClock: TXcomManualClock;
    FClockRef: IXcomClock;
    FMessage: TXcomWarningMessage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereNascostoFinoAlPrimoMessaggio;
    [Test]
    procedure DovrebbeMostrareIlTestoERiempireLoSfondoColColore;
    [Test]
    procedure DovrebbeScurireLoSfondoAOgniPassoFinoADodici;
    [Test]
    procedure DovrebbeSparireDopoVentiquattroPassi;
    [Test]
    procedure DovrebbeRipartireConUnNuovoMessaggio;
  end;

implementation

const
  BACKGROUND = 32;

procedure TTestXcomWarningMessage.Setup;
begin
  FClock := TXcomManualClock.Create;
  FClockRef := FClock;
  FMessage := TXcomWarningMessage.Create(FClockRef, 224, 24, 48, 32);
  FMessage.SetColor(BACKGROUND);
end;

procedure TTestXcomWarningMessage.TearDown;
begin
  FMessage.Free;
  FClockRef := nil;
end;

procedure TTestXcomWarningMessage.DovrebbeEssereNascostoFinoAlPrimoMessaggio;
begin
  Assert.IsFalse(FMessage.Visible);
end;

procedure TTestXcomWarningMessage.DovrebbeMostrareIlTestoERiempireLoSfondoColColore;
begin
  FMessage.ShowMessage('Not Enough Time Units!');
  FMessage.Draw;
  Assert.IsTrue(FMessage.Visible);
  Assert.AreEqual('Not Enough Time Units!', FMessage.Text);
  Assert.AreEqual(BACKGROUND, Integer(FMessage.GetPixel(0, 0)));
  Assert.AreEqual(BACKGROUND, Integer(FMessage.GetPixel(223, 23)));
end;

procedure TTestXcomWarningMessage.DovrebbeScurireLoSfondoAOgniPassoFinoADodici;
var
  LStep: Integer;
begin
  FMessage.ShowMessage('x');
  for LStep := 1 to 20 do
  begin
    FClock.Advance(50);
    FMessage.Think;
    FMessage.Draw;
    if LStep <= 12 then
      Assert.AreEqual(BACKGROUND + LStep, Integer(FMessage.GetPixel(0, 0)))
    else
      Assert.AreEqual(BACKGROUND + 12, Integer(FMessage.GetPixel(0, 0)));
  end;
end;

procedure TTestXcomWarningMessage.DovrebbeSparireDopoVentiquattroPassi;
var
  LStep: Integer;
begin
  FMessage.ShowMessage('x');
  for LStep := 1 to 23 do
  begin
    FClock.Advance(50);
    FMessage.Think;
  end;
  Assert.IsTrue(FMessage.Visible);
  FClock.Advance(50);
  FMessage.Think;
  Assert.IsFalse(FMessage.Visible);
end;

procedure TTestXcomWarningMessage.DovrebbeRipartireConUnNuovoMessaggio;
var
  LStep: Integer;
begin
  FMessage.ShowMessage('x');
  for LStep := 1 to 24 do
  begin
    FClock.Advance(50);
    FMessage.Think;
  end;
  FMessage.ShowMessage('y');
  FMessage.Draw;
  Assert.IsTrue(FMessage.Visible);
  Assert.AreEqual(BACKGROUND, Integer(FMessage.GetPixel(0, 0)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomWarningMessage);

end.
