{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of what a level of Greed does around the player            }
{                                                                              }
{  TGreedLevelRules on a level in memory with the stand-ins of the rest of the  }
{  game (TLibraryLevelRunner), and the parity of TGreedItemRules,               }
{  TGreedSwitchRules and TGreedLevelRules with the routines of the original     }
{  raven.pas: the scenarios of DelphiDoom.Tests.Greed.LevelScenarios give the   }
{  hashes that the original code gave (harness Tools\Verifica\175-level),       }
{  Tests\Data\Greed\level.golden.txt                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.LevelRules;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.LevelRules,
  DelphiDoom.Tests.Greed.LevelScenarios, DelphiDoom.Tests.Greed.LevelRunner;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedLevelRules = class(TObject)
  private
    FRunner: TLibraryLevelRunner;
    function Center(ATile: Integer): Integer;
    function Spot(ATileX, ATileY: Integer): Integer;
    function AddArea(AKind, ATileX, ATileY, ATime: Integer): Integer;
    function CountKind(AKind: Integer): Integer;
    procedure NoGoals;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSollevareSeUnaDipendenzaManca;
    [Test]
    procedure DovrebbeCaricareLeArmiDelGiocatore;
    [Test]
    procedure DovrebbeChiamareLePartiDelTicNellOrdineDellOriginale;
    [Test]
    procedure DovrebbeFarPensareGliSpriteOgniOttoTic;
    [Test]
    procedure DovrebbeEseguireIProcessiSoloSeCiSono;
    [Test]
    procedure DovrebbeSuonareLaPortaUrtata;
    [Test]
    procedure DovrebbeRiempireLAreaPronta;
    [Test]
    procedure DovrebbeRimandareLAreaCheAspetta;
    [Test]
    procedure DovrebbeFermareLeAreeConIlWarpJammer;
    [Test]
    procedure DovrebbeNonSuperareIlMassimoDiMostri;
    [Test]
    procedure DovrebbeTogliereUnCadavereEIlGeneratore;
    [Test]
    procedure DovrebbeSaltareLAreaOccupata;
    [Test]
    procedure DovrebbeIgnorareUnAreaDiTipoSconosciuto;
    [Test]
    procedure DovrebbeDareMunizioniOSaluteDalleAreeDegliOggetti;
    [Test]
    procedure DovrebbeMettereIlBonusSuUnaCasellaLibera;
    [Test]
    procedure DovrebbeSpostareIlBonusScaduto;
    [Test]
    procedure DovrebbeAspettareIlTempoDelBonus;
    [Test]
    procedure DovrebbePassareAlProssimoObiettivo;
    [Test]
    procedure DovrebbeDareMenoUnoSenzaObiettivi;
    [Test]
    procedure DovrebbeRicominciareDaCapo;
    [Test]
    procedure DovrebbeTenereIlGiocatoreAlLivelloSuccessivo;
    [Test]
    procedure DovrebbeFareLeFasiDelWarp;
    [Test]
    procedure DovrebbeCreareLUscitaVicinoAlGiocatore;
    [Test]
    procedure DovrebbeUsareIlWarpJammer;
    [Test]
    procedure DovrebbeCostruireScenariRipetibili;
    [Test]
    procedure DovrebbeDareLeStesseImpronteDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.RealData;

{ TTestGreedLevelRules }

procedure TTestGreedLevelRules.Setup;
begin
  FRunner := TLibraryLevelRunner.Create;
  FRunner.LoadEmpty;
end;

procedure TTestGreedLevelRules.TearDown;
begin
  FRunner.Free;
end;

function TTestGreedLevelRules.Center(ATile: Integer): Integer;
begin
  Result := ATile * GREED_FRACTILEUNIT + 32 * GREED_FRACUNIT;
end;

function TTestGreedLevelRules.Spot(ATileX, ATileY: Integer): Integer;
begin
  Result := ATileY * GREED_MAP_SIZE + ATileX;
end;

function TTestGreedLevelRules.AddArea(AKind, ATileX, ATileY, ATime: Integer): Integer;
var
  LArea: TGreedSpawnArea;
begin
  Result := FRunner.World.AddSpawnArea;
  LArea.MapSpot := Spot(ATileX, ATileY);
  LArea.MapX := Center(ATileX);
  LArea.MapY := Center(ATileY);
  LArea.Kind := AKind;
  LArea.Time := ATime;
  FRunner.World.SetSpawnArea(Result, LArea);
end;

function TTestGreedLevelRules.CountKind(AKind: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  LIndex := FRunner.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    if FRunner.Sprites.Item(LIndex)^.Kind = AKind then
      Inc(Result);
    LIndex := FRunner.Sprites.Next(LIndex);
  end;
end;

procedure TTestGreedLevelRules.NoGoals;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 1 do
    FRunner.State.Primaries[LIndex * 2] := -1;
  for LIndex := 0 to 6 do
    FRunner.State.Secondaries[LIndex * 2] := -1;
end;

procedure TTestGreedLevelRules.DovrebbeSollevareSeUnaDipendenzaManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(nil, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Random, FRunner.Game,
        FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(FRunner.State, nil, FRunner.Game, FRunner.Game, FRunner.Random, FRunner.Game,
        FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(FRunner.State, FRunner.Game, nil, FRunner.Game, FRunner.Random, FRunner.Game,
        FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(FRunner.State, FRunner.Game, FRunner.Game, nil, FRunner.Random, FRunner.Game,
        FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, nil, FRunner.Game,
        FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Random, nil,
        FRunner.Game, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Random,
        FRunner.Game, nil, FRunner.Game).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedLevelRules.Create(FRunner.State, FRunner.Game, FRunner.Game, FRunner.Game, FRunner.Random,
        FRunner.Game, FRunner.Game, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedLevelRules.DovrebbeCaricareLeArmiDelGiocatore;
begin
  // the weapon 0 charges 20 every 6 tics
  FRunner.State.Player.Weapons[1] := -1;
  FRunner.Level.ChargeWeapons;
  Assert.AreEqual(20, FRunner.State.Weapons[0].Charge);
  Assert.AreEqual(FRunner.State.TimeCount + 6, FRunner.State.Weapons[0].ChargeTime);
  Assert.AreEqual(0, FRunner.State.Weapons[1].Charge, 'a weapon that the player does not have');

  FRunner.State.TimeCount := FRunner.State.TimeCount + 13;
  FRunner.Level.ChargeWeapons;
  Assert.AreEqual(60, FRunner.State.Weapons[0].Charge, 'two more steps in 13 tics');

  FRunner.State.TimeCount := FRunner.State.TimeCount + 1000;
  FRunner.Level.ChargeWeapons;
  Assert.AreEqual(100, FRunner.State.Weapons[0].Charge, 'never over 100');
end;

procedure TTestGreedLevelRules.DovrebbeChiamareLePartiDelTicNellOrdineDellOriginale;
begin
  FRunner.State.NumProcesses := 1;
  FRunner.Game.Calls.Clear;
  FRunner.Level.TimeUpdate;
  Assert.AreEqual(
    'UpdateMouse,UpdateSound,Process,ClearTileLights,MoveSprites,UpdateMouse,CheckElevators,UpdateMouse',
    FRunner.Game.Calls.CommaText);
  Assert.AreEqual(20, FRunner.State.Weapons[0].Charge, 'the weapons charge first');
end;

procedure TTestGreedLevelRules.DovrebbeFarPensareGliSpriteOgniOttoTic;
begin
  // the sprites have thought at this tic
  FRunner.Level.TimeUpdate;
  Assert.AreEqual(FRunner.State.TimeCount + 8, FRunner.State.SpriteMoveTime);
  FRunner.Game.Calls.Clear;
  FRunner.State.TimeCount := FRunner.State.TimeCount + 7;
  FRunner.Level.TimeUpdate;
  Assert.AreEqual(0, FRunner.Game.CountOf('MoveSprites'));
  FRunner.State.TimeCount := FRunner.State.TimeCount + 1;
  FRunner.Level.TimeUpdate;
  Assert.AreEqual(1, FRunner.Game.CountOf('MoveSprites'));
  // a long frame: one turn for every 8 tics that went by
  FRunner.Game.Calls.Clear;
  FRunner.State.TimeCount := FRunner.State.TimeCount + 24;
  FRunner.Level.TimeUpdate;
  Assert.AreEqual(3, FRunner.Game.CountOf('MoveSprites'));
  Assert.AreEqual(3, FRunner.Game.CountOf('ClearTileLights'));
end;

procedure TTestGreedLevelRules.DovrebbeEseguireIProcessiSoloSeCiSono;
begin
  FRunner.Game.Calls.Clear;
  FRunner.Level.TimeUpdate;
  Assert.AreEqual(0, FRunner.Game.CountOf('Process'));
  Assert.AreEqual(1, FRunner.Game.CountOf('MoveSprites'));
end;

procedure TTestGreedLevelRules.DovrebbeSuonareLaPortaUrtata;
begin
  FRunner.State.DoorSound := True;
  FRunner.State.DoorX := 5;
  FRunner.State.DoorY := 6;
  FRunner.Game.Calls.Clear;
  FRunner.Level.TimeUpdate;
  Assert.IsTrue(FRunner.Game.Has(Format('SoundEffect %d 15 5 6', [GREED_SN_DOOR])));
  Assert.IsFalse(FRunner.State.DoorSound);
  FRunner.Game.Calls.Clear;
  FRunner.Level.TimeUpdate;
  Assert.AreEqual(0, FRunner.Game.CountOf('SoundEffect'), 'only once');
end;

procedure TTestGreedLevelRules.DovrebbeRiempireLAreaPronta;
var
  LArea: Integer;
begin
  LArea := AddArea(10, 20, 20, 0);
  FRunner.State.Player.Difficulty := 1;
  FRunner.Game.ClockValue := 256 + 7;
  FRunner.Game.Calls.Clear;
  // TimeUpdate looks at the areas when there are any
  FRunner.Level.TimeUpdate;
  Assert.IsTrue(FRunner.Game.Has(Format('SpawnSprite %d %d %d 0 0 0 0 1 0',
    [GREED_S_MONSTER1, Center(20), Center(20)])));
  Assert.IsTrue(FRunner.Game.Has(Format('SpawnSprite %d %d %d 0 0 0 0 1 0', [GREED_S_WARP, Center(20), Center(20)])));
  Assert.AreEqual(FRunner.State.TimeCount + 7 + 2100 * 2, FRunner.World.GetSpawnArea(LArea).Time,
    'the next one: the low byte of the clock and the difficulty');
end;

procedure TTestGreedLevelRules.DovrebbeRimandareLAreaCheAspetta;
var
  LArea: Integer;
begin
  // as the original: the area that is not ready is moved 7000 tics ahead at every call
  LArea := AddArea(10, 20, 20, FRunner.State.TimeCount + 1);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(FRunner.State.TimeCount + 7000, FRunner.World.GetSpawnArea(LArea).Time);
end;

procedure TTestGreedLevelRules.DovrebbeFermareLeAreeConIlWarpJammer;
var
  LArea: Integer;
begin
  LArea := AddArea(10, 20, 20, 0);
  FRunner.State.SpecialEffect := GREED_SE_WARPJAMMER;
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.World.GetSpawnArea(LArea).Time);
end;

procedure TTestGreedLevelRules.DovrebbeNonSuperareIlMassimoDiMostri;
var
  LIndex, LSprite, LArea: Integer;
begin
  LArea := AddArea(11, 20, 20, 0);
  for LIndex := 1 to GREED_MAXSPAWN do
  begin
    LSprite := FRunner.AddSprite(GREED_S_MONSTER2, 30, 30);
    FRunner.Sprites.Item(LSprite)^.HitPoints := 10;
  end;
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(GREED_MAXSPAWN, FRunner.Sprites.Count);
  Assert.AreEqual(FRunner.State.TimeCount + 4200, FRunner.World.GetSpawnArea(LArea).Time, 'the time goes on anyway');

  // one dies: there is room for another
  FRunner.Sprites.Item(FRunner.Sprites.First)^.HitPoints := 0;
  AddArea(11, 22, 20, 0);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(GREED_MAXSPAWN, CountKind(GREED_S_MONSTER2), 'the corpse is gone and a monster is born');
  Assert.AreEqual(1, CountKind(GREED_S_WARP));
end;

procedure TTestGreedLevelRules.DovrebbeTogliereUnCadavereEIlGeneratore;
var
  LSprite: Integer;
begin
  AddArea(12, 20, 20, 0);
  FRunner.AddSprite(GREED_S_GENERATOR, 20, 20);
  FRunner.AddSprite(GREED_S_GENSTART + 3, 20, 20);
  FRunner.AddSprite(GREED_S_GENERATOR, 21, 20);
  FRunner.AddSprite(GREED_S_MONSTER3, 40, 40);
  FRunner.AddSprite(GREED_S_MONSTER3, 41, 40);
  LSprite := FRunner.AddSprite(GREED_S_MONSTER4, 42, 40);
  Assert.AreEqual(0, FRunner.Sprites.Item(LSprite)^.HitPoints);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(1, CountKind(GREED_S_GENERATOR), 'the generator of another place stays');
  Assert.AreEqual(0, CountKind(GREED_S_GENSTART + 3));
  // one of the two corpses is gone, the new monster is there (the stand-in gives it hit points)
  Assert.AreEqual(2, CountKind(GREED_S_MONSTER3));
  Assert.AreEqual(1, CountKind(GREED_S_MONSTER4), 'the corpse of another kind stays');
end;

procedure TTestGreedLevelRules.DovrebbeSaltareLAreaOccupata;
var
  LBusy, LPlayer: Integer;
begin
  LBusy := AddArea(10, 20, 20, 0);
  FRunner.World.SetValue(gpMapSprites, Spot(20, 20), 1);
  LPlayer := AddArea(10, 10, 10, 0);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.World.GetSpawnArea(LBusy).Time, 'it tries again at the next call');
  Assert.AreEqual(0, FRunner.World.GetSpawnArea(LPlayer).Time, 'the player stands on it');
end;

procedure TTestGreedLevelRules.DovrebbeIgnorareUnAreaDiTipoSconosciuto;
var
  LArea: Integer;
begin
  LArea := AddArea(5, 20, 20, 0);
  AddArea(102, 22, 20, 0);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.World.GetSpawnArea(LArea).Time);
end;

procedure TTestGreedLevelRules.DovrebbeDareMunizioniOSaluteDalleAreeDegliOggetti;
var
  LAmmo, LHealth: Integer;
begin
  // the clock and the first random number are zero: the first thing of each list
  LAmmo := AddArea(0, 20, 20, 0);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(1, CountKind(GREED_S_ENERGY));
  Assert.AreEqual(GREED_SM_ENERGY, FRunner.MapSprite(20, 20), 'the stand-in marks the tile as SpawnSprite does');
  Assert.AreEqual(FRunner.State.TimeCount + 3500 - 350, FRunner.World.GetSpawnArea(LAmmo).Time);

  FRunner.Random.Offset := 0;
  LHealth := AddArea(1, 22, 20, 0);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(1, CountKind(GREED_S_MEDPAK1));
  Assert.AreEqual(1, CountKind(GREED_S_ENERGY), 'the first area waits now');
  Assert.AreEqual(FRunner.State.TimeCount + 3500 - 350, FRunner.World.GetSpawnArea(LHealth).Time);
  Assert.AreEqual(1, FRunner.Random.Offset, 'one random number for each thing');

  // the last numbers of the list: the game gives the soul stealer, the demo the clone
  FRunner.Game.ClockValue := 113;
  FRunner.Random.Offset := 0;
  AddArea(0, 24, 20, 0);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(1, CountKind(GREED_S_ISTEALER));
  FRunner.State.Demo := True;
  FRunner.Game.ClockValue := 109;
  FRunner.Random.Offset := 0;
  AddArea(1, 26, 20, 0);
  FRunner.Level.CheckSpawnAreas;
  Assert.AreEqual(1, CountKind(GREED_S_ICLONE));
end;

procedure TTestGreedLevelRules.DovrebbeMettereIlBonusSuUnaCasellaLibera;
var
  LSprite: PGreedSprite;
begin
  FRunner.State.BonusItem.Time := 0;
  FRunner.State.BonusTime := 300;
  FRunner.State.GoalItem := 4;
  // the first two random numbers are 0 and 8: with the clock at 5 the tile is (5, 13)
  FRunner.Game.ClockValue := 5;
  FRunner.Game.Calls.Clear;
  FRunner.Level.CheckBonusItem;
  Assert.AreEqual(5, FRunner.State.BonusItem.TileX);
  Assert.AreEqual(13, FRunner.State.BonusItem.TileY);
  Assert.AreEqual(Spot(5, 13), FRunner.State.BonusItem.MapSpot);
  Assert.AreEqual(2000 + 5 * 300, FRunner.State.BonusItem.Score);
  Assert.AreEqual(FRunner.State.TimeCount + 300 + 5, FRunner.State.BonusItem.Time);
  Assert.AreEqual(5, FRunner.State.BonusItem.Num);
  Assert.AreEqual(TGreedGameTables.RandomItemNames[5], FRunner.State.BonusItem.Name);
  Assert.AreEqual(FRunner.Game.LastSpawn, FRunner.Sprites.Next(FRunner.State.BonusItem.Sprite),
    'the warp is born after the bonus item');
  LSprite := PGreedSprite(FRunner.Sprites.Item(FRunner.State.BonusItem.Sprite));
  Assert.AreEqual(GREED_S_BONUSITEM, LSprite^.Kind);
  Assert.AreEqual(Center(5), LSprite^.X);
  Assert.AreEqual(Center(13), LSprite^.Y);
  Assert.AreEqual(GREED_S_BONUSITEM * 3 + 5, LSprite^.BasePic, 'the picture of the item number 5');
  Assert.AreEqual(1, CountKind(GREED_S_WARP));
  Assert.AreEqual(-1, FRunner.Game.OldGoalItem, 'the status bar draws the goal again');
  Assert.AreEqual(0, FRunner.State.GoalItem);
  Assert.AreEqual(GREED_SM_BONUSITEM, FRunner.MapSprite(5, 13));
end;

procedure TTestGreedLevelRules.DovrebbeSpostareIlBonusScaduto;
var
  LSpot: Integer;
begin
  FRunner.State.BonusItem.Time := 0;
  FRunner.Game.ClockValue := 5;
  FRunner.Level.CheckBonusItem;
  // tiles where the bonus item cannot go: no floor, something on it, a floor effect, no room
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    case LSpot mod 4 of
      0:
        FRunner.World.SetValue(gpFloorPic, LSpot, 0);
      1:
        if LSpot <> Spot(5, 13) then
          FRunner.World.SetValue(gpMapSprites, LSpot, 1);
      2:
        FRunner.World.SetValue(gpMapEffects, LSpot, 3);
    end;
  FRunner.World.SetValue(gpCeilingHeight, Spot(7, 1), 0);
  // and not where it is now, which will be free again
  FRunner.World.SetValue(gpMapEffects, Spot(5, 13), 3);
  FRunner.State.BonusItem.Time := 0;
  FRunner.Game.Calls.Clear;
  FRunner.Level.CheckBonusItem;
  Assert.AreEqual(1, CountKind(GREED_S_BONUSITEM), 'the old one is gone');
  Assert.AreEqual(0, FRunner.MapSprite(5, 13));
  Assert.AreEqual(3, FRunner.State.BonusItem.MapSpot mod 4, 'only the tiles that are left');
  Assert.AreNotEqual(Spot(7, 1), FRunner.State.BonusItem.MapSpot);
  Assert.IsTrue(FRunner.Game.Has(Format('SpawnSprite %d %d %d 0 0 0 0 0 0', [GREED_S_WARP, Center(5), Center(13)])),
    'a warp where it was');
  Assert.AreEqual(3, CountKind(GREED_S_WARP));
end;

procedure TTestGreedLevelRules.DovrebbeAspettareIlTempoDelBonus;
begin
  FRunner.State.BonusItem.Time := FRunner.State.TimeCount;
  FRunner.Level.CheckBonusItem;
  Assert.AreEqual(0, FRunner.Sprites.Count);
  Assert.AreEqual(0, FRunner.State.BonusItem.Score);
end;

procedure TTestGreedLevelRules.DovrebbePassareAlProssimoObiettivo;
begin
  NoGoals;
  // the level has the second primary goal and the fourth secondary one; there is no bonus item
  FRunner.State.Primaries[2] := 1;
  FRunner.State.Secondaries[6] := 3;
  FRunner.State.ToggleGoalItem := True;
  FRunner.State.GoalItem := 0;
  FRunner.Level.NewGoalItem;
  Assert.AreEqual(2, FRunner.State.GoalItem);
  Assert.IsFalse(FRunner.State.ToggleGoalItem);
  FRunner.Level.NewGoalItem;
  Assert.AreEqual(6, FRunner.State.GoalItem);
  FRunner.Level.NewGoalItem;
  Assert.AreEqual(2, FRunner.State.GoalItem, 'after the last it starts again, without the bonus item');
  FRunner.State.BonusItem.Score := 100;
  FRunner.State.GoalItem := 6;
  FRunner.Level.NewGoalItem;
  Assert.AreEqual(0, FRunner.State.GoalItem, 'the bonus item is the goal 0');
end;

procedure TTestGreedLevelRules.DovrebbeDareMenoUnoSenzaObiettivi;
begin
  NoGoals;
  FRunner.State.GoalItem := 0;
  FRunner.Level.NewGoalItem;
  Assert.AreEqual(-1, FRunner.State.GoalItem);
  FRunner.Level.NewGoalItem;
  Assert.AreEqual(-1, FRunner.State.GoalItem);
end;

procedure TTestGreedLevelRules.DovrebbeRicominciareDaCapo;
var
  LIndex: Integer;
begin
  FRunner.State.Player.Score := 900;
  FRunner.State.Player.LevelScore := 5;
  FRunner.State.LevelScore := 4000;
  FRunner.State.Player.Map := 3;
  FRunner.State.Player.Weapons[0] := 7;
  FRunner.State.Player.Weapons[3] := 2;
  FRunner.State.Player.CurrentWeapon := 3;
  for LIndex := 0 to 12 do
    FRunner.State.Player.Inventory[LIndex] := 9;
  FRunner.State.Player.Angst := 3;
  FRunner.State.Player.Shield := 3;
  FRunner.State.Player.BodyCount := 12;
  FRunner.State.Player.Primaries[1] := 2;
  FRunner.State.Player.Secondaries[6] := 1;
  FRunner.State.Player.HoloPic := 44;
  FRunner.State.DeadRestart := True;
  FRunner.State.ExitExists := True;
  FRunner.State.ExitLevel := True;
  FRunner.State.SpecialEffectTime := 77;
  FRunner.State.MoveRate := 4;
  FRunner.State.FallRate := 4;
  FRunner.Game.Calls.Clear;
  FRunner.Level.StartOver(2);
  Assert.AreEqual('resetdisplay,"loadweapon 7","newmap 3 2",INT_TimerHook', FRunner.Game.Calls.CommaText);
  Assert.AreEqual(0, FRunner.State.Player.Score);
  Assert.AreEqual(4000, FRunner.State.Player.LevelScore);
  Assert.AreEqual(-1, FRunner.State.Player.Weapons[3]);
  Assert.AreEqual(0, FRunner.State.Player.CurrentWeapon);
  Assert.AreEqual(4, FRunner.State.Player.Inventory[2]);
  Assert.AreEqual(2, FRunner.State.Player.Inventory[4]);
  Assert.AreEqual(2, FRunner.State.Player.Inventory[5]);
  Assert.AreEqual(2, FRunner.State.Player.Inventory[7]);
  Assert.AreEqual(0, FRunner.State.Player.Inventory[0]);
  Assert.AreEqual(0, FRunner.State.Player.Inventory[12]);
  Assert.AreEqual(100, FRunner.State.Player.Ammo[0]);
  Assert.AreEqual(100, FRunner.State.Player.Ammo[2]);
  Assert.AreEqual(FRunner.State.Player.MaxAngst, FRunner.State.Player.Angst);
  Assert.AreEqual(200, FRunner.State.Player.Shield);
  Assert.AreEqual(0, FRunner.State.Player.BodyCount);
  Assert.AreEqual(0, FRunner.State.Player.Primaries[1]);
  Assert.AreEqual(0, FRunner.State.Player.Secondaries[6]);
  Assert.AreEqual(0, FRunner.State.Player.HoloPic);
  Assert.IsFalse(FRunner.State.DeadRestart);
  Assert.IsFalse(FRunner.State.ExitExists);
  Assert.IsFalse(FRunner.State.ExitLevel);
  Assert.AreEqual(0, FRunner.State.SpecialEffectTime);
  Assert.AreEqual(0, FRunner.State.MoveRate);
  Assert.AreEqual(0, FRunner.State.FallRate);
end;

procedure TTestGreedLevelRules.DovrebbeTenereIlGiocatoreAlLivelloSuccessivo;
begin
  FRunner.State.Player.Score := 900;
  FRunner.State.Player.Map := 3;
  FRunner.State.Player.Weapons[3] := 2;
  FRunner.State.Player.Inventory[9] := 9;
  FRunner.State.Player.Angst := 3;
  FRunner.State.Player.Primaries[0] := 2;
  FRunner.State.ExitLevel := True;
  FRunner.Game.Calls.Clear;
  FRunner.Level.EndLevel;
  Assert.AreEqual('"VI_FadeOut 0 256 0 0 0 64",R_ClearRenderBuffer,I_SetPalette,resetdisplay,"newmap 4 1",' +
    'INT_TimerHook', FRunner.Game.Calls.CommaText);
  Assert.AreEqual(4, FRunner.State.Player.Map);
  Assert.AreEqual(900, FRunner.State.Player.Score);
  Assert.AreEqual(2, FRunner.State.Player.Weapons[3]);
  Assert.AreEqual(9, FRunner.State.Player.Inventory[9]);
  Assert.AreEqual(3, FRunner.State.Player.Angst);
  Assert.AreEqual(0, FRunner.State.Player.Primaries[0], 'the goals of the new level');
  Assert.IsFalse(FRunner.State.ExitLevel);
end;

procedure TTestGreedLevelRules.DovrebbeFareLeFasiDelWarp;
begin
  FRunner.State.Warping := 1;
  FRunner.State.WarpX := Center(30);
  FRunner.State.WarpY := Center(40);
  FRunner.State.Lighting := FRunner.Game.AmbientLight;
  FRunner.Game.Calls.Clear;
  FRunner.Level.WarpAnim;
  Assert.AreEqual(2, FRunner.State.Warping);
  Assert.AreEqual('CA_ReadLump', FRunner.Game.Calls.CommaText, 'the lights of the warp');

  // the lights go down, 128 at a time
  FRunner.Level.WarpAnim;
  Assert.AreEqual(2, FRunner.State.Warping);
  Assert.AreEqual(-128, FRunner.State.ChangeLight);
  Assert.AreEqual(Center(10), FRunner.State.Player.X, 'not moved yet');

  FRunner.State.Lighting := 127;
  FRunner.State.ChangeLight := 0;
  FRunner.Level.WarpAnim;
  Assert.AreEqual(3, FRunner.State.Warping);
  Assert.AreEqual(Center(30), FRunner.State.Player.X);
  Assert.AreEqual(Center(40), FRunner.State.Player.Y);
  Assert.AreEqual(0, FRunner.State.ChangeLight);

  // and come back
  FRunner.Level.WarpAnim;
  Assert.AreEqual(3, FRunner.State.Warping);
  Assert.AreEqual(128, FRunner.State.ChangeLight);

  FRunner.State.Lighting := FRunner.Game.AmbientLight;
  FRunner.Game.Calls.Clear;
  FRunner.Level.WarpAnim;
  Assert.AreEqual(0, FRunner.State.Warping);
  Assert.AreEqual('CA_ReadLump', FRunner.Game.Calls.CommaText, 'the lights of the level');

  FRunner.Game.Calls.Clear;
  FRunner.Level.WarpAnim;
  Assert.AreEqual(0, FRunner.Game.Calls.Count, 'nothing when there is no warp');
end;

procedure TTestGreedLevelRules.DovrebbeCreareLUscitaVicinoAlGiocatore;
begin
  // the tile up and to the left has no floor, the one above has something on it: the third one is free
  FRunner.World.SetValue(gpFloorPic, Spot(9, 9), 0);
  FRunner.World.SetValue(gpMapSprites, Spot(10, 9), 1);
  FRunner.Game.Calls.Clear;
  FRunner.Level.PrepareNexus;
  Assert.IsTrue(FRunner.Game.Has(Format('SpawnSprite %d %d %d 0 0 0 0 0 0', [GREED_S_EXIT, Center(11), Center(9)])));
  Assert.AreEqual(2, FRunner.Game.CountOf(Format('SoundEffect %d', [GREED_SN_NEXUS])));
  Assert.IsTrue(FRunner.State.ExitExists);
  Assert.AreEqual('Translation Nexus Created!', FRunner.Game.Messages[0]);
  Assert.AreEqual(GREED_SM_EXIT, FRunner.MapSprite(11, 9));
  Assert.AreEqual(1, FRunner.Sprites.Count, 'one exit only');
end;

procedure TTestGreedLevelRules.DovrebbeUsareIlWarpJammer;
var
  LArea: Integer;
begin
  LArea := AddArea(10, 20, 20, 99999);
  FRunner.AddSprite(GREED_S_GENERATOR, 15, 15);
  FRunner.AddSprite(GREED_S_GENEND, 16, 15);
  FRunner.AddSprite(GREED_S_MONSTER1, 17, 15);
  FRunner.World.SetValue(gpMapSprites, Spot(15, 15), 1);
  FRunner.State.Player.Inventory[11] := 2;
  FRunner.State.WarpJammer := True;
  FRunner.Level.JamWarps;
  Assert.AreEqual(GREED_SE_WARPJAMMER, FRunner.State.SpecialEffect);
  Assert.AreEqual(FRunner.State.TimeCount + 70 * 60, FRunner.State.SpecialEffectTime);
  Assert.AreEqual(70 * 60, FRunner.Game.TotalEffectTime);
  Assert.AreEqual(1, FRunner.State.Player.Inventory[11]);
  Assert.AreEqual(1, FRunner.Sprites.Count, 'the generators are gone');
  Assert.AreEqual(1, CountKind(GREED_S_MONSTER1));
  Assert.AreEqual(0, FRunner.MapSprite(15, 15));
  Assert.AreEqual(FRunner.State.TimeCount, FRunner.World.GetSpawnArea(LArea).Time);
  Assert.AreEqual('Used Warp Jammer', FRunner.Game.Messages[0]);
  Assert.IsFalse(FRunner.State.WarpJammer);

  // a second one while the first works is not used
  FRunner.State.WarpJammer := True;
  FRunner.Level.JamWarps;
  Assert.AreEqual(1, FRunner.State.Player.Inventory[11]);
  Assert.AreEqual(1, FRunner.Game.Messages.Count);
  Assert.IsFalse(FRunner.State.WarpJammer);
end;

procedure TTestGreedLevelRules.DovrebbeCostruireScenariRipetibili;
var
  LFirst, LSecond: TLevelScenario;
  LHashes, LAgain: TList<Cardinal>;
  LIndex: Integer;
begin
  LFirst := BuildLevelScenario(2);
  LSecond := BuildLevelScenario(2);
  Assert.AreEqual(Length(LFirst.Sprites), Length(LSecond.Sprites));
  Assert.AreEqual(Length(LFirst.Waypoints), Length(LSecond.Waypoints));
  Assert.IsTrue(Length(LFirst.Sprites) > 20, 'a level with things in it');
  Assert.IsTrue(Length(LFirst.Elevators) > 3);
  Assert.IsTrue(Length(LFirst.Areas) > 3);
  LFirst.Tics := 40;
  LHashes := TList<Cardinal>.Create;
  LAgain := TList<Cardinal>.Create;
  try
    FRunner.Run(LFirst, LHashes);
    FRunner.Run(LFirst, LAgain);
    Assert.AreEqual(40, LHashes.Count);
    for LIndex := 0 to LHashes.Count - 1 do
      Assert.AreEqual(LHashes[LIndex], LAgain[LIndex], 'the same frames give the same hashes');
    Assert.AreNotEqual(LHashes[0], LHashes[39], 'the state changes');
  finally
    LAgain.Free;
    LHashes.Free;
  end;
end;

procedure TTestGreedLevelRules.DovrebbeDareLeStesseImpronteDelCodiceOriginale;
var
  LGolden: TStringList;
  LHashes: TList<Cardinal>;
  LParts: TArray<string>;
  LLine, LScenario, LTics, LTic, LScenarios, LTotalTics, LSkipped: Integer;
begin
  LGolden := TStringList.Create;
  LHashes := TList<Cardinal>.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath('level.golden.txt'));
    LScenarios := 0;
    LTotalTics := 0;
    LSkipped := 0;
    LLine := 0;
    while LLine < LGolden.Count do
    begin
      if LGolden[LLine].StartsWith('X ') then
        Inc(LSkipped);
      if not LGolden[LLine].StartsWith('S ') then
      begin
        Inc(LLine);
        Continue;
      end;
      LParts := LGolden[LLine].Split([' ']);
      LScenario := StrToInt(LParts[1]);
      LTics := StrToInt(LParts[2]);
      LHashes.Clear;
      FRunner.Run(BuildLevelScenario(LScenario), LHashes);
      Assert.AreEqual(LTics, LHashes.Count, Format('scenario %d: the number of frames', [LScenario]));
      for LTic := 0 to LTics - 1 do
        if LGolden[LLine + 1 + LTic] <> IntToHex(LHashes[LTic], 8) then
          Assert.Fail(Format('scenario %d: the frame %d differs from the original (%s, here %s)',
            [LScenario, LTic, LGolden[LLine + 1 + LTic], IntToHex(LHashes[LTic], 8)]));
      Inc(LScenarios);
      LTotalTics := LTotalTics + LTics;
      LLine := LLine + 1 + LTics;
    end;
    Assert.AreEqual(LEVEL_SCENARIO_COUNT, LScenarios + LSkipped, 'every scenario is in the golden file');
    Assert.AreEqual(0, LSkipped, 'the original runs every scenario');
    Assert.IsTrue(LTotalTics > 20000, 'the frames that were compared');
  finally
    LHashes.Free;
    LGolden.Free;
  end;
end;

end.
