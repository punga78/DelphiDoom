{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the stats of a unit (UnitStats):      }
{  the writing half of convert<UnitStats>; the record and the reading are in   }
{  Libs\XcomMod (DelphiDoom.XcomMod.UnitStats)                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.UnitStats;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.UnitStats,
  DelphiDoom.XcomSave.NodeWriter;

type
  /// <summary>convert&lt;UnitStats&gt; of OpenXcom: a map with the stats as integers</summary>
  TXcomUnitStatsCodec = class
  public
    /// <summary>
    ///   node[key].as&lt;UnitStats&gt;(default): see TXcomUnitStatsReader.Read (the record is that of the ruleset)
    /// </summary>
    class function Read(const ANode: IYamlNode; const AKey: string; const ADefault: TXcomUnitStats)
      : TXcomUnitStats; static;
    /// <summary>node.as&lt;UnitStats&gt;(default) of the node itself</summary>
    class function Decode(const ANode: IYamlNode; const ADefault: TXcomUnitStats): TXcomUnitStats; static;
    /// <summary>node[key] = stats</summary>
    class procedure Write(const ANode: IYamlNode; const AKey: string; const AStats: TXcomUnitStats); static;
    /// <summary>The map node of the stats (convert&lt;UnitStats&gt;::encode)</summary>
    class function Encode(const AStats: TXcomUnitStats): IYamlNode; static;
  end;

implementation

{ TXcomUnitStatsCodec }

class function TXcomUnitStatsCodec.Read(const ANode: IYamlNode; const AKey: string;
  const ADefault: TXcomUnitStats): TXcomUnitStats;
begin
  Result := TXcomUnitStatsReader.Read(ANode, AKey, ADefault);
end;

class function TXcomUnitStatsCodec.Decode(const ANode: IYamlNode; const ADefault: TXcomUnitStats): TXcomUnitStats;
begin
  Result := TXcomUnitStatsReader.Decode(ANode, ADefault);
end;

class function TXcomUnitStatsCodec.Encode(const AStats: TXcomUnitStats): IYamlNode;
begin
  Result := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(Result, 'tu', AStats.TimeUnits);
  TXcomNodeWriter.SetInteger(Result, 'stamina', AStats.Stamina);
  TXcomNodeWriter.SetInteger(Result, 'health', AStats.Health);
  TXcomNodeWriter.SetInteger(Result, 'bravery', AStats.Bravery);
  TXcomNodeWriter.SetInteger(Result, 'reactions', AStats.Reactions);
  TXcomNodeWriter.SetInteger(Result, 'firing', AStats.Firing);
  TXcomNodeWriter.SetInteger(Result, 'throwing', AStats.Throwing);
  TXcomNodeWriter.SetInteger(Result, 'strength', AStats.Strength);
  TXcomNodeWriter.SetInteger(Result, 'psiStrength', AStats.PsiStrength);
  TXcomNodeWriter.SetInteger(Result, 'psiSkill', AStats.PsiSkill);
  TXcomNodeWriter.SetInteger(Result, 'melee', AStats.Melee);
end;

class procedure TXcomUnitStatsCodec.Write(const ANode: IYamlNode; const AKey: string; const AStats: TXcomUnitStats);
begin
  ANode.Child(YamlStringToText(AKey)).Assign(Encode(AStats));
end;

end.
