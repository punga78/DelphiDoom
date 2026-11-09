{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a unit of the battlescape (Unit: aliens,  }
{  civilians, tanks)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleUnit;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets,
  DelphiDoom.XcomMod.UnitStats;

type
  /// <summary>
  ///   The static data of a unit that the battlescape makes (HWP, alien, civilian): stats, armor, heights,
  ///   sounds, intelligence, special ability, built in weapons (Unit). The special ability is the number of
  ///   SpecialAbility (the C++ casts it without checking)
  /// </summary>
  TXcomRuleUnit = class
  strict private
    FType: string;
    FRace: string;
    FRank: string;
    FStats: TXcomUnitStats;
    FArmor: string;
    FStandHeight: Integer;
    FKneelHeight: Integer;
    FFloatHeight: Integer;
    FDeathSound: TArray<Integer>;
    FValue: Integer;
    FAggroSound: Integer;
    FMoveSound: Integer;
    FIntelligence: Integer;
    FAggression: Integer;
    FEnergyRecovery: Integer;
    FSpecialAbility: Integer;
    FSpawnUnit: string;
    FLivingWeapon: Boolean;
    FMeleeWeapon: string;
    FPsiWeapon: string;
    FBuiltInWeapons: TArray<TArray<string>>;
    FCapturable: Boolean;
    class function ReadStringRows(const ANode: IYamlNode; const AKey: string;
      const ADefault: TArray<TArray<string>>): TArray<TArray<string>>; static;
  public
    constructor Create(const AType: string);
    /// <summary>Loads the unit from a YAML node; stand plus float height over 25 is EXcomModException</summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
    property UnitType: string read FType;
    property Race: string read FRace;
    property Rank: string read FRank;
    property Stats: TXcomUnitStats read FStats;
    property Armor: string read FArmor;
    property StandHeight: Integer read FStandHeight;
    property KneelHeight: Integer read FKneelHeight;
    property FloatHeight: Integer read FFloatHeight;
    property DeathSounds: TArray<Integer> read FDeathSound;
    property Value: Integer read FValue;
    property AggroSound: Integer read FAggroSound;
    property MoveSound: Integer read FMoveSound;
    property Intelligence: Integer read FIntelligence;
    property Aggression: Integer read FAggression;
    property EnergyRecovery: Integer read FEnergyRecovery;
    property SpecialAbility: Integer read FSpecialAbility;
    property SpawnUnit: string read FSpawnUnit;
    property LivingWeapon: Boolean read FLivingWeapon;
    property MeleeWeapon: string read FMeleeWeapon;
    property PsiWeapon: string read FPsiWeapon;
    property BuiltInWeapons: TArray<TArray<string>> read FBuiltInWeapons;
    property Capturable: Boolean read FCapturable;
  end;

implementation

uses
  DelphiDoom.XcomMod.Types, DelphiDoom.Yaml.Types;

resourcestring
  SUnitTooTall = 'Error with unit %s: Unit height may not exceed 25';

{ TXcomRuleUnit }

constructor TXcomRuleUnit.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FAggroSound := -1;
  FMoveSound := -1;
  FEnergyRecovery := 30;
  FPsiWeapon := 'ALIEN_PSI_WEAPON';
  FCapturable := True;
end;

class function TXcomRuleUnit.ReadStringRows(const ANode: IYamlNode; const AKey: string;
  const ADefault: TArray<TArray<string>>): TArray<TArray<string>>;
var
  LField: IYamlNode;
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
    Result[LIndex] := TXcomNodeReader.StringsOf(LItems[LIndex]);
end;

procedure TXcomRuleUnit.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
begin
  FType := TXcomNodeReader.ReadString(ANode, 'type', FType);
  FRace := TXcomNodeReader.ReadString(ANode, 'race', FRace);
  FRank := TXcomNodeReader.ReadString(ANode, 'rank', FRank);
  FStats.Merge(TXcomUnitStatsReader.Read(ANode, 'stats', FStats));
  FArmor := TXcomNodeReader.ReadString(ANode, 'armor', FArmor);
  FStandHeight := TXcomNodeReader.ReadInteger(ANode, 'standHeight', FStandHeight);
  FKneelHeight := TXcomNodeReader.ReadInteger(ANode, 'kneelHeight', FKneelHeight);
  FFloatHeight := TXcomNodeReader.ReadInteger(ANode, 'floatHeight', FFloatHeight);
  if FFloatHeight + FStandHeight > 25 then
    raise EXcomModException.CreateFmt(SUnitTooTall, [FType]);
  FValue := TXcomNodeReader.ReadInteger(ANode, 'value', FValue);
  FIntelligence := TXcomNodeReader.ReadInteger(ANode, 'intelligence', FIntelligence);
  FAggression := TXcomNodeReader.ReadInteger(ANode, 'aggression', FAggression);
  FEnergyRecovery := TXcomNodeReader.ReadInteger(ANode, 'energyRecovery', FEnergyRecovery);
  FSpecialAbility := TXcomNodeReader.ReadInteger(ANode, 'specab', FSpecialAbility);
  FSpawnUnit := TXcomNodeReader.ReadString(ANode, 'spawnUnit', FSpawnUnit);
  FLivingWeapon := TXcomNodeReader.ReadBoolean(ANode, 'livingWeapon', FLivingWeapon);
  FMeleeWeapon := TXcomNodeReader.ReadString(ANode, 'meleeWeapon', FMeleeWeapon);
  FPsiWeapon := TXcomNodeReader.ReadString(ANode, 'psiWeapon', FPsiWeapon);
  FCapturable := TXcomNodeReader.ReadBoolean(ANode, 'capturable', FCapturable);
  FBuiltInWeapons := ReadStringRows(ANode, 'builtInWeaponSets', FBuiltInWeapons);
  if TXcomNodeReader.Field(ANode, 'builtInWeapons').IsDefined then
  begin
    SetLength(FBuiltInWeapons, Length(FBuiltInWeapons) + 1);
    FBuiltInWeapons[High(FBuiltInWeapons)] :=
      TXcomNodeReader.StringsOf(TXcomNodeReader.Field(ANode, 'builtInWeapons'));
  end;
  AOffsets.LoadSoundOffset(FType, FDeathSound, TXcomNodeReader.Field(ANode, 'deathSound'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset(FType, FAggroSound, TXcomNodeReader.Field(ANode, 'aggroSound'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset(FType, FMoveSound, TXcomNodeReader.Field(ANode, 'moveSound'), 'BATTLE.CAT');
end;

end.
