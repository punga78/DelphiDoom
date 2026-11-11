{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ufopaedia library - rules made from text, }
{  resources and a navigator made by hand                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomUfopaedia.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.RuleInterface,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Intf;

type
  /// <summary>Every set has 100 shared sprites and 20 shared sounds</summary>
  TUfopaediaFixedShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  /// <summary>The rules of a test: a small ruleset with an article of every kind and the rules they describe</summary>
  TUfopaediaTestRules = class
  public
    /// <summary>A ruleset loaded from YAML text and sorted (owned by the caller)</summary>
    class function Load(const AText: string): TXcomRuleset; static;
    /// <summary>
    ///   The standard ruleset of the tests: sections A (three articles, one hidden behind a research), B and the
    ///   not available one, with an article for each of the 17 kinds of state
    /// </summary>
    class function Standard: TXcomRuleset; static;
  end;

  /// <summary>
  ///   The resources of the fake game of the tests, plus what the Ufopaedia asks: any picture (a blank screen made
  ///   when asked, except the names in Missing) and the interface of the dogfight
  /// </summary>
  TUfopaediaResources = class(TInterfacedObject, IXcomResources)
  strict private
    FInner: IXcomResources;
    FSurfaces: TObjectDictionary<string, TXcomSurface>;
    FInterfaces: TObjectDictionary<string, TXcomRuleInterface>;
    FMissing: TList<string>;
    FAsked: TList<string>;
  public
    constructor Create(const AInner: IXcomResources);
    destructor Destroy; override;
    function GetSurface(const AName: string): TXcomSurface;
    function GetFont(const AName: string): TXcomFont;
    function GetInterface(const AId: string): TXcomRuleInterface;
    function GetPalette(const AName: string): PXcomColor;
    function CursorColor(const APalette: string): Integer;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256);
    function HasSoundDefinitions: Boolean;
    function SoundWave(const ASet: string; AIndex: Integer): TBytes;
    function Constant(const AName: string; ADefault: Integer): Integer;
    function MusicRules: TArray<TXcomMusicRule>;
    function SoundFile(const AName: string): TBytes;
    /// <summary>The names of the pictures that do not exist</summary>
    property Missing: TList<string> read FMissing;
    /// <summary>The names of the pictures asked, in order</summary>
    property Asked: TList<string> read FAsked;
  end;

  /// <summary>A navigator that only remembers what it was asked</summary>
  TFakeUfopaediaNavigator = class(TInterfacedObject, IXcomUfopaediaNavigator)
  strict private
    FCalls: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open;
    procedure OpenSection(const ASection: string);
    procedure OpenArticle(const AArticleId: string); overload;
    procedure OpenArticle(AArticle: TXcomArticleDefinition); overload;
    procedure Next;
    procedure Prev;
    /// <summary>The calls, as "name" or "name:argument"</summary>
    property Calls: TList<string> read FCalls;
  end;

implementation

uses
  DelphiDoom.Yaml.Factory, DelphiDoom.Yaml.Types;

