{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the classic ceilings (T_MoveCeiling, EV_DoCeiling)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.CeilingMachine;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.Plane.Types,
  DelphiDoom.Thinkers.Plane.Intf, DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Ceiling.Types, DelphiDoom.Tests.Thinkers.OldCeilings,
  DelphiDoom.Tests.Thinkers.OldCeilingsHeretic, DelphiDoom.Tests.Thinkers.PlaneFakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersCeilingMachine = class(TObject)
  strict private
    FHost: TFakePlaneHost;
    FHostIntf: IPlaneSectorHost;
    FNewLog: string;
    function State(ADirection, ASpeed, AOldSpeed: Integer): TCeilingState;
    /// <summary>T_MoveCeiling as IdTech1\Base\p_ceilng.pas writes it now, on the records of the test</summary>
    procedure NewMoveCeiling(ACeiling: Pceiling_t; AKind: TCeilingKind; AMoveSound: Integer);
    /// <summary>The body of the loop of EV_DoCeiling as IdTech1\Base\p_ceilng.pas writes it now</summary>
    procedure NewSpawnCeiling(ACeiling: Pceiling_t; ASector: Psector_t; AKind: TCeilingKind;
      const AProfile: TCeilingProfile);
    procedure RandomCeiling(var AState: Cardinal; out ASector: sector_t; out ACeiling: ceiling_t);
    procedure CheckSame(const AOld, ANew: ceiling_t; const AOldSector, ANewSector: sector_t;
      const AText: string);
    procedure CheckGameParity(AGame: TPlatGame; ASeed: Cardinal);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNonFareNullaInStasi;
    [Test]
    procedure DovrebbeSuonareSoloNeiTicDelSuono;
    [Test]
    procedure DovrebbeTacereConISchiacciatoriSilenziosi;
    [Test]
    procedure DovrebbeRimuovereIlSoffittoArrivatoInCima;
    [Test]
    procedure DovrebbeInvertireLoSchiacciatoreArrivatoInCima;
    [Test]
    procedure DovrebbeRimuovereIlSoffittoArrivatoInFondo;
    [Test]
    procedure DovrebbeFarRisalireLoSchiacciatoreConLaVelocitaNormale;
    [Test]
    procedure DovrebbeLasciareLaVelocitaDelloSchiacciatoreRapido;
    [Test]
    procedure DovrebbeSuonareLoStopDelloSchiacciatoreSilenzioso;
    [Test]
    procedure DovrebbeRallentareLoSchiacciatoreSuUnOstacolo;
    [Test]
    procedure DovrebbeNonRallentareSalendo;
    [Test]
    procedure DovrebbeRallentareIlGeneralizzatoSoloSeLento;
    [Test]
    procedure DovrebbeRidareLaVelocitaAlGeneralizzatoLentoInFondo;
    [Test]
    procedure DovrebbeCambiareTextureESpecialConICambiatori;
    [Test]
    procedure DovrebbeLasciareLoSpecialConIlCambiatoreSemplice;
    [Test]
    procedure DovrebbeNonFareAltroConUnGenereSconosciuto;
    [Test]
    procedure DovrebbeConfigurareLoSchiacciatoreRapidoSecondoIlGioco;
    [Test]
    procedure DovrebbeConfigurareAbbassaESchiacciaSecondoIlGioco;
    [Test]
    procedure DovrebbeNonSchiacciareConGliSchiacciatoriDiStrife;
    [Test]
    procedure DovrebbeChiedereLeAltezzeAttornoAlSettore;
    [Test]
    procedure DovrebbeLasciareICampiCheIlGenereNonScrive;
    [Test]
    procedure DovrebbeRisvegliareSoloConGliSchiacciatoriCheRisalgono;
    [Test]
    procedure DovrebbeDareIlProfiloDiOgniGioco;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiStrife;
    [Test]
    procedure DovrebbeSeguireIlVecchioCodiceDiHeretic;
  end;

implementation

uses
  DelphiDoom.Thinkers.Plane.Rules, DelphiDoom.Thinkers.Ceiling.Games,
  DelphiDoom.Thinkers.Ceiling.Machine;

const
  THING_HEIGHT = 24 * FRACUNIT;
  DOOM_KINDS: array[0..15] of TCeilingKind = (
    TCeilingKind.LowerToFloor, TCeilingKind.RaiseToHighest, TCeilingKind.LowerToLowest,
    TCeilingKind.LowerToMaxFloor, TCeilingKind.LowerAndCrush, TCeilingKind.CrushAndRaise,
    TCeilingKind.FastCrushAndRaise, TCeilingKind.SilentCrushAndRaise, TCeilingKind.GenCeiling,
    TCeilingKind.GenCeilingChg, TCeilingKind.GenCeilingChg0, TCeilingKind.GenCeilingChgT,
    TCeilingKind.GenCrusher, TCeilingKind.GenSilentCrusher, TCeilingKind.Other,
    TCeilingKind.Other);
  HERETIC_KINDS: array[0..6] of TCeilingKind = (
    TCeilingKind.LowerToFloor, TCeilingKind.RaiseToHighest, TCeilingKind.LowerAndCrush,
    TCeilingKind.CrushAndRaise, TCeilingKind.FastCrushAndRaise, TCeilingKind.Other,
    TCeilingKind.Other);

function ResultOf(AResult: result_e): TPlaneMoveResult;
begin
  case AResult of
    crushed:
      Result := TPlaneMoveResult.Crushed;
    pastdest:
      Result := TPlaneMoveResult.PastDest;
  else
    Result := TPlaneMoveResult.Ok;
  end;
end;

{ TTestThinkersCeilingMachine }

procedure TTestThinkersCeilingMachine.Setup;
begin
  FHost := TFakePlaneHost.Create(THING_HEIGHT);
  FHostIntf := FHost;
  OldCeilingHost := FHostIntf;
  OldCeilingRules := TPlaneRules.Doom(True);
  OldCeilingLevelTime := 0;
  OldCeilingLog := '';
  FNewLog := '';
end;

procedure TTestThinkersCeilingMachine.TearDown;
begin
  OldCeilingHost := nil;
  FHostIntf := nil;
  FHost := nil;
end;

function TTestThinkersCeilingMachine.State(ADirection, ASpeed, AOldSpeed: Integer): TCeilingState;
begin
  Result.Direction := ADirection;
  Result.Speed := ASpeed;
  Result.OldSpeed := AOldSpeed;
end;

procedure TTestThinkersCeilingMachine.NewMoveCeiling(ACeiling: Pceiling_t; AKind: TCeilingKind;
  AMoveSound: Integer);
var
  LResult: result_e;
  LState: TCeilingState;
  LActions: TCeilingActions;
begin
  case ACeiling.direction of
    1:
      LResult := OldCeilingMovePlane(ACeiling.sector, ACeiling.speed, ACeiling.topheight,
        False, 1, ACeiling.direction);
    -1:
      LResult := OldCeilingMovePlane(ACeiling.sector, ACeiling.speed, ACeiling.bottomheight,
        ACeiling.crush, 1, ACeiling.direction);
  else
    Exit;
  end;

  LState.Direction := ACeiling.direction;
  LState.Speed := ACeiling.speed;
  LState.OldSpeed := ACeiling.oldspeed;
  LActions := TCeilingMachine.AfterMove(AKind, LState, ResultOf(LResult),
    OldCeilingLevelTime and 7 = 0);
  ACeiling.direction := LState.Direction;
  ACeiling.speed := LState.Speed;

  if LActions = [] then
    Exit;
  if TCeilingAction.MoveSound in LActions then
    FNewLog := FNewLog + 'S' + IntToStr(AMoveSound) + ';';
  if TCeilingAction.TransferSpecial in LActions then
  begin
    ACeiling.sector.special := ACeiling.newspecial;
    ACeiling.sector.oldspecial := ACeiling.oldspecial;
  end;
  if TCeilingAction.ChangeTexture in LActions then
    ACeiling.sector.ceilingpic := ACeiling.texture;
  if TCeilingAction.StopSound in LActions then
    FNewLog := FNewLog + 'S' + IntToStr(sfx_pstop) + ';';
  if TCeilingAction.Remove in LActions then
    FNewLog := FNewLog + 'R;';
end;

procedure TTestThinkersCeilingMachine.NewSpawnCeiling(ACeiling: Pceiling_t; ASector: Psector_t;
  AKind: TCeilingKind; const AProfile: TCeilingProfile);
var
  LSpawn: TCeilingSpawn;
begin
  LSpawn.Crush := ACeiling.crush;
  LSpawn.TopHeight := ACeiling.topheight;
  LSpawn.BottomHeight := ACeiling.bottomheight;
  LSpawn.Direction := ACeiling.direction;
  LSpawn.Speed := ACeiling.speed;
  case TCeilingMachine.Configure(AKind, ASector.floorheight, ASector.ceilingheight, AProfile,
    LSpawn) of
    TCeilingNeighbor.TopHighestCeiling:
      LSpawn.TopHeight := OldHighestCeilingSurrounding;
    TCeilingNeighbor.BottomLowestCeiling:
      LSpawn.BottomHeight := OldLowestCeilingSurrounding;
    TCeilingNeighbor.BottomHighestFloor:
      LSpawn.BottomHeight := OldHighestFloorSurrounding;
  end;
  ACeiling.crush := LSpawn.Crush;
  ACeiling.topheight := LSpawn.TopHeight;
  ACeiling.bottomheight := LSpawn.BottomHeight;
  ACeiling.direction := LSpawn.Direction;
  ACeiling.speed := LSpawn.Speed;
end;

procedure TTestThinkersCeilingMachine.DovrebbeNonFareNullaInStasi;
var
  LState: TCeilingState;
begin
  LState := State(0, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.CrushAndRaise, LState,
    TPlaneMoveResult.PastDest, True) = [], 'no action');
  Assert.AreEqual(0, LState.Direction, 'direction');
  LState := State(2, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.RaiseToHighest, LState,
    TPlaneMoveResult.PastDest, True) = [], 'no action with a direction that is not one');
