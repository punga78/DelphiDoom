{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the move and death states            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelMove;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ModelRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarMoveState = class(TObject)
  private
    FRig: TModelRig;
    FSlot: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeArrivareAlPuntoEFermarsiInIdle;
    [Test]
    procedure DovrebbeAndareInLineaRettaVersoIlPrimoPunto;
    [Test]
    procedure DovrebbeVoltarsiEMettereLAzioneDiCamminata;
    [Test]
    procedure DovrebbePassarePerPiuPunti;
    [Test]
    procedure DovrebbeFinireSubitoSeNonCeUnaDestinazione;
    [Test]
    procedure DovrebbeRallentareArrivandoAllaFine;
    [Test]
    procedure DovrebbeCamminareAllaVelocitaDelTipoDiUnita;
    [Test]
    procedure DovrebbeArrendersiSeNonSiAvvicinaPerTreSecondi;
    [Test]
    procedure DovrebbeFermarsiPerAttaccareSeLoAttaccanoEControllaGliAttacchi;
    [Test]
    procedure DovrebbeIgnorareChiLoAttaccaSeNonControllaGliAttacchi;
    [Test]
    procedure DovrebbeUsareLaVelocitaPiuAltaDopoUnMiglioramento;
    [Test]
    procedure DovrebbeFinireUnaMarciaDiUnaUnitaCheMuoreMentreCammina;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarDeathState = class(TObject)
  private
    FRig: TModelRig;
    function Kill(AUnitType: Integer; APlayer: Byte = 0): Integer;
    function CorpseType: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMorireELasciareUnCadavereDellaSuaRazza;
    [Test]
    procedure DovrebbeLasciareUnCadavereDegliOrchi;
    [Test]
    procedure DovrebbeNonLasciareCadavereUnaCatapultaUnEvocatoUnoScheletroNeUnCadavere;
    [Test]
    procedure DovrebbeLiberareLeCaselleELasciareLaSelezione;
    [Test]
    procedure DovrebbeDareAlCadavereLaDirezioneDiChiEMortoEIlGiocatoreNeutro;
    [Test]
    procedure DovrebbeTogliereIlCadavereDopoLaSuaMorte;
    [Test]
    procedure DovrebbeDurareQuantoLAnimazioneAllaVelocitaDellaMappa;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.Math;

function TileCenter(ATileX, ATileY: Integer): TWarVec2;
begin
  Result := TWarModelMath.Vec(ATileX * 16 + 8, ATileY * 16 + 8);
end;

{ TTestWarMoveState }

procedure TTestWarMoveState.Setup;
begin
  FRig := TModelRig.Create;
  FSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
end;

procedure TTestWarMoveState.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarMoveState.DovrebbeArrivareAlPuntoEFermarsiInIdle;
var
  LCenter: TWarVec2;
begin
  Assert.IsTrue(FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(14, 10)]));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(FSlot));
  FRig.Run(8);
  LCenter := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  Assert.AreEqual<Single>(14 * 16 + 8, LCenter.X);
  Assert.AreEqual<Single>(10 * 16 + 8, LCenter.Y);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
end;

procedure TTestWarMoveState.DovrebbeAndareInLineaRettaVersoIlPrimoPunto;
var
  LCenter: TWarVec2;
begin
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(16, 16)]);
  FRig.Run(1);
  LCenter := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  // on the diagonal: the same advance in both directions
  Assert.IsTrue(Abs((LCenter.X - 168) - (LCenter.Y - 168)) < 0.01);
  Assert.IsTrue(LCenter.X > 168);
  Assert.IsTrue(LCenter.X < 168 + 17);
end;

procedure TTestWarMoveState.DovrebbeVoltarsiEMettereLAzioneDiCamminata;
begin
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(14, 10)]);
  FRig.Run(0.5);
  Assert.AreEqual<Integer>(WAR_DIRECTION_EAST, FRig.Entity(FSlot)^.UnitData.Direction);
  Assert.AreEqual<Integer>(WAR_ACTION_WALK, FRig.Entity(FSlot)^.UnitData.ActionType);
end;

procedure TTestWarMoveState.DovrebbePassarePerPiuPunti;
var
  LCenter: TWarVec2;
begin
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(12, 10), TileCenter(12, 12), TileCenter(10, 12)]);
  FRig.Run(15);
  LCenter := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  Assert.AreEqual<Single>(10 * 16 + 8, LCenter.X);
  Assert.AreEqual<Single>(12 * 16 + 8, LCenter.Y);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(WAR_DIRECTION_WEST, FRig.Entity(FSlot)^.UnitData.Direction);
end;

procedure TTestWarMoveState.DovrebbeFinireSubitoSeNonCeUnaDestinazione;
begin
  FRig.Move(FSlot, [TileCenter(10, 10)]);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(FSlot));
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
end;

procedure TTestWarMoveState.DovrebbeRallentareArrivandoAllaFine;
var
  LBefore: TWarVec2;
  LAfter: TWarVec2;
  LFarStep: Single;
  LNearStep: Single;
