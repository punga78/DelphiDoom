{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pmove library - the parts of the movement alone:   }
{  vectors, view angles, events and touched entities, animations, the item     }
{  list, the walk with the movements it hands over to                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Pmove.Parts;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, System.Generics.Defaults, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Models.Q3Player.Types, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf, DelphiDoom.Pmove.State;

type
  [TestFixture]
  [Category('Pmove')]
  TTestPmoveVector = class
  strict private
    procedure Near(const AExpected, AActual: Single; const AMessage: string);
  public
    [Test]
    procedure DovrebbeCalcolareLaLunghezzaConLaRadiceInDouble;
    [Test]
    procedure DovrebbeNormalizzareERiportareLaLunghezza;
    [Test]
    procedure DovrebbeLasciareUnVettoreNulloComeE;
    [Test]
    procedure DovrebbeAzzerareLUscitaDiNormalize2ConUnVettoreNullo;
    [Test]
    procedure DovrebbeFareLeOperazioniSuiVettori;
    [Test]
    procedure DovrebbeScivolareViaDallaSuperficieConIlSovrapposto;
    [Test]
    procedure DovrebbeCalcolareIlTempoDiUnPassoComeUnDouble;
  end;

  [TestFixture]
  [Category('Pmove')]
  TTestPmoveViewAngles = class
  public
    [Test]
    procedure DovrebbeConvertireUnAngoloDa16BitInGradi;
    [Test]
    procedure DovrebbeSommareComandoEDeltaFacendoGirareUnoShort;
    [Test]
    procedure DovrebbeTenerePiuInAltoEPiuInBassoDiNovantaGradi;
    [Test]
    procedure DovrebbeNonCambiareLaVistaInIntermissione;
    [Test]
    procedure DovrebbeNonCambiareLaVistaDaMortiMaSiDaSpettatori;
  end;

  [TestFixture]
  [Category('Pmove')]
  TTestPmoveEvents = class
  strict private
    FState: TPmoveState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeUsareLAnelloDiDueEventi;
    [Test]
    procedure DovrebbeNonSegnareIlMondoNeUnaEntitaDueVolte;
    [Test]
    procedure DovrebbeFermarsiATrentaduEntitaToccate;
    [Test]
    procedure DovrebbeCambiareIlBitDiInversioneDelleAnimazioni;
    [Test]
    procedure DovrebbeNonCambiareLeAnimazioniDaMorti;
    [Test]
    procedure DovrebbeRispettareIlTimerDiUnaAnimazioneDiPriorita;
    [Test]
    procedure DovrebbeNonRipartireDaUnaAnimazioneGiaInCorso;
  end;

  [TestFixture]
  [Category('Pmove')]
  TTestPmoveItems = class
  public
    [Test]
    procedure DovrebbeDareIlTagDegliOggettiDiBaseq3;
    [Test]
    procedure DovrebbeDareZeroPerUnIndiceFuoriDallaLista;
    [Test]
    procedure DovrebbeDareZeroSenzaCatalogo;
    [Test]
    procedure DovrebbeUsareUnCatalogoDelGioco;
    [Test]
    procedure DovrebbeNonUsareUnMedkitSeLaSaluteELaMassima;
  end;

  [TestFixture]
  [Category('Pmove')]
  TTestPmoveWalkMover = class
  public
    [Test]
    procedure DovrebbeNuotareSeVaVersoLAltoDalFondoConLaTestaSottoLAcqua;
    [Test]
    procedure DovrebbeSaltareNellAriaOnellAcquaSecondoLAcqua;
  end;

  [TestFixture]
  [Category('Pmove')]
  TTestPmoveTuning = class
  public
    [Test]
    procedure DovrebbeAvereIValoriDiBg_pmove;
    [Test]
    procedure DovrebbeUsareLeCostantiInVirgolaMobileDelC;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector, DelphiDoom.Pmove.ViewAngles, DelphiDoom.Pmove.Events, DelphiDoom.Pmove.Items,
  DelphiDoom.Pmove.Physics, DelphiDoom.Pmove.Slider, DelphiDoom.Pmove.WalkMover, DelphiDoom.Pmove.Factory,
  DelphiDoom.Tests.Pmove.Support.World, DelphiDoom.Tests.Collision.Q3Support;

type
  /// <summary>A movement that counts how many times it was asked to move</summary>
  TCountingMovement = class(TSingletonImplementation, IPmoveMovement)
  public
    Moves: Integer;
    procedure Move;
  end;

  /// <summary>An item list of a game that is not baseq3: item 5 is a medkit</summary>
  TOtherItems = class(TInterfacedObject, IPmoveItemCatalog)
  public
    function GameTag(const AIndex: Integer): Integer;
  end;

procedure TCountingMovement.Move;
begin
  Inc(Moves);
end;

function TOtherItems.GameTag(const AIndex: Integer): Integer;
begin
  if AIndex = 5 then
    Result := Q3_HI_MEDKIT
  else
    Result := 0;
end;

procedure AssertNear(const AExpected, AActual, ATolerance: Double; const AMessage: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) <= ATolerance, Format('%s: atteso %g ottenuto %g', [AMessage, AExpected, AActual]));
end;

