{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the diary rules of a ruleset           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.RulesetDiaryRules;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.DiaryRules.Intf;

type
  /// <summary>IXcomDiaryRules over a ruleset. The ruleset owns the rules and must outlive the adapter</summary>
  TXcomRulesetDiaryRules = class(TInterfacedObject, IXcomDiaryRules)
  strict private
    FRuleset: TXcomRuleset;
  public
    constructor Create(const ARuleset: TXcomRuleset);
    function Commendations: TXcomStringMap<TXcomRuleCommendations>;
    function FindItem(const AName: string; out ABattleType, ADamageType: Integer): Boolean;
    function UfoCount: Integer;
    function DeploymentCount: Integer;
    function CountryCount: Integer;
  end;

implementation

{ TXcomRulesetDiaryRules }

constructor TXcomRulesetDiaryRules.Create(const ARuleset: TXcomRuleset);
begin
  inherited Create;
  if not Assigned(ARuleset) then
    raise EArgumentNilException.Create('ARuleset');
  FRuleset := ARuleset;
end;

function TXcomRulesetDiaryRules.Commendations: TXcomStringMap<TXcomRuleCommendations>;
begin
  Result := FRuleset.Commendations;
end;

function TXcomRulesetDiaryRules.FindItem(const AName: string; out ABattleType, ADamageType: Integer): Boolean;
var
  LItem: TXcomRuleItem;
begin
  LItem := FRuleset.Items.Find(AName);
  Result := Assigned(LItem);
  if Result then
  begin
    ABattleType := LItem.BattleType;
    ADamageType := LItem.DamageType;
  end
  else
  begin
    ABattleType := 0;
    ADamageType := 0;
  end;
end;

function TXcomRulesetDiaryRules.UfoCount: Integer;
begin
  Result := Length(FRuleset.Ufos.Index);
end;

function TXcomRulesetDiaryRules.DeploymentCount: Integer;
begin
  Result := Length(FRuleset.AlienDeployments.Index);
end;

function TXcomRulesetDiaryRules.CountryCount: Integer;
begin
  Result := Length(FRuleset.Countries.Index);
end;

end.