const
  STANDARD_RULES =
    'items:'#10 +
    '  - type: STR_RIFLE'#10 +
    '    battleType: 1'#10 +
    '    bigSprite: 1'#10 +
    '    invWidth: 1'#10 +
    '    invHeight: 3'#10 +
    '    accuracyAuto: 35'#10 +
    '    accuracySnap: 60'#10 +
    '    accuracyAimed: 110'#10 +
    '    tuAuto: 35'#10 +
    '    tuSnap: 25'#10 +
    '    tuAimed: 80'#10 +
    '    compatibleAmmo:'#10 +
    '      - STR_RIFLE_CLIP'#10 +
    '      - STR_SECRET_CLIP'#10 +
    '  - type: STR_RIFLE_CLIP'#10 +
    '    battleType: 2'#10 +
    '    bigSprite: 2'#10 +
    '    power: 30'#10 +
    '    damageType: 1'#10 +
    '    clipSize: 20'#10 +
    '  - type: STR_SECRET_CLIP'#10 +
    '    battleType: 2'#10 +
    '    power: 60'#10 +
    '    damageType: 5'#10 +
    '    clipSize: 10'#10 +
    '  - type: STR_GRENADE'#10 +
    '    battleType: 4'#10 +
    '    power: 50'#10 +
    '    damageType: 3'#10 +
    '  - type: STR_TANK'#10 +
    '    battleType: 1'#10 +
    '    fixedWeapon: true'#10 +
    '    compatibleAmmo:'#10 +
    '      - STR_TANK_SHELL'#10 +
    '  - type: STR_TANK_SHELL'#10 +
    '    battleType: 2'#10 +
    '    power: 60'#10 +
    '    damageType: 1'#10 +
    '    clipSize: 30'#10 +
    '  - type: STR_LASER_TANK'#10 +
    '    battleType: 1'#10 +
    '    fixedWeapon: true'#10 +
    '    power: 110'#10 +
    '    damageType: 4'#10 +
    '    clipSize: 255'#10 +
    'armors:'#10 +
    '  - type: STR_SUIT'#10 +
    '    spriteInv: SUIT'#10 +
    '    corpseBattle:'#10 +
    '      - STR_CORPSE'#10 +
    '    frontArmor: 50'#10 +
    '    sideArmor: 40'#10 +
    '    rearArmor: 30'#10 +
    '    underArmor: 0'#10 +
    '    damageModifier:'#10 +
    '      - 1.0'#10 +
    '      - 0.8'#10 +
    '      - 1.0'#10 +
    '      - 0.7'#10 +
    '      - 1.0'#10 +
    '      - 1.0'#10 +
    '      - 1.0'#10 +
    '      - 1.0'#10 +
    '      - 1.3'#10 +
    '      - 0.0'#10 +
    '    stats:'#10 +
    '      tu: 5'#10 +
    '      strength: -3'#10 +
    '  - type: TANK_ARMOR'#10 +
    '    spriteInv: TANKS'#10 +
    '    corpseBattle:'#10 +
    '      - STR_CORPSE'#10 +
    '    frontArmor: 90'#10 +
    '    sideArmor: 75'#10 +
    '    rearArmor: 60'#10 +
    '    underArmor: 20'#10 +
    'units:'#10 +
    '  - type: STR_TANK'#10 +
    '    armor: TANK_ARMOR'#10 +
    '    stats:'#10 +
    '      tu: 70'#10 +
    '      health: 90'#10 +
    '  - type: STR_LASER_TANK'#10 +
    '    armor: TANK_ARMOR'#10 +
    '    stats:'#10 +
    '      tu: 100'#10 +
    '      health: 95'#10 +
    'crafts:'#10 +
    '  - type: STR_SHIP'#10 +
    '    fuelMax: 1500'#10 +
    '    damageMax: 150'#10 +
    '    speedMax: 2100'#10 +
    '    accel: 3'#10 +
    '    weapons: 2'#10 +
    '    soldiers: 14'#10 +
    '    vehicles: 3'#10 +
    'craftWeapons:'#10 +
    '  - type: STR_CANNON'#10 +
    '    launcher: STR_RIFLE'#10 +
    '    damage: 1100'#10 +
    '    range: 30'#10 +
    '    accuracy: 25'#10 +
    '    reloadStandard: 24'#10 +
    '    ammoMax: 200'#10 +
    'facilities:'#10 +
    '  - type: STR_LAB'#10 +
    '    spriteShape: 1'#10 +
    '    spriteFacility: 2'#10 +
    '    buildCost: 750000'#10 +
    '    buildTime: 26'#10 +
    '    monthlyCost: 30000'#10 +
    '  - type: STR_DEFENSE'#10 +
    '    size: 2'#10 +
    '    spriteShape: 4'#10 +
    '    spriteFacility: 8'#10 +
    '    buildCost: 200000'#10 +
    '    buildTime: 12'#10 +
    '    monthlyCost: 5000'#10 +
    '    defense: 500'#10 +
    '    hitRatio: 50'#10 +
    'ufos:'#10 +
    '  - type: STR_SCOUT'#10 +
    '    size: STR_SMALL'#10 +
    '    sprite: 1'#10 +
    '    damageMax: 50'#10 +
    '    speedMax: 2200'#10 +
    '    power: 20'#10 +
    '    range: 120'#10 +
    'ufopaedia:'#10 +
    '  - id: STR_SHIP'#10 +
    '    type_id: 1'#10 +
    '    section: STR_SECTION_A'#10 +
    '    image_id: UP004.SPK'#10 +
    '    text: STR_SHIP_TEXT'#10 +
    '    rect_stats: {x: 160, y: 5, width: 140, height: 60}'#10 +
    '    rect_text: {x: 5, y: 40, width: 150, height: 100}'#10 +
    '  - id: STR_CANNON'#10 +
    '    type_id: 2'#10 +
    '    section: STR_SECTION_A'#10 +
    '    image_id: UP006.SPK'#10 +
    '    text: STR_CANNON_TEXT'#10 +
    '  - id: STR_HIDDEN'#10 +
    '    type_id: 8'#10 +
    '    section: STR_SECTION_A'#10 +
    '    requires:'#10 +
    '      - STR_SECRET'#10 +
    '    text: STR_HIDDEN_TEXT'#10 +
    '  - id: STR_TANK'#10 +
    '    type_id: 3'#10 +
    '    section: STR_SECTION_B'#10 +
    '    weapon: STR_TANK_WEAPON'#10 +
    '    text: STR_TANK_TEXT'#10 +
    '  - id: STR_RIFLE'#10 +
    '    type_id: 4'#10 +
    '    section: STR_SECTION_B'#10 +
    '    text: STR_RIFLE_TEXT'#10 +
    '  - id: STR_RIFLE_CLIP'#10 +
    '    type_id: 4'#10 +
    '    section: STR_NOT_AVAILABLE'#10 +
    '    text: STR_CLIP_TEXT'#10 +
    '  - id: STR_SECRET_CLIP'#10 +
    '    type_id: 4'#10 +
    '    section: STR_NOT_AVAILABLE'#10 +
    '    requires:'#10 +
    '      - STR_SECRET'#10 +
    '    text: STR_CLIP_TEXT'#10 +
    '  - id: STR_SUIT'#10 +
    '    type_id: 5'#10 +
    '    section: STR_SECTION_B'#10 +
    '    text: STR_SUIT_TEXT'#10 +
    '  - id: STR_LAB'#10 +
    '    type_id: 6'#10 +
    '    section: STR_SECTION_B'#10 +
    '    text: STR_LAB_TEXT'#10 +
    '  - id: STR_PICTURE'#10 +
    '    type_id: 7'#10 +
    '    section: STR_SECTION_B'#10 +
    '    image_id: UP010.SPK'#10 +
    '    text: STR_PICTURE_TEXT'#10 +
    '    text_width: 150'#10 +
    '  - id: STR_SCOUT'#10 +
    '    type_id: 9'#10 +
    '    section: STR_SECTION_B'#10 +
    '    text: STR_SCOUT_TEXT'#10 +
    '  - id: STR_ALIEN_UC'#10 +
    '    type_id: 10'#10 +
    '    section: STR_SECTION_C'#10 +
    '    requires:'#10 +
    '      - STR_ALIEN'#10 +
    '    image_id: UP020.BDY'#10 +
    '    text: STR_ALIEN_TEXT'#10 +
    '  - id: STR_SHIP_TFTD'#10 +
    '    title: STR_SHIP'#10 +
    '    type_id: 11'#10 +
    '    section: STR_SECTION_C'#10 +
    '    image_id: UP021.BDY'#10 +
    '    text: STR_SHIP_TEXT'#10;

  // the TFTD articles describe rules by the id of the article: the same rules under the names of the TFTD articles
  STANDARD_TFTD =
    'crafts:'#10 +
    '  - type: STR_SHIP_TFTD'#10 +
    '    fuelMax: 30'#10 +
    '    damageMax: 1200'#10 +
    '    speedMax: 4000'#10 +
    '    accel: 8'#10 +
    '    weapons: 2'#10 +
    'craftWeapons:'#10 +
    '  - type: STR_TORPEDO'#10 +
    '    launcher: STR_GRENADE'#10 +
    '    damage: 70'#10 +
    '    range: 50'#10 +
    '    accuracy: 80'#10 +
    '    reloadStandard: 16'#10 +
    'armors:'#10 +
    '  - type: STR_AQUA_SUIT'#10 +
    '    spriteInv: AQUA'#10 +
    '    corpseBattle:'#10 +
    '      - STR_CORPSE'#10 +
    '    frontArmor: 12'#10 +
    '    sideArmor: 8'#10 +
    '    rearArmor: 5'#10 +
    '    underArmor: 2'#10 +
    'ufos:'#10 +
    '  - type: STR_SUB'#10 +
    '    size: STR_SMALL'#10 +
    '    damageMax: 60'#10 +
    '    speedMax: 1200'#10 +
    '    power: 10'#10 +
    '    range: 15'#10 +
    'ufopaedia:'#10 +
    '  - id: STR_TORPEDO'#10 +
    '    type_id: 12'#10 +
    '    section: STR_SECTION_C'#10 +
    '    image_id: UP025.BDY'#10 +
    '    text: STR_TORPEDO_TEXT'#10 +
    '  - id: STR_AQUA_SUIT'#10 +
    '    type_id: 15'#10 +
    '    section: STR_SECTION_C'#10 +
    '    image_id: UP026.BDY'#10 +
    '    text: STR_SUIT_TEXT'#10 +
    '  - id: STR_SUB'#10 +
    '    type_id: 17'#10 +
    '    section: STR_SECTION_C'#10 +
    '    image_id: UP027.BDY'#10 +
    '    text: STR_SUB_TEXT'#10 +
    '  - id: STR_LASER_TANK'#10 +
    '    type_id: 13'#10 +
    '    section: STR_SECTION_C'#10 +
    '    image_id: UP022.BDY'#10 +
    '    weapon: STR_LASER_WEAPON'#10 +
    '    text: STR_TANK_TEXT'#10 +
    '  - id: STR_GRENADE'#10 +
    '    type_id: 14'#10 +
    '    section: STR_SECTION_C'#10 +
    '    image_id: UP023.BDY'#10 +
    '    text: STR_GRENADE_TEXT'#10 +
    '  - id: STR_DEFENSE'#10 +
    '    type_id: 16'#10 +
    '    section: STR_SECTION_C'#10 +
    '    image_id: UP024.BDY'#10 +
    '    text: STR_DEFENSE_TEXT'#10;

