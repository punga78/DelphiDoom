{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - MonthlyReportState of OpenXcom (the      }
{  report of the council at the end of the month)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.MonthlyReportState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomStrategy.MonthlyReport, DelphiDoom.XcomGeoscape.Control.Intf, System.Generics.Collections,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.DiaryRules.Intf;

type
  /// <summary>
  ///   The report: the month, the rating, the income with its change, the maintenance, the balance and the words
  ///   of the council with the countries that are pleased, unhappy or that signed a pact. The month is calculated when
  ///   the state is made (it changes the funding of the countries), as in the C++. When the game is lost the first OK
  ///   shows "You have failed" and the second leaves for the statistics of the game (the film and the slides of
  ///   CutsceneState are not ported: what follows them is). After a month that goes on, OK counts the month of
  ///   service of every soldier, opens the psi training of the bases with laboratories and saves the game (the
  ///   autosave of the options or the save of an ironman game). With SetMedals the soldiers that the month of
  ///   service gives a medal to are told to the caller (manageCommendations; CommendationState is of another
  ///   library)
  /// </summary>
  TXcomMonthlyReportState = class(TXcomState)
  strict private
    FResult: TXcomMonthlyReportResult;
    FPsi: Boolean;
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnBigOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtMonth: TXcomText;
    FTxtRating: TXcomText;
    FTxtIncome: TXcomText;
    FTxtMaintenance: TXcomText;
    FTxtBalance: TXcomText;
    FTxtDesc: TXcomText;
    FTxtFailure: TXcomText;
    FDiaryRules: IXcomDiaryRules;
    FOnMedals: TProc<TList<TXcomSoldier>>;
    procedure OkClick(AAction: TXcomAction);
    procedure AddMonthlyService;
    procedure SaveAfterMonth;
    function CountryList(const ACountries: TArray<string>; const ASingular, APlural: string): string;
  public
    /// <param name="AResult">What the council decided (calculated by TXcomMonthlyReport, which changed the game)</param>
    /// <param name="APsi">A base has psi laboratories: the psi training screen follows the report</param>
    /// <param name="AControl">The geoscape, which opens the screens that follow the report (nil: none is opened)</param>
    constructor Create(AHost: TXcomStateHost; const AResult: TXcomMonthlyReportResult; APsi: Boolean = False;
      const AControl: IXcomGeoscapeControl = nil);
    procedure Init; override;
    /// <summary>
    ///   The medals of the end of the month: after the month of service every soldier of the bases is checked against
    ///   the commendations of the rules (SoldierDiary::manageCommendations), and the ones that got a medal are given
    ///   to AOnMedals, which shows them (the list is freed after the call). Without rules only the month is counted
    /// </summary>
    procedure SetMedals(const ADiaryRules: IXcomDiaryRules; const AOnMedals: TProc<TList<TXcomSoldier>>);
    property Result: TXcomMonthlyReportResult read FResult;
    property Description: TXcomText read FTxtDesc;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.CommendationManager,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.Funding, DelphiDoom.XcomBasescape.Navigator.Intf,
  DelphiDoom.XcomEngine.LocalizedText, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomEngine.Session.Intf,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.SaveGameState;

const
  MONTHS: array[1..12] of string = ('STR_JAN', 'STR_FEB', 'STR_MAR', 'STR_APR', 'STR_MAY', 'STR_JUN', 'STR_JUL',
    'STR_AUG', 'STR_SEP', 'STR_OCT', 'STR_NOV', 'STR_DEC');
  END_LOSE = 2;

{ TXcomMonthlyReportState }

constructor TXcomMonthlyReportState.Create(AHost: TXcomStateHost; const AResult: TXcomMonthlyReportResult;
  APsi: Boolean; const AControl: IXcomGeoscapeControl);
var
  LSave: TXcomSavedGame;
  LMonth, LYear: Integer;
  LText: string;
begin
  inherited Create(AHost);
  FResult := AResult;
  FPsi := APsi;
  FControl := AControl;
  LSave := TXcomStrategy.SavedGame(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpNone);
  FBtnOk := TXcomTextButton.Create(50, 12, 135, 180);
  FBtnBigOk := TXcomTextButton.Create(120, 18, 100, 174);
  FTxtTitle := TXcomText.Create(300, 17, 16, 8);
  FTxtMonth := TXcomText.Create(130, 9, 16, 24);
  FTxtRating := TXcomText.Create(160, 9, 146, 24);
  FTxtIncome := TXcomText.Create(300, 9, 16, 32);
  FTxtMaintenance := TXcomText.Create(130, 9, 16, 40);
  FTxtBalance := TXcomText.Create(160, 9, 146, 40);
  FTxtDesc := TXcomText.Create(280, 132, 16, 48);
  FTxtFailure := TXcomText.Create(290, 160, 15, 10);
  SetInterface('monthlyReport');
  Add(FWindow, 'window', 'monthlyReport');
  Add(FBtnOk, 'button', 'monthlyReport');
  Add(FBtnBigOk, 'button', 'monthlyReport');
  Add(FTxtTitle, 'text1', 'monthlyReport');
  Add(FTxtMonth, 'text1', 'monthlyReport');
  Add(FTxtRating, 'text1', 'monthlyReport');
  Add(FTxtIncome, 'text1', 'monthlyReport');
  Add(FTxtMaintenance, 'text1', 'monthlyReport');
  Add(FTxtBalance, 'text1', 'monthlyReport');
  Add(FTxtDesc, 'text2', 'monthlyReport');
  Add(FTxtFailure, 'text2', 'monthlyReport');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnBigOk.SetText(Tr('STR_OK'));
  FBtnBigOk.OnMouseClick(OkClick);
  FBtnBigOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnBigOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnBigOk.Visible := False;
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_XCOM_PROJECT_MONTHLY_REPORT'));
  FTxtFailure.SetBig;
  FTxtFailure.SetAlign(haCenter);
  FTxtFailure.SetVerticalAlign(vaMiddle);
  FTxtFailure.SetWordWrap(True);
  FTxtFailure.SetText(Tr('STR_YOU_HAVE_FAILED'));
  FTxtFailure.Visible := False;
  // the month that ended
  LMonth := LSave.Time.Month - 1;
  LYear := LSave.Time.Year;
  if LMonth = 0 then
  begin
    LMonth := 12;
    Dec(LYear);
  end;
  FTxtMonth.SetText(Tr('STR_MONTH').Arg(Tr(MONTHS[LMonth]).Text).Arg(LYear));
  FTxtRating.SetText(Tr('STR_MONTHLY_RATING').Arg(FResult.RatingTotal).Arg(Tr(FResult.Rating).Text));
  LText := Tr('STR_INCOME').Text + '> ' + Chr(XCOM_TOKEN_COLOR_FLIP) + TXcomFunding.Format(LSave.CountryFunding) + ' (';
  if FResult.FundingDiff > 0 then
    LText := LText + '+';
  FTxtIncome.SetText(LText + TXcomFunding.Format(FResult.FundingDiff) + ')');
  FTxtMaintenance.SetText(Tr('STR_MAINTENANCE').Text + '> ' + Chr(XCOM_TOKEN_COLOR_FLIP) +
    TXcomFunding.Format(LSave.MaintenanceList[High(LSave.MaintenanceList) - 1]));
  FTxtBalance.SetText(Tr('STR_BALANCE').Text + '> ' + Chr(XCOM_TOKEN_COLOR_FLIP) + TXcomFunding.Format(LSave.Funds));
  FTxtDesc.SetWordWrap(True);
  LText := Tr(FResult.Satisfaction).Text;
  if FResult.Debts then
    LText := LText + #10#10 + Tr('STR_COUNCIL_REDUCE_DEBTS').Text;
  LText := LText + CountryList(FResult.Happy, 'STR_COUNTRY_IS_PARTICULARLY_PLEASED',
    'STR_COUNTRIES_ARE_PARTICULARLY_HAPPY');
  LText := LText + CountryList(FResult.Sad, 'STR_COUNTRY_IS_UNHAPPY_WITH_YOUR_ABILITY',
    'STR_COUNTRIES_ARE_UNHAPPY_WITH_YOUR_ABILITY');
  LText := LText + CountryList(FResult.Pact, 'STR_COUNTRY_HAS_SIGNED_A_SECRET_PACT',
    'STR_COUNTRIES_HAVE_SIGNED_A_SECRET_PACT');
  FTxtDesc.SetText(LText);
end;

function TXcomMonthlyReportState.CountryList(const ACountries: TArray<string>; const ASingular,
  APlural: string): string;
var
  LList: TXcomLocalizedText;
  LIndex: Integer;
begin
  Result := '';
  if Length(ACountries) = 0 then
    Exit;
  Result := #10#10;
  if Length(ACountries) = 1 then
    Result := Result + Tr(ASingular).Arg(Tr(ACountries[0]).Text).Text
  else
  begin
    LList := Tr(ACountries[0]);
    for LIndex := 1 to High(ACountries) - 1 do
      LList := Tr('STR_COUNTRIES_COMMA').Arg(LList.Text).Arg(Tr(ACountries[LIndex]).Text);
    LList := Tr('STR_COUNTRIES_AND').Arg(LList.Text).Arg(Tr(ACountries[High(ACountries)]).Text);
    Result := Result + Tr(APlural).Arg(LList.Text).Text;
  end;
end;

procedure TXcomMonthlyReportState.Init;
begin
  inherited Init;
  // make sure the game is over
  if FResult.GameOver then
    TXcomStrategy.SavedGame(Host).EndingKind := END_LOSE;
end;

procedure TXcomMonthlyReportState.AddMonthlyService;
var
  LSave: TXcomSavedGame;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LMedalled: TList<TXcomSoldier>;
  LManager: TXcomCommendationManager;
begin
  LSave := TXcomStrategy.SavedGame(Host);
  LMedalled := TList<TXcomSoldier>.Create;
  try
    for LBase in LSave.Bases do
      for LSoldier in LBase.Soldiers do
      begin
        LSoldier.Diary.AddMonthlyService;
        if not Assigned(FDiaryRules) then
          Continue;
        LManager := TXcomCommendationManager.Create(LSoldier.Diary, FDiaryRules, LSave.MissionStatistics);
        try
          if LManager.Manage then
            LMedalled.Add(LSoldier);
        finally
          LManager.Free;
        end;
      end;
    if (LMedalled.Count > 0) and Assigned(FOnMedals) then
      FOnMedals(LMedalled);
  finally
    LMedalled.Free;
  end;
end;

procedure TXcomMonthlyReportState.SetMedals(const ADiaryRules: IXcomDiaryRules;
  const AOnMedals: TProc<TList<TXcomSoldier>>);
begin
  FDiaryRules := ADiaryRules;
  FOnMedals := AOnMedals;
end;

procedure TXcomMonthlyReportState.SaveAfterMonth;
var
  LSaver: IXcomSavedGameSaver;
begin
  LSaver := Host.SavedGameSaver;
  if LSaver = nil then
    Exit;
  if LSaver.IsIronman then
    Host.PushState(TXcomSaveGameState.Create(Host, ooGeoscape, stIronman, Palette))
  else if not FResult.GameOver and Host.Options.GetBool('autosave') then
    Host.PushState(TXcomSaveGameState.Create(Host, ooGeoscape, stAutoGeoscape, Palette));
end;

procedure TXcomMonthlyReportState.OkClick(AAction: TXcomAction);
var
  LElement: TXcomInterfaceElement;
  LInterface: TXcomRuleInterface;
begin
  if not FResult.GameOver then
  begin
    Host.PopState;
    AddMonthlyService;
    if FPsi and Assigned(FControl) then
      FControl.OpenBaseScreen(bsPsiTraining, nil);
    SaveAfterMonth;
  end
  else if FTxtFailure.Visible then
  begin
    // CutsceneState(LOSE_GAME): it takes itself away and sets the statistics of the game as the only state
    if Assigned(FControl) then
    begin
      FControl.OpenBaseScreen(bsStatistics, nil);
      SaveAfterMonth;
    end;
  end
  else
  begin
    // the failure replaces the report
    LInterface := Host.Resources.GetInterface('monthlyReport');
    if (LInterface <> nil) and LInterface.TryGetElement('window', LElement) and (LElement.Color2 <> XCOM_UNSET) then
      FWindow.SetColor(LElement.Color2);
    FTxtTitle.Visible := False;
    FTxtMonth.Visible := False;
    FTxtRating.Visible := False;
    FTxtIncome.Visible := False;
    FTxtMaintenance.Visible := False;
    FTxtBalance.Visible := False;
    FTxtDesc.Visible := False;
    FBtnOk.Visible := False;
    FBtnBigOk.Visible := True;
    FTxtFailure.Visible := True;
    Host.PlayMusic('GMLOSE');
  end;
end;

end.