function BitsOfDouble(const AValue: Double): UInt64;
begin
  Move(AValue, Result, SizeOf(Result));
end;

function Vec3(const AX, AY, AZ: Single): TQ3Vec3;
begin
  Result[0] := AX;
  Result[1] := AY;
  Result[2] := AZ;
end;

{ TTestPmoveVector }

procedure TTestPmoveVector.Near(const AExpected, AActual: Single; const AMessage: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) <= 1.0E-5, Format('%s: atteso %g ottenuto %g', [AMessage, AExpected, AActual]));
end;

procedure TTestPmoveVector.DovrebbeCalcolareLaLunghezzaConLaRadiceInDouble;
begin
  Near(5, TPmoveVector.Length(Vec3(3, 4, 0)), 'lunghezza');
  Near(0, TPmoveVector.Length(Vec3(0, 0, 0)), 'nulla');
  Near(3, TPmoveVector.SquareRoot(9), 'radice');
end;

procedure TTestPmoveVector.DovrebbeNormalizzareERiportareLaLunghezza;
var
  LVector: TQ3Vec3;
  LLength: Single;
begin
  LVector := Vec3(0, 3, 4);
  LLength := TPmoveVector.Normalize(LVector);
  Near(5, LLength, 'lunghezza');
  Near(0.6, LVector[1], 'y');
  Near(0.8, LVector[2], 'z');
end;

procedure TTestPmoveVector.DovrebbeLasciareUnVettoreNulloComeE;
var
  LVector: TQ3Vec3;
begin
  LVector := Vec3(0, 0, 0);
  Near(0, TPmoveVector.Normalize(LVector), 'lunghezza');
  Near(0, LVector[0] + LVector[1] + LVector[2], 'vettore');
end;

procedure TTestPmoveVector.DovrebbeAzzerareLUscitaDiNormalize2ConUnVettoreNullo;
var
  LOut: TQ3Vec3;
begin
  LOut := Vec3(7, 7, 7);
  Near(0, TPmoveVector.Normalize2(Vec3(0, 0, 0), LOut), 'lunghezza');
  Near(0, LOut[0] + LOut[1] + LOut[2], 'uscita');
  Near(2, TPmoveVector.Normalize2(Vec3(0, 2, 0), LOut), 'lunghezza');
  Near(1, LOut[1], 'unitario');
end;

procedure TTestPmoveVector.DovrebbeFareLeOperazioniSuiVettori;
var
  LResult: TQ3Vec3;