{ TUfopaediaFixedShared }

function TUfopaediaFixedShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TUfopaediaFixedShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 100;
end;

{ TUfopaediaTestRules }

class function TUfopaediaTestRules.Load(const AText: string): TXcomRuleset;
begin
  Result := TXcomRuleset.Create(TUfopaediaFixedShared.Create);
  try
    // one mod with room for a thousand sprites and sounds: the offsets of the rules need it
    Result.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000)), 0);
    Result.LoadFile(TYamlFactory.CreateParser.Load(YamlStringToText(AText)));
    Result.SortLists;
  except
    Result.Free;
    raise;
  end;
end;

class function TUfopaediaTestRules.Standard: TXcomRuleset;
begin
  Result := TXcomRuleset.Create(TUfopaediaFixedShared.Create);
  try
    // one mod with room for a thousand sprites and sounds: the offsets of the rules need it
    Result.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000)), 0);
    Result.LoadFile(TYamlFactory.CreateParser.Load(YamlStringToText(STANDARD_RULES)));
    Result.LoadFile(TYamlFactory.CreateParser.Load(YamlStringToText(STANDARD_TFTD)));
    Result.SortLists;
  except
    Result.Free;
    raise;
  end;
end;

{ TUfopaediaResources }

constructor TUfopaediaResources.Create(const AInner: IXcomResources);
var
  LRule: TXcomRuleInterface;
