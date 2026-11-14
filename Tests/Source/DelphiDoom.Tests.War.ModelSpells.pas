{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the spells, the mana and the          }
{  animations of the model                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelSpells;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.Tests.War.CommandRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarAnimations = class(TObject)
  private
    FRig: TCommandRig;
    function NewEffect: PWarEntity;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAggiungereETrovareUnaAnimazione;
    [Test]
    procedure DovrebbeTogliereLaPrimaAnimazioneConQuelNome;
    [Test]
    procedure DovrebbeDurareIlRitardoPerIFotogrammi;
    [Test]
    procedure DovrebbeFinireEdEssereToltaAlTicDopo;
    [Test]
    procedure DovrebbeSaltareLAnimazioneCheSegueQuellaTolta;
    [Test]
    procedure DovrebbeRicominciareSeEInCiclo;
    [Test]
    procedure DovrebbeAspettareIlRitardoDelCiclo;
    [Test]
    procedure DovrebbeCrescereOltreQualunqueNumeroDiAnimazioni;
    [Test]
    procedure DovrebbeDareIlFumoEPoiIlFuocoAUnEdificioColpito;
    [Test]
    procedure DovrebbeSostituireIDanniConIlCrolloQuandoLEdificioCrolla;
    [Test]
    procedure DovrebbeLasciareLEntitaDellEsplosioneQuandoLAnimazioneFinisce;
    [Test]
    procedure DovrebbeDareZeroSeLaPiscinaEPienaPerIlLampo;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarSpells = class(TObject)
  private
    FRig: TCommandRig;
    procedure Cast(ACaster, ASpell, ATarget: Integer; const APoint: TWarVec2);
    function CastDone(ACaster: Integer): Boolean;
    procedure FillPool;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRigenerareUnPuntoDiManaAlSecondoFinoAlMassimo;
    [Test]
    procedure DovrebbeFarMorireUnEvocatoQuandoIlManaFinisce;
    [Test]
    procedure DovrebbeNonAvvisareQuandoMuoreUnDemoneEvocato;
    [Test]
    procedure DovrebbeNonToccareIlManaDiChiMuore;
    [Test]
    procedure DovrebbePortareAZeroUnManaNegativoDiUnEvocato;
    [Test]
    procedure DovrebbeGuarireUnPuntoOgniSeiDiMana;
    [Test]
    procedure DovrebbeGuarireSoloCioCheManca;
    [Test]
    procedure DovrebbeNonSpendereNullaSeIlBersaglioNonCEPiu;
    [Test]
    procedure DovrebbeSeguireIlBersaglioFuoriPortata;
    [Test]
    procedure DovrebbeMisurareLaPortataAlPuntoDellOrdine;
    [Test]
    procedure DovrebbeCreareUnaVistaCheDuraDieciSecondi;
    [Test]
    procedure DovrebbeAvvisareSenzaManaPerLaVista;
    [Test]
    procedure DovrebbeRendereInvisibilePerCinquantaSecondi;
    [Test]
    procedure DovrebbeTogliereLInvisibilitaAChiLanciaUnIncantesimo;
    [Test]
    procedure DovrebbeDimezzareLaVitaERendereInvulnerabile;
    [Test]
    procedure DovrebbeFarCadereCinqueFuochiPerOgniColpoDellaPioggia;
    [Test]
    procedure DovrebbeFermareLaPioggiaQuandoIlManaFinisce;
    [Test]
    procedure DovrebbeFarPartireLaPioggiaDaSopraLaVista;
    [Test]
    procedure DovrebbeCreareUnaNubeCheFerisceOgniSecondo;
    [Test]
    procedure DovrebbeFerireAncheGliAmiciNellaNube;
    [Test]
    procedure DovrebbeResuscitareUnoScheletroPerOgniCadavereCheIlManaPaga;
    [Test]
    procedure DovrebbeAvvisarePerOgniCadavereCheNonPuoPagare;
    [Test]
    procedure DovrebbeNonFareNullaConUnaEvocazioneNelloStatoDiIncantesimo;
    [Test]
    procedure DovrebbeRifiutareOgniOrdineAChiLanciaUnIncantesimo;
    [Test]
    procedure DovrebbeAccettareUnOrdineAChiLanciaConLInterruttore;
    [Test]
    procedure DovrebbeNonInterrompereLaPioggiaDiSuaIniziativa;
    [Test]
    procedure DovrebbeDareUnNumeroACasoTraZeroEUno;
    [Test]
    procedure DovrebbeNonFarPiovereSenzaIServiziDelCombattimento;
    [Test]
    procedure DovrebbeDareZeroSeLaPiscinaEPienaPerVistaENube;
    [Test]
    procedure DovrebbeLasciareIlCadavereSeLaPiscinaEPiena;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Animations, DelphiDoom.War.Model.Spells,
  DelphiDoom.War.Model.State.Cast, DelphiDoom.War.Model.Combat.Intf, DelphiDoom.War.Model.Math;

{ TTestWarAnimations }

procedure TTestWarAnimations.Setup;
begin
  FRig := TCommandRig.Create;
end;

procedure TTestWarAnimations.TearDown;
begin
  FRig.Free;
end;

function TTestWarAnimations.NewEffect: PWarEntity;
begin
  Result := FRig.Entity(FRig.Context.Pool.CreateEntity(WAR_ENTITY_ANIMATION, True));
end;

procedure TTestWarAnimations.DovrebbeAggiungereETrovareUnaAnimazione;
var
  LEntity: PWarEntity;
begin
  LEntity := NewEffect;
  Assert.IsFalse(TWarAnimations.Contains(LEntity, WAR_ANIMATION_SPELL));
  TWarAnimations.CreateSpell(LEntity, TWarModelMath.Vec(40, 56));
  Assert.IsTrue(LEntity^.HasAnimations);
  Assert.AreEqual(1, LEntity^.AnimationCount);
  Assert.AreEqual(0, TWarAnimations.IndexOf(LEntity, WAR_ANIMATION_SPELL));
  Assert.AreEqual(6, LEntity^.Animations[0].FramesCount);
  Assert.AreEqual<Integer>(WAR_ANIM_NOT_STARTED, LEntity^.Animations[0].Status);
  Assert.AreEqual<Single>(40, LEntity^.Animations[0].Position.X);
  Assert.IsFalse(LEntity^.Animations[0].Loop);
end;

procedure TTestWarAnimations.DovrebbeTogliereLaPrimaAnimazioneConQuelNome;
var
  LEntity: PWarEntity;
begin
  LEntity := NewEffect;
  TWarAnimations.CreateDamage(LEntity, 1);
  TWarAnimations.CreateDamage(LEntity, 2);
  TWarAnimations.CreateDamage(LEntity, 1);
  TWarAnimations.Remove(LEntity, WAR_ANIMATION_LITTLE_DAMAGE);
  Assert.AreEqual(2, LEntity^.AnimationCount);
  Assert.AreEqual<Integer>(WAR_ANIMATION_HUGE_DAMAGE, LEntity^.Animations[0].Kind);
  Assert.AreEqual<Integer>(WAR_ANIMATION_LITTLE_DAMAGE, LEntity^.Animations[1].Kind);
  TWarAnimations.Remove(LEntity, WAR_ANIMATION_COLLAPSE);
  Assert.AreEqual(2, LEntity^.AnimationCount, 'un nome che non c''e'' non toglie nulla');
end;

procedure TTestWarAnimations.DovrebbeDurareIlRitardoPerIFotogrammi;
var
  LEntity: PWarEntity;
begin
  LEntity := NewEffect;
  Assert.AreEqual(1.7, Double(TWarAnimations.Duration(TWarAnimations.CreateCollapse(LEntity)^)), 0.0001);
  TWarAnimations.CreatePoisonCloud(LEntity, Default(TWarVec2));
  Assert.AreEqual(2.0, Double(TWarAnimations.Duration(LEntity^.Animations[1])), 0.0001);
  Assert.IsTrue(LEntity^.Animations[1].Loop);
  TWarAnimations.CreateRainOfFireExplosion(LEntity, Default(TWarVec2));
  Assert.AreEqual(3, LEntity^.Animations[2].FramesCount);
  TWarAnimations.CreateExplosion(LEntity, Default(TWarVec2));
  Assert.AreEqual(6, LEntity^.Animations[3].FramesCount);
end;

procedure TTestWarAnimations.DovrebbeFinireEdEssereToltaAlTicDopo;
var
  LEntity: PWarEntity;
begin
  LEntity := NewEffect;
  TWarAnimations.CreateExplosion(LEntity, Default(TWarVec2));
  TWarAnimations.UpdateOne(LEntity, 0, 0.3);
  Assert.AreEqual<Integer>(WAR_ANIM_RUNNING, LEntity^.Animations[0].Status);
  Assert.AreEqual(0.5, Double(LEntity^.Animations[0].AnimTime), 0.0001);
  TWarAnimations.UpdateOne(LEntity, 0, 0.4);
  Assert.AreEqual<Integer>(WAR_ANIM_FINISHED, LEntity^.Animations[0].Status);
  Assert.AreEqual<Single>(1, LEntity^.Animations[0].AnimTime);
  Assert.AreEqual(1, LEntity^.AnimationCount, 'resta fino al tic dopo');
  TWarAnimations.UpdateOne(LEntity, 0, 0.1);
  Assert.AreEqual(0, LEntity^.AnimationCount);
end;

procedure TTestWarAnimations.DovrebbeSaltareLAnimazioneCheSegueQuellaTolta;
var
  LEntity: PWarEntity;
begin
  LEntity := NewEffect;
  TWarAnimations.CreateExplosion(LEntity, TWarModelMath.Vec(1, 1));
  TWarAnimations.CreateSpell(LEntity, TWarModelMath.Vec(2, 2));
  LEntity^.Animations[0].Status := WAR_ANIM_FINISHED;
  FRig.Context.Clock^.DeltaTime := 0.24;
  TWarAnimations.UpdateAll(FRig.Context);
  // the explosion is removed and the spell, which took its place in the list, does not advance in this tic
  Assert.AreEqual(1, LEntity^.AnimationCount);
  Assert.AreEqual<Integer>(WAR_ANIMATION_SPELL, LEntity^.Animations[0].Kind);
  Assert.AreEqual<Single>(0, LEntity^.Animations[0].AnimTime);
  TWarAnimations.UpdateAll(FRig.Context);
  Assert.AreEqual(0.1, Double(LEntity^.Animations[0].AnimTime), 0.0001);
end;

procedure TTestWarAnimations.DovrebbeRicominciareSeEInCiclo;
var
  LEntity: PWarEntity;
begin
  LEntity := NewEffect;
  TWarAnimations.CreateDamage(LEntity, 2);
  TWarAnimations.UpdateOne(LEntity, 0, 0.9);
  Assert.AreEqual<Single>(0, LEntity^.Animations[0].AnimTime, 'finita, ricomincia');
  Assert.AreEqual<Integer>(WAR_ANIM_RUNNING, LEntity^.Animations[0].Status);
  TWarAnimations.UpdateOne(LEntity, 0, 0.2);
  Assert.AreEqual(0.25, Double(LEntity^.Animations[0].AnimTime), 0.0001);
  Assert.AreEqual(1, LEntity^.AnimationCount);
end;

procedure TTestWarAnimations.DovrebbeAspettareIlRitardoDelCiclo;
var
  LEntity: PWarEntity;
begin
  LEntity := NewEffect;
  TWarAnimations.CreateDamage(LEntity, 1);
  LEntity^.Animations[0].LoopDelay := 0.5;
  TWarAnimations.UpdateOne(LEntity, 0, 1.0);
  Assert.AreEqual<Single>(0.5, LEntity^.Animations[0].LoopTime);
  TWarAnimations.UpdateOne(LEntity, 0, 0.3);
  Assert.AreEqual(0.2, Double(LEntity^.Animations[0].LoopTime), 0.0001);
  Assert.AreEqual<Single>(0, LEntity^.Animations[0].AnimTime, 'ferma finche'' il ritardo non e'' passato');
end;

procedure TTestWarAnimations.DovrebbeCrescereOltreQualunqueNumeroDiAnimazioni;
var
  LEntity: PWarEntity;
  LIndex: Integer;
begin
  LEntity := NewEffect;
  for LIndex := 1 to 40 do
    TWarAnimations.CreateCollapse(LEntity);
  Assert.AreEqual(40, LEntity^.AnimationCount);
end;

procedure TTestWarAnimations.DovrebbeDareIlFumoEPoiIlFuocoAUnEdificioColpito;
var
  LFarm: Integer;
  LEntity: PWarEntity;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LEntity := FRig.Entity(LFarm);
  FRig.World.Combat.TakeDamage(LFarm, LEntity^.UnitData.MaxHp div 2, 0);
  Assert.IsTrue(TWarAnimations.Contains(LEntity, WAR_ANIMATION_LITTLE_DAMAGE));
  FRig.World.Combat.TakeDamage(LFarm, 1, 0);
  Assert.AreEqual(1, LEntity^.AnimationCount, 'il fumo non si aggiunge due volte');
  FRig.World.Combat.TakeDamage(LFarm, LEntity^.UnitData.MaxHp div 4, 0);
  Assert.IsTrue(TWarAnimations.Contains(LEntity, WAR_ANIMATION_HUGE_DAMAGE));
  Assert.IsFalse(TWarAnimations.Contains(LEntity, WAR_ANIMATION_LITTLE_DAMAGE), 'il fuoco prende il posto del fumo');
  // repaired up to a half, the smoke comes back next to the fire (as in the original)
  LEntity^.UnitData.Hp := LEntity^.UnitData.MaxHp div 2 + 5;
  FRig.World.Combat.TakeDamage(LFarm, 1, 0);
  Assert.AreEqual(2, LEntity^.AnimationCount);
end;

procedure TTestWarAnimations.DovrebbeSostituireIDanniConIlCrolloQuandoLEdificioCrolla;
var
  LFarm: Integer;
  LEntity: PWarEntity;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  LEntity := FRig.Entity(LFarm);
  FRig.World.Combat.TakeDamage(LFarm, LEntity^.UnitData.MaxHp - 10, 0);
  Assert.IsTrue(TWarAnimations.Contains(LEntity, WAR_ANIMATION_HUGE_DAMAGE));
  FRig.World.Combat.TakeDamage(LFarm, 100, 0);
  FRig.Tick;
  Assert.AreEqual(1, LEntity^.AnimationCount);
  Assert.AreEqual<Integer>(WAR_ANIMATION_COLLAPSE, LEntity^.Animations[0].Kind);
  Assert.IsFalse(LEntity^.SpriteEnabled);
  // the building is removed when its collapse has been played
  FRig.Run(2.0);
  Assert.AreEqual(0, FRig.CountOfType(WAR_UNIT_FARM_HUMANS));
end;

procedure TTestWarAnimations.DovrebbeLasciareLEntitaDellEsplosioneQuandoLAnimazioneFinisce;
var
  LSlot: Integer;
begin
  LSlot := TWarAnimations.SpawnSpellEffect(FRig.Context, TWarModelMath.Vec(100, 100));
  Assert.AreNotEqual(0, LSlot);
  FRig.Run(3.0);
  // defect of the original kept: the animation is gone, its entity stays for ever
  Assert.AreEqual(0, FRig.Entity(LSlot)^.AnimationCount);
  Assert.AreNotEqual(0, Integer(FRig.Entity(LSlot)^.Id));
  Assert.AreEqual(1, FRig.CountEntities(WAR_ENTITY_ANIMATION));
end;

procedure TTestWarAnimations.DovrebbeDareZeroSeLaPiscinaEPienaPerIlLampo;
begin
  while FRig.Context.Pool.CreateEntity(WAR_ENTITY_IMAGE, False) <> 0 do
    ;
  Assert.AreEqual(0, TWarAnimations.SpawnSpellEffect(FRig.Context, Default(TWarVec2)));
end;

{ TTestWarSpells }

procedure TTestWarSpells.Setup;
begin
  FRig := TCommandRig.Create;
end;

procedure TTestWarSpells.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarSpells.Cast(ACaster, ASpell, ATarget: Integer; const APoint: TWarVec2);
var
  LTargetId: Word;
  LState: PWarStateCast;
begin
  LTargetId := 0;
  if ATarget <> 0 then
    LTargetId := FRig.IdOf(ATarget);
  LState := TWarCastState.CreateState(FRig.Machine, ACaster, ASpell, LTargetId, APoint);
  Assert.IsTrue(FRig.Machine.ResetState(ACaster, PWarStateBase(LState), WAR_CAUSE_PLAYER_ORDER));
  FRig.Tick;
end;

function TTestWarSpells.CastDone(ACaster: Integer): Boolean;
begin
  Result := FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.ActiveType(ACaster) = WAR_STATE_IDLE;
    end, 20);
