{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - tile, item, unit    }
{  and saved battle with hand made rules and a scripted generator               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.Model;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.RulesetSettings, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Services.Intf, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Directions,
  DelphiDoom.XcomSave.Node;

type
  /// <summary>A generator that gives the numbers it was told to (and the minimum when it runs out)</summary>
  TScriptedRandom = class(TInterfacedObject, IXcomRandom)
  strict private
    FValues: TArray<Integer>;
    FNext: Integer;
  public
    constructor Create(const AValues: array of Integer);
    function Generate(AMin, AMax: Integer): Integer; overload;
    function Generate(AMin, AMax: Double): Double; overload;
    function Seed: UInt64;
    procedure SetSeed(AValue: UInt64);
  end;

  [TestFixture]
  [Category('xcom-battle')]
  TTestXcomBattleModel = class(TObject)
  strict private
    FSets: TObjectList<TXcomMapDataSet>;
    FArmors: TObjectList<TXcomArmor>;
    FItems: TObjectList<TXcomRuleItem>;
    FUnitRules: TObjectList<TXcomRuleUnit>;
    FInventories: TObjectList<TXcomRuleInventory>;
    FOffsets: TXcomModOffsets;
    function Yaml(const AText: string): IYamlNode;
    function Context(const AValues: array of Integer): IXcomBattleContext;
    function MakeArmor(const AText: string): TXcomArmor;
    function MakeItem(const AText: string): TXcomRuleItem;
    function MakeInventory(const AText: string): TXcomRuleInventory;
    function MakeUnitRules(const AText: string): TXcomRuleUnit;
    function MakeUnit(const AContext: IXcomBattleContext; AFaction, AId: Integer; ASize: Integer = 1)
      : TXcomBattleUnit;
    function MakePart(const ATuWalk: Integer; const ABigWall: Integer = 0): TXcomMapData;
    function Pos3(AX, AY, AZ: Integer): TXcomPosition;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeUsareSeStessaComeMunizioneSeLArmaNonHaCaricatori;
    [Test]
    procedure DovrebbeAccettareSoloLeMunizioniCompatibili;
    [Test]
    procedure DovrebbeSpendereLeMunizioniEDare255SeIllimitate;
    [Test]
    procedure DovrebbeSpostareUnOggettoFraInventari;
    [Test]
    procedure DovrebbeVerificareLOccupazioneDelloSlot;
    [Test]
    procedure DovrebbeSalvareUnOggettoConIlProprietario;
    [Test]
    procedure DovrebbeTrovareIlCostoDiMovimentoELePorteUfo;
    [Test]
    procedure DovrebbeDistruggereUnaParteESostituirlaConLaMorta;
    [Test]
    procedure DovrebbeDareLaLuceMassimaEIlColore;
    [Test]
    procedure DovrebbeAccendereIlFuocoSecondoLaProbabilita;
    [Test]
    procedure DovrebbeLimitareIlFumoAQuindici;
    [Test]
    procedure DovrebbeSalvareECaricareLeTegoleInBinario;
    [Test]
    procedure DovrebbeSceglierePosizioneEDirezioneDiUnaUnita;
    [Test]
    procedure DovrebbeGirareVersoUnaDirezione;
    [Test]
    procedure DovrebbeSubireDannoDallArmaturaAlleFerite;
    [Test]
    procedure DovrebbeSommareLoStordimentoENonLaSaluteInUnDannoStordente;
    [Test]
    procedure DovrebbeCalcolareICostiDelleAzioni;
    [Test]
    procedure DovrebbeCalcolareLaPrecisioneEIlRecuperoDiUnTurno;
    [Test]
    procedure DovrebbeSalvareECaricareUnaUnitaSenzaCambiarla;
    [Test]
    procedure DovrebbeIndicizzareLeTegoleDellaMappa;
    [Test]
    procedure DovrebbePosizionareUnaUnitaSoloSuUnaTegolaLibera;
    [Test]
    procedure DovrebbeSelezionareLeUnitaDelGiocatoreInGiro;
    [Test]
    procedure DovrebbeContareLeUnitaVive;
    [Test]
    procedure DovrebbeContareGliObiettivi;
    [Test]
    procedure DovrebbeCalcolareLaMappaDeiModuli;
    [Test]
    procedure DovrebbeCambiareLatoDiTurno;
    [Test]
    procedure DovrebbeSalvareECaricareUnaBattagliaVuota;
    [Test]
    procedure DovrebbeDareLeDirezioni;
  end;

implementation

type
  TFakeShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  /// <summary>A pathfinder that blocks nothing</summary>
  TOpenPathfinder = class(TInterfacedObject, IXcomBattlePathfinder)
  public
    procedure SetUnit(const AUnit: TXcomBattleUnit);
    function IsBlocked(const AStart, AEnd: TXcomTile; ADirection: Integer; const ATarget: TXcomBattleUnit)
      : Boolean;
  end;

  /// <summary>A tile engine that does nothing</summary>
  TQuietTileEngine = class(TInterfacedObject, IXcomBattleTileEngine)
  public
    procedure CalculateSunShading;
    procedure CalculateTerrainLighting;
    procedure CalculateUnitLighting;
    procedure RecalculateFov;
    procedure CalculateFov(const AUnit: TXcomBattleUnit);
    function HorizontalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer): Integer;
    procedure ApplyGravity(const ATile: TXcomTile);
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

{ TOpenPathfinder }

procedure TOpenPathfinder.SetUnit(const AUnit: TXcomBattleUnit);
begin
end;

