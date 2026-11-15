{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the panel of the commands             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiPanel;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.World, DelphiDoom.War.Model.Context,
  DelphiDoom.War.MapUi.Types, DelphiDoom.War.MapUi.CommandPanel;

type
  [TestFixture]
  [Category('war')]
  TTestWarMapUiPanel = class(TObject)
  strict private
    FWorld: TWarModelWorld;
    FPanel: TWarMapCommandPanel;
    FResult: TWarCommandPanel;
    function Spawn(AUnitType: Integer; APlayer: Byte; AKind: Integer = 0; AAmount: Integer = 0): Word;
    procedure Select(const AIds: array of Word);
    function Count: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareMuoviFermaEAttaccaAUnFante;
    [Test]
    procedure DovrebbeDareLeImmaginiDegliOrchi;
    [Test]
    procedure DovrebbeCambiareLeImmaginiConIMiglioramenti;
    [Test]
    procedure DovrebbeDareIComandiDelLavoratoreEConsegnareSeCarico;
    [Test]
    procedure DovrebbeAggiungereCostruisciAvanzatoConLaSegheria;
    [Test]
    procedure DovrebbeDareITestiDellaFattoriaEDellaMiniera;
    [Test]
    procedure DovrebbeLasciareVuotoPerUnUnitaDiUnAltraRazza;
    [Test]
    procedure DovrebbeDareSoloIComandiComuniAPiuUnita;
    [Test]
    procedure DovrebbeDareIComandiDiBaseAiMaghiSenzaIncantesimi;
    [Test]
    procedure DovrebbeDareLAddestramentoDellaCasermaESoloIlFanteSenzaSegheria;
    [Test]
    procedure DovrebbeMostrareSoloAnnullaPerUnEdificioInCostruzioneEPerChiHaUnComandoInAttesa;
    [Test]
    procedure DovrebbeMostrareIMenuDellEdificioPerIlContadinoCheCostruisce;
    [Test]
    procedure DovrebbeDareITuttiIComandiDegliEdificiConLeCapacitaEIMiglioramenti;
    [Test]
    procedure DovrebbeDareLeImmaginiDeiMiglioramentiEIlCostoDelSecondoLivello;
    [Test]
    procedure DovrebbeLasciareVuotoSenzaSelezione;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.Sound.SeededRandom, DelphiDoom.War.Ui.Types,
  DelphiDoom.War.MapUi.UnitNames.Data, DelphiDoom.War.MapUi.CommandData.Data;

{ TTestWarMapUiPanel }

procedure TTestWarMapUiPanel.Setup;
begin
  FWorld := TWarModelFactory.CreateWorld(TWarSeededRandom.Create(1));
  FWorld.Context.Players[0]^.Race := wraHumans;
  FWorld.Context.Players[1]^.Race := wraOrcs;
  FPanel := TWarMapCommandPanel.Create(FWorld.Context);
end;

procedure TTestWarMapUiPanel.TearDown;
begin
  FPanel.Free;
  FWorld.Free;
end;

function TTestWarMapUiPanel.Spawn(AUnitType: Integer; APlayer: Byte; AKind: Integer; AAmount: Integer): Word;
var
  LSlot: Integer;
begin
  LSlot := FWorld.Entities.CreateUnit(AUnitType, 10, 10, APlayer, TWarResourceKind(AKind), Cardinal(AAmount), True);
  Assert.AreNotEqual(0, LSlot);
  FWorld.Entities.SetInitialIdle(LSlot);
  Result := FWorld.Context.Pool.Slots[LSlot]^.Id;
end;

procedure TTestWarMapUiPanel.Select(const AIds: array of Word);
begin
  FWorld.Context.Selection.Assign(AIds);
  FPanel.Update(FResult);
end;

function TTestWarMapUiPanel.Count: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 5 do
    if FResult.SlotsActive[LIndex] then
      Inc(Result);
end;

procedure TTestWarMapUiPanel.DovrebbeDareMuoviFermaEAttaccaAUnFante;
begin
  Select([Spawn(WAR_UNIT_FOOTMAN, 0)]);
  Assert.AreEqual(3, Count);
  Assert.AreEqual('MOVE', string(FResult.Slots[0].Tooltip));
  Assert.AreEqual(WAR_PORTRAIT_MOVE_HUMANS, FResult.Slots[0].FrameIndex);
  Assert.IsTrue(FResult.Slots[0].HotKey = wkM);
  Assert.AreEqual('STOP', string(FResult.Slots[1].Tooltip));
  Assert.AreEqual(WAR_PORTRAIT_SHIELD_1_HUMANS, FResult.Slots[1].FrameIndex);
  Assert.AreEqual('ATTACK', string(FResult.Slots[2].Tooltip));
  Assert.AreEqual(WAR_PORTRAIT_SWORD_1, FResult.Slots[2].FrameIndex);
  Assert.AreEqual(WAR_COMMAND_ATTACK, FResult.Slots[2].Command);
  Assert.IsFalse(FResult.SlotsActive[3]);
end;

procedure TTestWarMapUiPanel.DovrebbeDareLeImmaginiDegliOrchi;
begin
  FWorld.Context.Players[0]^.Race := wraOrcs;
  Select([Spawn(WAR_UNIT_GRUNT, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_MOVE_ORCS, FResult.Slots[0].FrameIndex);
  Assert.AreEqual(WAR_PORTRAIT_SHIELD_1_ORCS, FResult.Slots[1].FrameIndex);
  Assert.AreEqual(WAR_PORTRAIT_AXE_1, FResult.Slots[2].FrameIndex);
  Select([Spawn(WAR_UNIT_SPEARMAN, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_SPEAR_1, FResult.Slots[2].FrameIndex);
  Select([Spawn(WAR_UNIT_NECROLYTE, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_SHADOW_SPEAR, FResult.Slots[2].FrameIndex);
  Select([Spawn(WAR_UNIT_WARLOCK, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_FIREBALL, FResult.Slots[2].FrameIndex);
end;

procedure TTestWarMapUiPanel.DovrebbeCambiareLeImmaginiConIMiglioramenti;
begin
  // the upgrades are kept by upgrade / 2: shield, swords (and axes), arrows (and spears)
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_SHIELD div 2].Level := 2;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level := 1;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_ARROWS div 2].Level := 2;
  Select([Spawn(WAR_UNIT_FOOTMAN, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_SHIELD_3_HUMANS, FResult.Slots[1].FrameIndex);
  Assert.AreEqual(WAR_PORTRAIT_SWORD_2, FResult.Slots[2].FrameIndex);
  Select([Spawn(WAR_UNIT_ARCHER, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_ARROW_3, FResult.Slots[2].FrameIndex);
  Select([Spawn(WAR_UNIT_CONJURER, 0)]);
  Assert.AreEqual(3, Count, 'senza ricerche il mago ha tre bottoni');
  // a spell that was researched (and is allowed) is a fourth button, with the portrait of the spell
  FWorld.Context.Players[0]^.Features[WAR_FEATURE_SPELL_RAIN_OF_FIRE div 2] := 1;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_RAIN_OF_FIRE div 2].Allowed := 1;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_RAIN_OF_FIRE div 2].Level := 1;
  Select([Spawn(WAR_UNIT_CONJURER, 0)]);
  Assert.AreEqual(4, Count);
  Assert.AreEqual(WAR_COMMAND_SPELL_RAIN_OF_FIRE, FResult.Slots[3].Command);
  Assert.AreEqual(WAR_PORTRAIT_RAIN_OF_FIRE, FResult.Slots[3].FrameIndex);
  FWorld.Context.Players[0]^.Race := wraOrcs;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_SHIELD div 2].Level := 1;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_AXES div 2].Level := 2;
  Select([Spawn(WAR_UNIT_GRUNT, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_SHIELD_2_ORCS, FResult.Slots[1].FrameIndex);
  Assert.AreEqual(WAR_PORTRAIT_AXE_3, FResult.Slots[2].FrameIndex);
end;

procedure TTestWarMapUiPanel.DovrebbeDareIComandiDelLavoratoreEConsegnareSeCarico;
begin
  Select([Spawn(WAR_UNIT_PEASANT, 0)]);
  Assert.AreEqual(5, Count);
  Assert.AreEqual(WAR_COMMAND_REPAIR, FResult.Slots[2].Command);
  Assert.AreEqual(WAR_COMMAND_HARVEST, FResult.Slots[3].Command);
  Assert.AreEqual(WAR_PORTRAIT_HARVEST, FResult.Slots[3].FrameIndex);
  Assert.AreEqual(WAR_COMMAND_BUILD_BASIC, FResult.Slots[4].Command);
  Assert.AreEqual('BUILD BASIC STRUCTURE', string(FResult.Slots[4].Tooltip));
  // with a full load the button delivers
  Select([Spawn(WAR_UNIT_PEASANT, 0, Ord(wrkGold), 100)]);
  Assert.AreEqual(WAR_COMMAND_DELIVER, FResult.Slots[3].Command);
  Assert.AreEqual(16, FResult.Slots[3].HighlightIndex);
  Assert.AreEqual(WAR_PORTRAIT_DELIVER, FResult.Slots[3].FrameIndex);
  Select([Spawn(WAR_UNIT_PEASANT, 0, Ord(wrkWood), 99)]);
  Assert.AreEqual(WAR_COMMAND_HARVEST, FResult.Slots[3].Command, 'un carico a meta'' non si consegna');
  FWorld.Context.Players[0]^.Race := wraOrcs;
  Select([Spawn(WAR_UNIT_PEON, 0)]);
  Assert.AreEqual(5, Count);
  Assert.AreEqual('REPAIR', string(FResult.Slots[2].Tooltip));
  Assert.AreEqual(WAR_PORTRAIT_REPAIR, FResult.Slots[2].FrameIndex);
  Assert.AreEqual(WAR_PORTRAIT_BUILD_BASIC, FResult.Slots[4].FrameIndex);
end;

procedure TTestWarMapUiPanel.DovrebbeAggiungereCostruisciAvanzatoConLaSegheria;
var
  LSlot: Integer;
begin
  LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_LUMBERMILL_HUMANS, 20, 20, 0, False);
  Assert.AreNotEqual(0, LSlot);
  Select([Spawn(WAR_UNIT_PEASANT, 0)]);
  Assert.AreEqual(6, Count);
  Assert.AreEqual(WAR_COMMAND_BUILD_ADVANCED, FResult.Slots[5].Command);
  Assert.AreEqual(6, FResult.Slots[5].HighlightIndex);
  Assert.AreEqual(WAR_PORTRAIT_BUILD_ADVANCED, FResult.Slots[5].FrameIndex);
  FWorld.Context.Players[0]^.Race := wraOrcs;
  LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_LUMBERMILL_ORCS, 24, 20, 0, False);
  Assert.AreNotEqual(0, LSlot);
  Select([Spawn(WAR_UNIT_PEON, 0)]);
  Assert.AreEqual(6, Count);
end;

procedure TTestWarMapUiPanel.DovrebbeDareITestiDellaFattoriaEDellaMiniera;
var
  LSlot: Integer;
begin
  LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_FARM_HUMANS, 20, 20, 0, False);
  Assert.AreNotEqual(0, LSlot);
  Spawn(WAR_UNIT_FOOTMAN, 0);
  Select([FWorld.Context.Pool.Slots[LSlot]^.Id]);
  Assert.AreEqual('FOOD USAGE:', string(FResult.Texts[0]));
  Assert.AreEqual('GROWN 5', string(FResult.Texts[1]));
  Assert.AreEqual(' USED 1', string(FResult.Texts[2]));
  Assert.IsTrue(FResult.TextsVisible[0] and FResult.TextsVisible[1] and FResult.TextsVisible[2]);
  Assert.AreEqual(0, Count);
  Select([Spawn(WAR_UNIT_GOLDMINE, 4, Ord(wrkGold), 7500)]);
  Assert.AreEqual('GOLD LEFT', string(FResult.Texts[0]));
  Assert.AreEqual('7500', string(FResult.Texts[3]));
  Assert.IsFalse(FResult.TextsVisible[1]);
end;

procedure TTestWarMapUiPanel.DovrebbeLasciareVuotoPerUnUnitaDiUnAltraRazza;
begin
  // a footman of the player 1, who plays the orcs: no commands
  Select([Spawn(WAR_UNIT_FOOTMAN, 1)]);
  Assert.AreEqual(0, Count);
end;

procedure TTestWarMapUiPanel.DovrebbeDareSoloIComandiComuniAPiuUnita;
begin
  Select([Spawn(WAR_UNIT_FOOTMAN, 0), Spawn(WAR_UNIT_PEASANT, 0)]);
  Assert.AreEqual(2, Count, 'muovi e ferma');
  Assert.IsTrue(FResult.SlotsActive[0] and FResult.SlotsActive[1]);
  Select([Spawn(WAR_UNIT_FOOTMAN, 0), Spawn(WAR_UNIT_FOOTMAN, 0)]);
  Assert.AreEqual(3, Count);
end;

procedure TTestWarMapUiPanel.DovrebbeDareIComandiDiBaseAiMaghiSenzaIncantesimi;
begin
  Select([Spawn(WAR_UNIT_CONJURER, 0)]);
  Assert.AreEqual(3, Count);
  Assert.AreEqual(WAR_PORTRAIT_ELEMENTAL_BLAST, FResult.Slots[2].FrameIndex);
  FWorld.Context.Players[0]^.Race := wraOrcs;
  Select([Spawn(WAR_UNIT_CLERIC, 0)]);
  Assert.AreEqual(0, Count, 'il chierico e'' degli umani: un giocatore orco non ha comandi');
  FWorld.Context.Players[0]^.Race := wraHumans;
  Select([Spawn(WAR_UNIT_CLERIC, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_HOLY_LANCE, FResult.Slots[2].FrameIndex);
end;

procedure TTestWarMapUiPanel.DovrebbeDareLAddestramentoDellaCasermaESoloIlFanteSenzaSegheria;
var
  LSlot: Integer;
begin
  LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_BARRACKS_HUMANS, 20, 20, 0, False);
  Assert.AreNotEqual(0, LSlot);
  Select([FWorld.Context.Pool.Slots[LSlot]^.Id]);
  Assert.AreEqual(1, Count);
  Assert.AreEqual(WAR_CMD_TRAIN_FOOTMAN, FResult.Slots[0].Command);
  Assert.AreEqual(WAR_PORTRAIT_FOOTMAN, FResult.Slots[0].FrameIndex);
  Assert.AreEqual('TRAIN FOOTMAN', string(FResult.Slots[0].Tooltip));
  Assert.AreEqual(FWorld.Context.Database.GetUnitStats(WAR_UNIT_FOOTMAN).GoldCost, FResult.Slots[0].Gold);
  // the archer needs a lumber mill, the catapult a blacksmith, the knight a stable too
  FWorld.Entities.CreateBuilding(WAR_UNIT_LUMBERMILL_HUMANS, 24, 20, 0, False);
  Select([FWorld.Context.Pool.Slots[LSlot]^.Id]);
  Assert.AreEqual(2, Count);
  Assert.AreEqual(WAR_CMD_TRAIN_ARCHER, FResult.Slots[1].Command);
  // a footman and a barracks have nothing in common
  Select([Spawn(WAR_UNIT_FOOTMAN, 0), FWorld.Context.Pool.Slots[LSlot]^.Id]);
  Assert.AreEqual(0, Count);
end;

procedure TTestWarMapUiPanel.DovrebbeMostrareSoloAnnullaPerUnEdificioInCostruzioneEPerChiHaUnComandoInAttesa;
var
  LSlot: Integer;
  LId: Word;
begin
  LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_BARRACKS_HUMANS, 20, 20, 0, True);
  Assert.AreNotEqual(0, LSlot);
  FWorld.Context.Pool.Slots[LSlot]^.UnitData.Building := True;
  Select([FWorld.Context.Pool.Slots[LSlot]^.Id]);
  Assert.AreEqual(1, Count);
  Assert.IsTrue(FResult.SlotsActive[5]);
  Assert.AreEqual(WAR_COMMAND_CANCEL, FResult.Slots[5].Command);
  Assert.AreEqual(WAR_PORTRAIT_CANCEL, FResult.Slots[5].FrameIndex);
  Assert.AreEqual(3, FResult.Slots[5].HighlightCount);
  // a footman with a command waiting: cancel only
  LId := Spawn(WAR_UNIT_FOOTMAN, 0);
  FWorld.Context.Selection.Assign([LId]);
  FPanel.Update(FResult, WAR_COMMAND_ATTACK);
  Assert.AreEqual(1, Count);
  Assert.AreEqual(WAR_COMMAND_CANCEL, FResult.Slots[5].Command);
end;

procedure TTestWarMapUiPanel.DovrebbeDareITuttiIComandiDegliEdificiConLeCapacitaEIMiglioramenti;
var
  LNext: Integer;
  LPlayer: PWarPlayerInfo;

  function Pick(AType: Integer): string;
  var
    LSlot: Integer;
    LIndex: Integer;
  begin
    // the commands of a building of the type, one number each (0 where there is no button)
    Inc(LNext, 4);
    LSlot := FWorld.Entities.CreateBuilding(AType, 4 + (LNext mod 56), 4 + (LNext div 56) * 4, 0, False);
    Assert.AreNotEqual(0, LSlot);
    FWorld.Context.Selection.Assign([FWorld.Context.Pool.Slots[LSlot]^.Id]);
    FPanel.Update(FResult);
    Result := '';
    for LIndex := 0 to 5 do
      if FResult.SlotsActive[LIndex] then
        Result := Result + IntToStr(FResult.Slots[LIndex].Command) + ' '
      else
        Result := Result + '0 ';
    Result := Trim(Result);
  end;

  procedure Allow(AFeature, AUpgrade, AAllowed, ALevel: Integer);
  begin
    LPlayer^.Features[AFeature div 2] := 1;
    LPlayer^.Upgrades[AUpgrade div 2].Allowed := AAllowed;
    LPlayer^.Upgrades[AUpgrade div 2].Level := ALevel;
  end;

begin
  LPlayer := FWorld.Context.Players[0];
  // the humans: the three researches of a tower, the upgrades of the buildings that have one
  Allow(WAR_FEATURE_SPELL_SCORPION, WAR_UPGRADE_SCORPIONS, 1, 0);
  Allow(WAR_FEATURE_SPELL_RAIN_OF_FIRE, WAR_UPGRADE_RAIN_OF_FIRE, 1, 0);
  Allow(WAR_FEATURE_SPELL_WATER_ELEMENTAL, WAR_UPGRADE_WATER_ELEMENTAL, 1, 0);
  Assert.AreEqual(Format('%d %d %d %d 0 0', [WAR_CMD_TRAIN_CONJURER, WAR_CMD_UPGRADE_SCORPION, WAR_CMD_UPGRADE_RAIN_OF_FIRE,
    WAR_CMD_UPGRADE_WATER_ELEMENTAL]), Pick(WAR_UNIT_TOWER_HUMANS));
  LPlayer^.Upgrades[WAR_UPGRADE_ARROWS div 2].Allowed := 2;
  Assert.AreEqual(Format('%d 0 0 0 0 0', [WAR_CMD_UPGRADE_ARROWS]), Pick(WAR_UNIT_LUMBERMILL_HUMANS));
  LPlayer^.Upgrades[WAR_UPGRADE_HORSES div 2].Allowed := 2;
  Assert.AreEqual(Format('%d 0 0 0 0 0', [WAR_CMD_UPGRADE_HORSES]), Pick(WAR_UNIT_STABLE));
  // the barracks need the buildings that open the units: the archer wants the lumber mill, the catapult the blacksmith and
  // the knight the stable too
  Assert.AreEqual(Format('%d %d 0 0 0 0', [WAR_CMD_TRAIN_FOOTMAN, WAR_CMD_TRAIN_ARCHER]), Pick(WAR_UNIT_BARRACKS_HUMANS));
  Pick(WAR_UNIT_BLACKSMITH_HUMANS);
  Assert.AreEqual(Format('%d %d %d %d 0 0', [WAR_CMD_TRAIN_FOOTMAN, WAR_CMD_TRAIN_ARCHER, WAR_CMD_TRAIN_CATAPULT_HUMANS,
    WAR_CMD_TRAIN_KNIGHT]), Pick(WAR_UNIT_BARRACKS_HUMANS));
  // a farm that is built has no buttons (its text is the food)
  Assert.AreEqual('0 0 0 0 0 0', Pick(WAR_UNIT_FARM_HUMANS));
  // the orcs
  LPlayer^.Race := wraOrcs;
  Allow(WAR_FEATURE_SPELL_SPIDER, WAR_UPGRADE_SPIDERS, 1, 0);
  Allow(WAR_FEATURE_SPELL_POISON_CLOUD, WAR_UPGRADE_POISON_CLOUD, 1, 0);
  Allow(WAR_FEATURE_SPELL_DAEMON, WAR_UPGRADE_DAEMON, 1, 0);
  Assert.AreEqual(Format('%d %d %d %d 0 0', [WAR_CMD_TRAIN_WARLOCK, WAR_CMD_UPGRADE_SPIDER, WAR_CMD_UPGRADE_POISON_CLOUD,
    WAR_CMD_UPGRADE_DAEMON]), Pick(WAR_UNIT_TOWER_ORCS));
  Allow(WAR_FEATURE_SPELL_RAISE_DEAD, WAR_UPGRADE_RAISE_DEAD, 1, 0);
  Allow(WAR_FEATURE_SPELL_DARK_VISION, WAR_UPGRADE_DARK_VISION, 1, 0);
  Allow(WAR_FEATURE_SPELL_UNHOLY_ARMOR, WAR_UPGRADE_UNHOLY_ARMOR, 1, 0);
  Assert.AreEqual(Format('%d %d %d %d 0 0', [WAR_CMD_TRAIN_NECROLYTE, WAR_CMD_UPGRADE_RAISE_DEAD,
    WAR_CMD_UPGRADE_DARK_VISION, WAR_CMD_UPGRADE_UNHOLY_ARMOR]), Pick(WAR_UNIT_TEMPLE));
  LPlayer^.Upgrades[WAR_UPGRADE_SPEARS div 2].Allowed := 2;
  Assert.AreEqual(Format('%d 0 0 0 0 0', [WAR_CMD_UPGRADE_SPEARS]), Pick(WAR_UNIT_LUMBERMILL_ORCS));
  LPlayer^.Upgrades[WAR_UPGRADE_WOLVES div 2].Allowed := 2;
  Assert.AreEqual(Format('%d 0 0 0 0 0', [WAR_CMD_UPGRADE_WOLVES]), Pick(WAR_UNIT_KENNEL));
  LPlayer^.Upgrades[WAR_UPGRADE_AXES div 2].Allowed := 2;
  LPlayer^.Upgrades[WAR_UPGRADE_SHIELD div 2].Allowed := 2;
  Assert.AreEqual(Format('%d %d 0 0 0 0', [WAR_CMD_UPGRADE_AXES, WAR_CMD_UPGRADE_SHIELD_ORCS]), Pick(WAR_UNIT_BLACKSMITH_ORCS));
  // the barracks of the orcs: the spearman, the catapult and the raider come with their buildings
  Assert.AreEqual(Format('%d %d %d %d 0 0', [WAR_CMD_TRAIN_GRUNT, WAR_CMD_TRAIN_SPEARMAN, WAR_CMD_TRAIN_CATAPULT_ORCS,
    WAR_CMD_TRAIN_RAIDER]), Pick(WAR_UNIT_BARRACKS_ORCS), 'con la segheria, la fucina e il canile');
end;

procedure TTestWarMapUiPanel.DovrebbeDareLeImmaginiDeiMiglioramentiEIlCostoDelSecondoLivello;
var
  LPlayer: PWarPlayerInfo;
  LId: Word;
begin
  LPlayer := FWorld.Context.Players[0];
  // the costs: the first level of a research and then the second
  LPlayer^.Upgrades[WAR_UPGRADE_SWORDS div 2].Allowed := 2;
  LPlayer^.Upgrades[WAR_UPGRADE_SWORDS div 2].Level := 1;
  LId := FWorld.Entities.CreateBuilding(WAR_UNIT_BLACKSMITH_HUMANS, 20, 20, 0, False);
  FWorld.Context.Selection.Assign([FWorld.Context.Pool.Slots[LId]^.Id]);
  FPanel.Update(FResult);
  Assert.AreEqual(WAR_PORTRAIT_SWORD_3, FResult.Slots[0].FrameIndex, 'la spada del secondo livello');
  Assert.AreEqual(FWorld.Context.Database.GetUpgradeStats(WAR_UPGRADE_SWORDS).GoldCost2, FResult.Slots[0].Gold);
  // the weapon of a footman: the arrow of an archer at level 1, the axe and the shields by level
  LPlayer^.Upgrades[WAR_UPGRADE_ARROWS div 2].Level := 1;
  Select([Spawn(WAR_UNIT_ARCHER, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_ARROW_2, FResult.Slots[2].FrameIndex);
  LPlayer^.Upgrades[WAR_UPGRADE_SHIELD div 2].Level := 1;
  Select([Spawn(WAR_UNIT_FOOTMAN, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_SHIELD_2_HUMANS, FResult.Slots[1].FrameIndex);
  LPlayer^.Race := wraOrcs;
  LPlayer^.Upgrades[WAR_UPGRADE_SHIELD div 2].Level := 2;
  Select([Spawn(WAR_UNIT_GRUNT, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_SHIELD_3_ORCS, FResult.Slots[1].FrameIndex);
  LPlayer^.Upgrades[WAR_UPGRADE_SPEARS div 2].Level := 1;
  Select([Spawn(WAR_UNIT_SPEARMAN, 0)]);
  Assert.AreEqual(WAR_PORTRAIT_SPEAR_2, FResult.Slots[2].FrameIndex);
end;

procedure TTestWarMapUiPanel.DovrebbeMostrareIMenuDellEdificioPerIlContadinoCheCostruisce;
var
  LId: Word;
begin
  LId := Spawn(WAR_UNIT_PEASANT, 0);
  FWorld.Context.Selection.Assign([LId]);
  FPanel.Update(FResult, WAR_COMMAND_BUILD_BASIC);
  Assert.AreEqual(WAR_CMD_BUILD_FARM_HUMANS, FResult.Slots[0].Command);
  Assert.AreEqual(WAR_CMD_BUILD_BARRACKS_HUMANS, FResult.Slots[2].Command);
  Assert.IsFalse(FResult.SlotsActive[1], 'senza la capacita'' della segheria');
  Assert.AreEqual(WAR_COMMAND_CANCEL, FResult.Slots[5].Command);
  Assert.AreEqual(FWorld.Context.Database.GetBuildingStats(WAR_UNIT_FARM_HUMANS).GoldCost, FResult.Slots[0].Gold);
  Assert.AreEqual(FWorld.Context.Database.GetBuildingStats(WAR_UNIT_FARM_HUMANS).WoodCost, FResult.Slots[0].Wood);
  FWorld.Context.Players[0]^.Features[WAR_FEATURE_UNIT_LUMBER_MILL_HUMANS div 2] := 1;
  FPanel.Update(FResult, WAR_COMMAND_BUILD_BASIC);
  Assert.AreEqual(WAR_CMD_BUILD_LUMBERMILL_HUMANS, FResult.Slots[1].Command);
  FPanel.Update(FResult, WAR_COMMAND_BUILD_ADVANCED);
  Assert.AreEqual(WAR_CMD_BUILD_BLACKSMITH_HUMANS, FResult.Slots[0].Command);
  Assert.AreEqual(WAR_CMD_BUILD_CHURCH, FResult.Slots[1].Command);
  Assert.AreEqual(WAR_CMD_BUILD_STABLE, FResult.Slots[2].Command);
  Assert.IsFalse(FResult.SlotsActive[3], 'la torre vuole la fucina');
  // the orcs: the first button of the advanced menu is the barracks, as in the original
  FWorld.Context.Players[0]^.Race := wraOrcs;
  LId := Spawn(WAR_UNIT_PEON, 0);
  FWorld.Context.Selection.Assign([LId]);
  FPanel.Update(FResult, WAR_COMMAND_BUILD_ADVANCED);
  Assert.AreEqual(WAR_CMD_BUILD_BARRACKS_ORCS, FResult.Slots[0].Command);
  Assert.AreEqual(WAR_CMD_BUILD_TEMPLE, FResult.Slots[1].Command);
  Assert.AreEqual(WAR_CMD_BUILD_KENNEL, FResult.Slots[2].Command);
end;

procedure TTestWarMapUiPanel.DovrebbeLasciareVuotoSenzaSelezione;
begin
  FResult.SlotsActive[1] := True;
  FWorld.Context.Selection.Clear;
  FPanel.Update(FResult);
  Assert.AreEqual(0, Count);
  // an entity that does not exist (left in the selection) shows nothing
  FWorld.Context.Selection.Add(4000);
  FPanel.Update(FResult);
  Assert.AreEqual(0, Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiPanel);

end.
