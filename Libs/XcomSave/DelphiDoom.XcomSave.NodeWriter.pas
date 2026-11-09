{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - building the YAML node of an object    }
{  (node["key"] = value of the save() functions of OpenXcom)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.NodeWriter;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory;

type
  /// <summary>The assignments of the save() functions: an int, a string, a bool or a vector&lt;int&gt; under a key</summary>
  TXcomNodeWriter = class
  public
    /// <summary>YAML::Node node: a null node that becomes a map with the first key assigned</summary>
    class function NewMap: IYamlNode; static;
    /// <summary>A node that already is a map (an empty std::map assigned to a node: it emits as {})</summary>
    class function NewEmptyMap: IYamlNode; static;
    /// <summary>An empty sequence node (to push_back into)</summary>
    class function NewSequence: IYamlNode; static;
    /// <summary>node[key] = another node</summary>
    class procedure SetNode(const ANode: IYamlNode; const AKey: string; const AValue: IYamlNode); static;
    /// <summary>node[key] = int (the decimal text a stream writes)</summary>
    class procedure SetInteger(const ANode: IYamlNode; const AKey: string; AValue: Integer); static;
    class procedure SetString(const ANode: IYamlNode; const AKey, AValue: string); static;
    /// <summary>node[key] = bool: true or false</summary>
    class procedure SetBoolean(const ANode: IYamlNode; const AKey: string; AValue: Boolean); static;
    /// <summary>node[key] = std::vector&lt;int&gt;: a sequence (an empty one stays a sequence)</summary>
    class procedure SetIntegers(const ANode: IYamlNode; const AKey: string; const AValues: TArray<Integer>);
      static;
  end;

implementation

{ TXcomNodeWriter }

class function TXcomNodeWriter.NewMap: IYamlNode;
begin
  Result := TYamlFactory.CreateNode;
end;

class function TXcomNodeWriter.NewEmptyMap: IYamlNode;
begin
  Result := TYamlFactory.CreateNode(ntMap);
end;

class function TXcomNodeWriter.NewSequence: IYamlNode;
begin
  Result := TYamlFactory.CreateNode(ntSequence);
end;

class procedure TXcomNodeWriter.SetNode(const ANode: IYamlNode; const AKey: string; const AValue: IYamlNode);
begin
  ANode.Child(YamlStringToText(AKey)).Assign(AValue);
end;

class procedure TXcomNodeWriter.SetInteger(const ANode: IYamlNode; const AKey: string; AValue: Integer);
begin
  ANode.Child(YamlStringToText(AKey)).AssignScalar(YamlStringToText(IntToStr(AValue)));
end;

class procedure TXcomNodeWriter.SetString(const ANode: IYamlNode; const AKey, AValue: string);
begin
  ANode.Child(YamlStringToText(AKey)).AssignScalar(YamlStringToText(AValue));
end;

class procedure TXcomNodeWriter.SetBoolean(const ANode: IYamlNode; const AKey: string; AValue: Boolean);
begin
  if AValue then
    ANode.Child(YamlStringToText(AKey)).AssignScalar('true')
  else
    ANode.Child(YamlStringToText(AKey)).AssignScalar('false');
end;

class procedure TXcomNodeWriter.SetIntegers(const ANode: IYamlNode; const AKey: string;
  const AValues: TArray<Integer>);
var
  LSequence: IYamlNode;
  LValue: Integer;
begin
  LSequence := TYamlFactory.CreateNode(ntSequence);
  for LValue in AValues do
    LSequence.Add(YamlStringToText(IntToStr(LValue)));
  ANode.Child(YamlStringToText(AKey)).Assign(LSequence);
end;

end.
