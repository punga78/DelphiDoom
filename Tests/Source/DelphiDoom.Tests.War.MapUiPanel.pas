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
    procedure DovrebbeLasciareVuotoPerGliEdificiEPerChiHaIncantesimi;
    [Test]
    procedure DovrebbeLasciareVuotoSenzaSelezione;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Factory,
  DelphiDoom.War.Model.Commands.Types, DelphiDoom.War.Sound.SeededRandom, DelphiDoom.War.Ui.Types,
  DelphiDoom.War.MapUi.UnitNames.Data;

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
  // a spell that was researched is not ported: the panel is empty
  FWorld.Context.Players[0]^.Upgrades[3].Allowed := 2;
  FWorld.Context.Players[0]^.Upgrades[3].Level := 1;
  Select([Spawn(WAR_UNIT_CONJURER, 0)]);
  Assert.AreEqual(0, Count);
  FWorld.Context.Players[0]^.Race := wraOrcs;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_SHIELD div 2].Level := 1;
  FWorld.Context.Players[0]^.Upgrades[WAR_UPGRADE_AXES div 2].Level := 2;
  FWorld.Context.Players[0]^.Upgrades[3].Level := 0;
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

procedure TTestWarMapUiPanel.DovrebbeLasciareVuotoPerGliEdificiEPerChiHaIncantesimi;
var
  LSlot: Integer;
begin
  LSlot := FWorld.Entities.CreateBuilding(WAR_UNIT_BARRACKS_HUMANS, 20, 20, 0, False);
  Assert.AreNotEqual(0, LSlot);
  Select([FWorld.Context.Pool.Slots[LSlot]^.Id]);
  Assert.AreEqual(0, Count, 'gli edifici non sono portati');
  Select([Spawn(WAR_UNIT_FOOTMAN, 0), FWorld.Context.Pool.Slots[LSlot]^.Id]);
  Assert.AreEqual(0, Count);
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