end;

procedure TTestThinkersCeilingMachine.DovrebbeSuonareSoloNeiTicDelSuono;
var
  LState: TCeilingState;
begin
  LState := State(-1, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.LowerToFloor, LState,
    TPlaneMoveResult.Ok, True) = [TCeilingAction.MoveSound], 'sound tic');
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.LowerToFloor, LState,
    TPlaneMoveResult.Ok, False) = [], 'other tics');
  LState := State(1, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.Other, LState,
    TPlaneMoveResult.Ok, True) = [TCeilingAction.MoveSound], 'going up');
end;

procedure TTestThinkersCeilingMachine.DovrebbeTacereConISchiacciatoriSilenziosi;
var
  LState: TCeilingState;
begin
  LState := State(-1, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.SilentCrushAndRaise, LState,
    TPlaneMoveResult.Ok, True) = [], 'silent');
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.GenSilentCrusher, LState,
    TPlaneMoveResult.Ok, True) = [], 'generalized silent');
  LState := State(1, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.GenSilentCrusher, LState,
    TPlaneMoveResult.Ok, True) = [], 'generalized silent going up');
end;

procedure TTestThinkersCeilingMachine.DovrebbeRimuovereIlSoffittoArrivatoInCima;
var
  LState: TCeilingState;
begin
  LState := State(1, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.RaiseToHighest, LState,
    TPlaneMoveResult.PastDest, False) = [TCeilingAction.Remove], 'raise to highest');
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.GenCeiling, LState,
    TPlaneMoveResult.PastDest, True) = [TCeilingAction.MoveSound, TCeilingAction.Remove],
    'generalized');
  // the ceilings that only go down are not removed at the top
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.LowerToFloor, LState,
    TPlaneMoveResult.PastDest, False) = [], 'lower to floor');
  Assert.AreEqual(1, LState.Direction, 'direction');