begin
  TPmoveVector.Add(Vec3(1, 2, 3), Vec3(4, 5, 6), LResult);
  Near(5, LResult[0], 'somma x');
  Near(9, LResult[2], 'somma z');
  TPmoveVector.Subtract(Vec3(4, 5, 6), Vec3(1, 2, 3), LResult);
  Near(3, LResult[1], 'differenza');
  TPmoveVector.Scale(Vec3(1, 2, 3), 2, LResult);
  Near(6, LResult[2], 'scala');
  TPmoveVector.MultiplyAdd(Vec3(1, 1, 1), 2, Vec3(1, 2, 3), LResult);
  Near(3, LResult[0], 'ma x');
  Near(7, LResult[2], 'ma z');
  TPmoveVector.Cross(Vec3(1, 0, 0), Vec3(0, 1, 0), LResult);
  Near(1, LResult[2], 'prodotto vettoriale');
  Near(32, TPmoveVector.Dot(Vec3(1, 2, 3), Vec3(4, 5, 6)), 'scalare');
  TPmoveVector.Copy(Vec3(1, 2, 3), LResult);
  Near(2, LResult[1], 'copia');
  TPmoveVector.Clear(LResult);
  Near(0, LResult[2], 'azzera');
end;

procedure TTestPmoveVector.DovrebbeScivolareViaDallaSuperficieConIlSovrapposto;
var
  LVelocity: TQ3Vec3;
begin
  // into the floor: the part into it is taken back by 1.001, and the part of the velocity along it stays
  LVelocity := Vec3(1, 0, -1);
  TPmoveVector.ClipVelocity(LVelocity, Vec3(0, 0, 1), LVelocity, Q3_OVERCLIP);
  Near(1, LVelocity[0], 'lungo');
  Assert.IsTrue(LVelocity[2] > 0, 'un poco verso l''alto per l''overclip');
  Near(0.001, LVelocity[2], 'z');
  // away from the surface the velocity is divided by the factor
  LVelocity := Vec3(0, 0, 2);
  TPmoveVector.ClipVelocity(LVelocity, Vec3(0, 0, 1), LVelocity, Q3_OVERCLIP);
  Assert.IsTrue(Abs(LVelocity[2]) < 0.01, 'quasi nulla');
end;

procedure TTestPmoveVector.DovrebbeCalcolareIlTempoDiUnPassoComeUnDouble;
var
  LValue: Double;
  LFrame: Single;
begin
  LValue := 66 * Q3_MSEC_TO_SECONDS;
  LFrame := LValue;
  Near(0.066, LFrame, 'passo da 66 msec');
end;

{ TTestPmoveViewAngles }

procedure TTestPmoveViewAngles.DovrebbeConvertireUnAngoloDa16BitInGradi;
begin
  Assert.AreEqual<Single>(90, TPmoveViewAngles.ShortToAngle(16384));
  Assert.AreEqual<Single>(-90, TPmoveViewAngles.ShortToAngle(-16384));
  Assert.AreEqual<Single>(0, TPmoveViewAngles.ShortToAngle(0));
end;

procedure TTestPmoveViewAngles.DovrebbeSommareComandoEDeltaFacendoGirareUnoShort;
var
  LState: TQ3PlayerState;
  LCommand: TQ3UserCmd;
begin
  LState := Default(TQ3PlayerState);
  LState.Stats[Q3_STAT_HEALTH] := 100;
  LCommand := Default(TQ3UserCmd);
  LCommand.Angles[Q3_YAW] := 30000;
  LState.DeltaAngles[Q3_YAW] := 10000;
  TPmoveViewAngles.Update(LState, LCommand);
  // 40000 does not fit a short: -25536
  AssertNear(-25536 * (360.0 / 65536), LState.ViewAngles[Q3_YAW], 1.0E-4, 'angolo');
end;

procedure TTestPmoveViewAngles.DovrebbeTenerePiuInAltoEPiuInBassoDiNovantaGradi;
var
  LState: TQ3PlayerState;
  LCommand: TQ3UserCmd;
