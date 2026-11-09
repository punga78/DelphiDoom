{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomTimer                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Timer;

interface

uses
  DUnitX.TestFramework, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.ManualClock;

type
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomTimer = class
  strict private
    FClock: TXcomManualClock;
    FInterface: IInterface;
    FCalls: Integer;
    FSurfaceCalls: Integer;
    function NewTimer(AInterval: Cardinal; AFrameSkipping: Boolean = False; AMaxSkip: Integer = 0): TXcomTimer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure NonScattaSeFermo;
    [Test]
    procedure ScattaDopoLIntervallo;
    [Test]
    procedure ScattaUnaSolaVoltaSenzaFrameSkipping;
    [Test]
    procedure RecuperaIColpiConFrameSkipping;
    [Test]
    procedure SiFermaSeLoStatoNonEPiuQuelloAttivo;
    [Test]
    procedure ChiamaIlGestoreDellaSuperficie;
    [Test]
    procedure TimeDiceIMillisecondiDallUltimoScatto;
  end;

implementation

function TTestXcomTimer.NewTimer(AInterval: Cardinal; AFrameSkipping: Boolean; AMaxSkip: Integer): TXcomTimer;
begin
  Result := TXcomTimer.Create(FClock, AInterval, AFrameSkipping, AMaxSkip);
  Result.OnTimerState(
    procedure
    begin
      Inc(FCalls);
    end);
  Result.OnTimerSurface(
    procedure
    begin
      Inc(FSurfaceCalls);
    end);
end;

procedure TTestXcomTimer.Setup;
begin
  FClock := TXcomManualClock.Create;
  FInterface := FClock;
  FCalls := 0;
  FSurfaceCalls := 0;
end;

procedure TTestXcomTimer.NonScattaSeFermo;
var
  LTimer: TXcomTimer;
begin
  LTimer := NewTimer(10);
  try
    FClock.Advance(100);
    LTimer.Think(True, True);
    Assert.AreEqual(0, FCalls);
    Assert.IsFalse(LTimer.IsRunning);
  finally
    LTimer.Free;
  end;
end;

procedure TTestXcomTimer.ScattaDopoLIntervallo;
var
  LTimer: TXcomTimer;
begin
  LTimer := NewTimer(10);
  try
    LTimer.Start;
    FClock.Advance(9);
    LTimer.Think(True, False);
    Assert.AreEqual(0, FCalls);
    FClock.Advance(1);
    LTimer.Think(True, False);
    Assert.AreEqual(1, FCalls);
  finally
    LTimer.Free;
  end;
end;

procedure TTestXcomTimer.ScattaUnaSolaVoltaSenzaFrameSkipping;
var
  LTimer: TXcomTimer;
begin
  LTimer := NewTimer(10, False, 8);
  try
    LTimer.Start;
    FClock.Advance(55);
    LTimer.Think(True, False, function: Boolean begin Result := True; end);
    Assert.AreEqual(1, FCalls);
  finally
    LTimer.Free;
  end;
end;

procedure TTestXcomTimer.RecuperaIColpiConFrameSkipping;
var
  LTimer: TXcomTimer;
begin
  LTimer := NewTimer(10, True, 8);
  try
    LTimer.Start;
    FClock.Advance(55);
    LTimer.Think(True, False, function: Boolean begin Result := True; end);
    Assert.AreEqual(5, FCalls);
  finally
    LTimer.Free;
  end;
end;

procedure TTestXcomTimer.SiFermaSeLoStatoNonEPiuQuelloAttivo;
var
  LTimer: TXcomTimer;
begin
  LTimer := NewTimer(10, True, 8);
  try
    LTimer.Start;
    FClock.Advance(55);
    LTimer.Think(True, False, function: Boolean begin Result := False; end);
    Assert.AreEqual(1, FCalls);
  finally
    LTimer.Free;
  end;
end;

procedure TTestXcomTimer.ChiamaIlGestoreDellaSuperficie;
var
  LTimer: TXcomTimer;
begin
  LTimer := NewTimer(10);
  try
    LTimer.Start;
    FClock.Advance(10);
    LTimer.Think(False, True);
    Assert.AreEqual(0, FCalls);
    Assert.AreEqual(1, FSurfaceCalls);
  finally
    LTimer.Free;
  end;
end;

procedure TTestXcomTimer.TimeDiceIMillisecondiDallUltimoScatto;
var
  LTimer: TXcomTimer;
begin
  LTimer := NewTimer(10);
  try
    LTimer.Start;
    FClock.Advance(4);
    Assert.AreEqual(Cardinal(4), LTimer.Time);
  finally
    LTimer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomTimer);

end.
