{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - the ruleset, its registries  }
{  and the loader with YAML written in the tests (no game data)                 }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.Ruleset;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Intf,
  DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomMod.ModFiles.Intf, DelphiDoom.XcomMod.Ruleset;

type
  /// <summary>Every set has 100 shared sprites and 20 shared sounds</summary>
  TXcomFixedShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  /// <summary>Files in memory: the YAML source of the parser and the virtual files of the mods</summary>
  TXcomMemoryFiles = class(TInterfacedObject, IYamlFileSource, IXcomModFiles)
  strict private
    FFiles: TDictionary<string, string>;
    FBinary: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName, AText: string);
    function TryReadAllBytes(const AFileName: string; out ABytes: TBytes): Boolean;
    function FolderContents(const AVirtualFolder: string): TArray<string>;
    function LoadYaml(const AVirtualFile: string): IYamlNode;
    function LoadBytes(const AVirtualFile: string): TBytes;
    procedure AddBytes(const AName: string; const ABytes: TBytes);
  end;

  [TestFixture]
  [Category('xcom-mod')]
  [Category('xcom-mod-ruleset')]
  TTestXcomRuleset = class(TObject)
  strict private
    FRuleset: TXcomRuleset;
    FFiles: TXcomMemoryFiles;
    FFilesRef: IInterface;
    procedure Load(const AText: string);
    function LoadFails(const AText: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnOggettoConElencoDiOrdineAutomatico;
    [Test]
    procedure DovrebbeSollevareErroreSeUnArmaNonHaMunizioni;
    [Test]
    procedure DovrebbeCalcolareIlRaggioDiEsplosione;
    [Test]
    procedure DovrebbeCancellareUnaRegolaConDelete;
    [Test]
    procedure DovrebbeSommareGliOffsetDelModCorrente;
    [Test]
    procedure DovrebbeCaricareUnaCorazzaConCadavereEModificatoriDiDanno;
    [Test]
    procedure DovrebbeSollevareErroreSeLaCorazzaNonHaCadaveri;
    [Test]
    procedure DovrebbeSollevareErroreSeUnUnitaESuperaLAltezza;
    [Test]
    procedure DovrebbeCaricareISoldatiEIPoolDeiNomi;
    [Test]
    procedure DovrebbeSollevareErroreSeISoldatiNonHannoFile;
    [Test]
    procedure DovrebbeCaricareIComandiDiUnoScriptDiMappa;
    [Test]
    procedure DovrebbeSollevareErroriNeiComandiDiMappa;
    [Test]
    procedure DovrebbeCaricareGliArticoliDellUfopaediaDiOgniTipo;
    [Test]
    procedure DovrebbeSollevareErroreSeUnArticoloHaUnTipoSconosciuto;
    [Test]
    procedure DovrebbeOrdinareGliIndiciPerOrdineDiElenco;
    [Test]
    procedure DovrebbeCaricareLeAltreSezioniDelFile;
    [Test]
    procedure DovrebbeUnireLeDistribuzioniDelleRazzeEScartareQuelleVuote;
    [Test]
    procedure DovrebbeControllareLeMissioniDegliScript;
    [Test]
    procedure DovrebbeCaricareIMod;
    [Test]
    procedure DovrebbeCaricareIlFileDelleRisorse;
    [Test]
    procedure DovrebbeLeggereLeMappeConNumeriEIlRecordDelleStatistiche;
    [Test]
    procedure DovrebbeSollevareErroriNelleMissioniAliene;
  end;

implementation

uses
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.ModLoader, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.RuleSoldier,
  DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomMod.RuleAlienMission,
  DelphiDoom.XcomMod.RuleMissionScript, DelphiDoom.XcomMod.RuleRegistry, DelphiDoom.XcomMod.MapDataSet,
  DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomMod.IntStringMap;

{ TXcomFixedShared }

function TXcomFixedShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TXcomFixedShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 100;
end;

{ TXcomMemoryFiles }

constructor TXcomMemoryFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, string>.Create;
  FBinary := TDictionary<string, TBytes>.Create;
end;

destructor TXcomMemoryFiles.Destroy;
begin
  FBinary.Free;
  FFiles.Free;
  inherited Destroy;
end;

procedure TXcomMemoryFiles.Add(const AName, AText: string);
begin
  FFiles.AddOrSetValue(AName, AText);
end;

function TXcomMemoryFiles.TryReadAllBytes(const AFileName: string; out ABytes: TBytes): Boolean;
var
  LText: string;
begin
  Result := FFiles.TryGetValue(AFileName, LText);
  if Result then
    ABytes := TEncoding.UTF8.GetBytes(LText);
end;

function TXcomMemoryFiles.FolderContents(const AVirtualFolder: string): TArray<string>;
var
  LName: string;
  LList: TList<string>;
begin
  LList := TList<string>.Create;
  try
    for LName in FFiles.Keys do
      if (Copy(LName, 1, Length(AVirtualFolder)) = AVirtualFolder) then
        LList.Add(Copy(LName, Length(AVirtualFolder) + 1, MaxInt));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

procedure TXcomMemoryFiles.AddBytes(const AName: string; const ABytes: TBytes);
begin
  FBinary.AddOrSetValue(AName, ABytes);
end;

function TXcomMemoryFiles.LoadBytes(const AVirtualFile: string): TBytes;
begin
  if not FBinary.TryGetValue(AVirtualFile, Result) then
    raise EXcomModException.CreateFmt('File %s not found', [AVirtualFile]);
end;

function TXcomMemoryFiles.LoadYaml(const AVirtualFile: string): IYamlNode;
var
  LText: string;
begin
  if not FFiles.TryGetValue(AVirtualFile, LText) then
    raise EXcomModException.CreateFmt('File %s not found', [AVirtualFile]);
  Result := TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(LText));