end;

procedure TTestThinkersCeilingMachine.DovrebbeInvertireLoSchiacciatoreArrivatoInCima;
var
  LState: TCeilingState;
  LKind: TCeilingKind;
begin
  for LKind in [TCeilingKind.CrushAndRaise, TCeilingKind.FastCrushAndRaise,
    TCeilingKind.GenCrusher, TCeilingKind.GenSilentCrusher] do
  begin
    LState := State(1, 3 * CEILING_SPEED, 7);
    Assert.IsTrue(TCeilingMachine.AfterMove(LKind, LState, TPlaneMoveResult.PastDest,
      False) = [], 'actions');
    Assert.AreEqual(-1, LState.Direction, 'direction');
    Assert.AreEqual(3 * CEILING_SPEED, LState.Speed, 'speed');
  end;
end;

procedure TTestThinkersCeilingMachine.DovrebbeRimuovereIlSoffittoArrivatoInFondo;
var
  LState: TCeilingState;
  LKind: TCeilingKind;
begin
  for LKind in [TCeilingKind.LowerAndCrush, TCeilingKind.LowerToFloor,
    TCeilingKind.LowerToLowest, TCeilingKind.LowerToMaxFloor, TCeilingKind.GenCeiling] do
  begin
    LState := State(-1, CEILING_SPEED, 0);
    Assert.IsTrue(TCeilingMachine.AfterMove(LKind, LState, TPlaneMoveResult.PastDest,
      False) = [TCeilingAction.Remove], 'actions');
    Assert.AreEqual(-1, LState.Direction, 'direction');
  end;
  LState := State(-1, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.RaiseToHighest, LState,
    TPlaneMoveResult.PastDest, False) = [], 'raise to highest is not removed at the bottom');
end;

procedure TTestThinkersCeilingMachine.DovrebbeFarRisalireLoSchiacciatoreConLaVelocitaNormale;
var
  LState: TCeilingState;
begin
  LState := State(-1, CEILING_SPEED div 8, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.CrushAndRaise, LState,
    TPlaneMoveResult.PastDest, False) = [], 'actions');
  Assert.AreEqual(1, LState.Direction, 'direction');
  Assert.AreEqual(CEILING_SPEED, LState.Speed, 'speed');
end;

procedure TTestThinkersCeilingMachine.DovrebbeLasciareLaVelocitaDelloSchiacciatoreRapido;
var
  LState: TCeilingState;
begin
  LState := State(-1, 4 * CEILING_SPEED, 0);
  TCeilingMachine.AfterMove(TCeilingKind.FastCrushAndRaise, LState, TPlaneMoveResult.PastDest,
    False);
  Assert.AreEqual(1, LState.Direction, 'direction');
  Assert.AreEqual(4 * CEILING_SPEED, LState.Speed, 'speed');
  // and an obstacle does not slow it
  LState := State(-1, 4 * CEILING_SPEED, 0);
  TCeilingMachine.AfterMove(TCeilingKind.FastCrushAndRaise, LState, TPlaneMoveResult.Crushed,
    False);
  Assert.AreEqual(4 * CEILING_SPEED, LState.Speed, 'speed on an obstacle');
