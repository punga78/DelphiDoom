{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the greed library - the tables of the game         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.GameTables;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedGameTables = class
  public
    [Test]
    procedure DovrebbeAvereLeDiciannoveArmiDellOriginale;
    [Test]
    procedure DovrebbeAvereUnRecordDellArmaDiVentiByte;
    [Test]
    procedure DovrebbeAvereLaTabellaDelDondolioConIlFattore;
    [Test]
    procedure DovrebbeAvereINomiDeiSeiPersonaggi;
    [Test]
    procedure DovrebbeAvereUnNomeDiLumpPerOgniSpriteGenerato;
    [Test]
    [TestCase('mostro 1', '75,True')]
    [TestCase('mostro 1 senza ombra', '76,True')]
    [TestCase('mostro 13', '34,True')]
    [TestCase('mostro 5', '99,True')]
    [TestCase('non un mostro', '83,False')]
    [TestCase('proiettile', '513,False')]
    [TestCase('zero', '0,False')]
    procedure DovrebbeRiconoscereIMostri(AKind: Integer; AExpected: Boolean);
    [Test]
    procedure DovrebbeDareIlTestoDellaMissioneDelGiocoEDellaDemo;
    [Test]
    [TestCase('mappa negativa', '-1,0')]
    [TestCase('mappa oltre', '30,0')]
    [TestCase('pezzo negativo', '1,-1')]
    [TestCase('pezzo oltre', '1,3')]
    procedure DovrebbeDareUnTestoVuotoFuoriDaiLimiti(AMap, AStringNumber: Integer);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables;

procedure TTestGreedGameTables.DovrebbeAvereLeDiciannoveArmiDellOriginale;
begin
  Assert.AreEqual(19, Length(TGreedGameTables.Weapons));
  Assert.AreEqual(6, TGreedGameTables.Weapons[0].ChargeRate);
  Assert.AreEqual(75, TGreedGameTables.Weapons[18].AmmoRate);
  Assert.AreEqual(2, TGreedGameTables.Weapons[18].AmmoType);
  Assert.AreEqual(19, Length(TGreedGameTables.WeaponState));
end;

procedure TTestGreedGameTables.DovrebbeAvereUnRecordDellArmaDiVentiByte;
begin
  Assert.AreEqual(20, SizeOf(TGreedWeaponInfo));
end;

procedure TTestGreedGameTables.DovrebbeAvereLaTabellaDelDondolioConIlFattore;
begin
  Assert.AreEqual(GREED_HEADBOBFACTOR * GREED_MAXBOBS + 1, Length(TGreedGameTables.HeadMove));
  Assert.AreEqual(0, TGreedGameTables.HeadMove[0]);
  Assert.AreEqual(GREED_BOBFACTOR * 1715, TGreedGameTables.HeadMove[1]);
  Assert.AreEqual(GREED_WEAPONBOBFACTOR * GREED_MAXBOBS + 1, Length(TGreedGameTables.WeaponMove));
end;

procedure TTestGreedGameTables.DovrebbeAvereINomiDeiSeiPersonaggi;
begin
  Assert.AreEqual(GREED_MAXCHARTYPES, Length(TGreedGameTables.CharacterNames));
  Assert.AreEqual('cyborg', TGreedGameTables.CharacterNames[0]);
  Assert.AreEqual('bighead', TGreedGameTables.CharacterNames[5]);
  Assert.AreEqual(42 * GREED_FRACUNIT, TGreedGameTables.PlayerHeights[0]);
  Assert.AreEqual((GREED_FRACUNIT * 5) div 2, TGreedGameTables.PlayerMoveSpeed);
end;

procedure TTestGreedGameTables.DovrebbeAvereUnNomeDiLumpPerOgniSpriteGenerato;
var
  LName: string;
begin
  Assert.AreEqual(GREED_S_END - GREED_S_START + 1, Length(TGreedGameTables.SpriteLumpNames));
  for LName in TGreedGameTables.SpriteLumpNames do
    Assert.IsNotEmpty(LName);
  Assert.AreEqual('pulsebullet', TGreedGameTables.SpriteLumpNames[0]);
end;

procedure TTestGreedGameTables.DovrebbeRiconoscereIMostri(AKind: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TGreedGameTables.IsMonster(AKind));
end;

procedure TTestGreedGameTables.DovrebbeDareIlTestoDellaMissioneDelGiocoEDellaDemo;
begin
  Assert.StartsWith('Sublevel 2:'#13#10'Primary Holding', TGreedGameTables.MissionInfo(1, 0, False));
  Assert.Contains(TGreedGameTables.MissionInfo(1, 2, False), '55,000');
  Assert.AreNotEqual(TGreedGameTables.MissionInfo(1, 0, False), TGreedGameTables.MissionInfo(1, 0, True));
end;

procedure TTestGreedGameTables.DovrebbeDareUnTestoVuotoFuoriDaiLimiti(AMap, AStringNumber: Integer);
begin
  Assert.AreEqual('', TGreedGameTables.MissionInfo(AMap, AStringNumber, False));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedGameTables);

end.
