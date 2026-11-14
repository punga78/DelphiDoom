{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the idle and wait states             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelIdle;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ModelRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarIdleState = class(TObject)
  private
    FRig: TModelRig;
    FRandom: TScriptedRandom;
    procedure StartRig(const AValues: array of Integer; AUnsigned: Boolean = False);
    function DirectionAfter(AInitial, AChance, AStep: Integer; AUnsigned: Boolean): Integer;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeOccuparELiberareLeCaselleDellUnita;
    [Test]
    procedure DovrebbeGuardarsiIntornoUnaVoltaAlSecondo;
    [Test]
    procedure DovrebbeNonGuardarsiIntornoUnEdificio;
    [Test]
    procedure DovrebbeGirareDalNordAlNordOvestSeLaDirezioneHaIlSegno;
    [Test]
    procedure DovrebbeGirareDalNordAlNordSeLaDirezioneESenzaSegnoComeIlCCompilatoConGcc;
    [Test]
    procedure DovrebbeGirareDalNordOvestAlNordPassandoLOttavaDirezione;
    [Test]
    procedure DovrebbeLasciareLaDirezioneSeNonCambia;
    [Test]
    procedure DovrebbeFarAttaccareUnGuerrieroCheVedeUnNemicoVicino;
    [Test]
    procedure DovrebbeNonFarAttaccareUnLavoratoreNeUnGuerrieroSenzaNemici;
    [Test]
    procedure DovrebbeNonVedereUnNemicoInvisibileNeLontano;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarWaitState = class(TObject)
  private
    FRig: TModelRig;
    FSlot: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAspettareELasciareLaMessaAlloStatoSotto;
    [Test]
    procedure DovrebbeOccuparLeCaselleMentreAspetta;
    [Test]
    procedure DovrebbeNonLiberareLeCaselleUscendoConLoStackNonVuotoComeIlC;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.Context;

{ TTestWarIdleState }

procedure TTestWarIdleState.StartRig(const AValues: array of Integer; AUnsigned: Boolean);
begin
  FRandom := TScriptedRandom.Create(AValues);
  FRig := TModelRig.Create(FRandom);
  FRig.World.Context.UnsignedDirections := AUnsigned;
end;

function TTestWarIdleState.DirectionAfter(AInitial, AChance, AStep: Integer; AUnsigned: Boolean): Integer;
var
  LSlot: Integer;
begin
  StartRig([AInitial, AChance, AStep], AUnsigned);
  LSlot := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  Result := FRig.Entity(LSlot)^.UnitData.Direction;
end;

procedure TTestWarIdleState.TearDown;
begin
  FreeAndNil(FRig);
end;

procedure TTestWarIdleState.DovrebbeOccuparELiberareLeCaselleDellUnita;
var
  LSlot: Integer;
begin
  FRig := TModelRig.Create;
  LSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 12);
  Assert.IsTrue(FRig.Grid.IsStatic(10, 12));
  Assert.AreEqual<Integer>(Integer(FRig.Entity(LSlot)^.Id), Integer(FRig.Grid.GetTileEntityId(10, 12)));
  FRig.World.Combat.TakeDamage(LSlot, 255, 255);
  FRig.Tick;
  // the idle state left and the death does not occupy anything
  Assert.IsTrue(FRig.Grid.IsEmpty(10, 12));
end;

procedure TTestWarIdleState.DovrebbeGuardarsiIntornoUnaVoltaAlSecondo;
begin
  // a direction, then "no" (50 is not under 20) to every look
  StartRig([0, 50, 50, 50, 50, 50, 50, 50]);
  FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  Assert.AreEqual<Integer>(2, FRandom.Draws);
  FRig.Run(3.2);
  Assert.AreEqual<Integer>(2 + 3, FRandom.Draws);
end;

procedure TTestWarIdleState.DovrebbeNonGuardarsiIntornoUnEdificio;
begin
  StartRig([3]);
  FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 10, 10);
  FRig.Run(5);
  Assert.AreEqual<Integer>(1, FRandom.Draws);
end;

procedure TTestWarIdleState.DovrebbeGirareDalNordAlNordOvestSeLaDirezioneHaIlSegno;
begin
  Assert.AreEqual<Integer>(WAR_DIRECTION_NORTH_WEST, DirectionAfter(WAR_DIRECTION_NORTH, 0, 0, False));
end;

procedure TTestWarIdleState.DovrebbeGirareDalNordAlNordSeLaDirezioneESenzaSegnoComeIlCCompilatoConGcc;
begin
  Assert.AreEqual<Integer>(WAR_DIRECTION_NORTH, DirectionAfter(WAR_DIRECTION_NORTH, 0, 0, True));
end;

procedure TTestWarIdleState.DovrebbeGirareDalNordOvestAlNordPassandoLOttavaDirezione;
begin
  Assert.AreEqual<Integer>(WAR_DIRECTION_NORTH, DirectionAfter(WAR_DIRECTION_NORTH_WEST, 0, 2, False));
  TearDown;
  Assert.AreEqual<Integer>(WAR_DIRECTION_NORTH, DirectionAfter(WAR_DIRECTION_NORTH_WEST, 0, 2, True));
end;

