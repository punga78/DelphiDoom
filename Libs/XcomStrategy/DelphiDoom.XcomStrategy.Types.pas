{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - types shared by the units of the library }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Types;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomMod.RuleManufacture;

type
  /// <summary>
  ///   The strategic logic met a situation that the C++ leaves undefined (a missing rule, a zone that does not
  ///   exist): here it is an error with the message of the C++ when there is one
  /// </summary>
  EXcomStrategyException = class(Exception);

  /// <summary>productionProgress_e: what a step of a production ended with</summary>
  TXcomProductionProgress = (ppNotComplete, ppComplete, ppNotEnoughMoney, ppNotEnoughMaterials);

  /// <summary>
  ///   What a finished research project brought (the popups that GeoscapeState::time1Day opens for it, in the order of
  ///   the C++): the topic, the topic that came free (nil if none), the topic that the Ufopaedia shows again (nil when
  ///   its entry was already known), the topics and the items that can now be researched or produced, and the weapon
  ///   whose ammunition is not researched yet ('' if none). The rules are not owned
  /// </summary>
  TXcomResearchOutcome = record
    Research: TXcomRuleResearch;
    Bonus: TXcomRuleResearch;
    NewResearch: TXcomRuleResearch;
    NewPossibleResearch: TArray<TXcomRuleResearch>;
    NewPossibleManufacture: TArray<TXcomRuleManufacture>;
    WeaponNeedingAmmo: string;
  end;

implementation

end.
