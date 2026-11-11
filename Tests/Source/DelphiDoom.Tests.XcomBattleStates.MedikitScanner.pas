{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the medi-kit screen (MedikitState, MedikitView)    }
{  and of the motion scanner (ScannerState, ScannerView) on a real battle       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.MedikitScanner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.XcomBattleStates.MedikitState,
  DelphiDoom.XcomBattleStates.ScannerState, DelphiDoom.Tests.XcomBattleStates.Bench;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomMedikitScanner = class
  strict private
    FBench: TBattleBench;
    FState: TXcomBattlescapeState;
    FAction: TXcomBattleAction;
    FItem: TXcomBattleItem;
    FActor: TXcomBattleUnit;
    FTarget: TXcomBattleUnit;
    function Ready: Boolean;
    procedure MakeItem(const AType: string);
    function OpenMedikit: TXcomMedikitState;
    function OpenScanner: TXcomScannerState;
    procedure Click(ASurface: TXcomInteractiveSurface; AButton: Integer = XCOM_BUTTON_LEFT);
    procedure PressKey(AKey: Integer);
    procedure Wound;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlMedikitDovrebbeMostrareLeDosiELaParteFerita;
    [Test]
    procedure CurareDovrebbeTogliereLaFeritaESpendereLeUnitaDiTempo;
    [Test]
    procedure SenzaDosiIlPulsanteNonFaNulla;
    [Test]
    procedure SenzaUnitaDiTempoLoSchermoSiChiudeConLAvviso;
    [Test]
    procedure LoStimolanteDovrebbeDareEnergiaEContareLaDose;
    [Test]
    procedure LoStimolanteDovrebbeRianimareChiESvenutoEChiudere;
    [Test]
    procedure LAntidolorificoDovrebbeRidareIlMorale;
    [Test]
    procedure IlMedikitSiChiudeColPulsanteColTastoDestroEConEsc;
    [Test]
    procedure IlClicSulCorpoSceglieLaParte;
    [Test]
    procedure LeSchermateVereDannoMedikitEScanner;
    [Test]
    procedure LoScannerDovrebbeDisegnareLaFrecciaAlCentro;
    [Test]
    procedure LoScannerDovrebbeMostrareChiSiEMosso;
    [Test]
    procedure LoScannerDovrebbeLampeggiareOgni125Millisecondi;
    [Test]
    procedure LoScannerSiChiudeConUnClicColTastoDestroEConEsc;
    [Test]
    procedure GliOggettiDellaManoSinistraHannoIlLoroSetDiSprite;
  end;

implementation

uses
  DelphiDoom.XcomBattleStates.Screens, DelphiDoom.XcomBattleStates.Screens.Intf,
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomBattleStates.MedikitView,
  DelphiDoom.XcomBattleStates.ScannerView;

const
  MEDIKIT = 'STR_MEDI_KIT';
  SCANNER = 'STR_PARTICLE_DISTURBANCE_SENSOR';
  KEY_ESCAPE = 27;
  ACTION_COST = 10;

procedure TTestXcomMedikitScanner.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomMedikitScanner.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomMedikitScanner.Setup;
var
  LUnit: TXcomBattleUnit;
begin
  FState := nil;
  FAction := nil;
  FItem := nil;
  if not FBench.Available then
    Exit;
  FBench.Start;
  FState := FBench.PushBattlescape;
  FActor := FBench.Session.Battle.SelectedUnit;
  FTarget := nil;
  for LUnit in FBench.Session.Battle.Units do
    if (LUnit <> FActor) and (LUnit.Faction = FACTION_PLAYER) and (not LUnit.IsOut) then
    begin
      FTarget := LUnit;
      Break;
    end;
  FAction := TXcomBattleAction.Create;
  FAction.Actor := FActor;
  FAction.ActionType := BA_USE;
  FAction.TimeUnits := ACTION_COST;
end;

procedure TTestXcomMedikitScanner.TearDown;
begin
  FState := nil;
  FBench.Stop;
  FAction.Free;
  FItem.Free;
end;

function TTestXcomMedikitScanner.Ready: Boolean;
begin
  Result := Assigned(FState) and Assigned(FActor) and Assigned(FTarget);
  if not Result then
    Assert.Pass('the data of TFTD are not here');
end;

procedure TTestXcomMedikitScanner.MakeItem(const AType: string);
var
  LId: Integer;
begin
  LId := 9000;
  FItem := TXcomBattleItem.Create(FBench.Ruleset.Items.Find(AType), LId);
  FAction.Weapon := FItem;
end;

procedure TTestXcomMedikitScanner.Wound;
begin
  // ignoring the armor the hit is on the torso; with this power the unit is always wounded
  FTarget.Damage(TXcomPosition.Make(0, 0, 0), 12, TXcomRuleItem.DT_AP, True);
  Assert.IsTrue(FTarget.GetFatalWound(BODYPART_TORSO) > 0, 'the target must be wounded');
end;

function TTestXcomMedikitScanner.OpenMedikit: TXcomMedikitState;
begin
  MakeItem(MEDIKIT);
  Result := TXcomMedikitState.Create(FBench.World.Game, FBench.Session, FTarget, FAction);
  FBench.World.Game.PushState(Result);
  FBench.World.Wait(60);
end;

function TTestXcomMedikitScanner.OpenScanner: TXcomScannerState;
begin
  MakeItem(SCANNER);
  Result := TXcomScannerState.Create(FBench.World.Game, FBench.Session, FAction);
  FBench.World.Game.PushState(Result);
  FBench.World.Wait(60);
end;

procedure TTestXcomMedikitScanner.Click(ASurface: TXcomInteractiveSurface; AButton: Integer);
var
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
begin
  LX := Round((ASurface.X + ASurface.Width div 2) * FBench.World.Game.Screen.XScale);
  LY := Round((ASurface.Y + ASurface.Height div 2) * FBench.World.Game.Screen.YScale);
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := LX;
  LEvent.Y := LY;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  LEvent.Kind := ekMouseDown;
  LEvent.Button := AButton;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(40);
  LEvent.Kind := ekMouseUp;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(40);
end;

procedure TTestXcomMedikitScanner.PressKey(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  LEvent.Kind := ekKeyUp;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
end;

procedure TTestXcomMedikitScanner.IlMedikitDovrebbeMostrareLeDosiELaParteFerita;
var
  LScreen: TXcomMedikitState;
begin
  if not Ready then
    Exit;
  Wound;
  LScreen := OpenMedikit;
  Assert.AreEqual(IntToStr(FItem.Rules.Heal), LScreen.HealText.GetText);
  Assert.AreEqual(IntToStr(FItem.Rules.Stimulant), LScreen.StimulantText.GetText);
  Assert.AreEqual(IntToStr(FItem.Rules.PainKiller), LScreen.PainKillerText.GetText);
  Assert.AreEqual(BODYPART_TORSO, LScreen.MedikitView.SelectedPart);
  Assert.AreEqual(IntToStr(FTarget.GetFatalWound(BODYPART_TORSO)), LScreen.WoundText.GetText);
  Assert.AreEqual(FState.Tr('STR_TORSO').Text, LScreen.PartText.GetText);
end;

procedure TTestXcomMedikitScanner.CurareDovrebbeTogliereLaFeritaESpendereLeUnitaDiTempo;
var
  LScreen: TXcomMedikitState;
  LWounds: Integer;
  LTimeUnits: Integer;
  LDoses: Integer;
begin
  if not Ready then
    Exit;
  Wound;
  LScreen := OpenMedikit;
  LWounds := FTarget.GetFatalWound(BODYPART_TORSO);
  LTimeUnits := FActor.TimeUnits;
  LDoses := FItem.HealQuantity;
  Click(LScreen.HealButton);
  Assert.AreEqual(LDoses - 1, FItem.HealQuantity);
  Assert.AreEqual(LTimeUnits - ACTION_COST, FActor.TimeUnits);
  Assert.IsTrue(FTarget.GetFatalWound(BODYPART_TORSO) < LWounds);
  Assert.AreEqual(1, FActor.Statistics.WoundsHealed);
  Assert.AreEqual(IntToStr(LDoses - 1), LScreen.HealText.GetText);
  Assert.AreEqual(IntToStr(FTarget.GetFatalWound(BODYPART_TORSO)), LScreen.WoundText.GetText);
  Assert.IsTrue(FBench.World.Game.IsState(LScreen), 'the target is awake: the screen stays');
end;

procedure TTestXcomMedikitScanner.SenzaDosiIlPulsanteNonFaNulla;
var
  LScreen: TXcomMedikitState;
  LTimeUnits: Integer;
begin
  if not Ready then
    Exit;
  LScreen := OpenMedikit;
  FItem.HealQuantity := 0;
  FItem.StimulantQuantity := 0;
  FItem.PainKillerQuantity := 0;
  LTimeUnits := FActor.TimeUnits;
  Click(LScreen.HealButton);
  Click(LScreen.StimulantButton);
  Click(LScreen.PainKillerButton);
  Assert.AreEqual(LTimeUnits, FActor.TimeUnits);
  Assert.IsTrue(FBench.World.Game.IsState(LScreen));
  Assert.AreEqual('', FAction.ResultText);
end;

procedure TTestXcomMedikitScanner.SenzaUnitaDiTempoLoSchermoSiChiudeConLAvviso;
var
  LScreen: TXcomMedikitState;
begin
  if not Ready then
    Exit;
  FAction.TimeUnits := FActor.TimeUnits + 1;
  LScreen := OpenMedikit;
  Click(LScreen.PainKillerButton);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FAction.ResultText);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
  Assert.AreEqual(FItem.Rules.PainKiller, FItem.PainKillerQuantity);
end;

procedure TTestXcomMedikitScanner.LoStimolanteDovrebbeDareEnergiaEContareLaDose;
var
  LScreen: TXcomMedikitState;
  LDoses: Integer;
begin
  if not Ready then
    Exit;
  LScreen := OpenMedikit;
  LDoses := FItem.StimulantQuantity;
  Click(LScreen.StimulantButton);
  Assert.AreEqual(LDoses - 1, FItem.StimulantQuantity);
  Assert.AreEqual(1, FActor.Statistics.AppliedStimulant);
  Assert.AreEqual(0, FActor.Statistics.RevivedSoldier);
  Assert.IsTrue(FBench.World.Game.IsState(LScreen));
end;

procedure TTestXcomMedikitScanner.LoStimolanteDovrebbeRianimareChiESvenutoEChiudere;
var
  LScreen: TXcomMedikitState;
  LGuard: Integer;
begin
  if not Ready then
    Exit;
  FTarget.KnockOut;
  FTarget.StartFalling;
  LGuard := 0;
  while (FTarget.Status <> STATUS_UNCONSCIOUS) and (LGuard < 20) do
  begin
    FTarget.KeepFalling;
    Inc(LGuard);
  end;
  Assert.AreEqual(STATUS_UNCONSCIOUS, FTarget.Status);
  LScreen := OpenMedikit;
  if FItem.Rules.StunRecovery <= 0 then
  begin
    Assert.Pass('the medi-kit of the rules does not heal the stun');
    Exit;
  end;
  Click(LScreen.StimulantButton);
  Assert.AreEqual(1, FActor.Statistics.RevivedSoldier);
  Assert.AreEqual(0, FTarget.TimeUnits);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'the screen closes when the target revives');
