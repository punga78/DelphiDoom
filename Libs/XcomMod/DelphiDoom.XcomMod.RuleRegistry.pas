{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the table of the rules of one kind        }
{  (the std::map + index vector of Mod and Mod::loadRule)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleRegistry;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>
  ///   The rules of one kind, by name (std::map&lt;std::string, T*&gt;, in the byte order of the names) and in the
  ///   order they were created (the _xxxIndex vector of Mod). The registry owns the rules
  /// </summary>
  TXcomRuleRegistry<T: class> = class
  strict private
    FMap: TXcomStringMap<T>;
    FIndex: TList<string>;
    FFactory: TFunc<string, T>;
  public
    /// <param name="AFactory">Makes a blank rule of a type (new T(type))</param>
    constructor Create(const AFactory: TFunc<string, T>);
    destructor Destroy; override;
    /// <summary>
    ///   Mod::loadRule: a node with the key gives the rule of that name (made if it is new); a node with "delete"
    ///   removes the rule and its place in the index and gives nil; a node with neither gives nil
    /// </summary>
    function LoadRule(const ANode: IYamlNode; const AKey: string = 'type'; AIndexed: Boolean = True): T;
    function Count: Integer;
    /// <summary>The name of the AIndex-th rule in the order of the names</summary>
    function Name(AIndex: Integer): string;
    /// <summary>The AIndex-th rule in the order of the names</summary>
    function Rule(AIndex: Integer): T;
    /// <summary>nil if there is no rule with the name</summary>
    function Find(const AName: string): T;
    /// <summary>The names in the order the rules were made (_xxxIndex)</summary>
    function Index: TArray<string>;
    /// <summary>Replaces the order of the index (Mod::sortLists)</summary>
    procedure SetIndex(const ANames: TArray<string>);
  end;

implementation

{ TXcomRuleRegistry<T> }

constructor TXcomRuleRegistry<T>.Create(const AFactory: TFunc<string, T>);
begin
  inherited Create;
  FFactory := AFactory;
  FMap := TXcomStringMap<T>.Create;
  FIndex := TList<string>.Create;
end;

destructor TXcomRuleRegistry<T>.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FMap.Count - 1 do
    FMap.Value(LIndex).Free;
  FMap.Free;
  FIndex.Free;
  inherited Destroy;
end;

function TXcomRuleRegistry<T>.LoadRule(const ANode: IYamlNode; const AKey: string; AIndexed: Boolean): T;
var
  LType: string;
  LPosition: Integer;
  LOld: T;
begin
  Result := nil;
  if TXcomNodeReader.Field(ANode, AKey).IsDefined then
  begin
    LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(ANode, AKey));
    if not FMap.TryGetValue(LType, Result) then
    begin
      Result := FFactory(LType);
      FMap.SetValue(LType, Result);
      if AIndexed then
        FIndex.Add(LType);
    end;
  end
  else if TXcomNodeReader.Field(ANode, 'delete').IsDefined then
  begin
    LType := TXcomNodeReader.TextOf(TXcomNodeReader.Field(ANode, 'delete'));
    if FMap.TryGetValue(LType, LOld) then
    begin
      FMap.Remove(LType);
      LOld.Free;
    end;
    if AIndexed then
    begin
      LPosition := FIndex.IndexOf(LType);
      if LPosition >= 0 then
        FIndex.Delete(LPosition);
    end;
  end;
end;

function TXcomRuleRegistry<T>.Count: Integer;
begin
  Result := FMap.Count;
end;

function TXcomRuleRegistry<T>.Name(AIndex: Integer): string;
begin
  Result := FMap.Key(AIndex);
end;

function TXcomRuleRegistry<T>.Rule(AIndex: Integer): T;
begin
  Result := FMap.Value(AIndex);
end;

function TXcomRuleRegistry<T>.Find(const AName: string): T;
begin
  if not FMap.TryGetValue(AName, Result) then
    Result := nil;
end;

function TXcomRuleRegistry<T>.Index: TArray<string>;
begin
  Result := FIndex.ToArray;
end;

procedure TXcomRuleRegistry<T>.SetIndex(const ANames: TArray<string>);
begin
  FIndex.Clear;
  FIndex.AddRange(ANames);
end;

end.
