{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the rules a saved game asks of Mod    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Rules.Intf;

interface

type
  /// <summary>
  ///   AlienDeployment as the saved game uses it: its type, the name of the marker on the globe and the marker
  ///   icon. The ruleset (Mod) implements it; tests use a fake
  /// </summary>
  IXcomDeploymentRule = interface
    ['{3C0B7F1A-5D52-4E0C-9A31-176000000001}']
    function DeploymentType: string;
    function MarkerName: string;
    /// <summary>The marker sprite, -1 if none</summary>
    function MarkerIcon: Integer;
  end;

  /// <summary>RuleAlienMission as the saved game uses it: its type</summary>
  IXcomMissionRule = interface
    ['{3C0B7F1A-5D52-4E0C-9A31-176000000002}']
    function MissionType: string;
  end;

implementation

end.
