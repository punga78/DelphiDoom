{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - an armor (Armor)                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.Armor;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.UnitStats;

type
  /// <summary>
  ///   A type of armor, soldier armor or the one that aliens and vehicles wear: sprites, corpses, armor levels,
  ///   size, damage modifiers, stats and colors (Armor). The movement type and the forced torso are the numbers
  ///   of MovementType and ForcedTorso (the C++ casts them without checking)
  /// </summary>
  TXcomArmor = class
  public
    const
      /// <summary>DAMAGE_TYPES</summary>
      DAMAGE_TYPES = 10;
      /// <summary>Armor::NONE: the store item of an armor that is always there</summary>
      NONE = 'STR_NONE';
      /// <summary>MT_WALK</summary>
      MOVEMENT_WALK = 0;
      /// <summary>TORSO_USE_GENDER</summary>
      TORSO_USE_GENDER = 0;
  strict private
    FType: string;
    FSpriteSheet: string;
    FSpriteInv: string;
    FCorpseGeo: string;
    FStoreItem: string;
    FSpecWeapon: string;
    FCorpseBattle: TArray<string>;
    FFrontArmor: Integer;
    FSideArmor: Integer;
    FRearArmor: Integer;
    FUnderArmor: Integer;
    FDrawingRoutine: Integer;
    FDrawBubbles: Boolean;
    FMovementType: Integer;
    FSize: Integer;
    FWeight: Integer;
    FDamageModifier: array[0..DAMAGE_TYPES - 1] of Single;
    FLoftempsSet: TArray<Integer>;
    FStats: TXcomUnitStats;
    FDeathFrames: Integer;
    FConstantAnimation: Boolean;
    FHasInventory: Boolean;
    FForcedTorso: Integer;
    FFaceColorGroup: Integer;
    FHairColorGroup: Integer;
    FUtileColorGroup: Integer;
    FRankColorGroup: Integer;
    FFaceColor: TArray<Integer>;
    FHairColor: TArray<Integer>;
    FUtileColor: TArray<Integer>;
    FRankColor: TArray<Integer>;
    FUnits: TArray<string>;
    function GetDamageModifier(AType: Integer): Single;
  public
    constructor Create(const AType: string);
    /// <summary>
    ///   Loads the armor from a YAML node. corpseBattle with no items is EXcomModException (the C++ reads
    ///   the first one anyway)
    /// </summary>
    procedure Load(const ANode: IYamlNode);
    property ArmorType: string read FType;
    property SpriteSheet: string read FSpriteSheet;
    property SpriteInventory: string read FSpriteInv;
    property CorpseGeoscape: string read FCorpseGeo;
    property CorpseBattlescape: TArray<string> read FCorpseBattle;
    property StoreItem: string read FStoreItem;
    property SpecialWeapon: string read FSpecWeapon;
    property FrontArmor: Integer read FFrontArmor;
    property SideArmor: Integer read FSideArmor;
    property RearArmor: Integer read FRearArmor;
    property UnderArmor: Integer read FUnderArmor;
    property DrawingRoutine: Integer read FDrawingRoutine;
    property DrawBubbles: Boolean read FDrawBubbles;
    property MovementType: Integer read FMovementType;
    property Size: Integer read FSize;
    property Weight: Integer read FWeight;
    /// <summary>getDamageModifier: AType is 0 to DAMAGE_TYPES - 1</summary>
    property DamageModifier[AType: Integer]: Single read GetDamageModifier;
    property LoftempsSet: TArray<Integer> read FLoftempsSet;
    property Stats: TXcomUnitStats read FStats;
    property DeathFrames: Integer read FDeathFrames;
    property ConstantAnimation: Boolean read FConstantAnimation;
    property HasInventory: Boolean read FHasInventory;
    property ForcedTorso: Integer read FForcedTorso;
    property FaceColorGroup: Integer read FFaceColorGroup;
    property HairColorGroup: Integer read FHairColorGroup;
    property UtileColorGroup: Integer read FUtileColorGroup;
    property RankColorGroup: Integer read FRankColorGroup;
    property FaceColor: TArray<Integer> read FFaceColor;
    property HairColor: TArray<Integer> read FHairColor;
    property UtileColor: TArray<Integer> read FUtileColor;
    property RankColor: TArray<Integer> read FRankColor;
    property Units: TArray<string> read FUnits;
  end;

implementation

uses
  DelphiDoom.XcomMod.Types;

resourcestring
  SArmorNoCorpse = 'Armor %s has an empty corpseBattle list';

{ TXcomArmor }

constructor TXcomArmor.Create(const AType: string);
var
  LIndex: Integer;
begin
  inherited Create;
  FType := AType;
  FHasInventory := True;
  FSize := 1;
  FDeathFrames := 3;
  for LIndex := 0 to DAMAGE_TYPES - 1 do
    FDamageModifier[LIndex] := 1.0;
end;

function TXcomArmor.GetDamageModifier(AType: Integer): Single;
begin
  Result := FDamageModifier[AType];
end;

procedure TXcomArmor.Load(const ANode: IYamlNode);
var
  LDamage: IYamlNode;
  LIndex: Integer;
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FSpriteSheet := TXcomNodeReader.ReadString(ANode, 'spriteSheet', FSpriteSheet);
  FSpriteInv := TXcomNodeReader.ReadString(ANode, 'spriteInv', FSpriteInv);
  FHasInventory := TXcomNodeReader.ReadBoolean(ANode, 'allowInv', FHasInventory);
  if TXcomNodeReader.Field(ANode, 'corpseItem').IsDefined then
  begin
    FCorpseBattle := TArray<string>.Create(TXcomNodeReader.TextOf(TXcomNodeReader.Field(ANode, 'corpseItem')));
    FCorpseGeo := FCorpseBattle[0];
  end
  else if TXcomNodeReader.Field(ANode, 'corpseBattle').IsDefined then
  begin
    FCorpseBattle := TXcomNodeReader.StringsOf(TXcomNodeReader.Field(ANode, 'corpseBattle'));
    if Length(FCorpseBattle) = 0 then
      raise EXcomModException.CreateFmt(SArmorNoCorpse, [FType]);
    FCorpseGeo := FCorpseBattle[0];
  end;
  FCorpseGeo := TXcomNodeReader.ReadString(ANode, 'corpseGeo', FCorpseGeo);
  FStoreItem := TXcomNodeReader.ReadString(ANode, 'storeItem', FStoreItem);
  FSpecWeapon := TXcomNodeReader.ReadString(ANode, 'specialWeapon', FSpecWeapon);
  FFrontArmor := TXcomNodeReader.ReadInteger(ANode, 'frontArmor', FFrontArmor);
  FSideArmor := TXcomNodeReader.ReadInteger(ANode, 'sideArmor', FSideArmor);
  FRearArmor := TXcomNodeReader.ReadInteger(ANode, 'rearArmor', FRearArmor);
  FUnderArmor := TXcomNodeReader.ReadInteger(ANode, 'underArmor', FUnderArmor);
  FDrawingRoutine := TXcomNodeReader.ReadInteger(ANode, 'drawingRoutine', FDrawingRoutine);
  FDrawBubbles := TXcomNodeReader.ReadBoolean(ANode, 'drawBubbles', FDrawBubbles);
  FMovementType := TXcomNodeReader.ReadInteger(ANode, 'movementType', FMovementType);
  FSize := TXcomNodeReader.ReadInteger(ANode, 'size', FSize);
  FWeight := TXcomNodeReader.ReadInteger(ANode, 'weight', FWeight);
  FStats.Merge(TXcomUnitStatsReader.Read(ANode, 'stats', FStats));
  LDamage := TXcomNodeReader.Field(ANode, 'damageModifier');
  if LDamage.IsDefined then
    for LIndex := 0 to LDamage.Size - 1 do
    begin
      if LIndex >= DAMAGE_TYPES then
        Break;
      FDamageModifier[LIndex] := LDamage.Find(LIndex).AsSingle;
    end;
  FLoftempsSet := TXcomNodeReader.ReadIntegers(ANode, 'loftempsSet', FLoftempsSet);
  if TXcomNodeReader.Field(ANode, 'loftemps').IsDefined then
    FLoftempsSet := TArray<Integer>.Create(TXcomNodeReader.Field(ANode, 'loftemps').AsInteger);
  FDeathFrames := TXcomNodeReader.ReadInteger(ANode, 'deathFrames', FDeathFrames);
  FConstantAnimation := TXcomNodeReader.ReadBoolean(ANode, 'constantAnimation', FConstantAnimation);
  FForcedTorso := TXcomNodeReader.ReadInteger(ANode, 'forcedTorso', FForcedTorso);
  FFaceColorGroup := TXcomNodeReader.ReadInteger(ANode, 'spriteFaceGroup', FFaceColorGroup);
  FHairColorGroup := TXcomNodeReader.ReadInteger(ANode, 'spriteHairGroup', FHairColorGroup);
  FRankColorGroup := TXcomNodeReader.ReadInteger(ANode, 'spriteRankGroup', FRankColorGroup);
  FUtileColorGroup := TXcomNodeReader.ReadInteger(ANode, 'spriteUtileGroup', FUtileColorGroup);
  FFaceColor := TXcomNodeReader.ReadIntegers(ANode, 'spriteFaceColor', FFaceColor);
  FHairColor := TXcomNodeReader.ReadIntegers(ANode, 'spriteHairColor', FHairColor);
  FRankColor := TXcomNodeReader.ReadIntegers(ANode, 'spriteRankColor', FRankColor);
  FUtileColor := TXcomNodeReader.ReadIntegers(ANode, 'spriteUtileColor', FUtileColor);
  FUnits := TXcomNodeReader.ReadStrings(ANode, 'units', FUnits);
end;

end.