begin
  inherited Create;
  FInner := AInner;
  FSurfaces := TObjectDictionary<string, TXcomSurface>.Create([doOwnsValues]);
  FInterfaces := TObjectDictionary<string, TXcomRuleInterface>.Create([doOwnsValues]);
  FMissing := TList<string>.Create;
  FAsked := TList<string>.Create;
  LRule := TXcomRuleInterface.Create('dogfight');
  LRule.Load(TYamlFactory.CreateParser.Load(YamlStringToText(
    'elements:'#10'  - id: previewMid'#10'    pos: [2, 96]'#10'    size: [160, 28]'#10)));
  FInterfaces.Add('dogfight', LRule);
end;

destructor TUfopaediaResources.Destroy;
begin
  FAsked.Free;
  FMissing.Free;
  FInterfaces.Free;
  FSurfaces.Free;
  inherited Destroy;
end;

function TUfopaediaResources.GetSurface(const AName: string): TXcomSurface;
begin
  FAsked.Add(AName);
  if FMissing.Contains(AName) then
    raise EXcomEngineException.Create('no surface ' + AName);
  if not FSurfaces.TryGetValue(AName, Result) then
  begin
    if AName = 'INTERWIN.DAT' then
      Result := TXcomSurface.Create(160, 600)
    else
      Result := TXcomSurface.Create(320, 200);
    Result.Clear(7);
    FSurfaces.Add(AName, Result);
  end;
end;

function TUfopaediaResources.GetFont(const AName: string): TXcomFont;
begin
  Result := FInner.GetFont(AName);
end;

function TUfopaediaResources.GetInterface(const AId: string): TXcomRuleInterface;
begin
  if not FInterfaces.TryGetValue(AId, Result) then
    Result := FInner.GetInterface(AId);
end;

function TUfopaediaResources.GetPalette(const AName: string): PXcomColor;
begin
  Result := FInner.GetPalette(AName);
end;

function TUfopaediaResources.CursorColor(const APalette: string): Integer;
begin
  Result := FInner.CursorColor(APalette);
end;

procedure TUfopaediaResources.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  FInner.SetPalette(AColors, AFirst, ACount);
end;

function TUfopaediaResources.HasSoundDefinitions: Boolean;
begin
  Result := FInner.HasSoundDefinitions;
end;

function TUfopaediaResources.SoundWave(const ASet: string; AIndex: Integer): TBytes;
begin
  Result := FInner.SoundWave(ASet, AIndex);
end;

function TUfopaediaResources.Constant(const AName: string; ADefault: Integer): Integer;
begin
  Result := FInner.Constant(AName, ADefault);
end;

function TUfopaediaResources.MusicRules: TArray<TXcomMusicRule>;
begin
  Result := FInner.MusicRules;
end;

function TUfopaediaResources.SoundFile(const AName: string): TBytes;
begin
  Result := FInner.SoundFile(AName);
end;

{ TFakeUfopaediaNavigator }

constructor TFakeUfopaediaNavigator.Create;
begin
  inherited Create;
  FCalls := TList<string>.Create;
end;

destructor TFakeUfopaediaNavigator.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

procedure TFakeUfopaediaNavigator.Open;
begin
  FCalls.Add('open');
end;

procedure TFakeUfopaediaNavigator.OpenSection(const ASection: string);
begin
  FCalls.Add('section:' + ASection);
end;

procedure TFakeUfopaediaNavigator.OpenArticle(const AArticleId: string);
begin
  FCalls.Add('id:' + AArticleId);
end;

procedure TFakeUfopaediaNavigator.OpenArticle(AArticle: TXcomArticleDefinition);
begin
  FCalls.Add('article:' + AArticle.Id);
end;

procedure TFakeUfopaediaNavigator.Next;
begin
  FCalls.Add('next');
end;

procedure TFakeUfopaediaNavigator.Prev;
begin
  FCalls.Add('prev');
end;

end.
