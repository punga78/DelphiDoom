{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - attack, follow, patrol, projectiles  }
{  and the steps of the actions                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelAttack;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Model.Types,
  DelphiDoom.Tests.War.ModelRig;

type
  /// <summary>Base of the fixtures: a rig whose random numbers are given and a tic that also runs the steps of the actions and the projectiles</summary>
  TAttackFixture = class(TObject)
  protected
    FRig: TModelRig;
    procedure NewRig(const AValues: array of Integer);
    procedure TickAll(ACount: Integer = 1);
    procedure RunAll(ASeconds: Single);
    function Attack(AAttacker, ATarget: Integer): Boolean;
    function ProjectileCount: Integer;
    function Distance(ASlot: Integer; const APoint: TWarVec2): Single;
  public
    [TearDown]
    procedure TearDown;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarAttackState = class(TAttackFixture)
  public
    [Test]
    procedure DovrebbeFerireInMischiaUnBersaglioVicino;
    [Test]
    procedure DovrebbeMancareIlColpoQuandoIlNumeroCasualeELAlto;
    [Test]
    procedure DovrebbeSeguireUnBersaglioFuoriPortata;
    [Test]
    procedure DovrebbeAndareAlPuntoSeNonCeUnBersaglio;
    [Test]
    procedure DovrebbeFinireQuandoIlBersaglioMuore;
    [Test]
    procedure DovrebbeFinireQuandoIlBersaglioNonEsistePiu;
    [Test]
    procedure DovrebbeAspettareSeIlBersaglioELDentroUnEdificio;
    [Test]
    procedure DovrebbeRendereVisibileChiColpisce;
    [Test]
    procedure DovrebbeColpireConIlDannoMinimoAlto;
    [Test]
    procedure DovrebbeSuonareAlMassimoUnaVoltaOgniQuartoDiSecondo;
    [Test]
    procedure DovrebbeRivolgersiVersoIlBersaglio;
    [Test]
    procedure DovrebbeColpireUnEdificioCheCrolla;
    [Test]
    procedure DovrebbeIgnorareUnBersaglioCheNonEUnUnita;
    [Test]
    procedure DovrebbeRegistrareGliStatiEIlCombattimentoNelContesto;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarRangedAttack = class(TAttackFixture)
  public
    [Test]
    procedure DovrebbeLanciareUnaFrecciaECheColpisce;
    [Test]
    procedure DovrebbeSpendereDueDiManaPerColpoDiUnIncantatore;
    [Test]
    procedure DovrebbeSmettereDiAttaccareSenzaMana;
    [Test]
    procedure DovrebbeFarEsplodereLaCatapultaAncheSuiPropri;
    [Test]
    procedure DovrebbeUsareIlTipoDiProiettileDelTipoDiUnita;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarProjectiles = class(TAttackFixture)
  strict private
    function Launch(AType, ASource, ATarget: Integer; AFromX, AFromY, AToX, AToY: Single): Integer;
  public
    [Test]
    procedure DovrebbeVolareAllaVelocitaDelTipoEScomparireAllArrivo;
    [Test]
    procedure DovrebbeGirareLoSpriteSecondoLaDirezione;
    [Test]
    procedure DovrebbeCambiareFotogrammaConLaStrada;
    [Test]
    procedure DovrebbeSaltareIlProiettileDopoQuelloCheArriva;
    [Test]
    procedure DovrebbeFarCadereLaPioggiaDiFuocoSuTuttiInUnaCasella;
    [Test]
    procedure DovrebbeNonColpireIlBersaglioGiaRimosso;
    [Test]
    procedure DovrebbeColpireConUnaPalladiFuocoIlBersaglioDelloScagliatore;
    [Test]
    procedure DovrebbeFermarsiSubitoSeOrigineEBersaglioCoincidono;
    [Test]
    procedure DovrebbeDareZeroSeIlPoolEPieno;
    [Test]
    procedure DovrebbeLasciareLeAnimazioniDelleEsplosioni;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarFollowAndPatrol = class(TAttackFixture)
  public
    [Test]
    procedure DovrebbeSeguireUnaUnitaFinoAllaDistanza;
    [Test]
    procedure DovrebbeFinireSubitoSeEGiaADistanza;
    [Test]
    procedure DovrebbeFinireSeLUnitaSeguitaSparisce;
    [Test]
    procedure DovrebbeSeguireUnPuntoSenzaBersaglio;
    [Test]
    procedure DovrebbeSeguireUnEdificioSenzaUnitaPuntoPiuVicino;
    [Test]
    procedure DovrebbePattugliareAndataERitorno;
    [Test]
    procedure DovrebbeFinireSeLaPattugliaHaUnSoloPunto;
    [Test]
    procedure DovrebbeFinireInIdleSeNonEAllUltimoPunto;
    [Test]
    procedure DovrebbeFermarsiAdAttaccareUnNemicoMentrePattuglia;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarActionSteps = class(TAttackFixture)
  public
    [Test]
    procedure DovrebbeSegnareIlColpoUnaVoltaPerGiroDiAttacco;
    [Test]
    procedure DovrebbeFinireUnAzioneCheNonSiRipete;
    [Test]
    procedure DovrebbeRipetereUnAzioneCheSiRipete;
    [Test]
    procedure DovrebbeFinireUnAzioneCheIlTipoNonHa;
    [Test]
    procedure DovrebbeIgnorareUnUnitaSenzaAzione;
    [Test]
    procedure DovrebbeRiavviareUnAzioneSenzaPassoIniziale;
    [Test]
    procedure DovrebbeAspettareLaFineDellAttesa;
    [Test]
    procedure DovrebbeNotareIlSuonoDelPasso;
    [Test]
    procedure DovrebbeNonFareNienteDopoLaFine;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarTargetGeometry = class(TObject)
  public
    [TestCase('sopra a sinistra', '0,0,16,16')]
    [TestCase('sopra al centro', '35,0,35,16')]
    [TestCase('sopra a destra', '90,0,63,16')]
    [TestCase('a destra', '90,30,63,30')]
    [TestCase('sotto a destra', '90,90,63,47')]
    [TestCase('sotto al centro', '35,90,35,47')]
    [TestCase('sotto a sinistra', '0,90,16,47')]
    [TestCase('a sinistra', '0,30,16,30')]
    [TestCase('dentro', '35,30,35,30')]
    procedure DovrebbeTrovareIlPuntoPiuVicinoDelRettangolo(AX, AY, AExpectedX, AExpectedY: Integer);
  end;

  [TestFixture]
  [Category('war')]
  TTestWarNearUnits = class(TAttackFixture)
  public
    [Test]
    procedure DovrebbeDareLeUnitaVicineCellaPerCellaDallUltimaInserita;
    [Test]
    procedure DovrebbeEscludereLeUnitaCheStannoPerMorire;
    [Test]
    procedure DovrebbeEscludereLeUnitaLontane;
    [Test]
    procedure DovrebbeTenereNelGrigliaLUnitaCheMuoreDopoLaCostruzione;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Sound.Intf, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.World,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.EntityPool,
  DelphiDoom.War.Model.ActionRunner, DelphiDoom.War.Model.ActionSteps.Data, DelphiDoom.War.Model.ActionTable,
  DelphiDoom.War.Model.TargetGeometry, DelphiDoom.War.Model.NearUnits, DelphiDoom.War.Model.Combat.Intf,
  DelphiDoom.War.Model.Projectiles;

{ TAttackFixture }

procedure TAttackFixture.NewRig(const AValues: array of Integer);
begin
  FreeAndNil(FRig);
  FRig := TModelRig.Create(IWarRandom(TScriptedRandom.Create(AValues)));
end;

procedure TAttackFixture.TearDown;
begin
  FreeAndNil(FRig);
end;

procedure TAttackFixture.TickAll(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
  begin
    FRig.World.AdvanceClock(TIC_LENGTH);
    FRig.World.Update;
    FRig.World.UpdateAfterStates;
  end;
end;

procedure TAttackFixture.RunAll(ASeconds: Single);
var
  LEnd: Double;
begin
  LEnd := FRig.World.Context.Clock^.GameTime + ASeconds;
  while FRig.World.Context.Clock^.GameTime < LEnd do
    TickAll;
end;

function TAttackFixture.Attack(AAttacker, ATarget: Integer): Boolean;
var
  LTarget: PWarEntity;
  LState: PWarStateAttack;
begin
  LTarget := FRig.Entity(ATarget);
  LState := FRig.World.Machine.CreateAttack(AAttacker, LTarget^.Id, TWarUnitGeometry.CenterPosition(LTarget));
  Result := FRig.World.Machine.ResetState(AAttacker, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
end;

function TAttackFixture.ProjectileCount: Integer;
begin
  Result := FRig.World.Context.Pool.OfType[WAR_ENTITY_PROJECTILE].Count;
end;

function TAttackFixture.Distance(ASlot: Integer; const APoint: TWarVec2): Single;
begin
  Result := TWarModelMath.Length(TWarModelMath.Sub(TWarUnitGeometry.CenterPosition(FRig.Entity(ASlot)), APoint));
end;

{ TTestWarAttackState }

procedure TTestWarAttackState.DovrebbeFerireInMischiaUnBersaglioVicino;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 11, 10, 1);
  Assert.IsTrue(Attack(LAttacker, LTarget));
  RunAll(2);
  Assert.IsTrue(FRig.Entity(LTarget)^.UnitData.Hp < FRig.Entity(LTarget)^.UnitData.MaxHp);
  Assert.IsTrue(FRig.Observer.AttackSounds > 0);
  Assert.AreEqual<Integer>(WAR_ACTION_ATTACK, FRig.Entity(LAttacker)^.UnitData.ActionType);
end;

procedure TTestWarAttackState.DovrebbeMancareIlColpoQuandoIlNumeroCasualeELAlto;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  // 99 is never below 80: no blow lands (and no unit looks around)
  FreeAndNil(FRig);
  FRig := TModelRig.Create(IWarRandom(TScriptedRandom.Create([99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99])));
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 11, 10, 1);
  Attack(LAttacker, LTarget);
  RunAll(0.5);
  Assert.AreEqual<Integer>(FRig.Entity(LTarget)^.UnitData.MaxHp, FRig.Entity(LTarget)^.UnitData.Hp);
end;

procedure TTestWarAttackState.DovrebbeSeguireUnBersaglioFuoriPortata;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  // a peasant: a warrior would come out to meet the attacker
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_PEASANT, 15, 5, 1);
  Attack(LAttacker, LTarget);
  TickAll(3);
  Assert.IsTrue(FRig.World.Machine.Contains(LAttacker, WAR_STATE_FOLLOW));
  RunAll(25);
  // the peasant dies (and its corpse is removed)
  Assert.IsTrue(FRig.Observer.Died > 0);