begin
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(30, 10)]);
  FRig.Tick(2);
  LBefore := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  FRig.Tick;
  LAfter := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  LFarStep := LAfter.X - LBefore.X;
  while (30 * 16 + 8) - TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot)).X > 10 do
    FRig.Tick;
  LBefore := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  FRig.Tick;
  LAfter := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  LNearStep := LAfter.X - LBefore.X;
  // a step at the full speed is 16.736 / 60 pixels; within 3 tiles of the end the speed goes down, to a quarter at least
  Assert.IsTrue(Abs(LFarStep - 0.2789) < 0.002);
  Assert.IsTrue((LNearStep > 0.06) and (LNearStep < 0.075));
end;
procedure TTestWarMoveState.DovrebbeCamminareAllaVelocitaDelTipoDiUnita;
var
  LKnight: Integer;
  LFootman: TWarVec2;
  LRider: TWarVec2;
begin
  LKnight := FRig.AddDude(WAR_UNIT_KNIGHT, 10, 20);
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(40, 10)]);
  FRig.Move(LKnight, [TileCenter(10, 20), TileCenter(40, 20)]);
  FRig.Run(1);
  LFootman := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  LRider := TWarUnitGeometry.CenterPosition(FRig.Entity(LKnight));
  Assert.IsTrue(Abs((LFootman.X - 168) - 16.736) < 0.4);
  Assert.IsTrue(Abs((LRider.X - 168) - 19.584) < 0.4);
end;

procedure TTestWarMoveState.DovrebbeArrendersiSeNonSiAvvicinaPerTreSecondi;
var
  LBefore: TWarVec2;
begin
  // a type without a speed (a building) does not advance: after 3 seconds the move gives up
  FRig.Entity(FSlot)^.UnitData.UnitType := WAR_UNIT_FARM_HUMANS;
  LBefore := TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot));
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(30, 10)]);
  FRig.Run(2.8);
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(FSlot));
  FRig.Run(0.5);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.AreEqual<Single>(LBefore.X, TWarUnitGeometry.CenterPosition(FRig.Entity(FSlot)).X);
end;

procedure TTestWarMoveState.DovrebbeFermarsiPerAttaccareSeLoAttaccanoEControllaGliAttacchi;
var
  LEnemy: Integer;
  LAttack: PWarStateAttack;
begin
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 40, 40, 1);
  LAttack := FRig.World.Machine.CreateAttack(LEnemy, FRig.Entity(FSlot)^.Id, FRig.Entity(FSlot)^.Position);
  FRig.World.Machine.ResetState(LEnemy, PWarStateBase(LAttack), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(30, 10)], True);
  FRig.Tick(2);
  Assert.AreEqual<Integer>(WAR_STATE_ATTACK, FRig.ActiveType(FSlot));
  Assert.IsTrue(FRig.World.Machine.Contains(FSlot, WAR_STATE_MOVE));
end;

procedure TTestWarMoveState.DovrebbeIgnorareChiLoAttaccaSeNonControllaGliAttacchi;
var
  LEnemy: Integer;
  LAttack: PWarStateAttack;
begin
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 40, 40, 1);
  LAttack := FRig.World.Machine.CreateAttack(LEnemy, FRig.Entity(FSlot)^.Id, FRig.Entity(FSlot)^.Position);
  FRig.World.Machine.ResetState(LEnemy, PWarStateBase(LAttack), WAR_CAUSE_PLAYER_ORDER);
  FRig.Tick;
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(30, 10)], False);
  FRig.Tick(2);
  Assert.AreEqual<Integer>(WAR_STATE_MOVE, FRig.ActiveType(FSlot));
end;

procedure TTestWarMoveState.DovrebbeUsareLaVelocitaPiuAltaDopoUnMiglioramento;
var
  LKnight: Integer;
  LCenter: TWarVec2;
begin
  LKnight := FRig.AddDude(WAR_UNIT_KNIGHT, 10, 20);
  FRig.World.Economy.IncreaseUpgradeLevel(FRig.World.Context.Players[0], WAR_UPGRADE_HORSES);
  Assert.AreEqual<Integer>(1, FRig.Entity(LKnight)^.UnitData.Speed);
  FRig.Move(LKnight, [TileCenter(10, 20), TileCenter(40, 20)]);
  FRig.Run(1);
  LCenter := TWarUnitGeometry.CenterPosition(FRig.Entity(LKnight));
  Assert.IsTrue(Abs((LCenter.X - 168) - 22.064) < 0.4);
end;

procedure TTestWarMoveState.DovrebbeFinireUnaMarciaDiUnaUnitaCheMuoreMentreCammina;
begin
  FRig.Move(FSlot, [TileCenter(10, 10), TileCenter(30, 10)]);
  FRig.Run(0.5);
  FRig.World.Combat.TakeDamage(FSlot, 255, 255);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_DEATH, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_MOVE]);
  Assert.AreEqual<Integer>(1, FRig.Entity(FSlot)^.StateMachine.Depth);
end;

{ TTestWarDeathState }

procedure TTestWarDeathState.Setup;
begin
  FRig := TModelRig.Create;
end;

procedure TTestWarDeathState.TearDown;
begin
  FRig.Free;
