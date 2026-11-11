{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the inventory screen of a battle (InventoryState): }
{  the equipment template (create, apply, clear, auto-equip), the buttons, the  }
{  item under the mouse and the way out, on a real battle                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.InventoryState;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.XcomBattleStates.InventoryState,
  DelphiDoom.Tests.XcomBattleStates.Bench;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomInventoryState = class
  strict private
    FBench: TBattleBench;
    FState: TXcomBattlescapeState;
    FInventory: TXcomInventoryState;
    function Open(ATimeUnits: Boolean): Boolean;
    function Soldier: TXcomBattleUnit;
    procedure Click(ASurface: TXcomInteractiveSurface);
    procedure ClickAt(AX, AY: Integer);
    procedure MoveTo(AX, AY: Integer);
    procedure PressKey(AKey: Integer);
    /// <summary>The items of the soldier that are not fixed weapons, as "type@slot:x,y" sorted</summary>
    function Carried(AUnit: TXcomBattleUnit): string;
    function Asked(const ACall: string): Integer;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaUnitaDiTempoIPulsantiDelModelloSiVedono;
    [Test]
    procedure ConLeUnitaDiTempoIPulsantiDelModelloSonoNascosti;
    [Test]
    procedure CreaDovrebbeCopiareLEquipaggiamentoNelModello;
    [Test]
    procedure ApplicaSenzaModelloDovrebbeSvuotareLInventario;
    [Test]
    procedure ApplicaDovrebbeRidareLEquipaggiamentoDelModello;
    [Test]
    procedure ApplicaDovrebbeAvvisareSeMancanoGliOggetti;
    [Test]
    procedure IlModelloDovrebbeValereAncheSuUnAltroSoldato;
    [Test]
    procedure IlTastoSvuotaDovrebbeLasciareTuttoATerra;
    [Test]
    procedure IlTastoDellEquipaggiamentoAutomaticoDovrebbeDareOggetti;
    [Test]
    procedure ITastiDelModelloDovrebberoCreareEApplicare;
    [Test]
    procedure ConUnOggettoInManoIPulsantiDelModelloNonFannoNulla;
    [Test]
    procedure ILPulsantiSuccessivoEPrecedenteCambianoSoldato;
    [Test]
    procedure IlGradoDovrebbeAprireLaSchedaDelSoldato;
    [Test]
    procedure LOggettoSottoIlMouseDovrebbeEssereDescritto;
    [Test]
    procedure ScaricaDovrebbeTogliereIlCaricatoreDallArmaInMano;
    [Test]
    procedure OkSenzaUnitaDiTempoDovrebbeSalvareLEquipaggiamentoEChiudere;
    [Test]
    procedure OkConLeUnitaDiTempoDovrebbeSoloChiudere;
    [Test]
    procedure ISuggerimentiDeiPulsantiDovrebberoApparireEsparire;
  end;

implementation

uses
  DelphiDoom.XcomSave.Soldier;

const
  KEY_CREATE = 99;
  KEY_APPLY = 118;
  KEY_CLEAR = 120;
  KEY_AUTOEQUIP = 122;
  KEY_ESCAPE = 27;

procedure TTestXcomInventoryState.SetupFixture;
begin
  FBench := TBattleBench.Create;
end;

procedure TTestXcomInventoryState.TearDownFixture;
begin
  FBench.Free;
end;

procedure TTestXcomInventoryState.Setup;
begin
  FState := nil;
  FInventory := nil;
end;

procedure TTestXcomInventoryState.TearDown;
begin
  FInventory := nil;
  FState := nil;
  FBench.Stop;
end;

function TTestXcomInventoryState.Open(ATimeUnits: Boolean): Boolean;
begin
  Result := FBench.Available;
  if not Result then
  begin
    Assert.Pass('the data of TFTD are not here');
    Exit;
  end;
  FBench.Start;
  FState := FBench.PushBattlescape;
  FBench.World.Wait(60);
  FInventory := TXcomInventoryState.Create(FBench.World.Game, FState, ATimeUnits);
  FBench.World.Game.PushState(FInventory);
  FBench.World.Wait(60);
end;

function TTestXcomInventoryState.Soldier: TXcomBattleUnit;
begin
  Result := FBench.Session.Battle.SelectedUnit;
end;

procedure TTestXcomInventoryState.MoveTo(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := Round(AX * FBench.World.Game.Screen.XScale);
  LEvent.Y := Round(AY * FBench.World.Game.Screen.YScale);
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(30);
end;

procedure TTestXcomInventoryState.ClickAt(AX, AY: Integer);
begin
  FBench.World.Click(Round(AX * FBench.World.Game.Screen.XScale), Round(AY * FBench.World.Game.Screen.YScale));
end;

procedure TTestXcomInventoryState.Click(ASurface: TXcomInteractiveSurface);
begin
  ClickAt(ASurface.X + ASurface.Width div 2, ASurface.Y + ASurface.Height div 2);
end;

procedure TTestXcomInventoryState.PressKey(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
  LEvent.Kind := ekKeyUp;
  FBench.World.Events.Enqueue(LEvent);
  FBench.World.Wait(20);
end;

function TTestXcomInventoryState.Carried(AUnit: TXcomBattleUnit): string;
var
  LItem: TXcomBattleItem;
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    for LItem in AUnit.Inventory do
      if (not LItem.Rules.FixedWeapon) and Assigned(LItem.Slot) then
        LLines.Add(Format('%s@%s:%d,%d', [LItem.Rules.ItemType, LItem.Slot.Id, LItem.SlotX, LItem.SlotY]));
    LLines.Sort;
    Result := LLines.CommaText;
  finally
    LLines.Free;
  end;
end;

function TTestXcomInventoryState.Asked(const ACall: string): Integer;
var
  LCall: string;
begin
  Result := 0;
  for LCall in FBench.Screens.Calls do
    if LCall = ACall then
      Inc(Result);
end;

procedure TTestXcomInventoryState.SenzaUnitaDiTempoIPulsantiDelModelloSiVedono;
begin
  if not Open(False) then
    Exit;
  Assert.IsTrue(FInventory.CreateTemplateButton.Visible);
  Assert.IsTrue(FInventory.ApplyTemplateButton.Visible);
  Assert.AreEqual(0, FInventory.TemplateCount);
  // with no template the second button clears the inventory
  Assert.AreEqual('STR_CLEAR_INVENTORY', FInventory.ApplyTemplateButton.Tooltip);
end;

procedure TTestXcomInventoryState.ConLeUnitaDiTempoIPulsantiDelModelloSonoNascosti;
var
  LBefore: string;
begin
  if not Open(True) then
    Exit;
  Assert.IsFalse(FInventory.CreateTemplateButton.Visible);
  Assert.IsFalse(FInventory.ApplyTemplateButton.Visible);
  // and their keys do nothing
  LBefore := Carried(Soldier);
  PressKey(KEY_CREATE);
  PressKey(KEY_CLEAR);
  Assert.AreEqual(0, FInventory.TemplateCount);
  Assert.AreEqual(LBefore, Carried(Soldier));
end;

procedure TTestXcomInventoryState.CreaDovrebbeCopiareLEquipaggiamentoNelModello;
var
  LItem: TXcomBattleItem;
  LExpected: Integer;
begin
  if not Open(False) then
    Exit;
  LExpected := 0;
  for LItem in Soldier.Inventory do
    if not LItem.Rules.FixedWeapon then
      Inc(LExpected);
  Assert.IsTrue(LExpected > 0, 'the soldier of the scenario carries something');
  Click(FInventory.CreateTemplateButton);
  Assert.AreEqual(LExpected, FInventory.TemplateCount);
  Assert.AreEqual('STR_APPLY_INVENTORY_TEMPLATE', FInventory.ApplyTemplateButton.Tooltip);
end;

procedure TTestXcomInventoryState.ApplicaSenzaModelloDovrebbeSvuotareLInventario;
var
  LGroundBefore: Integer;
  LCarried: Integer;
  LItem: TXcomBattleItem;
begin
  if not Open(False) then
    Exit;
  LCarried := 0;
  for LItem in Soldier.Inventory do
    if not LItem.Rules.FixedWeapon then
      Inc(LCarried);
  LGroundBefore := Soldier.Tile.Inventory.Count;
  Click(FInventory.ApplyTemplateButton);
  Assert.AreEqual('', Carried(Soldier));
  Assert.AreEqual(LGroundBefore + LCarried, Soldier.Tile.Inventory.Count);
  for LItem in Soldier.Tile.Inventory do
  begin
    Assert.IsNull(LItem.Owner);
    Assert.AreEqual('STR_GROUND', LItem.Slot.Id);
  end;
  Assert.IsFalse(FInventory.Inventory.WarningVisible, 'an empty template misses nothing');
end;

procedure TTestXcomInventoryState.ApplicaDovrebbeRidareLEquipaggiamentoDelModello;
var
  LBefore: string;
begin
  if not Open(False) then
    Exit;
  LBefore := Carried(Soldier);
  Click(FInventory.CreateTemplateButton);
  PressKey(KEY_CLEAR);
  Assert.AreEqual('', Carried(Soldier));
  Click(FInventory.ApplyTemplateButton);
  Assert.AreEqual(LBefore, Carried(Soldier));
  Assert.IsFalse(FInventory.Inventory.WarningVisible);
end;

procedure TTestXcomInventoryState.ApplicaDovrebbeAvvisareSeMancanoGliOggetti;
var
  LTile: TXcomTile;
  LItem: TXcomBattleItem;
  LLost: TXcomBattleItem;
begin
  if not Open(False) then
    Exit;
  Click(FInventory.CreateTemplateButton);
  PressKey(KEY_CLEAR);
  // one of the items of the template is no longer on the ground
  LTile := Soldier.Tile;
  LLost := nil;
  for LItem in LTile.Inventory do
    if not Assigned(LItem.AmmoItem) or (LItem.AmmoItem = LItem) then
    begin
      LLost := LItem;
      Break;
    end;
  Assert.IsNotNull(LLost);
  LTile.RemoveItem(LLost);
  try
    Click(FInventory.ApplyTemplateButton);
    Assert.IsTrue(FInventory.Inventory.WarningVisible, 'not enough items for the template');
  finally
    // back on the ground: the battle owns it
    LTile.AddItem(LLost, FBench.Ruleset.Inventories.Find('STR_GROUND'));
  end;
end;

procedure TTestXcomInventoryState.IlModelloDovrebbeValereAncheSuUnAltroSoldato;
var
  LFirst: TXcomBattleUnit;
  LSecond: TXcomBattleUnit;
begin
  if not Open(False) then
    Exit;
  LFirst := Soldier;
  Click(FInventory.CreateTemplateButton);
  PressKey(FBench.World.Game.Options.GetValue('keyBattleNextUnit'));
  LSecond := Soldier;
  Assert.IsTrue(LSecond <> LFirst, 'another soldier is on screen');
  Assert.IsTrue(FInventory.TemplateCount > 0, 'the template stays when the soldier changes');
  Click(FInventory.ApplyTemplateButton);
  // the other soldier gets what the ground of its tile has: every item it carries now is one of the template
  Assert.IsTrue(LSecond.Inventory.Count <= FInventory.TemplateCount + 2);
end;

procedure TTestXcomInventoryState.IlTastoSvuotaDovrebbeLasciareTuttoATerra;
begin
  if not Open(False) then
    Exit;
  Assert.AreNotEqual('', Carried(Soldier));
  PressKey(KEY_CLEAR);
  Assert.AreEqual('', Carried(Soldier));
end;

procedure TTestXcomInventoryState.IlTastoDellEquipaggiamentoAutomaticoDovrebbeDareOggetti;
begin
  if not Open(False) then
    Exit;
  PressKey(KEY_CLEAR);
  Assert.AreEqual('', Carried(Soldier));
  PressKey(KEY_AUTOEQUIP);
  Assert.AreNotEqual('', Carried(Soldier), 'the soldier takes a weapon from the ground');
end;

procedure TTestXcomInventoryState.ITastiDelModelloDovrebberoCreareEApplicare;
var
  LBefore: string;
begin
  if not Open(False) then
    Exit;
  LBefore := Carried(Soldier);
  PressKey(KEY_CREATE);
  Assert.IsTrue(FInventory.TemplateCount > 0);
  PressKey(KEY_CLEAR);
  PressKey(KEY_APPLY);
  Assert.AreEqual(LBefore, Carried(Soldier));
end;

procedure TTestXcomInventoryState.ConUnOggettoInManoIPulsantiDelModelloNonFannoNulla;
var
  LSection: TXcomRuleInventory;
  LBefore: string;
begin
  if not Open(False) then
    Exit;
  LSection := FBench.Ruleset.Inventories.Find('STR_RIGHT_HAND');
  Assert.IsNotNull(Soldier.GetItem('STR_RIGHT_HAND'), 'the soldier of the scenario has a weapon in the right hand');
  // the weapon is picked up: it follows the mouse
  ClickAt(LSection.X + 8, LSection.Y + 8);
  Assert.IsNotNull(FInventory.Inventory.SelectedItem);
  LBefore := Carried(Soldier);
  PressKey(KEY_CREATE);
  PressKey(KEY_CLEAR);
  PressKey(KEY_AUTOEQUIP);
  PressKey(KEY_APPLY);
  Assert.AreEqual(0, FInventory.TemplateCount);
  Assert.AreEqual(LBefore, Carried(Soldier));
  // and OK does not close the screen
  PressKey(KEY_ESCAPE);
  Assert.IsTrue(FBench.World.Game.IsState(FInventory));
end;

procedure TTestXcomInventoryState.ILPulsantiSuccessivoEPrecedenteCambianoSoldato;
var
  LFirst: TXcomBattleUnit;
  LName: string;
begin
  if not Open(False) then
    Exit;
  LFirst := Soldier;
  LName := FInventory.NameText;
  PressKey(FBench.World.Game.Options.GetValue('keyBattleNextUnit'));
  Assert.IsTrue(Soldier <> LFirst);
  Assert.AreNotEqual(LName, FInventory.NameText);
  PressKey(FBench.World.Game.Options.GetValue('keyBattlePrevUnit'));
  Assert.IsTrue(Soldier = LFirst);
  Assert.AreEqual(LName, FInventory.NameText);
end;

procedure TTestXcomInventoryState.IlGradoDovrebbeAprireLaSchedaDelSoldato;
begin
  if not Open(False) then
    Exit;
  // the rank in the corner
  ClickAt(8, 8);
  Assert.AreEqual(1, Asked('UnitInfo'));
end;

procedure TTestXcomInventoryState.LOggettoSottoIlMouseDovrebbeEssereDescritto;
var
  LSection: TXcomRuleInventory;
  LItem: TXcomBattleItem;
begin
  if not Open(False) then
    Exit;
  LSection := FBench.Ruleset.Inventories.Find('STR_RIGHT_HAND');
  LItem := Soldier.GetItem('STR_RIGHT_HAND');
  Assert.IsNotNull(LItem);
  MoveTo(LSection.X + 9, LSection.Y + 9);
  MoveTo(LSection.X + 8, LSection.Y + 8);
  Assert.IsTrue(FInventory.Inventory.MouseOverItem = LItem, 'the item under the mouse');
  Assert.AreEqual(FState.Tr(LItem.Rules.Name).Text, FInventory.ItemText);
  if LItem.NeedsAmmo and Assigned(LItem.AmmoItem) then
    Assert.AreNotEqual('', FInventory.AmmoText, 'the rounds left');
  // away from every item the texts go
  MoveTo(200, 30);
  Assert.AreEqual('', FInventory.ItemText);
  Assert.AreEqual('', FInventory.AmmoText);
end;

procedure TTestXcomInventoryState.ScaricaDovrebbeTogliereIlCaricatoreDallArmaInMano;
var
  LSection: TXcomRuleInventory;
  LWeapon: TXcomBattleItem;
  LLeft: TXcomBattleItem;
begin
  if not Open(False) then
    Exit;
  LWeapon := Soldier.GetItem('STR_RIGHT_HAND');
  Assert.IsNotNull(LWeapon);
  if (not LWeapon.NeedsAmmo) or (not Assigned(LWeapon.AmmoItem)) then
  begin
    Assert.Pass('the weapon of the soldier has no clip to unload');
    Exit;
  end;
  // the other hand must be free: what it holds goes to the ground
  LLeft := Soldier.GetItem('STR_LEFT_HAND');
  if Assigned(LLeft) and (not LLeft.Rules.FixedWeapon) then
  begin
    LSection := FBench.Ruleset.Inventories.Find('STR_LEFT_HAND');
    ClickAt(LSection.X + 8, LSection.Y + 8);
    LSection := FBench.Ruleset.Inventories.Find('STR_GROUND');
    ClickAt(LSection.X + 150, LSection.Y + 20);
  end;
  if Assigned(Soldier.GetItem('STR_LEFT_HAND')) then
  begin
    Assert.Pass('the left hand of the soldier cannot be emptied');
    Exit;
  end;
  LSection := FBench.Ruleset.Inventories.Find('STR_RIGHT_HAND');
  ClickAt(LSection.X + 8, LSection.Y + 8);
  Assert.IsNotNull(FInventory.Inventory.SelectedItem);
  // the unload button, on the right of the screen
  ClickAt(288 + 16, 32 + 12);
  Assert.IsNull(LWeapon.AmmoItem, 'the clip left the weapon');
  Assert.IsNotNull(Soldier.GetItem('STR_LEFT_HAND'), 'the clip is in the other hand');
end;

procedure TTestXcomInventoryState.OkSenzaUnitaDiTempoDovrebbeSalvareLEquipaggiamentoEChiudere;
var
  LSoldier: TXcomSoldier;
  LUnit: TXcomBattleUnit;
  LCarried: Integer;
  LItem: TXcomBattleItem;
begin
  if not Open(False) then
    Exit;
  LUnit := Soldier;
  LSoldier := LUnit.GeoscapeSoldier;
  Assert.IsNotNull(LSoldier);
  LCarried := 0;
  for LItem in LUnit.Inventory do
    if Assigned(LItem.Slot) then
      Inc(LCarried);
  LSoldier.EquipmentLayout.Clear;
  PressKey(KEY_ESCAPE);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
  Assert.AreEqual(LCarried, LSoldier.EquipmentLayout.Count, 'the layout of the soldier is what it carries');
  FInventory := nil;
end;

procedure TTestXcomInventoryState.OkConLeUnitaDiTempoDovrebbeSoloChiudere;
var
  LSoldier: TXcomSoldier;
begin
  if not Open(True) then
    Exit;
  LSoldier := Soldier.GeoscapeSoldier;
  LSoldier.EquipmentLayout.Clear;
  Assert.AreNotEqual('', FInventory.TimeUnitsText);
  PressKey(KEY_ESCAPE);
  Assert.IsTrue(FBench.World.Game.IsState(FState));
  Assert.AreEqual(0, LSoldier.EquipmentLayout.Count, 'in battle the layout is not saved');
  FInventory := nil;
end;

procedure TTestXcomInventoryState.ISuggerimentiDeiPulsantiDovrebberoApparireEsparire;
begin
  if not Open(False) then
    Exit;
  FBench.World.Game.Options.SetValue('battleTooltips', 1);
  MoveTo(FInventory.CreateTemplateButton.X + 5, FInventory.CreateTemplateButton.Y + 5);
  Assert.AreEqual(FState.Tr('STR_CREATE_INVENTORY_TEMPLATE').Text, FInventory.ItemText);
  MoveTo(FInventory.ApplyTemplateButton.X + 5, FInventory.ApplyTemplateButton.Y + 5);
  Assert.AreEqual(FState.Tr('STR_CLEAR_INVENTORY').Text, FInventory.ItemText);
  MoveTo(200, 30);
  Assert.AreEqual('', FInventory.ItemText);
end;

end.