begin
  LState := Default(TQ3PlayerState);
  LState.Stats[Q3_STAT_HEALTH] := 100;
  LCommand := Default(TQ3UserCmd);
  LCommand.Angles[Q3_PITCH] := 20000;
  TPmoveViewAngles.Update(LState, LCommand);
  AssertNear(16000 * (360.0 / 65536), LState.ViewAngles[Q3_PITCH], 1.0E-4, 'giu');
  Assert.AreEqual(-4000, LState.DeltaAngles[Q3_PITCH], 'il delta compensa');
  LCommand.Angles[Q3_PITCH] := -20000;
  LState.DeltaAngles[Q3_PITCH] := 0;
  TPmoveViewAngles.Update(LState, LCommand);
  AssertNear(-16000 * (360.0 / 65536), LState.ViewAngles[Q3_PITCH], 1.0E-4, 'su');
  Assert.AreEqual(4000, LState.DeltaAngles[Q3_PITCH]);
end;

procedure TTestPmoveViewAngles.DovrebbeNonCambiareLaVistaInIntermissione;
var
  LState: TQ3PlayerState;
  LCommand: TQ3UserCmd;
  LType: Integer;
begin
  for LType := Q3_PM_INTERMISSION to Q3_PM_SPINTERMISSION do
  begin
    LState := Default(TQ3PlayerState);
    LState.PmType := LType;
    LState.Stats[Q3_STAT_HEALTH] := 100;
    LCommand := Default(TQ3UserCmd);
    LCommand.Angles[Q3_YAW] := 1000;
    TPmoveViewAngles.Update(LState, LCommand);
    AssertNear(0, LState.ViewAngles[Q3_YAW], 0, 'tipo ' + IntToStr(LType));
  end;
end;

procedure TTestPmoveViewAngles.DovrebbeNonCambiareLaVistaDaMortiMaSiDaSpettatori;
var
  LState: TQ3PlayerState;
  LCommand: TQ3UserCmd;
begin
  LState := Default(TQ3PlayerState);
  LState.Stats[Q3_STAT_HEALTH] := 0;
  LCommand := Default(TQ3UserCmd);
  LCommand.Angles[Q3_YAW] := 1000;
  TPmoveViewAngles.Update(LState, LCommand);
  AssertNear(0, LState.ViewAngles[Q3_YAW], 0, 'morto');
  LState.PmType := Q3_PM_SPECTATOR;
  TPmoveViewAngles.Update(LState, LCommand);
  Assert.IsTrue(LState.ViewAngles[Q3_YAW] > 0, 'spettatore');
end;

{ TTestPmoveEvents }

procedure TTestPmoveEvents.Setup;
begin
  FState := TPmoveState.Create(TFakeWorld.Create as IPmoveTrace, nil, TPmoveTuning.Default, nil);
end;

procedure TTestPmoveEvents.TearDown;
begin
  FState.Free;
end;

procedure TTestPmoveEvents.DovrebbeUsareLAnelloDiDueEventi;
var
  LEvents: TPmoveEvents;
begin
  LEvents := TPmoveEvents.Create(FState);
  try
    LEvents.AddEvent(Q3_EV_JUMP);
    LEvents.AddEvent(Q3_EV_STEP_4);
    LEvents.AddEvent(Q3_EV_FOOTSTEP);
    Assert.AreEqual(3, FState.Pm.Ps.EventSequence);
    // the third overwrote the first
    Assert.AreEqual(Q3_EV_FOOTSTEP, FState.Pm.Ps.Events[0]);
    Assert.AreEqual(Q3_EV_STEP_4, FState.Pm.Ps.Events[1]);
    Assert.AreEqual(0, FState.Pm.Ps.EventParms[0]);
  finally
    LEvents.Free;
  end;
end;

procedure TTestPmoveEvents.DovrebbeNonSegnareIlMondoNeUnaEntitaDueVolte;
var
  LEvents: TPmoveEvents;
begin
  LEvents := TPmoveEvents.Create(FState);
  try
    LEvents.AddTouchEnt(Q3_ENTITYNUM_WORLD);
    Assert.AreEqual(0, FState.Pm.NumTouch, 'il mondo no');
    LEvents.AddTouchEnt(7);
    LEvents.AddTouchEnt(7);
    LEvents.AddTouchEnt(9);
    Assert.AreEqual(2, FState.Pm.NumTouch);
    Assert.AreEqual(7, FState.Pm.TouchEnts[0]);
    Assert.AreEqual(9, FState.Pm.TouchEnts[1]);
  finally
    LEvents.Free;
  end;
