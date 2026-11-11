{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - DebriefingState of OpenXcom (the        }
{  screen after a mission: the scores, what was recovered, the soldiers)         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.DebriefingState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomDebriefing.Types;

type
  /// <summary>
  ///   What the player does after the debriefing: the screens that follow it (commendations, promotions, containment,
  ///   storage, the autosave) belong to the host of the game, which receives the report
  /// </summary>
  TXcomDebriefingFinished = reference to procedure(const AReport: TXcomDebriefingReport);

  /// <summary>
  ///   The two pages of the debriefing: the score of the mission (the statistics, the recovered objects, the total and
  ///   the rating) and the improvement of the soldiers. The report is the one that TXcomDebriefing.Run gave
  ///   (not owned unless AOwnsReport). The name of a stat shows under the list while the mouse is on its heading
  /// </summary>
  TXcomDebriefingState = class(TXcomState)
  strict private
    FReport: TXcomDebriefingReport;
    FOnFinished: TXcomDebriefingFinished;
    FOwnsReport: Boolean;
    FShowSoldierStats: Boolean;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnStats: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtItem: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtScore: TXcomText;
    FTxtRecovery: TXcomText;
    FTxtRating: TXcomText;
    FLstStats: TXcomTextList;
    FLstRecovery: TXcomTextList;
    FLstTotal: TXcomTextList;
    FSoldierHeadings: array[0..11] of TXcomText;
    FLstSoldierStats: TXcomTextList;
    FTxtTooltip: TXcomText;
    FCurrentTooltip: string;
    FInitDone: Boolean;
    FMusic: string;
    function InterfaceColor(const AElement: string): Integer;
    procedure WatchTooltip(AHeading: TXcomText; const ATooltip: string);
    procedure OkClick(AAction: TXcomAction);
    procedure StatsClick(AAction: TXcomAction);
    procedure ApplyVisibility;
    procedure FillLists;
    class function SoldierString(AStat: Integer): string; static;
  public
    /// <param name="AReport">The report of the mission (not owned)</param>
    /// <param name="AOnFinished">Called after the state is closed with OK; can be nil</param>
    constructor Create(AHost: TXcomStateHost; const AReport: TXcomDebriefingReport;
      const AOnFinished: TXcomDebriefingFinished; AOwnsReport: Boolean = False);
    destructor Destroy; override;
    /// <summary>Shows the page of the soldiers (true) or the one of the score, as the Stats/Score button does</summary>
    procedure ShowPage(ASoldierStats: Boolean);
    /// <summary>
    ///   The first time the state comes to the front, a live alien that died because the base has no containment is
    ///   told with a message (the C++ pushes it at the end of init)
    /// </summary>
    procedure Init; override;
    /// <summary>
    ///   Mod::playMusic of DebriefingState::init: the music that starts the first time the state comes to the front
    ///   (the one of the rules for a mission that went well or badly); empty: the music goes on as it is
    /// </summary>
    property Music: string read FMusic write FMusic;
    property StatsList: TXcomTextList read FLstStats;
    property RecoveryList: TXcomTextList read FLstRecovery;
    property TotalList: TXcomTextList read FLstTotal;
    property SoldierStatsList: TXcomTextList read FLstSoldierStats;
    property TitleText: TXcomText read FTxtTitle;
    property RatingText: TXcomText read FTxtRating;
    property RecoveryText: TXcomText read FTxtRecovery;
    property ShowSoldierStats: Boolean read FShowSoldierStats;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomMenu.ErrorMessageState;

const
  SOLDIER_HEADINGS: array[0..10] of string = ('STR_TIME_UNITS_ABBREVIATION', 'STR_STAMINA_ABBREVIATION',
    'STR_HEALTH_ABBREVIATION', 'STR_BRAVERY_ABBREVIATION', 'STR_REACTIONS_ABBREVIATION',
    'STR_FIRING_ACCURACY_ABBREVIATION', 'STR_THROWING_ACCURACY_ABBREVIATION', 'STR_MELEE_ACCURACY_ABBREVIATION',
    'STR_STRENGTH_ABBREVIATION', 'STR_PSIONIC_STRENGTH_ABBREVIATION', 'STR_PSIONIC_SKILL_ABBREVIATION');
  SOLDIER_TOOLTIPS: array[0..10] of string = ('STR_TIME_UNITS', 'STR_STAMINA', 'STR_HEALTH', 'STR_BRAVERY',
    'STR_REACTIONS', 'STR_FIRING_ACCURACY', 'STR_THROWING_ACCURACY', 'STR_MELEE_ACCURACY', 'STR_STRENGTH',
    'STR_PSIONIC_STRENGTH', 'STR_PSIONIC_SKILL');
  HEADING_X: array[0..10] of Integer = (106, 124, 142, 160, 178, 196, 214, 232, 250, 268, 286);

{ TXcomDebriefingState }

constructor TXcomDebriefingState.Create(AHost: TXcomStateHost; const AReport: TXcomDebriefingReport;
  const AOnFinished: TXcomDebriefingFinished; AOwnsReport: Boolean);
var
  LIndex: Integer;
begin
  inherited Create(AHost);
  FReport := AReport;
  FOnFinished := AOnFinished;
  FOwnsReport := AOwnsReport;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(40, 12, 16, 180);
  FBtnStats := TXcomTextButton.Create(40, 12, 264, 180);
  FTxtTitle := TXcomText.Create(300, 17, 16, 8);
  FTxtItem := TXcomText.Create(180, 9, 16, 24);
  FTxtQuantity := TXcomText.Create(60, 9, 200, 24);
  FTxtScore := TXcomText.Create(55, 9, 270, 24);
  FTxtRecovery := TXcomText.Create(180, 9, 16, 60);
  FTxtRating := TXcomText.Create(200, 9, 64, 180);
  FLstStats := TXcomTextList.Create(Host.Options, Host.Clock, 290, 80, 16, 32);
  FLstRecovery := TXcomTextList.Create(Host.Options, Host.Clock, 290, 80, 16, 32);
  FLstTotal := TXcomTextList.Create(Host.Options, Host.Clock, 290, 9, 16, 12);
  // the second page (the soldiers)
  FSoldierHeadings[0] := TXcomText.Create(90, 9, 16, 24);
  for LIndex := 0 to 10 do
    FSoldierHeadings[LIndex + 1] := TXcomText.Create(18, 9, HEADING_X[LIndex], 24);
  FLstSoldierStats := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 16, 32);
  FTxtTooltip := TXcomText.Create(200, 9, 64, 180);
  SetInterface('debriefing');
  Add(FWindow, 'window', 'debriefing');
  Add(FBtnOk, 'button', 'debriefing');
  Add(FBtnStats, 'button', 'debriefing');
  Add(FTxtTitle, 'heading', 'debriefing');
  Add(FTxtItem, 'text', 'debriefing');
  Add(FTxtQuantity, 'text', 'debriefing');
  Add(FTxtScore, 'text', 'debriefing');
  Add(FTxtRecovery, 'text', 'debriefing');
  Add(FTxtRating, 'text', 'debriefing');
  Add(FLstStats, 'list', 'debriefing');
  Add(FLstRecovery, 'list', 'debriefing');
  Add(FLstTotal, 'totals', 'debriefing');
  for LIndex := 0 to 11 do
    Add(FSoldierHeadings[LIndex], 'text', 'debriefing');
  Add(FLstSoldierStats, 'list', 'debriefing');
  Add(FTxtTooltip, 'text', 'debriefing');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnStats.OnMouseClick(StatsClick);
  FTxtTitle.SetBig;
  FTxtItem.SetText(Tr('STR_LIST_ITEM'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtQuantity.SetAlign(haRight);
  FTxtScore.SetText(Tr('STR_SCORE'));
  FLstStats.SetColumns([224, 30, 64]);
  FLstStats.SetDot(True);
  FLstRecovery.SetColumns([224, 30, 64]);
  FLstRecovery.SetDot(True);
  FLstTotal.SetColumns([254, 64]);
  FLstTotal.SetDot(True);
  FSoldierHeadings[0].SetText(Tr('STR_NAME_UC'));
  for LIndex := 0 to 10 do
  begin
    FSoldierHeadings[LIndex + 1].SetAlign(haCenter);
    FSoldierHeadings[LIndex + 1].SetText(Tr(SOLDIER_HEADINGS[LIndex]));
    WatchTooltip(FSoldierHeadings[LIndex + 1], SOLDIER_TOOLTIPS[LIndex]);
  end;
  // the last column (a dummy that makes the dots reach the end of the line) is 1 wide: a surface cannot be 0 wide
  FLstSoldierStats.SetColumns([90, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 1]);
  FLstSoldierStats.SetAlign(haCenter);
  FLstSoldierStats.SetAlign(haLeft, 0);
  FLstSoldierStats.SetDot(True);
  FillLists;
  ApplyVisibility;
end;

procedure TXcomDebriefingState.WatchTooltip(AHeading: TXcomText; const ATooltip: string);
var
  LTooltip: string;
begin
  // a copy for the closures: the parameter cannot be captured
  LTooltip := ATooltip;
  AHeading.OnMouseIn(
    procedure(AAction: TXcomAction)
    begin
      FCurrentTooltip := LTooltip;
      FTxtTooltip.SetText(Tr(LTooltip));
    end);
  AHeading.OnMouseOut(
    procedure(AAction: TXcomAction)
    begin
      if FCurrentTooltip = LTooltip then
        FTxtTooltip.SetText('');
    end);
end;

class function TXcomDebriefingState.SoldierString(AStat: Integer): string;
begin
  if AStat = 0 then
    Exit('');
  Result := Chr(XCOM_TOKEN_COLOR_FLIP) + '+' + IntToStr(AStat) + Chr(XCOM_TOKEN_COLOR_FLIP);
end;

procedure TXcomDebriefingState.FillLists;
var
  LImprovement: TXcomSoldierImprovement;
  LStat: TXcomDebriefingStat;
  LStatsY, LRecoveryY: Integer;
  LQuantity, LScore: string;
begin
  FTxtTitle.SetText(Tr(FReport.Title));
  for LImprovement in FReport.SoldierStats do
    FLstSoldierStats.AddRow([LImprovement.Name, SoldierString(LImprovement.Stats.TimeUnits),
      SoldierString(LImprovement.Stats.Stamina), SoldierString(LImprovement.Stats.Health),
      SoldierString(LImprovement.Stats.Bravery), SoldierString(LImprovement.Stats.Reactions),
      SoldierString(LImprovement.Stats.Firing), SoldierString(LImprovement.Stats.Throwing),
      SoldierString(LImprovement.Stats.Melee), SoldierString(LImprovement.Stats.Strength),
      SoldierString(LImprovement.Stats.PsiStrength), SoldierString(LImprovement.Stats.PsiSkill), '']);
  LStatsY := 0;
  LRecoveryY := 0;
  for LStat in FReport.Stats do
  begin
    if LStat.Quantity = 0 then
      Continue;
    LQuantity := Chr(XCOM_TOKEN_COLOR_FLIP) + IntToStr(LStat.Quantity) + Chr(XCOM_TOKEN_COLOR_FLIP);
    LScore := Chr(XCOM_TOKEN_COLOR_FLIP) + IntToStr(LStat.Score);
    if LStat.Recovery then
    begin
      FLstRecovery.AddRow([Tr(LStat.Item).Text, LQuantity, LScore]);
      Inc(LRecoveryY, 8);
    end
    else
    begin
      FLstStats.AddRow([Tr(LStat.Item).Text, LQuantity, LScore]);
      Inc(LStatsY, 8);
    end;
  end;
  FLstTotal.AddRow([Tr('STR_TOTAL_UC').Text, IntToStr(FReport.Total)]);
  if LRecoveryY > 0 then
  begin
    FTxtRecovery.SetText(Tr(FReport.RecoveryTitle));
    FTxtRecovery.Y := FLstStats.Y + LStatsY + 5;
    FLstRecovery.Y := FTxtRecovery.Y + 8;
    FLstTotal.Y := FLstRecovery.Y + LRecoveryY + 5;
  end
  else
  begin
    FTxtRecovery.SetText('');
    FLstTotal.Y := FLstStats.Y + LStatsY + 5;
  end;
  FTxtRating.SetText(Tr('STR_RATING').Arg(Tr(FReport.Rating).Text));
end;

procedure TXcomDebriefingState.ApplyVisibility;
var
  LIndex: Integer;
begin
  // the first page: the scores
  FTxtItem.Visible := not FShowSoldierStats;
  FTxtQuantity.Visible := not FShowSoldierStats;
  FTxtScore.Visible := not FShowSoldierStats;
  FTxtRecovery.Visible := not FShowSoldierStats;
  FTxtRating.Visible := not FShowSoldierStats;
  FLstStats.Visible := not FShowSoldierStats;
  FLstRecovery.Visible := not FShowSoldierStats;
  FLstTotal.Visible := not FShowSoldierStats;
  // the second page: the stats of the soldiers
  for LIndex := 0 to 11 do
    FSoldierHeadings[LIndex].Visible := FShowSoldierStats;
  FLstSoldierStats.Visible := FShowSoldierStats;
  FTxtTooltip.Visible := FShowSoldierStats;
  if FShowSoldierStats then
    FBtnStats.SetText(Tr('STR_SCORE'))
  else
    FBtnStats.SetText(Tr('STR_STATS'));
end;

function TXcomDebriefingState.InterfaceColor(const AElement: string): Integer;
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  Result := 0;
  LInterface := Host.Resources.GetInterface('debriefing');
  if (LInterface <> nil) and LInterface.TryGetElement(AElement, LElement) then
    Result := LElement.Color;
end;

procedure TXcomDebriefingState.Init;
begin
  inherited Init;
  if FInitDone then
    Exit;
  FInitDone := True;
  if FMusic <> '' then
    Host.PlayMusic(FMusic);
  if FReport.NoContainment then
    Host.PushState(TXcomErrorMessageState.Create(Host, Tr('STR_ALIEN_DIES_NO_ALIEN_CONTAINMENT_FACILITY').Text,
      Palette, Byte(InterfaceColor('errorMessage')), 'BACK01.SCR', InterfaceColor('errorPalette')));
end;

procedure TXcomDebriefingState.ShowPage(ASoldierStats: Boolean);
begin
  FShowSoldierStats := ASoldierStats;
  ApplyVisibility;
end;

procedure TXcomDebriefingState.StatsClick(AAction: TXcomAction);
begin
  FShowSoldierStats := not FShowSoldierStats;
  ApplyVisibility;
end;

destructor TXcomDebriefingState.Destroy;
begin
  if FOwnsReport then
    FReport.Free;
  inherited Destroy;
end;

procedure TXcomDebriefingState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
  if Assigned(FOnFinished) then
    FOnFinished(FReport);
end;

end.