end;

function TTestWarDeathState.Kill(AUnitType: Integer; APlayer: Byte): Integer;
begin
  Result := FRig.AddDude(AUnitType, 20, 20, APlayer);
  FRig.World.Combat.TakeDamage(Result, 255, 255);
  FRig.Tick;
end;

function TTestWarDeathState.CorpseType: Integer;
var
  LIndex: Integer;
  LUnits: Integer;
begin
  Result := -1;
  LUnits := FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count;
  for LIndex := 0 to LUnits - 1 do
    if FRig.Entity(FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT][LIndex])^.UnitData.UnitType in
      [WAR_UNIT_HUMAN_CORPSE, WAR_UNIT_ORC_CORPSE] then
      Result := FRig.Entity(FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT][LIndex])^.UnitData.UnitType;
end;

procedure TTestWarDeathState.DovrebbeMorireELasciareUnCadavereDellaSuaRazza;
var
  LSlot: Integer;
begin
  LSlot := Kill(WAR_UNIT_FOOTMAN);
  Assert.AreEqual<Integer>(WAR_STATE_DEATH, FRig.ActiveType(LSlot));
  Assert.AreEqual<Integer>(1, FRig.Observer.Died);
  FRig.Run(1.5);
  Assert.AreEqual<Integer>(WAR_STATE_DEATH, FRig.ActiveType(LSlot));
  FRig.Run(0.6);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(WAR_UNIT_HUMAN_CORPSE, CorpseType);
end;

procedure TTestWarDeathState.DovrebbeLasciareUnCadavereDegliOrchi;
begin
  Kill(WAR_UNIT_GRUNT, 1);
  FRig.Run(2.5);
  Assert.AreEqual<Integer>(WAR_UNIT_ORC_CORPSE, CorpseType);
end;

procedure TTestWarDeathState.DovrebbeNonLasciareCadavereUnaCatapultaUnEvocatoUnoScheletroNeUnCadavere;
var
  LType: Integer;
begin
  for LType in [WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_SPIDER, WAR_UNIT_SKELETON] do
  begin
    FRig.Free;
    FRig := TModelRig.Create;
    Kill(LType);
    FRig.Run(120);
    Assert.AreEqual<Integer>(-1, CorpseType, Format('tipo %d', [LType]));
    Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  end;
  FRig.Free;
  FRig := TModelRig.Create;
  Kill(WAR_UNIT_FOOTMAN);
  FRig.Run(2.5);
  // the corpse is hit: it dies again and leaves no corpse
  FRig.World.Combat.TakeDamage(FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT][0], 5, 5);
  FRig.Run(30);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
end;

procedure TTestWarDeathState.DovrebbeLiberareLeCaselleELasciareLaSelezione;
var
  LSlot: Integer;
begin
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 20);
  Assert.IsTrue(FRig.Grid.IsStatic(20, 20));
  FRig.World.Combat.TakeDamage(LSlot, 255, 255);
  FRig.Tick;
  Assert.IsTrue(FRig.Grid.IsEmpty(20, 20));
  Assert.AreEqual<Integer>(1, FRig.Observer.LeftSelection);
end;

procedure TTestWarDeathState.DovrebbeDareAlCadavereLaDirezioneDiChiEMortoEIlGiocatoreNeutro;
var
  LSlot: Integer;
  LCorpse: Integer;
  LDirection: Integer;
begin
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 20, 20);
  FRig.Entity(LSlot)^.UnitData.Direction := WAR_DIRECTION_SOUTH_WEST;
  LDirection := WAR_DIRECTION_SOUTH_WEST;
  FRig.World.Combat.TakeDamage(LSlot, 255, 255);
  FRig.Run(2.5);
  LCorpse := FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT][0];
  Assert.AreEqual<Integer>(LDirection, FRig.Entity(LCorpse)^.UnitData.Direction);
  Assert.AreEqual<Integer>(4, FRig.Entity(LCorpse)^.UnitData.Player);
  Assert.AreEqual<Integer>(20, Trunc(TWarUnitGeometry.CenterTile(FRig.Entity(LCorpse)).X));
end;

procedure TTestWarDeathState.DovrebbeTogliereIlCadavereDopoLaSuaMorte;
begin
  Kill(WAR_UNIT_FOOTMAN);
  FRig.Run(2.5);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  FRig.Run(19);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  FRig.Run(2);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.EntityCount);
end;

procedure TTestWarDeathState.DovrebbeDurareQuantoLAnimazioneAllaVelocitaDellaMappa;
var
  LSlot: Integer;
  LId: Word;
begin
  // 111 frames of the footman: 1.85 s at the normal speed, 0.925 s at the fastest
  FRig.World.Context.Clock^.GameSpeed := 4;
  LSlot := Kill(WAR_UNIT_FOOTMAN);
  LId := FRig.Entity(LSlot)^.Id;
  FRig.Run(0.8);
  Assert.AreEqual<Integer>(WAR_STATE_DEATH, FRig.ActiveType(LSlot));
  FRig.Run(0.3);
  Assert.AreEqual<Integer>(1, FRig.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Pool.FindSlot(LId));
end;

end.
