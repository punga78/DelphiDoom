{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - hit points, mana and damage          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelCombat;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.War.ModelRig;

type
  [TestFixture]
  [Category('war')]
  TTestWarCombat = class(TObject)
  private
    FRig: TModelRig;
    FSlot: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase('senza armatura', '3,10,0,13')]
    [TestCase('armatura minore', '3,10,4,9')]
    [TestCase('armatura maggiore', '3,10,40,3')]
    [TestCase('nessun danno', '0,0,0,0')]
    procedure DovrebbeSommareIlMinimoEQuelloCasualeMenoLArmatura(AMin, ARnd, AArmor, AExpected: Integer);
    [Test]
    procedure DovrebbeDareECurarePuntiFerita;
    [Test]
    procedure DovrebbeDareEToglierePuntiManaFraZeroEIlMassimo;
    [Test]
    procedure DovrebbeDareFalsoESegnalareSeNonCeAbbastanzaMana;
    [Test]
    procedure DovrebbeFerireUnaUnitaSenzaUccidere;
    [Test]
    procedure DovrebbeTenereContoDellArmatura;
    [Test]
    procedure DovrebbeFarMorireUnaUnitaSenzaPuntiFerita;
    [Test]
    procedure DovrebbeNonFerireUnaUnitaInvulnerabile;
    [Test]
    procedure DovrebbeNonFerireIlGiocatoreInModalitaDio;
    [Test]
    procedure DovrebbeFarCrollareUnEdificioSenzaPuntiFerita;
    [Test]
    procedure DovrebbeDireQuantoEDanneggiatoUnEdificioInPiedi;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Combat;

{ TTestWarCombat }

procedure TTestWarCombat.Setup;
begin
  FRig := TModelRig.Create;
  FSlot := FRig.AddDude(WAR_UNIT_FOOTMAN, 10, 10);
end;

procedure TTestWarCombat.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarCombat.DovrebbeSommareIlMinimoEQuelloCasualeMenoLArmatura(AMin, ARnd, AArmor, AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, TWarCombat.TotalDamage(AMin, ARnd, AArmor));
end;

procedure TTestWarCombat.DovrebbeDareECurarePuntiFerita;
begin
  FRig.World.Combat.DecreaseHp(FSlot, 25);
  Assert.AreEqual<Integer>(35, FRig.Entity(FSlot)^.UnitData.Hp);
  FRig.World.Combat.IncreaseHp(FSlot, 10);
  Assert.AreEqual<Integer>(45, FRig.Entity(FSlot)^.UnitData.Hp);
  FRig.World.Combat.IncreaseHp(FSlot, 1000);
  Assert.AreEqual<Integer>(60, FRig.Entity(FSlot)^.UnitData.Hp);
  FRig.World.Combat.DecreaseHp(FSlot, 1000);
  Assert.AreEqual<Integer>(0, FRig.Entity(FSlot)^.UnitData.Hp);
end;

procedure TTestWarCombat.DovrebbeDareEToglierePuntiManaFraZeroEIlMassimo;
var
  LMage: Integer;
begin
  LMage := FRig.AddDude(WAR_UNIT_CONJURER, 12, 12);
  Assert.AreEqual<Integer>(100, FRig.Entity(LMage)^.UnitData.Mana);
  Assert.AreEqual<Integer>(255, FRig.Entity(LMage)^.UnitData.MaxMana);
  FRig.World.Combat.IncreaseMana(LMage, 1000);
  Assert.AreEqual<Integer>(255, FRig.Entity(LMage)^.UnitData.Mana);
  Assert.IsTrue(FRig.World.Combat.DecreaseMana(LMage, 255));
  Assert.AreEqual<Integer>(0, FRig.Entity(LMage)^.UnitData.Mana);
  // a unit with no maximum of mana (-1) is clamped to 0
  FRig.World.Combat.IncreaseMana(FSlot, 5);
  Assert.AreEqual<Integer>(0, FRig.Entity(FSlot)^.UnitData.Mana);
end;

procedure TTestWarCombat.DovrebbeDareFalsoESegnalareSeNonCeAbbastanzaMana;
begin
  Assert.IsFalse(FRig.World.Combat.DecreaseMana(FSlot, 101));
  Assert.AreEqual<Cardinal>(1, FRig.Observer.FlashCount);
  Assert.AreEqual<Integer>(Ord(wsmNotEnoughMana), Ord(FRig.Observer.LastMessage));
  Assert.AreEqual<Integer>(100, FRig.Entity(FSlot)^.UnitData.Mana);