end;

procedure TTestWarAttackState.DovrebbeAndareAlPuntoSeNonCeUnBersaglio;
var
  LAttacker: Integer;
  LState: PWarStateAttack;
  LPoint: TWarVec2;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LPoint := TWarModelMath.Vec(10 * 16 + 8, 5 * 16 + 8);
  LState := FRig.World.Machine.CreateAttack(LAttacker, 0, LPoint);
  FRig.World.Machine.ResetState(LAttacker, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  TickAll(3);
  Assert.IsTrue(FRig.World.Machine.Contains(LAttacker, WAR_STATE_MOVE));
  RunAll(12);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LAttacker));
  Assert.IsTrue(Distance(LAttacker, LPoint) < 24);
end;

procedure TTestWarAttackState.DovrebbeFinireQuandoIlBersaglioMuore;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 11, 10, 1);
  Attack(LAttacker, LTarget);
  TickAll(2);
  FRig.World.Combat.TakeDamage(LTarget, 255, 0);
  RunAll(3);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LAttacker));
end;

procedure TTestWarAttackState.DovrebbeFinireQuandoIlBersaglioNonEsistePiu;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 11, 10, 1);
  Attack(LAttacker, LTarget);
  TickAll(2);
  FRig.World.Entities.RemoveEntity(LTarget);
  RunAll(2);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LAttacker));
end;

procedure TTestWarAttackState.DovrebbeAspettareSeIlBersaglioELDentroUnEdificio;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 7, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_PEON, 8, 5, 1);
  FRig.World.Machine.PushState(LTarget, FRig.World.Machine.AllocState(LTarget, WAR_STATE_MINING), WAR_CAUSE_AI_ORDER);
  TickAll(2);
  Attack(LAttacker, LTarget);
  TickAll(3);
  Assert.IsTrue(FRig.World.Machine.Contains(LAttacker, WAR_STATE_WAIT));
  Assert.AreEqual<Integer>(FRig.Entity(LTarget)^.UnitData.MaxHp, FRig.Entity(LTarget)^.UnitData.Hp);
end;

procedure TTestWarAttackState.DovrebbeRendereVisibileChiColpisce;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 11, 10, 1);
  FRig.Entity(LAttacker)^.UnitData.Invisible := True;
  FRig.Entity(LAttacker)^.UnitData.InvisibilityTime := 5;
  Attack(LAttacker, LTarget);
  RunAll(2);
  Assert.IsFalse(FRig.Entity(LAttacker)^.UnitData.Invisible);
  Assert.IsTrue(FRig.Entity(LAttacker)^.UnitData.InvisibilityTime = 0);
