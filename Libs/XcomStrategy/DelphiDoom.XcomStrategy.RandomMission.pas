{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - Mod::getRandomMission (a mission of an  }
{  objective by the weights of the month)                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.RandomMission;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleAlienMission;

type
  /// <summary>Mod::getRandomMission: the mission rules go by name (the C++ keeps a std::map), weighted by the month</summary>
  TXcomRandomMission = class
  public
    /// <summary>The rule chosen with the random generator, nil if no rule of the objective has a weight this month</summary>
    class function Choose(const ARuleset: TXcomRuleset; const ARandom: IXcomRandom; AObjective: Integer;
      AMonthsPassed: Cardinal): TXcomRuleAlienMission; static;
  end;

implementation

type
  TWeightedMission = record
    Total: Integer;
    Rule: TXcomRuleAlienMission;
  end;

{ TXcomRandomMission }

class function TXcomRandomMission.Choose(const ARuleset: TXcomRuleset; const ARandom: IXcomRandom;
  AObjective: Integer; AMonthsPassed: Cardinal): TXcomRuleAlienMission;
var
  LNames: TArray<string>;
  LName: string;
  LRule: TXcomRuleAlienMission;
  LPossible: TList<TWeightedMission>;
  LEntry: TWeightedMission;
  LTotal, LPick: Integer;
begin
  Result := nil;
  LNames := Copy(ARuleset.AlienMissions.Index);
  TArray.Sort<string>(LNames, TComparer<string>.Construct(
    function(const ALeft, ARight: string): Integer
    begin
      Result := CompareStr(ALeft, ARight);
    end));
  LPossible := TList<TWeightedMission>.Create;
  try
    LTotal := 0;
    for LName in LNames do
    begin
      LRule := ARuleset.AlienMissions.Find(LName);
      if (LRule.Objective = AObjective) and (LRule.GetWeight(AMonthsPassed) > 0) then
      begin
        Inc(LTotal, LRule.GetWeight(AMonthsPassed));
        LEntry.Total := LTotal;
        LEntry.Rule := LRule;
        LPossible.Add(LEntry);
      end;
    end;
    if LTotal > 0 then
    begin
      LPick := ARandom.Generate(1, LTotal);
      for LEntry in LPossible do
        if LPick <= LEntry.Total then
          Exit(LEntry.Rule);
    end;
  finally
    LPossible.Free;
  end;
end;

end.
