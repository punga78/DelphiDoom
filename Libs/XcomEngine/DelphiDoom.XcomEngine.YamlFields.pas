{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - node["key"].as<T>(default) on a YAML node  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.YamlFields;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf;

type
  /// <summary>
  ///   The reads that the engine does on YAML (options, languages, interfaces, fonts): a missing key or a value
  ///   that does not convert gives the fallback, as as&lt;T&gt;(fallback) does in yaml-cpp
  /// </summary>
  TXcomYamlFields = class
  public
    /// <summary>node["key"]: an invalid handle (IsDefined false) when the key is missing; nil for a nil node</summary>
    class function Field(const ANode: IYamlNode; const AKey: string): IYamlNode; static;
    class function Exists(const ANode: IYamlNode; const AKey: string): Boolean; static;
    class function ReadString(const ANode: IYamlNode; const AKey, ADefault: string): string; static;
    class function ReadInteger(const ANode: IYamlNode; const AKey: string; ADefault: Integer): Integer; static;
    class function ReadBoolean(const ANode: IYamlNode; const AKey: string; ADefault: Boolean): Boolean; static;
    /// <summary>The elements of a sequence (empty when the node is missing or not a sequence)</summary>
    class function Sequence(const ANode: IYamlNode; const AKey: string): TArray<IYamlNode>; static;
  end;

implementation

class function TXcomYamlFields.Field(const ANode: IYamlNode; const AKey: string): IYamlNode;
begin
  if not Assigned(ANode) then
    Exit(nil);
  if not (ANode.IsDefined and ANode.IsMap) then
    Exit(nil);
  Result := ANode.Find(YamlStringToText(AKey));
  if Assigned(Result) and not Result.IsDefined then
    Result := nil;
end;

class function TXcomYamlFields.Exists(const ANode: IYamlNode; const AKey: string): Boolean;
begin
  Result := Assigned(Field(ANode, AKey));
end;

class function TXcomYamlFields.ReadString(const ANode: IYamlNode; const AKey, ADefault: string): string;
var
  LValue: IYamlNode;
begin
  LValue := Field(ANode, AKey);
  if (not Assigned(LValue)) or (not LValue.IsScalar) then
    Exit(ADefault);
  Result := LValue.ScalarString;
end;

class function TXcomYamlFields.ReadInteger(const ANode: IYamlNode; const AKey: string; ADefault: Integer): Integer;
var
  LValue: IYamlNode;
begin
  LValue := Field(ANode, AKey);
  if (not Assigned(LValue)) or (not LValue.TryAsInteger(Result)) then
    Result := ADefault;
end;

class function TXcomYamlFields.ReadBoolean(const ANode: IYamlNode; const AKey: string; ADefault: Boolean): Boolean;
var
  LValue: IYamlNode;
begin
  LValue := Field(ANode, AKey);
  if (not Assigned(LValue)) or (not LValue.TryAsBoolean(Result)) then
    Result := ADefault;
end;

class function TXcomYamlFields.Sequence(const ANode: IYamlNode; const AKey: string): TArray<IYamlNode>;
var
  LValue: IYamlNode;
begin
  LValue := Field(ANode, AKey);
  if Assigned(LValue) and LValue.IsSequence then
    Result := LValue.Items
  else
    Result := nil;
end;

end.
