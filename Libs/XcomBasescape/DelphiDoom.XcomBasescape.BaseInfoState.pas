{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - BaseInfoState of OpenXcom (the         }
{  information of a base: staff, space and detection with bars)                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.BaseInfoState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextEdit,
  DelphiDoom.XcomUi.Bar, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomBasescape.MiniBaseView;

type
  /// <summary>
  ///   The information of a base: how many soldiers, engineers and scientists are available out of the total, how
  ///   much of the living quarters, stores, laboratories, workshops and hangars is used, the defense and the short
  ///   and long range detection, each with its bar. The name can be edited and the little maps change the base. The
  ///   transfers, stores and monthly costs screens are not ported; the base screen under this one does not follow
  ///   a change of base made here
  /// </summary>
  TXcomBaseInfoState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FSave: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FCapacity: TXcomBaseCapacity;
    FBackground: TXcomWidget;
    FMini: TXcomMiniBaseView;
    FBtnOk: TXcomTextButton;
    FBtnTransfers: TXcomTextButton;
    FBtnStores: TXcomTextButton;
    FBtnMonthlyCosts: TXcomTextButton;
    FEdtBase: TXcomTextEdit;
    FTxtPersonnel: TXcomText;
    FTxtSpace: TXcomText;
    FLabels: array[0..11] of TXcomText;
    FNumbers: array[0..11] of TXcomText;
    FBars: array[0..11] of TXcomBar;
    procedure AddRow(AIndex: Integer; AY, ABarY: Integer; const AKey, ABarElement: string; AScale: Double);
    procedure SetRow(AIndex: Integer; const ANumber: string; AMax, AValue: Double);
    procedure OkClick(AAction: TXcomAction);
    procedure StoresClick(AAction: TXcomAction);
    procedure TransfersClick(AAction: TXcomAction);
    procedure MonthlyCostsClick(AAction: TXcomAction);
    procedure MiniClick(AAction: TXcomAction);
    procedure EditBaseChange(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomBasescape.StoresState,
  DelphiDoom.XcomBasescape.TransfersState, DelphiDoom.XcomBasescape.MonthlyCostsState;

const
  // the rows: soldiers, engineers, scientists, quarters, stores, laboratories, workshops, containment, hangars,
  // defense, short range, long range
  ROW_SOLDIERS = 0;
  ROW_ENGINEERS = 1;
  ROW_SCIENTISTS = 2;
  ROW_QUARTERS = 3;
  ROW_STORES = 4;
  ROW_LABORATORIES = 5;
  ROW_WORKSHOPS = 6;
  ROW_CONTAINMENT = 7;
  ROW_HANGARS = 8;
  ROW_DEFENSE = 9;
  ROW_SHORT_RANGE = 10;
  ROW_LONG_RANGE = 11;

{ TXcomBaseInfoState }

constructor TXcomBaseInfoState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LEnforced: Boolean;
  LIndex: Integer;
begin
  inherited Create(AHost);
  FBase := ABase;
  FSave := TXcomStrategy.SavedGame(AHost);
  FRuleset := TXcomStrategy.Ruleset(AHost);
  FCapacity := TXcomBaseCapacity.Create(FRuleset);
  LEnforced := Host.Options.GetBool('storageLimitsEnforced');
  FBackground := TXcomWidget.Create(320, 200, 0, 0);
  FMini := TXcomMiniBaseView.Create(FRuleset, 128, 16, 182, 8);
  FBtnOk := TXcomTextButton.Create(30, 14, 10, 180);
  FBtnTransfers := TXcomTextButton.Create(80, 14, 46, 180);
  FBtnStores := TXcomTextButton.Create(80, 14, 132, 180);
  FBtnMonthlyCosts := TXcomTextButton.Create(92, 14, 218, 180);
  FEdtBase := TXcomTextEdit.Create(Self, 127, 16, 8, 8);
  FTxtPersonnel := TXcomText.Create(300, 9, 8, 30);
  FTxtSpace := TXcomText.Create(300, 9, 8, 72);
  SetInterface('baseInfo');
  Add(FBackground);
  Add(FMini, 'miniBase', 'basescape');
  Add(FBtnOk, 'button', 'baseInfo');
  Add(FBtnTransfers, 'button', 'baseInfo');
  Add(FBtnStores, 'button', 'baseInfo');
  Add(FBtnMonthlyCosts, 'button', 'baseInfo');
  Add(FEdtBase, 'text1', 'baseInfo');
  Add(FTxtPersonnel, 'text1', 'baseInfo');
  // the rows in the order that the C++ adds them: personnel, then the title of the space, then the rest
  AddRow(ROW_SOLDIERS, 41, 43, 'STR_SOLDIERS', 'personnelBars', 1.0);
  AddRow(ROW_ENGINEERS, 51, 53, 'STR_ENGINEERS', 'personnelBars', 1.0);
  AddRow(ROW_SCIENTISTS, 61, 63, 'STR_SCIENTISTS', 'personnelBars', 1.0);
  Add(FTxtSpace, 'text1', 'baseInfo');
  AddRow(ROW_QUARTERS, 83, 85, 'STR_LIVING_QUARTERS_PLURAL', 'facilityBars', 0.5);
  AddRow(ROW_STORES, 93, 95, 'STR_STORES', 'facilityBars', 0.5);
  AddRow(ROW_LABORATORIES, 103, 105, 'STR_LABORATORIES', 'facilityBars', 0.5);
  AddRow(ROW_WORKSHOPS, 113, 115, 'STR_WORK_SHOPS', 'facilityBars', 0.5);
  if LEnforced then
    AddRow(ROW_CONTAINMENT, 123, 125, 'STR_ALIEN_CONTAINMENT', 'facilityBars', 0.5);
  if LEnforced then
    AddRow(ROW_HANGARS, 133, 135, 'STR_HANGARS', 'facilityBars', 18.0)
  else
    AddRow(ROW_HANGARS, 123, 125, 'STR_HANGARS', 'facilityBars', 18.0);
  if LEnforced then
    AddRow(ROW_DEFENSE, 147, 149, 'STR_DEFENSE_STRENGTH', 'defenceBar', 0.125)
  else
    AddRow(ROW_DEFENSE, 138, 140, 'STR_DEFENSE_STRENGTH', 'defenceBar', 0.125);
  if LEnforced then
    AddRow(ROW_SHORT_RANGE, 157, 159, 'STR_SHORT_RANGE_DETECTION', 'detectionBars', 25.0)
  else
    AddRow(ROW_SHORT_RANGE, 153, 155, 'STR_SHORT_RANGE_DETECTION', 'detectionBars', 25.0);
  if LEnforced then
    AddRow(ROW_LONG_RANGE, 167, 169, 'STR_LONG_RANGE_DETECTION', 'detectionBars', 25.0)
  else
    AddRow(ROW_LONG_RANGE, 163, 165, 'STR_LONG_RANGE_DETECTION', 'detectionBars', 25.0);
  CenterAllSurfaces;
  if LEnforced then
    Host.Resources.GetSurface('ALTBACK07.SCR').Blit(FBackground)
  else
    Host.Resources.GetSurface('BACK07.SCR').Blit(FBackground);
  FMini.SetTexture(TXcomStrategy.Rules(AHost).GetSurfaceSet('BASEBITS.PCK'));
  FMini.SetBases(FSave.Bases);
  for LIndex := 0 to FSave.Bases.Count - 1 do
    if FSave.Bases[LIndex] = FBase then
    begin
      FMini.SetSelectedBase(LIndex);
      Break;
    end;
  FMini.OnMouseClick(MiniClick);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnTransfers.SetText(Tr('STR_TRANSFERS_UC'));
  FBtnTransfers.OnMouseClick(TransfersClick);
  FBtnStores.SetText(Tr('STR_STORES_UC'));
  FBtnStores.OnMouseClick(StoresClick);
  FBtnMonthlyCosts.SetText(Tr('STR_MONTHLY_COSTS'));
  FBtnMonthlyCosts.OnMouseClick(MonthlyCostsClick);
  FEdtBase.SetBig;
  FEdtBase.OnChange(EditBaseChange);
  FTxtPersonnel.SetText(Tr('STR_PERSONNEL_AVAILABLE_PERSONNEL_TOTAL'));
  FTxtSpace.SetText(Tr('STR_SPACE_USED_SPACE_AVAILABLE'));
end;

destructor TXcomBaseInfoState.Destroy;
begin
  FCapacity.Free;
  inherited Destroy;
end;

procedure TXcomBaseInfoState.AddRow(AIndex: Integer; AY, ABarY: Integer; const AKey, ABarElement: string;
  AScale: Double);
begin
  FLabels[AIndex] := TXcomText.Create(114, 9, 8, AY);
  FNumbers[AIndex] := TXcomText.Create(40, 9, 126, AY);
  FBars[AIndex] := TXcomBar.Create(150, 5, 166, ABarY);
  Add(FLabels[AIndex], 'text2', 'baseInfo');
  Add(FNumbers[AIndex], 'numbers', 'baseInfo');
  Add(FBars[AIndex], ABarElement, 'baseInfo');
  FLabels[AIndex].SetText(Tr(AKey));
  FBars[AIndex].SetScale(AScale);
end;

procedure TXcomBaseInfoState.SetRow(AIndex: Integer; const ANumber: string; AMax, AValue: Double);
begin
  FNumbers[AIndex].SetText(ANumber);
  FBars[AIndex].SetMax(AMax);
  FBars[AIndex].SetValue(AValue);
end;

procedure TXcomBaseInfoState.Init;
var
  LStores, LMinRadar, LShort, LLong, LRange: Integer;
  LFacility: TXcomBaseFacility;
  LRule: TXcomRuleBaseFacility;
  LName: string;
begin
  inherited Init;
  FEdtBase.SetText(FBase.Name);
  SetRow(ROW_SOLDIERS, Format('%d:%d', [FBase.AvailableSoldiers, FCapacity.TotalSoldiers(FBase)]),
    FCapacity.TotalSoldiers(FBase), FBase.AvailableSoldiers);
  SetRow(ROW_ENGINEERS, Format('%d:%d', [FCapacity.AvailableEngineers(FBase), FCapacity.TotalEngineers(FBase)]),
    FCapacity.TotalEngineers(FBase), FCapacity.AvailableEngineers(FBase));
  SetRow(ROW_SCIENTISTS, Format('%d:%d', [FCapacity.AvailableScientists(FBase), FCapacity.TotalScientists(FBase)]),
    FCapacity.TotalScientists(FBase), FCapacity.AvailableScientists(FBase));
  SetRow(ROW_QUARTERS, Format('%d:%d', [FCapacity.UsedQuarters(FBase), FCapacity.AvailableQuarters(FBase)]),
    FCapacity.AvailableQuarters(FBase), FCapacity.UsedQuarters(FBase));
  LStores := Floor(FCapacity.UsedStores(FBase) + 0.05);
  SetRow(ROW_STORES, Format('%d:%d', [LStores, FCapacity.AvailableStores(FBase)]), FCapacity.AvailableStores(FBase),
    LStores);
  SetRow(ROW_LABORATORIES, Format('%d:%d', [FCapacity.UsedLaboratories(FBase), FCapacity.AvailableLaboratories(FBase)]),
    FCapacity.AvailableLaboratories(FBase), FCapacity.UsedLaboratories(FBase));
  SetRow(ROW_WORKSHOPS, Format('%d:%d', [FCapacity.UsedWorkshops(FBase), FCapacity.AvailableWorkshops(FBase)]),
    FCapacity.AvailableWorkshops(FBase), FCapacity.UsedWorkshops(FBase));
  if Assigned(FBars[ROW_CONTAINMENT]) then
    SetRow(ROW_CONTAINMENT, Format('%d:%d', [FCapacity.UsedContainment(FBase), FCapacity.AvailableContainment(FBase)]),
      FCapacity.AvailableContainment(FBase), FCapacity.UsedContainment(FBase));
  SetRow(ROW_HANGARS, Format('%d:%d', [FCapacity.UsedHangars(FBase), FCapacity.AvailableHangars(FBase)]),
    FCapacity.AvailableHangars(FBase), FCapacity.UsedHangars(FBase));
  SetRow(ROW_DEFENSE, IntToStr(FCapacity.DefenseValue(FBase)), FCapacity.DefenseValue(FBase),
    FCapacity.DefenseValue(FBase));
  // the smallest radar range of the facilities of the ruleset decides which radars are short range
  LMinRadar := 0;
  for LName in FRuleset.Facilities.Index do
  begin
    LRange := FRuleset.Facilities.Find(LName).RadarRange;
    if (LRange > 0) and ((LMinRadar = 0) or (LMinRadar > LRange)) then
      LMinRadar := LRange;
  end;
  LShort := 0;
  LLong := 0;
  for LFacility in FBase.Facilities do
  begin
    if LFacility.BuildTime <> 0 then
      Continue;
    LRule := FRuleset.Facilities.Find(LFacility.Rules.FacilityType);
    if (LMinRadar <> 0) and (LRule.RadarRange = LMinRadar) then
      Inc(LShort);
    if LRule.RadarRange > LMinRadar then
      Inc(LLong);
  end;
  SetRow(ROW_SHORT_RANGE, IntToStr(LShort), LShort, LShort);
  SetRow(ROW_LONG_RANGE, IntToStr(LLong), LLong, LLong);
end;

procedure TXcomBaseInfoState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomBaseInfoState.StoresClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomStoresState.Create(Host, FBase));
end;

procedure TXcomBaseInfoState.TransfersClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomTransfersState.Create(Host, FBase));
end;

procedure TXcomBaseInfoState.MonthlyCostsClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomMonthlyCostsState.Create(Host, FBase));
end;

procedure TXcomBaseInfoState.MiniClick(AAction: TXcomAction);
var
  LBase: Integer;
begin
  LBase := FMini.HoveredBase;
  if (LBase >= 0) and (LBase < FSave.Bases.Count) then
  begin
    FMini.SetSelectedBase(LBase);
    FBase := FSave.Bases[LBase];
    Init;
  end;
end;

procedure TXcomBaseInfoState.EditBaseChange(AAction: TXcomAction);
begin
  FBase.Name := FEdtBase.GetText;
end;

end.