end;

procedure TTestWarAttackState.DovrebbeColpireConIlDannoMinimoAlto;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  FRig.World.Context.Players[0]^.GodMode := True;
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 11, 10, 1);
  Attack(LAttacker, LTarget);
  RunAll(3);
  Assert.IsTrue(FRig.Observer.Died > 0);
  Assert.AreEqual<Integer>(0, FRig.Entity(LTarget)^.UnitData.Hp);
end;

procedure TTestWarAttackState.DovrebbeSuonareAlMassimoUnaVoltaOgniQuartoDiSecondo;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_OGRE, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_SLIME, 11, 10, 1);
  Attack(LAttacker, LTarget);
  RunAll(4);
  Assert.IsTrue(FRig.Observer.AttackSounds >= 1);
  Assert.IsTrue(FRig.Observer.AttackSounds <= 16);
  Assert.IsTrue(FRig.Observer.LastSoundStep >= WAR_ACTION_STEP_SOUND_SWORD);
end;

procedure TTestWarAttackState.DovrebbeRivolgersiVersoIlBersaglio;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 10, 11, 1);
  Attack(LAttacker, LTarget);
  TickAll(3);
  Assert.AreEqual<Integer>(WAR_DIRECTION_SOUTH, FRig.Entity(LAttacker)^.UnitData.Direction);
end;

procedure TTestWarAttackState.DovrebbeColpireUnEdificioCheCrolla;
var
  LAttacker: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_OGRE, 10, 10, 0);
  LTarget := FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 11, 10, 1);
  FRig.Entity(LTarget)^.UnitData.Hp := 1;
  Attack(LAttacker, LTarget);
  RunAll(3);
  Assert.IsTrue(FRig.Observer.Collapsing > 0);
end;

procedure TTestWarAttackState.DovrebbeIgnorareUnBersaglioCheNonEUnUnita;
var
  LAttacker: Integer;
  LNote: Integer;
  LState: PWarStateAttack;
begin
  NewRig([]);
  LAttacker := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  // an animation entity is an entity that is not a unit (the walls will be one)
  LNote := FRig.World.Context.Pool.CreateEntity(WAR_ENTITY_ANIMATION, True);
  LState := FRig.World.Machine.CreateAttack(LAttacker, FRig.Entity(LNote)^.Id, TWarModelMath.Vec(170, 170));
  FRig.World.Machine.ResetState(LAttacker, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  RunAll(1);
  Assert.IsTrue(FRig.World.Machine.IsAttacking(LAttacker));
  Assert.AreEqual<Integer>(0, FRig.Observer.AttackSounds);
end;

procedure TTestWarAttackState.DovrebbeRegistrareGliStatiEIlCombattimentoNelContesto;
begin
  NewRig([]);
  Assert.IsTrue(Assigned(FRig.World.Context.Combat));
  Assert.IsTrue(Assigned(FRig.World.Context.CombatEvents));
  Assert.IsTrue(Assigned(FRig.World.Machine.Descriptors[WAR_STATE_ATTACK].UpdateAll));
  Assert.IsTrue(Assigned(FRig.World.Machine.Descriptors[WAR_STATE_FOLLOW].UpdateAll));
  Assert.IsTrue(Assigned(FRig.World.Machine.Descriptors[WAR_STATE_PATROL].OnEnter));
end;

{ TTestWarRangedAttack }

procedure TTestWarRangedAttack.DovrebbeLanciareUnaFrecciaECheColpisce;
var
  LArcher: Integer;
  LTarget: Integer;
  LTics: Integer;
begin
  NewRig([]);
  LArcher := FRig.AddDude(WAR_UNIT_ARCHER, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 9, 5, 1);
  Attack(LArcher, LTarget);
  LTics := 0;
  while (ProjectileCount = 0) and (LTics < 600) do
  begin
    TickAll;
    Inc(LTics);
  end;
  Assert.AreEqual<Integer>(1, ProjectileCount);
  Assert.AreEqual<Integer>(WAR_PROJECTILE_ARROW,
    FRig.World.Context.Pool.Slots[FRig.World.Context.Pool.OfType[WAR_ENTITY_PROJECTILE][0]]^.Projectile.ProjectileType);
  RunAll(3);
  Assert.IsTrue(FRig.Observer.ArrowHits > 0);
  Assert.IsTrue(FRig.Entity(LTarget)^.UnitData.Hp < FRig.Entity(LTarget)^.UnitData.MaxHp);
end;

procedure TTestWarRangedAttack.DovrebbeSpendereDueDiManaPerColpoDiUnIncantatore;
var
  LCaster: Integer;
  LTarget: Integer;
  LMana: Integer;
begin
  NewRig([]);
  LCaster := FRig.AddDude(WAR_UNIT_CONJURER, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_OGRE, 7, 5, 1);
  LMana := FRig.Entity(LCaster)^.UnitData.Mana;
  Attack(LCaster, LTarget);
  RunAll(3);
  Assert.IsTrue(FRig.Entity(LCaster)^.UnitData.Mana < LMana);
  Assert.AreEqual<Integer>(0, (LMana - FRig.Entity(LCaster)^.UnitData.Mana) mod 2);
end;

procedure TTestWarRangedAttack.DovrebbeSmettereDiAttaccareSenzaMana;
var
  LCaster: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LCaster := FRig.AddDude(WAR_UNIT_CONJURER, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_OGRE, 7, 5, 1);
  FRig.Entity(LCaster)^.UnitData.Mana := 0;
  Attack(LCaster, LTarget);
  RunAll(3);
  // it goes idle, sees the ogre and attacks again, and so on: it never shoots
  Assert.IsTrue(FRig.Observer.FlashCount > 0);
  Assert.AreEqual<Integer>(0, ProjectileCount);
  Assert.AreEqual<Integer>(0, FRig.Entity(LCaster)^.UnitData.Mana);
end;

procedure TTestWarRangedAttack.DovrebbeFarEsplodereLaCatapultaAncheSuiPropri;
var
  LCatapult: Integer;
  LTarget: Integer;
  LFriend: Integer;
begin
  // the splash does not ask who is the enemy: a friend near the target is hit
  NewRig([]);
  LCatapult := FRig.AddDude(WAR_UNIT_CATAPULT_ORCS, 2, 5, 1);
  LTarget := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 8, 5, 0);
  LFriend := FRig.AddDude(WAR_UNIT_PEON, 8, 7, 1);
  Attack(LCatapult, LTarget);
  RunAll(10);
  Assert.IsTrue(FRig.Observer.Explosions > 0, Format('expl %d active %d proj %d', [FRig.Observer.Explosions,
    FRig.ActiveType(LCatapult), ProjectileCount]));
  // the friend dies of it (and its corpse is removed: the slot is free)
  Assert.IsTrue(FRig.Observer.Died > 0);
  Assert.IsTrue(LFriend > 0);
  Assert.IsTrue(FRig.World.Context.Pool.OfType[WAR_ENTITY_ANIMATION].Count > 0, 'animation');
