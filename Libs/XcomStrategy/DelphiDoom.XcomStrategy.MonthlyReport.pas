{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - what the council decides at the end of   }
{  a month (MonthlyReportState::calculateChanges and the judgment of its        }
{  constructor)                                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.MonthlyReport;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomSave.SavedGame;

type
  /// <summary>
  ///   What the monthly report shows and what it does to the game: the rating, the change in the funding, the
  ///   satisfaction of the council and the countries that are pleased, unhappy or that signed a pact
  /// </summary>
  TXcomMonthlyReportResult = record
    RatingTotal: Integer;
    LastMonthsRating: Integer;
    FundingDiff: Integer;
    /// <summary>The key of the text of the rating (STR_RATING_TERRIBLE ... STR_RATING_EXCELLENT)</summary>
    Rating: string;
    /// <summary>The key of the text of the council (STR_COUNCIL_IS_DISSATISFIED, STR_YOU_HAVE_NOT_SUCCEEDED...)</summary>
    Satisfaction: string;
    /// <summary>The council asks to reduce the debts (STR_COUNCIL_REDUCE_DEBTS): the game is warned</summary>
    Debts: Boolean;
    /// <summary>The game is lost</summary>
    GameOver: Boolean;
    Happy: TArray<string>;
    Sad: TArray<string>;
    Pact: TArray<string>;
    /// <summary>The infiltration mission that gave the points of a pact ('' if none)</summary>
    Infiltration: string;
  end;

  /// <summary>
  ///   The month of the council: the regions and the countries start a new month (the countries choose their
  ///   funding, and sign pacts), the rating is the activity of XCOM against the aliens, and the council judges it.
  ///   It changes the saved game (the activity lists, the funding, the warning of the debts) and uses the random
  ///   generator (the funding of the countries and the infiltration mission that gives the points of a pact)
  /// </summary>
  TXcomMonthlyReport = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    function RandomMission(AObjective: Integer; AMonthsPassed: Cardinal): TXcomRuleAlienMission;
  public
    constructor Create(AGame: TXcomSavedGame; ARuleset: TXcomRuleset; const ARandom: IXcomRandom);
    /// <summary>The month has been closed (AddMonth and the funding): the report of the month that ended</summary>
    function Calculate: TXcomMonthlyReportResult;
  end;

implementation

uses
  DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.Country, DelphiDoom.XcomMod.RulesetSettings,
  DelphiDoom.XcomStrategy.RandomMission;



{ TXcomMonthlyReport }

constructor TXcomMonthlyReport.Create(AGame: TXcomSavedGame; ARuleset: TXcomRuleset; const ARandom: IXcomRandom);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FRandom := ARandom;
end;

function TXcomMonthlyReport.RandomMission(AObjective: Integer; AMonthsPassed: Cardinal): TXcomRuleAlienMission;
begin
  Result := TXcomRandomMission.Choose(FRuleset, FRandom, AObjective, AMonthsPassed);
end;

function TXcomMonthlyReport.Calculate: TXcomMonthlyReportResult;
var
  LRegion: TXcomRegion;
  LCountry: TXcomCountry;
  LXcomSubTotal, LXcomTotal, LAlienTotal, LMonthOffset, LLastMonthOffset, LThreshold, LPactScore: Integer;
  LScores: TArray<Integer>;
  LInfiltration: TXcomRuleAlienMission;
  LResetWarning: Boolean;
  LHappy, LSad, LPact: TList<string>;
  LDifficulty: Integer;
begin
  Result := Default(TXcomMonthlyReportResult);
  LXcomSubTotal := 0;
  LAlienTotal := 0;
  LMonthOffset := Length(FGame.FundsList) - 2;
  LLastMonthOffset := Length(FGame.FundsList) - 3;
  if LLastMonthOffset < 0 then
    Inc(LLastMonthOffset, 2);
  LHappy := TList<string>.Create;
  LSad := TList<string>.Create;
  LPact := TList<string>.Create;
  try
    // the activity meters start a new month; the total of the regions and the score of the last month
    for LRegion in FGame.Regions do
    begin
      LRegion.NewMonth;
      if Length(LRegion.ActivityXcom) > 2 then
        Inc(Result.LastMonthsRating, LRegion.ActivityXcom[LLastMonthOffset] - LRegion.ActivityAlien[LLastMonthOffset]);
      Inc(LXcomSubTotal, LRegion.ActivityXcom[LMonthOffset]);
      Inc(LAlienTotal, LRegion.ActivityAlien[LMonthOffset]);
    end;
    // the research bonus is for the council only: it does not touch the decision of the countries. The council is
    // more lenient after the first month
    LScores := FGame.ResearchScores;
    if FGame.MonthsPassed > 1 then
      FGame.AddResearchScoreAt(LMonthOffset, 400);
    LScores := FGame.ResearchScores;
    LXcomTotal := LScores[LMonthOffset] + LXcomSubTotal;
    if Length(LScores) > 2 then
      Inc(Result.LastMonthsRating, LScores[LLastMonthOffset]);
    // the countries decide with the point of view of the council
    LInfiltration := RandomMission(TXcomRuleAlienMission.OBJECTIVE_INFILTRATION, Cardinal(FGame.MonthsPassed));
    LPactScore := 0;
    if Assigned(LInfiltration) then
    begin
      LPactScore := LInfiltration.Points;
      Result.Infiltration := LInfiltration.MissionType;
    end;
    for LCountry in FGame.Countries do
    begin
      // the new pact is told before the new month, which resets the flag
      if LCountry.NewPact then
        LPact.Add(LCountry.Rules.CountryType);
      LCountry.NewMonth(LXcomTotal, LAlienTotal, LPactScore, FRandom);
      Inc(Result.FundingDiff, LCountry.Funding[High(LCountry.Funding)] - LCountry.Funding[High(LCountry.Funding) - 1]);
      case LCountry.Satisfaction of
        1: LSad.Add(LCountry.Rules.CountryType);
        3: LHappy.Add(LCountry.Rules.CountryType);
      end;
    end;
    Result.RatingTotal := LXcomTotal - LAlienTotal;
    // the judgment of the council
    LDifficulty := FGame.Difficulty;
    if LDifficulty > 4 then
      LDifficulty := 4;
    LThreshold := FRuleset.Settings.DefeatScore + 100 * FRuleset.Settings.DifficultyCoefficient[LDifficulty];
    Result.Rating := 'STR_RATING_TERRIBLE';
    if Result.RatingTotal > LThreshold - 300 then
      Result.Rating := 'STR_RATING_POOR';
    if Result.RatingTotal > LThreshold then
      Result.Rating := 'STR_RATING_OK';
    if Result.RatingTotal > 0 then
      Result.Rating := 'STR_RATING_GOOD';
    if Result.RatingTotal > 500 then
      Result.Rating := 'STR_RATING_EXCELLENT';
    Result.Satisfaction := 'STR_COUNCIL_IS_DISSATISFIED';
    LResetWarning := True;
    if Result.RatingTotal > LThreshold then
      Result.Satisfaction := 'STR_COUNCIL_IS_GENERALLY_SATISFIED';
    if Result.RatingTotal > 500 then
      Result.Satisfaction := 'STR_COUNCIL_IS_VERY_PLEASED';
    if (Result.LastMonthsRating <= LThreshold) and (Result.RatingTotal <= LThreshold) then
    begin
      Result.Satisfaction := 'STR_YOU_HAVE_NOT_SUCCEEDED';
      LPact.Clear;
      LHappy.Clear;
      LSad.Clear;
      Result.GameOver := True;
    end;
    if not Result.GameOver and (FGame.Funds <= FRuleset.Settings.DefeatFunds) then
    begin
      if FGame.Warned then
      begin
        Result.Satisfaction := 'STR_YOU_HAVE_NOT_SUCCEEDED';
        LPact.Clear;
        LHappy.Clear;
        LSad.Clear;
        Result.GameOver := True;
      end
      else
      begin
        Result.Debts := True;
        FGame.Warned := True;
        LResetWarning := False;
      end;
    end;
    if LResetWarning and FGame.Warned then
      FGame.Warned := False;
    Result.Happy := LHappy.ToArray;
    Result.Sad := LSad.ToArray;
    Result.Pact := LPact.ToArray;
  finally
    LPact.Free;
    LSad.Free;
    LHappy.Free;
  end;
end;

end.