end;

procedure TTestThinkersCeilingMachine.DovrebbeSuonareLoStopDelloSchiacciatoreSilenzioso;
var
  LState: TCeilingState;
begin
  LState := State(-1, CEILING_SPEED div 8, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.SilentCrushAndRaise, LState,
    TPlaneMoveResult.PastDest, True) = [TCeilingAction.StopSound], 'bottom');
  Assert.AreEqual(1, LState.Direction, 'direction at the bottom');
  Assert.AreEqual(CEILING_SPEED, LState.Speed, 'speed at the bottom');
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.SilentCrushAndRaise, LState,
    TPlaneMoveResult.PastDest, False) = [TCeilingAction.StopSound], 'top');
  Assert.AreEqual(-1, LState.Direction, 'direction at the top');
end;

procedure TTestThinkersCeilingMachine.DovrebbeRallentareLoSchiacciatoreSuUnOstacolo;
var
  LState: TCeilingState;
  LKind: TCeilingKind;
begin
  for LKind in [TCeilingKind.SilentCrushAndRaise, TCeilingKind.CrushAndRaise,
    TCeilingKind.LowerAndCrush] do
  begin
    LState := State(-1, CEILING_SPEED, 0);
    TCeilingMachine.AfterMove(LKind, LState, TPlaneMoveResult.Crushed, False);
    Assert.AreEqual(CEILING_SPEED div 8, LState.Speed, 'speed');
    Assert.AreEqual(-1, LState.Direction, 'direction');
  end;
  LState := State(-1, CEILING_SPEED, 0);
  TCeilingMachine.AfterMove(TCeilingKind.LowerToFloor, LState, TPlaneMoveResult.Crushed, False);
  Assert.AreEqual(CEILING_SPEED, LState.Speed, 'lower to floor keeps its speed');
end;

procedure TTestThinkersCeilingMachine.DovrebbeNonRallentareSalendo;
var
  LState: TCeilingState;
begin
  LState := State(1, CEILING_SPEED, 0);
  TCeilingMachine.AfterMove(TCeilingKind.CrushAndRaise, LState, TPlaneMoveResult.Crushed, False);
  Assert.AreEqual(CEILING_SPEED, LState.Speed, 'speed');
end;

procedure TTestThinkersCeilingMachine.DovrebbeRallentareIlGeneralizzatoSoloSeLento;
var
  LState: TCeilingState;
begin
  LState := State(-1, 2 * CEILING_SPEED, 2 * CEILING_SPEED);
  TCeilingMachine.AfterMove(TCeilingKind.GenCrusher, LState, TPlaneMoveResult.Crushed, False);
  Assert.AreEqual(CEILING_SPEED div 8, LState.Speed, 'slow crusher');
  LState := State(-1, 3 * CEILING_SPEED, 3 * CEILING_SPEED);
  TCeilingMachine.AfterMove(TCeilingKind.GenSilentCrusher, LState, TPlaneMoveResult.Crushed,
    False);
  Assert.AreEqual(3 * CEILING_SPEED, LState.Speed, 'fast crusher');
end;

procedure TTestThinkersCeilingMachine.DovrebbeRidareLaVelocitaAlGeneralizzatoLentoInFondo;
var
  LState: TCeilingState;
begin
  LState := State(-1, CEILING_SPEED div 8, 2 * CEILING_SPEED);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.GenCrusher, LState,
    TPlaneMoveResult.PastDest, False) = [], 'actions');
  Assert.AreEqual(2 * CEILING_SPEED, LState.Speed, 'slow: old speed');
  Assert.AreEqual(1, LState.Direction, 'direction');
  LState := State(-1, 5 * CEILING_SPEED, 3 * CEILING_SPEED);
  TCeilingMachine.AfterMove(TCeilingKind.GenSilentCrusher, LState, TPlaneMoveResult.PastDest,
    False);
  Assert.AreEqual(5 * CEILING_SPEED, LState.Speed, 'fast: untouched');
  Assert.AreEqual(1, LState.Direction, 'direction of the fast one');
end;

procedure TTestThinkersCeilingMachine.DovrebbeCambiareTextureESpecialConICambiatori;
var
  LState: TCeilingState;
  LDirection: Integer;
  LKind: TCeilingKind;
begin
  for LKind in [TCeilingKind.GenCeilingChg0, TCeilingKind.GenCeilingChgT] do
    for LDirection in [-1, 1] do
    begin
      LState := State(LDirection, CEILING_SPEED, 0);
      Assert.IsTrue(TCeilingMachine.AfterMove(LKind, LState, TPlaneMoveResult.PastDest,
        False) = [TCeilingAction.TransferSpecial, TCeilingAction.ChangeTexture,
        TCeilingAction.Remove], 'actions');
      Assert.AreEqual(LDirection, LState.Direction, 'direction');
    end;
