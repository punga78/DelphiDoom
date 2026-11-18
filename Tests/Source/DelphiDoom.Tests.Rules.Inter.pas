{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the damage filter and of the health rule of p_inter    }
{                                                                              }
{  Only what p_inter owns: the flags that stop or halve a damage, and the      }
{  health a player takes up to a limit. The limit itself belongs to the game   }
{  (TInterGameRules, replaced here by a shim that gives a number).             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Rules.Inter;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  d_player,
  DelphiDoom.Engine.World.InterRules,
  p_inter,
  p_mobj_h;

type
  [TestFixture]
  [Category('rules')]
  TTestRulesInter = class
  strict private
    FTarget: mobj_t;
    FInflictor: mobj_t;
    FPlayer: player_t;
    FPlayerMobj: mobj_t;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareDannoPienoSenzaInflictor;
    [Test]
    procedure DovrebbeDareDannoPienoSenzaFlagDiGhiaccioOFuoco;
    [Test]
    procedure DovrebbeAnnullareIlDannoDaGhiaccioSeIlBersaglioNeEImmune;
    [Test]
    procedure DovrebbeDimezzareIlDannoDaGhiaccioSeIlBersaglioResiste;
    [Test]
    procedure DovrebbeNonDimezzareUnDannoDiUnPunto;
    [Test]
    procedure DovrebbeAnnullareIlDannoDaFuocoSeIlBersaglioNeEImmune;
    [Test]
    procedure DovrebbeDimezzareIlDannoDaFuocoSeIlBersaglioResiste;
    [Test]
    procedure DovrebbeDimezzareDueVolteSeIlDannoEDiGhiaccioEDiFuoco;
    [Test]
    procedure DovrebbeDareSaluteFinoAlLimiteESegnarlaSulMostro;
    [Test]
    procedure DovrebbeNonDareSaluteSeIlGiocatoreHaGiaIlLimite;
    [Test]
    procedure DovrebbeNonAbbassareLaSaluteOltreIlLimite;
  end;

implementation

{ TTestRulesInter }

procedure TTestRulesInter.Setup;
begin
  FillChar(FTarget, SizeOf(FTarget), 0);
  FillChar(FInflictor, SizeOf(FInflictor), 0);
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FillChar(FPlayerMobj, SizeOf(FPlayerMobj), 0);
  FPlayer.mo := @FPlayerMobj;
  TInterGameRules.ShimMaxHealth := 100;
end;

procedure TTestRulesInter.DovrebbeDareDannoPienoSenzaInflictor;
var
  LDamage: Integer;
begin
  LDamage := 40;
  Assert.IsTrue(P_DamageFlagFilter(@FTarget, nil, LDamage));
  Assert.AreEqual(40, LDamage);
end;

procedure TTestRulesInter.DovrebbeDareDannoPienoSenzaFlagDiGhiaccioOFuoco;
var
  LDamage: Integer;
begin
  FTarget.flags3_ex := MF3_EX_NOFREEZEDAMAGE or MF3_EX_FREEZEDAMAGERESIST or MF3_EX_NOFLAMEDAMAGE;
  FTarget.flags4_ex := MF4_EX_FLAMEDAMAGERESIST;
  LDamage := 40;
  Assert.IsTrue(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
  Assert.AreEqual(40, LDamage);
end;

procedure TTestRulesInter.DovrebbeAnnullareIlDannoDaGhiaccioSeIlBersaglioNeEImmune;
var
  LDamage: Integer;
begin
  FInflictor.flags3_ex := MF3_EX_FREEZEDAMAGE;
  FTarget.flags3_ex := MF3_EX_NOFREEZEDAMAGE;
  LDamage := 40;
  Assert.IsFalse(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
end;

procedure TTestRulesInter.DovrebbeDimezzareIlDannoDaGhiaccioSeIlBersaglioResiste;
var
  LDamage: Integer;
begin
  FInflictor.flags3_ex := MF3_EX_FREEZEDAMAGE;
  FTarget.flags3_ex := MF3_EX_FREEZEDAMAGERESIST;
  LDamage := 40;
  Assert.IsTrue(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
  Assert.AreEqual(20, LDamage);
  // an odd damage is rounded down
  LDamage := 41;
  Assert.IsTrue(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
  Assert.AreEqual(20, LDamage);
end;

procedure TTestRulesInter.DovrebbeNonDimezzareUnDannoDiUnPunto;
var
  LDamage: Integer;
begin
  FInflictor.flags3_ex := MF3_EX_FREEZEDAMAGE or MF3_EX_FLAMEDAMAGE;
  FTarget.flags3_ex := MF3_EX_FREEZEDAMAGERESIST;
  FTarget.flags4_ex := MF4_EX_FLAMEDAMAGERESIST;
  LDamage := 1;
  Assert.IsTrue(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
  Assert.AreEqual(1, LDamage);
end;

procedure TTestRulesInter.DovrebbeAnnullareIlDannoDaFuocoSeIlBersaglioNeEImmune;
var
  LDamage: Integer;
begin
  FInflictor.flags3_ex := MF3_EX_FLAMEDAMAGE;
  FTarget.flags3_ex := MF3_EX_NOFLAMEDAMAGE;
  LDamage := 40;
  Assert.IsFalse(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
end;

procedure TTestRulesInter.DovrebbeDimezzareIlDannoDaFuocoSeIlBersaglioResiste;
var
  LDamage: Integer;
begin
  FInflictor.flags3_ex := MF3_EX_FLAMEDAMAGE;
  FTarget.flags4_ex := MF4_EX_FLAMEDAMAGERESIST;
  LDamage := 40;
  Assert.IsTrue(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
  Assert.AreEqual(20, LDamage);
end;

procedure TTestRulesInter.DovrebbeDimezzareDueVolteSeIlDannoEDiGhiaccioEDiFuoco;
var
  LDamage: Integer;
begin
  FInflictor.flags3_ex := MF3_EX_FREEZEDAMAGE or MF3_EX_FLAMEDAMAGE;
  FTarget.flags3_ex := MF3_EX_FREEZEDAMAGERESIST;
  FTarget.flags4_ex := MF4_EX_FLAMEDAMAGERESIST;
  LDamage := 40;
  Assert.IsTrue(P_DamageFlagFilter(@FTarget, @FInflictor, LDamage));
  Assert.AreEqual(10, LDamage);
end;

procedure TTestRulesInter.DovrebbeDareSaluteFinoAlLimiteESegnarlaSulMostro;
begin
  FPlayer.health := 70;
  Assert.IsTrue(P_GiveBody(@FPlayer, 10));
  Assert.AreEqual(80, FPlayer.health);
  Assert.AreEqual(80, FPlayerMobj.health);
  Assert.IsTrue(P_GiveBody(@FPlayer, 50));
  Assert.AreEqual(100, FPlayer.health);
  Assert.AreEqual(100, FPlayerMobj.health);
end;

procedure TTestRulesInter.DovrebbeNonDareSaluteSeIlGiocatoreHaGiaIlLimite;
begin
  FPlayer.health := 100;
  FPlayerMobj.health := 7;
  Assert.IsFalse(P_GiveBody(@FPlayer, 10));
  Assert.AreEqual(100, FPlayer.health);
  Assert.AreEqual(7, FPlayerMobj.health);
end;

procedure TTestRulesInter.DovrebbeNonAbbassareLaSaluteOltreIlLimite;
begin
  // above the limit (a soul sphere): nothing is given and nothing is taken
  TInterGameRules.ShimMaxHealth := 100;
  FPlayer.health := 150;
  Assert.IsFalse(P_GiveBody(@FPlayer, 10));
  Assert.AreEqual(150, FPlayer.health);
end;

end.