end;

procedure TTestWarRangedAttack.DovrebbeUsareIlTipoDiProiettileDelTipoDiUnita;
begin
  Assert.AreEqual<Integer>(WAR_PROJECTILE_ARROW, TWarProjectiles.TypeOfUnit(WAR_UNIT_SPEARMAN));
  Assert.AreEqual<Integer>(WAR_PROJECTILE_CATAPULT, TWarProjectiles.TypeOfUnit(WAR_UNIT_CATAPULT_HUMANS));
  Assert.AreEqual<Integer>(WAR_PROJECTILE_FIREBALL, TWarProjectiles.TypeOfUnit(WAR_UNIT_NECROLYTE));
  Assert.AreEqual<Integer>(WAR_PROJECTILE_WATER_ELEMENTAL, TWarProjectiles.TypeOfUnit(WAR_UNIT_WATER_ELEMENTAL));
  // a unit that does not shoot throws an arrow (the original warns)
  Assert.AreEqual<Integer>(WAR_PROJECTILE_ARROW, TWarProjectiles.TypeOfUnit(WAR_UNIT_FOOTMAN));
end;

{ TTestWarProjectiles }

function TTestWarProjectiles.Launch(AType, ASource, ATarget: Integer; AFromX, AFromY, AToX, AToY: Single): Integer;
var
  LSourceId: Word;
  LTargetId: Word;
begin
  LSourceId := 0;
  LTargetId := 0;
  if ASource <> 0 then
    LSourceId := FRig.Entity(ASource)^.Id;
  if ATarget <> 0 then
    LTargetId := FRig.Entity(ATarget)^.Id;
  Result := FRig.World.Context.Combat.CreateProjectile(AType, LSourceId, LTargetId,
    TWarModelMath.Vec(AFromX, AFromY), TWarModelMath.Vec(AToX, AToY));
end;

procedure TTestWarProjectiles.DovrebbeVolareAllaVelocitaDelTipoEScomparireAllArrivo;
var
  LSlot: Integer;
  LStart: Integer;
begin
  NewRig([]);
  LStart := FRig.World.Context.Pool.EntityCount;
  LSlot := Launch(WAR_PROJECTILE_ARROW, 0, 0, 0, 100, 128, 100);
  Assert.AreEqual<Integer>(WAR_ENTITY_PROJECTILE, FRig.Entity(LSlot)^.EntityType);
  Assert.AreEqual<Integer>(128, FRig.Entity(LSlot)^.Projectile.Speed);
  TickAll(30);
  // 30 tics of 1/60 s at 128 pixels per second: 64 pixels
  Assert.IsTrue(Abs(FRig.Entity(LSlot)^.Position.X - 64) < 0.01);
  RunAll(1);
  Assert.AreEqual<Integer>(0, ProjectileCount);
  Assert.AreEqual<Integer>(LStart, FRig.World.Context.Pool.EntityCount);
  Assert.AreEqual<Integer>(1, FRig.Observer.ArrowHits);
end;

procedure TTestWarProjectiles.DovrebbeGirareLoSpriteSecondoLaDirezione;
var
  LEast: Integer;
  LWest: Integer;
  LNorth: Integer;
  LSouthEast: Integer;
begin
  NewRig([]);
  LEast := Launch(WAR_PROJECTILE_ARROW, 0, 0, 0, 100, 400, 100);
  LWest := Launch(WAR_PROJECTILE_ARROW, 0, 0, 400, 200, 0, 200);
  LNorth := Launch(WAR_PROJECTILE_ARROW, 0, 0, 200, 400, 200, 0);
  LSouthEast := Launch(WAR_PROJECTILE_ARROW, 0, 0, 0, 0, 400, 400);
  TickAll;
  Assert.AreEqual<Integer>(2, FRig.Entity(LEast)^.Projectile.FrameIndex);
  Assert.IsFalse(FRig.Entity(LEast)^.Projectile.FlipX);
  Assert.IsTrue(FRig.Entity(LWest)^.Projectile.FlipX);
  Assert.AreEqual<Integer>(0, FRig.Entity(LNorth)^.Projectile.FrameIndex);
  Assert.AreEqual<Integer>(3, FRig.Entity(LSouthEast)^.Projectile.FrameIndex);
  Assert.IsFalse(FRig.Entity(LSouthEast)^.Projectile.FlipX);
end;

procedure TTestWarProjectiles.DovrebbeCambiareFotogrammaConLaStrada;
var
  LFireball: Integer;
  LCatapult: Integer;
  LRain: Integer;
begin
  NewRig([]);
  LFireball := Launch(WAR_PROJECTILE_FIREBALL, 0, 0, 0, 100, 1000, 100);
  LCatapult := Launch(WAR_PROJECTILE_CATAPULT, 0, 0, 0, 200, 1000, 200);
  LRain := Launch(WAR_PROJECTILE_RAIN_OF_FIRE, 0, 0, 0, 300, 1000, 300);
  TickAll(2);
  Assert.AreEqual<Integer>(2, FRig.Entity(LFireball)^.Projectile.FrameIndex);
  Assert.AreEqual<Integer>(2, FRig.Entity(LCatapult)^.Projectile.FrameIndex);
  Assert.AreEqual<Integer>(0, FRig.Entity(LRain)^.Projectile.FrameIndex);
  // a rain of fire at the end of its way is on its last frame
  FRig.Entity(LRain)^.Position := TWarModelMath.Vec(700, 300);
  FRig.Entity(LFireball)^.Position := TWarModelMath.Vec(900, 100);
  FRig.Entity(LCatapult)^.Position := TWarModelMath.Vec(500, 200);
  TickAll;
  Assert.AreEqual<Integer>(2, FRig.Entity(LRain)^.Projectile.FrameIndex);
  Assert.AreEqual<Integer>(2 + 4 * 5, FRig.Entity(LFireball)^.Projectile.FrameIndex);
  Assert.AreEqual<Integer>(2 + 2 * 5, FRig.Entity(LCatapult)^.Projectile.FrameIndex);
end;

