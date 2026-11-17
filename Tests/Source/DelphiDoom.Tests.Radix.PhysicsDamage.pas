{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixDamageRules                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PhysicsDamage;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Physics.Damage;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPhysicsDamage = class(TObject)
  public
    [Test]
    // 80 * (1 + skill) div 5, then * (128 + random) div 384
    [TestCase('baby col numero piu basso', '80,0,0,5')]
    [TestCase('baby col numero piu alto', '80,0,255,15')]
    [TestCase('easy a meta', '80,1,128,21')]
    [TestCase('medium a meta', '80,2,128,32')]
    [TestCase('hard a meta', '80,3,128,42')]
    [TestCase('nightmare non scala per abilita', '80,4,128,53')]
    [TestCase('nightmare col numero piu alto', '80,4,255,79')]
    [TestCase('un punto resta un punto', '1,0,0,1')]
    [TestCase('mai meno di uno dopo il numero', '2,4,0,1')]
    [TestCase('colpo enorme senza traboccare', '10000000,4,255,9973958')]
    procedure DovrebbeScalareIlDannoAllaNavetta(ADamage, ASkill, ARandom, AExpected: Integer);
    [Test]
    procedure IlDannoAllaNavettaDovrebbeCrescereConLAbilita;
    [Test]
    [TestCase('normale', '1,3,False,False,False,1')]
    [TestCase('alternativo', '1,3,True,True,False,3')]
    [TestCase('opzione spenta', '1,3,True,False,False,1')]
    [TestCase('cosa senza alternativo', '1,3,False,True,False,1')]
    [TestCase('mai in una demo', '1,3,True,True,True,1')]
    procedure DovrebbeScegliereIlDannoAlternativo(ADamage, AAltDamage: Integer; AUseAlt, AVanilla, ADemo: Boolean;
      AExpected: Integer);
    [Test]
    [TestCase('toccata da un pilota', 'True,20,5,False,True,5')]
    [TestCase('toccata da un mostro', 'True,20,5,False,False,0')]
    [TestCase('toccata da chiunque', 'True,20,5,True,False,5')]
    [TestCase('non colpibile', 'False,20,5,True,True,0')]
    [TestCase('morta', 'True,0,5,True,True,0')]
    [TestCase('senza danno da contatto', 'True,20,0,True,True,0')]
    [TestCase('danno negativo', 'True,20,-3,True,True,0')]
    procedure DovrebbeDareIlDannoDaContatto(AShootable: Boolean; AHealth, ATouchDamage: Integer; AWhenTouched,
      AToucherIsPlayer: Boolean; AExpected: Integer);
    [Test]
    procedure IlDannoDiUnaCosaDovrebbeEssereQuelloDiPGetThingDamageDelFork;
  end;

implementation

{ TTestRadixPhysicsDamage }

procedure TTestRadixPhysicsDamage.DovrebbeScalareIlDannoAllaNavetta(ADamage, ASkill, ARandom, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixDamageRules.CraftDamage(ADamage, ASkill, ARandom));
end;

procedure TTestRadixPhysicsDamage.IlDannoAllaNavettaDovrebbeCrescereConLAbilita;
var
  LSkill: Integer;
  LPrevious: Integer;
  LDamage: Integer;
begin
  LPrevious := 0;
  for LSkill := 0 to TRadixDamageRules.NIGHTMARE_SKILL do
  begin
    LDamage := TRadixDamageRules.CraftDamage(100, LSkill, 200);
    Assert.IsTrue(LDamage > LPrevious, Format('abilita'' %d: %d dopo %d', [LSkill, LDamage, LPrevious]));
    LPrevious := LDamage;
  end;
  // the hardest skill takes less than the whole hit too
  Assert.IsTrue(LPrevious < 100);
end;

procedure TTestRadixPhysicsDamage.DovrebbeScegliereIlDannoAlternativo(ADamage, AAltDamage: Integer; AUseAlt, AVanilla,
  ADemo: Boolean; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixDamageRules.ThingDamage(ADamage, AAltDamage, AUseAlt, AVanilla, ADemo));
end;

procedure TTestRadixPhysicsDamage.DovrebbeDareIlDannoDaContatto(AShootable: Boolean; AHealth, ATouchDamage: Integer;
  AWhenTouched, AToucherIsPlayer: Boolean; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixDamageRules.TouchDamage(AShootable, AHealth, ATouchDamage, AWhenTouched,
    AToucherIsPlayer));
end;

// P_GetThingDamage of Rad-X (g_gameplay.pas)
function ForkThingDamage(ADemo, AVanillaOption, AUseAltDamage: Boolean; ADamage, AAltDamage: Integer): Integer;
begin
  if ADemo then
    Result := ADamage
  else if AVanillaOption and AUseAltDamage then
    Result := AAltDamage
  else
    Result := ADamage;
end;

procedure TTestRadixPhysicsDamage.IlDannoDiUnaCosaDovrebbeEssereQuelloDiPGetThingDamageDelFork;
var
  LIteration, LDamage, LAltDamage: Integer;
  LDemo, LOption, LUseAlt: Boolean;
begin
  RandSeed := 169020;
  for LIteration := 1 to 20000 do
  begin
    LDemo := Random(2) = 1;
    LOption := Random(2) = 1;
    LUseAlt := Random(2) = 1;
    LDamage := Random(100);
    LAltDamage := Random(100);
    Assert.AreEqual(ForkThingDamage(LDemo, LOption, LUseAlt, LDamage, LAltDamage),
      TRadixDamageRules.ThingDamage(LDamage, LAltDamage, LUseAlt, LOption, LDemo));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPhysicsDamage);

end.
