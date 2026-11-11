{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the rules that a soldier diary asks    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.DiaryRules.Intf;

interface

uses
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.RuleCommendations;

type
  /// <summary>
  ///   What SoldierDiary::updateDiary and manageCommendations read of the Mod: the commendations, the battle and
  ///   damage type of an item, and how many UFOs, deployments and countries there are. The ruleset adapter
  ///   (TXcomRulesetDiaryRules) implements it; tests use a fake
  /// </summary>
  IXcomDiaryRules = interface
    ['{3C0B7F1A-5D52-4E0C-9A31-176000000011}']
    /// <summary>getCommendationsList (by name, in the byte order of the names)</summary>
    function Commendations: TXcomStringMap<TXcomRuleCommendations>;
    /// <summary>getItem: false if the ruleset has no item with the name</summary>
    function FindItem(const AName: string; out ABattleType, ADamageType: Integer): Boolean;
    /// <summary>getUfosList().size()</summary>
    function UfoCount: Integer;
    /// <summary>getDeploymentsList().size()</summary>
    function DeploymentCount: Integer;
    /// <summary>getCountriesList().size()</summary>
    function CountryCount: Integer;
  end;

implementation

end.