end;

procedure TTestWarSpells.FillPool;
begin
  while FRig.Context.Pool.CreateEntity(WAR_ENTITY_IMAGE, False) <> 0 do
    ;
end;

procedure TTestWarSpells.DovrebbeRigenerareUnPuntoDiManaAlSecondoFinoAlMassimo;
var
  LCleric: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  FRig.UnitOf(LCleric)^.Mana := 10;
  FRig.Run(5.2);
  Assert.IsTrue((FRig.UnitOf(LCleric)^.Mana >= 14) and (FRig.UnitOf(LCleric)^.Mana <= 16),
    Format('mana %d', [FRig.UnitOf(LCleric)^.Mana]));
  FRig.UnitOf(LCleric)^.Mana := FRig.UnitOf(LCleric)^.MaxMana;
  FRig.Run(3);
  Assert.AreEqual(FRig.UnitOf(LCleric)^.MaxMana, FRig.UnitOf(LCleric)^.Mana);
end;

procedure TTestWarSpells.DovrebbeFarMorireUnEvocatoQuandoIlManaFinisce;
var
  LSpider: Integer;
begin
  LSpider := FRig.AddDude(WAR_UNIT_SPIDER, 10, 10);
  FRig.UnitOf(LSpider)^.Mana := 2;
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.Machine.IsDead(LSpider);
    end, 6));
  Assert.AreEqual(0, FRig.UnitOf(LSpider)^.Mana);
  Assert.AreEqual(1, FRig.Observer.SummonsExpired, 'il verso del ragno che muore');
