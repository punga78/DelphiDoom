{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the clock that is real or virtual }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.SwitchClock;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Clock.ManualClock,
  DelphiDoom.Parity.SwitchClock,
  DelphiDoom.Tests.Parity.Fakes;

type
  [TestFixture]
  [Category('parity')]
  TTestParitySwitchClock = class(TObject)
  strict private
    FReal: TManualClock;
    FRealRef: IClock;
    FSwitch: TFakeParitySwitch;
    FSwitchRef: IInterface;
    FClock: TParitySwitchClock;
    FClockRef: IClock;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnOrologioNil;
    [Test]
    procedure DovrebbeRifiutareUnInterruttoreNil;
    [Test]
    procedure ConLInterruttoreSpentoDovrebbeSeguireLOrologioVero;
    [Test]
    procedure ConLInterruttoreSpentoLaFineDelFotogrammaNonDovrebbeFarNulla;
    [Test]
    procedure ConLInterruttoreSpentoSleepDovrebbeIrALOrologioVero;
    [Test]
    procedure ConLInterruttoreAccesoDovrebbeContareITic;
    [Test]
    procedure ConLInterruttoreAccesoLOrologioVeroNonDovrebbeEssereLetto;
    [Test]
    procedure ConLInterruttoreAccesoLaFineDelFotogrammaDovrebbeAvanzare;
    [Test]
    procedure DovrebbeAccorgersiDelCambioDiInterruttore;
  end;

implementation

procedure TTestParitySwitchClock.Setup;
begin
  FReal := TManualClock.Create;
  FRealRef := FReal;
  FSwitch := TFakeParitySwitch.Create;
  FSwitchRef := FSwitch;
  FClock := TParitySwitchClock.Create(FRealRef, FSwitch, 35);
  FClockRef := FClock;
end;

procedure TTestParitySwitchClock.TearDown;
begin
  FClock := nil;
  FClockRef := nil;
  FSwitch := nil;
  FSwitchRef := nil;
  FReal := nil;
  FRealRef := nil;
end;

procedure TTestParitySwitchClock.DovrebbeRifiutareUnOrologioNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TParitySwitchClock.Create(nil, FSwitch, 35);
    end, EArgumentNilException);
end;

procedure TTestParitySwitchClock.DovrebbeRifiutareUnInterruttoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TParitySwitchClock.Create(FRealRef, nil, 35);
    end, EArgumentNilException);
end;

procedure TTestParitySwitchClock.ConLInterruttoreSpentoDovrebbeSeguireLOrologioVero;
begin
  FReal.Advance(2000);
  Assert.AreEqual(70, FClockRef.Steps(35));
  Assert.AreEqual(2.0, FClockRef.Seconds, 0.0000001);
  Assert.AreEqual(70 * 100, FClockRef.ScaledSteps(35, 100));
end;

procedure TTestParitySwitchClock.ConLInterruttoreSpentoLaFineDelFotogrammaNonDovrebbeFarNulla;
begin
  FClock.AdvanceFrame;
  FClock.AdvanceFrame;
  Assert.AreEqual(0, FClockRef.Steps(35));
  Assert.AreEqual(0, FClock.VirtualTics);
end;

procedure TTestParitySwitchClock.ConLInterruttoreSpentoSleepDovrebbeIrALOrologioVero;
begin
  FClockRef.Sleep(1000);
  Assert.AreEqual(Cardinal(1000), FReal.Milliseconds);
end;

procedure TTestParitySwitchClock.ConLInterruttoreAccesoDovrebbeContareITic;
begin
  FSwitch.Active := True;
  FReal.Advance(5000);
  Assert.AreEqual(0, FClockRef.Steps(35));
  FClock.AdvanceFrame;
  FClock.AdvanceFrame;
  Assert.AreEqual(2, FClockRef.Steps(35));
end;

procedure TTestParitySwitchClock.ConLInterruttoreAccesoLOrologioVeroNonDovrebbeEssereLetto;
begin
  FSwitch.Active := True;
  FClockRef.Sleep(1000);
  Assert.AreEqual(Cardinal(0), FReal.Milliseconds);
  Assert.AreEqual(1, FClock.VirtualTics);
end;

procedure TTestParitySwitchClock.ConLInterruttoreAccesoLaFineDelFotogrammaDovrebbeAvanzare;
begin
  FSwitch.Active := True;
  FClock.AdvanceFrame;
  Assert.AreEqual(1, FClock.VirtualTics);
end;

procedure TTestParitySwitchClock.DovrebbeAccorgersiDelCambioDiInterruttore;
begin
  FReal.Advance(1000);
  Assert.AreEqual(35, FClockRef.Steps(35));
  FSwitch.Active := True;
  Assert.AreEqual(0, FClockRef.Steps(35));
  FSwitch.Active := False;
  Assert.AreEqual(35, FClockRef.Steps(35));
end;

end.
