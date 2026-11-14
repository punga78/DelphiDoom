{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the clock library - the resolution of the timer         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Clock.TimerResolution;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Clock.Intf, DelphiDoom.Clock.TimerResolution,
  DelphiDoom.Clock.WindowsTimerResolution, DelphiDoom.Clock.Factory;

type
  /// <summary>A timer of the system that counts the periods asked and given back</summary>
  TFakeTimerSystem = class(TInterfacedObject, ITimerResolutionSystem)
  public
    Grant: Boolean;
    Began: TArray<Integer>;
    Ended: TArray<Integer>;
    constructor Create;
    function BeginPeriod(AMilliseconds: Integer): Boolean;
    procedure EndPeriod(AMilliseconds: Integer);
  end;

  [TestFixture]
  [Category('clock')]
  TTestClockTimerResolution = class(TObject)
  public
    [Test]
    procedure DovrebbeChiedereIlPeriodoQuandoNasce;
    [Test]
    procedure DovrebbeRestituireIlPeriodoUnaSolaVoltaQuandoSiRilascia;
    [Test]
    procedure NonDovrebbeRestituireUnPeriodoRifiutato;
    [Test]
    procedure DovrebbeTenereIlPeriodoFinoAllUltimoRiferimento;
    [Test]
    procedure DovrebbeRifiutareUnSistemaNil;
    [Test]
    procedure DovrebbeRifiutareUnPeriodoNonPositivo;
    [Test]
    procedure LaFabbricaDovrebbeUsareIlSistemaDato;
    [Test]
    procedure IlTimerDiWindowsDovrebbeDareEResituireUnMillisecondo;
    [Test]
    procedure LaFabbricaDiWindowsDovrebbeDareUnaConcessione;
  end;

implementation

{ TFakeTimerSystem }

constructor TFakeTimerSystem.Create;
begin
  inherited Create;
  Grant := True;
end;

function TFakeTimerSystem.BeginPeriod(AMilliseconds: Integer): Boolean;
begin
  Began := Began + [AMilliseconds];
  Result := Grant;
end;

procedure TFakeTimerSystem.EndPeriod(AMilliseconds: Integer);
begin
  Ended := Ended + [AMilliseconds];
end;

{ TTestClockTimerResolution }

procedure TTestClockTimerResolution.DovrebbeChiedereIlPeriodoQuandoNasce;
var
  LSystem: TFakeTimerSystem;
  LKeeper: ITimerResolutionSystem;
  LLease: ITimerResolutionLease;
begin
  LSystem := TFakeTimerSystem.Create;
  LKeeper := LSystem;
  LLease := TTimerResolutionLease.Create(LKeeper, 1);
  Assert.AreEqual<Integer>(1, Length(LSystem.Began));
  Assert.AreEqual(1, LSystem.Began[0]);
  Assert.IsTrue(LLease.IsGranted);
  Assert.AreEqual(1, LLease.Milliseconds);
  Assert.AreEqual<Integer>(0, Length(LSystem.Ended));
end;

procedure TTestClockTimerResolution.DovrebbeRestituireIlPeriodoUnaSolaVoltaQuandoSiRilascia;
var
  LSystem: TFakeTimerSystem;
  LKeeper: ITimerResolutionSystem;
  LLease: ITimerResolutionLease;
begin
  LSystem := TFakeTimerSystem.Create;
  LKeeper := LSystem;
  LLease := TTimerResolutionLease.Create(LKeeper, 2);
  LLease := nil;
  Assert.AreEqual<Integer>(1, Length(LSystem.Ended));
  Assert.AreEqual(2, LSystem.Ended[0]);
end;

procedure TTestClockTimerResolution.NonDovrebbeRestituireUnPeriodoRifiutato;
var
  LSystem: TFakeTimerSystem;
  LKeeper: ITimerResolutionSystem;
  LLease: ITimerResolutionLease;
begin
  LSystem := TFakeTimerSystem.Create;
  LKeeper := LSystem;
  LSystem.Grant := False;
  LLease := TTimerResolutionLease.Create(LKeeper, 1);
  Assert.IsFalse(LLease.IsGranted);
  LLease := nil;
  Assert.AreEqual<Integer>(0, Length(LSystem.Ended));
end;

procedure TTestClockTimerResolution.DovrebbeTenereIlPeriodoFinoAllUltimoRiferimento;
var
  LSystem: TFakeTimerSystem;
  LKeeper: ITimerResolutionSystem;
  LFirst: ITimerResolutionLease;
  LSecond: ITimerResolutionLease;
begin
  LSystem := TFakeTimerSystem.Create;
  LKeeper := LSystem;
  LFirst := TTimerResolutionLease.Create(LKeeper, 1);
  LSecond := LFirst;
  LFirst := nil;
  Assert.AreEqual<Integer>(0, Length(LSystem.Ended));
  LSecond := nil;
  Assert.AreEqual<Integer>(1, Length(LSystem.Ended));
end;

procedure TTestClockTimerResolution.DovrebbeRifiutareUnSistemaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTimerResolutionLease.Create(nil, 1).Free;
    end, EArgumentNilException);
end;

procedure TTestClockTimerResolution.DovrebbeRifiutareUnPeriodoNonPositivo;
var
  LKeeper: ITimerResolutionSystem;
begin
  LKeeper := TFakeTimerSystem.Create;
  Assert.WillRaise(
    procedure
    begin
      TTimerResolutionLease.Create(LKeeper, 0).Free;
    end, EArgumentOutOfRangeException);
end;

procedure TTestClockTimerResolution.LaFabbricaDovrebbeUsareIlSistemaDato;
var
  LSystem: TFakeTimerSystem;
  LKeeper: ITimerResolutionSystem;
  LLease: ITimerResolutionLease;
begin
  LSystem := TFakeTimerSystem.Create;
  LKeeper := LSystem;
  LLease := TClockFactory.AcquireTimerResolution(LKeeper, 3);
  Assert.AreEqual(3, LSystem.Began[0]);
  LLease := nil;
  Assert.AreEqual(3, LSystem.Ended[0]);
end;

procedure TTestClockTimerResolution.IlTimerDiWindowsDovrebbeDareEResituireUnMillisecondo;
var
  LSystem: ITimerResolutionSystem;
begin
  LSystem := TWindowsTimerResolutionSystem.Create;
  Assert.IsTrue(LSystem.BeginPeriod(1));
  LSystem.EndPeriod(1);
end;

procedure TTestClockTimerResolution.LaFabbricaDiWindowsDovrebbeDareUnaConcessione;
var
  LLease: ITimerResolutionLease;
begin
  LLease := TClockFactory.AcquireTimerResolution(1);
  Assert.IsTrue(LLease.IsGranted);
  Assert.AreEqual(1, LLease.Milliseconds);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestClockTimerResolution);

end.
