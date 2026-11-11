{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - the diary rules from a    }
{  YAML file (a fake of IXcomDiaryRules)                                        }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.FakeDiaryRules;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleCommendations,
  DelphiDoom.XcomSave.DiaryRules.Intf;

type
  /// <summary>
  ///   The rules of diary.rules.yml (commendations, items, and the number of UFOs, deployments and countries)
  ///   as the diary reads them. Owns the commendations
  /// </summary>
  TXcomFakeDiaryRules = class(TInterfacedObject, IXcomDiaryRules)
  strict private
    FCommendations: TXcomStringMap<TXcomRuleCommendations>;
    FBattleTypes: TDictionary<string, Integer>;
    FDamageTypes: TDictionary<string, Integer>;
    FUfos: Integer;
    FDeployments: Integer;
    FCountries: Integer;
  public
    constructor Create(const AYamlText: string);
    destructor Destroy; override;
    function Commendations: TXcomStringMap<TXcomRuleCommendations>;
    function FindItem(const AName: string; out ABattleType, ADamageType: Integer): Boolean;
    function UfoCount: Integer;
    function DeploymentCount: Integer;
    function CountryCount: Integer;
  end;

implementation

{ TXcomFakeDiaryRules }

constructor TXcomFakeDiaryRules.Create(const AYamlText: string);
var
  LDocument, LItem: IYamlNode;
  LRule: TXcomRuleCommendations;
  LType: string;
begin
  inherited Create;
  FCommendations := TXcomStringMap<TXcomRuleCommendations>.Create;
  FBattleTypes := TDictionary<string, Integer>.Create;
  FDamageTypes := TDictionary<string, Integer>.Create;
  LDocument := TYamlFactory.CreateParser.Load(YamlStringToText(AYamlText));
  FUfos := LDocument.Child('ufos').Size;
  FDeployments := LDocument.Child('deployments').Size;
  FCountries := LDocument.Child('countries').Size;
  for LItem in LDocument.Child('items').Items do
  begin
    LType := YamlTextToString(LItem.Child('type').AsString);
    FBattleTypes.Add(LType, LItem.Child('battleType').AsInteger);
    FDamageTypes.Add(LType, LItem.Child('damageType').AsInteger);
  end;
  for LItem in LDocument.Child('commendations').Items do
  begin
    LRule := TXcomRuleCommendations.Create;
    LRule.Load(LItem);
    FCommendations.SetValue(YamlTextToString(LItem.Child('type').AsString), LRule);
  end;
end;

destructor TXcomFakeDiaryRules.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCommendations.Count - 1 do
    FCommendations.Value(LIndex).Free;
  FCommendations.Free;
  FDamageTypes.Free;
  FBattleTypes.Free;
  inherited Destroy;
end;

function TXcomFakeDiaryRules.Commendations: TXcomStringMap<TXcomRuleCommendations>;
begin
  Result := FCommendations;
end;

function TXcomFakeDiaryRules.FindItem(const AName: string; out ABattleType, ADamageType: Integer): Boolean;
begin
  Result := FBattleTypes.TryGetValue(AName, ABattleType);
  if Result then
    ADamageType := FDamageTypes[AName]
  else
  begin
    ABattleType := 0;
    ADamageType := 0;
  end;
end;

function TXcomFakeDiaryRules.UfoCount: Integer;
begin
  Result := FUfos;
end;

function TXcomFakeDiaryRules.DeploymentCount: Integer;
begin
  Result := FDeployments;
end;

function TXcomFakeDiaryRules.CountryCount: Integer;
begin
  Result := FCountries;
end;

end.