end;

procedure TTestWarSpells.DovrebbeNonAvvisareQuandoMuoreUnDemoneEvocato;
var
  LDaemon: Integer;
begin
  LDaemon := FRig.AddDude(WAR_UNIT_DAEMON, 10, 10);
  FRig.UnitOf(LDaemon)^.Mana := 1;
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.Machine.IsDead(LDaemon);
    end, 6));
  Assert.AreEqual(0, FRig.Observer.SummonsExpired);
end;

procedure TTestWarSpells.DovrebbeNonToccareIlManaDiChiMuore;
var
  LCleric: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  FRig.UnitOf(LCleric)^.Mana := 10;
  FRig.World.Combat.TakeDamage(LCleric, 500, 0);
  FRig.Run(0.5);
  Assert.IsTrue(FRig.Machine.IsDead(LCleric));
  FRig.UnitOf(LCleric)^.ManaTime := 0;
  FRig.Tick(3);
  Assert.AreEqual(10, FRig.UnitOf(LCleric)^.Mana);
end;

procedure TTestWarSpells.DovrebbePortareAZeroUnManaNegativoDiUnEvocato;
var
  LSpider: Integer;
begin
  LSpider := FRig.AddDude(WAR_UNIT_SPIDER, 10, 10);
  FRig.UnitOf(LSpider)^.Mana := -5;
  FRig.UnitOf(LSpider)^.ManaTime := 0;
  FRig.Tick;
  Assert.AreEqual(0, FRig.UnitOf(LSpider)^.Mana);