end;

procedure TTestPmoveEvents.DovrebbeFermarsiATrentaduEntitaToccate;
var
  LEvents: TPmoveEvents;
  LIndex: Integer;
begin
  // a limit the movement cannot reach in one step (a step has a handful of hits); here it is asked directly
  LEvents := TPmoveEvents.Create(FState);
  try
    for LIndex := 1 to 40 do
      LEvents.AddTouchEnt(LIndex);
    Assert.AreEqual(Q3_MAXTOUCH, FState.Pm.NumTouch);
    Assert.AreEqual(32, FState.Pm.TouchEnts[31]);
  finally
    LEvents.Free;
  end;
end;

procedure TTestPmoveEvents.DovrebbeCambiareIlBitDiInversioneDelleAnimazioni;
var
  LEvents: TPmoveEvents;
begin
  LEvents := TPmoveEvents.Create(FState);
  try
    LEvents.StartTorsoAnim(Q3_TORSO_ATTACK);
    Assert.AreEqual(Q3_TORSO_ATTACK or Q3_ANIM_TOGGLEBIT, FState.Pm.Ps.TorsoAnim);
    LEvents.StartTorsoAnim(Q3_TORSO_ATTACK);
    Assert.AreEqual(Q3_TORSO_ATTACK, FState.Pm.Ps.TorsoAnim, 'ripartire la stessa animazione la distingue');
    LEvents.StartLegsAnim(Q3_LEGS_RUN);
    Assert.AreEqual(Q3_LEGS_RUN or Q3_ANIM_TOGGLEBIT, FState.Pm.Ps.LegsAnim);
  finally
    LEvents.Free;
  end;
end;

procedure TTestPmoveEvents.DovrebbeNonCambiareLeAnimazioniDaMorti;
var
  LEvents: TPmoveEvents;
begin
  LEvents := TPmoveEvents.Create(FState);
  try
    FState.Pm.Ps.PmType := Q3_PM_DEAD;
    LEvents.StartTorsoAnim(Q3_TORSO_ATTACK);
    LEvents.StartLegsAnim(Q3_LEGS_RUN);
    Assert.AreEqual(0, FState.Pm.Ps.TorsoAnim);
    Assert.AreEqual(0, FState.Pm.Ps.LegsAnim);
  finally
    LEvents.Free;
  end;
end;

procedure TTestPmoveEvents.DovrebbeRispettareIlTimerDiUnaAnimazioneDiPriorita;
var
  LEvents: TPmoveEvents;
begin
  LEvents := TPmoveEvents.Create(FState);
  try
    FState.Pm.Ps.LegsTimer := 100;
    FState.Pm.Ps.TorsoTimer := 100;
    LEvents.StartLegsAnim(Q3_LEGS_RUN);
    LEvents.ContinueLegsAnim(Q3_LEGS_WALK);
    LEvents.ContinueTorsoAnim(Q3_TORSO_STAND);
    Assert.AreEqual(0, FState.Pm.Ps.LegsAnim, 'le gambe');
    Assert.AreEqual(0, FState.Pm.Ps.TorsoAnim, 'il busto');
    // forcing it ends the timer of the legs
    LEvents.ForceLegsAnim(Q3_LEGS_JUMP);
    Assert.AreEqual(0, FState.Pm.Ps.LegsTimer);
    Assert.AreEqual(Q3_LEGS_JUMP or Q3_ANIM_TOGGLEBIT, FState.Pm.Ps.LegsAnim);
  finally
    LEvents.Free;
  end;
end;

procedure TTestPmoveEvents.DovrebbeNonRipartireDaUnaAnimazioneGiaInCorso;
var
  LEvents: TPmoveEvents;
