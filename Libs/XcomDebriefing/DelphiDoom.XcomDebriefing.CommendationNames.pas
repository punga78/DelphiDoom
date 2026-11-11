{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the name of the level of a medal, as   }
{  CommendationState and CommendationLateState of OpenXcom work it out          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.CommendationNames;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomSave.SoldierCommendation;

type
  /// <summary>The keys of the language file that the two screens of the medals show for a commendation</summary>
  TXcomCommendationNames = class
  public
    const
      /// <summary>The noun of a commendation that has none</summary>
      NO_NOUN = 'noNoun';
  public
    /// <summary>
    ///   The key of the level ("STR_AWARD_n"): the level of the commendation less the levels that the rule repeats
    ///   (two equal thresholds in a row in the first criterion are one name). A rule without criteria skips nothing
    /// </summary>
    class function LevelKey(const ARule: TXcomRuleCommendations; const ACommendation: TXcomSoldierCommendation): string;
      static;
  end;

implementation

{ TXcomCommendationNames }

class function TXcomCommendationNames.LevelKey(const ARule: TXcomRuleCommendations;
  const ACommendation: TXcomSoldierCommendation): string;
var
  LThresholds: TArray<Integer>;
  LSkipCounter, LLastValue, LIndex: Integer;
begin
  LSkipCounter := 0;
  LThresholds := nil;
  if ARule.Criteria.Count > 0 then
    LThresholds := ARule.Criteria.Value(0);
  for LIndex := 0 to High(LThresholds) do
  begin
    if LIndex = ACommendation.DecorationLevel + 1 then
      Break;
    if LIndex > 0 then
      LLastValue := LThresholds[LIndex - 1]
    else
      LLastValue := -2;
    if LThresholds[LIndex] = LLastValue then
      Inc(LSkipCounter);
  end;
  Result := 'STR_AWARD_' + IntToStr(ACommendation.DecorationLevel - LSkipCounter);
end;

end.