end;

procedure TTestXcomMedikitScanner.LAntidolorificoDovrebbeRidareIlMorale;
var
  LScreen: TXcomMedikitState;
  LDoses: Integer;
begin
  if not Ready then
    Exit;
  Wound;
  LScreen := OpenMedikit;
  LDoses := FItem.PainKillerQuantity;
  Click(LScreen.PainKillerButton);
  Assert.AreEqual(LDoses - 1, FItem.PainKillerQuantity);
  Assert.AreEqual(1, FActor.Statistics.AppliedPainKill);
  Assert.AreEqual(IntToStr(LDoses - 1), LScreen.PainKillerText.GetText);
end;

procedure TTestXcomMedikitScanner.IlMedikitSiChiudeColPulsanteColTastoDestroEConEsc;
var
  LScreen: TXcomMedikitState;
begin
  if not Ready then
    Exit;
  LScreen := OpenMedikit;
  Click(LScreen.EndButton);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'button');
  FItem.Free;
  FItem := nil;
  LScreen := OpenMedikit;
  Click(LScreen.MedikitView, XCOM_BUTTON_RIGHT);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'right button');
  FItem.Free;
  FItem := nil;
  OpenMedikit;
  PressKey(KEY_ESCAPE);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'escape');
end;

procedure TTestXcomMedikitScanner.IlClicSulCorpoSceglieLaParte;
var
  LScreen: TXcomMedikitState;
  LBefore: Integer;
