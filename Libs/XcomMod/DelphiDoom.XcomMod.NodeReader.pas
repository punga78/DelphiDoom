{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - reading the fields of a YAML node the     }
{  way the rules do (node["key"].as<T>(default) and the std containers)         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.NodeReader;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types;

type
  /// <summary>
  ///   node["key"].as&lt;T&gt;(fallback) for the types the rules use. A missing key, a node of another kind and a
  ///   value that does not convert give the fallback; the elements of a container are read with as&lt;T&gt;() and a
  ///   bad one raises EYamlBadConversion (std::vector and std::map conversions of yaml-cpp). The node must be
  ///   a map or the YAML library raises its own error
  /// </summary>
  TXcomNodeReader = class
  public
    /// <summary>The value of a key; an invalid handle (IsDefined false) if the key is missing</summary>
    class function Field(const ANode: IYamlNode; const AKey: string): IYamlNode; static;
    class function ReadString(const ANode: IYamlNode; const AKey, ADefault: string): string; static;
    class function ReadInteger(const ANode: IYamlNode; const AKey: string; ADefault: Integer): Integer; static;
    /// <summary>as&lt;size_t&gt; with the 32 bit size_t of the Win32 build of OpenXcom</summary>
    class function ReadSize(const ANode: IYamlNode; const AKey: string; ADefault: Cardinal): Cardinal; static;
    class function ReadBoolean(const ANode: IYamlNode; const AKey: string; ADefault: Boolean): Boolean; static;
    class function ReadDouble(const ANode: IYamlNode; const AKey: string; ADefault: Double): Double; static;
    /// <summary>as&lt;std::vector&lt;std::string&gt;&gt;</summary>
    class function ReadStrings(const ANode: IYamlNode; const AKey: string;
      const ADefault: TArray<string>): TArray<string>; static;
    /// <summary>
    ///   as&lt;std::map&lt;std::string, int&gt;&gt;: the result is ADefault itself when the node has no map; otherwise
    ///   ADefault is cleared and refilled (as the C++ does with the map it is given)
    /// </summary>
    class procedure ReadStringIntMap(const ANode: IYamlNode; const AKey: string;
      const AValues: TXcomStringMap<Integer>); static;
    /// <summary>as&lt;std::vector&lt;std::vector&lt;double&gt;&gt;&gt;</summary>
    class function ReadDoubleRows(const ANode: IYamlNode; const AKey: string;
      const ADefault: TArray<TArray<Double>>): TArray<TArray<Double>>; static;
    /// <summary>as&lt;std::vector&lt;std::vector&lt;int&gt;&gt;&gt;</summary>
    class function ReadIntegerRows(const ANode: IYamlNode; const AKey: string;
      const ADefault: TArray<TArray<Integer>>): TArray<TArray<Integer>>; static;
    /// <summary>The text of a node (as&lt;std::string&gt;(): a null node is "null")</summary>
    class function TextOf(const ANode: IYamlNode): string; static;
    /// <summary>as&lt;std::vector&lt;int&gt;&gt;() of a node, without a fallback: a node that is not a sequence raises</summary>
    class function IntegersOf(const ANode: IYamlNode): TArray<Integer>; static;
    /// <summary>as&lt;std::vector&lt;std::string&gt;&gt;() of a node, without a fallback</summary>
    class function StringsOf(const ANode: IYamlNode): TArray<string>; static;
    /// <summary>as&lt;std::vector&lt;int&gt;&gt;(fallback) of a field</summary>
    class function ReadIntegers(const ANode: IYamlNode; const AKey: string;
      const ADefault: TArray<Integer>): TArray<Integer>; static;
    /// <summary>The conversion error of yaml-cpp (a bad conversion at the position of the node)</summary>
    class function BadConversion(const ANode: IYamlNode): EYamlBadConversion; static;
  end;

implementation

{ TXcomNodeReader }

class function TXcomNodeReader.Field(const ANode: IYamlNode; const AKey: string): IYamlNode;
begin
  Result := ANode.Find(YamlStringToText(AKey));
end;

class function TXcomNodeReader.TextOf(const ANode: IYamlNode): string;
begin
  Result := YamlTextToString(ANode.AsString);
end;

class function TXcomNodeReader.BadConversion(const ANode: IYamlNode): EYamlBadConversion;
begin
  Result := EYamlBadConversion.Create(ANode.Mark, 'bad conversion');
end;

class function TXcomNodeReader.IntegersOf(const ANode: IYamlNode): TArray<Integer>;
var
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  if not ANode.IsSequence then
    raise BadConversion(ANode);
  LItems := ANode.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
    Result[LIndex] := LItems[LIndex].AsInteger;
end;

class function TXcomNodeReader.StringsOf(const ANode: IYamlNode): TArray<string>;
var
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  if not ANode.IsSequence then
    raise BadConversion(ANode);
  LItems := ANode.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
    Result[LIndex] := TextOf(LItems[LIndex]);
end;

class function TXcomNodeReader.ReadIntegers(const ANode: IYamlNode; const AKey: string;
  const ADefault: TArray<Integer>): TArray<Integer>;
var
  LField: IYamlNode;
begin
  LField := Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  Result := IntegersOf(LField);
end;

class function TXcomNodeReader.ReadString(const ANode: IYamlNode; const AKey, ADefault: string): string;
begin
  Result := YamlTextToString(Field(ANode, AKey).AsString(YamlStringToText(ADefault)));
end;

class function TXcomNodeReader.ReadInteger(const ANode: IYamlNode; const AKey: string; ADefault: Integer): Integer;
begin
  Result := Field(ANode, AKey).AsInteger(ADefault);
end;

class function TXcomNodeReader.ReadSize(const ANode: IYamlNode; const AKey: string; ADefault: Cardinal): Cardinal;
begin
  Result := Field(ANode, AKey).AsCardinal(ADefault);
end;

class function TXcomNodeReader.ReadBoolean(const ANode: IYamlNode; const AKey: string; ADefault: Boolean): Boolean;
begin
  Result := Field(ANode, AKey).AsBoolean(ADefault);
end;

class function TXcomNodeReader.ReadDouble(const ANode: IYamlNode; const AKey: string; ADefault: Double): Double;
begin
  Result := Field(ANode, AKey).AsDouble(ADefault);
end;

class function TXcomNodeReader.ReadStrings(const ANode: IYamlNode; const AKey: string;
  const ADefault: TArray<string>): TArray<string>;
var
  LField: IYamlNode;
  LItems: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
    Result[LIndex] := TextOf(LItems[LIndex]);
end;

class procedure TXcomNodeReader.ReadStringIntMap(const ANode: IYamlNode; const AKey: string;
  const AValues: TXcomStringMap<Integer>);
var
  LField: IYamlNode;
  LPairs: TArray<TYamlPair>;
  LPair: TYamlPair;
begin
  LField := Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsMap then
    Exit;
  AValues.Clear;
  LPairs := LField.Pairs;
  for LPair in LPairs do
    AValues.SetValue(TextOf(LPair.Key), LPair.Value.AsInteger);
end;

class function TXcomNodeReader.ReadDoubleRows(const ANode: IYamlNode; const AKey: string;
  const ADefault: TArray<TArray<Double>>): TArray<TArray<Double>>;
var
  LField, LRow: IYamlNode;
  LItems, LCells: TArray<IYamlNode>;
  LIndex, LCell: Integer;
begin
  LField := Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    LRow := LItems[LIndex];
    // as<std::vector<double>>() without a fallback: a row that is not a sequence does not convert
    if not LRow.IsSequence then
      raise EYamlBadConversion.Create(LRow.Mark, 'bad conversion');
    LCells := LRow.Items;
    SetLength(Result[LIndex], Length(LCells));
    for LCell := 0 to High(LCells) do
      Result[LIndex][LCell] := LCells[LCell].AsDouble;
  end;
end;

class function TXcomNodeReader.ReadIntegerRows(const ANode: IYamlNode; const AKey: string;
  const ADefault: TArray<TArray<Integer>>): TArray<TArray<Integer>>;
var
  LField, LRow: IYamlNode;
  LItems, LCells: TArray<IYamlNode>;
  LIndex, LCell: Integer;
begin
  LField := Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    LRow := LItems[LIndex];
    if not LRow.IsSequence then
      raise EYamlBadConversion.Create(LRow.Mark, 'bad conversion');
    LCells := LRow.Items;
    SetLength(Result[LIndex], Length(LCells));
    for LCell := 0 to High(LCells) do
      Result[LIndex][LCell] := LCells[LCell].AsInteger;
  end;
end;

end.
