{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the clock library - the manual clock                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Clock.ManualClock;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Clock.Intf, DelphiDoom.Clock.ManualClock;

type
  [TestFixture]
  [Category('clock')]
  TTestClockManualClock = class(TObject)
  private
    FClock: TManualClock;
    FClockRef: IClock;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePartireDalTempoDato;
    [Test]
    procedure DovrebbeAvanzareSoloSeGliSiDice;
    [Test]
    procedure LAttesaDovrebbeEssereUnAvanzamento;
    [Test]
    procedure UnAttesaNegativaNonDovrebbeTornareIndietro;
    [Test]
    procedure IPassiAMilleDovrebberoEssereIMillisecondiEsatti;
    [Test]
    procedure IPassiDovrebberoEssereTroncati;
    [Test]
    procedure IPassiScalatiDovrebberoTenereLaParteFrazionaria;
    [Test]
    procedure ISecondiDovrebberoEssereIMillisecondiDivisiPerMille;
    [Test]
    procedure IMillisecondiDovrebberoFareIlGiroA32Bit;
  end;

implementation

procedure TTestClockManualClock.Setup;
begin
  FClock := TManualClock.Create;
  FClockRef := FClock;
end;

procedure TTestClockManualClock.TearDown;
begin
  FClock := nil;
  FClockRef := nil;
end;

procedure TTestClockManualClock.DovrebbePartireDalTempoDato;
var
  LClock: IClock;
begin
  Assert.AreEqual(0, FClockRef.Steps(1000));
  LClock := TManualClock.Create(100);
  Assert.AreEqual(100, LClock.Steps(1000));
end;

procedure TTestClockManualClock.DovrebbeAvanzareSoloSeGliSiDice;
begin
  Assert.AreEqual(Cardinal(0), FClock.Milliseconds);
  Assert.AreEqual(Cardinal(0), FClock.Milliseconds, 'leggerlo non lo muove');
  FClock.Advance(10);
  FClock.Advance(5);
  Assert.AreEqual(Cardinal(15), FClock.Milliseconds);
end;

procedure TTestClockManualClock.LAttesaDovrebbeEssereUnAvanzamento;
begin
  FClockRef.Sleep(16);
  FClockRef.Wait(4);
  Assert.AreEqual(Cardinal(20), FClock.Milliseconds);
end;

procedure TTestClockManualClock.UnAttesaNegativaNonDovrebbeTornareIndietro;
begin
  FClock.Advance(50);
  FClockRef.Sleep(-10);
  FClockRef.Sleep(0);
  Assert.AreEqual(Cardinal(50), FClock.Milliseconds);
end;

procedure TTestClockManualClock.IPassiAMilleDovrebberoEssereIMillisecondiEsatti;
var
  LIndex: Integer;
begin
  // a clock that divided and multiplied in floating point would lose a millisecond here and there
  for LIndex := 1 to 5000 do
  begin
    FClock.Advance(1);
    Assert.AreEqual(LIndex, FClockRef.Steps(1000));
  end;
  FClock.Advance(123456789);
  Assert.AreEqual(123461789, FClockRef.Steps(1000));
end;

procedure TTestClockManualClock.IPassiDovrebberoEssereTroncati;
begin
  FClock.Advance(999);
  Assert.AreEqual(34, FClockRef.Steps(35));
  FClock.Advance(1);
  Assert.AreEqual(35, FClockRef.Steps(35));
end;

procedure TTestClockManualClock.IPassiScalatiDovrebberoTenereLaParteFrazionaria;
begin
  FClock.Advance(500);
  Assert.AreEqual(17 * 65536 + 32768, FClockRef.ScaledSteps(35, 65536));
end;

procedure TTestClockManualClock.ISecondiDovrebberoEssereIMillisecondiDivisiPerMille;
begin
  FClock.Advance(2500);
  Assert.AreEqual(Double(2.5), FClockRef.Seconds, 1E-12);
end;

procedure TTestClockManualClock.IMillisecondiDovrebberoFareIlGiroA32Bit;
begin
  FClock.Advance($FFFFFFFF);
  FClock.Advance(2);
  Assert.AreEqual(Cardinal(1), FClock.Milliseconds);
end;

end.