procedure TTestWarProjectiles.DovrebbeSaltareIlProiettileDopoQuelloCheArriva;
var
  LFirst: Integer;
begin
  // the list is walked while the arrived projectile leaves it: the second one waits a tic (defect of the original, kept)
  NewRig([]);
  Launch(WAR_PROJECTILE_ARROW, 0, 0, 0, 100, 1, 100);
  Launch(WAR_PROJECTILE_ARROW, 0, 0, 0, 200, 1, 200);
  LFirst := ProjectileCount;
  Assert.AreEqual<Integer>(2, LFirst);
  TickAll;
  Assert.AreEqual<Integer>(1, ProjectileCount);
  Assert.AreEqual<Integer>(1, FRig.Observer.ArrowHits);
  TickAll;
  Assert.AreEqual<Integer>(0, ProjectileCount);
  Assert.AreEqual<Integer>(2, FRig.Observer.ArrowHits);
end;

procedure TTestWarProjectiles.DovrebbeFarCadereLaPioggiaDiFuocoSuTuttiInUnaCasella;
var
  LNear: Integer;
  LFar: Integer;
  LOwn: Integer;
begin
  NewRig([]);
  LNear := FRig.AddDude(WAR_UNIT_PEON, 10, 10, 1);
  LOwn := FRig.AddDude(WAR_UNIT_PEASANT, 11, 11, 0);
  LFar := FRig.AddDude(WAR_UNIT_PEON, 15, 15, 1);
  Launch(WAR_PROJECTILE_RAIN_OF_FIRE, 0, 0, 10 * 16 + 8, 10 * 16 - 100, 10 * 16 + 8, 10 * 16 + 8);
  RunAll(2);
  Assert.AreEqual<Integer>(FRig.Entity(LNear)^.UnitData.MaxHp - 10, FRig.Entity(LNear)^.UnitData.Hp);
  Assert.AreEqual<Integer>(FRig.Entity(LOwn)^.UnitData.MaxHp - 10, FRig.Entity(LOwn)^.UnitData.Hp);
  Assert.AreEqual<Integer>(FRig.Entity(LFar)^.UnitData.MaxHp, FRig.Entity(LFar)^.UnitData.Hp);
  Assert.AreEqual<Integer>(1, FRig.Observer.Explosions);
end;

procedure TTestWarProjectiles.DovrebbeNonColpireIlBersaglioGiaRimosso;
var
  LSource: Integer;
  LTarget: Integer;
  LHp: Integer;
begin
  NewRig([]);
  LSource := FRig.AddDude(WAR_UNIT_ARCHER, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_GRUNT, 6, 5, 1);
  Launch(WAR_PROJECTILE_ARROW, LSource, LTarget, 100, 100, 101, 100);
  LHp := FRig.Entity(LTarget)^.UnitData.MaxHp;
  FRig.World.Entities.RemoveEntity(LTarget);
  TickAll(3);
  Assert.AreEqual<Integer>(0, ProjectileCount);
  Assert.AreEqual<Integer>(1, FRig.Observer.ArrowHits);
  Assert.IsTrue(LHp > 0);
end;

procedure TTestWarProjectiles.DovrebbeColpireConUnaPalladiFuocoIlBersaglioDelloScagliatore;
var
  LSource: Integer;
  LTarget: Integer;
begin
  NewRig([]);
  LSource := FRig.AddDude(WAR_UNIT_WARLOCK, 5, 5, 1);
  LTarget := FRig.AddDude(WAR_UNIT_FOOTMAN, 6, 5, 0);
  Launch(WAR_PROJECTILE_FIREBALL_2, LSource, LTarget, 100, 100, 101, 100);
  TickAll(3);
  Assert.IsTrue(FRig.Entity(LTarget)^.UnitData.Hp < FRig.Entity(LTarget)^.UnitData.MaxHp);
  Assert.AreEqual<Integer>(0, FRig.Observer.ArrowHits);
end;

procedure TTestWarProjectiles.DovrebbeFermarsiSubitoSeOrigineEBersaglioCoincidono;
begin
  NewRig([]);
  Launch(WAR_PROJECTILE_FIREBALL, 0, 0, 100, 100, 100, 100);
  TickAll;
  Assert.AreEqual<Integer>(0, ProjectileCount);
end;

procedure TTestWarProjectiles.DovrebbeDareZeroSeIlPoolEPieno;
var
  LIndex: Integer;
begin
  NewRig([]);
  for LIndex := 1 to WAR_MODEL_MAX_ENTITIES do
    if FRig.World.Context.Pool.CreateEntity(WAR_ENTITY_ANIMATION, True) = 0 then
      Break;
  Assert.AreEqual<Integer>(0, Launch(WAR_PROJECTILE_ARROW, 0, 0, 0, 0, 10, 10));
end;

procedure TTestWarProjectiles.DovrebbeLasciareLeAnimazioniDelleEsplosioni;
begin
  // defect of the original kept: an explosion makes an animation entity that nobody removes
  NewRig([]);
  Launch(WAR_PROJECTILE_CATAPULT, 0, 0, 0, 100, 1, 100);
  Launch(WAR_PROJECTILE_RAIN_OF_FIRE, 0, 0, 0, 200, 1, 200);
  RunAll(1);
  Assert.AreEqual<Integer>(2, FRig.World.Context.Pool.OfType[WAR_ENTITY_ANIMATION].Count);
  Assert.AreEqual<Integer>(0, ProjectileCount);
end;

{ TTestWarFollowAndPatrol }

procedure TTestWarFollowAndPatrol.DovrebbeSeguireUnaUnitaFinoAllaDistanza;
var
  LFollower: Integer;
  LTarget: Integer;
  LState: PWarStateFollow;
begin
  NewRig([]);
  LFollower := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_PEASANT, 12, 5, 0);
  LState := FRig.World.Machine.CreateFollow(LFollower, FRig.Entity(LTarget)^.Id, TWarModelMath.Vec(0, 0), 32);
  FRig.World.Machine.ResetState(LFollower, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  TickAll(3);
  Assert.IsTrue(FRig.World.Machine.Contains(LFollower, WAR_STATE_MOVE));
  RunAll(12);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFollower));
  Assert.IsTrue(Distance(LFollower, TWarUnitGeometry.CenterPosition(FRig.Entity(LTarget))) <= 32);
end;

procedure TTestWarFollowAndPatrol.DovrebbeFinireSubitoSeEGiaADistanza;
var
  LFollower: Integer;
  LTarget: Integer;
  LState: PWarStateFollow;