begin
  if not Ready then
    Exit;
  LScreen := OpenMedikit;
  LBefore := LScreen.MedikitView.SelectedPart;
  Assert.AreEqual(0, LBefore, 'with no wound the head is selected');
  // the middle of the body picture is the torso
  Click(LScreen.MedikitView);
  Assert.AreEqual(BODYPART_TORSO, LScreen.MedikitView.SelectedPart);
  FBench.World.Wait(40);
  Assert.AreEqual(FState.Tr('STR_TORSO').Text, LScreen.PartText.GetText);
end;

procedure TTestXcomMedikitScanner.LeSchermateVereDannoMedikitEScanner;
var
  LScreens: IXcomBattleScreens;
  LScreen: TXcomState;
begin
  if not Ready then
    Exit;
  MakeItem(MEDIKIT);
  LScreens := TXcomBattleScreens.Create;
  LScreen := LScreens.Medikit(FState, FTarget, FAction);
  try
    Assert.IsTrue(LScreen is TXcomMedikitState);
  finally
    LScreen.Free;
  end;
  LScreen := LScreens.Scanner(FState, FAction);
  try
    Assert.IsTrue(LScreen is TXcomScannerState);
  finally
    LScreen.Free;
  end;
end;

procedure TTestXcomMedikitScanner.LoScannerDovrebbeDisegnareLaFrecciaAlCentro;
var
  LScreen: TXcomScannerState;
  LView: TXcomScannerView;
  LX: Integer;
  LY: Integer;
  LInside: Integer;