end;

procedure TTestWarSpells.DovrebbeGuarireUnPuntoOgniSeiDiMana;
var
  LCleric: Integer;
  LFootman: Integer;
  LEffects: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 12, 10);
  FRig.UnitOf(LCleric)^.Mana := 60;
  FRig.UnitOf(LCleric)^.ManaTime := 1000;
  FRig.UnitOf(LFootman)^.Hp := 20;
  LEffects := FRig.CountEntities(WAR_ENTITY_ANIMATION);
  Cast(LCleric, WAR_SPELL_HEALING, LFootman, FRig.Center(LFootman));
  Assert.IsTrue(CastDone(LCleric));
  Assert.AreEqual(30, FRig.UnitOf(LFootman)^.Hp);
  Assert.AreEqual(0, FRig.UnitOf(LCleric)^.Mana);
  Assert.AreEqual(LEffects + 1, FRig.CountEntities(WAR_ENTITY_ANIMATION), 'il lampo dell''incantesimo');
  Assert.AreEqual(1, FRig.Observer.SpellsCast);
end;

procedure TTestWarSpells.DovrebbeGuarireSoloCioCheManca;
var
  LCleric: Integer;
  LFootman: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 12, 10);
  FRig.UnitOf(LCleric)^.Mana := 100;
  FRig.UnitOf(LCleric)^.ManaTime := 1000;
  FRig.UnitOf(LFootman)^.Hp := FRig.UnitOf(LFootman)^.MaxHp - 3;
  Cast(LCleric, WAR_SPELL_HEALING, LFootman, FRig.Center(LFootman));
  Assert.IsTrue(CastDone(LCleric));
  Assert.AreEqual(FRig.UnitOf(LFootman)^.MaxHp, FRig.UnitOf(LFootman)^.Hp);
  Assert.AreEqual(100 - 18, FRig.UnitOf(LCleric)^.Mana);
end;