function TOpenPathfinder.IsBlocked(const AStart, AEnd: TXcomTile; ADirection: Integer;
  const ATarget: TXcomBattleUnit): Boolean;
begin
  Result := False;
end;

{ TQuietTileEngine }

procedure TQuietTileEngine.CalculateSunShading;
begin
end;

procedure TQuietTileEngine.CalculateTerrainLighting;
begin
end;

procedure TQuietTileEngine.CalculateUnitLighting;
begin
end;

procedure TQuietTileEngine.RecalculateFov;
begin
end;

procedure TQuietTileEngine.CalculateFov(const AUnit: TXcomBattleUnit);
begin
end;

function TQuietTileEngine.HorizontalBlockage(const AStart, AEnd: TXcomTile; ADamageType: Integer): Integer;
begin
  Result := 0;
end;

procedure TQuietTileEngine.ApplyGravity(const ATile: TXcomTile);
begin
end;

{ TScriptedRandom }

constructor TScriptedRandom.Create(const AValues: array of Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FValues, Length(AValues));
  for LIndex := 0 to High(AValues) do
    FValues[LIndex] := AValues[LIndex];
end;

function TScriptedRandom.Generate(AMin, AMax: Integer): Integer;
begin
  if FNext < Length(FValues) then
  begin
    Result := FValues[FNext];
    Inc(FNext);
  end
  else
    Result := AMin;
end;

function TScriptedRandom.Generate(AMin, AMax: Double): Double;
begin
  Result := AMin;
end;

function TScriptedRandom.Seed: UInt64;
begin
  Result := 0;
end;

procedure TScriptedRandom.SetSeed(AValue: UInt64);
begin
end;

{ TTestXcomBattleModel }

