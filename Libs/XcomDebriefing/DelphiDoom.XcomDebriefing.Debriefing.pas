{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the end of a mission, without a screen  }
{  (the logic of DebriefingState: prepareDebriefing and init)                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Debriefing;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomSave.RulesetDiaryRules, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomDebriefing.Types, DelphiDoom.XcomDebriefing.Calculator, DelphiDoom.XcomDebriefing.Scorer;

type
  /// <summary>
  ///   Ends a battle: evaluates it, records it in the saved game and gives the report that the screen shows. The
  ///   saved game forgets its battle document (the caller frees the battle, which it owns)
  /// </summary>
  TXcomDebriefing = class
  public
    /// <summary>The caller owns the report</summary>
    class function Run(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame; const ARuleset: TXcomRuleset;
      const ARules: TXcomRulesetRules; const AOptions: TXcomDebriefingOptions;
      const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>): TXcomDebriefingReport; static;
  end;

implementation

{ TXcomDebriefing }

class function TXcomDebriefing.Run(const AGame: TXcomSavedGame; const ABattle: TXcomSavedBattleGame;
  const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules; const AOptions: TXcomDebriefingOptions;
  const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>): TXcomDebriefingReport;
var
  LCalculator: TXcomDebriefingCalculator;
  LScorer: TXcomDebriefingScorer;
begin
  Result := TXcomDebriefingReport.Create;
  try
    LCalculator := TXcomDebriefingCalculator.Create(AGame, ABattle, ARuleset, ARules, AOptions, Result,
      AZombieConverter);
    try
      LCalculator.Prepare;
    finally
      LCalculator.Free;
    end;
    LScorer := TXcomDebriefingScorer.Create(AGame, ABattle, TXcomRulesetDiaryRules.Create(ARuleset), AOptions, Result);
    try
      LScorer.Score;
    finally
      LScorer.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