end;

{ TTestXcomRuleset }

procedure TTestXcomRuleset.Setup;
begin
  FFiles := TXcomMemoryFiles.Create;
  FFilesRef := FFiles;
  FRuleset := TXcomRuleset.Create(TXcomFixedShared.Create, FFiles);
  FRuleset.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000),
    TXcomModData.Make('extra', 1000, 500)), 0);
end;

procedure TTestXcomRuleset.TearDown;
begin
  FRuleset.Free;
  FFilesRef := nil;
end;

procedure TTestXcomRuleset.Load(const AText: string);
begin
  // the tests write the top level as a flow map without its braces
  FRuleset.LoadFile(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('{' + AText + '}')));
end;

function TTestXcomRuleset.LoadFails(const AText: string): string;
begin
  Result := '';
  try
    Load(AText);
  except
    on LError: Exception do
      Result := LError.Message;
  end;
end;

procedure TTestXcomRuleset.DovrebbeCaricareUnOggettoConElencoDiOrdineAutomatico;
var
  LItem: TXcomRuleItem;
begin
  Load('items: [{type: STR_A, costBuy: 5, bigSprite: 150, handSprite: 7, requires: [R1]}, {type: STR_B, listOrder: 3}]');
  Assert.AreEqual(2, FRuleset.Items.Count);
  LItem := FRuleset.Items.Find('STR_A');
  Assert.AreEqual(100, LItem.ListOrder, 'ordine automatico');
  Assert.AreEqual(5, LItem.BuyCost);
  Assert.AreEqual(150, LItem.BigSprite, 'sprite sopra i condivisi: offset del mod 0');
  Assert.AreEqual(7, LItem.HandSprite, 'sprite fra i condivisi: nessun offset');
  Assert.AreEqual(3, FRuleset.Items.Find('STR_B').ListOrder, 'ordine esplicito');
  Assert.AreEqual('STR_A', LItem.Name);
  Assert.AreEqual(1, Length(LItem.Requirements));
  // un oggetto ricaricato resta lo stesso e non cambia l'ordine
  Load('items: [{type: STR_A, costBuy: 9}]');
  Assert.AreEqual(2, FRuleset.Items.Count);
  Assert.AreEqual(9, FRuleset.Items.Find('STR_A').BuyCost);
end;

procedure TTestXcomRuleset.DovrebbeSollevareErroreSeUnArmaNonHaMunizioni;
begin
  Assert.Contains(LoadFails('items: [{type: STR_GUN, battleType: 1}]'), 'has clip size 0 and no ammo defined');
  Assert.AreEqual('', LoadFails('items: [{type: STR_GUN2, battleType: 1, clipSize: -1}]'));
end;

procedure TTestXcomRuleset.DovrebbeCalcolareIlRaggioDiEsplosione;
begin
  Load('items: [{type: INC, damageType: 2, power: 60}, {type: HE, damageType: 3, power: 500}, ' +
    '{type: FIXED, damageType: 3, blastRadius: 4}, {type: AP, damageType: 1, power: 40, maxRange: 50000, ' +
    'battleType: 3, clipSize: 1, twoHanded: true}, {type: PISTOL, battleType: 1, clipSize: 1}]');
  Assert.AreEqual(3, FRuleset.Items.Find('INC').ExplosionRadius, 'incendiario: potenza / 30 + 1');
  Assert.AreEqual(11, FRuleset.Items.Find('HE').ExplosionRadius, 'al massimo 11');
  Assert.AreEqual(4, FRuleset.Items.Find('FIXED').ExplosionRadius);
  Assert.AreEqual(0, FRuleset.Items.Find('AP').ExplosionRadius);
  Assert.IsTrue(FRuleset.Items.Find('AP').IsRifle);
  Assert.IsFalse(FRuleset.Items.Find('AP').IsPistol);
  Assert.IsTrue(FRuleset.Items.Find('PISTOL').IsPistol);
  Assert.AreEqual(Integer(Int64(50000) * 50000), FRuleset.Items.Find('AP').MaxRangeSquared, 'il prodotto torna a capo');
end;

procedure TTestXcomRuleset.DovrebbeCancellareUnaRegolaConDelete;
begin
  Load('items: [{type: STR_A}, {type: STR_B}]');
  Load('items: [{delete: STR_A}, {delete: STR_MISSING}, {name: senzaChiave}]');
  Assert.AreEqual(1, FRuleset.Items.Count);
  Assert.IsNull(FRuleset.Items.Find('STR_A'));
  Assert.AreEqual(1, Length(FRuleset.Items.Index));
  Assert.AreEqual('STR_B', FRuleset.Items.Index[0]);
  FRuleset.Items.Delete('STR_B');
  Assert.AreEqual(0, FRuleset.Items.Count);
  Assert.AreEqual('STR_C', FRuleset.Items.GetOrCreate('STR_C').ItemType);
  Assert.AreEqual(0, Length(FRuleset.Items.Index), 'GetOrCreate non mette nell''indice');
  FRuleset.Items.Add('STR_D', TXcomRuleItem.Create('STR_D'));
  FRuleset.Items.Add('STR_D', TXcomRuleItem.Create('STR_D2'));
  Assert.AreEqual('STR_D2', FRuleset.Items.Find('STR_D').ItemType);
  Assert.AreEqual(1, Length(FRuleset.Items.Index));
  FRuleset.Items.SetIndex(nil);
  Assert.AreEqual(0, Length(FRuleset.Items.Index));
