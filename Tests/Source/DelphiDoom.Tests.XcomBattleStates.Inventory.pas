{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the view of the inventory of the battlescape            }
{  (Inventory) with hand made rules and fake pictures                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.Inventory;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Xcom.Types,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.Clock.ManualClock,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.RulesetSettings, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf,
  DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattleStates.Graphics.Intf,
  DelphiDoom.XcomBattleStates.Inventory;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomInventory = class
  strict private
    FClock: TManualClock;
    FClockRef: IClock;
    FGraphics: IXcomBattleGraphics;
    FContext: IXcomBattleContext;
    FOffsets: TXcomModOffsets;
    FArmors: TObjectList<TXcomArmor>;
    FUnitRules: TObjectList<TXcomRuleUnit>;
    FRules: TObjectList<TXcomRuleItem>;
    FSections: TObjectList<TXcomRuleInventory>;
    FItems: TObjectList<TXcomBattleItem>;
    FUnit: TXcomBattleUnit;
    FTile: TXcomTile;
    FInventory: TXcomInventory;
    FGround, FRightHand, FLeftHand, FBelt, FBackPack: TXcomRuleInventory;
    FRifle, FClip, FOtherClip, FGrenade, FProximity, FFlare: TXcomRuleItem;
    FNextId: Integer;
    FSounds: TList<TXcomInventorySound>;
    FClosed: Integer;
    FPrimed: TXcomBattleItem;
    function Yaml(const AText: string): IYamlNode;
    function MakeSection(const AText: string): TXcomRuleInventory;
    function MakeRules(const AText: string): TXcomRuleItem;
    function Carried(const ARules: TXcomRuleItem; const ASlot: TXcomRuleInventory; AX: Integer = 0;
      AY: Integer = 0): TXcomBattleItem;
    function OnGround(const ARules: TXcomRuleItem): TXcomBattleItem;
    procedure PickUp(const AItem: TXcomBattleItem);
    procedure DropAt(const ASlot: TXcomRuleInventory; AX, AY: Integer);
    function TestColors: TXcomColors;
    function NewTarget: TXcomSurface;
    procedure ClickCell(const ASlot: TXcomRuleInventory; AX, AY, AButton: Integer; AControl: Boolean = False);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePrendereInManoLOggettoCliccato;
    [Test]
    procedure DovrebbeSpostareDallaCinturaAlloZainoSpendendoITu;
    [Test]
    procedure DovrebbeAvvisareETenereLOggettoSeMancanoITu;
    [Test]
    procedure DovrebbeSpostareGratisSenzaModalitaTu;
    [Test]
    procedure DovrebbeRifiutareUnoSlotOccupato;
    [Test]
    procedure DovrebbeRifiutareUnOggettoCheEsceDallaSezione;
    [Test]
    procedure DovrebbeCaricareLArmaTrascinandoIlCaricatore;
    [Test]
    procedure DovrebbeAvvisareSeIlCaricatoreESbagliato;
    [Test]
    procedure DovrebbeAvvisareSeLArmaEGiaCarica;
    [Test]
    procedure DovrebbeScaricareLArmaNelleDueMani;
    [Test]
    procedure DovrebbeVolereLeManiVuotePerScaricare;
    [Test]
    procedure DovrebbeAvvisareSeLArmaDaScaricareEVuota;
    [Test]
    procedure DovrebbeImpilareATerraGliOggettiUguali;
    [Test]
    procedure DovrebbeLasciareATerraSopraUnOggettoUguale;
    [Test]
    procedure DovrebbeNonImpilareGranateInnescateOCaricatoriDiversi;
    [Test]
    procedure DovrebbeRaccogliereDaTerraConCtrlNellaManoDestra;
    [Test]
    procedure DovrebbeLasciareATerraConCtrl;
    [Test]
    procedure DovrebbeRimettereAlPostoLOggettoColTastoDestro;
    [Test]
    procedure DovrebbeChiudereColTastoDestroInBattaglia;
    [Test]
    procedure DovrebbeInnescareLeGranateColTastoDestroSenzaTu;
    [Test]
    procedure DovrebbeScorrereIlTerrenoAPagine;
    [Test]
    procedure DovrebbeDisegnareGrigliaOggettiENumeroDellaPila;
    [Test]
    procedure DovrebbeFarPulsareLaGranataInnescata;
    [Test]
    procedure DovrebbeDireLOggettoSottoIlMouse;
  end;

implementation

uses
  DelphiDoom.XcomBattlescape.Sprites.Intf;

const
  GRID_COLOR = 5;
  STACK_COLOR = 82;
  START_TU = 50;
  PRIMER_COLOR = 33;

type
  TFixedRandom = class(TInterfacedObject, IXcomRandom)
  public
    function Generate(AMin, AMax: Integer): Integer; overload;
    function Generate(AMin, AMax: Double): Double; overload;
    function Seed: UInt64;
    procedure SetSeed(AValue: UInt64);
  end;

  TFakeShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  /// <summary>BIGOBS.PCK with a frame per item with a square of the color 100 + index at its top left, SCANG.DAT with the frame 6</summary>
  TFakeGraphics = class(TInterfacedObject, IXcomBattleGraphics)
  strict private
    FBigObs: TXcomSurfaceSet;
    FScanner: TXcomSurfaceSet;
  public
    constructor Create;
    destructor Destroy; override;
    function Sprites: IXcomBattleSprites;
    function SurfaceSet(const AName: string): TXcomSurfaceSet;
    function Surface(const AName: string): TXcomSurface;
    function Palette(ADepth: Integer): PXcomColor;
    function Transparencies(ADepth: Integer): TBytes;
    procedure SetPalette(AColors: PXcomColor);
    function VoxelData: TArray<Word>;
  end;

{ TFixedRandom }

function TFixedRandom.Generate(AMin, AMax: Integer): Integer;
begin
  Result := AMin;
end;

function TFixedRandom.Generate(AMin, AMax: Double): Double;
begin
  Result := AMin;
end;

function TFixedRandom.Seed: UInt64;
begin
  Result := 0;
end;

procedure TFixedRandom.SetSeed(AValue: UInt64);
begin
end;

{ TFakeShared }

function TFakeShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TFakeShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 30;
end;

{ TFakeGraphics }

constructor TFakeGraphics.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  FBigObs := TXcomSurfaceSet.Create(32, 48);
  for LIndex := 0 to 7 do
    FBigObs.AddFrame(LIndex).DrawRect(0, 0, 12, 12, Byte(100 + LIndex));
  FScanner := TXcomSurfaceSet.Create(4, 4);
  FScanner.AddFrame(6).DrawRect(0, 0, 4, 4, PRIMER_COLOR);
end;

destructor TFakeGraphics.Destroy;
begin
  FScanner.Free;
  FBigObs.Free;
  inherited Destroy;
end;

function TFakeGraphics.Sprites: IXcomBattleSprites;
begin
  Result := nil;
end;

function TFakeGraphics.SurfaceSet(const AName: string): TXcomSurfaceSet;
begin
  if AName = 'BIGOBS.PCK' then
    Result := FBigObs
  else if AName = 'SCANG.DAT' then
    Result := FScanner
  else
    Result := nil;
end;

function TFakeGraphics.Surface(const AName: string): TXcomSurface;
begin
  Result := nil;
end;

function TFakeGraphics.Palette(ADepth: Integer): PXcomColor;
begin
  Result := nil;
end;

function TFakeGraphics.Transparencies(ADepth: Integer): TBytes;
begin
  Result := nil;
end;

procedure TFakeGraphics.SetPalette(AColors: PXcomColor);
begin
end;

function TFakeGraphics.VoxelData: TArray<Word>;
begin
  Result := nil;
end;

{ TTestXcomInventory }

function TTestXcomInventory.Yaml(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

function TTestXcomInventory.MakeSection(const AText: string): TXcomRuleInventory;
var
  LNode: IYamlNode;
begin
  LNode := Yaml(AText);
  Result := TXcomRuleInventory.Create(YamlTextToString(LNode.Find(YamlStringToText('id')).AsString));
  Result.Load(LNode, 1);
  FSections.Add(Result);
end;

function TTestXcomInventory.MakeRules(const AText: string): TXcomRuleItem;
var
  LNode: IYamlNode;
begin
  LNode := Yaml(AText);
  Result := TXcomRuleItem.Create(YamlTextToString(LNode.Find(YamlStringToText('type')).AsString));
  Result.Load(LNode, FOffsets, 1);
  FRules.Add(Result);
end;

function TTestXcomInventory.Carried(const ARules: TXcomRuleItem; const ASlot: TXcomRuleInventory; AX,
  AY: Integer): TXcomBattleItem;
begin
  Result := TXcomBattleItem.Create(ARules, FNextId);
  FItems.Add(Result);
  Result.MoveToOwner(FUnit);
  Result.Slot := ASlot;
  Result.SlotX := AX;
  Result.SlotY := AY;
end;

function TTestXcomInventory.OnGround(const ARules: TXcomRuleItem): TXcomBattleItem;
begin
  Result := TXcomBattleItem.Create(ARules, FNextId);
  FItems.Add(Result);
  FTile.AddItem(Result, FGround);
end;

procedure TTestXcomInventory.ClickCell(const ASlot: TXcomRuleInventory; AX, AY, AButton: Integer; AControl: Boolean);
var
  LX, LY: Integer;
begin
  LX := ASlot.X + AX * INV_SLOT_WIDTH + 2;
  LY := ASlot.Y + AY * INV_SLOT_HEIGHT + 2;
  FInventory.Hover(LX, LY);
  FInventory.Click(LX, LY, AButton, AControl);
end;

procedure TTestXcomInventory.PickUp(const AItem: TXcomBattleItem);
begin
  if AItem.Slot.InventoryType = INV_HAND then
    ClickCell(AItem.Slot, 0, 0, XCOM_BUTTON_LEFT)
  else
    ClickCell(AItem.Slot, AItem.SlotX - FInventory.GroundOffset * Ord(AItem.Slot.InventoryType = INV_GROUND),
      AItem.SlotY, XCOM_BUTTON_LEFT);
  Assert.AreSame(AItem, FInventory.SelectedItem, 'the item is not in the hand of the player');
end;

procedure TTestXcomInventory.DropAt(const ASlot: TXcomRuleInventory; AX, AY: Integer);
var
  LRules: TXcomRuleItem;
  LX, LY: Integer;
begin
  // the slot is chosen by the middle of the top left cell of the picture, which is centered on the mouse
  LRules := FInventory.SelectedItem.Rules;
  LX := ASlot.X + AX * INV_SLOT_WIDTH + 8 - ((INV_HAND_WIDTH - LRules.InventoryWidth) * INV_SLOT_WIDTH div 2 + 8) + 16;
  LY := ASlot.Y + AY * INV_SLOT_HEIGHT + 8 - ((INV_HAND_HEIGHT - LRules.InventoryHeight) * INV_SLOT_HEIGHT div 2 + 8) +
    24;
  FInventory.Hover(LX, LY);
  FInventory.Click(LX, LY, XCOM_BUTTON_LEFT);
end;

function TTestXcomInventory.TestColors: TXcomColors;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
  begin
    Result[LIndex].Red := Byte(LIndex);
    Result[LIndex].Green := Byte(255 - LIndex);
    Result[LIndex].Blue := Byte(LIndex * 7);
    Result[LIndex].Alpha := 255;
  end;
end;

function TTestXcomInventory.NewTarget: TXcomSurface;
begin
  Result := TXcomSurface.Create(320, 200);
  Result.SetColors(TestColors);
end;

procedure TTestXcomInventory.Setup;
const
  COSTS = 'costs: {STR_GROUND: 2, STR_RIGHT_HAND: 4, STR_LEFT_HAND: 4, STR_BELT: 8, STR_BACK_PACK: 14}';
var
  LArmor: TXcomArmor;
  LUnitRules: TXcomRuleUnit;
  LAdjustment: TXcomStatAdjustment;
  LStyle: TXcomInventoryStyle;
  LColors: TXcomColors;
begin
  FNextId := 1;
  FClock := TManualClock.Create;
  FClockRef := FClock;
  FGraphics := TFakeGraphics.Create;
  FContext := TXcomBattleContext.Create(TFixedRandom.Create);
  FOffsets := TXcomModOffsets.Create([TXcomModData.Make('master', 0, 1000)], 0, TFakeShared.Create);
  FArmors := TObjectList<TXcomArmor>.Create(True);
  FUnitRules := TObjectList<TXcomRuleUnit>.Create(True);
  FRules := TObjectList<TXcomRuleItem>.Create(True);
  FSections := TObjectList<TXcomRuleInventory>.Create(True);
  FItems := TObjectList<TXcomBattleItem>.Create(True);
  FSounds := TList<TXcomInventorySound>.Create;
  // in the order of the ids, as the std::map of the rules
  FBackPack := MakeSection('{id: STR_BACK_PACK, type: 0, x: 192, y: 40, slots: [[0, 0], [1, 0], [2, 0], [0, 1], ' +
    '[1, 1], [2, 1], [0, 2], [1, 2], [2, 2]], ' + COSTS + '}');
  FBelt := MakeSection('{id: STR_BELT, type: 0, x: 192, y: 104, slots: [[0, 0], [1, 0], [2, 0], [3, 0], [0, 1], ' +
    '[3, 1]], ' + COSTS + '}');
  FGround := MakeSection('{id: STR_GROUND, type: 2, x: 0, y: 152, ' + COSTS + '}');
  FLeftHand := MakeSection('{id: STR_LEFT_HAND, type: 1, x: 128, y: 64, ' + COSTS + '}');
  FRightHand := MakeSection('{id: STR_RIGHT_HAND, type: 1, x: 0, y: 64, ' + COSTS + '}');
  FRifle := MakeRules('{type: STR_RIFLE, battleType: 1, clipSize: -1, compatibleAmmo: [STR_CLIP], invWidth: 1, ' +
    'invHeight: 3, bigSprite: 1}');
  FClip := MakeRules('{type: STR_CLIP, battleType: 2, clipSize: 20, invWidth: 1, invHeight: 1, bigSprite: 2}');
  FOtherClip := MakeRules('{type: STR_OTHER_CLIP, battleType: 2, clipSize: 8, invWidth: 1, invHeight: 1, ' +
    'bigSprite: 3}');
  FGrenade := MakeRules('{type: STR_GRENADE, battleType: 4, invWidth: 1, invHeight: 1, bigSprite: 4}');
  FProximity := MakeRules('{type: STR_PROXIMITY, battleType: 5, invWidth: 1, invHeight: 1, bigSprite: 5}');
  FFlare := MakeRules('{type: STR_FLARE, battleType: 10, invWidth: 2, invHeight: 1, bigSprite: 6}');
  LArmor := TXcomArmor.Create('STR_TEST_ARMOR');
  FArmors.Add(LArmor);
  LArmor.Load(Yaml('{type: A, frontArmor: 20, sideArmor: 15, rearArmor: 10, underArmor: 5, size: 1, weight: 10, ' +
    'deathFrames: 3, loftempsSet: [1], damageModifier: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, ' +
    '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], stats: {tu: 0}}'));
  LUnitRules := TXcomRuleUnit.Create('STR_TEST_UNIT');
  FUnitRules.Add(LUnitRules);
  LUnitRules.Load(Yaml('{type: U, race: STR_RACE, rank: STR_LIVE_SOLDIER, standHeight: 22, kneelHeight: 14, ' +
    'floatHeight: 0, value: 5, energyRecovery: 12, stats: {tu: 50, stamina: 60, health: 40, bravery: 30, ' +
    'reactions: 55, firing: 60, throwing: 50, strength: 30, psiStrength: 0, psiSkill: 0, melee: 40}}'), FOffsets);
  FillChar(LAdjustment, SizeOf(LAdjustment), 0);
  LAdjustment.AimAndArmorMultiplier := 1.0;
  FUnit := TXcomBattleUnit.Create(FContext, LUnitRules, FACTION_PLAYER, 1, LArmor, LAdjustment, 0);
  FUnit.SetTimeUnits(START_TU);
  FTile := TXcomTile.Create(TXcomPosition.Make(3, 4, 0), FContext);
  FUnit.SetTile(FTile);
  FillChar(LStyle, SizeOf(LStyle), 0);
  LStyle.GridColor := GRID_COLOR;
  LStyle.StackColor := STACK_COLOR;
  FInventory := TXcomInventory.Create(FClockRef, FSections.ToArray, FGraphics,
    function(AId: string): string
    begin
      Result := AId;
    end, LStyle, 320, 200);
  // 256 different colors: a blit between layers must find every index again
  LColors := TestColors;
  FInventory.SetPalette(@LColors[0], 0, 256);
  FInventory.OnSound :=
    procedure(ASound: TXcomInventorySound)
    begin
      FSounds.Add(ASound);
    end;
  FInventory.OnClose :=
    procedure
    begin
      Inc(FClosed);
    end;
  FInventory.OnPrimeGrenade :=
    procedure(AItem: TXcomBattleItem)
    begin
      FPrimed := AItem;
    end;
  FClosed := 0;
  FPrimed := nil;
end;

procedure TTestXcomInventory.TearDown;
begin
  FInventory.Free;
  FUnit.Free;
  FTile.Free;
  FItems.Free;
  FSounds.Free;
  FSections.Free;
  FRules.Free;
  FUnitRules.Free;
  FArmors.Free;
  FOffsets.Free;
  FContext := nil;
  FGraphics := nil;
  FClockRef := nil;
end;

procedure TTestXcomInventory.DovrebbePrendereInManoLOggettoCliccato;
var
  LClip: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 1, 0);
  FInventory.SetSelectedUnit(FUnit);
  ClickCell(FBelt, 0, 0, XCOM_BUTTON_LEFT);
  Assert.IsNull(FInventory.SelectedItem);
  ClickCell(FBelt, 1, 0, XCOM_BUTTON_LEFT);
  Assert.AreSame(LClip, FInventory.SelectedItem);
  Assert.AreEqual(START_TU, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeSpostareDallaCinturaAlloZainoSpendendoITu;
var
  LClip: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 1, 0);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LClip);
  DropAt(FBackPack, 2, 1);
  Assert.IsNull(FInventory.SelectedItem);
  Assert.AreSame(FBackPack, LClip.Slot);
  Assert.AreEqual(2, LClip.SlotX);
  Assert.AreEqual(1, LClip.SlotY);
  Assert.AreEqual(START_TU - 14, FUnit.TimeUnits);
  Assert.AreEqual(1, FSounds.Count);
  Assert.AreEqual(Ord(isDrop), Ord(FSounds[0]));
  // moving inside the same section is free
  PickUp(LClip);
  DropAt(FBackPack, 0, 0);
  Assert.AreEqual(0, LClip.SlotX);
  Assert.AreEqual(START_TU - 14, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeAvvisareETenereLOggettoSeMancanoITu;
var
  LClip: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 1, 0);
  FInventory.SetSelectedUnit(FUnit);
  FUnit.SetTimeUnits(13);
  PickUp(LClip);
  DropAt(FBackPack, 0, 0);
  Assert.AreSame(LClip, FInventory.SelectedItem);
  Assert.AreSame(FBelt, LClip.Slot);
  Assert.AreEqual(13, FUnit.TimeUnits);
  Assert.IsTrue(FInventory.WarningVisible);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FInventory.WarningText);
  Assert.AreEqual(0, FSounds.Count);
