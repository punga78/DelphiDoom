{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a base facility (RuleBaseFacility)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleBaseFacility;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets;

type
  /// <summary>
  ///   Constant data of a type of base facility: sprites, size, costs, what it stores or houses, radar and defense
  ///   (RuleBaseFacility)
  /// </summary>
  TXcomRuleBaseFacility = class
  strict private
    FType: string;
    FRequires: TArray<string>;
    FSpriteShape: Integer;
    FSpriteFacility: Integer;
    FLift: Boolean;
    FHyper: Boolean;
    FMind: Boolean;
    FGrav: Boolean;
    FSize: Integer;
    FBuildCost: Integer;
    FBuildTime: Integer;
    FMonthlyCost: Integer;
    FStorage: Integer;
    FPersonnel: Integer;
    FAliens: Integer;
    FCrafts: Integer;
    FLabs: Integer;
    FWorkshops: Integer;
    FPsiLabs: Integer;
    FRadarRange: Integer;
    FRadarChance: Integer;
    FDefense: Integer;
    FHitRatio: Integer;
    FFireSound: Integer;
    FHitSound: Integer;
    FMapName: string;
    FListOrder: Integer;
  public
    constructor Create(const AType: string);
    /// <summary>Loads the facility from a YAML node; AListOrder is the default of listOrder</summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets; AListOrder: Integer);
    property FacilityType: string read FType;
    property Requirements: TArray<string> read FRequires;
    property SpriteShape: Integer read FSpriteShape;
    property SpriteFacility: Integer read FSpriteFacility;
    property IsLift: Boolean read FLift;
    property IsHyperwave: Boolean read FHyper;
    property IsMindShield: Boolean read FMind;
    property IsGravShield: Boolean read FGrav;
    property Size: Integer read FSize;
    property BuildCost: Integer read FBuildCost;
    property BuildTime: Integer read FBuildTime;
    property MonthlyCost: Integer read FMonthlyCost;
    property Storage: Integer read FStorage;
    property Personnel: Integer read FPersonnel;
    property Aliens: Integer read FAliens;
    property Crafts: Integer read FCrafts;
    property Laboratories: Integer read FLabs;
    property Workshops: Integer read FWorkshops;
    property PsiLaboratories: Integer read FPsiLabs;
    property RadarRange: Integer read FRadarRange;
    property RadarChance: Integer read FRadarChance;
    property DefenseValue: Integer read FDefense;
    property HitRatio: Integer read FHitRatio;
    property FireSound: Integer read FFireSound;
    property HitSound: Integer read FHitSound;
    property MapName: string read FMapName;
    property ListOrder: Integer read FListOrder;
  end;

implementation

{ TXcomRuleBaseFacility }

constructor TXcomRuleBaseFacility.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FSpriteShape := -1;
  FSpriteFacility := -1;
  FSize := 1;
end;

procedure TXcomRuleBaseFacility.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets; AListOrder: Integer);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FRequires := TXcomNodeReader.ReadStrings(ANode, 'requires', FRequires);
  AOffsets.LoadSpriteOffset(FType, FSpriteShape, TXcomNodeReader.Field(ANode, 'spriteShape'), 'BASEBITS.PCK');
  AOffsets.LoadSpriteOffset(FType, FSpriteFacility, TXcomNodeReader.Field(ANode, 'spriteFacility'), 'BASEBITS.PCK');
  FLift := TXcomNodeReader.ReadBoolean(ANode, 'lift', FLift);
  FHyper := TXcomNodeReader.ReadBoolean(ANode, 'hyper', FHyper);
  FMind := TXcomNodeReader.ReadBoolean(ANode, 'mind', FMind);
  FGrav := TXcomNodeReader.ReadBoolean(ANode, 'grav', FGrav);
  FSize := TXcomNodeReader.ReadInteger(ANode, 'size', FSize);
  FBuildCost := TXcomNodeReader.ReadInteger(ANode, 'buildCost', FBuildCost);
  FBuildTime := TXcomNodeReader.ReadInteger(ANode, 'buildTime', FBuildTime);
  FMonthlyCost := TXcomNodeReader.ReadInteger(ANode, 'monthlyCost', FMonthlyCost);
  FStorage := TXcomNodeReader.ReadInteger(ANode, 'storage', FStorage);
  FPersonnel := TXcomNodeReader.ReadInteger(ANode, 'personnel', FPersonnel);
  FAliens := TXcomNodeReader.ReadInteger(ANode, 'aliens', FAliens);
  FCrafts := TXcomNodeReader.ReadInteger(ANode, 'crafts', FCrafts);
  FLabs := TXcomNodeReader.ReadInteger(ANode, 'labs', FLabs);
  FWorkshops := TXcomNodeReader.ReadInteger(ANode, 'workshops', FWorkshops);
  FPsiLabs := TXcomNodeReader.ReadInteger(ANode, 'psiLabs', FPsiLabs);
  FRadarRange := TXcomNodeReader.ReadInteger(ANode, 'radarRange', FRadarRange);
  FRadarChance := TXcomNodeReader.ReadInteger(ANode, 'radarChance', FRadarChance);
  FDefense := TXcomNodeReader.ReadInteger(ANode, 'defense', FDefense);
  FHitRatio := TXcomNodeReader.ReadInteger(ANode, 'hitRatio', FHitRatio);
  AOffsets.LoadSoundOffset(FType, FFireSound, TXcomNodeReader.Field(ANode, 'fireSound'), 'GEO.CAT');
  AOffsets.LoadSoundOffset(FType, FHitSound, TXcomNodeReader.Field(ANode, 'hitSound'), 'GEO.CAT');
  FMapName := TXcomNodeReader.ReadString(ANode, 'mapName', FMapName);
  FListOrder := TXcomNodeReader.ReadInteger(ANode, 'listOrder', FListOrder);
  if FListOrder = 0 then
    FListOrder := AListOrder;
end;

end.
