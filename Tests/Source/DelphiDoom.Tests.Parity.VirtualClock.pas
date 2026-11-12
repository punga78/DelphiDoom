{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the virtual clock                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.VirtualClock;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Parity.VirtualClock;

type
  [TestFixture]
  [Category('parity')]
  TTestParityVirtualClock = class(TObject)
  strict private
    FClock: TParityVirtualClock;
    FClockRef: IClock;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePartireDaZero;
    [Test]
    procedure NonDovrebbeAvanzareDaSolo;
    [Test]
    procedure FineFotogrammaDovrebbeAvanzareDiUnTic;
    [Test]
    procedure IPassiNellaFrequenzaDelGiocoDovrebbeEssereITic;
    [Test]
    procedure IPassiADiversaFrequenzaDovrebberoEssereProporzionali;
    [Test]
    procedure IPassiScalatiDovrebberoEssereIlTicPerLaScala;
    [Test]
    procedure ISecondiDovrebberoEssereITicDivisiPerLaFrequenza;
    [Test]
    procedure SleepEWaitDovrebberoAvanzareDiUnTic;
    [Test]
    procedure UnaSerieLungaDiLettureSenzaAvanzamentoDovrebbeAvanzare;
    [Test]
    procedure UnAvanzamentoDovrebbeAzzerareIlContoDelleLetture;
  end;

implementation

procedure TTestParityVirtualClock.Setup;
begin
  FClock := TParityVirtualClock.Create(35);
  FClockRef := FClock;
end;

procedure TTestParityVirtualClock.TearDown;
begin
  FClock := nil;
  FClockRef := nil;
end;

procedure TTestParityVirtualClock.DovrebbePartireDaZero;
begin
  Assert.AreEqual(0, FClockRef.Steps(35));
  Assert.AreEqual(0, FClock.Tics);
  Assert.AreEqual(0.0, FClockRef.Seconds, 0.0000001);
end;

procedure TTestParityVirtualClock.NonDovrebbeAvanzareDaSolo;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 1000 do
    FClockRef.Steps(35);
  Assert.AreEqual(0, FClock.Tics);
end;

procedure TTestParityVirtualClock.FineFotogrammaDovrebbeAvanzareDiUnTic;
begin
  FClock.AdvanceFrame;
  FClock.AdvanceFrame;
  Assert.AreEqual(2, FClockRef.Steps(35));
end;

procedure TTestParityVirtualClock.IPassiNellaFrequenzaDelGiocoDovrebbeEssereITic;
begin
  FClock.AdvanceFrame;
  FClock.AdvanceFrame;
  FClock.AdvanceFrame;
  Assert.AreEqual(3, FClockRef.Steps(35));
end;

procedure TTestParityVirtualClock.IPassiADiversaFrequenzaDovrebberoEssereProporzionali;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 35 do
    FClock.AdvanceFrame;
  Assert.AreEqual(1000, FClockRef.Steps(1000));
  Assert.AreEqual(70, FClockRef.Steps(70));
end;

procedure TTestParityVirtualClock.IPassiScalatiDovrebberoEssereIlTicPerLaScala;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 7 do
    FClock.AdvanceFrame;
  Assert.AreEqual(7 * 65536, FClockRef.ScaledSteps(35, 65536));
end;

procedure TTestParityVirtualClock.ISecondiDovrebberoEssereITicDivisiPerLaFrequenza;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 70 do
    FClock.AdvanceFrame;
  Assert.AreEqual(2.0, FClockRef.Seconds, 0.0000001);
end;

procedure TTestParityVirtualClock.SleepEWaitDovrebberoAvanzareDiUnTic;
begin
  FClockRef.Sleep(500);
  FClockRef.Wait(2000);
  Assert.AreEqual(2, FClock.Tics);
end;

procedure TTestParityVirtualClock.UnaSerieLungaDiLettureSenzaAvanzamentoDovrebbeAvanzare;
var
  LIndex: Integer;
begin
  // a loop that waits for the time to pass must not wait for ever
  for LIndex := 1 to 100005 do
    FClockRef.Steps(35);
  Assert.AreEqual(1, FClock.Tics);
end;

procedure TTestParityVirtualClock.UnAvanzamentoDovrebbeAzzerareIlContoDelleLetture;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 99000 do
    FClockRef.Steps(35);
  FClock.AdvanceFrame;
  for LIndex := 1 to 99000 do
    FClockRef.Steps(35);
  Assert.AreEqual(1, FClock.Tics);
end;

end.