procedure TTestWarSpells.DovrebbeNonSpendereNullaSeIlBersaglioNonCEPiu;
var
  LCleric: Integer;
  LFootman: Integer;
  LPoint: TWarVec2;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 12, 10);
  FRig.UnitOf(LCleric)^.ManaTime := 1000;
  LPoint := FRig.Center(LFootman);
  Cast(LCleric, WAR_SPELL_INVISIBILITY, LFootman, LPoint);
  FRig.World.Entities.RemoveEntity(LFootman);
  Assert.IsTrue(CastDone(LCleric));
  Assert.AreEqual(100, FRig.UnitOf(LCleric)^.Mana);
  Assert.AreEqual(0, FRig.Observer.SpellsCast);
end;

procedure TTestWarSpells.DovrebbeSeguireIlBersaglioFuoriPortata;
var
  LCleric: Integer;
  LFootman: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 10);
  Cast(LCleric, WAR_SPELL_HEALING, LFootman, FRig.Center(LFootman));
  FRig.Tick(2);
  Assert.IsTrue(FRig.Machine.Contains(LCleric, WAR_STATE_FOLLOW), 'la guarigione ha portata 6');
  Assert.IsTrue(FRig.Machine.Contains(LCleric, WAR_STATE_CAST));
end;

procedure TTestWarSpells.DovrebbeMisurareLaPortataAlPuntoDellOrdine;
var
  LCleric: Integer;
  LFootman: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 50, 50);
  FRig.UnitOf(LCleric)^.ManaTime := 1000;
  FRig.UnitOf(LFootman)^.Hp := 10;
  // defect of the original kept: the point of the order is next to the caster, the target is far away, and it is healed
  Cast(LCleric, WAR_SPELL_HEALING, LFootman, FRig.TilePoint(12, 10));
  Assert.IsTrue(CastDone(LCleric));
  Assert.IsFalse(FRig.Machine.Contains(LCleric, WAR_STATE_FOLLOW));
  Assert.AreEqual(10 + 100 div 6, FRig.UnitOf(LFootman)^.Hp);
end;

procedure TTestWarSpells.DovrebbeCreareUnaVistaCheDuraDieciSecondi;
var
  LCleric: Integer;
  LSight: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  FRig.UnitOf(LCleric)^.ManaTime := 1000;
  Cast(LCleric, WAR_SPELL_FAR_SIGHT, 0, FRig.TilePoint(40, 40));
  Assert.IsTrue(CastDone(LCleric));
  Assert.AreEqual(30, FRig.UnitOf(LCleric)^.Mana, 'la vista lontana costa 70');
  Assert.AreEqual(1, FRig.Context.Pool.OfType[WAR_ENTITY_SIGHT].Count);
  LSight := FRig.Context.Pool.OfType[WAR_ENTITY_SIGHT][0];
  Assert.IsTrue(FRig.Entity(LSight)^.HasSight);
  Assert.AreEqual<Single>(40, FRig.Entity(LSight)^.SpellTile.X);
  Assert.AreEqual(1, FRig.Entity(LSight)^.AnimationCount, 'il lampo e'' sull''entita'' della vista');
  FRig.Run(9);
  Assert.AreEqual(1, FRig.Context.Pool.OfType[WAR_ENTITY_SIGHT].Count);
  FRig.Run(1.5);
  Assert.AreEqual(0, FRig.Context.Pool.OfType[WAR_ENTITY_SIGHT].Count);
end;

procedure TTestWarSpells.DovrebbeAvvisareSenzaManaPerLaVista;
var
  LNecrolyte: Integer;
  LFlashes: Cardinal;
begin
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 10, 10);
  FRig.UnitOf(LNecrolyte)^.Mana := 20;
  FRig.UnitOf(LNecrolyte)^.ManaTime := 1000;
  LFlashes := FRig.Observer.FlashCount;
  Cast(LNecrolyte, WAR_SPELL_DARK_VISION, 0, FRig.TilePoint(40, 40));
  Assert.IsTrue(CastDone(LNecrolyte));
  Assert.AreEqual(20, FRig.UnitOf(LNecrolyte)^.Mana);
  Assert.AreEqual(0, FRig.Context.Pool.OfType[WAR_ENTITY_SIGHT].Count);
  Assert.AreEqual(LFlashes + 1, FRig.Observer.FlashCount);
  Assert.AreEqual(wsmNotEnoughMana, FRig.Observer.LastMessage);
end;

procedure TTestWarSpells.DovrebbeRendereInvisibilePerCinquantaSecondi;
var
  LCleric: Integer;
  LFootman: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_FOOTMAN, 12, 10);
  FRig.UnitOf(LCleric)^.Mana := 255;
  FRig.UnitOf(LCleric)^.ManaTime := 1000;
  Cast(LCleric, WAR_SPELL_INVISIBILITY, LFootman, FRig.Center(LFootman));
  Assert.IsTrue(CastDone(LCleric));
  Assert.IsTrue(FRig.UnitOf(LFootman)^.Invisible);
  Assert.AreEqual(55, FRig.UnitOf(LCleric)^.Mana);
  FRig.Run(48, 0.25);
  Assert.IsTrue(FRig.UnitOf(LFootman)^.Invisible);
  FRig.Run(3, 0.25);
  Assert.IsFalse(FRig.UnitOf(LFootman)^.Invisible);
  Assert.AreEqual<Single>(0, FRig.UnitOf(LFootman)^.InvisibilityTime);
end;

procedure TTestWarSpells.DovrebbeTogliereLInvisibilitaAChiLanciaUnIncantesimo;
var
  LCleric: Integer;
begin
  LCleric := FRig.AddDude(WAR_UNIT_CLERIC, 10, 10);
  FRig.UnitOf(LCleric)^.Invisible := True;
  FRig.UnitOf(LCleric)^.InvisibilityTime := 40;
  Cast(LCleric, WAR_SPELL_FAR_SIGHT, 0, FRig.TilePoint(20, 20));
  Assert.IsTrue(CastDone(LCleric));
  Assert.IsFalse(FRig.UnitOf(LCleric)^.Invisible);