end;

procedure TTestXcomInventory.DovrebbeSpostareGratisSenzaModalitaTu;
var
  LClip: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 1, 0);
  FInventory.SetTuMode(False);
  FInventory.SetSelectedUnit(FUnit);
  FUnit.SetTimeUnits(0);
  PickUp(LClip);
  DropAt(FLeftHand, 0, 0);
  Assert.AreSame(FLeftHand, LClip.Slot);
  Assert.AreEqual(0, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeRifiutareUnoSlotOccupato;
var
  LClip, LGrenade: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 1, 0);
  LGrenade := Carried(FGrenade, FBelt, 2, 0);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LClip);
  DropAt(FBelt, 2, 0);
  Assert.AreSame(LClip, FInventory.SelectedItem);
  Assert.AreEqual(1, LClip.SlotX);
  Assert.AreEqual(2, LGrenade.SlotX);
  Assert.AreEqual(START_TU, FUnit.TimeUnits);
  Assert.IsFalse(FInventory.WarningVisible);
end;

procedure TTestXcomInventory.DovrebbeRifiutareUnOggettoCheEsceDallaSezione;
var
  LFlare, LRifle: TXcomBattleItem;
begin
  LFlare := Carried(FFlare, FBackPack, 0, 0);
  LRifle := Carried(FRifle, FRightHand);
  FInventory.SetSelectedUnit(FUnit);
  // two cells wide: the last column of the belt has no cell at its right
  PickUp(LFlare);
  DropAt(FBelt, 3, 0);
  Assert.AreSame(LFlare, FInventory.SelectedItem);
  // the cell under it does not exist in the belt
  DropAt(FBelt, 1, 1);
  Assert.AreSame(LFlare, FInventory.SelectedItem);
  DropAt(FBelt, 1, 0);
  Assert.IsNull(FInventory.SelectedItem);
  Assert.AreSame(FBelt, LFlare.Slot);
  // three cells tall: only the first row of the back pack takes it
  PickUp(LRifle);
  DropAt(FBackPack, 2, 1);
  Assert.AreSame(LRifle, FInventory.SelectedItem);
  DropAt(FBackPack, 2, 0);
  Assert.AreSame(FBackPack, LRifle.Slot);
