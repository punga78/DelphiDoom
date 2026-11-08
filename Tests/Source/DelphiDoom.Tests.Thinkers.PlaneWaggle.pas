{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the waggling floor (Hexen)                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlaneWaggle;

// The accumulator and the heights of the random cases wrap as they did in the old code
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Plane.Types,
  DelphiDoom.Thinkers.Plane.Intf, DelphiDoom.Tests.Thinkers.OldPlanes,
  DelphiDoom.Tests.Thinkers.PlaneFakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersPlaneWaggle = class(TObject)
  strict private
    FHost: TFakePlaneHost;
    FHostIntf: IPlaneSectorHost;
    FBob: TArray<Integer>;
    FSector: sector_t;
    function MakeState(AState, AScale, ATargetScale, AScaleDelta, ATicker: Integer): TPlaneWaggleState;
    function Tick(var AState: TPlaneWaggleState): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFarCrescereLaScalaFinoAlBersaglio;
    [Test]
    procedure DovrebbeCalcolareLAltezzaDelPavimentoDallaTabella;
    [Test]
    procedure DovrebbeRestareStabileSenzaTempoLimite;
    [Test]
    procedure DovrebbeIniziareARidurreQuandoIlTempoNonEFinito;
    [Test]
    procedure DovrebbeRestareStabileQuandoIlTempoArrivaAZero;
    [Test]
    procedure DovrebbeFinireQuandoLaScalaArrivaAZero;
    [Test]
    procedure DovrebbeContinuareFinoAllaFineDellaRiduzione;
    [Test]
    procedure DovrebbeChiedereAlHostConIlFlagDiSchiacciamento;
    [Test]
    procedure DovrebbeDareUnErroreConUnaTabellaTroppoCorta;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelVecchioCodiceTicPerTic;
  end;

implementation

uses
  DelphiDoom.Thinkers.Plane.Waggle;

{ TTestThinkersPlaneWaggle }

procedure TTestThinkersPlaneWaggle.Setup;
var
  LIndex: Integer;
begin
  FHost := TFakePlaneHost.Create(0);
  FHostIntf := FHost;
  SetLength(FBob, PLANE_BOB_TABLE_SIZE);
  for LIndex := 0 to PLANE_BOB_TABLE_SIZE - 1 do
  begin
    FBob[LIndex] := (LIndex - 32) * 3000 + (LIndex mod 7) * 111;
    OldBobOffsets[LIndex] := FBob[LIndex];
  end;
  FSector.floorheight := 1000;
  FSector.ceilingheight := 5000;
end;

procedure TTestThinkersPlaneWaggle.TearDown;
begin
  OldPlaneHost := nil;
  FHostIntf := nil;
  FHost := nil;
end;

function TTestThinkersPlaneWaggle.MakeState(AState, AScale, ATargetScale, AScaleDelta,
  ATicker: Integer): TPlaneWaggleState;
begin
  Result.OriginalHeight := 1000;
  Result.Accumulator := 0;
  Result.AccDelta := 65536;
  Result.TargetScale := ATargetScale;
  Result.Scale := AScale;
  Result.ScaleDelta := AScaleDelta;
  Result.Ticker := ATicker;
  Result.State := AState;
end;

function TTestThinkersPlaneWaggle.Tick(var AState: TPlaneWaggleState): Boolean;
begin
  Result := TPlaneWaggle.Tick(AState, FSector.floorheight, FBob, FHostIntf, @FSector);
end;

procedure TTestThinkersPlaneWaggle.DovrebbeFarCrescereLaScalaFinoAlBersaglio;
var
  LState: TPlaneWaggleState;
begin
  LState := MakeState(PLANE_WAGGLE_EXPAND, 0, 250, 100, -1);
  Assert.IsFalse(Tick(LState), 'first tic');
  Assert.AreEqual(100, LState.Scale, 'scale 1');
  Assert.AreEqual(PLANE_WAGGLE_EXPAND, LState.State, 'state 1');
  Tick(LState);
  Assert.AreEqual(200, LState.Scale, 'scale 2');
  Assert.AreEqual(PLANE_WAGGLE_EXPAND, LState.State, 'state 2');
  Tick(LState);
  Assert.AreEqual(250, LState.Scale, 'scale stops at the target');
  Assert.AreEqual(PLANE_WAGGLE_STABLE, LState.State, 'state 3');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeCalcolareLAltezzaDelPavimentoDallaTabella;
var
  LState: TPlaneWaggleState;
begin
  // the accumulator moves by one entry of the table at every tic and the scale is 1.0
  LState := MakeState(PLANE_WAGGLE_STABLE, 65536, 65536, 0, -1);
  Tick(LState);
  Assert.AreEqual(65536, LState.Accumulator, 'accumulator');
  Assert.AreEqual(1000 + FBob[1], FSector.floorheight, 'floor at entry 1');
  Tick(LState);
  Assert.AreEqual(1000 + FBob[2], FSector.floorheight, 'floor at entry 2');
  LState.Accumulator := 63 * 65536;
  Tick(LState);
  Assert.AreEqual(1000 + FBob[0], FSector.floorheight, 'the table starts again after 64 entries');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeRestareStabileSenzaTempoLimite;
var
  LState: TPlaneWaggleState;
  LTic: Integer;
begin
  LState := MakeState(PLANE_WAGGLE_STABLE, 65536, 65536, 0, -1);
  for LTic := 1 to 1000 do
    Assert.IsFalse(Tick(LState), 'tic');
  Assert.AreEqual(PLANE_WAGGLE_STABLE, LState.State, 'state');
  Assert.AreEqual(-1, LState.Ticker, 'ticker');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeIniziareARidurreQuandoIlTempoNonEFinito;
var
  LState: TPlaneWaggleState;
begin
  // as the old code: any ticker that is not 0 after the decrement starts the reduction
  LState := MakeState(PLANE_WAGGLE_STABLE, 65536, 65536, 0, 5);
  Tick(LState);
  Assert.AreEqual(4, LState.Ticker, 'ticker');
  Assert.AreEqual(PLANE_WAGGLE_REDUCE, LState.State, 'state');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeRestareStabileQuandoIlTempoArrivaAZero;
var
  LState: TPlaneWaggleState;
begin
  LState := MakeState(PLANE_WAGGLE_STABLE, 65536, 65536, 0, 1);
  Tick(LState);
  Assert.AreEqual(0, LState.Ticker, 'ticker');
  Assert.AreEqual(PLANE_WAGGLE_STABLE, LState.State, 'state');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeFinireQuandoLaScalaArrivaAZero;
var
  LState: TPlaneWaggleState;
begin
  LState := MakeState(PLANE_WAGGLE_REDUCE, 100, 65536, 100, 5);
  FSector.floorheight := 1234;
  Assert.IsTrue(Tick(LState), 'ended');
  Assert.AreEqual(0, LState.Scale, 'scale');
  Assert.AreEqual(1000, FSector.floorheight, 'the floor is back at the original height');
  Assert.AreEqual(0, LState.Accumulator, 'the accumulator is not moved when it ends');
  Assert.AreEqual(1, FHost.ChangeCount, 'the sector is changed once');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeContinuareFinoAllaFineDellaRiduzione;
var
  LState: TPlaneWaggleState;
begin
  LState := MakeState(PLANE_WAGGLE_REDUCE, 300, 65536, 100, 5);
  Assert.IsFalse(Tick(LState), 'first');
  Assert.AreEqual(200, LState.Scale, 'scale 1');
  Assert.IsFalse(Tick(LState), 'second');
  Assert.AreEqual(100, LState.Scale, 'scale 2');
  Assert.IsTrue(Tick(LState), 'third');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeChiedereAlHostConIlFlagDiSchiacciamento;
var
  LState: TPlaneWaggleState;
begin
  LState := MakeState(PLANE_WAGGLE_STABLE, 65536, 65536, 0, -1);
  Tick(LState);
  Assert.AreEqual(1, FHost.ChangeCount, 'changes');
  Assert.AreEqual(0, FHost.MovedCount, 'a waggle does not update the slopes');
  Assert.IsTrue(FHost.LastSector = @FSector, 'sector');
  Assert.IsTrue(Pos('/1>', FHost.Log) > 0, 'the crush flag is set');
end;

procedure TTestThinkersPlaneWaggle.DovrebbeDareUnErroreConUnaTabellaTroppoCorta;
var
  LState: TPlaneWaggleState;
  LShort: TArray<Integer>;
begin
  LState := MakeState(PLANE_WAGGLE_STABLE, 65536, 65536, 0, -1);
  SetLength(LShort, PLANE_BOB_TABLE_SIZE - 1);
  Assert.WillRaise(
    procedure
    begin
      TPlaneWaggle.Tick(LState, FSector.floorheight, LShort, FHostIntf, @FSector);
    end,
    EPlaneException);
end;

procedure TTestThinkersPlaneWaggle.DovrebbeDareGliStessiValoriDelVecchioCodiceTicPerTic;
var
  LSeed, LTic: Integer;
  LRandom: Cardinal;
  LOldHost, LNewHost: TFakePlaneHost;
  LOldIntf, LNewIntf: IPlaneSectorHost;
  LOldSector, LNewSector: sector_t;
  LOld: TOldWaggle;
  LNew: TPlaneWaggleState;
  LFinished: Boolean;
  LText: string;
begin
  LOldHost := TFakePlaneHost.Create(0);
  LOldIntf := LOldHost;
  LNewHost := TFakePlaneHost.Create(0);
  LNewIntf := LNewHost;
  OldPlaneHost := LOldIntf;
  try
    for LSeed := 1 to 60 do
    begin
      LRandom := Cardinal(LSeed * 7919);
      LOldSector.floorheight := TestNumberIn(LRandom, -100000, 100000);
      LOldSector.ceilingheight := LOldSector.floorheight + 100000;
      LNewSector := LOldSector;
      LOld.sector := @LOldSector;
      LOld.originalHeight := LOldSector.floorheight;
      LOld.accumulator := TestNumberIn(LRandom, 0, 64 * 65536);
      LOld.accDelta := TestNumberIn(LRandom, -5 * 65536, 5 * 65536);
      LOld.targetScale := TestNumberIn(LRandom, 0, 20 * 65536);
      LOld.scale := TestNumberIn(LRandom, 0, LOld.targetScale + 1000);
      LOld.scaleDelta := TestNumberIn(LRandom, 1, 3 * 65536);
      if TestNumberIn(LRandom, 0, 2) = 0 then
        LOld.ticker := -1
      else
        LOld.ticker := TestNumberIn(LRandom, 0, 70);
      LOld.state := TestNumberIn(LRandom, 0, 3);
      LOld.removed := False;

      LNew.OriginalHeight := LOld.originalHeight;
      LNew.Accumulator := LOld.accumulator;
      LNew.AccDelta := LOld.accDelta;
      LNew.TargetScale := LOld.targetScale;
      LNew.Scale := LOld.scale;
      LNew.ScaleDelta := LOld.scaleDelta;
      LNew.Ticker := LOld.ticker;
      LNew.State := LOld.state;

      for LTic := 1 to 600 do
      begin
        LOldHost.Clear;
        LNewHost.Clear;
        OldFloorWaggle(@LOld);
        LFinished := TPlaneWaggle.Tick(LNew, LNewSector.floorheight, FBob, LNewIntf, @LNewSector);
        LText := Format('seed %d tic %d', [LSeed, LTic]);
        Assert.AreEqual(LOld.removed, LFinished, 'end at ' + LText);
        Assert.AreEqual(LOldSector.floorheight, LNewSector.floorheight, 'floor at ' + LText);
        Assert.AreEqual(LOld.accumulator, LNew.Accumulator, 'accumulator at ' + LText);
        Assert.AreEqual(LOld.scale, LNew.Scale, 'scale at ' + LText);
        Assert.AreEqual(LOld.ticker, LNew.Ticker, 'ticker at ' + LText);
        Assert.AreEqual(LOld.state, LNew.State, 'state at ' + LText);
        Assert.AreEqual(LOldHost.Log, LNewHost.Log, 'calls at ' + LText);
        if LFinished then
          Break;
      end;
    end;
  finally
    OldPlaneHost := nil;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersPlaneWaggle);

end.