end;

procedure TTestXcomRuleset.DovrebbeSommareGliOffsetDelModCorrente;
begin
  FRuleset.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000),
    TXcomModData.Make('extra', 1000, 500)), 1);
  Load('crafts: [{type: STR_C, sprite: 9, marker: 3}], facilities: [{type: STR_F, spriteShape: 2}], ' +
    'ufos: [{type: STR_U, marker: 20}], craftWeapons: [{type: STR_W, sprite: 7}]');
  Assert.AreEqual(1009, FRuleset.Crafts.Find('STR_C').Sprite, 'sprite sopra 4');
  Assert.AreEqual(3, FRuleset.Crafts.Find('STR_C').Marker, 'marker fino a 8');
  Assert.AreEqual(1020, FRuleset.Ufos.Find('STR_U').Marker);
  Assert.AreEqual(1007, FRuleset.CraftWeapons.Find('STR_W').Sprite);
  Assert.AreEqual(2, FRuleset.Facilities.Find('STR_F').SpriteShape);
  Assert.AreEqual(100, FRuleset.Crafts.Find('STR_C').ListOrder);
  Assert.AreEqual(100, FRuleset.Facilities.Find('STR_F').ListOrder);
  Assert.AreEqual('STR_U', FRuleset.Ufos.Find('STR_U').UfoType);
  Assert.AreEqual(2, FRuleset.Ufos.Find('STR_U').Radius, 'dimensione predefinita: molto piccolo');
end;

procedure TTestXcomRuleset.DovrebbeCaricareUnaCorazzaConCadavereEModificatoriDiDanno;
var
  LArmor: TXcomArmor;
begin
  Load('armors: [{type: A1, corpseItem: CORPSE, damageModifier: [0.5, 2], loftemps: 3, stats: {tu: 5}, ' +
    'spriteFaceColor: [1, 2]}, {type: A2, corpseBattle: [C1, C2], loftempsSet: [1, 2]}]');
  LArmor := FRuleset.Armors.Find('A1');
  Assert.AreEqual('CORPSE', LArmor.CorpseGeoscape);
  Assert.AreEqual(1, Length(LArmor.CorpseBattlescape));
  Assert.AreEqual(Single(0.5), LArmor.DamageModifier[0]);
  Assert.AreEqual(Single(2), LArmor.DamageModifier[1]);
  Assert.AreEqual(Single(1), LArmor.DamageModifier[2]);
  Assert.AreEqual(1, Length(LArmor.LoftempsSet));
  Assert.AreEqual(5, LArmor.Stats.TimeUnits);
  Assert.AreEqual(2, Length(LArmor.FaceColor));
  Assert.IsTrue(LArmor.HasInventory);
  Assert.AreEqual('C1', FRuleset.Armors.Find('A2').CorpseGeoscape);
  Assert.AreEqual(2, Length(FRuleset.Armors.Find('A2').LoftempsSet));
end;

procedure TTestXcomRuleset.DovrebbeSollevareErroreSeLaCorazzaNonHaCadaveri;
begin
  Assert.Contains(LoadFails('armors: [{type: A1, corpseBattle: []}]'), 'empty corpseBattle');
end;

procedure TTestXcomRuleset.DovrebbeSollevareErroreSeUnUnitaESuperaLAltezza;
var
  LUnit: TXcomRuleUnit;
begin
  Assert.Contains(LoadFails('units: [{type: U1, standHeight: 20, floatHeight: 6}]'), 'may not exceed 25');
  Load('units: [{type: U2, standHeight: 20, floatHeight: 5, stats: {tu: 9}, builtInWeaponSets: [[A, B]], ' +
    'builtInWeapons: [C], deathSound: [1, 2], race: R}]');
  LUnit := FRuleset.Units.Find('U2');
  Assert.AreEqual(2, Length(LUnit.BuiltInWeapons));
  Assert.AreEqual(2, Length(LUnit.DeathSounds));
  Assert.AreEqual(9, LUnit.Stats.TimeUnits);
  Assert.AreEqual(30, LUnit.EnergyRecovery);
  Assert.AreEqual(0, Length(FRuleset.Units.Index), 'le unita non hanno indice');
end;

procedure TTestXcomRuleset.DovrebbeCaricareISoldatiEIPoolDeiNomi;
var
  LSoldier: TXcomRuleSoldier;
begin
  FFiles.Add('SoldierName/A.nam', 'maleFirst: [Al, Bo]' + sLineBreak + 'maleLast: [Cy]' + sLineBreak +
    'lookWeights: [1, 2, 3]' + sLineBreak + 'femaleFrequency: 40');
  FFiles.Add('SoldierName/B.nam', 'maleFirst: [Di]' + sLineBreak + 'femaleFirst: [Eve]');
  FFiles.Add('SoldierName/ignored.txt', 'x');
  Load('soldiers: [{type: XCOM, soldierNames: [SoldierName/], minStats: {tu: 50}, deathMale: 3}]');
  LSoldier := FRuleset.Soldiers.Find('XCOM');
  Assert.IsNotNull(LSoldier);
  Assert.AreEqual('STR_SOLDIER', LSoldier.SoldierType, 'XCOM diventa STR_SOLDIER');
  Assert.AreEqual(2, LSoldier.Names.Count, 'solo i .nam della cartella');
  Assert.AreEqual(2, Length(LSoldier.Names[0].FemaleFirst), 'senza nomi femminili prende quelli maschili');
  Assert.AreEqual(6, LSoldier.Names[0].TotalWeight);
  Assert.AreEqual(40, LSoldier.Names[0].FemaleFrequency);
  Assert.AreEqual(1, Length(LSoldier.Names[1].FemaleFirst));
  Assert.AreEqual(50, LSoldier.MinStats.TimeUnits);
  Load('soldiers: [{type: XCOM, soldierNames: [delete, SoldierName/B.nam]}]');
  Assert.AreEqual(1, LSoldier.Names.Count);
  Assert.AreEqual(50, LSoldier.FemaleFrequency);
  Assert.AreEqual(20, LSoldier.Value);
