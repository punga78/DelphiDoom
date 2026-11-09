{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the rules of the ruleset seen as the   }
{  small interfaces that a saved game asks for (Rules.Intf)                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.RuleAdapters;

interface

uses
  System.SysUtils, DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomMod.AlienDeployment,
  DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomMod.RuleCraftWeapon;

type
  /// <summary>
  ///   IXcomDeploymentRule on a TXcomAlienDeployment of the ruleset. The adapter does not own the rule: the
  ///   ruleset does, and must outlive it
  /// </summary>
  TXcomDeploymentRuleAdapter = class(TInterfacedObject, IXcomDeploymentRule)
  strict private
    FRule: TXcomAlienDeployment;
  public
    constructor Create(const ARule: TXcomAlienDeployment);
    function DeploymentType: string;
    function MarkerName: string;
    function MarkerIcon: Integer;
  end;

  /// <summary>IXcomMissionRule on a TXcomRuleAlienMission (not owned)</summary>
  TXcomMissionRuleAdapter = class(TInterfacedObject, IXcomMissionRule)
  strict private
    FRule: TXcomRuleAlienMission;
  public
    constructor Create(const ARule: TXcomRuleAlienMission);
    function MissionType: string;
  end;

  /// <summary>IXcomItemRule on a TXcomRuleItem (not owned)</summary>
  TXcomItemRuleAdapter = class(TInterfacedObject, IXcomItemRule)
  strict private
    FRule: TXcomRuleItem;
  public
    constructor Create(const ARule: TXcomRuleItem);
    function ItemType: string;
  end;

  /// <summary>IXcomFacilityRule on a TXcomRuleBaseFacility (not owned)</summary>
  TXcomFacilityRuleAdapter = class(TInterfacedObject, IXcomFacilityRule)
  strict private
    FRule: TXcomRuleBaseFacility;
  public
    constructor Create(const ARule: TXcomRuleBaseFacility);
    function FacilityType: string;
  end;

  /// <summary>IXcomCraftWeaponRule on a TXcomRuleCraftWeapon (not owned)</summary>
  TXcomCraftWeaponRuleAdapter = class(TInterfacedObject, IXcomCraftWeaponRule)
  strict private
    FRule: TXcomRuleCraftWeapon;
  public
    constructor Create(const ARule: TXcomRuleCraftWeapon);
    function WeaponType: string;
    function AmmoMax: Integer;
    function RearmRate: Integer;
  end;

implementation

{ TXcomDeploymentRuleAdapter }

constructor TXcomDeploymentRuleAdapter.Create(const ARule: TXcomAlienDeployment);
begin
  inherited Create;
  if not Assigned(ARule) then
    raise EArgumentNilException.Create('ARule');
  FRule := ARule;
end;

function TXcomDeploymentRuleAdapter.DeploymentType: string;
begin
  Result := FRule.DeploymentType;
end;

function TXcomDeploymentRuleAdapter.MarkerName: string;
begin
  Result := FRule.MarkerName;
end;

function TXcomDeploymentRuleAdapter.MarkerIcon: Integer;
begin
  Result := FRule.MarkerIcon;
end;

{ TXcomMissionRuleAdapter }

constructor TXcomMissionRuleAdapter.Create(const ARule: TXcomRuleAlienMission);
begin
  inherited Create;
  if not Assigned(ARule) then
    raise EArgumentNilException.Create('ARule');
  FRule := ARule;
end;

function TXcomMissionRuleAdapter.MissionType: string;
begin
  Result := FRule.MissionType;
end;

{ TXcomItemRuleAdapter }

constructor TXcomItemRuleAdapter.Create(const ARule: TXcomRuleItem);
begin
  inherited Create;
  if not Assigned(ARule) then
    raise EArgumentNilException.Create('ARule');
  FRule := ARule;
end;

function TXcomItemRuleAdapter.ItemType: string;
begin
  Result := FRule.ItemType;
end;

{ TXcomFacilityRuleAdapter }

constructor TXcomFacilityRuleAdapter.Create(const ARule: TXcomRuleBaseFacility);
begin
  inherited Create;
  if not Assigned(ARule) then
    raise EArgumentNilException.Create('ARule');
  FRule := ARule;
end;

function TXcomFacilityRuleAdapter.FacilityType: string;
begin
  Result := FRule.FacilityType;
end;

{ TXcomCraftWeaponRuleAdapter }

constructor TXcomCraftWeaponRuleAdapter.Create(const ARule: TXcomRuleCraftWeapon);
begin
  inherited Create;
  if not Assigned(ARule) then
    raise EArgumentNilException.Create('ARule');
  FRule := ARule;
end;

function TXcomCraftWeaponRuleAdapter.WeaponType: string;
begin
  Result := FRule.WeaponType;
end;

function TXcomCraftWeaponRuleAdapter.AmmoMax: Integer;
begin
  Result := FRule.AmmoMax;
end;

function TXcomCraftWeaponRuleAdapter.RearmRate: Integer;
begin
  Result := FRule.RearmRate;
end;

end.