end;

procedure TTestThinkersCeilingMachine.DovrebbeLasciareLoSpecialConIlCambiatoreSemplice;
var
  LState: TCeilingState;
begin
  LState := State(-1, CEILING_SPEED, 0);
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.GenCeilingChg, LState,
    TPlaneMoveResult.PastDest, False) = [TCeilingAction.ChangeTexture, TCeilingAction.Remove]);
  // not arrived: nothing yet
  Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.GenCeilingChg, LState,
    TPlaneMoveResult.Ok, False) = [], 'moving');
end;

procedure TTestThinkersCeilingMachine.DovrebbeNonFareAltroConUnGenereSconosciuto;
var
  LState: TCeilingState;
  LDirection: Integer;
  LResult: TPlaneMoveResult;
begin
  for LDirection in [-1, 1] do
    for LResult := Low(TPlaneMoveResult) to High(TPlaneMoveResult) do
    begin
      LState := State(LDirection, 123, 456);
      Assert.IsTrue(TCeilingMachine.AfterMove(TCeilingKind.Other, LState, LResult,
        False) = [], 'actions');
      Assert.AreEqual(LDirection, LState.Direction, 'direction');
      Assert.AreEqual(123, LState.Speed, 'speed');
    end;
end;

procedure TTestThinkersCeilingMachine.DovrebbeConfigurareLoSchiacciatoreRapidoSecondoIlGioco;
var
  LSpawn: TCeilingSpawn;
  LGame: TPlatGame;
begin
  for LGame := Low(TPlatGame) to High(TPlatGame) do
  begin
    FillChar(LSpawn, SizeOf(LSpawn), 0);
    Assert.AreEqual(Ord(TCeilingNeighbor.None), Ord(TCeilingMachine.Configure(
      TCeilingKind.FastCrushAndRaise, 10, 500, TCeilingGames.ProfileOf(LGame), LSpawn)));
    Assert.IsTrue(LSpawn.Crush, 'crush');
    Assert.AreEqual(500, LSpawn.TopHeight, 'top');
    Assert.AreEqual(10 + CEILING_CRUSH_GAP, LSpawn.BottomHeight, 'bottom');
    Assert.AreEqual(-1, LSpawn.Direction, 'direction');
    if LGame = TPlatGame.Strife then
      Assert.AreEqual(4 * CEILING_SPEED, LSpawn.Speed, 'speed of Strife')
    else
      Assert.AreEqual(2 * CEILING_SPEED, LSpawn.Speed, 'speed');
  end;
end;

procedure TTestThinkersCeilingMachine.DovrebbeConfigurareAbbassaESchiacciaSecondoIlGioco;
var
  LSpawn: TCeilingSpawn;
begin
  FillChar(LSpawn, SizeOf(LSpawn), 0);
  TCeilingMachine.Configure(TCeilingKind.LowerAndCrush, 10, 500,
    TCeilingGames.ProfileOf(TPlatGame.Doom), LSpawn);
  Assert.IsFalse(LSpawn.Crush, 'doom does not crush');
  Assert.AreEqual(10 + CEILING_CRUSH_GAP, LSpawn.BottomHeight, 'doom stops above the floor');

  FillChar(LSpawn, SizeOf(LSpawn), 0);
  TCeilingMachine.Configure(TCeilingKind.LowerAndCrush, 10, 500,
    TCeilingGames.ProfileOf(TPlatGame.Heretic), LSpawn);
  Assert.IsFalse(LSpawn.Crush, 'heretic does not crush');
  Assert.AreEqual(10 + CEILING_CRUSH_GAP, LSpawn.BottomHeight, 'heretic stops above the floor');

  FillChar(LSpawn, SizeOf(LSpawn), 0);
  TCeilingMachine.Configure(TCeilingKind.LowerAndCrush, 10, 500,
    TCeilingGames.ProfileOf(TPlatGame.Strife), LSpawn);
  Assert.IsTrue(LSpawn.Crush, 'strife crushes');
  Assert.AreEqual(10, LSpawn.BottomHeight, 'strife reaches the floor');
  Assert.AreEqual(-1, LSpawn.Direction, 'direction');
  Assert.AreEqual(CEILING_SPEED, LSpawn.Speed, 'speed');
end;

procedure TTestThinkersCeilingMachine.DovrebbeNonSchiacciareConGliSchiacciatoriDiStrife;
var
  LSpawn: TCeilingSpawn;
  LKind: TCeilingKind;