function TTestXcomBattleModel.Yaml(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

function TTestXcomBattleModel.Context(const AValues: array of Integer): IXcomBattleContext;
begin
  Result := TXcomBattleContext.Create(TScriptedRandom.Create(AValues));
end;

function TTestXcomBattleModel.MakeArmor(const AText: string): TXcomArmor;
begin
  Result := TXcomArmor.Create('STR_TEST_ARMOR');
  Result.Load(Yaml(AText));
  FArmors.Add(Result);
end;

function TTestXcomBattleModel.MakeItem(const AText: string): TXcomRuleItem;
var
  LNode: IYamlNode;
begin
  LNode := Yaml(AText);
  Result := TXcomRuleItem.Create(YamlTextToString(LNode.Find(YamlStringToText('type')).AsString));
  Result.Load(LNode, FOffsets, 1);
  FItems.Add(Result);
end;

function TTestXcomBattleModel.MakeInventory(const AText: string): TXcomRuleInventory;
var
  LNode: IYamlNode;
begin
  LNode := Yaml(AText);
  Result := TXcomRuleInventory.Create(YamlTextToString(LNode.Find(YamlStringToText('id')).AsString));
  Result.Load(LNode, 1);
  FInventories.Add(Result);
end;

function TTestXcomBattleModel.MakeUnitRules(const AText: string): TXcomRuleUnit;
begin
  Result := TXcomRuleUnit.Create('STR_TEST_UNIT');
  Result.Load(Yaml(AText), FOffsets);
  FUnitRules.Add(Result);
end;

function TTestXcomBattleModel.MakeUnit(const AContext: IXcomBattleContext; AFaction, AId: Integer;
  ASize: Integer): TXcomBattleUnit;
var
  LArmor: TXcomArmor;
  LRules: TXcomRuleUnit;
  LAdjustment: TXcomStatAdjustment;
begin
  LArmor := MakeArmor(Format('{type: A, frontArmor: 20, sideArmor: 15, rearArmor: 10, underArmor: 5, size: %d, ' +
    'weight: 10, deathFrames: 3, loftempsSet: [1], damageModifier: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, ' +
    '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0], stats: {tu: 0}}', [ASize]));
  LRules := MakeUnitRules('{type: U, race: STR_RACE, rank: STR_LIVE_SOLDIER, standHeight: 22, kneelHeight: 14, ' +
    'floatHeight: 0, value: 5, energyRecovery: 12, stats: {tu: 50, stamina: 60, health: 40, bravery: 30, ' +
    'reactions: 55, firing: 60, throwing: 50, strength: 30, psiStrength: 0, psiSkill: 0, melee: 40}}');
  FillChar(LAdjustment, SizeOf(LAdjustment), 0);
  LAdjustment.AimAndArmorMultiplier := 1.0;
  Result := TXcomBattleUnit.Create(AContext, LRules, AFaction, AId, LArmor, LAdjustment, 0);
end;

function TTestXcomBattleModel.MakePart(const ATuWalk: Integer; const ABigWall: Integer): TXcomMapData;
var
  LSet: TXcomMapDataSet;
begin
  LSet := TXcomMapDataSet.Create('TEST');
  FSets.Add(LSet);
  Result := LSet.AddObject;
  Result.SetTuCosts(ATuWalk, ATuWalk, ATuWalk);
  Result.BigWall := ABigWall;
end;

function TTestXcomBattleModel.Pos3(AX, AY, AZ: Integer): TXcomPosition;
begin
  Result := TXcomPosition.Make(AX, AY, AZ);
end;

procedure TTestXcomBattleModel.Setup;
begin
  FSets := TObjectList<TXcomMapDataSet>.Create(True);
  FArmors := TObjectList<TXcomArmor>.Create(True);
  FItems := TObjectList<TXcomRuleItem>.Create(True);
  FUnitRules := TObjectList<TXcomRuleUnit>.Create(True);
  FInventories := TObjectList<TXcomRuleInventory>.Create(True);
  FOffsets := TXcomModOffsets.Create([TXcomModData.Make('master', 0, 1000)], 0, TFakeShared.Create);
end;

procedure TTestXcomBattleModel.TearDown;
begin
  FOffsets.Free;
  FInventories.Free;
  FUnitRules.Free;
  FItems.Free;
  FArmors.Free;
  FSets.Free;
end;

procedure TTestXcomBattleModel.DovrebbeUsareSeStessaComeMunizioneSeLArmaNonHaCaricatori;
var
  LId: Integer;
  LKnife: TXcomBattleItem;
  LRifle: TXcomBattleItem;
begin
  LId := 7;
  LKnife := TXcomBattleItem.Create(MakeItem('{type: KNIFE, battleType: 3, clipSize: -1}'), LId);
  LRifle := TXcomBattleItem.Create(MakeItem('{type: RIFLE, battleType: 1, clipSize: -1, compatibleAmmo: [CLIP]}'),
    LId);
  try
    Assert.AreEqual(9, LId);
    Assert.IsFalse(LKnife.NeedsAmmo);
    Assert.IsTrue(LRifle.NeedsAmmo);
    Assert.AreEqual(-2, LKnife.SetAmmoItem(LRifle));
  finally
    LRifle.Free;
    LKnife.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeAccettareSoloLeMunizioniCompatibili;
var
  LId: Integer;
  LRifleRules: TXcomRuleItem;
  LRifle, LClip, LOther: TXcomBattleItem;
begin
  LId := 1;
  LRifleRules := MakeItem('{type: STR_RIFLE, battleType: 1, clipSize: -1, compatibleAmmo: [STR_CLIP]}');
  LRifle := TXcomBattleItem.Create(LRifleRules, LId);
  LClip := TXcomBattleItem.Create(MakeItem('{type: STR_CLIP, battleType: 2, clipSize: 20}'), LId);
  LOther := TXcomBattleItem.Create(MakeItem('{type: STR_OTHER, battleType: 2, clipSize: 20}'), LId);
  try
    Assert.AreEqual(-2, LRifle.SetAmmoItem(LOther));
    Assert.IsFalse(LClip.IsAmmo);
    Assert.AreEqual(0, LRifle.SetAmmoItem(LClip));
    Assert.IsTrue(LClip.IsAmmo);
    Assert.AreEqual(-1, LRifle.SetAmmoItem(LOther));
    Assert.AreEqual(0, LRifle.SetAmmoItem(nil));
    Assert.IsFalse(LClip.IsAmmo);
    Assert.IsNull(LRifle.AmmoItem);
  finally
    LOther.Free;
    LClip.Free;
    LRifle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSpendereLeMunizioniEDare255SeIllimitate;
var
  LId: Integer;
  LClip, LEndless: TXcomBattleItem;
begin
  LId := 1;
  LClip := TXcomBattleItem.Create(MakeItem('{type: C, battleType: 2, clipSize: 2}'), LId);
  LEndless := TXcomBattleItem.Create(MakeItem('{type: E, battleType: 2, clipSize: -1}'), LId);
  try
    Assert.AreEqual(2, LClip.AmmoQuantity);
    Assert.IsTrue(LClip.SpendBullet);
    Assert.IsFalse(LClip.SpendBullet);
    Assert.IsFalse(LClip.SpendBullet);
    Assert.AreEqual(0, LClip.AmmoQuantity);
    Assert.AreEqual(255, LEndless.AmmoQuantity);
  finally
    LEndless.Free;
    LClip.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSpostareUnOggettoFraInventari;
var
  LId: Integer;
  LItem: TXcomBattleItem;
  LFirst, LSecond: TXcomBattleUnit;
begin
  LId := 1;
  LFirst := MakeUnit(Context([]), FACTION_PLAYER, 1);
  LSecond := MakeUnit(Context([]), FACTION_PLAYER, 2);
  LItem := TXcomBattleItem.Create(MakeItem('{type: G, battleType: 4}'), LId);
  try
    LItem.MoveToOwner(LFirst);
    Assert.AreEqual(1, LFirst.Inventory.Count);
    LItem.MoveToOwner(LSecond);
    Assert.AreEqual(0, LFirst.Inventory.Count);
    Assert.AreEqual(1, LSecond.Inventory.Count);
    Assert.AreSame(LFirst, LItem.PreviousOwner);
    Assert.AreSame(LSecond, LItem.Owner);
  finally
    LItem.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeVerificareLOccupazioneDelloSlot;
var
  LId: Integer;
  LItem, LOther: TXcomBattleItem;
begin
  LId := 1;
  LItem := TXcomBattleItem.Create(MakeItem('{type: A, battleType: 1, clipSize: -1, invWidth: 2, invHeight: 3}'), LId);
  LOther := TXcomBattleItem.Create(MakeItem('{type: B, battleType: 4, invWidth: 1, invHeight: 1}'), LId);
  try
    LItem.Slot := MakeInventory('{id: STR_BACK_PACK, type: 0}');
    LItem.SlotX := 3;
    LItem.SlotY := 4;
    Assert.IsTrue(LItem.OccupiesSlot(4, 6));
    Assert.IsFalse(LItem.OccupiesSlot(5, 6));
    Assert.IsFalse(LItem.OccupiesSlot(4, 7));
    Assert.IsFalse(LItem.OccupiesSlot(0, 0, LItem));
    Assert.IsTrue(LItem.OccupiesSlot(2, 4, LOther) = False);
    Assert.IsTrue(LItem.OccupiesSlot(3, 4, LOther));
    LItem.Slot := MakeInventory('{id: STR_RIGHT_HAND, type: 1}');
    Assert.IsTrue(LItem.OccupiesSlot(99, 99));
  finally
    LOther.Free;
    LItem.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSalvareUnOggettoConIlProprietario;
var
  LId: Integer;
  LItem: TXcomBattleItem;
  LOwner: TXcomBattleUnit;
  LNode: IYamlNode;
begin
  LId := 12;
  LOwner := MakeUnit(Context([]), FACTION_PLAYER, 3);
  LItem := TXcomBattleItem.Create(MakeItem('{type: STR_GRENADE, battleType: 4, clipSize: 1}'), LId);
  try
    LItem.MoveToOwner(LOwner);
    LItem.Slot := MakeInventory('{id: STR_BELT, type: 0}');
    LItem.FuseTimer := 2;
    LItem.XcomProperty := True;
    LNode := LItem.Save;
    Assert.AreEqual('STR_GRENADE', string(LNode.Find('type').AsString));
    Assert.AreEqual(12, LNode.Find('id').AsInteger);
    Assert.AreEqual(3, LNode.Find('owner').AsInteger);
    Assert.AreEqual('STR_BELT', string(LNode.Find('inventoryslot').AsString));
    Assert.AreEqual(2, LNode.Find('fuseTimer').AsInteger);
    Assert.IsTrue(LNode.Find('XCOMProperty').AsBoolean);
    Assert.IsFalse(LNode.Find('droppedOnAlienTurn').IsDefined);
  finally
    LItem.Free;
    LOwner.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeTrovareIlCostoDiMovimentoELePorteUfo;
var
  LTile: TXcomTile;
  LDoor: TXcomMapData;
begin
  LTile := TXcomTile.Create(Pos3(1, 2, 0), Context([]));
  try
    Assert.AreEqual(0, LTile.GetTuCost(XCOM_PART_FLOOR, MT_WALK));
    LTile.SetMapData(MakePart(4), 0, 0, XCOM_PART_FLOOR);
    Assert.AreEqual(4, LTile.GetTuCost(XCOM_PART_FLOOR, MT_WALK));
    LTile.SetMapData(MakePart(255, 4), 1, 0, XCOM_PART_OBJECT);
    Assert.AreEqual(0, LTile.GetTuCost(XCOM_PART_OBJECT, MT_WALK));
    Assert.IsTrue(LTile.IsBigWall);
    LDoor := MakePart(6);
    LDoor.SetFlags(True, False, False, 0, False, False, False, False, False);
    LTile.SetMapData(LDoor, 2, 0, XCOM_PART_WESTWALL);
    Assert.IsFalse(LTile.IsUfoDoorOpen(XCOM_PART_WESTWALL));
    Assert.AreEqual(1, LTile.OpenDoor(XCOM_PART_WESTWALL));
    Assert.IsTrue(LTile.IsUfoDoorOpen(XCOM_PART_WESTWALL));
    Assert.AreEqual(3, LTile.OpenDoor(XCOM_PART_WESTWALL));
    LTile.Animate;
    Assert.AreEqual(0, LTile.GetTuCost(XCOM_PART_WESTWALL, MT_WALK));
    Assert.AreEqual(1, LTile.CloseUfoDoor);
    Assert.AreEqual(0, LTile.CloseUfoDoor);
    Assert.AreEqual(-1, LTile.OpenDoor(XCOM_PART_NORTHWALL));
  finally
    LTile.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeDistruggereUnaParteESostituirlaConLaMorta;
var
  LSet: TXcomMapDataSet;
  LAlive, LDead, LScorched: TXcomMapData;
  LTile: TXcomTile;
begin
  LSet := TXcomMapDataSet.Create('TEST');
  FSets.Add(LSet);
  LAlive := LSet.AddObject;
  LDead := LSet.AddObject;
  LScorched := LSet.AddObject;
  LAlive.DieMcd := 1;
  LDead.ObjectType := XCOM_PART_OBJECT;
  LAlive.Armor := 20;
  LAlive.Explosive := 30;
  LAlive.ExplosiveType := 3;
  LTile := TXcomTile.Create(Pos3(0, 0, 0), Context([]));
  try
    LTile.SetMapData(LAlive, 0, 0, XCOM_PART_OBJECT);
    Assert.IsFalse(LTile.Damage(XCOM_PART_OBJECT, 19, 5, LScorched));
    Assert.AreSame(LAlive, LTile.MapData[XCOM_PART_OBJECT]);
    LTile.Damage(XCOM_PART_OBJECT, 20, 5, LScorched);
    Assert.AreSame(LDead, LTile.MapData[XCOM_PART_OBJECT]);
    Assert.AreEqual(30, LTile.Explosive);
    Assert.AreEqual(3, LTile.ExplosiveType);
    // the floor of the lowest level becomes scorched earth when the part is gone
    LTile.SetMapData(LAlive, 0, 0, XCOM_PART_FLOOR);
    LTile.DestroyPart(XCOM_PART_FLOOR, 0, LScorched);
    Assert.AreSame(LScorched, LTile.MapData[XCOM_PART_FLOOR]);
  finally
    LTile.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeDareLaLuceMassimaEIlColore;
var
  LTile: TXcomTile;
begin
  LTile := TXcomTile.Create(Pos3(0, 0, 0), Context([]));
  try
    Assert.AreEqual(15, LTile.GetShade);
    LTile.AddLight(5, 0);
    LTile.AddLight(3, 0);
    LTile.AddLight(9, 2);
    Assert.AreEqual(6, LTile.GetShade);
    LTile.ResetLight(2);
    Assert.AreEqual(10, LTile.GetShade);
    LTile.SetDiscovered(True, 2);
    Assert.IsTrue(LTile.IsDiscovered(0));
    Assert.IsTrue(LTile.IsDiscovered(1));
  finally
    LTile.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeAccendereIlFuocoSecondoLaProbabilita;
var
  LTile: TXcomTile;
  LPart: TXcomMapData;
begin
  LPart := MakePart(1);
  LPart.Flammable := 20;
  LPart.Fuel := 4;
  // power 30 - 2 + 15 = 43; the number 10 is below it, then the animation offset 2
  LTile := TXcomTile.Create(Pos3(0, 0, 0), Context([10, 2]));
  try
    LTile.SetMapData(LPart, 0, 0, XCOM_PART_OBJECT);
    LTile.Ignite(30);
    Assert.AreEqual(5, LTile.Fire);
    Assert.AreEqual(13, LTile.Smoke);
    Assert.AreEqual(1, LTile.Overlaps);
    Assert.AreEqual(2, LTile.AnimationOffset);
  finally
    LTile.Free;
  end;
  LTile := TXcomTile.Create(Pos3(0, 0, 0), Context([90]));
  try
    LTile.SetMapData(LPart, 0, 0, XCOM_PART_OBJECT);
    LTile.Ignite(30);
    Assert.AreEqual(0, LTile.Fire);
  finally
    LTile.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeLimitareIlFumoAQuindici;
var
  LTile: TXcomTile;
begin
  LTile := TXcomTile.Create(Pos3(0, 0, 0), Context([]));
  try
    LTile.AddSmoke(10);
    LTile.PrepareNewTurn(True);
    LTile.AddSmoke(12);
    Assert.AreEqual(15, LTile.Smoke);
    Assert.AreEqual(1, LTile.Overlaps);
    // with an overlap the smoke of the turn is averaged: (15 / 1) - 1
    LTile.PrepareNewTurn(False);
    Assert.AreEqual(14, LTile.Smoke);
    Assert.AreEqual(0, LTile.Overlaps);
  finally
    LTile.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSalvareECaricareLeTegoleInBinario;
var
  LTile, LLoaded: TXcomTile;
  LBuffer: TBytes;
  LOffset: Integer;
  LSetId: Integer;
  LKey: TXcomTileSerializationKey;
begin
  LKey := TXcomTileSerializationKey.Current;
  Assert.AreEqual(23, Integer(LKey.TotalBytes));
  LTile := TXcomTile.Create(Pos3(0, 0, 0), Context([]));
  LLoaded := TXcomTile.Create(Pos3(0, 0, 0), Context([]));
  try
    LTile.SetMapData(MakePart(1), 300, 2, XCOM_PART_OBJECT);
    LTile.SetSmoke(7);
    LTile.SetFire(2);
    LTile.SetDiscovered(True, 1);
    SetLength(LBuffer, 23);
    LOffset := 0;
    LTile.SaveBinary(LBuffer, LOffset);
    Assert.AreEqual(19, LOffset);
    LLoaded.LoadBinary(LBuffer, 0, LKey);
    Assert.AreEqual(7, LLoaded.Smoke);
    Assert.AreEqual(2, LLoaded.Fire);
    Assert.IsTrue(LLoaded.IsDiscovered(1));
    Assert.IsFalse(LLoaded.IsDiscovered(0));
    LLoaded.GetMapDataIds(LOffset, LSetId, XCOM_PART_OBJECT);
    Assert.AreEqual(300, LOffset);
    Assert.AreEqual(2, LSetId);
  finally
    LLoaded.Free;
    LTile.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSceglierePosizioneEDirezioneDiUnaUnita;
var
  LUnit: TXcomBattleUnit;
begin
  LUnit := MakeUnit(Context([]), FACTION_PLAYER, 1);
  try
    LUnit.SetPosition(Pos3(5, 5, 0));
    Assert.AreEqual(0, LUnit.DirectionTo(Pos3(5, 1, 0)));
    Assert.AreEqual(1, LUnit.DirectionTo(Pos3(9, 1, 0)));
    Assert.AreEqual(2, LUnit.DirectionTo(Pos3(9, 5, 0)));
    Assert.AreEqual(3, LUnit.DirectionTo(Pos3(9, 9, 0)));
    Assert.AreEqual(4, LUnit.DirectionTo(Pos3(5, 9, 0)));
    Assert.AreEqual(5, LUnit.DirectionTo(Pos3(1, 9, 0)));
    Assert.AreEqual(6, LUnit.DirectionTo(Pos3(1, 5, 0)));
    Assert.AreEqual(7, LUnit.DirectionTo(Pos3(1, 1, 0)));
    LUnit.SetPosition(Pos3(6, 6, 0));
    Assert.AreEqual(Pos3(5, 5, 0).X, LUnit.LastPosition.X);
    LUnit.SetDirection(2);
    Assert.IsTrue(LUnit.CheckViewSector(Pos3(9, 6, 0)));
    Assert.IsFalse(LUnit.CheckViewSector(Pos3(2, 6, 0)));
  finally
    LUnit.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeGirareVersoUnaDirezione;
var
  LUnit: TXcomBattleUnit;
begin
  LUnit := MakeUnit(Context([]), FACTION_PLAYER, 1);
  try
    LUnit.SetDirection(0);
    LUnit.LookAt(6);
    Assert.AreEqual(STATUS_TURNING, LUnit.Status);
    LUnit.Turn;
    Assert.AreEqual(7, LUnit.Direction);
    LUnit.Turn;
    Assert.AreEqual(6, LUnit.Direction);
    Assert.AreEqual(STATUS_STANDING, LUnit.Status);
    LUnit.LookAt(9);
    Assert.AreEqual(6, LUnit.ToDirection);
    LUnit.LookAt(2, True);
    Assert.AreEqual(2, LUnit.Direction);
  finally
    LUnit.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSubireDannoDallArmaturaAlleFerite;
var
  LUnit: TXcomBattleUnit;
  LDone: Integer;
begin
  // the unit faces south and the hit comes from +y: the front, with no roll for the side; then the stun roll (1)
  LUnit := MakeUnit(Context([1]), FACTION_PLAYER, 1);
  try
    LUnit.SetDirection(4);
    LDone := LUnit.Damage(Pos3(0, 8, 10), 30, TXcomRuleItem.DT_AP);
    // the front armor of 20 stops 20 of 30
    Assert.AreEqual(10, LDone);
    Assert.AreEqual(30, LUnit.Health);
    Assert.AreEqual(1, LUnit.StunLevel);
    Assert.AreEqual(18, LUnit.GetArmor(SIDE_FRONT));
    Assert.AreEqual(SIDE_FRONT, LUnit.FatalShotSide);
    Assert.AreEqual(BODYPART_TORSO, LUnit.FatalShotBodyPart);
  finally
    LUnit.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSommareLoStordimentoENonLaSaluteInUnDannoStordente;
var
  LUnit: TXcomBattleUnit;
begin
  LUnit := MakeUnit(Context([]), FACTION_PLAYER, 1);
  try
    Assert.AreEqual(0, LUnit.Damage(Pos3(0, 0, 0), 0, TXcomRuleItem.DT_STUN));
    LUnit.Damage(Pos3(0, 0, 0), 30, TXcomRuleItem.DT_STUN, True);
    Assert.AreEqual(30, LUnit.StunLevel);
    Assert.AreEqual(40, LUnit.Health);
    LUnit.HealStun(100);
    Assert.AreEqual(0, LUnit.StunLevel);
    LUnit.KnockOut;
    Assert.AreEqual(40, LUnit.StunLevel);
    Assert.IsFalse(LUnit.IsOut);
    LUnit.GoToTimeOut;
    Assert.IsTrue(LUnit.IsOut);
  finally
    LUnit.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeCalcolareICostiDelleAzioni;
var
  LUnit: TXcomBattleUnit;
  LPercent, LFlat: TXcomRuleItem;
begin
  LUnit := MakeUnit(Context([]), FACTION_PLAYER, 1);
  LPercent := MakeItem('{type: P, battleType: 1, clipSize: -1, tuSnap: 25, tuAimed: 80, tuAuto: 35}');
  LFlat := MakeItem('{type: F, battleType: 1, clipSize: -1, tuSnap: 13, flatRate: true}');
  try
    // the unit has 50 time units: 25 % of 50 is 12.5, floored
    Assert.AreEqual(12, LUnit.GetActionTus(BA_SNAPSHOT, LPercent));
    Assert.AreEqual(40, LUnit.GetActionTus(BA_AIMEDSHOT, LPercent));
    Assert.AreEqual(17, LUnit.GetActionTus(BA_AUTOSHOT, LPercent));
    Assert.AreEqual(13, LUnit.GetActionTus(BA_SNAPSHOT, LFlat));
    Assert.AreEqual(12, LUnit.GetActionTus(BA_THROW, LFlat));
    Assert.AreEqual(25, LUnit.GetActionTus(BA_PRIME, LFlat));
    Assert.AreEqual(0, LUnit.GetActionTus(BA_WALK, LPercent));
    Assert.AreEqual(0, LUnit.GetActionTus(BA_SNAPSHOT, TXcomRuleItem(nil)));
    Assert.IsTrue(LUnit.SpendTimeUnits(20));
    Assert.IsFalse(LUnit.SpendTimeUnits(31));
    Assert.IsTrue(LUnit.SpendEnergy(11));
    Assert.AreEqual(55, LUnit.Energy);
    LUnit.SetTimeUnits(-4);
    Assert.AreEqual(0, LUnit.TimeUnits);
  finally
    LUnit.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeCalcolareLaPrecisioneEIlRecuperoDiUnTurno;
var
  LUnit: TXcomBattleUnit;
begin
  LUnit := MakeUnit(Context([]), FACTION_PLAYER, 1);
  try
    Assert.AreEqual(100, LUnit.GetAccuracyModifier);
    Assert.AreEqual(50.0, LUnit.GetThrowingAccuracy, 0.0001);
    Assert.AreEqual(55.0, LUnit.GetReactionScore, 0.0001);
    LUnit.SpendTimeUnits(25);
    Assert.AreEqual(27.5, LUnit.GetReactionScore, 0.0001);
    // strength 30 over a weight of 10 (the armor): no encumbrance, all the units come back
    LUnit.RecoverTimeUnits;
    Assert.AreEqual(50, LUnit.TimeUnits);
    // the energy: 60 stamina is the cap, 12 is the recovery
    LUnit.SpendEnergy(60);
    LUnit.RecoverTimeUnits;
    Assert.AreEqual(42, LUnit.Energy);
    Assert.AreEqual(10, LUnit.GetCarriedWeight);
  finally
    LUnit.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSalvareECaricareUnaUnitaSenzaCambiarla;
var
  LUnit, LOther: TXcomBattleUnit;
  LNode: IYamlNode;
  LFirst, LSecond: TYamlText;
begin
  LUnit := MakeUnit(Context([]), FACTION_HOSTILE, 1000001);
  LOther := MakeUnit(Context([]), FACTION_HOSTILE, 5);
  try
    LUnit.SetPosition(Pos3(3, 4, 1));
    LUnit.SetDirection(5);
    LUnit.Kneel(True);
    LUnit.Damage(Pos3(1, 1, 1), 10, TXcomRuleItem.DT_IN, True);
    LUnit.SetFire(3);
    LUnit.AddKillCount;
    LUnit.MurdererWeapon := 'STR_X';
    LNode := LUnit.Save;
    LFirst := TYamlFactory.Dump(LNode);
    LOther.Load(LNode);
    LSecond := TYamlFactory.Dump(LOther.Save);
    Assert.AreEqual(string(LFirst), string(LSecond));
    Assert.AreEqual(3, LOther.Position.X);
    Assert.AreEqual(1000001, LOther.Id);
    Assert.IsTrue(LOther.IsKneeled);
  finally
    LOther.Free;
    LUnit.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeIndicizzareLeTegoleDellaMappa;
var
  LBattle: TXcomSavedBattleGame;
  LX, LY, LZ: Integer;
begin
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  try
    LBattle.InitMap(4, 3, 2);
    Assert.AreEqual(24, LBattle.MapSizeXyz);
    Assert.AreEqual(1 * 12 + 2 * 4 + 3, LBattle.TileIndex(Pos3(3, 2, 1)));
    LBattle.TileCoords(23, LX, LY, LZ);
    Assert.AreEqual(3, LX);
    Assert.AreEqual(2, LY);
    Assert.AreEqual(1, LZ);
    Assert.IsNotNull(LBattle.TileAt(Pos3(3, 2, 1)));
    Assert.IsNull(LBattle.TileAt(Pos3(4, 0, 0)));
    Assert.IsNull(LBattle.TileAt(Pos3(0, -1, 0)));
    Assert.IsNull(LBattle.TileAt(Pos3(0, 0, 2)));
    Assert.AreEqual(121, Length(LBattle.TileSearch));
    Assert.AreEqual(-5, LBattle.TileSearch[0].X);
    Assert.AreEqual(5, LBattle.TileSearch[120].Y);
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbePosizionareUnaUnitaSoloSuUnaTegolaLibera;
var
  LBattle: TXcomSavedBattleGame;
  LFirst, LSecond: TXcomBattleUnit;
  LFloor: TXcomMapData;
  LIndex: Integer;
begin
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  LBattle.Pathfinder := TOpenPathfinder.Create;
  LBattle.TileEngine := TQuietTileEngine.Create;
  LBattle.InitMap(3, 3, 1);
  LFloor := MakePart(2);
  for LIndex := 0 to 8 do
    LBattle.TileByIndex(LIndex).SetMapData(LFloor, 0, 0, XCOM_PART_FLOOR);
  LFirst := MakeUnit(Context([]), FACTION_PLAYER, 1);
  LSecond := MakeUnit(Context([]), FACTION_PLAYER, 2);
  LBattle.Units.Add(LFirst);
  LBattle.Units.Add(LSecond);
  try
    Assert.IsTrue(LBattle.SetUnitPosition(LFirst, Pos3(1, 1, 0)));
    Assert.AreSame(LFirst, LBattle.TileAt(Pos3(1, 1, 0)).CurrentUnit);
    Assert.IsFalse(LBattle.SetUnitPosition(LSecond, Pos3(1, 1, 0)));
    Assert.IsFalse(LBattle.SetUnitPosition(LSecond, Pos3(7, 1, 0)));
    // near: the occupied tile is skipped for a free one
    Assert.IsTrue(LBattle.PlaceUnitNearPosition(LSecond, Pos3(1, 1, 0), False));
    Assert.IsFalse((LSecond.Position.X = 1) and (LSecond.Position.Y = 1));
    Assert.IsFalse(LBattle.EyesOnTarget(FACTION_PLAYER, LFirst));
    LSecond.AddToVisibleUnits(LFirst);
    Assert.IsTrue(LBattle.EyesOnTarget(FACTION_PLAYER, LFirst));
    Assert.IsTrue(LBattle.AddFallingUnit(LFirst));
    Assert.IsFalse(LBattle.AddFallingUnit(LFirst));
    Assert.IsTrue(LBattle.UnitsFalling);
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSelezionareLeUnitaDelGiocatoreInGiro;
var
  LBattle: TXcomSavedBattleGame;
  LFirst, LSecond, LAlien: TXcomBattleUnit;
begin
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  LFirst := MakeUnit(Context([]), FACTION_PLAYER, 1);
  LAlien := MakeUnit(Context([]), FACTION_HOSTILE, 1000001);
  LSecond := MakeUnit(Context([]), FACTION_PLAYER, 2);
  LBattle.Units.Add(LFirst);
  LBattle.Units.Add(LAlien);
  LBattle.Units.Add(LSecond);
  try
    Assert.AreSame(LFirst, LBattle.SelectNextPlayerUnit);
    Assert.AreSame(LSecond, LBattle.SelectNextPlayerUnit);
    Assert.AreSame(LFirst, LBattle.SelectNextPlayerUnit);
    Assert.AreSame(LSecond, LBattle.SelectPreviousPlayerUnit);
    LBattle.SelectedUnit := nil;
    Assert.AreSame(LSecond, LBattle.SelectPreviousPlayerUnit);
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeContareLeUnitaVive;
var
  LBattle: TXcomSavedBattleGame;
  LLiveAliens, LLiveSoldiers: Integer;
  LDead: TXcomBattleUnit;
begin
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  LBattle.Units.Add(MakeUnit(Context([]), FACTION_PLAYER, 1));
  LBattle.Units.Add(MakeUnit(Context([]), FACTION_HOSTILE, 1000001));
  LBattle.Units.Add(MakeUnit(Context([]), FACTION_HOSTILE, 1000002));
  LDead := MakeUnit(Context([]), FACTION_HOSTILE, 1000003);
  LDead.InstaKill;
  LBattle.Units.Add(LDead);
  try
    LBattle.TallyUnits(LLiveAliens, LLiveSoldiers);
    Assert.AreEqual(2, LLiveAliens);
    Assert.AreEqual(1, LLiveSoldiers);
    Assert.AreSame(LBattle.Units[0], LBattle.GetHighestRankedXcom);
    Assert.AreEqual(100, LBattle.GetMoraleModifier);
    LBattle.Units[0].RankInt := 4;
    Assert.AreEqual(125, LBattle.GetMoraleModifier);
    Assert.AreEqual(150, LBattle.GetMoraleModifier(LBattle.Units[0]));
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeContareGliObiettivi;
var
  LBattle: TXcomSavedBattleGame;
begin
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  try
    Assert.IsFalse(LBattle.AllObjectivesDestroyed);
    LBattle.SetObjectiveCount(2);
    Assert.IsFalse(LBattle.AddDestroyedObjective);
    Assert.IsTrue(LBattle.AddDestroyedObjective);
    Assert.IsTrue(LBattle.AllObjectivesDestroyed);
    Assert.IsFalse(LBattle.AddDestroyedObjective);
    Assert.AreEqual(2, LBattle.ObjectivesDestroyed);
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeCalcolareLaMappaDeiModuli;
var
  LBattle: TXcomSavedBattleGame;
  LModule: TXcomMapData;
begin
  LModule := MakePart(1);
  LModule.SetFlags(False, False, False, 0, False, False, False, False, True);
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  try
    LBattle.InitMap(20, 10, 1);
    LBattle.TileAt(Pos3(12, 3, 0)).SetMapData(LModule, 0, 0, XCOM_PART_OBJECT);
    LBattle.TileAt(Pos3(13, 3, 0)).SetMapData(LModule, 0, 0, XCOM_PART_OBJECT);
    LBattle.CalculateModuleMap;
    Assert.AreEqual(2, Length(LBattle.ModuleMap));
    Assert.AreEqual(-1, LBattle.ModuleMap[0][0].Key);
    // the first module of a cell takes it from -1 to 1, the next ones add one
    Assert.AreEqual(2, LBattle.ModuleMap[1][0].Key);
    Assert.AreEqual(2, LBattle.ModuleMap[1][0].Value);
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeCambiareLatoDiTurno;
var
  LBattle: TXcomSavedBattleGame;
begin
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  LBattle.TileEngine := TQuietTileEngine.Create;
  LBattle.InitMap(2, 2, 1);
  LBattle.Units.Add(MakeUnit(Context([]), FACTION_PLAYER, 1));
  LBattle.Units.Add(MakeUnit(Context([]), FACTION_HOSTILE, 1000001));
  try
    Assert.AreEqual(FACTION_PLAYER, LBattle.Side);
    LBattle.EndTurn;
    Assert.AreEqual(FACTION_HOSTILE, LBattle.Side);
    // the neutral turn is kept while there are units to select
    LBattle.EndTurn;
    Assert.AreEqual(FACTION_NEUTRAL, LBattle.Side);
    LBattle.EndTurn;
    Assert.AreEqual(FACTION_PLAYER, LBattle.Side);
    Assert.AreEqual(2, LBattle.Turn);
    Assert.AreSame(LBattle.Units[0], LBattle.SelectedUnit);
    LBattle.ResetTurnCounter;
    Assert.AreEqual(1, LBattle.Turn);
    Assert.IsTrue(LBattle.BeforeGame);
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeSalvareECaricareUnaBattagliaVuota;
var
  LBattle: TXcomSavedBattleGame;
  LNode: IYamlNode;
begin
  LBattle := TXcomSavedBattleGame.Create(Context([]));
  try
    LBattle.InitMap(2, 2, 1);
    LBattle.MissionType := 'STR_TERROR_MISSION';
    LBattle.Music := 'GMTACTIC';
    LBattle.Nodes.Add(TXcomNode.Create(3, Pos3(1, 1, 0), 0, 1, 2, 3, 4, 5));
    LNode := LBattle.Save;
    Assert.AreEqual(2, LNode.Find('width').AsInteger);
    Assert.AreEqual('STR_TERROR_MISSION', string(LNode.Find('missionType').AsString));
    Assert.AreEqual(-1, LNode.Find('selectedUnit').AsInteger);
    Assert.AreEqual(0, LNode.Find('totalTiles').AsInteger);
    Assert.AreEqual(1, LNode.Find('nodes').Size);
    Assert.IsFalse(LNode.Find('units').IsDefined);
  finally
    LBattle.Free;
  end;
end;

procedure TTestXcomBattleModel.DovrebbeDareLeDirezioni;
begin
  Assert.AreEqual(0, TXcomDirections.ToVector(0).X);
  Assert.AreEqual(-1, TXcomDirections.ToVector(0).Y);
  Assert.AreEqual(1, TXcomDirections.ToVector(8).Z);
  Assert.AreEqual(-1, TXcomDirections.ToVector(9).Z);
  Assert.AreEqual(3, TXcomDirections.FromVector(Pos3(1, 1, 0)));
  Assert.AreEqual(-1, TXcomDirections.FromVector(Pos3(0, 0, 0)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomBattleModel);

end.
