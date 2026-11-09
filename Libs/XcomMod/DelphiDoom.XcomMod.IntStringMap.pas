{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - std::map<int, std::string> and its        }
{  reading from YAML                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.IntStringMap;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf;

type
  /// <summary>
  ///   std::map&lt;int, std::string&gt;: the pairs in the order of the numbers; an existing number keeps its place
  ///   and takes the new text
  /// </summary>
  TXcomIntStringMap = class
  strict private
    FKeys: TList<Integer>;
    FValues: TList<string>;
    function Find(AKey: Integer; out AIndex: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    procedure SetValue(AKey: Integer; const AValue: string);
    function Key(AIndex: Integer): Integer;
    function Value(AIndex: Integer): string;
    /// <summary>
    ///   as&lt;std::map&lt;int, std::string&gt;&gt;(map) of ANode[AKey]: a missing field or one that is not a map leaves
    ///   the pairs as they are; otherwise a new map replaces them (a bad key or text raises, the pairs stay)
    /// </summary>
    procedure ReadField(const ANode: IYamlNode; const AKey: string);
    /// <summary>The text of the map as "key:'value'" pairs separated by commas, for the tests</summary>
    function ToText: string;
  end;

implementation

uses
  DelphiDoom.XcomMod.NodeReader;

{ TXcomIntStringMap }

constructor TXcomIntStringMap.Create;
begin
  inherited Create;
  FKeys := TList<Integer>.Create;
  FValues := TList<string>.Create;
end;

destructor TXcomIntStringMap.Destroy;
begin
  FValues.Free;
  FKeys.Free;
  inherited Destroy;
end;

function TXcomIntStringMap.Find(AKey: Integer; out AIndex: Integer): Boolean;
begin
  AIndex := 0;
  while (AIndex < FKeys.Count) and (FKeys[AIndex] < AKey) do
    Inc(AIndex);
  Result := (AIndex < FKeys.Count) and (FKeys[AIndex] = AKey);
end;

function TXcomIntStringMap.Count: Integer;
begin
  Result := FKeys.Count;
end;

procedure TXcomIntStringMap.SetValue(AKey: Integer; const AValue: string);
var
  LIndex: Integer;
begin
  if Find(AKey, LIndex) then
    FValues[LIndex] := AValue
  else
  begin
    FKeys.Insert(LIndex, AKey);
    FValues.Insert(LIndex, AValue);
  end;
end;

function TXcomIntStringMap.Key(AIndex: Integer): Integer;
begin
  Result := FKeys[AIndex];
end;

function TXcomIntStringMap.Value(AIndex: Integer): string;
begin
  Result := FValues[AIndex];
end;

procedure TXcomIntStringMap.ReadField(const ANode: IYamlNode; const AKey: string);
var
  LField: IYamlNode;
  LPair: TYamlPair;
  LNew: TXcomIntStringMap;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsMap then
    Exit;
  LNew := TXcomIntStringMap.Create;
  try
    for LPair in LField.Pairs do
      LNew.SetValue(LPair.Key.AsInteger, TXcomNodeReader.TextOf(LPair.Value));
    FKeys.Clear;
    FValues.Clear;
    for LIndex := 0 to LNew.Count - 1 do
    begin
      FKeys.Add(LNew.Key(LIndex));
      FValues.Add(LNew.Value(LIndex));
    end;
  finally
    LNew.Free;
  end;
end;

function TXcomIntStringMap.ToText: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FKeys.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(FKeys[LIndex]) + ':' + FValues[LIndex];
  end;
end;

end.