begin
  for LKind in [TCeilingKind.CrushAndRaise, TCeilingKind.SilentCrushAndRaise] do
  begin
    FillChar(LSpawn, SizeOf(LSpawn), 0);
    TCeilingMachine.Configure(LKind, 10, 500, TCeilingGames.ProfileOf(TPlatGame.Strife), LSpawn);
    Assert.IsFalse(LSpawn.Crush, 'strife');
    Assert.AreEqual(500, LSpawn.TopHeight, 'top');
    Assert.AreEqual(10 + CEILING_CRUSH_GAP, LSpawn.BottomHeight, 'bottom');

    FillChar(LSpawn, SizeOf(LSpawn), 0);
    TCeilingMachine.Configure(LKind, 10, 500, TCeilingGames.ProfileOf(TPlatGame.Doom), LSpawn);
    Assert.IsTrue(LSpawn.Crush, 'doom');
    Assert.AreEqual(CEILING_SPEED, LSpawn.Speed, 'speed');
  end;
end;

procedure TTestThinkersCeilingMachine.DovrebbeChiedereLeAltezzeAttornoAlSettore;
var
  LSpawn: TCeilingSpawn;
  LProfile: TCeilingProfile;
begin
  LProfile := TCeilingGames.ProfileOf(TPlatGame.Doom);
  FillChar(LSpawn, SizeOf(LSpawn), 0);
  Assert.AreEqual(Ord(TCeilingNeighbor.TopHighestCeiling),
    Ord(TCeilingMachine.Configure(TCeilingKind.RaiseToHighest, 0, 100, LProfile, LSpawn)));
  Assert.AreEqual(1, LSpawn.Direction, 'raise goes up');
  Assert.AreEqual(Ord(TCeilingNeighbor.BottomLowestCeiling),
    Ord(TCeilingMachine.Configure(TCeilingKind.LowerToLowest, 0, 100, LProfile, LSpawn)));
  Assert.AreEqual(-1, LSpawn.Direction, 'lower goes down');
  Assert.AreEqual(Ord(TCeilingNeighbor.BottomHighestFloor),
    Ord(TCeilingMachine.Configure(TCeilingKind.LowerToMaxFloor, 0, 100, LProfile, LSpawn)));
  Assert.AreEqual(CEILING_SPEED, LSpawn.Speed, 'speed');
  Assert.AreEqual(Ord(TCeilingNeighbor.None),
    Ord(TCeilingMachine.Configure(TCeilingKind.LowerToFloor, 7, 100, LProfile, LSpawn)));
  Assert.AreEqual(7, LSpawn.BottomHeight, 'lower to floor');
end;

procedure TTestThinkersCeilingMachine.DovrebbeLasciareICampiCheIlGenereNonScrive;
var
  LSpawn: TCeilingSpawn;
  LKind: TCeilingKind;
begin
  for LKind in [TCeilingKind.GenCeiling, TCeilingKind.GenCrusher, TCeilingKind.Other] do
  begin
    LSpawn.Crush := True;
    LSpawn.TopHeight := 11;
    LSpawn.BottomHeight := 22;
    LSpawn.Direction := 33;
    LSpawn.Speed := 44;
    Assert.AreEqual(Ord(TCeilingNeighbor.None), Ord(TCeilingMachine.Configure(LKind, 0, 100,
      TCeilingGames.ProfileOf(TPlatGame.Doom), LSpawn)));
    Assert.IsTrue(LSpawn.Crush, 'crush');
    Assert.AreEqual(11, LSpawn.TopHeight, 'top');
    Assert.AreEqual(22, LSpawn.BottomHeight, 'bottom');
    Assert.AreEqual(33, LSpawn.Direction, 'direction');
    Assert.AreEqual(44, LSpawn.Speed, 'speed');
  end;
  // lower to floor does not write the top
  LSpawn.TopHeight := 11;
  TCeilingMachine.Configure(TCeilingKind.LowerToFloor, 0, 100,
    TCeilingGames.ProfileOf(TPlatGame.Doom), LSpawn);
  Assert.AreEqual(11, LSpawn.TopHeight, 'top of lower to floor');
end;

procedure TTestThinkersCeilingMachine.DovrebbeRisvegliareSoloConGliSchiacciatoriCheRisalgono;
var
  LKind: TCeilingKind;
begin
  for LKind := Low(TCeilingKind) to High(TCeilingKind) do
    Assert.AreEqual(
      LKind in [TCeilingKind.CrushAndRaise, TCeilingKind.FastCrushAndRaise,
        TCeilingKind.SilentCrushAndRaise],
      TCeilingMachine.WakesUpStopped(LKind), 'kind ' + IntToStr(Ord(LKind)));
  Assert.IsTrue(OldDoomWakesUp(ceiling_e.crushAndRaise) and OldDoomWakesUp(ceiling_e.fastCrushAndRaise) and
    OldDoomWakesUp(ceiling_e.silentCrushAndRaise) and
    not OldDoomWakesUp(ceiling_e.lowerAndCrush), 'old doom');
  Assert.IsTrue(OldHereticWakesUp(heretic_ceiling_e.crushAndRaise) and
    OldHereticWakesUp(heretic_ceiling_e.fastCrushAndRaise) and
    not OldHereticWakesUp(heretic_ceiling_e.lowerAndCrush), 'old heretic');
