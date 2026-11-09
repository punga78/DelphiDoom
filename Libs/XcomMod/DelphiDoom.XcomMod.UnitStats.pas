{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the stats of a unit (UnitStats) and its   }
{  reading from YAML (convert<UnitStats>)                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.UnitStats;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>
  ///   UnitStats: the eleven abilities of a unit. The sums wrap around like the 32 bit integers of the C++.
  ///   The ruleset (armor, soldier, unit) and the saved game share this record
  /// </summary>
  TXcomUnitStats = record
    TimeUnits: Integer;
    Stamina: Integer;
    Health: Integer;
    Bravery: Integer;
    Reactions: Integer;
    Firing: Integer;
    Throwing: Integer;
    Strength: Integer;
    PsiStrength: Integer;
    PsiSkill: Integer;
    Melee: Integer;
    class operator Add(const ALeft, ARight: TXcomUnitStats): TXcomUnitStats;
    class operator Subtract(const ALeft, ARight: TXcomUnitStats): TXcomUnitStats;
    class operator Negative(const AValue: TXcomUnitStats): TXcomUnitStats;
    /// <summary>merge: the non-zero fields of the other stats replace the ones here</summary>
    procedure Merge(const AOther: TXcomUnitStats);
  end;

  /// <summary>The reading half of convert&lt;UnitStats&gt; of OpenXcom: a map with the stats as integers</summary>
  TXcomUnitStatsReader = class
  public
    /// <summary>
    ///   node[key].as&lt;UnitStats&gt;(default): a missing or not map node gives the default; a missing or
    ///   wrong field is 0 (the stats are decoded into new ones, not into the default)
    /// </summary>
    class function Read(const ANode: IYamlNode; const AKey: string; const ADefault: TXcomUnitStats)
      : TXcomUnitStats; static;
    /// <summary>node.as&lt;UnitStats&gt;(default) of the node itself</summary>
    class function Decode(const ANode: IYamlNode; const ADefault: TXcomUnitStats): TXcomUnitStats; static;
  end;

implementation

{ TXcomUnitStats }

class operator TXcomUnitStats.Add(const ALeft, ARight: TXcomUnitStats): TXcomUnitStats;
begin
  Result.TimeUnits := ALeft.TimeUnits + ARight.TimeUnits;
  Result.Stamina := ALeft.Stamina + ARight.Stamina;
  Result.Health := ALeft.Health + ARight.Health;
  Result.Bravery := ALeft.Bravery + ARight.Bravery;
  Result.Reactions := ALeft.Reactions + ARight.Reactions;
  Result.Firing := ALeft.Firing + ARight.Firing;
  Result.Throwing := ALeft.Throwing + ARight.Throwing;
  Result.Strength := ALeft.Strength + ARight.Strength;
  Result.PsiStrength := ALeft.PsiStrength + ARight.PsiStrength;
  Result.PsiSkill := ALeft.PsiSkill + ARight.PsiSkill;
  Result.Melee := ALeft.Melee + ARight.Melee;
end;

class operator TXcomUnitStats.Subtract(const ALeft, ARight: TXcomUnitStats): TXcomUnitStats;
begin
  Result.TimeUnits := ALeft.TimeUnits - ARight.TimeUnits;
  Result.Stamina := ALeft.Stamina - ARight.Stamina;
  Result.Health := ALeft.Health - ARight.Health;
  Result.Bravery := ALeft.Bravery - ARight.Bravery;
  Result.Reactions := ALeft.Reactions - ARight.Reactions;
  Result.Firing := ALeft.Firing - ARight.Firing;
  Result.Throwing := ALeft.Throwing - ARight.Throwing;
  Result.Strength := ALeft.Strength - ARight.Strength;
  Result.PsiStrength := ALeft.PsiStrength - ARight.PsiStrength;
  Result.PsiSkill := ALeft.PsiSkill - ARight.PsiSkill;
  Result.Melee := ALeft.Melee - ARight.Melee;
end;

class operator TXcomUnitStats.Negative(const AValue: TXcomUnitStats): TXcomUnitStats;
begin
  Result.TimeUnits := -AValue.TimeUnits;
  Result.Stamina := -AValue.Stamina;
  Result.Health := -AValue.Health;
  Result.Bravery := -AValue.Bravery;
  Result.Reactions := -AValue.Reactions;
  Result.Firing := -AValue.Firing;
  Result.Throwing := -AValue.Throwing;
  Result.Strength := -AValue.Strength;
  Result.PsiStrength := -AValue.PsiStrength;
  Result.PsiSkill := -AValue.PsiSkill;
  Result.Melee := -AValue.Melee;
end;

procedure TXcomUnitStats.Merge(const AOther: TXcomUnitStats);
begin
  if AOther.TimeUnits <> 0 then
    TimeUnits := AOther.TimeUnits;
  if AOther.Stamina <> 0 then
    Stamina := AOther.Stamina;
  if AOther.Health <> 0 then
    Health := AOther.Health;
  if AOther.Bravery <> 0 then
    Bravery := AOther.Bravery;
  if AOther.Reactions <> 0 then
    Reactions := AOther.Reactions;
  if AOther.Firing <> 0 then
    Firing := AOther.Firing;
  if AOther.Throwing <> 0 then
    Throwing := AOther.Throwing;
  if AOther.Strength <> 0 then
    Strength := AOther.Strength;
  if AOther.PsiStrength <> 0 then
    PsiStrength := AOther.PsiStrength;
  if AOther.PsiSkill <> 0 then
    PsiSkill := AOther.PsiSkill;
  if AOther.Melee <> 0 then
    Melee := AOther.Melee;
end;

{ TXcomUnitStatsReader }

class function TXcomUnitStatsReader.Read(const ANode: IYamlNode; const AKey: string;
  const ADefault: TXcomUnitStats): TXcomUnitStats;
var
  LField: IYamlNode;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined then
    Exit(ADefault);
  Result := Decode(LField, ADefault);
end;

class function TXcomUnitStatsReader.Decode(const ANode: IYamlNode; const ADefault: TXcomUnitStats): TXcomUnitStats;
begin
  if not ANode.IsMap then
    Exit(ADefault);
  // as<T>(fallback) decodes into a new T (all zero): a field that is missing is 0, not the fallback
  Result := Default(TXcomUnitStats);
  Result.TimeUnits := TXcomNodeReader.ReadInteger(ANode, 'tu', Result.TimeUnits);
  Result.Stamina := TXcomNodeReader.ReadInteger(ANode, 'stamina', Result.Stamina);
  Result.Health := TXcomNodeReader.ReadInteger(ANode, 'health', Result.Health);
  Result.Bravery := TXcomNodeReader.ReadInteger(ANode, 'bravery', Result.Bravery);
  Result.Reactions := TXcomNodeReader.ReadInteger(ANode, 'reactions', Result.Reactions);
  Result.Firing := TXcomNodeReader.ReadInteger(ANode, 'firing', Result.Firing);
  Result.Throwing := TXcomNodeReader.ReadInteger(ANode, 'throwing', Result.Throwing);
  Result.Strength := TXcomNodeReader.ReadInteger(ANode, 'strength', Result.Strength);
  Result.PsiStrength := TXcomNodeReader.ReadInteger(ANode, 'psiStrength', Result.PsiStrength);
  Result.PsiSkill := TXcomNodeReader.ReadInteger(ANode, 'psiSkill', Result.PsiSkill);
  Result.Melee := TXcomNodeReader.ReadInteger(ANode, 'melee', Result.Melee);
end;

end.