end;

procedure TTestXcomInventory.DovrebbeCaricareLArmaTrascinandoIlCaricatore;
var
  LRifle, LClip: TXcomBattleItem;
begin
  LRifle := Carried(FRifle, FRightHand);
  LClip := Carried(FClip, FBelt, 0, 0);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LClip);
  DropAt(FRightHand, 0, 0);
  Assert.IsNull(FInventory.SelectedItem);
  Assert.AreSame(LClip, LRifle.AmmoItem);
  Assert.IsNull(LClip.Owner);
  Assert.AreEqual(1, FUnit.Inventory.Count);
  Assert.AreEqual(START_TU - 15, FUnit.TimeUnits);
  Assert.AreEqual(Ord(isReload), Ord(FSounds.Last));
end;

procedure TTestXcomInventory.DovrebbeAvvisareSeIlCaricatoreESbagliato;
var
  LRifle, LClip: TXcomBattleItem;
begin
  LRifle := Carried(FRifle, FRightHand);
  LClip := Carried(FOtherClip, FBelt, 0, 0);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LClip);
  DropAt(FRightHand, 0, 0);
  Assert.AreSame(LClip, FInventory.SelectedItem);
  Assert.IsNull(LRifle.AmmoItem);
  Assert.AreEqual('STR_WRONG_AMMUNITION_FOR_THIS_WEAPON', FInventory.WarningText);
  Assert.AreEqual(START_TU, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeAvvisareSeLArmaEGiaCarica;
var
  LRifle, LLoaded, LClip: TXcomBattleItem;
begin
  LRifle := Carried(FRifle, FRightHand);
  LLoaded := TXcomBattleItem.Create(FClip, FNextId);
  FItems.Add(LLoaded);
  LRifle.SetAmmoItem(LLoaded);
  LClip := Carried(FClip, FBelt, 0, 0);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LClip);
  DropAt(FRightHand, 0, 0);
  Assert.AreSame(LClip, FInventory.SelectedItem);
  Assert.AreSame(LLoaded, LRifle.AmmoItem);
  Assert.AreEqual('STR_WEAPON_IS_ALREADY_LOADED', FInventory.WarningText);
  // with too few time units the clip stays in the hand of the player
  LRifle.SetAmmoItem(nil);
  FUnit.SetTimeUnits(14);
  DropAt(FRightHand, 0, 0);
  Assert.IsNull(LRifle.AmmoItem);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FInventory.WarningText);