end;

procedure TTestThinkersCeilingMachine.DovrebbeDareIlProfiloDiOgniGioco;
var
  LProfile: TCeilingProfile;
begin
  LProfile := TCeilingGames.ProfileOf(TPlatGame.Doom);
  Assert.AreEqual(2, LProfile.FastCrushSpeedFactor, 'doom factor');
  Assert.IsTrue(LProfile.CrushAndRaiseCrushes, 'doom crushes');
  Assert.IsFalse(LProfile.LowerAndCrushReachesFloor, 'doom gap');
  Assert.IsTrue(LProfile.WakeUpCounts, 'doom wake up');

  LProfile := TCeilingGames.ProfileOf(TPlatGame.Heretic);
  Assert.AreEqual(2, LProfile.FastCrushSpeedFactor, 'heretic factor');
  Assert.IsTrue(LProfile.CrushAndRaiseCrushes, 'heretic crushes');
  Assert.IsFalse(LProfile.LowerAndCrushReachesFloor, 'heretic gap');
  Assert.IsFalse(LProfile.WakeUpCounts, 'heretic wake up');

  LProfile := TCeilingGames.ProfileOf(TPlatGame.Strife);
  Assert.AreEqual(4, LProfile.FastCrushSpeedFactor, 'strife factor');
  Assert.IsFalse(LProfile.CrushAndRaiseCrushes, 'strife crushes');
  Assert.IsTrue(LProfile.LowerAndCrushReachesFloor, 'strife gap');
  Assert.IsTrue(LProfile.WakeUpCounts, 'strife wake up');
end;

procedure TTestThinkersCeilingMachine.RandomCeiling(var AState: Cardinal; out ASector: sector_t;
  out ACeiling: ceiling_t);
begin
  FillChar(ASector, SizeOf(ASector), 0);
  FillChar(ACeiling, SizeOf(ACeiling), 0);
  ASector.floorheight := TestNumberIn(AState, -16, 16) * FRACUNIT;
  ASector.ceilingheight := ASector.floorheight + TestNumberIn(AState, 0, 96) * FRACUNIT;
  ASector.special := TestNumberIn(AState, 0, 30);
  ASector.oldspecial := TestNumberIn(AState, 0, 30);
  ASector.ceilingpic := TestNumberIn(AState, 0, 100);
  // what the memory of a new thinker could hold: the kinds that set nothing keep it
  ACeiling.topheight := ASector.ceilingheight + TestNumberIn(AState, 0, 64) * FRACUNIT;
  ACeiling.bottomheight := ASector.floorheight + TestNumberIn(AState, -8, 32) * FRACUNIT;
  ACeiling.direction := TestNumberIn(AState, -1, 1);
  ACeiling.speed := TestNumberIn(AState, 1, 5 * FRACUNIT);
  ACeiling.oldspeed := TestNumberIn(AState, 1, 5 * FRACUNIT);
  if TestNumberIn(AState, 0, 3) = 0 then
    ACeiling.oldspeed := 3 * FRACUNIT - TestNumberIn(AState, 0, 1);
  ACeiling.newspecial := TestNumberIn(AState, 0, 30);
  ACeiling.oldspecial := TestNumberIn(AState, 0, 30);
  ACeiling.texture := TestNumberIn(AState, 0, 100);
  ACeiling.crush := TestNumberIn(AState, 0, 1) = 1;
  OldHighestCeilingSurrounding := ASector.ceilingheight + TestNumberIn(AState, -16, 64) * FRACUNIT;
  OldLowestCeilingSurrounding := ASector.ceilingheight - TestNumberIn(AState, -16, 64) * FRACUNIT;
  OldHighestFloorSurrounding := ASector.floorheight + TestNumberIn(AState, -16, 48) * FRACUNIT;
end;

procedure TTestThinkersCeilingMachine.CheckSame(const AOld, ANew: ceiling_t; const AOldSector,
  ANewSector: sector_t; const AText: string);
begin
  Assert.AreEqual(AOld.topheight, ANew.topheight, 'top of ' + AText);
  Assert.AreEqual(AOld.bottomheight, ANew.bottomheight, 'bottom of ' + AText);
  Assert.AreEqual(AOld.speed, ANew.speed, 'speed of ' + AText);
  Assert.AreEqual(AOld.oldspeed, ANew.oldspeed, 'old speed of ' + AText);
  Assert.AreEqual(AOld.crush, ANew.crush, 'crush of ' + AText);
  Assert.AreEqual(AOld.direction, ANew.direction, 'direction of ' + AText);
  Assert.AreEqual(AOldSector.floorheight, ANewSector.floorheight, 'floor of ' + AText);
  Assert.AreEqual(AOldSector.ceilingheight, ANewSector.ceilingheight, 'ceiling of ' + AText);
  Assert.AreEqual(AOldSector.special, ANewSector.special, 'special of ' + AText);
  Assert.AreEqual(AOldSector.oldspecial, ANewSector.oldspecial, 'old special of ' + AText);
  Assert.AreEqual(AOldSector.ceilingpic, ANewSector.ceilingpic, 'texture of ' + AText);
  Assert.AreEqual(OldCeilingLog, FNewLog, 'sounds and removal of ' + AText);