end;

procedure TTestXcomRuleset.DovrebbeSollevareErroreSeISoldatiNonHannoFile;
var
  LOther: TXcomRuleset;
begin
  LOther := TXcomRuleset.Create(TXcomFixedShared.Create);
  try
    LOther.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000)), 0);
    try
      LOther.LoadFile(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('soldiers: [{type: S, soldierNames: [a.nam]}]')));
      Assert.Fail('doveva sollevare');
    except
      on LError: EXcomModException do
        Assert.Contains(LError.Message, 'has no files');
    end;
    try
      LOther.LoadFile(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('soldiers: [{type: S, soldierNames: [dir/]}]')));
      Assert.Fail('doveva sollevare');
    except
      on LError: EXcomModException do
        Assert.Contains(LError.Message, 'has no files');
    end;
  finally
    LOther.Free;
  end;
end;

procedure TTestXcomRuleset.DovrebbeCaricareIComandiDiUnoScriptDiMappa;
var
  LList: TObjectList<TXcomMapScript>;
begin
  Load('mapScripts: [{type: DEFAULT, commands: [{type: addBlock, size: [2, 3, 1], groups: 4, freqs: [3], ' +
    'maxUses: 2, rects: [[0, 0, 4, 4]], conditionals: [1, 2], label: -5}, {type: addLine, direction: V, ' +
    'blocks: [1, 2], freqs: [1, 2, 3]}, {type: addCraft}, {type: resize, size: 5}, ' +
    '{type: digTunnel, direction: b, tunnelData: {level: 2, MCDReplacements: [{type: wall, set: 1, entry: 2}]}}, ' +
    '{type: fillArea, conditionals: 7, UFOName: UFO1}, {type: removeBlock}, {type: checkBlock}, {type: addUFO}]}]');
  Assert.IsTrue(FRuleset.MapScripts.TryGetValue('DEFAULT', LList));
  Assert.AreEqual(9, LList.Count);
  Assert.AreEqual(2, LList[0].SizeX);
  Assert.AreEqual(3, LList[0].SizeY);
  Assert.AreEqual(1, LList[0].SizeZ);
  Assert.AreEqual(5, LList[0].ScriptLabel, 'il valore assoluto');
  Assert.AreEqual(1, Length(LList[0].Rects));
  Assert.AreEqual(3, LList[0].Frequencies[0]);
  Assert.AreEqual(2, LList[0].MaxUses[0] + 0);
  Assert.AreEqual(TXcomMapScript.MD_VERTICAL, LList[1].Direction);
  Assert.AreEqual(2, Length(LList[1].Blocks));
  Assert.AreEqual(1, LList[2].Groups[0], 'addCraft: gruppo 1 di default');
  Assert.AreEqual(5, LList[3].SizeX);
  Assert.AreEqual(5, LList[3].SizeY);
  Assert.AreEqual(TXcomMapScript.MD_BOTH, LList[4].Direction);
  Assert.AreEqual(2, LList[4].TunnelData.Level);
  Assert.AreEqual(1, LList[4].TunnelData.Replacements.Count);
  Assert.AreEqual('UFO1', LList[5].UfoName);
  Assert.AreEqual(7, LList[5].Conditionals[0]);
  // lo stesso nome senza comandi svuota la lista
  Load('mapScripts: [{type: DEFAULT}]');
  Assert.AreEqual(0, LList.Count);
  Load('mapScripts: [{type: OTHER, delete: DEFAULT}]');
  Assert.AreEqual(0, LList.Count);
end;

procedure TTestXcomRuleset.DovrebbeSollevareErroriNeiComandiDiMappa;
begin
  Assert.Contains(LoadFails('mapScripts: [{type: X, commands: [{type: nope}]}]'), 'Unknown command: nope');
  Assert.Contains(LoadFails('mapScripts: [{type: X, commands: [{name: nope}]}]'), 'Missing command type.');
  Assert.Contains(LoadFails('mapScripts: [{type: X, commands: [{type: addBlock, direction: Q}]}]'),
    'direction must be');
  Assert.Contains(LoadFails('mapScripts: [{type: X, commands: [{type: digTunnel}]}]'), 'no direction defined');
  Assert.Contains(LoadFails('mapScripts: [{type: X, commands: [{type: addLine}]}]'), 'no direction defined');
end;

procedure TTestXcomRuleset.DovrebbeCaricareGliArticoliDellUfopaediaDiOgniTipo;
var
  LArticle: TXcomArticleDefinition;