end;

procedure TTestWarSpells.DovrebbeDimezzareLaVitaERendereInvulnerabile;
var
  LNecrolyte: Integer;
  LGrunt: Integer;
  LHp: Integer;
begin
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 10, 10);
  LGrunt := FRig.AddDude(WAR_UNIT_GRUNT, 12, 10);
  FRig.UnitOf(LNecrolyte)^.ManaTime := 1000;
  LHp := FRig.UnitOf(LGrunt)^.Hp;
  Cast(LNecrolyte, WAR_SPELL_UNHOLY_ARMOR, LGrunt, FRig.Center(LGrunt));
  Assert.IsTrue(CastDone(LNecrolyte));
  Assert.AreEqual(LHp - LHp div 2, FRig.UnitOf(LGrunt)^.Hp);
  Assert.IsTrue(FRig.UnitOf(LGrunt)^.Invulnerable);
  Assert.AreEqual(0, FRig.UnitOf(LNecrolyte)^.Mana, 'l''armatura costa 100');
  FRig.World.Combat.TakeDamage(LGrunt, 500, 0);
  Assert.AreEqual(LHp - LHp div 2, FRig.UnitOf(LGrunt)^.Hp, 'nessun danno finche'' dura');
  FRig.Run(14, 0.25);
  Assert.IsFalse(FRig.UnitOf(LGrunt)^.Invulnerable);
end;

procedure TTestWarSpells.DovrebbeFarCadereCinqueFuochiPerOgniColpoDellaPioggia;
var
  LConjurer: Integer;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  FRig.UnitOf(LConjurer)^.ManaTime := 1000;
  FRig.Context.ViewportTop := 0;
  Cast(LConjurer, WAR_SPELL_RAIN_OF_FIRE, 0, FRig.TilePoint(14, 10));
  Assert.IsTrue(FRig.RunUntil(
    function: Boolean
    begin
      Result := FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE].Count >= 5;
    end, 10));
  Assert.AreEqual(5, FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE].Count);
  Assert.AreEqual(75, FRig.UnitOf(LConjurer)^.Mana, 'un colpo di pioggia costa 25');
  Assert.AreEqual<Integer>(WAR_STATE_CAST, FRig.ActiveType(LConjurer), 'la pioggia continua');
end;

procedure TTestWarSpells.DovrebbeFermareLaPioggiaQuandoIlManaFinisce;
var
  LConjurer: Integer;
  LFootman: Integer;
  LHp: Integer;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  LFootman := FRig.AddDude(WAR_UNIT_GRUNT, 14, 10, 1);
  // the grunt does not fight back: it is asleep in a wait state
  FRig.Machine.ResetState(LFootman, PWarStateBase(FRig.Machine.CreateWait(LFootman, 1000)), WAR_CAUSE_SCRIPT);
  FRig.UnitOf(LConjurer)^.Mana := 60;
  FRig.UnitOf(LConjurer)^.ManaTime := 1000;
  LHp := FRig.UnitOf(LFootman)^.Hp;
  FRig.Context.ViewportTop := 100;
  Cast(LConjurer, WAR_SPELL_RAIN_OF_FIRE, 0, FRig.Center(LFootman));
  Assert.IsTrue(CastDone(LConjurer));
  Assert.AreEqual(10, FRig.UnitOf(LConjurer)^.Mana, 'due colpi da 25, il terzo non si paga');
  FRig.Run(6);
  Assert.AreEqual(0, FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE].Count);
  Assert.AreEqual(10, FRig.CountEntities(WAR_ENTITY_ANIMATION), 'una esplosione per fuoco, mai tolta');
  Assert.IsTrue(FRig.UnitOf(LFootman)^.Hp <= LHp, 'chi sta sotto la pioggia puo'' solo perdere vita');
end;

procedure TTestWarSpells.DovrebbeFarPartireLaPioggiaDaSopraLaVista;
var
  LSlot: Integer;
  LIndex: Integer;
  LList: TList<Integer>;
begin
  FRig.Context.ViewportTop := 320;
  TWarSpells.RainOfFire(FRig.Context, TWarModelMath.Vec(400, 600));
  LList := FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE];
  Assert.AreEqual(5, LList.Count);
  for LIndex := 0 to LList.Count - 1 do
  begin
    LSlot := LList[LIndex];
    Assert.AreEqual<Integer>(WAR_PROJECTILE_RAIN_OF_FIRE, FRig.Entity(LSlot)^.Projectile.ProjectileType);
    Assert.IsTrue((FRig.Entity(LSlot)^.Projectile.Origin.Y <= 320 - 16) and
      (FRig.Entity(LSlot)^.Projectile.Origin.Y > 320 - 64), 'da 1 a 4 caselle sopra la vista');
    Assert.IsTrue(Abs(FRig.Entity(LSlot)^.Projectile.Target.X - 400) <= 32, 'entro 2 caselle dal punto');
    Assert.IsTrue(Abs(FRig.Entity(LSlot)^.Projectile.Target.Y - 600) <= 32);
    Assert.AreEqual<Single>(FRig.Entity(LSlot)^.Projectile.Target.X, FRig.Entity(LSlot)^.Projectile.Origin.X);
  end;
  Assert.AreEqual<Cardinal>(15, FRig.Observer.Draws, 'tre estrazioni per fuoco');
end;

procedure TTestWarSpells.DovrebbeCreareUnaNubeCheFerisceOgniSecondo;
var
  LWarlock: Integer;
  LGrunt: Integer;
  LHp: Integer;
  LCloud: Integer;