end;

procedure TTestThinkersCeilingMachine.CheckGameParity(AGame: TPlatGame; ASeed: Cardinal);
const
  RUN_COUNT = 600;
  TIC_COUNT = 400;
var
  LState: Cardinal;
  LRun, LTic, LIndex, LMoveSound, LLift: Integer;
  LOldSector, LNewSector: sector_t;
  LOld, LNew: ceiling_t;
  LKind: TCeilingKind;
  LProfile: TCeilingProfile;
  LSpawned: Boolean;
  LText: string;
begin
  LState := ASeed;
  LProfile := TCeilingGames.ProfileOf(AGame);
  case AGame of
    TPlatGame.Heretic:
      OldCeilingRules := TPlaneRules.Heretic;
    TPlatGame.Strife:
      OldCeilingRules := TPlaneRules.Strife;
  else
    OldCeilingRules := TPlaneRules.Doom(True);
  end;
  if AGame = TPlatGame.Heretic then
    LMoveSound := sfx_dormov
  else
    LMoveSound := sfx_stnmov;

  for LRun := 1 to RUN_COUNT do
  begin
    RandomCeiling(LState, LOldSector, LOld);
    LNewSector := LOldSector;
    LNew := LOld;
    LOld.sector := @LOldSector;
    LNew.sector := @LNewSector;
    if AGame = TPlatGame.Heretic then
      LIndex := TestNumberIn(LState, 0, High(HERETIC_KINDS))
    else
      LIndex := TestNumberIn(LState, 0, High(DOOM_KINDS));
    // the kinds of EV_DoCeiling are made by it, the others (Boom, scripted) by someone else:
    // their fields are whatever the random ceiling has, with a direction that moves
    LSpawned := TestNumberIn(LState, 0, 4) > 0;
    if AGame = TPlatGame.Heretic then
      LKind := HERETIC_KINDS[LIndex]
    else
      LKind := DOOM_KINDS[LIndex];
    LOld._type := ceiling_e(LIndex);
    LNew._type := LOld._type;
    if LSpawned then
    begin
      LOld.crush := False;
      LNew.crush := False;
      case AGame of
        TPlatGame.Heretic:
          OldHereticSpawnCeiling(@LOld, @LOldSector, heretic_ceiling_e(LIndex));
        TPlatGame.Strife:
          OldStrifeSpawnCeiling(@LOld, @LOldSector, ceiling_e(LIndex));
      else
        OldDoomSpawnCeiling(@LOld, @LOldSector, ceiling_e(LIndex));
      end;
      NewSpawnCeiling(@LNew, @LNewSector, LKind, LProfile);
    end;
    LText := Format('run %d kind %d', [LRun, LIndex]);
    OldCeilingLog := '';
    FNewLog := '';
    CheckSame(LOld, LNew, LOldSector, LNewSector, 'the new ceiling of ' + LText);

    for LTic := 1 to TIC_COUNT do
    begin
      OldCeilingLevelTime := LRun * 3 + LTic;
      // now and then the floor comes up under the ceiling: an obstacle for the crushers
      if TestNumberIn(LState, 0, 40) = 0 then
      begin
        LLift := TestNumberIn(LState, -8, 8) * FRACUNIT;
        Inc(LOldSector.floorheight, LLift);
        Inc(LNewSector.floorheight, LLift);
      end;
      if AGame = TPlatGame.Heretic then
        OldHereticMoveCeiling(@LOld, heretic_ceiling_e(LIndex))
      else
        OldDoomMoveCeiling(@LOld);
      NewMoveCeiling(@LNew, LKind, LMoveSound);
      CheckSame(LOld, LNew, LOldSector, LNewSector, Format('%s tic %d', [LText, LTic]));
      // removed: the thinker is gone
      if (OldCeilingLog <> '') and (OldCeilingLog[Length(OldCeilingLog) - 1] = 'R') then
        Break;
      OldCeilingLog := '';
      FNewLog := '';
    end;
  end;
end;

procedure TTestThinkersCeilingMachine.DovrebbeSeguireIlVecchioCodiceDiDoom;
begin
  CheckGameParity(TPlatGame.Doom, 41);
end;

procedure TTestThinkersCeilingMachine.DovrebbeSeguireIlVecchioCodiceDiStrife;
begin
  CheckGameParity(TPlatGame.Strife, 42);
end;

procedure TTestThinkersCeilingMachine.DovrebbeSeguireIlVecchioCodiceDiHeretic;
begin
  CheckGameParity(TPlatGame.Heretic, 43);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersCeilingMachine);

end.
