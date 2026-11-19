{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the armor and the dropped things (PickupGivers)        }
{                                                                              }
{  The unit is the same for Doom, Heretic and Strife. What a game decides      }
{  (negative armor of Strife, the version that scatters the drops, the         }
{  compatibility mode) is given by the shim of TInterGameRules, with the       }
{  constants of the game of the project. The oracles are written from the      }
{  meaning of the rule: an armor is picked up only if it is better, a dropped  }
{  thing carries MF_DROPPED and, out of compatibility, falls from 32 units.    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Rules.PickupGivers;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  d_player,
  m_fixed,
  p_mobj_h;

type
  [TestFixture]
  [Category('rules')]
  TTestRulesPickupGivers = class
  strict private
    FPlayer: player_t;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareUnaArmaturaSeIlGiocatoreNonNeHa;
    [Test]
    procedure DovrebbeDareUnaArmaturaMigliore;
    [Test]
    procedure DovrebbeRifiutareUnaArmaturaUgualeOPeggiore;
    [Test]
    procedure DovrebbeRifiutareUnaArmaturaPeggioreAncheSeDiTipoDiverso;
    [Test]
    procedure DovrebbeNonModificareIlGiocatoreSeLArmaturaERifiutata;
    [Test]
    procedure DovrebbeMarcareLOggettoComeCaduto;
    [Test]
    procedure DovrebbeFarCadereLOggettoFuoriDallaCompatibilita;
    [Test]
    procedure DovrebbeLasciareFermoLOggettoInCompatibilita;
    [Test]
    procedure DovrebbeDisperdereLOggettoDallaVersioneDiScatter;
    [Test]
    procedure DovrebbeNonDisperdereLOggettoPrimaDellaVersioneDiScatter;
    [Test]
    procedure DovrebbeChiedereLOggettoDelTipoRichiesto;
    {$IFDEF STRIFE}
    [Test]
    procedure DovrebbeRifiutareLArmaturaNegativaSeIlGiocatoreHaPunti;
    [Test]
    procedure DovrebbeDareLArmaturaNegativaSeIlGiocatoreNonHaPunti;
    {$ENDIF}
  end;

implementation

uses
  g_game,
  m_rnd,
  p_mobj,
  DelphiDoom.MathCore.Factory,
  DelphiDoom.Engine.World.InterRules,
  DelphiDoom.Engine.World.PickupGivers;

{ TTestRulesPickupGivers }

procedure TTestRulesPickupGivers.Setup;
begin
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  M_ConfigureRandom(TMathCoreFactory.CreateGameRandom);
  TInterGameRules.ShimNeedsCompatibility := False;
  shim_engineversion := 207;
  TShimMobjSpawn.Count := 0;
  TShimMobjSpawn.LastType := -1;
end;

procedure TTestRulesPickupGivers.TearDown;
begin
  shim_engineversion := 203;
  TInterGameRules.ShimNeedsCompatibility := False;
end;

procedure TTestRulesPickupGivers.DovrebbeDareUnaArmaturaSeIlGiocatoreNonNeHa;
begin
  Assert.IsTrue(P_GiveArmor(@FPlayer, 1));
  Assert.AreEqual<Integer>(1, FPlayer.armortype);
  Assert.AreEqual<Integer>(100, FPlayer.armorpoints);
end;

procedure TTestRulesPickupGivers.DovrebbeDareUnaArmaturaMigliore;
begin
  FPlayer.armortype := 1;
  FPlayer.armorpoints := 100;
  Assert.IsTrue(P_GiveArmor(@FPlayer, 2));
  Assert.AreEqual<Integer>(2, FPlayer.armortype);
  Assert.AreEqual<Integer>(200, FPlayer.armorpoints);
end;

procedure TTestRulesPickupGivers.DovrebbeRifiutareUnaArmaturaUgualeOPeggiore;
begin
  FPlayer.armortype := 2;
  FPlayer.armorpoints := 200;
  Assert.IsFalse(P_GiveArmor(@FPlayer, 2));
  Assert.IsFalse(P_GiveArmor(@FPlayer, 1));
end;

procedure TTestRulesPickupGivers.DovrebbeRifiutareUnaArmaturaPeggioreAncheSeDiTipoDiverso;
begin
  // the rule compares the points, not the type: a damaged better armor still beats a new worse one
  FPlayer.armortype := 2;
  FPlayer.armorpoints := 150;
  Assert.IsFalse(P_GiveArmor(@FPlayer, 1));
  Assert.AreEqual<Integer>(2, FPlayer.armortype);
  Assert.AreEqual<Integer>(150, FPlayer.armorpoints);
end;

procedure TTestRulesPickupGivers.DovrebbeNonModificareIlGiocatoreSeLArmaturaERifiutata;
begin
  FPlayer.armortype := 2;
  FPlayer.armorpoints := 200;
  P_GiveArmor(@FPlayer, 1);
  Assert.AreEqual<Integer>(2, FPlayer.armortype);
  Assert.AreEqual<Integer>(200, FPlayer.armorpoints);
end;

procedure TTestRulesPickupGivers.DovrebbeChiedereLOggettoDelTipoRichiesto;
begin
  P_SpawnDroppedMobj(10 * FRACUNIT, 20 * FRACUNIT, 5 * FRACUNIT, 7);
  Assert.AreEqual(1, TShimMobjSpawn.Count);
  Assert.AreEqual(7, TShimMobjSpawn.LastType);
end;

procedure TTestRulesPickupGivers.DovrebbeMarcareLOggettoComeCaduto;
var
  LMobj: Pmobj_t;
begin
  TInterGameRules.ShimNeedsCompatibility := True;
  LMobj := P_SpawnDroppedMobj(0, 0, 0, 1);
  Assert.IsTrue((LMobj.flags and MF_DROPPED) <> 0);
end;

procedure TTestRulesPickupGivers.DovrebbeFarCadereLOggettoFuoriDallaCompatibilita;
var
  LMobj: Pmobj_t;
begin
  LMobj := P_SpawnDroppedMobj(0, 0, 8 * FRACUNIT, 1);
  Assert.AreEqual<Integer>(40 * FRACUNIT, LMobj.z);
  Assert.AreEqual<Integer>(4 * FRACUNIT, LMobj.momz);
end;

procedure TTestRulesPickupGivers.DovrebbeLasciareFermoLOggettoInCompatibilita;
var
  LMobj: Pmobj_t;
begin
  TInterGameRules.ShimNeedsCompatibility := True;
  LMobj := P_SpawnDroppedMobj(0, 0, 8 * FRACUNIT, 1);
  Assert.AreEqual<Integer>(8 * FRACUNIT, LMobj.z);
  Assert.AreEqual<Integer>(0, LMobj.momz);
  Assert.AreEqual<Integer>(0, LMobj.momx);
  Assert.AreEqual<Integer>(0, LMobj.momy);
end;

procedure TTestRulesPickupGivers.DovrebbeDisperdereLOggettoDallaVersioneDiScatter;
var
  LMobj: Pmobj_t;
begin
  shim_engineversion := TInterGameRules.DroppedScatterVersion;
  LMobj := P_SpawnDroppedMobj(0, 0, 0, 1);
  // N_Random is a signed byte: the speed is a multiple of 64 within +-255 * 64
  Assert.AreEqual<Integer>(0, LMobj.momx mod 64);
  Assert.AreEqual<Integer>(0, LMobj.momy mod 64);
  Assert.IsTrue(Abs(LMobj.momx) <= 255 * 64);
  Assert.IsTrue(Abs(LMobj.momy) <= 255 * 64);
end;

procedure TTestRulesPickupGivers.DovrebbeNonDisperdereLOggettoPrimaDellaVersioneDiScatter;
var
  LMobj: Pmobj_t;
begin
  shim_engineversion := TInterGameRules.DroppedScatterVersion - 1;
  LMobj := P_SpawnDroppedMobj(0, 0, 0, 1);
  Assert.AreEqual<Integer>(0, LMobj.momx);
  Assert.AreEqual<Integer>(0, LMobj.momy);
end;

{$IFDEF STRIFE}
procedure TTestRulesPickupGivers.DovrebbeRifiutareLArmaturaNegativaSeIlGiocatoreHaPunti;
begin
  FPlayer.armortype := 1;
  FPlayer.armorpoints := 50;
  Assert.IsFalse(P_GiveArmor(@FPlayer, -2));
  Assert.AreEqual<Integer>(50, FPlayer.armorpoints);
end;

procedure TTestRulesPickupGivers.DovrebbeDareLArmaturaNegativaSeIlGiocatoreNonHaPunti;
begin
  // the negative type is a pickup that works only on a player without armor: the type is taken without the sign
  Assert.IsTrue(P_GiveArmor(@FPlayer, -2));
  Assert.AreEqual<Integer>(2, FPlayer.armortype);
  Assert.AreEqual<Integer>(200, FPlayer.armorpoints);
end;
{$ENDIF}

end.