begin
  LWarlock := FRig.AddDude(WAR_UNIT_WARLOCK, 10, 10);
  LGrunt := FRig.AddDude(WAR_UNIT_FOOTMAN, 16, 10, 1);
  FRig.Machine.ResetState(LGrunt, PWarStateBase(FRig.Machine.CreateWait(LGrunt, 1000)), WAR_CAUSE_SCRIPT);
  FRig.UnitOf(LWarlock)^.ManaTime := 1000;
  LHp := FRig.UnitOf(LGrunt)^.Hp;
  Cast(LWarlock, WAR_SPELL_POISON_CLOUD, 0, FRig.Center(LGrunt));
  Assert.IsTrue(CastDone(LWarlock));
  Assert.AreEqual(0, FRig.UnitOf(LWarlock)^.Mana, 'la nube costa 100');
  Assert.AreEqual(1, FRig.Context.Pool.OfType[WAR_ENTITY_POISON_CLOUD].Count);
  LCloud := FRig.Context.Pool.OfType[WAR_ENTITY_POISON_CLOUD][0];
  Assert.IsTrue(FRig.Entity(LCloud)^.HasPoisonCloud);
  Assert.AreEqual<Integer>(WAR_ANIMATION_POISON_CLOUD, FRig.Entity(LCloud)^.Animations[0].Kind);
  FRig.Run(3.5);
  Assert.IsTrue(FRig.UnitOf(LGrunt)^.Hp < LHp, 'la nube ferisce');
  FRig.Run(8);
  Assert.AreEqual(0, FRig.Context.Pool.OfType[WAR_ENTITY_POISON_CLOUD].Count, 'dura 10 secondi');
end;

procedure TTestWarSpells.DovrebbeFerireAncheGliAmiciNellaNube;
var
  LPeasant: Integer;
  LDying: Integer;
  LHp: Integer;
begin
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 20, 20);
  LDying := FRig.AddDude(WAR_UNIT_PEASANT, 21, 20);
  LHp := FRig.UnitOf(LPeasant)^.Hp;
  FRig.World.Combat.TakeDamage(LDying, 500, 0);
  Assert.AreNotEqual(0, TWarSpells.SpawnPoisonCloud(FRig.Context, TWarModelMath.Vec(20, 20), 3));
  FRig.Run(1.5);
  Assert.IsTrue(FRig.UnitOf(LPeasant)^.Hp < LHp);
  Assert.AreEqual(0, FRig.UnitOf(LDying)^.Hp, 'chi muore non e'' ferito ancora');
end;

procedure TTestWarSpells.DovrebbeResuscitareUnoScheletroPerOgniCadavereCheIlManaPaga;
var
  LNecrolyte: Integer;
  LSkeleton: Integer;
begin
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 10, 10);
  FRig.AddCorpse(14, 10);
  FRig.AddCorpse(15, 11);
  FRig.UnitOf(LNecrolyte)^.Mana := 120;
  FRig.UnitOf(LNecrolyte)^.ManaTime := 1000;
  Cast(LNecrolyte, WAR_SPELL_RAISE_DEAD, 0, FRig.TilePoint(14, 10));
  Assert.IsTrue(CastDone(LNecrolyte));
  Assert.AreEqual(2, FRig.CountOfType(WAR_UNIT_SKELETON));
  Assert.AreEqual(0, FRig.CountOfType(WAR_UNIT_HUMAN_CORPSE));
  Assert.AreEqual(20, FRig.UnitOf(LNecrolyte)^.Mana, 'uno scheletro costa 50');
  LSkeleton := FRig.Context.Pool.UnitsOfType[WAR_UNIT_SKELETON][0];
  Assert.AreEqual(0, Integer(FRig.UnitOf(LSkeleton)^.Player), 'lo scheletro e'' di chi lo resuscita');
  Assert.AreEqual(2, FRig.Observer.SpellsCast);
end;

procedure TTestWarSpells.DovrebbeAvvisarePerOgniCadavereCheNonPuoPagare;
var
  LNecrolyte: Integer;
  LFlashes: Cardinal;
begin
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 10, 10);
  FRig.AddCorpse(14, 10);
  FRig.AddCorpse(15, 11);
  FRig.AddCorpse(13, 11);
  FRig.UnitOf(LNecrolyte)^.Mana := 60;
  FRig.UnitOf(LNecrolyte)^.ManaTime := 1000;
  LFlashes := FRig.Observer.FlashCount;
  Cast(LNecrolyte, WAR_SPELL_RAISE_DEAD, 0, FRig.TilePoint(14, 10));
  Assert.IsTrue(CastDone(LNecrolyte));
  Assert.AreEqual(1, FRig.CountOfType(WAR_UNIT_SKELETON));
  Assert.AreEqual(2, FRig.CountOfType(WAR_UNIT_HUMAN_CORPSE));
  Assert.AreEqual(LFlashes + 2, FRig.Observer.FlashCount, 'difetto conservato: un avviso per cadavere non pagato');
end;

procedure TTestWarSpells.DovrebbeNonFareNullaConUnaEvocazioneNelloStatoDiIncantesimo;
var
  LConjurer: Integer;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  FRig.UnitOf(LConjurer)^.ManaTime := 1000;
  Cast(LConjurer, WAR_SUMMON_SPIDER, 0, FRig.TilePoint(12, 10));
  FRig.Run(5);
  Assert.AreEqual<Integer>(WAR_STATE_CAST, FRig.ActiveType(LConjurer), 'le evocazioni sono un comando, non un incantesimo');
  Assert.AreEqual(100, FRig.UnitOf(LConjurer)^.Mana);
  Assert.AreEqual(0, FRig.CountOfType(WAR_UNIT_SPIDER));