procedure TTestWarIdleState.DovrebbeLasciareLaDirezioneSeNonCambia;
begin
  Assert.AreEqual<Integer>(WAR_DIRECTION_SOUTH, DirectionAfter(WAR_DIRECTION_SOUTH, 0, 1, False));
  TearDown;
  Assert.AreEqual<Integer>(WAR_DIRECTION_EAST, DirectionAfter(WAR_DIRECTION_SOUTH_EAST, 0, 0, False));
  TearDown;
  Assert.AreEqual<Integer>(WAR_DIRECTION_SOUTH, DirectionAfter(WAR_DIRECTION_SOUTH, 50, 0, False));
end;

procedure TTestWarIdleState.DovrebbeFarAttaccareUnGuerrieroCheVedeUnNemicoVicino;
var
  LFirst: Integer;
  LSecond: Integer;
begin
  FRig := TModelRig.Create;
  LFirst := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10, 0);
  Assert.IsFalse(FRig.World.Machine.IsGoingToAttack(LFirst));
  LSecond := FRig.AddDude(WAR_UNIT_GRUNT, 13, 10, 1);
  // the grunt sees the footman at once: the attack waits for the next tic and is of the autonomous cause
  Assert.IsTrue(FRig.World.Machine.IsGoingToAttack(LSecond));
  Assert.AreEqual<Integer>(WAR_CAUSE_AUTONOMOUS, FRig.Entity(LSecond)^.StateMachine.Pending.Cause);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_ATTACK, FRig.ActiveType(LSecond));
  Assert.AreEqual<Integer>(Integer(FRig.Entity(LFirst)^.Id),
    Integer(PWarStateAttack(FRig.World.Machine.ActiveState(LSecond))^.TargetEntityId));
  // the footman sees the grunt at its next look
  FRig.Run(1.2);
  Assert.IsTrue(FRig.World.Machine.IsAttacking(LFirst));
end;

procedure TTestWarIdleState.DovrebbeNonFarAttaccareUnLavoratoreNeUnGuerrieroSenzaNemici;
var
  LPeasant: Integer;
  LWarrior: Integer;
begin
  FRig := TModelRig.Create;
  LPeasant := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10, 0);
  FRig.AddDude(WAR_UNIT_GRUNT, 12, 10, 1);
  LWarrior := FRig.AddDude(WAR_UNIT_FOOTMAN, 30, 30, 0);
  FRig.AddDude(WAR_UNIT_FOOTMAN, 31, 30, 0);
  // a neutral unit is nobody's enemy
  FRig.AddDude(WAR_UNIT_OGRE, 31, 31, 4);
  FRig.Run(2.5);
  Assert.IsFalse(FRig.World.Machine.IsGoingToAttack(LPeasant) or FRig.World.Machine.IsAttacking(LPeasant));
  Assert.IsFalse(FRig.World.Machine.IsGoingToAttack(LWarrior) or FRig.World.Machine.IsAttacking(LWarrior));
end;

procedure TTestWarIdleState.DovrebbeNonVedereUnNemicoInvisibileNeLontano;
var
  LEnemy: Integer;
  LWatcher: Integer;
begin
  FRig := TModelRig.Create;
  LEnemy := FRig.AddDude(WAR_UNIT_GRUNT, 10, 10, 1);
  FRig.Entity(LEnemy)^.UnitData.Invisible := True;
  LWatcher := FRig.AddDude(WAR_UNIT_FOOTMAN, 12, 10, 0);
  FRig.AddDude(WAR_UNIT_GRUNT, 20, 10, 1);
  FRig.Run(1.2);
  Assert.IsFalse(FRig.World.Machine.IsGoingToAttack(LWatcher) or FRig.World.Machine.IsAttacking(LWatcher));
end;

{ TTestWarWaitState }

procedure TTestWarWaitState.Setup;
begin
  FRig := TModelRig.Create;
  FSlot := FRig.AddDude(WAR_UNIT_PEASANT, 10, 10);
  FRig.World.Machine.PushState(FSlot, PWarStateBase(FRig.World.Machine.CreateWait(FSlot, 1.0)), WAR_CAUSE_AI_ORDER);
end;

procedure TTestWarWaitState.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarWaitState.DovrebbeAspettareELasciareLaMessaAlloStatoSotto;
begin
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_WAIT, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(2, FRig.Entity(FSlot)^.StateMachine.Depth);
  FRig.Run(0.8);
  Assert.AreEqual<Integer>(WAR_STATE_WAIT, FRig.ActiveType(FSlot));
  FRig.Run(0.4);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(1, FRig.Entity(FSlot)^.StateMachine.Depth);
  Assert.AreEqual<Integer>(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_WAIT]);
end;

procedure TTestWarWaitState.DovrebbeOccuparLeCaselleMentreAspetta;
begin
  FRig.Grid.SetFreeTiles(10, 10, 1, 1);
  Assert.IsTrue(FRig.Grid.IsEmpty(10, 10));
  FRig.Tick;
  Assert.IsTrue(FRig.Grid.IsStatic(10, 10));
end;

procedure TTestWarWaitState.DovrebbeNonLiberareLeCaselleUscendoConLoStackNonVuotoComeIlC;
begin
  FRig.Tick;
  FRig.Grid.SetFreeTiles(10, 10, 1, 1);
  FRig.Run(1.2);
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.IsTrue(FRig.Grid.IsEmpty(10, 10));
end;

end.