end;

procedure TTestWarCombat.DovrebbeFerireUnaUnitaSenzaUccidere;
begin
  FRig.World.Combat.TakeDamage(FSlot, 5, 20);
  // 5 + (20 - 2 armor)
  Assert.AreEqual<Integer>(60 - 23, FRig.Entity(FSlot)^.UnitData.Hp);
  FRig.Tick;
  Assert.AreEqual<Integer>(WAR_STATE_IDLE, FRig.ActiveType(FSlot));
  Assert.AreEqual<Integer>(0, FRig.Observer.Died);
end;

procedure TTestWarCombat.DovrebbeTenereContoDellArmatura;
var
  LKnight: Integer;
begin
  LKnight := FRig.AddDude(WAR_UNIT_KNIGHT, 12, 12);
  FRig.World.Combat.TakeDamage(LKnight, 0, 4);
  Assert.AreEqual<Integer>(90, FRig.Entity(LKnight)^.UnitData.Hp);
end;

procedure TTestWarCombat.DovrebbeFarMorireUnaUnitaSenzaPuntiFerita;
begin
  FRig.World.Combat.TakeDamage(FSlot, 100, 0);
  Assert.AreEqual<Integer>(0, FRig.Entity(FSlot)^.UnitData.Hp);
  Assert.IsTrue(FRig.World.Machine.IsGoingToDie(FSlot));
  Assert.AreEqual<Integer>(WAR_CAUSE_LIFECYCLE, FRig.Entity(FSlot)^.StateMachine.Pending.Cause);
  Assert.AreEqual<Integer>(1, FRig.Observer.Died);
  Assert.AreEqual<Cardinal>(1, FRig.Observer.AudioCount);
end;

procedure TTestWarCombat.DovrebbeNonFerireUnaUnitaInvulnerabile;
begin
  FRig.Entity(FSlot)^.UnitData.Invulnerable := True;
  FRig.World.Combat.TakeDamage(FSlot, 100, 100);
  Assert.AreEqual<Integer>(60, FRig.Entity(FSlot)^.UnitData.Hp);
end;

procedure TTestWarCombat.DovrebbeNonFerireIlGiocatoreInModalitaDio;
begin
  FRig.World.Context.Players[0]^.GodMode := True;
  FRig.World.Combat.TakeDamage(FSlot, 100, 100);
  Assert.AreEqual<Integer>(60, FRig.Entity(FSlot)^.UnitData.Hp);
end;

procedure TTestWarCombat.DovrebbeFarCrollareUnEdificioSenzaPuntiFerita;
var
  LFarm: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 20);
  FRig.World.Combat.TakeDamage(LFarm, 500, 0);
  Assert.AreEqual<Integer>(0, FRig.Entity(LFarm)^.UnitData.Hp);
  Assert.IsTrue(FRig.World.Machine.IsGoingToCollapse(LFarm));
  Assert.AreEqual<Integer>(1, FRig.Observer.Collapsing);
  FRig.Tick;
  // the collapse is not ported: the state is there and nothing updates it
  Assert.IsTrue(FRig.World.Machine.IsCollapsing(LFarm));
  FRig.Run(5);
  Assert.IsTrue(FRig.World.Machine.IsCollapsing(LFarm));
end;

procedure TTestWarCombat.DovrebbeDireQuantoEDanneggiatoUnEdificioInPiedi;
var
  LFarm: Integer;
begin
  LFarm := FRig.AddBuilding(WAR_UNIT_FARM_HUMANS, 20, 20);
  FRig.World.Combat.TakeDamage(LFarm, 100, 0);
  Assert.AreEqual<Integer>(-1, FRig.Observer.DamagePercent);
  FRig.World.Combat.TakeDamage(LFarm, 140, 0);
  Assert.AreEqual<Integer>(40, FRig.Observer.DamagePercent);
  FRig.World.Combat.TakeDamage(LFarm, 140, 0);
  Assert.AreEqual<Integer>(5, FRig.Observer.DamagePercent);
end;

end.