begin
  Load('ufopaedia: [{id: A1, type_id: 1, section: S1, image_id: IMG, rect_stats: {x: 1, y: 2, width: 3, height: 4}, ' +
    'text: T}, {id: A2, type_id: 2, section: S1, image_id: I2}, {id: A3, type_id: 3, weapon: W, section: S2}, ' +
    '{id: A4, type_id: 4, section: S2}, {id: A5, type_id: 5, section: STR_NOT_AVAILABLE}, {id: A6, type_id: 6}, ' +
    '{id: A7, type_id: 7, text_width: 99, section: S3}, {id: A8, type_id: 8, section: S3}, {id: A9, type_id: 9, ' +
    'section: S3}, {id: A10, type_id: 14, section: S4, listOrder: 5}, {delete: A5}, {delete: NOPE}, {x: 1}]');
  Assert.AreEqual(9, FRuleset.Articles.Count);
  LArticle := FRuleset.Articles.Find('A1');
  Assert.AreEqual(3, LArticle.RectStats.Width);
  Assert.AreEqual(2, LArticle.RectStats.Y);
  Assert.AreEqual('IMG', LArticle.ImageId);
  Assert.AreEqual('A1', LArticle.Title);
  Assert.AreEqual('W', FRuleset.Articles.Find('A3').Weapon);
  Assert.AreEqual(99, FRuleset.Articles.Find('A7').TextWidth);
  LArticle := FRuleset.Articles.Find('A10');
  Assert.AreEqual(14, LArticle.Kind, 'la classe TFTD prende il tipo dal nodo');
  Assert.AreEqual(157, LArticle.TextWidth);
  Assert.AreEqual(5, LArticle.ListOrder);
  Assert.AreEqual(5, FRuleset.ArticleSectionIndex.Count, 'S1, S2, S3, S4 e la sezione senza nome di A6');
end;

procedure TTestXcomRuleset.DovrebbeSollevareErroreSeUnArticoloHaUnTipoSconosciuto;
begin
  Assert.Contains(LoadFails('ufopaedia: [{id: A1, type_id: 99}]'), 'Unknown Ufopaedia type_id');
  Assert.AreNotEqual('', LoadFails('ufopaedia: [{id: A1}]'), 'senza type_id e'' un errore di conversione');
end;

procedure TTestXcomRuleset.DovrebbeOrdinareGliIndiciPerOrdineDiElenco;
begin
  Load('items: [{type: C, listOrder: 30}, {type: A, listOrder: 10}, {type: B, listOrder: 10}, {type: L, listOrder: 5}], ' +
    'craftWeapons: [{type: W1, launcher: C}, {type: W2, launcher: A}], armors: [{type: AR1, storeItem: C}, ' +
    '{type: AR2}, {type: AR3, storeItem: A}], research: [{name: R1, listOrder: 9}, {name: R2, listOrder: 1}], ' +
    'ufopaedia: [{id: X1, type_id: 8, section: S2, listOrder: 7}, {id: X2, type_id: 8, section: S1, listOrder: 9}, ' +
    '{id: X3, type_id: 8, section: S2, listOrder: 2}]');
  FRuleset.SortLists;
  Assert.AreEqual('L,A,B,C', string.Join(',', FRuleset.Items.Index), 'iguali nell''ordine di arrivo');
  Assert.AreEqual('W2,W1', string.Join(',', FRuleset.CraftWeapons.Index), 'per l''ordine del lanciatore');
  Assert.AreEqual('AR2,AR3,AR1', string.Join(',', FRuleset.Armors.Index), 'senza oggetto prima di tutto');
  Assert.AreEqual('R2,R1', string.Join(',', FRuleset.Research.Index));
  Assert.AreEqual('X3,X1,X2', string.Join(',', FRuleset.Articles.Index), 'per sezione e poi per ordine');
  Assert.AreEqual('S2,S1', string.Join(',', FRuleset.ArticleSectionIndex.ToArray));
  Load('craftWeapons: [{type: W3, launcher: MISSING}]');
  try
    FRuleset.SortLists;
    Assert.Fail('doveva sollevare');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'not found');
  end;
end;