begin
  LEvents := TPmoveEvents.Create(FState);
  try
    LEvents.StartLegsAnim(Q3_LEGS_WALK);
    LEvents.ContinueLegsAnim(Q3_LEGS_WALK);
    Assert.AreEqual(Q3_LEGS_WALK or Q3_ANIM_TOGGLEBIT, FState.Pm.Ps.LegsAnim, 'il bit non si inverte');
    LEvents.StartTorsoAnim(Q3_TORSO_STAND);
    LEvents.ContinueTorsoAnim(Q3_TORSO_STAND);
    Assert.AreEqual(Q3_TORSO_STAND or Q3_ANIM_TOGGLEBIT, FState.Pm.Ps.TorsoAnim);
  finally
    LEvents.Free;
  end;
end;

{ TTestPmoveItems }

procedure TTestPmoveItems.DovrebbeDareIlTagDegliOggettiDiBaseq3;
var
  LCatalog: IPmoveItemCatalog;
begin
  LCatalog := TPmoveBaseItemCatalog.Create;
  // the weapons come after the armors and the healths: the gauntlet is item 8 (tag 1)
  Assert.AreEqual(Q3_WP_GAUNTLET, LCatalog.GameTag(8));
  Assert.AreEqual(0, LCatalog.GameTag(0));
end;

procedure TTestPmoveItems.DovrebbeDareZeroPerUnIndiceFuoriDallaLista;
var
  LCatalog: IPmoveItemCatalog;
begin
  LCatalog := TPmoveBaseItemCatalog.Create;
  Assert.AreEqual(0, LCatalog.GameTag(-1));
  Assert.AreEqual(0, LCatalog.GameTag(1000));
end;

procedure TTestPmoveItems.DovrebbeDareZeroSenzaCatalogo;
var
  LState: TPmoveState;
begin
  LState := TPmoveState.Create(TFakeWorld.Create as IPmoveTrace, nil, TPmoveTuning.Default, nil);
  try
    Assert.AreEqual(0, LState.ItemTag(5));
  finally
    LState.Free;
  end;
end;

procedure TTestPmoveItems.DovrebbeUsareUnCatalogoDelGioco;
var
  LWorld: TFakeWorld;
  LTrace: IPmoveTrace;
  LMover: IPmove;
  LPmove: TPmove;
begin
  LWorld := TFakeWorld.Create;
  LTrace := LWorld;
  LWorld.AddBox(-1000, -1000, -64, 1000, 1000, 0, Q3_CONTENTS_SOLID);
  LMover := TPmoveFactory.CreateMover(LTrace, TOtherItems.Create as IPmoveItemCatalog, nil);
  LPmove := Default(TPmove);
  LPmove.TraceMask := Q3_MASK_PLAYERSOLID;
  LPmove.Ps.CommandTime := 1000;
  LPmove.Ps.Gravity := 800;
  LPmove.Ps.Origin[2] := 24.125;
  LPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_WORLD;
  LPmove.Ps.Stats[Q3_STAT_HEALTH] := 100;
  LPmove.Ps.Stats[Q3_STAT_MAX_HEALTH] := 100;
  LPmove.Ps.Stats[Q3_STAT_HOLDABLE_ITEM] := 5;
  LPmove.Cmd.ServerTime := 1016;
  LPmove.Cmd.Buttons := Q3_BUTTON_USE_HOLDABLE;
  LMover.Execute(LPmove);
  // the item 5 of this game is a medkit (tag 2): the event is EV_USE_ITEM0 + 2 and the item is gone
  Assert.AreEqual(Q3_EV_USE_ITEM0 + Q3_HI_MEDKIT, LPmove.Ps.Events[0]);
  Assert.AreEqual(0, LPmove.Ps.Stats[Q3_STAT_HOLDABLE_ITEM]);
  Assert.IsTrue((LPmove.Ps.PmFlags and Q3_PMF_USE_ITEM_HELD) <> 0, 'tasto tenuto');
end;

procedure TTestPmoveItems.DovrebbeNonUsareUnMedkitSeLaSaluteELaMassima;
var
  LWorld: TFakeWorld;
  LTrace: IPmoveTrace;
  LMover: IPmove;
  LPmove: TPmove;