end;

procedure TTestXcomInventory.DovrebbeScaricareLArmaNelleDueMani;
var
  LRifle, LLoaded: TXcomBattleItem;
begin
  LRifle := Carried(FRifle, FBackPack, 0, 0);
  LLoaded := TXcomBattleItem.Create(FClip, FNextId);
  FItems.Add(LLoaded);
  LLoaded.Slot := FBelt;
  LRifle.SetAmmoItem(LLoaded);
  FInventory.SetSelectedUnit(FUnit);
  Assert.IsFalse(FInventory.Unload, 'nothing in the hand of the player');
  PickUp(LRifle);
  Assert.IsTrue(FInventory.Unload);
  Assert.IsNull(FInventory.SelectedItem);
  Assert.IsNull(LRifle.AmmoItem);
  Assert.AreSame(FRightHand, LRifle.Slot);
  Assert.AreSame(FLeftHand, LLoaded.Slot);
  Assert.AreSame(FUnit, LLoaded.Owner);
  Assert.AreEqual(2, FUnit.Inventory.Count);
  Assert.AreEqual(START_TU - 8, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeVolereLeManiVuotePerScaricare;
var
  LRifle, LLoaded: TXcomBattleItem;
begin
  LRifle := Carried(FRifle, FBackPack, 0, 0);
  Carried(FGrenade, FLeftHand);
  LLoaded := TXcomBattleItem.Create(FClip, FNextId);
  FItems.Add(LLoaded);
  LRifle.SetAmmoItem(LLoaded);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LRifle);
  Assert.IsFalse(FInventory.Unload);
  Assert.AreEqual('STR_BOTH_HANDS_MUST_BE_EMPTY', FInventory.WarningText);
  Assert.AreSame(LLoaded, LRifle.AmmoItem);
  Assert.AreEqual(START_TU, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeAvvisareSeLArmaDaScaricareEVuota;
var
  LRifle: TXcomBattleItem;
begin
  LRifle := Carried(FRifle, FRightHand);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LRifle);
  Assert.IsFalse(FInventory.Unload);
  Assert.AreEqual('STR_NO_AMMUNITION_LOADED', FInventory.WarningText);
