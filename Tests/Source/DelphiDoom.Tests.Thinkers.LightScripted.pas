{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the lights of the scripted specials                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightScripted;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Light.Types,
  DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightScripted = class(TObject)
  private
    FWorld: TFakeLightWorld;
    function Arguments(AArg1, AArg2, AArg3, AArg4: Integer): TLightArguments;
    function SpawnInstant(AKind: TLightKind; ALevel, AArg1: Integer): Integer;
    procedure CheckSameAsOldCode(AKind: TLightKind; ALevel, AArg1, AArg2, AArg3, AArg4: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAlzareIlLivelloFinoA255;
    [Test]
    procedure DovrebbeAbbassareIlLivelloFinoA0;
    [Test]
    procedure DovrebbeCambiareIlLivelloSubito;
    [Test]
    procedure DovrebbeDareIlPiuAltoDeiViciniCheEIlLivelloDelSettore;
    [Test]
    procedure DovrebbeDareIlPiuBassoDeiVicini;
    [Test]
    procedure DovrebbeDareFalsoPerUnTipoSconosciuto;
    [Test]
    procedure DovrebbePrendereIValoriDiUnaDissolvenzaVersoIlBuio;
    [Test]
    procedure DovrebbePrendereIValoriDiUnaDissolvenzaVersoLaLuce;
    [Test]
    procedure DovrebbeUsareUnNumeroCasualeNelLampeggio;
    [Test]
    procedure DovrebbePrendereIValoriDelLampeggioRegolare;
    [Test]
    procedure DovrebbeUsareIlMinimoZeroSeStroboDoomHaViciniUguali;
    [Test]
    procedure DovrebbeTerminareLaDissolvenzaQuandoRaggiungeIlLivello;
    [Test]
    procedure DovrebbeAspettareFinoAllaFineDelConteggio;
    [Test]
    procedure DovrebbeNonFareNullaNelTicDiUnTipoIstantaneo;
    [Test]
    procedure DovrebbeDareGliStessiLivelliDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Scripted, DelphiDoom.Tests.Thinkers.OldLights;

{ TTestThinkersLightScripted }

procedure TTestThinkersLightScripted.Setup;
begin
  FWorld := TFakeLightWorld.Create;
end;

procedure TTestThinkersLightScripted.TearDown;
begin
  FreeAndNil(FWorld);
end;

function TTestThinkersLightScripted.Arguments(AArg1, AArg2, AArg3, AArg4: Integer): TLightArguments;
begin
  Result.Arg1 := AArg1;
  Result.Arg2 := AArg2;
  Result.Arg3 := AArg3;
  Result.Arg4 := AArg4;
end;

function TTestThinkersLightScripted.SpawnInstant(AKind: TLightKind; ALevel, AArg1: Integer): Integer;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
begin
  LSector := FWorld.AddWithNeighbors(ALevel, [90, 140]);
  Assert.AreEqual(Ord(TLightScriptedOutcome.Instant),
    Ord(TLightScripted.Spawn(AKind, LSector, Arguments(AArg1, 0, 0, 0), CreateTestRandom(0), LState)));
  Result := LSector.Level;
end;

procedure TTestThinkersLightScripted.DovrebbeAlzareIlLivelloFinoA255;
begin
  Assert.AreEqual(180, SpawnInstant(TLightKind.RaiseByValue, 160, 20));
  Assert.AreEqual(255, SpawnInstant(TLightKind.RaiseByValue, 250, 20));
end;

procedure TTestThinkersLightScripted.DovrebbeAbbassareIlLivelloFinoA0;
begin
  Assert.AreEqual(140, SpawnInstant(TLightKind.LowerByValue, 160, 20));
  Assert.AreEqual(0, SpawnInstant(TLightKind.LowerByValue, 10, 20));
end;

procedure TTestThinkersLightScripted.DovrebbeCambiareIlLivelloSubito;
begin
  Assert.AreEqual(77, SpawnInstant(TLightKind.ChangeToValue, 160, 77));
end;

procedure TTestThinkersLightScripted.DovrebbeDareIlPiuAltoDeiViciniCheEIlLivelloDelSettore;
begin
  // the old search never found a higher neighbor (see TLightNeighbors.HighestOrOwn)
  Assert.AreEqual(160, SpawnInstant(TLightKind.MaxNeighbor, 160, 0));
end;

procedure TTestThinkersLightScripted.DovrebbeDareIlPiuBassoDeiVicini;
begin
  Assert.AreEqual(90, SpawnInstant(TLightKind.MinNeighbor, 160, 0));
end;

procedure TTestThinkersLightScripted.DovrebbeDareFalsoPerUnTipoSconosciuto;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
begin
  LSector := FWorld.AddWithNeighbors(160, [90]);
  Assert.AreEqual(Ord(TLightScriptedOutcome.Invalid),
    Ord(TLightScripted.Spawn(TLightKind(99), LSector, Arguments(1, 2, 3, 4), CreateTestRandom(0), LState)));
  Assert.AreEqual(160, Integer(LSector.Level), 'nothing was touched');
end;

procedure TTestThinkersLightScripted.DovrebbePrendereIValoriDiUnaDissolvenzaVersoIlBuio;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
begin
  LSector := FWorld.AddWithNeighbors(200, []);
  Assert.AreEqual(Ord(TLightScriptedOutcome.Thinker),
    Ord(TLightScripted.Spawn(TLightKind.Fade, LSector, Arguments(100, 10, 0, 0), CreateTestRandom(0), LState)));
  Assert.AreEqual(100, LState.Value1, 'destination');
  Assert.AreEqual(-1, LState.Tics2, 'darker');
  Assert.IsTrue(LState.Value2 < 0, 'negative step');
end;

procedure TTestThinkersLightScripted.DovrebbePrendereIValoriDiUnaDissolvenzaVersoLaLuce;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
begin
  LSector := FWorld.AddWithNeighbors(100, []);
  TLightScripted.Spawn(TLightKind.Fade, LSector, Arguments(200, 10, 0, 0), CreateTestRandom(0), LState);
  Assert.AreEqual(1, LState.Tics2, 'brighter');
  Assert.IsTrue(LState.Value2 > 0, 'positive step');
end;

procedure TTestThinkersLightScripted.DovrebbeUsareUnNumeroCasualeNelLampeggio;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
  LRandom: IGameRandom;
begin
  LSector := FWorld.AddWithNeighbors(100, []);
  LRandom := CreateTestRandom(3);
  TLightScripted.Spawn(TLightKind.Flicker, LSector, Arguments(200, 50, 0, 0), LRandom, LState);
  Assert.AreEqual(4, LRandom.PlayIndex);
  Assert.AreEqual(200, Integer(LSector.Level), 'starts at the upper level');
  Assert.IsTrue((LState.Count = 1) or (LState.Count = 65), 'count ' + IntToStr(LState.Count));
end;

procedure TTestThinkersLightScripted.DovrebbePrendereIValoriDelLampeggioRegolare;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
begin
  LSector := FWorld.AddWithNeighbors(100, []);
  TLightScripted.Spawn(TLightKind.Strobe, LSector, Arguments(200, 50, 7, 9), CreateTestRandom(0), LState);
  Assert.AreEqual(200, LState.Value1);
  Assert.AreEqual(50, LState.Value2);
  Assert.AreEqual(7, LState.Tics1);
  Assert.AreEqual(9, LState.Tics2);
  Assert.AreEqual(7, LState.Count);
  Assert.AreEqual(200, Integer(LSector.Level));
end;

procedure TTestThinkersLightScripted.DovrebbeUsareIlMinimoZeroSeStroboDoomHaViciniUguali;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
begin
  LSector := FWorld.AddWithNeighbors(100, [100]);
  TLightScripted.Spawn(TLightKind.StrobeDoom, LSector, Arguments(5, 6, 0, 0), CreateTestRandom(0), LState);
  Assert.AreEqual(100, LState.Value1);
  Assert.AreEqual(0, LState.Value2);
  Assert.AreEqual(5, LState.Count);
end;

procedure TTestThinkersLightScripted.DovrebbeTerminareLaDissolvenzaQuandoRaggiungeIlLivello;
var
  LSector: TFakeLightSector;
  LState: TLightScriptedState;
  LRandom: IGameRandom;
  LTic: Integer;
  LFinished: Boolean;
begin
  LSector := FWorld.AddWithNeighbors(100, []);
  LRandom := CreateTestRandom(0);
  TLightScripted.Spawn(TLightKind.Fade, LSector, Arguments(150, 10, 0, 0), LRandom, LState);
  LFinished := False;
  for LTic := 1 to 100 do
    if not LFinished then
      LFinished := TLightScripted.Tick(TLightKind.Fade, LState.Value1, LState.Value2, LState.Tics1,
        LState.Tics2, LState.Count, LSector.Level, LRandom);
  Assert.IsTrue(LFinished, 'finished');
  Assert.AreEqual(150, Integer(LSector.Level));
end;

procedure TTestThinkersLightScripted.DovrebbeAspettareFinoAllaFineDelConteggio;
var
  LLevel: SmallInt;
  LTics1, LTics2, LCount: Integer;
begin
  LLevel := 100;
  LTics1 := 3;
  LTics2 := 4;
  LCount := 2;
  Assert.IsFalse(TLightScripted.Tick(TLightKind.Strobe, 200, 50, LTics1, LTics2, LCount, LLevel,
    CreateTestRandom(0)));
  Assert.AreEqual(1, LCount);
  Assert.AreEqual(100, Integer(LLevel));
end;

procedure TTestThinkersLightScripted.DovrebbeNonFareNullaNelTicDiUnTipoIstantaneo;
var
  LLevel: SmallInt;
  LTics1, LTics2, LCount: Integer;
begin
  LLevel := 100;
  LTics1 := 0;
  LTics2 := 0;
  LCount := 0;
  Assert.IsFalse(TLightScripted.Tick(TLightKind.RaiseByValue, 200, 50, LTics1, LTics2, LCount, LLevel,
    CreateTestRandom(0)));
  Assert.AreEqual(100, Integer(LLevel));
end;

procedure TTestThinkersLightScripted.CheckSameAsOldCode(AKind: TLightKind; ALevel, AArg1, AArg2, AArg3,
  AArg4: Integer);
var
  LSeed, LTic: Integer;
  LOldSector, LNewSector: TFakeLightSector;
  LOld: TOldScripted;
  LState: TLightScriptedState;
  LThink: Boolean;
  LOldResult: Boolean;
  LOutcome: TLightScriptedOutcome;
  LOldRandom, LNewRandom: IGameRandom;
  LNewRemoved: Boolean;
  LWasRemoved: Boolean;
  LName: string;
begin
  LName := Format('kind %d level %d args %d,%d,%d,%d', [Ord(AKind), ALevel, AArg1, AArg2, AArg3, AArg4]);
  for LSeed := 0 to 3 do
  begin
    LOldSector := FWorld.AddWithNeighbors(ALevel, [70, NO_NEIGHBOR, 150]);
    LNewSector := FWorld.AddWithNeighbors(ALevel, [70, NO_NEIGHBOR, 150]);
    LOldRandom := CreateTestRandom(LSeed * 47);
    LNewRandom := CreateTestRandom(LSeed * 47);
    // the old code leaves some fields as they are: a stack record is not zeroed in 64 bit
    FillChar(LOld, SizeOf(LOld), 0);
    LOldResult := OldSpawnScripted(LOld, LOldSector, Ord(AKind), AArg1, AArg2, AArg3, AArg4, LOldRandom, LThink);
    LOutcome := TLightScripted.Spawn(AKind, LNewSector, Arguments(AArg1, AArg2, AArg3, AArg4), LNewRandom,
      LState);
    Assert.AreEqual(LOldResult, LOutcome <> TLightScriptedOutcome.Invalid, 'result ' + LName);
    Assert.AreEqual(LThink, LOutcome = TLightScriptedOutcome.Thinker, 'thinker ' + LName);
    Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level), 'level after spawn ' + LName);
    Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, 'random after spawn ' + LName);
    if not LThink then
      Continue;

    Assert.AreEqual(LOld.Value1, LState.Value1, 'value1 ' + LName);
    Assert.AreEqual(LOld.Value2, LState.Value2, 'value2 ' + LName);
    Assert.AreEqual(LOld.Tics1, LState.Tics1, 'tics1 ' + LName);
    Assert.AreEqual(LOld.Tics2, LState.Tics2, 'tics2 ' + LName);
    Assert.AreEqual(LOld.Count, LState.Count, 'count ' + LName);

    for LTic := 1 to 3000 do
    begin
      // a removed light does not run any more, in the old code and in the new one alike
      LWasRemoved := LOld.Removed;
      if not LWasRemoved then
        OldTickScripted(LOld, LOldRandom);
      LNewRemoved := LWasRemoved;
      if not LWasRemoved then
        LNewRemoved := TLightScripted.Tick(AKind, LState.Value1, LState.Value2, LState.Tics1, LState.Tics2,
          LState.Count, LNewSector.Level, LNewRandom);
      Assert.AreEqual(LOld.Removed, LNewRemoved, Format('removed at tic %d, %s', [LTic, LName]));
      Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level),
        Format('level at tic %d, %s', [LTic, LName]));
      Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, Format('random at tic %d, %s', [LTic, LName]));
    end;
  end;
end;

procedure TTestThinkersLightScripted.DovrebbeDareGliStessiLivelliDelVecchioCodice;
var
  LKind: TLightKind;
begin
  for LKind := Low(TLightKind) to High(TLightKind) do
  begin
    CheckSameAsOldCode(LKind, 160, 20, 0, 0, 0);
    CheckSameAsOldCode(LKind, 240, 200, 30, 12, 9);
    CheckSameAsOldCode(LKind, 30, 90, 40, 25, 7);
    CheckSameAsOldCode(LKind, 120, 250, 100, 3, 4);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightScripted);

end.