begin
  LWorld := TFakeWorld.Create;
  LTrace := LWorld;
  LWorld.AddBox(-1000, -1000, -64, 1000, 1000, 0, Q3_CONTENTS_SOLID);
  LMover := TPmoveFactory.CreateMover(LTrace, TOtherItems.Create as IPmoveItemCatalog, nil);
  LPmove := Default(TPmove);
  LPmove.TraceMask := Q3_MASK_PLAYERSOLID;
  LPmove.Ps.CommandTime := 1000;
  LPmove.Ps.Gravity := 800;
  LPmove.Ps.Origin[2] := 24.125;
  LPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_WORLD;
  LPmove.Ps.Stats[Q3_STAT_HEALTH] := 125;
  LPmove.Ps.Stats[Q3_STAT_MAX_HEALTH] := 100;
  LPmove.Ps.Stats[Q3_STAT_HOLDABLE_ITEM] := 5;
  LPmove.Cmd.ServerTime := 1016;
  LPmove.Cmd.Buttons := Q3_BUTTON_USE_HOLDABLE;
  LMover.Execute(LPmove);
  Assert.AreEqual(5, LPmove.Ps.Stats[Q3_STAT_HOLDABLE_ITEM], 'resta');
  Assert.AreEqual(0, LPmove.Ps.EventSequence, 'nessun evento');
end;

{ TTestPmoveWalkMover }

procedure TTestPmoveWalkMover.DovrebbeNuotareSeVaVersoLAltoDalFondoConLaTestaSottoLAcqua;
var
  LState: TPmoveState;
  LEvents: TPmoveEvents;
  LPhysics: TPmovePhysics;
  LSlider: TPmoveSlider;
  LWalk: TPmoveWalkMover;
  LWater, LAir: TCountingMovement;
begin
  // in the original the dispatcher sends a player with the water level over 1 to the swimming, so the walk never
  // meets a level of 3; the walk still hands over to the swimming in that case
  LState := TPmoveState.Create(TFakeWorld.Create as IPmoveTrace, nil, TPmoveTuning.Default, nil);
  LEvents := TPmoveEvents.Create(LState);
  LPhysics := TPmovePhysics.Create(LState);
  LSlider := TPmoveSlider.Create(LState, LEvents);
  LWater := TCountingMovement.Create;
  LAir := TCountingMovement.Create;
  LWalk := TPmoveWalkMover.Create(LState, LEvents, LPhysics, LSlider, LWater as IPmoveMovement,
    LAir as IPmoveMovement);
  try
    LState.Pm.WaterLevel := 3;
    LState.Pml.GroundTrace.Plane.Normal := Vec3(0, 0, 1);
    LState.Pml.Forward := Vec3(0, 0, 1);
    LWalk.Move;
    Assert.AreEqual(1, LWater.Moves, 'acqua');
    Assert.AreEqual(0, LAir.Moves, 'aria');
  finally
    LWalk.Free;
    LAir.Free;
    LWater.Free;
    LSlider.Free;
    LPhysics.Free;
    LEvents.Free;
    LState.Free;
  end;
end;

procedure TTestPmoveWalkMover.DovrebbeSaltareNellAriaOnellAcquaSecondoLAcqua;
var
  LState: TPmoveState;
  LEvents: TPmoveEvents;
  LPhysics: TPmovePhysics;
  LSlider: TPmoveSlider;
  LWalk: TPmoveWalkMover;
  LWater, LAir: TCountingMovement;