end;

procedure TTestXcomInventory.DovrebbeImpilareATerraGliOggettiUguali;
var
  LFirst, LSecond, LGrenade, LRifle: TXcomBattleItem;
begin
  LFirst := OnGround(FClip);
  LRifle := OnGround(FRifle);
  LSecond := OnGround(FClip);
  LGrenade := OnGround(FGrenade);
  FInventory.SetSelectedUnit(FUnit);
  Assert.AreEqual(0, LFirst.SlotX);
  Assert.AreEqual(0, LFirst.SlotY);
  Assert.AreEqual(0, LSecond.SlotX);
  Assert.AreEqual(0, LSecond.SlotY);
  Assert.AreEqual(2, FInventory.StackLevel(0, 0));
  // the rifle is three cells tall: the column of the clips has no room for it
  Assert.AreEqual(1, LRifle.SlotX);
  Assert.AreEqual(0, LRifle.SlotY);
  Assert.AreEqual(0, LGrenade.SlotX);
  Assert.AreEqual(1, LGrenade.SlotY);
  Assert.AreEqual(1, FInventory.StackLevel(0, 1));
  // taking one from the pile lowers it
  PickUp(LFirst);
  Assert.AreEqual(1, FInventory.StackLevel(0, 0));
  FInventory.Click(0, 0, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(2, FInventory.StackLevel(0, 0));
end;

procedure TTestXcomInventory.DovrebbeLasciareATerraSopraUnOggettoUguale;
var
  LGround, LCarried: TXcomBattleItem;
begin
  LGround := OnGround(FClip);
  LCarried := Carried(FClip, FBelt, 0, 0);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LCarried);
  DropAt(FGround, 0, 0);
  Assert.IsNull(FInventory.SelectedItem);
  Assert.AreSame(FGround, LCarried.Slot);
  Assert.AreEqual(LGround.SlotX, LCarried.SlotX);
  Assert.AreEqual(LGround.SlotY, LCarried.SlotY);
  Assert.AreEqual(2, FInventory.StackLevel(0, 0));
  Assert.AreEqual(2, FTile.Inventory.Count);
  Assert.AreEqual(0, FUnit.Inventory.Count);
  Assert.IsNull(LCarried.Owner);
  Assert.AreSame(FTile, LCarried.Tile);
  Assert.AreEqual(START_TU - 2, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeNonImpilareGranateInnescateOCaricatoriDiversi;
var
  LFirst, LSecond, LClip, LOther: TXcomBattleItem;
begin
  LFirst := OnGround(FGrenade);
  LSecond := OnGround(FGrenade);
  LClip := OnGround(FClip);
  LOther := OnGround(FOtherClip);
  Assert.IsTrue(TXcomInventory.CanBeStacked(LFirst, LSecond));
  Assert.IsFalse(TXcomInventory.CanBeStacked(LFirst, nil));
  Assert.IsFalse(TXcomInventory.CanBeStacked(LClip, LOther));
  LSecond.FuseTimer := 0;
  Assert.IsFalse(TXcomInventory.CanBeStacked(LFirst, LSecond));
  FInventory.SetSelectedUnit(FUnit);
  Assert.AreEqual(1, FInventory.StackLevel(LFirst.SlotX, LFirst.SlotY));
  Assert.IsTrue((LFirst.SlotX <> LSecond.SlotX) or (LFirst.SlotY <> LSecond.SlotY));
end;

procedure TTestXcomInventory.DovrebbeRaccogliereDaTerraConCtrlNellaManoDestra;
var
  LRifle, LSecond, LClip: TXcomBattleItem;
begin
  LRifle := OnGround(FRifle);
  LSecond := OnGround(FRifle);
  LClip := OnGround(FOtherClip);
  FInventory.SetSelectedUnit(FUnit);
  // the two rifles are one pile
  ClickCell(FGround, 0, 0, XCOM_BUTTON_LEFT, True);
  Assert.AreSame(FRightHand, LRifle.Slot);
  Assert.AreSame(FUnit, LRifle.Owner);
  Assert.AreEqual(START_TU - 4, FUnit.TimeUnits);
  Assert.AreEqual(1, FInventory.StackLevel(0, 0));
  // the right hand is taken: the second one goes to the first free place of the other sections
  ClickCell(FGround, 0, 0, XCOM_BUTTON_LEFT, True);
  Assert.AreSame(FBackPack, LSecond.Slot);
  Assert.AreEqual(START_TU - 4 - 14, FUnit.TimeUnits);
  // a small item goes to the belt
  ClickCell(FGround, LClip.SlotX, LClip.SlotY, XCOM_BUTTON_LEFT, True);
  Assert.AreSame(FBelt, LClip.Slot);
  Assert.AreEqual(0, FTile.Inventory.Count);
end;

procedure TTestXcomInventory.DovrebbeLasciareATerraConCtrl;
var
  LClip: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 3, 1);
  FInventory.SetSelectedUnit(FUnit);
  FUnit.SetTimeUnits(1);
  ClickCell(FBelt, 3, 1, XCOM_BUTTON_LEFT, True);
  Assert.AreSame(FBelt, LClip.Slot);
  Assert.AreEqual('STR_NOT_ENOUGH_TIME_UNITS', FInventory.WarningText);
  FUnit.SetTimeUnits(2);
  ClickCell(FBelt, 3, 1, XCOM_BUTTON_LEFT, True);
  Assert.AreSame(FGround, LClip.Slot);
  Assert.AreEqual(0, LClip.SlotX);
  Assert.AreEqual(1, FTile.Inventory.Count);
  Assert.AreEqual(1, FInventory.StackLevel(0, 0));
  Assert.AreEqual(0, FUnit.TimeUnits);
