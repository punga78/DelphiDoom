{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the rules of a ruleset, by name, as    }
{  the interfaces of Rules.Intf (the Mod::getXxx that a saved game calls)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.RulesetRules;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Rules.Intf;

type
  /// <summary>
  ///   Gives the rules of a ruleset to the saved game objects: Mod::getAlienDeployment, getAlienMission, getItem,
  ///   getBaseFacility and getCraftWeapon as the small interfaces they ask for. Each function gives nil if the
  ///   ruleset has no rule of that name. The ruleset owns the rules and must outlive what is given
  /// </summary>
  TXcomRulesetRules = class
  strict private
    FRuleset: TXcomRuleset;
  public
    constructor Create(const ARuleset: TXcomRuleset);
    function Deployment(const AType: string): IXcomDeploymentRule;
    function Mission(const AType: string): IXcomMissionRule;
    function Item(const AType: string): IXcomItemRule;
    function Facility(const AType: string): IXcomFacilityRule;
    function CraftWeapon(const AType: string): IXcomCraftWeaponRule;
  end;

implementation

uses
  DelphiDoom.XcomSave.RuleAdapters;

{ TXcomRulesetRules }

constructor TXcomRulesetRules.Create(const ARuleset: TXcomRuleset);
begin
  inherited Create;
  if not Assigned(ARuleset) then
    raise EArgumentNilException.Create('ARuleset');
  FRuleset := ARuleset;
end;

function TXcomRulesetRules.Deployment(const AType: string): IXcomDeploymentRule;
begin
  if Assigned(FRuleset.AlienDeployments.Find(AType)) then
    Result := TXcomDeploymentRuleAdapter.Create(FRuleset.AlienDeployments.Find(AType))
  else
    Result := nil;
end;

function TXcomRulesetRules.Mission(const AType: string): IXcomMissionRule;
begin
  if Assigned(FRuleset.AlienMissions.Find(AType)) then
    Result := TXcomMissionRuleAdapter.Create(FRuleset.AlienMissions.Find(AType))
  else
    Result := nil;
end;

function TXcomRulesetRules.Item(const AType: string): IXcomItemRule;
begin
  if Assigned(FRuleset.Items.Find(AType)) then
    Result := TXcomItemRuleAdapter.Create(FRuleset.Items.Find(AType))
  else
    Result := nil;
end;

function TXcomRulesetRules.Facility(const AType: string): IXcomFacilityRule;
begin
  if Assigned(FRuleset.Facilities.Find(AType)) then
    Result := TXcomFacilityRuleAdapter.Create(FRuleset.Facilities.Find(AType))
  else
    Result := nil;
end;

function TXcomRulesetRules.CraftWeapon(const AType: string): IXcomCraftWeaponRule;
begin
  if Assigned(FRuleset.CraftWeapons.Find(AType)) then
    Result := TXcomCraftWeaponRuleAdapter.Create(FRuleset.CraftWeapons.Find(AType))
  else
    Result := nil;
end;

end.