procedure TTestXcomRuleset.DovrebbeCaricareLeAltreSezioniDelFile;
begin
  Load('MCDPatches: [{type: M1, data: [{MCDIndex: 3, bigWall: 1, TUWalk: 2, noFloor: true, LOFTS: [1, 2], ' +
    'stopLOS: false, objectType: 4}]}], extraSprites: [{type: S1, files: {1: a.png, 0: b.png}, width: 5, ' +
    'singleImage: true}, {type: TEXTURE.DAT, files: {0: c.png}}, {delete: S1}], ' +
    'extraSounds: [{type: SND, files: {2: x.wav}}], extraStrings: [{type: en, strings: {A: a, B: {one: b1, ' +
    'other: b2}, C: [x]}}], statStrings: [{string: X, tu: [10, 20], psiTraining: [1], health: [5]}], ' +
    'interfaces: [{type: I1, palette: P, elements: [{id: e1, size: [3, 4], pos: [1, 2], color: 7}, {id: e2}]}], ' +
    'cutscenes: [{type: V1, videos: [a.fli], audioTracks: [t], slideshow: {musicId: M, slides: [{imagePath: i.png, ' +
    'captionPos: [1, 2]}]}}], converter: {offsets: {a: 1}, markers: [m]}, ' +
    'constants: {doorSound: 5, windowPopup: [4, 5, 6, 7], fireDamageRange: [1], goodDebriefingMusic: GM, ' +
    'smokeOffset: 9, explosionOffset: 3}, ' +
    'costEngineer: 11, alienFuel: [STR_FUEL, 7], difficultyCoefficient: [5, 6], aimAndArmorMultipliers: [0.25], ' +
    'statGrowthMultipliers: {tu: 3}, alienItemLevels: [[1, 2], [3]], startingBase: {items: {A: 1}}, ' +
    'startingTime: {year: 2000}, fontName: F, difficultyDemigod: true, defeatScore: 8');
  Assert.AreEqual(1, FRuleset.McdPatches.Count);
  Assert.AreEqual(1, Length(FRuleset.McdPatches.Value(0).Numbers('bigWall')));
  Assert.AreEqual(1, Length(FRuleset.McdPatches.Value(0).NoFloors));
  Assert.AreEqual(0, Length(FRuleset.McdPatches.Value(0).Numbers('desconocido')));
  Assert.AreEqual(1, FRuleset.ExtraSprites.Count, 'S1 cancellato, resta TEXTURE.DAT');
  Assert.AreEqual(1, FRuleset.ExtraSounds.Count);
  Assert.AreEqual(3, FRuleset.ExtraStrings.Value(0).Strings.Count);
  Assert.AreEqual(3, Length(FRuleset.StatStrings[0].Conditions), 'tu, health, psiTraining: nell''ordine del C++');
  Assert.IsTrue(FRuleset.StatStrings[0].Conditions[0].IsMet(15, False));
  Assert.IsFalse(FRuleset.StatStrings[0].Conditions[0].IsMet(25, False));
  Assert.IsTrue(FRuleset.StatStrings[0].Conditions[2].IsMet(1, False), 'psiTraining sempre vero');
  Assert.IsFalse(FRuleset.StatStrings[0].Conditions[1].IsMet(1, False), 'health: minimo 5');
  Assert.AreEqual(2, FRuleset.Interfaces.Find('I1').Elements.Count);
  Assert.AreEqual(MaxInt, FRuleset.Interfaces.Find('I1').Elements.Value(1).W);
  Assert.AreEqual(1, Length(FRuleset.Videos.Find('V1').Slides));
  Assert.AreEqual(320, FRuleset.Videos.Find('V1').Slides[0].W);
  Assert.AreEqual(30, FRuleset.Videos.Find('V1').SlideshowHeader.TransitionSeconds);
  Assert.AreEqual(1, Length(FRuleset.Converter.List('markers')));
  Assert.AreEqual(5, FRuleset.Constants.DoorOpen);
  Assert.AreEqual(6, FRuleset.Constants.WindowPopup[2]);
  Assert.AreEqual(1, FRuleset.Constants.FireDamageRange[0]);
  Assert.AreEqual(10, FRuleset.Constants.FireDamageRange[1]);
  Assert.AreEqual(9, FRuleset.Constants.SmokeOffset);
  Assert.AreEqual(3, FRuleset.Constants.ExplosionOffset);
  Assert.AreEqual(11, FRuleset.Settings.CostEngineer);
  Assert.AreEqual(7, FRuleset.Settings.AlienFuelQuantity);
  Assert.AreEqual(6, FRuleset.Settings.StatAdjustment[1].GrowthMultiplier);
  Assert.AreEqual(Double(0.25), FRuleset.Settings.StatAdjustment[0].AimAndArmorMultiplier);
  Assert.AreEqual(3, FRuleset.Settings.StatAdjustment[4].StatGrowth.TimeUnits);
  Assert.AreEqual(2, Length(FRuleset.Settings.AlienItemLevels));
  Assert.AreEqual(1, FRuleset.StartingBase.Count);
  Assert.IsTrue(Assigned(FRuleset.StartingTime));
  Assert.IsTrue(FRuleset.Settings.DifficultyDemigod);
  Load('constants: [{doorSound: 6}, {doorSound: 7}]');
  Assert.AreEqual(7, FRuleset.Constants.DoorOpen);
end;

procedure TTestXcomRuleset.DovrebbeUnireLeDistribuzioniDelleRazzeEScartareQuelleVuote;
var
  LMission: TXcomRuleAlienMission;
begin
  Load('alienMissions: [{type: M1, objective: 1, waves: [{ufo: U, count: 2, trajectory: T, timer: 30, objective: true}], ' +
    'missionWeights: {0: 5, 4: 9}, raceWeights: {0: {A: 1}, 6: {B: 2}, 3: {C: 0}}}]');
  LMission := FRuleset.AlienMissions.Find('M1');
  Assert.AreEqual(2, LMission.RaceMonthCount, 'il mese con peso 0 e'' vuoto e si scarta');
  Assert.AreEqual(1, LMission.WaveCount);
  Assert.AreEqual(5, LMission.GetWeight(3));
  Assert.AreEqual(9, LMission.GetWeight(10));
  Load('alienMissions: [{type: M1, raceWeights: {0: {D: 3}}}]');
  Assert.AreEqual(2, LMission.RaceMonthCount);
  Assert.AreEqual(2, Integer(LMission.RaceOptions(0).Choices.Count), 'A e D: unite');
  Assert.AreEqual(1, LMission.GetWeight(3) - 4, 'i pesi si sostituiscono solo se ci sono');
  LMission := TXcomRuleAlienMission.Create('X');
  try
    Assert.AreEqual(1, LMission.GetWeight(5), 'senza pesi vale 1');
    Assert.AreEqual('', LMission.GenerateRace(3, nil), 'senza razze non c''e'' nulla da scegliere');
  finally
    LMission.Free;
  end;
end;