end;

procedure TTestWarSpells.DovrebbeRifiutareOgniOrdineAChiLanciaUnIncantesimo;
var
  LConjurer: Integer;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  Cast(LConjurer, WAR_SPELL_RAIN_OF_FIRE, 0, FRig.TilePoint(14, 10));
  // defect of the original kept: wst_canInterruptCast is never registered
  Assert.IsFalse(FRig.Machine.CanSubmitTransition(LConjurer, WAR_INTERRUPT_PLAYER_ORDER));
  Assert.IsFalse(FRig.Machine.CanSubmitTransition(LConjurer, WAR_INTERRUPT_LIFECYCLE));
  FRig.Select([LConjurer]);
  Assert.IsFalse(FRig.Commands.Movement.Move(FRig.TilePoint(30, 30)));
  Assert.AreEqual<Integer>(WAR_STATE_CAST, FRig.ActiveType(LConjurer));
end;

procedure TTestWarSpells.DovrebbeAccettareUnOrdineAChiLanciaConLInterruttore;
var
  LConjurer: Integer;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  FRig.Context.InterruptibleCasts := True;
  Cast(LConjurer, WAR_SPELL_POISON_CLOUD, 0, FRig.TilePoint(40, 10));
  Assert.IsTrue(FRig.Machine.CanSubmitTransition(LConjurer, WAR_INTERRUPT_AUTONOMOUS));
  FRig.Select([LConjurer]);
  Assert.IsTrue(FRig.Commands.Movement.Move(FRig.TilePoint(30, 30)));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(LConjurer));
end;

procedure TTestWarSpells.DovrebbeNonInterrompereLaPioggiaDiSuaIniziativa;
var
  LConjurer: Integer;
begin
  LConjurer := FRig.AddDude(WAR_UNIT_CONJURER, 10, 10);
  FRig.Context.InterruptibleCasts := True;
  Cast(LConjurer, WAR_SPELL_RAIN_OF_FIRE, 0, FRig.TilePoint(14, 10));
  Assert.IsFalse(FRig.Machine.CanSubmitTransition(LConjurer, WAR_INTERRUPT_AUTONOMOUS));
  Assert.IsTrue(FRig.Machine.CanSubmitTransition(LConjurer, WAR_INTERRUPT_PLAYER_ORDER));
end;

procedure TTestWarSpells.DovrebbeDareUnNumeroACasoTraZeroEUno;
var
  LIndex: Integer;
  LValue: Single;
begin
  // the statistics of the spells are those of the tables of the game; a type that is not a spell is an error
  Assert.AreEqual(6, FRig.Context.SpellStats(WAR_SPELL_HEALING).ManaCost);
  Assert.AreEqual(6, FRig.Context.SpellStats(WAR_SPELL_HEALING).Range);
  Assert.AreEqual<Integer>(WAR_UNIT_DAEMON, FRig.Context.SpellStats(WAR_SUMMON_DAEMON).MappedUnit);
  Assert.WillRaise(
    procedure
    begin
      FRig.Context.SpellStats(WAR_SPELL_COUNT);
    end, EWarException);
  for LIndex := 1 to 200 do
  begin
    LValue := TWarSpells.RandomUnit(FRig.Context);
    Assert.IsTrue((LValue >= 0) and (LValue < 1));
  end;
end;

procedure TTestWarSpells.DovrebbeNonFarPiovereSenzaIServiziDelCombattimento;
var
  LCombat: IWarCombatServices;
begin
  LCombat := FRig.Context.Combat;
  FRig.Context.Combat := nil;
  try
    TWarSpells.RainOfFire(FRig.Context, TWarModelMath.Vec(100, 100));
    Assert.AreEqual(0, FRig.Context.Pool.OfType[WAR_ENTITY_PROJECTILE].Count);
    // a cloud without them does not hurt, and still ends
    Assert.AreNotEqual(0, TWarSpells.SpawnPoisonCloud(FRig.Context, TWarModelMath.Vec(5, 5), 0.5));
    TWarSpells.UpdateSpells(FRig.Machine);
  finally
    FRig.Context.Combat := LCombat;
  end;
  Assert.Pass;
end;

procedure TTestWarSpells.DovrebbeDareZeroSeLaPiscinaEPienaPerVistaENube;
begin
  FillPool;
  Assert.AreEqual(0, TWarSpells.SpawnSight(FRig.Context, Default(TWarVec2), 10));
  Assert.AreEqual(0, TWarSpells.SpawnPoisonCloud(FRig.Context, Default(TWarVec2), 10));
end;

procedure TTestWarSpells.DovrebbeLasciareIlCadavereSeLaPiscinaEPiena;
var
  LNecrolyte: Integer;
begin
  LNecrolyte := FRig.AddDude(WAR_UNIT_NECROLYTE, 10, 10);
  FRig.AddCorpse(14, 10);
  FRig.UnitOf(LNecrolyte)^.ManaTime := 1000;
  Cast(LNecrolyte, WAR_SPELL_RAISE_DEAD, 0, FRig.TilePoint(14, 10));
  FillPool;
  Assert.IsTrue(CastDone(LNecrolyte));
  Assert.AreEqual(0, FRig.CountOfType(WAR_UNIT_SKELETON));
  Assert.AreEqual(1, FRig.CountOfType(WAR_UNIT_HUMAN_CORPSE), 'il C andrebbe in crash: qui il cadavere resta');
end;

end.