begin
  NewRig([]);
  LFollower := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_PEASANT, 6, 5, 0);
  LState := FRig.World.Machine.CreateFollow(LFollower, FRig.Entity(LTarget)^.Id, TWarModelMath.Vec(0, 0), 64);
  FRig.World.Machine.ResetState(LFollower, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  TickAll(3);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFollower));
  Assert.IsFalse(FRig.World.Machine.Contains(LFollower, WAR_STATE_MOVE));
end;

procedure TTestWarFollowAndPatrol.DovrebbeFinireSeLUnitaSeguitaSparisce;
var
  LFollower: Integer;
  LTarget: Integer;
  LState: PWarStateFollow;
begin
  NewRig([]);
  LFollower := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LTarget := FRig.AddDude(WAR_UNIT_PEASANT, 20, 5, 0);
  LState := FRig.World.Machine.CreateFollow(LFollower, FRig.Entity(LTarget)^.Id, TWarModelMath.Vec(0, 0), 16);
  FRig.World.Machine.ResetState(LFollower, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  TickAll(2);
  FRig.World.Entities.RemoveEntity(LTarget);
  // the move is on top: it has to end before the follow sees that the target is gone
  RunAll(25);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFollower));
  Assert.IsFalse(FRig.World.Machine.Contains(LFollower, WAR_STATE_FOLLOW));
end;

procedure TTestWarFollowAndPatrol.DovrebbeSeguireUnPuntoSenzaBersaglio;
var
  LFollower: Integer;
  LPoint: TWarVec2;
  LState: PWarStateFollow;
begin
  NewRig([]);
  LFollower := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LPoint := TWarModelMath.Vec(10 * 16 + 8, 5 * 16 + 8);
  LState := FRig.World.Machine.CreateFollow(LFollower, 0, LPoint, 16);
  FRig.World.Machine.ResetState(LFollower, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  RunAll(12);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFollower));
  Assert.IsTrue(Distance(LFollower, LPoint) <= 16);
end;

procedure TTestWarFollowAndPatrol.DovrebbeSeguireUnEdificioSenzaUnitaPuntoPiuVicino;
var
  LFollower: Integer;
  LTarget: Integer;
  LNote: Integer;
  LState: PWarStateFollow;
begin
  NewRig([]);
  LFollower := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LTarget := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 8, 5, 0);
  LState := FRig.World.Machine.CreateFollow(LFollower, FRig.Entity(LTarget)^.Id, TWarModelMath.Vec(0, 0), 16);
  FRig.World.Machine.ResetState(LFollower, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  RunAll(10);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LFollower));
  // a target that is not a unit: its position
  LNote := FRig.World.Context.Pool.CreateEntity(WAR_ENTITY_ANIMATION, True);
  FRig.Entity(LNote)^.Position := TWarModelMath.Vec(300, 80);
  LState := FRig.World.Machine.CreateFollow(LFollower, FRig.Entity(LNote)^.Id, TWarModelMath.Vec(0, 0), 16);
  FRig.World.Machine.ResetState(LFollower, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  RunAll(20);
  Assert.IsTrue(Distance(LFollower, TWarModelMath.Vec(300, 80)) <= 16);
end;

procedure TTestWarFollowAndPatrol.DovrebbePattugliareAndataERitorno;
var
  LUnit: Integer;
  LStart: TWarVec2;
  LEnd: TWarVec2;
  LState: PWarStatePatrol;
  LFound: PWarStateBase;
  LTics: Integer;
begin
  NewRig([99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99]);
  LUnit := FRig.AddDude(WAR_UNIT_PEASANT, 5, 5, 0);
  LStart := TWarUnitGeometry.CenterPosition(FRig.Entity(LUnit));
  LEnd := TWarModelMath.Vec(10 * 16 + 8, 5 * 16 + 8);
  LState := FRig.World.Machine.CreatePatrol(LUnit, [LStart, LEnd]);
  FRig.World.Machine.ResetState(LUnit, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  RunAll(3);
  Assert.IsTrue(FRig.World.Machine.Contains(LUnit, WAR_STATE_PATROL));
  Assert.IsTrue(Distance(LUnit, LEnd) > 1);
  // back and forth: the list is reversed each time a leg ends
  LTics := 0;
  LFound := FRig.World.Machine.FindState(LUnit, WAR_STATE_PATROL);
  while (PWarStatePatrol(LFound)^.Dir > 0) and (LTics < 1200) do
  begin
    TickAll;
    Inc(LTics);
  end;
  Assert.AreEqual<Integer>(-1, PWarStatePatrol(LFound)^.Dir);
  Assert.IsTrue(Distance(LUnit, LEnd) < 1);
  while (PWarStatePatrol(LFound)^.Dir < 0) and (LTics < 3000) do
  begin
    TickAll;
    Inc(LTics);
  end;
  Assert.AreEqual<Integer>(1, PWarStatePatrol(LFound)^.Dir);
  Assert.IsTrue(Distance(LUnit, LStart) < 1);
end;

procedure TTestWarFollowAndPatrol.DovrebbeFinireSeLaPattugliaHaUnSoloPunto;
var
  LUnit: Integer;
  LState: PWarStatePatrol;
begin
  NewRig([]);
  LUnit := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LState := FRig.World.Machine.CreatePatrol(LUnit, [TWarUnitGeometry.CenterPosition(FRig.Entity(LUnit))]);
  FRig.World.Machine.ResetState(LUnit, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  TickAll(4);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LUnit));
  Assert.IsFalse(FRig.World.Machine.Contains(LUnit, WAR_STATE_PATROL));
end;

procedure TTestWarFollowAndPatrol.DovrebbeFinireInIdleSeNonEAllUltimoPunto;
var
  LUnit: Integer;
  LStart: TWarVec2;
  LState: PWarStatePatrol;
  LFound: PWarStatePatrol;
begin
  NewRig([99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99]);
  LUnit := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LStart := TWarUnitGeometry.CenterPosition(FRig.Entity(LUnit));
  LState := FRig.World.Machine.CreatePatrol(LUnit, [LStart, TWarModelMath.Vec(8 * 16 + 8, 5 * 16 + 8)]);
  FRig.World.Machine.ResetState(LUnit, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  TickAll(5);
  // the move gave up somewhere else (here: the last point of the patrol is changed under it)
  LFound := PWarStatePatrol(FRig.World.Machine.FindState(LUnit, WAR_STATE_PATROL));
  LFound^.Waypoints[1] := TWarModelMath.Vec(30 * 16, 30 * 16);
  RunAll(8);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(LUnit));
  Assert.IsFalse(FRig.World.Machine.Contains(LUnit, WAR_STATE_PATROL));
end;

procedure TTestWarFollowAndPatrol.DovrebbeFermarsiAdAttaccareUnNemicoMentrePattuglia;
var
  LPatroller: Integer;
  LEnemy: Integer;
  LState: PWarStatePatrol;
  LStart: TWarVec2;
begin
  NewRig([]);
  LPatroller := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LStart := TWarUnitGeometry.CenterPosition(FRig.Entity(LPatroller));
  LState := FRig.World.Machine.CreatePatrol(LPatroller, [LStart, TWarModelMath.Vec(20 * 16 + 8, 5 * 16 + 8)]);
  FRig.World.Machine.ResetState(LPatroller, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER);
  LEnemy := FRig.AddDude(WAR_UNIT_PEON, 12, 5, 1);
  FRig.World.Machine.PushState(LEnemy,
    PWarStateBase(FRig.World.Machine.CreateAttack(LEnemy, FRig.Entity(LPatroller)^.Id, LStart)), WAR_CAUSE_AI_ORDER);
  RunAll(8);
  Assert.IsTrue(FRig.World.Machine.Contains(LPatroller, WAR_STATE_ATTACK) or
    (FRig.Entity(LEnemy)^.UnitData.Hp < FRig.Entity(LEnemy)^.UnitData.MaxHp));
end;

{ TTestWarActionSteps }

procedure TTestWarActionSteps.DovrebbeSegnareIlColpoUnaVoltaPerGiroDiAttacco;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LTime: Double;
  LBlows: Integer;
  LIndex: Integer;
  LWas: Boolean;
  LIs: Boolean;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_ATTACK, True, 1.0);
  LTime := 0;
  LBlows := 0;
  LWas := False;
  for LIndex := 1 to 300 do
  begin
    LTime := LTime + 1 / 60;
    TWarActionRunner.Update(FRig.Entity(LSlot), LTime);
    LIs := LUnit^.Actions[WAR_ACTION_ATTACK].LastActionStep = WAR_ACTION_STEP_ATTACK;
    if LIs and not LWas then
      Inc(LBlows);
    LWas := LIs;
  end;
  // the attack of a footman lasts 32 frames (about half a second): one blow for each turn in 5 seconds
  Assert.IsTrue((LBlows >= 6) and (LBlows <= 8), IntToStr(LBlows));