procedure TTestXcomRuleset.DovrebbeControllareLeMissioniDegliScript;
begin
  Load('alienMissions: [{type: SCORE, objective: 0}, {type: SITE, objective: 3}], regions: [{type: R1, ' +
    'missionWeights: {SCORE: 1}}]');
  Load('missionScripts: [{type: S1, missionWeights: {0: {SCORE: 1}}}]');
  FRuleset.ValidateMissions;
  Assert.IsFalse(FRuleset.MissionScripts.Find('S1').SiteType);
  Load('missionScripts: [{type: S2, missionWeights: {0: {SITE: 1}}}]');
  FRuleset.ValidateMissions;
  Assert.IsTrue(FRuleset.MissionScripts.Find('S2').SiteType);
  Load('missionScripts: [{type: S3, missionWeights: {0: {SITE: 1, SCORE: 1}}}]');
  try
    FRuleset.ValidateMissions;
    Assert.Fail('doveva sollevare');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'cannot mix terror/non-terror');
  end;
  FRuleset.MissionScripts.Delete('S3');
  Load('missionScripts: [{type: S4, missionWeights: {0: {NOPE: 1}}}]');
  try
    FRuleset.ValidateMissions;
    Assert.Fail('doveva sollevare');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'not defined');
  end;
  FRuleset.MissionScripts.Delete('S4');
  Load('regions: [{type: R2, missionWeights: {SITE: 1}}]');
  try
    FRuleset.ValidateMissions;
    Assert.Fail('doveva sollevare');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'Terror mission can only be invoked via missionScript');
  end;
  FRuleset.Regions.Delete('R2');
  Load('regions: [{type: R3, missionWeights: {GHOST: 1}}]');
  try
    FRuleset.ValidateMissions;
    Assert.Fail('doveva sollevare');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'Error with MissionWeights');
  end;
  Assert.Contains(LoadFails('missionScripts: [{type: S5, maxRuns: 2}]'), 'no varName provided');
end;

procedure TTestXcomRuleset.DovrebbeCaricareIMod;
var
  LLoader: TXcomModLoader;
  LRuleset: TXcomRuleset;
  LFiles: TXcomMemoryFiles;
  LRef: IInterface;
begin
  LFiles := TXcomMemoryFiles.Create;
  LRef := LFiles;
  LFiles.Add('m/a.rul', 'items: [{type: A, bigSprite: 150}]');
  LFiles.Add('m/b.rul', 'items: [{type: B}]');
  LFiles.Add('x/a.rul', 'items: [{type: C, bigSprite: 150}, {delete: B}]');
  LFiles.Add('bad.rul', 'items: [{type: A');
  LFiles.Add('mission.rul', 'missionScripts: [{type: S, missionWeights: {0: {NOPE: 1}}}]');
  LLoader := TXcomModLoader.Create(TYamlFactory.CreateParser(LFiles), TXcomFixedShared.Create, LFiles);
  try
    LLoader.LoadAll(TArray<TXcomModSource>.Create(
      TXcomModSource.Make('master', 1, nil)));
    Assert.Fail('master e'' un nome riservato');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'this mod name is already used');
  end;
  LRuleset := LLoader.LoadAll(TArray<TXcomModSource>.Create(
    TXcomModSource.Make('base', 1, TArray<string>.Create('m/a.rul', 'm/b.rul')),
    TXcomModSource.Make('extra', 2, TArray<string>.Create('x/a.rul'))));
  try
    Assert.AreEqual(2, LRuleset.Items.Count);
    Assert.AreEqual(150, LRuleset.Items.Find('A').BigSprite, 'il primo mod comincia da 0');
    Assert.AreEqual(1150, LRuleset.Items.Find('C').BigSprite, 'il secondo da 1000');
    Assert.AreEqual('A,C', string.Join(',', LRuleset.Items.Index));
  finally
    LRuleset.Free;
  end;
  try
    LLoader.LoadAll(TArray<TXcomModSource>.Create(TXcomModSource.Make('base', 1, TArray<string>.Create('m/a.rul')),
      TXcomModSource.Make('base', 1, nil)));
    Assert.Fail('nome ripetuto');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'already used');
  end;
  try
    LLoader.LoadAll(TArray<TXcomModSource>.Create(TXcomModSource.Make('base', 1, TArray<string>.Create('bad.rul'))));
    Assert.Fail('YAML sbagliato');
  except
    on LError: EXcomModException do
    begin
      Assert.Contains(LError.Message, 'failed to load ''base''');
      Assert.Contains(LError.Message, 'bad.rul: ');
    end;
  end;
  try
    LLoader.LoadAll(TArray<TXcomModSource>.Create(TXcomModSource.Make('base', 1, TArray<string>.Create('mission.rul'))));
    Assert.Fail('missione non definita');
  except
    on LError: EXcomModException do
      Assert.Contains(LError.Message, 'not defined');
  end;
  LLoader.Free;
end;

procedure TTestXcomRuleset.DovrebbeCaricareIlFileDelleRisorse;
var
  LLoader: TXcomModLoader;
  LRuleset: TXcomRuleset;
  LFiles: TXcomMemoryFiles;
  LRef: IInterface;
