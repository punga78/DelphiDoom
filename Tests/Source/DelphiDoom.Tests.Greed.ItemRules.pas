{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of what the player of Greed picks up and of the warps      }
{                                                                              }
{  TGreedItemRules on a level in memory with the stand-ins of the rest of the   }
{  game (TLibraryLevelRunner). The parity with the original raven.pas is the    }
{  golden test of DelphiDoom.Tests.Greed.LevelRules                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.ItemRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.ItemRules, DelphiDoom.Tests.Greed.LevelRunner;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedItemRules = class(TObject)
  private
    FRunner: TLibraryLevelRunner;
    function Center(ATile: Integer): Integer;
    function Spot(ATileX, ATileY: Integer): Integer;
    function FirstKind: Integer;
    procedure PutValue(AMapValue, ATileX, ATileY: Integer);
    procedure Take(ATileX, ATileY: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSeUnaDipendenzaManca;
    [Test]
    procedure DovrebbeConservareIlMedTubeSeLaSaluteEPiena;
    [Test]
    procedure DovrebbeUsareIlMedTubeSeFerito;
    [Test]
    procedure DovrebbeFermareIMedTubeAVenti;
    [Test]
    procedure DovrebbeConservareOUsareLaCaricaDelloScudo;
    [Test]
    procedure DovrebbeDareMunizioniFinoAlMassimo;
    [Test]
    procedure DovrebbeLasciareLaCassaDiMunizioniSeSonoPiene;
    [Test]
    procedure DovrebbeDareQuarantacinqueDiOgniTipoConLArmaSenzaMunizioni;
    [Test]
    procedure DovrebbeDareCentoventicinqueDelTipoDellArma;
    [Test]
    procedure DovrebbeEseguireLEventoDellaCassa;
    [Test]
    procedure DovrebbeLasciareLaCassaMedicaSeSano;
    [Test]
    procedure DovrebbeDareDueOggettiDallaCassaDegliOggetti;
    [Test]
    procedure DovrebbeRaccogliereLeGranateFinoAQuindici;
    [Test]
    procedure DovrebbeContareLObiettivoPrimario;
    [Test]
    procedure DovrebbeContareLObiettivoSecondario;
    [Test]
    procedure DovrebbeRaccogliereIlBonus;
    [Test]
    procedure DovrebbeAvviareGliAscensoriDellInterruttore;
    [Test]
    procedure DovrebbeLasciareLInterruttoreSenzaAscensori;
    [Test]
    procedure DovrebbeSegnareLUscita;
    [Test]
    procedure DovrebbeDarePiuMunizioniPerLaStessaArma;
    [Test]
    procedure DovrebbePrendereUnArmaNuova;
    [Test]
    procedure DovrebbeScambiareLArmaELasciareLaVecchiaVicino;
    [Test]
    procedure DovrebbeCaricareSubitoLArmaScambiataCheEInMano;
    [Test]
    procedure DovrebbeIgnorareLArmaSenzaPosto;
    [Test]
    procedure DovrebbeTogliereSoltantoLOggettoSeNonLoUsa;
    [Test]
    procedure DovrebbeNonRaccogliereSenzaLoSprite;
    [Test]
    procedure DovrebbeIniziareIlWarpVersoLAltraCasella;
    [Test]
    procedure DovrebbeNonRipartireFinoAQuandoLasciaIlWarp;
    [Test]
    procedure DovrebbeRestareFermoSeIlWarpEGiaInCorso;
    [Test]
    procedure DovrebbeRaccogliereCamminandoSullOggetto;
    [Test]
    procedure DovrebbeEseguireLEventoDelTrigger;
    [Test]
    procedure DovrebbeNonFareNullaFuoriDallaMappa;
  end;

implementation

{ TTestGreedItemRules }

procedure TTestGreedItemRules.Setup;
begin
  FRunner := TLibraryLevelRunner.Create;
  FRunner.LoadEmpty;
end;

procedure TTestGreedItemRules.TearDown;
begin
  FRunner.Free;
end;

function TTestGreedItemRules.Center(ATile: Integer): Integer;
begin
  Result := ATile * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
end;

function TTestGreedItemRules.Spot(ATileX, ATileY: Integer): Integer;
begin
  Result := ATileY * GREED_MAP_SIZE + ATileX;
end;

function TTestGreedItemRules.FirstKind: Integer;
begin
  if FRunner.Sprites.First = GREED_POOL_NIL then
    Result := -1
  else
    Result := FRunner.Sprites.Item(FRunner.Sprites.First)^.Kind;
end;

procedure TTestGreedItemRules.PutValue(AMapValue, ATileX, ATileY: Integer);
begin
  FRunner.World.SetValue(gpMapSprites, Spot(ATileX, ATileY), Byte(AMapValue));
end;

procedure TTestGreedItemRules.Take(ATileX, ATileY: Integer);
begin
  FRunner.Game.Calls.Clear;
  FRunner.Game.Messages.Clear;
  FRunner.Items.CheckItems(ATileX, ATileY, True, 0);
end;

procedure TTestGreedItemRules.DovrebbeSollevareSeUnaDipendenzaManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(nil, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game,
        FRunner.Random, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, nil, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game,
        FRunner.Random, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, FRunner.Game, nil, FRunner.Game, FRunner.Game, FRunner.Game,
        FRunner.Random, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, FRunner.Game, FRunner.Game, nil, FRunner.Game, FRunner.Game,
        FRunner.Random, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, nil, FRunner.Game,
        FRunner.Random, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game, nil,
        FRunner.Random, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game,
        nil, FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game,
        FRunner.Random, nil, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedItemRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Game,
        FRunner.Random, FRunner.Game, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedItemRules.DovrebbeConservareIlMedTubeSeLaSaluteEPiena;
begin
  FRunner.PutItem(GREED_SM_MEDPAK1, GREED_S_MEDPAK1, 12, 10);
  Take(12, 10);
  Assert.AreEqual(5, FRunner.State.Player.Inventory[0]);
  Assert.AreEqual('Stored MedTube!', FRunner.Game.Messages[0]);
  Assert.AreEqual(0, FRunner.MapSprite(12, 10), 'the tile is free');
  Assert.AreEqual(1, FRunner.Sprites.Count, 'the item is gone and its generator is there');
  Assert.AreEqual(GREED_S_GENERATOR, FirstKind);
  Assert.AreEqual(-2, FRunner.Game.OldInventory, 'the inventory is drawn again');
  Assert.IsTrue(FRunner.Game.Has(Format('SoundEffect %d 0 %d %d',
    [GREED_SN_PICKUP0, 12 * GREED_FRACTILEUNIT, 10 * GREED_FRACTILEUNIT])));
  Assert.IsTrue(FRunner.Game.Has(Format('SpawnSprite %d %d %d 0 0 0 0 0 0',
    [GREED_S_GENERATOR, Center(12), Center(10)])));
end;

procedure TTestGreedItemRules.DovrebbeUsareIlMedTubeSeFerito;
begin
  FRunner.State.Player.Angst := 100;
  FRunner.PutItem(GREED_SM_MEDPAK4, GREED_S_MEDPAK4, 12, 10);
  Take(12, 10);
  Assert.AreEqual(0, FRunner.State.Player.Inventory[0]);
  Assert.IsTrue(FRunner.Game.Has('medpaks 100'), 'the smallest tube heals 100');
  Assert.AreEqual(200, FRunner.State.Player.Angst);
  Assert.AreEqual('Used MedTube!', FRunner.Game.Messages[0]);
end;

procedure TTestGreedItemRules.DovrebbeFermareIMedTubeAVenti;
begin
  FRunner.State.Player.Inventory[0] := 18;
  FRunner.PutItem(GREED_SM_MEDPAK1, GREED_S_MEDPAK1, 12, 10);
  Take(12, 10);
  Assert.AreEqual(20, FRunner.State.Player.Inventory[0]);
end;

procedure TTestGreedItemRules.DovrebbeConservareOUsareLaCaricaDelloScudo;
begin
  FRunner.PutItem(GREED_SM_SHIELD3, GREED_S_SHIELD3, 12, 10);
  Take(12, 10);
  Assert.AreEqual(3, FRunner.State.Player.Inventory[1], 'the third charge is worth three');
  Assert.AreEqual('Stored Shield Charge!', FRunner.Game.Messages[0]);

  FRunner.State.Player.Shield := 10;
  FRunner.PutItem(GREED_SM_SHIELD1, GREED_S_SHIELD1, 14, 10);
  Take(14, 10);
  Assert.IsTrue(FRunner.Game.Has('heal 50'));
  Assert.AreEqual(60, FRunner.State.Player.Shield);
  Assert.AreEqual('Used Shield Charge!', FRunner.Game.Messages[0]);
end;

procedure TTestGreedItemRules.DovrebbeDareMunizioniFinoAlMassimo;
begin
  FRunner.State.Player.Ammo[1] := 280;
  FRunner.PutItem(GREED_SM_BALLISTIC, GREED_S_BALLISTIC, 12, 10);
  Take(12, 10);
  Assert.AreEqual(GREED_MAX_AMMO, FRunner.State.Player.Ammo[1]);
  Assert.AreEqual(0, FRunner.State.Player.Ammo[0]);
  Assert.AreEqual(-1, FRunner.Game.OldShots, 'the ammunition is drawn again');
  Assert.IsTrue(FRunner.State.HurtBorder);
  Assert.AreEqual('Bullets picked up!', FRunner.Game.Messages[0]);
  Assert.AreEqual(GREED_S_GENERATOR, FirstKind);
end;

procedure TTestGreedItemRules.DovrebbeLasciareLaCassaDiMunizioniSeSonoPiene;
begin
  // the weapon 1 in the hand uses the ammunition 1
  FRunner.State.Player.CurrentWeapon := 1;
  FRunner.State.Player.Ammo[1] := GREED_MAX_AMMO;
  FRunner.PutItem(GREED_SM_AMMOBOX, GREED_S_AMMOBOX, 12, 10);
  Take(12, 10);
  Assert.AreEqual(GREED_SM_AMMOBOX, FRunner.MapSprite(12, 10));
  Assert.AreEqual(1, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
end;

procedure TTestGreedItemRules.DovrebbeDareQuarantacinqueDiOgniTipoConLArmaSenzaMunizioni;
begin
  // the slot 0 in the hand: the weapon 0 of the table does not use ammunition
  FRunner.State.Player.Ammo[2] := 290;
  FRunner.PutItem(GREED_SM_AMMOBOX, GREED_S_AMMOBOX, 12, 10);
  Take(12, 10);
  Assert.AreEqual(45, FRunner.State.Player.Ammo[0]);
  Assert.AreEqual(45, FRunner.State.Player.Ammo[1]);
  Assert.AreEqual(GREED_MAX_AMMO, FRunner.State.Player.Ammo[2]);
  Assert.AreEqual('Ammo Box picked up!', FRunner.Game.Messages[0]);
  Assert.AreEqual(0, FRunner.Sprites.Count, 'a box leaves no generator');
  Assert.AreEqual(0, FRunner.MapSprite(12, 10));
end;

procedure TTestGreedItemRules.DovrebbeDareCentoventicinqueDelTipoDellArma;
begin
  FRunner.State.Player.CurrentWeapon := 1;
  FRunner.PutItem(GREED_SM_AMMOBOX, GREED_S_AMMOBOX, 12, 10);
  Take(12, 10);
  Assert.AreEqual(0, FRunner.State.Player.Ammo[0]);
  Assert.AreEqual(125, FRunner.State.Player.Ammo[1]);
  Assert.AreEqual(0, FRunner.State.Player.Ammo[2]);
end;

procedure TTestGreedItemRules.DovrebbeEseguireLEventoDellaCassa;
var
  LSprite: Integer;
begin
  FRunner.State.Player.Angst := 10;
  LSprite := FRunner.PutItem(GREED_SM_MEDBOX, GREED_S_MEDBOX, 12, 10);
  FRunner.Sprites.Item(LSprite)^.DeathEvent := 7;
  Take(12, 10);
  Assert.IsTrue(FRunner.Game.Has('RunEvent 7 0'));
  Assert.IsTrue(FRunner.Game.Has('heal 250'));
  Assert.IsTrue(FRunner.Game.Has('medpaks 250'));
  Assert.AreEqual(260, FRunner.State.Player.Angst);
  Assert.AreEqual('Auto-Doc picked up!', FRunner.Game.Messages[0]);
  Assert.AreEqual(0, FRunner.Sprites.Count);
end;

procedure TTestGreedItemRules.DovrebbeLasciareLaCassaMedicaSeSano;
begin
  FRunner.PutItem(GREED_SM_MEDBOX, GREED_S_MEDBOX, 12, 10);
  Take(12, 10);
  Assert.AreEqual(GREED_SM_MEDBOX, FRunner.MapSprite(12, 10));
  Assert.AreEqual(1, FRunner.Sprites.Count);
end;

procedure TTestGreedItemRules.DovrebbeDareDueOggettiDallaCassaDegliOggetti;
var
  LIndex, LTotal: Integer;
begin
  FRunner.PutItem(GREED_SM_GOODIEBOX, GREED_S_GOODIEBOX, 12, 10);
  Take(12, 10);
  // as the original: only the items 6 and 10 of the table (the places 8 and 12 of the inventory), one each time
  LTotal := 0;
  for LIndex := 0 to High(FRunner.State.Player.Inventory) do
    LTotal := LTotal + FRunner.State.Player.Inventory[LIndex];
  Assert.AreEqual(2, LTotal);
  Assert.AreEqual(2, FRunner.State.Player.Inventory[8] + FRunner.State.Player.Inventory[12]);
  Assert.AreEqual('Utility Chest picked up!', FRunner.Game.Messages[0]);
  Assert.IsTrue(FRunner.Random.Offset >= 2, 'the random numbers that were used');
end;

procedure TTestGreedItemRules.DovrebbeRaccogliereLeGranateFinoAQuindici;
begin
  FRunner.State.Player.Inventory[2] := 12;
  FRunner.PutItem(GREED_SM_IGRENADE, GREED_S_IGRENADE, 12, 10);
  Take(12, 10);
  Assert.AreEqual(15, FRunner.State.Player.Inventory[2]);
  Assert.AreEqual('Grenades picked up!', FRunner.Game.Messages[0]);

  FRunner.State.Player.Inventory[12] := 10;
  FRunner.PutItem(GREED_SM_ISTEALER, GREED_S_ISTEALER, 14, 10);
  Take(14, 10);
  Assert.AreEqual(10, FRunner.State.Player.Inventory[12], 'the other items stop at ten');
  Assert.AreEqual('Soul Stealer picked up!', FRunner.Game.Messages[0]);
end;

procedure TTestGreedItemRules.DovrebbeContareLObiettivoPrimario;
begin
  FRunner.State.Primaries[3] := 700;
  FRunner.State.Player.LevelScore := 1000;
  FRunner.PutItem(GREED_SM_PRIMARY2, GREED_S_PRIMARY1 + 1, 12, 10);
  Take(12, 10);
  Assert.AreEqual(1, FRunner.State.Player.Primaries[1]);
  Assert.AreEqual(0, FRunner.State.Player.Primaries[0]);
  Assert.IsTrue(FRunner.Game.Has('addscore 700'));
  Assert.AreEqual(300, FRunner.State.Player.LevelScore);
  Assert.AreEqual('Primary goal item!', FRunner.Game.Messages[0]);
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.IsTrue(FRunner.Game.Has(Format('SoundEffect %d 0 %d %d',
    [GREED_SN_WEAPPICKUP0, 12 * GREED_FRACTILEUNIT, 10 * GREED_FRACTILEUNIT])));
end;

procedure TTestGreedItemRules.DovrebbeContareLObiettivoSecondario;
begin
  FRunner.State.Secondaries[13] := 150;
  FRunner.PutItem(GREED_SM_SECONDARY7, GREED_S_SECONDARY1 + 6, 12, 10);
  Take(12, 10);
  Assert.AreEqual(1, FRunner.State.Player.Secondaries[6]);
  Assert.IsTrue(FRunner.Game.Has('addscore 150'));
  Assert.AreEqual('Secondary goal item!', FRunner.Game.Messages[0]);
end;

procedure TTestGreedItemRules.DovrebbeRaccogliereIlBonus;
begin
  FRunner.State.BonusItem.Score := 2500;
  FRunner.State.BonusItem.Name := 'thing';
  FRunner.State.BonusItem.MapSpot := Spot(12, 10);
  FRunner.State.BonusItem.Sprite := FRunner.PutItem(GREED_SM_BONUSITEM, GREED_S_BONUSITEM, 12, 10);
  Take(12, 10);
  Assert.IsTrue(FRunner.Game.Has('addscore 2500'));
  Assert.AreEqual(0, FRunner.State.BonusItem.Score);
  Assert.AreEqual(-1, FRunner.State.BonusItem.MapSpot);
  Assert.AreEqual('', FRunner.State.BonusItem.Name);
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.MapSprite(12, 10));
  Assert.AreEqual('Bonus Item!', FRunner.Game.Messages[0]);
end;

procedure TTestGreedItemRules.DovrebbeAvviareGliAscensoriDellInterruttore;
var
  LDown, LOther: Integer;
begin
  PutValue(GREED_SM_SWITCHDOWN, 12, 10);
  LDown := FRunner.AddElevator(getSwitchDown, 20, 21, 0, 64, 64);
  LOther := FRunner.AddElevator(getSwitchUp, 22, 21, 0, 64, 0);
  Take(12, 10);
  Assert.IsTrue(FRunner.State.Elevators.Item(LDown)^.Down);
  Assert.AreEqual(FRunner.State.TimeCount, FRunner.State.Elevators.Item(LDown)^.Timer);
  Assert.IsFalse(FRunner.State.Elevators.Item(LOther)^.Up, 'the elevators of another switch stay');
  Assert.AreEqual(0, FRunner.MapSprite(12, 10));
  Assert.IsTrue(FRunner.Game.Has(Format('SoundEffect %d 15 %d %d',
    [GREED_SN_ELEVATORSTART, 20 * GREED_FRACTILEUNIT, 21 * GREED_FRACTILEUNIT])));
  // as the original: the click is played twice for each elevator of the list from the one that started
  Assert.AreEqual(4, FRunner.Game.CountOf(Format('SoundEffect %d', [GREED_SN_TRIGGER])));

  PutValue(GREED_SM_SWITCHUP, 14, 10);
  Take(14, 10);
  Assert.IsTrue(FRunner.State.Elevators.Item(LOther)^.Up);
  Assert.AreEqual(1, FRunner.Game.CountOf(Format('SoundEffect %d', [GREED_SN_TRIGGER])));
end;

procedure TTestGreedItemRules.DovrebbeLasciareLInterruttoreSenzaAscensori;
begin
  // as the original: the tile is cleared inside the loop of the elevators
  PutValue(GREED_SM_SWITCHDOWN2, 12, 10);
  Take(12, 10);
  Assert.AreEqual(GREED_SM_SWITCHDOWN2, FRunner.MapSprite(12, 10));
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
end;

procedure TTestGreedItemRules.DovrebbeSegnareLUscita;
begin
  PutValue(GREED_SM_EXIT, 12, 10);
  Take(12, 10);
  Assert.IsTrue(FRunner.State.ExitLevel);
end;

procedure TTestGreedItemRules.DovrebbeDarePiuMunizioniPerLaStessaArma;
begin
  // the weapon 2 uses the ammunition 1 and goes in the slot 3
  FRunner.State.Player.Weapons[3] := 2;
  FRunner.State.Player.Ammo[1] := 250;
  FRunner.PutItem(GREED_SM_WEAPON0 + 2, GREED_S_WEAPON0 + 2, 12, 10);
  Take(12, 10);
  Assert.AreEqual(GREED_MAX_AMMO, FRunner.State.Player.Ammo[1]);
  Assert.AreEqual('Found more ammo.', FRunner.Game.Messages[0]);
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.MapSprite(12, 10));
  Assert.IsFalse(FRunner.State.ChangingWeapons);
end;

procedure TTestGreedItemRules.DovrebbePrendereUnArmaNuova;
begin
  FRunner.PutItem(GREED_SM_WEAPON0 + 2, GREED_S_WEAPON0 + 2, 12, 10);
  Take(12, 10);
  Assert.AreEqual(2, FRunner.State.Player.Weapons[3]);
  Assert.AreEqual('Acquired new weapon!', FRunner.Game.Messages[0]);
  Assert.IsTrue(FRunner.State.ChangingWeapons);
  Assert.IsTrue(FRunner.State.WeaponLowering);
  Assert.AreEqual(3, FRunner.State.NewWeapon);
  Assert.IsTrue(FRunner.State.HurtBorder);
  Assert.AreEqual(0, FRunner.Sprites.Count);
end;

procedure TTestGreedItemRules.DovrebbeScambiareLArmaELasciareLaVecchiaVicino;
begin
  // the weapon 9 uses the ammunition 1 too
  FRunner.State.Player.Weapons[3] := 9;
  FRunner.PutItem(GREED_SM_WEAPON0 + 2, GREED_S_WEAPON0 + 2, 12, 10);
  Take(12, 10);
  Assert.AreEqual(2, FRunner.State.Player.Weapons[3]);
  Assert.AreEqual('Exchanged weapons!', FRunner.Game.Messages[0]);
  // the first free tile around is the one up and to the left
  Assert.IsTrue(FRunner.Game.Has(Format('SpawnSprite %d %d %d 0 0 0 0 0 0',
    [GREED_S_WEAPON0 + 9, Center(11), Center(9)])));
  Assert.AreEqual(GREED_SM_WEAPON0 + 9, FRunner.MapSprite(11, 9));
  Assert.AreEqual(GREED_S_WEAPON0 + 9, FirstKind, 'the old weapon is the only sprite left');
  Assert.IsTrue(FRunner.State.WeaponLowering, 'the weapon in the hand is another one');
  Assert.AreEqual(0, FRunner.Game.CountOf('loadweapon'));
end;

procedure TTestGreedItemRules.DovrebbeCaricareSubitoLArmaScambiataCheEInMano;
begin
  FRunner.State.Player.Weapons[3] := 9;
  FRunner.State.Player.CurrentWeapon := 3;
  FRunner.PutItem(GREED_SM_WEAPON0 + 2, GREED_S_WEAPON0 + 2, 12, 10);
  Take(12, 10);
  Assert.IsTrue(FRunner.Game.Has('loadweapon 2'));
  Assert.IsFalse(FRunner.State.WeaponLowering);
  Assert.IsTrue(FRunner.State.ChangingWeapons);
  Assert.AreEqual(FRunner.Game.WeaponPictureHeight - 20, FRunner.State.WeaponYChange);
  Assert.AreEqual(3, FRunner.State.NewWeapon);
end;

procedure TTestGreedItemRules.DovrebbeIgnorareLArmaSenzaPosto;
begin
  // the weapon 6 has the ammunition kind 3: there is no slot for it
  FRunner.PutItem(GREED_SM_WEAPON0 + 6, GREED_S_WEAPON0 + 6, 12, 10);
  Take(12, 10);
  Assert.AreEqual(1, FRunner.Sprites.Count);
  Assert.AreEqual(GREED_SM_WEAPON0 + 6, FRunner.MapSprite(12, 10));
  Assert.AreEqual(0, FRunner.Game.Messages.Count);
end;

procedure TTestGreedItemRules.DovrebbeTogliereSoltantoLOggettoSeNonLoUsa;
begin
  FRunner.PutItem(GREED_SM_MEDPAK1, GREED_S_MEDPAK1, 12, 10);
  FRunner.Game.Calls.Clear;
  FRunner.Items.CheckItems(12, 10, False, 3);
  Assert.AreEqual(0, FRunner.State.Player.Inventory[0]);
  Assert.AreEqual(0, FRunner.Game.Messages.Count);
  Assert.AreEqual(0, FRunner.MapSprite(12, 10));
  Assert.AreEqual(GREED_S_GENERATOR, FirstKind);
  Assert.IsTrue(FRunner.Game.Has(Format('SoundEffect %d 0 %d %d',
    [GREED_SN_PICKUP0 + 3, 12 * GREED_FRACTILEUNIT, 10 * GREED_FRACTILEUNIT])), 'the sound of who took it');
end;

procedure TTestGreedItemRules.DovrebbeNonRaccogliereSenzaLoSprite;
begin
  PutValue(GREED_SM_ENERGY, 12, 10);
  // a sprite of another kind on the tile, the right one on another tile
  FRunner.AddSprite(GREED_S_PLASMA, 12, 10);
  FRunner.AddSprite(GREED_S_ENERGY, 13, 10);
  Take(12, 10);
  Assert.AreEqual(GREED_SM_ENERGY, FRunner.MapSprite(12, 10));
  Assert.AreEqual(2, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
end;

procedure TTestGreedItemRules.DovrebbeIniziareIlWarpVersoLAltraCasella;
begin
  PutValue(GREED_SM_WARP1, 12, 10);
  PutValue(GREED_SM_WARP1, 30, 40);
  PutValue(GREED_SM_WARP2, 20, 5);
  FRunner.PlacePlayer(12, 10);
  FRunner.State.MoveRate := 5;
  FRunner.State.TurnRate := 3;
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.AreEqual(1, FRunner.State.Warping);
  Assert.AreEqual(Center(30), FRunner.State.WarpX);
  Assert.AreEqual(Center(40), FRunner.State.WarpY);
  Assert.AreEqual(GREED_SM_WARP1, Integer(FRunner.Items.WarpActive));
  Assert.AreEqual(0, FRunner.State.MoveRate, 'the player stands still');
  Assert.AreEqual(0, FRunner.State.TurnRate);
  Assert.IsTrue(FRunner.Game.Has('ResetMouse'));
end;

procedure TTestGreedItemRules.DovrebbeNonRipartireFinoAQuandoLasciaIlWarp;
begin
  PutValue(GREED_SM_WARP1, 12, 10);
  PutValue(GREED_SM_WARP1, 30, 40);
  // it has just come out on the tile (30, 40)
  FRunner.Items.WarpActive := GREED_SM_WARP1;
  FRunner.PlacePlayer(30, 40);
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.AreEqual(0, FRunner.State.Warping);

  FRunner.PlacePlayer(31, 40);
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.AreEqual(0, Integer(FRunner.Items.WarpActive), 'off the warp it can be used again');

  FRunner.PlacePlayer(30, 40);
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.AreEqual(1, FRunner.State.Warping);
  Assert.AreEqual(Center(12), FRunner.State.WarpX);
end;

procedure TTestGreedItemRules.DovrebbeRestareFermoSeIlWarpEGiaInCorso;
begin
  PutValue(GREED_SM_WARP3, 12, 10);
  PutValue(GREED_SM_WARP3, 30, 40);
  FRunner.State.Triggers[12 * GREED_MAP_SIZE + 10] := 4;
  FRunner.State.Warping := 2;
  FRunner.PlacePlayer(12, 10);
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.AreEqual(2, FRunner.State.Warping);
  Assert.AreEqual(0, Integer(FRunner.Items.WarpActive));
  Assert.AreEqual(0, FRunner.Game.CountOf('RunEvent'), 'not even the trigger of the tile');
end;

procedure TTestGreedItemRules.DovrebbeRaccogliereCamminandoSullOggetto;
begin
  FRunner.State.Player.CharType := 2;
  FRunner.PutItem(GREED_SM_PLASMA, GREED_S_PLASMA, 12, 10);
  FRunner.PlacePlayer(12, 10);
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.AreEqual(75, FRunner.State.Player.Ammo[2]);
  Assert.IsTrue(FRunner.Game.Has(Format('SoundEffect %d 0 %d %d',
    [GREED_SN_PICKUP0 + 2, 12 * GREED_FRACTILEUNIT, 10 * GREED_FRACTILEUNIT])), 'the sound of the character');
end;

procedure TTestGreedItemRules.DovrebbeEseguireLEventoDelTrigger;
begin
  // triggers[x][y]
  FRunner.State.Triggers[12 * GREED_MAP_SIZE + 10] := 9;
  FRunner.PlacePlayer(12, 10);
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.IsTrue(FRunner.Game.Has('RunEvent 9 1'));
  Assert.AreEqual(2, FRunner.Game.CountOf(Format('SoundEffect %d', [GREED_SN_TRIGGER])));
  Assert.AreEqual(0, Integer(FRunner.State.Triggers[12 * GREED_MAP_SIZE + 10]), 'the stand-in takes an odd one away');

  FRunner.Game.Calls.Clear;
  FRunner.PlacePlayer(10, 12);
  FRunner.Items.CheckWarps(FRunner.State.Player.X, FRunner.State.Player.Y);
  Assert.AreEqual(0, FRunner.Game.CountOf('RunEvent'), 'the tile (10, 12) has no trigger');
end;

procedure TTestGreedItemRules.DovrebbeNonFareNullaFuoriDallaMappa;
begin
  FRunner.Game.Calls.Clear;
  FRunner.Items.CheckItems(-5, 70, True, 0);
  FRunner.Items.CheckItems(200, 200, True, 0);
  FRunner.Items.CheckWarps(-3 * GREED_FRACTILEUNIT, 70 * GREED_FRACTILEUNIT);
  Assert.AreEqual(0, FRunner.Game.Calls.Count);
  Assert.AreEqual(0, FRunner.Sprites.Count);
end;


end.