end;

procedure TTestWarActionSteps.DovrebbeFinireUnAzioneCheNonSiRipete;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LTime: Double;
  LIndex: Integer;
  LType: Integer;
  LAction: Integer;
  LFoundType: Integer;
  LFoundAction: Integer;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  // the first definition of the tables that does not repeat; the unit takes that type for the test
  LFoundType := -1;
  LFoundAction := -1;
  for LType := 0 to WAR_UNIT_COUNT - 1 do
    for LAction := 0 to WAR_ACTION_TYPE_COUNT - 1 do
      if (LFoundType < 0) and WAR_ACTION_DEF_DATA[LType, LAction].Present and
        not WAR_ACTION_DEF_DATA[LType, LAction].Loop then
      begin
        LFoundType := LType;
        LFoundAction := LAction;
      end;
  Assert.IsTrue(LFoundType >= 0);
  LUnit^.UnitType := LFoundType;
  TWarActionTable.SetAction(LUnit^, LFoundAction, True, 1.0);
  LTime := 0;
  for LIndex := 1 to 1200 do
  begin
    LTime := LTime + 1 / 60;
    TWarActionRunner.Update(FRig.Entity(LSlot), LTime);
    if LUnit^.Actions[LFoundAction].Status = WAR_ACTION_FINISHED then
      Break;
  end;
  Assert.AreEqual<Integer>(WAR_ACTION_FINISHED, LUnit^.Actions[LFoundAction].Status);
end;

procedure TTestWarActionSteps.DovrebbeRipetereUnAzioneCheSiRipete;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LTime: Double;
  LIndex: Integer;
  LWrapped: Boolean;
  LLast: Integer;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_WALK, True, 1.0);
  LTime := 0;
  LWrapped := False;
  LLast := 0;
  for LIndex := 1 to 600 do
  begin
    LTime := LTime + 1 / 60;
    TWarActionRunner.Update(FRig.Entity(LSlot), LTime);
    if LUnit^.Actions[WAR_ACTION_WALK].StepIndex < LLast then
      LWrapped := True;
    LLast := LUnit^.Actions[WAR_ACTION_WALK].StepIndex;
  end;
  Assert.IsTrue(LWrapped);
  Assert.AreEqual<Integer>(WAR_ACTION_RUNNING, LUnit^.Actions[WAR_ACTION_WALK].Status);
end;

procedure TTestWarActionSteps.DovrebbeFinireUnAzioneCheIlTipoNonHa;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  // a footman does not harvest: set by hand, as nothing but SetAction would refuse it
  LUnit^.ActionType := WAR_ACTION_HARVEST;
  TWarActionRunner.Update(FRig.Entity(LSlot), 1);
  Assert.AreEqual<Integer>(WAR_ACTION_NONE, LUnit^.ActionType);
  Assert.AreEqual<Integer>(WAR_ACTION_FINISHED, LUnit^.Actions[WAR_ACTION_HARVEST].Status);
end;

procedure TTestWarActionSteps.DovrebbeIgnorareUnUnitaSenzaAzione;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  LUnit^.ActionType := WAR_ACTION_NONE;
  TWarActionRunner.Update(FRig.Entity(LSlot), 1);
  Assert.AreEqual<Integer>(WAR_ACTION_NONE, LUnit^.ActionType);
end;

procedure TTestWarActionSteps.DovrebbeRiavviareUnAzioneSenzaPassoIniziale;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  LUnit^.Actions[WAR_ACTION_WALK].StepIndex := -1;
  LUnit^.ActionType := WAR_ACTION_WALK;
  TWarActionRunner.Update(FRig.Entity(LSlot), 1);
  Assert.AreEqual<Integer>(WAR_ACTION_RUNNING, LUnit^.Actions[WAR_ACTION_WALK].Status);
  Assert.IsTrue(LUnit^.Actions[WAR_ACTION_WALK].StepIndex >= 0);
end;

procedure TTestWarActionSteps.DovrebbeAspettareLaFineDellAttesa;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LIndex: Integer;
  LEnd: Double;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_WALK, True, 1.0);
  TWarActionRunner.Update(FRig.Entity(LSlot), 1.0);
  LIndex := LUnit^.Actions[WAR_ACTION_WALK].StepIndex;
  LEnd := LUnit^.Actions[WAR_ACTION_WALK].WaitEndGameTime;
  Assert.IsTrue(LEnd > 1.0);
  TWarActionRunner.Update(FRig.Entity(LSlot), 1.0 + (LEnd - 1.0) / 2);
  Assert.AreEqual<Integer>(LIndex, LUnit^.Actions[WAR_ACTION_WALK].StepIndex);
  TWarActionRunner.Update(FRig.Entity(LSlot), LEnd);
  Assert.AreNotEqual<Integer>(LIndex, LUnit^.Actions[WAR_ACTION_WALK].StepIndex);
