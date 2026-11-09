{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - the rules of a real       }
{  ruleset (Libs\XcomMod) given to the saved game objects                       }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.RulesetRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomMod.ModOffsets, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.RulesetRules;

type
  /// <summary>Every set has 100 shared sprites and 20 shared sounds</summary>
  TXcomSaveFixedShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-rules')]
  TTestXcomRulesetRules = class(TObject)
  strict private
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeRegoleDelRegolamentoComeInterfacce;
    [Test]
    procedure DovrebbeDareNilPerUnaRegolaCheNonEsiste;
    [Test]
    procedure DovrebbeFarCostruireGliOggettiDellaPartitaConLeRegoleVere;
    [Test]
    procedure DovrebbeRifiutareUnRegolamentoMancante;
  end;

implementation

uses
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types, DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.RuleAdapters,
  DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomSave.Vehicle, DelphiDoom.XcomSave.CraftWeapon,
  DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.MissionSite;

{ TXcomSaveFixedShared }

function TXcomSaveFixedShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TXcomSaveFixedShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 100;
end;

{ TTestXcomRulesetRules }

procedure TTestXcomRulesetRules.Setup;
const
  LRules = '{items: [{type: STR_TANK, battleType: 0}], facilities: [{type: STR_LAB, labs: 2}], ' +
    'craftWeapons: [{type: STR_CANNON, ammoMax: 50, rearmRate: 4}], alienMissions: [{type: STR_SCOUT}], ' +
    'alienDeployments: [{type: STR_BASE, markerName: STR_ALIEN_BASE, markerIcon: 3}]}';
begin
  FRuleset := TXcomRuleset.Create(TXcomSaveFixedShared.Create);
  FRuleset.SetMods(TArray<TXcomModData>.Create(TXcomModData.Make('master', 0, 1000)), 0);
  FRuleset.LoadFile(TYamlFactory.CreateParser.Load(TEncoding.UTF8.GetBytes(LRules)));
  FRules := TXcomRulesetRules.Create(FRuleset);
end;

procedure TTestXcomRulesetRules.TearDown;
begin
  FRules.Free;
  FRuleset.Free;
end;

procedure TTestXcomRulesetRules.DovrebbeDareLeRegoleDelRegolamentoComeInterfacce;
begin
  Assert.AreEqual('STR_TANK', FRules.Item('STR_TANK').ItemType);
  Assert.AreEqual('STR_LAB', FRules.Facility('STR_LAB').FacilityType);
  Assert.AreEqual('STR_CANNON', FRules.CraftWeapon('STR_CANNON').WeaponType);
  Assert.AreEqual(50, FRules.CraftWeapon('STR_CANNON').AmmoMax);
  Assert.AreEqual(4, FRules.CraftWeapon('STR_CANNON').RearmRate);
  Assert.AreEqual('STR_SCOUT', FRules.Mission('STR_SCOUT').MissionType);
  Assert.AreEqual('STR_BASE', FRules.Deployment('STR_BASE').DeploymentType);
  Assert.AreEqual('STR_ALIEN_BASE', FRules.Deployment('STR_BASE').MarkerName);
  Assert.AreEqual(3, FRules.Deployment('STR_BASE').MarkerIcon);
end;

procedure TTestXcomRulesetRules.DovrebbeDareNilPerUnaRegolaCheNonEsiste;
begin
  Assert.IsFalse(Assigned(FRules.Item('NOPE')));
  Assert.IsFalse(Assigned(FRules.Facility('NOPE')));
  Assert.IsFalse(Assigned(FRules.CraftWeapon('NOPE')));
  Assert.IsFalse(Assigned(FRules.Mission('NOPE')));
  Assert.IsFalse(Assigned(FRules.Deployment('NOPE')));
end;

procedure TTestXcomRulesetRules.DovrebbeFarCostruireGliOggettiDellaPartitaConLeRegoleVere;
var
  LBase: TXcomAlienBase;
  LVehicle: TXcomVehicle;
  LWeapon: TXcomCraftWeapon;
  LFacility: TXcomBaseFacility;
  LSite: TXcomMissionSite;
begin
  LBase := TXcomAlienBase.Create(FRules.Deployment('STR_BASE'));
  LVehicle := TXcomVehicle.Create(FRules.Item('STR_TANK'), 10, 4);
  LWeapon := TXcomCraftWeapon.Create(FRules.CraftWeapon('STR_CANNON'), 20);
  LFacility := TXcomBaseFacility.Create(FRules.Facility('STR_LAB'));
  LSite := TXcomMissionSite.Create(FRules.Mission('STR_SCOUT'), FRules.Deployment('STR_BASE'));
  try
    Assert.AreEqual('STR_BASE', LBase.Deployment.DeploymentType);
    Assert.AreEqual('STR_TANK', LVehicle.Rules.ItemType);
    Assert.AreEqual(50, LWeapon.Rules.AmmoMax);
    Assert.AreEqual('STR_LAB', LFacility.Rules.FacilityType);
    Assert.AreEqual('STR_SCOUT', LSite.Rules.MissionType);
  finally
    LSite.Free;
    LFacility.Free;
    LWeapon.Free;
    LVehicle.Free;
    LBase.Free;
  end;
end;

procedure TTestXcomRulesetRules.DovrebbeRifiutareUnRegolamentoMancante;
begin
  Assert.WillRaise(procedure begin TXcomRulesetRules.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TXcomItemRuleAdapter.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TXcomMissionRuleAdapter.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TXcomFacilityRuleAdapter.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TXcomDeploymentRuleAdapter.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TXcomCraftWeaponRuleAdapter.Create(nil); end, EArgumentNilException);
end;

end.