end;

procedure TTestXcomInventory.DovrebbeRimettereAlPostoLOggettoColTastoDestro;
var
  LClip: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 1, 0);
  FInventory.SetSelectedUnit(FUnit);
  PickUp(LClip);
  FInventory.Click(100, 100, XCOM_BUTTON_RIGHT);
  Assert.IsNull(FInventory.SelectedItem);
  Assert.AreSame(FBelt, LClip.Slot);
  Assert.AreEqual(0, FClosed);
end;

procedure TTestXcomInventory.DovrebbeChiudereColTastoDestroInBattaglia;
begin
  FInventory.SetSelectedUnit(FUnit);
  FInventory.Click(100, 100, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(1, FClosed);
end;

procedure TTestXcomInventory.DovrebbeInnescareLeGranateColTastoDestroSenzaTu;
var
  LGrenade, LProximity: TXcomBattleItem;
begin
  LGrenade := Carried(FGrenade, FBelt, 0, 0);
  LProximity := Carried(FProximity, FBelt, 1, 0);
  FInventory.SetTuMode(False);
  FInventory.SetSelectedUnit(FUnit);
  ClickCell(FBelt, 1, 0, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(0, LProximity.FuseTimer);
  Assert.AreEqual('STR_GRENADE_IS_ACTIVATED', FInventory.WarningText);
  ClickCell(FBelt, 1, 0, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(-1, LProximity.FuseTimer);
  Assert.AreEqual('STR_GRENADE_IS_DEACTIVATED', FInventory.WarningText);
  // a grenade with a timer asks for the turns
  ClickCell(FBelt, 0, 0, XCOM_BUTTON_RIGHT);
  Assert.AreSame(LGrenade, FPrimed);
  Assert.AreEqual(-1, LGrenade.FuseTimer);
  Assert.AreEqual(0, FClosed);
end;

procedure TTestXcomInventory.DovrebbeScorrereIlTerrenoAPagine;
var
  LIndex: Integer;
  LLast: TXcomBattleItem;
begin
  // 20 columns of 3 cells: 21 rifles that are not alike (each with a fuse would be odd: a clip of its own)
  for LIndex := 0 to 19 do
    OnGround(FRifle).StimulantQuantity := LIndex;
  LLast := OnGround(FRifle);
  LLast.StimulantQuantity := 20;
  FInventory.SetSelectedUnit(FUnit);
  Assert.AreEqual(0, FInventory.GroundOffset);
  Assert.AreEqual(20, LLast.SlotX);
  FInventory.ArrangeGround;
  Assert.AreEqual(20, FInventory.GroundOffset);
  // the second page shows the last rifle in the first column
  ClickCell(FGround, 0, 0, XCOM_BUTTON_LEFT);
  Assert.AreSame(LLast, FInventory.SelectedItem);
  FInventory.Click(0, 0, XCOM_BUTTON_RIGHT);
  FInventory.ArrangeGround;
  Assert.AreEqual(0, FInventory.GroundOffset);
  // without changing the page
  FInventory.ArrangeGround(False);
  Assert.AreEqual(0, FInventory.GroundOffset);
end;

procedure TTestXcomInventory.DovrebbeDisegnareGrigliaOggettiENumeroDellaPila;
var
  LTarget: TXcomSurface;
  LX, LY: Integer;
  LNumber: Boolean;
begin
  Carried(FClip, FBelt, 1, 0);
  Carried(FRifle, FRightHand);
  OnGround(FGrenade);
  OnGround(FGrenade);
  FInventory.Draw;
  FInventory.SetSelectedUnit(FUnit);
  LTarget := NewTarget;
  try
    FInventory.Blit(LTarget);
    // the corner of a cell of the back pack and its inside
    Assert.AreEqual(GRID_COLOR, Integer(LTarget.GetPixel(192, 40)));
    Assert.AreEqual(0, Integer(LTarget.GetPixel(193, 41)));
    // the frame of a hand: two by three cells
    Assert.AreEqual(GRID_COLOR, Integer(LTarget.GetPixel(31, 64 + 47)));
    Assert.AreEqual(0, Integer(LTarget.GetPixel(32, 64)));
    // the last column and row of the ground keep the line at the edge of the screen (the clipped SDL rectangle)
    Assert.AreEqual(GRID_COLOR, Integer(LTarget.GetPixel(319, 160)));
    Assert.AreEqual(GRID_COLOR, Integer(LTarget.GetPixel(100, 199)));
    Assert.AreEqual(0, Integer(LTarget.GetPixel(318, 198)));
    // the clip in the belt, the rifle in the middle of the hand (one cell wide: half a cell from the left)
    Assert.AreEqual(102, Integer(LTarget.GetPixel(192 + 16 + 3, 104 + 3)));
    Assert.AreEqual(101, Integer(LTarget.GetPixel(8 + 3, 64 + 3)));
    Assert.AreEqual(0, Integer(LTarget.GetPixel(3, 64 + 3)));
    // the grenades on the ground and the number of the pile at the bottom right of the cell
    Assert.AreEqual(104, Integer(LTarget.GetPixel(2, 154)));
    LNumber := False;
    for LY := 152 + 10 to 152 + 16 do
      for LX := 12 to 20 do
        // NumberText adds its color to the pixels of the digits (1) and of their border (2)
        if LTarget.GetPixel(LX, LY) in [STACK_COLOR + 1, STACK_COLOR + 2] then
          LNumber := True;
    Assert.IsTrue(LNumber, 'the number of the pile is not drawn');
  finally
    LTarget.Free;
  end;
end;

procedure TTestXcomInventory.DovrebbeFarPulsareLaGranataInnescata;
var
  LGrenade: TXcomBattleItem;
  LTarget: TXcomSurface;
  LStep: Integer;
const
  PULSATE: array[0..8] of Integer = (0, 1, 2, 3, 4, 3, 2, 1, 0);
begin
  LGrenade := Carried(FGrenade, FBelt, 0, 0);
  LGrenade.FuseTimer := 2;
  FInventory.SetSelectedUnit(FUnit);
  LTarget := NewTarget;
  try
    for LStep := 0 to 8 do
    begin
      FClock.Advance(125);
      FInventory.Think;
      FInventory.Blit(LTarget);
      Assert.AreEqual(PRIMER_COLOR + PULSATE[LStep], Integer(LTarget.GetPixel(192, 104)),
        Format('step %d', [LStep]));
    end;
    // picking it up warns the player
    PickUp(LGrenade);
    Assert.AreEqual('STR_GRENADE_IS_ACTIVATED', FInventory.WarningText);
  finally
    LTarget.Free;
  end;
end;

procedure TTestXcomInventory.DovrebbeDireLOggettoSottoIlMouse;
var
  LClip, LGrenade: TXcomBattleItem;
begin
  LClip := Carried(FClip, FBelt, 1, 0);
  LGrenade := OnGround(FGrenade);
  FInventory.Hover(192 + 16 + 2, 104 + 2);
  Assert.IsNull(FInventory.MouseOverItem, 'no unit yet');
  FInventory.SetSelectedUnit(FUnit);
  FInventory.Hover(192 + 16 + 2, 104 + 2);
  Assert.AreSame(LClip, FInventory.MouseOverItem);
  FInventory.Hover(2, 154);
  Assert.AreSame(LGrenade, FInventory.MouseOverItem);
  FInventory.Hover(100, 20);
  Assert.IsNull(FInventory.MouseOverItem);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomInventory);

end.