begin
  LState := TPmoveState.Create(TFakeWorld.Create as IPmoveTrace, nil, TPmoveTuning.Default, nil);
  LEvents := TPmoveEvents.Create(LState);
  LPhysics := TPmovePhysics.Create(LState);
  LSlider := TPmoveSlider.Create(LState, LEvents);
  LWater := TCountingMovement.Create;
  LAir := TCountingMovement.Create;
  LWalk := TPmoveWalkMover.Create(LState, LEvents, LPhysics, LSlider, LWater as IPmoveMovement,
    LAir as IPmoveMovement);
  try
    LState.Pm.Cmd.UpMove := 127;
    LState.Pml.GroundTrace.Plane.Normal := Vec3(0, 0, 1);
    LWalk.Move;
    Assert.AreEqual(1, LAir.Moves, 'salto all''asciutto: aria');
    Assert.AreEqual<Integer>(Q3_JUMP_VELOCITY, Round(LState.Velocity^[2]), 'velocita del salto');
    LState.Pm.Ps.PmFlags := 0;
    LState.Pm.WaterLevel := 2;
    LWalk.Move;
    Assert.AreEqual(1, LWater.Moves, 'salto nell''acqua alta: acqua');
  finally
    LWalk.Free;
    LAir.Free;
    LWater.Free;
    LSlider.Free;
    LPhysics.Free;
    LEvents.Free;
    LState.Free;
  end;
end;

{ TTestPmoveTuning }


procedure TTestPmoveTuning.DovrebbeAvereIValoriDiBg_pmove;
var
  LTuning: TPmoveTuning;
begin
  LTuning := TPmoveTuning.Default;
  Assert.AreEqual<Single>(100, LTuning.StopSpeed);
  Assert.AreEqual<Single>(0.25, LTuning.DuckScale);
  Assert.AreEqual<Single>(0.5, LTuning.SwimScale);
  Assert.AreEqual<Single>(0.7, LTuning.WadeScale);
  Assert.AreEqual<Single>(10, LTuning.Accelerate);
  Assert.AreEqual<Single>(1, LTuning.AirAccelerate);
  Assert.AreEqual<Single>(4, LTuning.WaterAccelerate);
  Assert.AreEqual<Single>(8, LTuning.FlyAccelerate);
  Assert.AreEqual<Single>(6, LTuning.Friction);
  Assert.AreEqual<Single>(1, LTuning.WaterFriction);
  Assert.AreEqual<Single>(3, LTuning.FlightFriction);
  Assert.AreEqual<Single>(5, LTuning.SpectatorFriction);
end;

procedure TTestPmoveTuning.DovrebbeUsareLeCostantiInVirgolaMobileDelC;
begin
  // the bits of what the C compiler makes of the constants of bg_pmove.c and bg_local.h
  Assert.AreEqual<Cardinal>($3F8020C5, BitsOfFloat(Q3_OVERCLIP), 'OVERCLIP 1.001f');
  Assert.AreEqual<Cardinal>($3F333333, BitsOfFloat(Q3_MIN_WALK_NORMAL), 'MIN_WALK_NORMAL 0.7f');
  Assert.AreEqual<UInt64>($3F50624DD2F1A9FC, BitsOfDouble(Q3_MSEC_TO_SECONDS), '0.001');
  Assert.AreEqual<UInt64>($3FB999999999999A, BitsOfDouble(Q3_CLIP_INTO), '0.1');
  Assert.AreEqual<UInt64>($3FEFAE147AE147AE, BitsOfDouble(Q3_SAME_PLANE), '0.99');
  Assert.AreEqual<UInt64>($3FE6666666666666, BitsOfDouble(Q3_STEP_NORMAL), '0.7');
  Assert.AreEqual<UInt64>($3F1A36E2EB1C432D, BitsOfDouble(Q3_FALL_SCALE), '0.0001');
  Assert.AreEqual<UInt64>($4008000000000000, BitsOfDouble(Q3_WATER_DIVISOR), '3.0');
  Assert.AreEqual<UInt64>($3FF4CCCCCCCCCCCD, BitsOfDouble(Q3_HASTE_DIVISOR), '1.3');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPmoveVector);
  TDUnitX.RegisterTestFixture(TTestPmoveViewAngles);
  TDUnitX.RegisterTestFixture(TTestPmoveEvents);
  TDUnitX.RegisterTestFixture(TTestPmoveItems);
  TDUnitX.RegisterTestFixture(TTestPmoveWalkMover);
  TDUnitX.RegisterTestFixture(TTestPmoveTuning);

end.