begin
  LFiles := TXcomMemoryFiles.Create;
  LRef := LFiles;
  LFiles.Add('res.yml', '{soundDefs: [{type: S1, soundRanges: [[1, 3], [7], 5], sounds: [9, x], file: A.CAT}, {name: x}], ' +
    'transparencyLUTs: [{colors: [[1, 2, 3, 4], [5, 6]]}, {colors: [[9, 9, 9]]}]}');
  LFiles.Add('toomany.yml', '{transparencyLUTs: [{colors: [[1], [2], [3]]}]}');
  LFiles.Add('badlut.yml', '{transparencyLUTs: [{colors: 3}]}');
  LLoader := TXcomModLoader.Create(TYamlFactory.CreateParser(LFiles), TXcomFixedShared.Create, LFiles);
  try
    LRuleset := LLoader.LoadAll(TArray<TXcomModSource>.Create(TXcomModSource.Make('base', 1, nil, 'res.yml')));
    try
      Assert.AreEqual(7, Length(LRuleset.SoundDefinitions.Find('S1').SoundList),
        '1, 2, 3 e due elementi che non sono una coppia (0), poi 9 e -1 per "x"');
      Assert.AreEqual('A.CAT', LRuleset.SoundDefinitions.Find('S1').CatFile);
      Assert.AreEqual(10, Length(LRuleset.Transparencies), '1000 / 100');
      Assert.AreEqual(1, Integer(LRuleset.Transparencies[0].R));
      Assert.AreEqual(4, Integer(LRuleset.Transparencies[0].Unused));
      Assert.AreEqual(2, Integer(LRuleset.Transparencies[1].Unused), 'il quarto numero manca: 2');
      Assert.AreEqual(9, Integer(LRuleset.Transparencies[2].R));
    finally
      LRuleset.Free;
    end;
    try
      LLoader.LoadAll(TArray<TXcomModSource>.Create(TXcomModSource.Make('base', 0, nil, 'toomany.yml')));
      Assert.Fail('troppi colori');
    except
      on LError: EXcomModException do
        Assert.Contains(LError.Message, 'transparencyLUTs mod limit reach');
    end;
    try
      LLoader.LoadAll(TArray<TXcomModSource>.Create(TXcomModSource.Make('base', 1, nil, 'badlut.yml')));
      Assert.Fail('colors non e'' una lista');
    except
      on LError: EXcomModException do
        Assert.Contains(LError.Message, 'unknown transparencyLUTs node type');
    end;
  finally
    LLoader.Free;
  end;
end;

procedure TTestXcomRuleset.DovrebbeLeggereLeMappeConNumeriEIlRecordDelleStatistiche;
var
  LMap: TXcomIntStringMap;
  LFirst, LSecond, LSum: TXcomUnitStats;
  LNode: IYamlNode;
begin
  LMap := TXcomIntStringMap.Create;
  try
    LNode := TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('{files: {5: e, 2: b, 9: z}, other: 3}'));
    LMap.ReadField(LNode, 'files');
    Assert.AreEqual('2:b,5:e,9:z', LMap.ToText, 'in ordine di numero');
    LMap.ReadField(LNode, 'other');
    LMap.ReadField(LNode, 'missing');
    Assert.AreEqual(3, LMap.Count, 'un campo che non e'' una mappa non cambia nulla');
    LMap.SetValue(5, 'new');
    Assert.AreEqual('new', LMap.Value(1));
    Assert.AreEqual(2, LMap.Key(0));
    LMap.ReadField(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('{files: {1: a}}')), 'files');
    Assert.AreEqual('1:a', LMap.ToText, 'una mappa nuova sostituisce');
    Assert.WillRaise(
      procedure
      begin
        LMap.ReadField(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('{files: {x: a}}')), 'files');
      end);
  finally
    LMap.Free;
  end;
  LFirst := Default(TXcomUnitStats);
  LFirst.TimeUnits := 10;
  LFirst.Melee := 3;
  LSecond := Default(TXcomUnitStats);
  LSecond.TimeUnits := 5;
  LSecond.Health := 7;
  LSum := LFirst + LSecond;
  Assert.AreEqual(15, LSum.TimeUnits);
  Assert.AreEqual(7, LSum.Health);
  LSum := LFirst - LSecond;
  Assert.AreEqual(5, LSum.TimeUnits);
  Assert.AreEqual(-7, LSum.Health);
  LSum := -LFirst;
  Assert.AreEqual(-10, LSum.TimeUnits);
  Assert.AreEqual(-3, LSum.Melee);
  LFirst.Merge(LSecond);
  Assert.AreEqual(5, LFirst.TimeUnits, 'il valore non zero sostituisce');
  Assert.AreEqual(3, LFirst.Melee, 'zero lascia com''era');
  Assert.AreEqual(7, LFirst.Health);
  LNode := TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes('{stats: {tu: 4, psiSkill: 2}, text: x}'));
  LSum := TXcomUnitStatsReader.Read(LNode, 'stats', LFirst);
  Assert.AreEqual(4, LSum.TimeUnits);
  Assert.AreEqual(0, LSum.Melee, 'decodificato in uno nuovo');
  Assert.AreEqual(3, TXcomUnitStatsReader.Read(LNode, 'text', LFirst).Melee, 'non e'' una mappa: il predefinito');
  Assert.AreEqual(3, TXcomUnitStatsReader.Read(LNode, 'missing', LFirst).Melee);
end;

procedure TTestXcomRuleset.DovrebbeSollevareErroriNelleMissioniAliene;
begin
  Assert.AreNotEqual('', LoadFails('alienMissions: [{type: M, waves: [3]}]'), 'un''ondata deve essere una mappa');
  Assert.AreNotEqual('', LoadFails('alienMissions: [{type: M, missionWeights: {a: 1}}]'));
  Load('alienMissions: [{type: M2, missionWeights: {1: 2}}]');
  Load('alienMissions: [{type: M2, missionWeights: {3: 4}}]');
  Assert.AreEqual(1, FRuleset.AlienMissions.Find('M2').WeightMonthCount, 'i pesi nuovi sostituiscono');
  Assert.AreEqual(3, Integer(FRuleset.AlienMissions.Find('M2').WeightMonth(0)));
  Assert.AreEqual(0, FRuleset.AlienMissions.Find('M2').GetWeight(1), 'prima del primo mese vale 0');
  Assert.AreNotEqual('', LoadFails('alienMissions: [{type: M3, missionWeights: {1: x}}]'));
  Assert.AreEqual(0, FRuleset.AlienMissions.Find('M3').WeightMonthCount, 'un errore lascia i pesi com''erano');
end;

end.