end;

procedure TTestWarActionSteps.DovrebbeNotareIlSuonoDelPasso;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LTime: Double;
  LIndex: Integer;
  LSound: Integer;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_ATTACK, True, 1.0);
  LTime := 0;
  LSound := WAR_ACTION_STEP_NONE;
  for LIndex := 1 to 120 do
  begin
    LTime := LTime + 1 / 60;
    TWarActionRunner.Update(FRig.Entity(LSlot), LTime);
    if LUnit^.Actions[WAR_ACTION_ATTACK].LastSoundStep <> WAR_ACTION_STEP_NONE then
      LSound := LUnit^.Actions[WAR_ACTION_ATTACK].LastSoundStep;
  end;
  Assert.AreEqual<Integer>(WAR_ACTION_STEP_SOUND_SWORD, LSound);
end;

procedure TTestWarActionSteps.DovrebbeNonFareNienteDopoLaFine;
var
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LStep: Integer;
begin
  NewRig([]);
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 5, 5, 0);
  LUnit := @FRig.Entity(LSlot)^.UnitData;
  LUnit^.ActionType := WAR_ACTION_IDLE;
  LUnit^.Actions[WAR_ACTION_IDLE].Status := WAR_ACTION_FINISHED;
  LStep := LUnit^.Actions[WAR_ACTION_IDLE].StepIndex;
  TWarActionRunner.Update(FRig.Entity(LSlot), 100);
  Assert.AreEqual<Integer>(LStep, LUnit^.Actions[WAR_ACTION_IDLE].StepIndex);
end;

{ TTestWarTargetGeometry }

procedure TTestWarTargetGeometry.DovrebbeTrovareIlPuntoPiuVicinoDelRettangolo(AX, AY, AExpectedX, AExpectedY: Integer);
var
  LPoint: TWarVec2;
begin
  // the rectangle is 16, 16, 48 x 32: left 16, top 16, right 63, bottom 47
  LPoint := TWarTargetGeometry.ClosestPointOnRect(16, 16, 48, 32, TWarModelMath.Vec(AX, AY));
  Assert.AreEqual<Integer>(AExpectedX, Trunc(LPoint.X));
  Assert.AreEqual<Integer>(AExpectedY, Trunc(LPoint.Y));
end;

{ TTestWarNearUnits }

procedure TTestWarNearUnits.DovrebbeDareLeUnitaVicineCellaPerCellaDallUltimaInserita;
var
  LNear: TWarNearUnits;
  LList: TList<Integer>;
  LFirst: Integer;
  LSecond: Integer;
  LThird: Integer;
begin
  NewRig([]);
  LFirst := FRig.AddDude(WAR_UNIT_PEON, 10, 10, 0);
  LSecond := FRig.AddDude(WAR_UNIT_PEON, 11, 10, 0);
  // another cell of the grid (4 tiles)
  LThird := FRig.AddDude(WAR_UNIT_PEON, 12, 10, 0);
  LNear := TWarNearUnits.Create(FRig.World.Context, FRig.World.Machine);
  LList := TList<Integer>.Create;
  try
    LNear.Build;
    LNear.Collect(TWarModelMath.Vec(11, 10), 2, LList);
    Assert.AreEqual<Integer>(3, LList.Count);
    // cell (2,2): the second then the first; cell (3,2): the third
    Assert.AreEqual<Integer>(LSecond, LList[0]);
    Assert.AreEqual<Integer>(LFirst, LList[1]);
    Assert.AreEqual<Integer>(LThird, LList[2]);
  finally
    LList.Free;
    LNear.Free;
  end;
end;

procedure TTestWarNearUnits.DovrebbeEscludereLeUnitaCheStannoPerMorire;
var
  LNear: TWarNearUnits;
  LList: TList<Integer>;
  LDying: Integer;
begin
  NewRig([]);
  LDying := FRig.AddDude(WAR_UNIT_PEON, 10, 10, 0);
  FRig.AddDude(WAR_UNIT_PEON, 11, 10, 0);
  FRig.World.Combat.TakeDamage(LDying, 255, 0);
  LNear := TWarNearUnits.Create(FRig.World.Context, FRig.World.Machine);
  LList := TList<Integer>.Create;
  try
    LNear.Build;
    LNear.Collect(TWarModelMath.Vec(10, 10), 3, LList);
    Assert.AreEqual<Integer>(1, LList.Count);
    Assert.AreNotEqual<Integer>(LDying, LList[0]);
  finally
    LList.Free;
    LNear.Free;
  end;
end;

procedure TTestWarNearUnits.DovrebbeEscludereLeUnitaLontane;
var
  LNear: TWarNearUnits;
  LList: TList<Integer>;
begin
  NewRig([]);
  FRig.AddDude(WAR_UNIT_PEON, 10, 10, 0);
  FRig.AddDude(WAR_UNIT_PEON, 30, 30, 0);
  LNear := TWarNearUnits.Create(FRig.World.Context, FRig.World.Machine);
  LList := TList<Integer>.Create;
  try
    LNear.Build;
    LNear.Collect(TWarModelMath.Vec(0, 0), 2, LList);
    Assert.AreEqual<Integer>(0, LList.Count);
    LNear.Collect(TWarModelMath.Vec(10, 10), 1, LList);
    Assert.AreEqual<Integer>(1, LList.Count);
  finally
    LList.Free;
    LNear.Free;
  end;
end;

procedure TTestWarNearUnits.DovrebbeTenereNelGrigliaLUnitaCheMuoreDopoLaCostruzione;
var
  LNear: TWarNearUnits;
  LList: TList<Integer>;
  LUnit: Integer;
begin
  NewRig([]);
  LUnit := FRig.AddDude(WAR_UNIT_PEON, 10, 10, 0);
  LNear := TWarNearUnits.Create(FRig.World.Context, FRig.World.Machine);
  LList := TList<Integer>.Create;
  try
    LNear.Build;
    FRig.World.Combat.TakeDamage(LUnit, 255, 0);
    LNear.Collect(TWarModelMath.Vec(10, 10), 1, LList);
    Assert.AreEqual<Integer>(1, LList.Count);
  finally
    LList.Free;
    LNear.Free;
  end;
end;

end.