begin
  if not Ready then
    Exit;
  LScreen := OpenScanner;
  LView := LScreen.ScannerView;
  LInside := 0;
  for LY := 0 to LView.Height - 1 do
    for LX := 0 to LView.Width - 1 do
      if LView.GetPixel(LX, LY) <> 0 then
      begin
        if (Abs(LX - TXcomScannerView.RANGE * TXcomScannerView.CELL) <= TXcomScannerView.CELL) and
          (Abs(LY - TXcomScannerView.RANGE * TXcomScannerView.CELL) <= TXcomScannerView.CELL) then
          Inc(LInside);
      end;
  Assert.IsTrue(LInside > 0, 'the arrow of the direction');
end;

procedure TTestXcomMedikitScanner.LoScannerDovrebbeMostrareChiSiEMosso;
var
  LScreen: TXcomScannerState;
  LView: TXcomScannerView;
  LUnit: TXcomBattleUnit;
  LMoved: Integer;
  LX: Integer;
  LY: Integer;
  LCount: Integer;
begin
  if not Ready then
    Exit;
  LMoved := 0;
  for LUnit in FBench.Session.Battle.Units do
    if (LUnit <> FActor) and (LUnit.MotionPoints <> 0) and (not LUnit.IsOut) and
      (Abs(LUnit.Position.X - FActor.Position.X) <= TXcomScannerView.RANGE - 1) and
      (Abs(LUnit.Position.Y - FActor.Position.Y) <= TXcomScannerView.RANGE - 1) then
      Inc(LMoved);
  LScreen := OpenScanner;
  LView := LScreen.ScannerView;
  LCount := 0;
  for LY := 0 to LView.Height - 1 do
    for LX := 0 to LView.Width - 1 do
      if (LView.GetPixel(LX, LY) <> 0) and
        ((Abs(LX - TXcomScannerView.RANGE * TXcomScannerView.CELL) > TXcomScannerView.CELL) or
        (Abs(LY - TXcomScannerView.RANGE * TXcomScannerView.CELL) > TXcomScannerView.CELL)) then
        Inc(LCount);
  if LMoved = 0 then
    Assert.AreEqual(0, LCount, 'nobody moved: no blip away from the middle')
  else
    Assert.IsTrue(LCount > 0, 'a unit that moved is a blip');
end;

procedure TTestXcomMedikitScanner.LoScannerDovrebbeLampeggiareOgni125Millisecondi;
var
  LScreen: TXcomScannerState;
  LFrame: Integer;
begin
  if not Ready then
    Exit;
  LScreen := OpenScanner;
  LFrame := LScreen.ScannerView.Frame;
  FBench.World.Wait(130);
  Assert.AreEqual(1 - LFrame, LScreen.ScannerView.Frame);
  FBench.World.Wait(130);
  Assert.AreEqual(LFrame, LScreen.ScannerView.Frame);
end;

procedure TTestXcomMedikitScanner.LoScannerSiChiudeConUnClicColTastoDestroEConEsc;
var
  LScreen: TXcomScannerState;
begin
  if not Ready then
    Exit;
  LScreen := OpenScanner;
  Click(LScreen.Background);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'click');
  FItem.Free;
  FItem := nil;
  LScreen := OpenScanner;
  Click(LScreen.Background, XCOM_BUTTON_RIGHT);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'right button');
  FItem.Free;
  FItem := nil;
  OpenScanner;
  PressKey(KEY_ESCAPE);
  Assert.IsTrue(FBench.World.Game.IsState(FState), 'escape');
end;

procedure TTestXcomMedikitScanner.GliOggettiDellaManoSinistraHannoIlLoroSetDiSprite;
var
  LRight: TXcomSurfaceSet;
  LLeft: TXcomSurfaceSet;
begin
  if not Ready then
    Exit;
  // Mod::loadBattlescapeResources: HANDOB2.PCK is a copy of HANDOB.PCK (without it an item in the left hand
  // had no set to be drawn from)
  LRight := FBench.Session.Graphics.Sprites.SurfaceSet('HANDOB.PCK');
  LLeft := FBench.Session.Graphics.Sprites.SurfaceSet('HANDOB2.PCK');
  Assert.IsNotNull(LRight);
  Assert.IsNotNull(LLeft);
  Assert.IsTrue(LLeft <> LRight, 'the two hands must not share the frames');
  Assert.AreEqual(LRight.TotalFrames, LLeft.TotalFrames);
  Assert.IsTrue(LLeft.GetFrame(0) <> LRight.GetFrame(0));
end;

end.
