{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - GraphsState of OpenXcom (UFO and X-COM   }
{  activity in the regions and countries, income and finances, month by month)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.GraphsState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomEngine.LineWidget,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ToggleTextButton,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.GraphScale;

type
  /// <summary>GraphButInfo: the state of a button of a region or country, kept when the list scrolls</summary>
  TXcomGraphButtonInfo = class
  strict private
    FName: string;
    FColor: Byte;
    FPushed: Boolean;
  public
    constructor Create(const AName: string; AColor: Byte);
    property Name: string read FName;
    property Color: Byte read FColor;
    property Pushed: Boolean read FPushed write FPushed;
  end;

  /// <summary>
  ///   The graphs of the geoscape: seven screens (UFO and X-COM activity by region and by country, income, finances)
  ///   of twelve months, with a toggle for every line. The toggles go back to the saved game when the screen is
  ///   closed (the C++ does it in the destructor)
  /// </summary>
  TXcomGraphsState = class(TXcomState)
  strict private
    const
      MAX_BUTTONS = 16;
      MONTH_KEYS: array[0..11] of string = ('STR_JAN', 'STR_FEB', 'STR_MAR', 'STR_APR', 'STR_MAY', 'STR_JUN',
        'STR_JUL', 'STR_AUG', 'STR_SEP', 'STR_OCT', 'STR_NOV', 'STR_DEC');
  strict private
    FSave: TXcomSavedGame;
    FAlien: Boolean;
    FIncome: Boolean;
    FCountry: Boolean;
    FFinance: Boolean;
    FButRegionsOffset: Integer;
    FButCountriesOffset: Integer;
    FBackground: TXcomInteractiveSurface;
    FBtnUfoRegion: TXcomInteractiveSurface;
    FBtnUfoCountry: TXcomInteractiveSurface;
    FBtnXcomRegion: TXcomInteractiveSurface;
    FBtnXcomCountry: TXcomInteractiveSurface;
    FBtnIncome: TXcomInteractiveSurface;
    FBtnFinance: TXcomInteractiveSurface;
    FBtnGeoscape: TXcomInteractiveSurface;
    FTxtTitle: TXcomText;
    FTxtFactor: TXcomText;
    FTxtMonths: TXcomTextList;
    FTxtYears: TXcomTextList;
    FTxtScale: TList<TXcomText>;
    FBtnRegions: TList<TXcomToggleTextButton>;
    FBtnCountries: TList<TXcomToggleTextButton>;
    FBtnFinances: TList<TXcomToggleTextButton>;
    FBtnRegionTotal: TXcomToggleTextButton;
    FBtnCountryTotal: TXcomToggleTextButton;
    FAlienRegionLines: TList<TXcomLineWidget>;
    FXcomRegionLines: TList<TXcomLineWidget>;
    FAlienCountryLines: TList<TXcomLineWidget>;
    FXcomCountryLines: TList<TXcomLineWidget>;
    FIncomeLines: TList<TXcomLineWidget>;
    FFinanceLines: TList<TXcomLineWidget>;
    FRegionToggles: TObjectList<TXcomGraphButtonInfo>;
    FCountryToggles: TObjectList<TXcomGraphButtonInfo>;
    FFinanceToggles: TList<Boolean>;
    function AddLines(AList: TList<TXcomLineWidget>): TXcomLineWidget;
    function ElementColor(const AElement: string; ASecond: Boolean): Integer;
    procedure GeoscapeClick(AAction: TXcomAction);
    procedure UfoRegionClick(AAction: TXcomAction);
    procedure UfoCountryClick(AAction: TXcomAction);
    procedure XcomRegionClick(AAction: TXcomAction);
    procedure XcomCountryClick(AAction: TXcomAction);
    procedure IncomeClick(AAction: TXcomAction);
    procedure FinanceClick(AAction: TXcomAction);
    procedure RegionListClick(AAction: TXcomAction);
    procedure CountryListClick(AAction: TXcomAction);
    procedure FinanceListClick(AAction: TXcomAction);
    procedure ShiftButtons(AAction: TXcomAction);
    procedure ScrollButtons(AToggles: TObjectList<TXcomGraphButtonInfo>; AButtons: TList<TXcomToggleTextButton>;
      var AOffset: Integer; AStep: Integer);
    procedure ShowScreen(AAlien, AIncome, ACountry, AFinance: Boolean; const ATitle: string);
    procedure ResetScreen;
    procedure ShowButtons(AButtons: TList<TXcomToggleTextButton>; ATotal: TXcomToggleTextButton);
    procedure UpdateScale(const AScale: TXcomGraphScale);
    procedure DrawLines;
    procedure DrawEntityLines;
    procedure DrawFinanceLines;
    procedure StoreToggles;
    procedure BuildGrid;
    procedure BuildAxisTexts;
    procedure LoadToggles;
  public
    constructor Create(AHost: TXcomStateHost);
    destructor Destroy; override;
    procedure Init; override;
    property Title: TXcomText read FTxtTitle;
    property ScaleTexts: TList<TXcomText> read FTxtScale;
    property RegionToggles: TObjectList<TXcomGraphButtonInfo> read FRegionToggles;
    property CountryToggles: TObjectList<TXcomGraphButtonInfo> read FCountryToggles;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Region,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Gfx,
  DelphiDoom.XcomGeoscape.Funding, DelphiDoom.XcomEngine.Resources.Intf;

{ TXcomGraphButtonInfo }

constructor TXcomGraphButtonInfo.Create(const AName: string; AColor: Byte);
begin
  inherited Create;
  FName := AName;
  FColor := AColor;
end;

{ TXcomGraphsState }

function TXcomGraphsState.AddLines(AList: TList<TXcomLineWidget>): TXcomLineWidget;
begin
  Result := TXcomLineWidget.Create(Host, 320, 200, 0, 0);
  Add(Result);
  AList.Add(Result);
end;

function TXcomGraphsState.ElementColor(const AElement: string; ASecond: Boolean): Integer;
var
  LElement: TXcomInterfaceElement;
begin
  Result := 0;
  if Assigned(RuleInterface) and RuleInterface.TryGetElement(AElement, LElement) then
    if ASecond then
      Result := LElement.Color2
    else
      Result := LElement.Color;
end;

constructor TXcomGraphsState.Create(AHost: TXcomStateHost);
var
  LIndex, LScaleText, LOffset: Integer;
  LRegion: TXcomRegion;
  LCountry: TXcomCountry;
  LButton: TXcomToggleTextButton;
  LColor: Byte;
  LTotalColor: Byte;
begin
  inherited Create(AHost);
  FSave := TXcomStrategy.SavedGame(AHost);
  FTxtScale := TList<TXcomText>.Create;
  FBtnRegions := TList<TXcomToggleTextButton>.Create;
  FBtnCountries := TList<TXcomToggleTextButton>.Create;
  FBtnFinances := TList<TXcomToggleTextButton>.Create;
  FAlienRegionLines := TList<TXcomLineWidget>.Create;
  FXcomRegionLines := TList<TXcomLineWidget>.Create;
  FAlienCountryLines := TList<TXcomLineWidget>.Create;
  FXcomCountryLines := TList<TXcomLineWidget>.Create;
  FIncomeLines := TList<TXcomLineWidget>.Create;
  FFinanceLines := TList<TXcomLineWidget>.Create;
  FRegionToggles := TObjectList<TXcomGraphButtonInfo>.Create(True);
  FCountryToggles := TObjectList<TXcomGraphButtonInfo>.Create(True);
  FFinanceToggles := TList<Boolean>.Create;
  FBackground := TXcomInteractiveSurface.Create(320, 200, 0, 0);
  FBackground.OnMousePress(ShiftButtons, XCOM_BUTTON_WHEELUP);
  FBackground.OnMousePress(ShiftButtons, XCOM_BUTTON_WHEELDOWN);
  FBtnUfoRegion := TXcomInteractiveSurface.Create(32, 24, 96, 0);
  FBtnUfoCountry := TXcomInteractiveSurface.Create(32, 24, 128, 0);
  FBtnXcomRegion := TXcomInteractiveSurface.Create(32, 24, 160, 0);
  FBtnXcomCountry := TXcomInteractiveSurface.Create(32, 24, 192, 0);
  FBtnIncome := TXcomInteractiveSurface.Create(32, 24, 224, 0);
  FBtnFinance := TXcomInteractiveSurface.Create(32, 24, 256, 0);
  FBtnGeoscape := TXcomInteractiveSurface.Create(32, 24, 288, 0);
  FTxtTitle := TXcomText.Create(230, 16, 90, 28);
  FTxtFactor := TXcomText.Create(38, 11, 96, 28);
  FTxtMonths := TXcomTextList.Create(Host.Options, Host.Clock, 205, 8, 115, 183);
  FTxtYears := TXcomTextList.Create(Host.Options, Host.Clock, 200, 8, 121, 191);
  SetInterface('graphs');
  Add(FBackground);
  Add(FBtnUfoRegion);
  Add(FBtnUfoCountry);
  Add(FBtnXcomRegion);
  Add(FBtnXcomCountry);
  Add(FBtnIncome);
  Add(FBtnFinance);
  Add(FBtnGeoscape);
  Add(FTxtMonths, 'scale', 'graphs');
  Add(FTxtYears, 'scale', 'graphs');
  Add(FTxtTitle, 'text', 'graphs');
  Add(FTxtFactor, 'text', 'graphs');
  for LScaleText := 0 to 9 do
  begin
    FTxtScale.Add(TXcomText.Create(42, 16, 80, 171 - (LScaleText * 14)));
    Add(FTxtScale[LScaleText], 'scale', 'graphs');
  end;
  // the buttons of the regions: all of them are kept in the toggles, the first 16 get a button
  LOffset := 0;
  for LRegion in FSave.Regions do
  begin
    LColor := Byte(13 + 8 * (LOffset mod MAX_BUTTONS));
    FRegionToggles.Add(TXcomGraphButtonInfo.Create(Tr(LRegion.Rules.RegionType).Text, LColor));
    if LOffset < MAX_BUTTONS then
    begin
      LButton := TXcomToggleTextButton.Create(88, 11, 0, LOffset * 11);
      LButton.SetText(Tr(LRegion.Rules.RegionType).Text);
      LButton.SetInvertColor(LColor);
      LButton.OnMousePress(RegionListClick);
      Add(LButton, 'button', 'graphs');
      FBtnRegions.Add(LButton);
    end;
    AddLines(FAlienRegionLines);
    AddLines(FXcomRegionLines);
    Inc(LOffset);
  end;
  LTotalColor := Byte(ElementColor('regionTotal', False));
  if FRegionToggles.Count < MAX_BUTTONS then
    FBtnRegionTotal := TXcomToggleTextButton.Create(88, 11, 0, FRegionToggles.Count * 11)
  else
    FBtnRegionTotal := TXcomToggleTextButton.Create(88, 11, 0, MAX_BUTTONS * 11);
  FRegionToggles.Add(TXcomGraphButtonInfo.Create(Tr('STR_TOTAL_UC').Text, LTotalColor));
  FBtnRegionTotal.OnMousePress(RegionListClick);
  FBtnRegionTotal.SetInvertColor(LTotalColor);
  FBtnRegionTotal.SetText(Tr('STR_TOTAL_UC').Text);
  AddLines(FAlienRegionLines);
  AddLines(FXcomRegionLines);
  Add(FBtnRegionTotal, 'button', 'graphs');
  // the countries
  LOffset := 0;
  for LCountry in FSave.Countries do
  begin
    LColor := Byte(13 + 8 * (LOffset mod MAX_BUTTONS));
    FCountryToggles.Add(TXcomGraphButtonInfo.Create(Tr(LCountry.Rules.CountryType).Text, LColor));
    if LOffset < MAX_BUTTONS then
    begin
      LButton := TXcomToggleTextButton.Create(88, 11, 0, LOffset * 11);
      LButton.SetInvertColor(LColor);
      LButton.SetText(Tr(LCountry.Rules.CountryType).Text);
      LButton.OnMousePress(CountryListClick);
      Add(LButton, 'button', 'graphs');
      FBtnCountries.Add(LButton);
    end;
    AddLines(FAlienCountryLines);
    AddLines(FXcomCountryLines);
    AddLines(FIncomeLines);
    Inc(LOffset);
  end;
  LTotalColor := Byte(ElementColor('countryTotal', False));
  if FCountryToggles.Count < MAX_BUTTONS then
    FBtnCountryTotal := TXcomToggleTextButton.Create(88, 11, 0, FCountryToggles.Count * 11)
  else
    FBtnCountryTotal := TXcomToggleTextButton.Create(88, 11, 0, MAX_BUTTONS * 11);
  FCountryToggles.Add(TXcomGraphButtonInfo.Create(Tr('STR_TOTAL_UC').Text, LTotalColor));
  FBtnCountryTotal.OnMousePress(CountryListClick);
  FBtnCountryTotal.SetInvertColor(LTotalColor);
  FBtnCountryTotal.SetText(Tr('STR_TOTAL_UC').Text);
  AddLines(FAlienCountryLines);
  AddLines(FXcomCountryLines);
  AddLines(FIncomeLines);
  Add(FBtnCountryTotal, 'button', 'graphs');
  // the finances: income, expenditure, maintenance, balance and score
  for LIndex := 0 to 4 do
  begin
    LButton := TXcomToggleTextButton.Create(88, 11, 0, LIndex * 11);
    FFinanceToggles.Add(False);
    LButton.SetInvertColor(Byte(13 + 8 * LIndex));
    LButton.OnMousePress(FinanceListClick);
    Add(LButton, 'button', 'graphs');
    FBtnFinances.Add(LButton);
    AddLines(FFinanceLines);
  end;
  FBtnFinances[0].SetText(Tr('STR_INCOME').Text);
  FBtnFinances[1].SetText(Tr('STR_EXPENDITURE').Text);
  FBtnFinances[2].SetText(Tr('STR_MAINTENANCE').Text);
  FBtnFinances[3].SetText(Tr('STR_BALANCE').Text);
  FBtnFinances[4].SetText(Tr('STR_SCORE').Text);
  LoadToggles;
  BuildGrid;
  BuildAxisTexts;
  for LIndex := 0 to FTxtScale.Count - 1 do
    FTxtScale[LIndex].SetAlign(haRight);
  UfoRegionClick(nil);
  try
    Host.Resources.GetSurface('GRAPH.BDY').Blit(FBackground);
  except
    on EXcomEngineException do
      Host.Resources.GetSurface('GRAPHS.SPK').Blit(FBackground);
  end;
  FTxtTitle.SetAlign(haCenter);
  FTxtFactor.SetText(Tr('STR_FINANCE_THOUSANDS'));
  FBtnUfoRegion.OnMousePress(UfoRegionClick);
  FBtnUfoCountry.OnMousePress(UfoCountryClick);
  FBtnXcomRegion.OnMousePress(XcomRegionClick);
  FBtnXcomCountry.OnMousePress(XcomCountryClick);
  FBtnIncome.OnMousePress(IncomeClick);
  FBtnFinance.OnMousePress(FinanceClick);
  FBtnGeoscape.OnMousePress(GeoscapeClick);
  FBtnGeoscape.OnKeyboardPress(GeoscapeClick, Host.Options.KeyCancel);
  FBtnGeoscape.OnKeyboardPress(GeoscapeClick, Host.Options.GetValue('keyGeoGraphs'));
  CenterAllSurfaces;
end;

destructor TXcomGraphsState.Destroy;
begin
  // the surfaces belong to the state; the lists only point at them
  FFinanceToggles.Free;
  FCountryToggles.Free;
  FRegionToggles.Free;
  FFinanceLines.Free;
  FIncomeLines.Free;
  FXcomCountryLines.Free;
  FAlienCountryLines.Free;
  FXcomRegionLines.Free;
  FAlienRegionLines.Free;
  FBtnFinances.Free;
  FBtnCountries.Free;
  FBtnRegions.Free;
  FTxtScale.Free;
  inherited Destroy;
end;

procedure TXcomGraphsState.Init;
begin
  inherited Init;
end;

procedure TXcomGraphsState.LoadToggles;
var
  LRegion, LCountry, LFinance: string;
  LIndex: Integer;
begin
  LRegion := FSave.GraphRegionToggles;
  LCountry := FSave.GraphCountryToggles;
  LFinance := FSave.GraphFinanceToggles;
  while Length(LRegion) < FRegionToggles.Count do
    LRegion := LRegion + '0';
  while Length(LCountry) < FCountryToggles.Count do
    LCountry := LCountry + '0';
  while Length(LFinance) < FFinanceToggles.Count do
    LFinance := LFinance + '0';
  for LIndex := 0 to FRegionToggles.Count - 1 do
  begin
    FRegionToggles[LIndex].Pushed := LRegion[LIndex + 1] <> '0';
    if LIndex = FRegionToggles.Count - 1 then
      FBtnRegionTotal.SetPressed(FRegionToggles[LIndex].Pushed)
    else if LIndex < MAX_BUTTONS then
      FBtnRegions[LIndex].SetPressed(FRegionToggles[LIndex].Pushed);
  end;
  for LIndex := 0 to FCountryToggles.Count - 1 do
  begin
    FCountryToggles[LIndex].Pushed := LCountry[LIndex + 1] <> '0';
    if LIndex = FCountryToggles.Count - 1 then
      FBtnCountryTotal.SetPressed(FCountryToggles[LIndex].Pushed)
    else if LIndex < MAX_BUTTONS then
      FBtnCountries[LIndex].SetPressed(FCountryToggles[LIndex].Pushed);
  end;
  for LIndex := 0 to FFinanceToggles.Count - 1 do
  begin
    FFinanceToggles[LIndex] := LFinance[LIndex + 1] <> '0';
    FBtnFinances[LIndex].SetPressed(FFinanceToggles[LIndex]);
  end;
end;

procedure TXcomGraphsState.StoreToggles;
var
  LRegion, LCountry, LFinance: string;
  LInfo: TXcomGraphButtonInfo;
  LToggle: Boolean;
begin
  LRegion := '';
  LCountry := '';
  LFinance := '';
  for LInfo in FRegionToggles do
    LRegion := LRegion + Chr(Ord('0') + Ord(LInfo.Pushed));
  for LInfo in FCountryToggles do
    LCountry := LCountry + Chr(Ord('0') + Ord(LInfo.Pushed));
  for LToggle in FFinanceToggles do
    LFinance := LFinance + Chr(Ord('0') + Ord(LToggle));
  FSave.GraphRegionToggles := LRegion;
  FSave.GraphCountryToggles := LCountry;
  FSave.GraphFinanceToggles := LFinance;
end;

procedure TXcomGraphsState.BuildGrid;
var
  LGridColor, LGrid, LX, LY: Integer;
  LColor: Byte;
begin
  LGridColor := ElementColor('graph', False);
  FBackground.DrawRect(125, 49, 188, 127, Byte(LGridColor));
  for LGrid := 0 to 4 do
  begin
    LY := 50 + LGrid;
    while LY <= 163 + LGrid do
    begin
      LX := 126 + LGrid;
      while LX <= 297 + LGrid do
      begin
        LColor := Byte(LGridColor + LGrid + 1);
        if LGrid = 4 then
          LColor := 0;
        FBackground.DrawRect(LX, LY, 16 - (LGrid * 2), 13 - (LGrid * 2), LColor);
        Inc(LX, 17);
      end;
      Inc(LY, 14);
    end;
  end;
end;

procedure TXcomGraphsState.BuildAxisTexts;
var
  LMonth, LIter: Integer;
begin
  LMonth := FSave.Time.Month;
  FTxtMonths.SetColumns([17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17]);
  FTxtMonths.AddRow([' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ']);
  FTxtYears.SetColumns([34, 34, 34, 34, 34, 34]);
  FTxtYears.AddRow([' ', ' ', ' ', ' ', ' ', ' ']);
  for LIter := 0 to 11 do
  begin
    if LMonth > 11 then
    begin
      LMonth := 0;
      FTxtYears.SetCellText(0, LIter div 2, IntToStr(FSave.Time.Year));
      if LIter > 2 then
        FTxtYears.SetCellText(0, 0, IntToStr(FSave.Time.Year - 1));
    end;
    FTxtMonths.SetCellText(0, LIter, Tr(MONTH_KEYS[LMonth]).Text);
    Inc(LMonth);
  end;
end;

procedure TXcomGraphsState.GeoscapeClick(AAction: TXcomAction);
begin
  StoreToggles;
  Host.PopState;
end;

procedure TXcomGraphsState.ShowScreen(AAlien, AIncome, ACountry, AFinance: Boolean; const ATitle: string);
begin
  FAlien := AAlien;
  FIncome := AIncome;
  FCountry := ACountry;
  FFinance := AFinance;
  ResetScreen;
  DrawLines;
  if AFinance then
    ShowButtons(FBtnFinances, nil)
  else if ACountry then
    ShowButtons(FBtnCountries, FBtnCountryTotal)
  else
    ShowButtons(FBtnRegions, FBtnRegionTotal);
  if AIncome then
    FTxtFactor.Visible := True;
  FTxtTitle.SetBig;
  FTxtTitle.SetText(ATitle);
end;

procedure TXcomGraphsState.ShowButtons(AButtons: TList<TXcomToggleTextButton>; ATotal: TXcomToggleTextButton);
var
  LButton: TXcomToggleTextButton;
begin
  for LButton in AButtons do
    LButton.Visible := True;
  if Assigned(ATotal) then
    ATotal.Visible := True;
end;

procedure TXcomGraphsState.UfoRegionClick(AAction: TXcomAction);
begin
  ShowScreen(True, False, False, False, Tr('STR_UFO_ACTIVITY_IN_AREAS').Text);
end;

procedure TXcomGraphsState.UfoCountryClick(AAction: TXcomAction);
begin
  ShowScreen(True, False, True, False, Tr('STR_UFO_ACTIVITY_IN_COUNTRIES').Text);
end;

procedure TXcomGraphsState.XcomRegionClick(AAction: TXcomAction);
begin
  ShowScreen(False, False, False, False, Tr('STR_XCOM_ACTIVITY_IN_AREAS').Text);
end;

procedure TXcomGraphsState.XcomCountryClick(AAction: TXcomAction);
begin
  ShowScreen(False, False, True, False, Tr('STR_XCOM_ACTIVITY_IN_COUNTRIES').Text);
end;

procedure TXcomGraphsState.IncomeClick(AAction: TXcomAction);
begin
  ShowScreen(False, True, True, False, Tr('STR_INCOME').Text);
end;

procedure TXcomGraphsState.FinanceClick(AAction: TXcomAction);
begin
  ShowScreen(False, False, False, True, Tr('STR_FINANCE').Text);
end;

procedure TXcomGraphsState.RegionListClick(AAction: TXcomAction);
var
  LButton: TXcomToggleTextButton;
  LNumber, LIndex: Integer;
begin
  LNumber := 0;
  LButton := AAction.Sender as TXcomToggleTextButton;
  if LButton = FBtnRegionTotal then
    LNumber := FRegionToggles.Count - 1
  else
    for LIndex := 0 to FBtnRegions.Count - 1 do
      if LButton = FBtnRegions[LIndex] then
      begin
        LNumber := LIndex + FButRegionsOffset;
        Break;
      end;
  FRegionToggles[LNumber].Pushed := LButton.GetPressed;
  DrawLines;
end;

procedure TXcomGraphsState.CountryListClick(AAction: TXcomAction);
var
  LButton: TXcomToggleTextButton;
  LNumber, LIndex: Integer;
begin
  LNumber := 0;
  LButton := AAction.Sender as TXcomToggleTextButton;
  if LButton = FBtnCountryTotal then
    LNumber := FCountryToggles.Count - 1
  else
    for LIndex := 0 to FBtnCountries.Count - 1 do
      if LButton = FBtnCountries[LIndex] then
      begin
        LNumber := LIndex + FButCountriesOffset;
        Break;
      end;
  FCountryToggles[LNumber].Pushed := LButton.GetPressed;
  DrawLines;
end;

procedure TXcomGraphsState.FinanceListClick(AAction: TXcomAction);
var
  LButton: TXcomToggleTextButton;
  LNumber, LIndex: Integer;
begin
  LNumber := 0;
  LButton := AAction.Sender as TXcomToggleTextButton;
  for LIndex := 0 to FBtnFinances.Count - 1 do
    if LButton = FBtnFinances[LIndex] then
    begin
      LNumber := LIndex;
      Break;
    end;
  FFinanceLines[LNumber].Visible := not FFinanceToggles[LNumber];
  FFinanceToggles[LNumber] := LButton.GetPressed;
  DrawLines;
end;

procedure TXcomGraphsState.ResetScreen;
var
  LWidget: TXcomLineWidget;
  LButton: TXcomToggleTextButton;
begin
  for LWidget in FAlienRegionLines do
    LWidget.Visible := False;
  for LWidget in FAlienCountryLines do
    LWidget.Visible := False;
  for LWidget in FXcomRegionLines do
    LWidget.Visible := False;
  for LWidget in FXcomCountryLines do
    LWidget.Visible := False;
  for LWidget in FIncomeLines do
    LWidget.Visible := False;
  for LWidget in FFinanceLines do
    LWidget.Visible := False;
  for LButton in FBtnRegions do
    LButton.Visible := False;
  for LButton in FBtnCountries do
    LButton.Visible := False;
  for LButton in FBtnFinances do
    LButton.Visible := False;
  FBtnRegionTotal.Visible := False;
  FBtnCountryTotal.Visible := False;
  FTxtFactor.Visible := False;
end;

procedure TXcomGraphsState.UpdateScale(const AScale: TXcomGraphScale);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 9 do
    FTxtScale[LIndex].SetText(TXcomFunding.FormatNumber(AScale.AxisLabel(LIndex), ''));
end;

procedure TXcomGraphsState.DrawLines;
begin
  if FFinance then
    DrawFinanceLines
  else
    DrawEntityLines;
end;

procedure TXcomGraphsState.DrawEntityLines;
var
  LSeries: TArray<TArray<Integer>>;
  LToggles: TObjectList<TXcomGraphButtonInfo>;
  LTargets: TList<TXcomLineWidget>;
  LTotals: array[0..11] of Integer;
  LEntry, LIter, LEntity, LValue, LTotal, LUpper, LLower, LFirstCell, LX, LY: Integer;
  LValues: TArray<Integer>;
  LScale: TXcomGraphScale;
  LTrackLower: Boolean;
  LPoints: TList<Integer>;
  LCountryItem: TXcomCountry;
  LRegionItem: TXcomRegion;
  LColor: Byte;
  LFunding: Integer;
  LFundsCount: Integer;
begin
  // the activity (or the funding in thousands) of every region or country, month by month
  if FCountry then
  begin
    LToggles := FCountryToggles;
    SetLength(LSeries, FSave.Countries.Count);
    for LEntity := 0 to FSave.Countries.Count - 1 do
    begin
      LCountryItem := FSave.Countries[LEntity];
      if FAlien then
        LSeries[LEntity] := Copy(LCountryItem.ActivityAlien)
      else if FIncome then
      begin
        SetLength(LSeries[LEntity], Length(LCountryItem.Funding));
        for LIter := 0 to High(LCountryItem.Funding) do
        begin
          LFunding := LCountryItem.Funding[LIter];
          LSeries[LEntity][LIter] := LFunding div 1000;
        end;
      end
      else
        LSeries[LEntity] := Copy(LCountryItem.ActivityXcom);
    end;
    if FAlien then
      LTargets := FAlienCountryLines
    else if FIncome then
      LTargets := FIncomeLines
    else
      LTargets := FXcomCountryLines;
  end
  else
  begin
    LToggles := FRegionToggles;
    SetLength(LSeries, FSave.Regions.Count);
    for LEntity := 0 to FSave.Regions.Count - 1 do
    begin
      LRegionItem := FSave.Regions[LEntity];
      if FAlien then
        LSeries[LEntity] := Copy(LRegionItem.ActivityAlien)
      else
        LSeries[LEntity] := Copy(LRegionItem.ActivityXcom);
    end;
    if FAlien then
      LTargets := FAlienRegionLines
    else
      LTargets := FXcomRegionLines;
  end;
  // only the activity of the X-COM (and of the UFO in the regions) can go below zero
  LTrackLower := (not FCountry) or ((not FAlien) and (not FIncome));
  LUpper := 0;
  LLower := 0;
  LFundsCount := Length(FSave.FundsList);
  for LEntry := 0 to LFundsCount - 1 do
  begin
    LTotal := 0;
    for LEntity := 0 to High(LSeries) do
    begin
      if LEntry >= Length(LSeries[LEntity]) then
        Continue;
      LValue := LSeries[LEntity][LEntry];
      Inc(LTotal, LValue);
      if (LValue > LUpper) and LToggles[LEntity].Pushed then
        LUpper := LValue;
      if LTrackLower and (LValue < LLower) and LToggles[LEntity].Pushed then
        LLower := LValue;
    end;
    if LToggles.Last.Pushed and (LTotal > LUpper) then
      LUpper := LTotal;
    if LToggles.Last.Pushed and (LTotal < LLower) then
      LLower := LTotal;
  end;
  if FIncome then
    LFirstCell := 50
  else
    LFirstCell := 10;
  LScale := TXcomGraphScale.Fit(LUpper, LLower, LFirstCell);
  FillChar(LTotals, SizeOf(LTotals), 0);
  LPoints := TList<Integer>.Create;
  try
    for LEntity := 0 to High(LSeries) do
    begin
      LTargets[LEntity].ClearLines;
      LValues := LSeries[LEntity];
      LPoints.Clear;
      for LIter := 0 to 11 do
      begin
        LX := 312 - (LIter * 17);
        LY := LScale.BaseY;
        if LIter < Length(LValues) then
        begin
          LValue := LValues[Length(LValues) - (1 + LIter)];
          LY := LScale.PointY(LValue);
          Inc(LTotals[LIter], LValue);
        end;
        if LY >= 175 then
          LY := 175;
        LPoints.Add(LY);
        if LPoints.Count > 1 then
        begin
          LColor := Byte(LToggles[LEntity].Color + 4);
          LTargets[LEntity].Line(LX, LY, LX + 17, LPoints[LPoints.Count - 2], LColor);
        end;
      end;
      LTargets[LEntity].Visible := LToggles[LEntity].Pushed;
    end;
    // the "total" line has its own surface, the last of the list
    LTargets.Last.ClearLines;
    if FCountry then
      LColor := Byte(ElementColor('countryTotal', True))
    else
      LColor := Byte(ElementColor('regionTotal', True));
    LPoints.Clear;
    for LIter := 0 to 11 do
    begin
      LX := 312 - (LIter * 17);
      LY := LScale.PointY(LTotals[LIter]);
      LPoints.Add(LY);
      if LPoints.Count > 1 then
        LTargets.Last.Line(LX, LY, LX + 17, LPoints[LPoints.Count - 2], LColor);
    end;
    LTargets.Last.Visible := LToggles.Last.Pushed;
  finally
    LPoints.Free;
  end;
  UpdateScale(LScale);
  FTxtFactor.Visible := FIncome;
end;

procedure TXcomGraphsState.DrawFinanceLines;
var
  LIncome, LBalance, LExpend, LMaint: array[0..11] of Int64;
  LScore: array[0..11] of Integer;
  LEntry, LInverted, LUpper, LLower, LButton, LIter, LX, LY, LOffset, LCount: Integer;
  LRegion: TXcomRegion;
  LCapacity: TXcomBaseCapacity;
  LScale: TXcomGraphScale;
  LPoints: TList<Integer>;
  LValue: Int64;
  LFunds: TArray<Int64>;
begin
  FillChar(LIncome, SizeOf(LIncome), 0);
  FillChar(LBalance, SizeOf(LBalance), 0);
  FillChar(LExpend, SizeOf(LExpend), 0);
  FillChar(LMaint, SizeOf(LMaint), 0);
  FillChar(LScore, SizeOf(LScore), 0);
  LUpper := 0;
  LLower := 0;
  LCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(Host));
  try
    LMaint[0] := LCapacity.BaseMaintenance(FSave) div 1000;
  finally
    LCapacity.Free;
  end;
  LFunds := FSave.FundsList;
  LCount := Length(LFunds);
  for LEntry := 0 to Min(LCount, 12) - 1 do
  begin
    LInverted := LCount - (1 + LEntry);
    Inc(LMaint[LEntry], FSave.MaintenanceList[LInverted] div 1000);
    LBalance[LEntry] := LFunds[LInverted] div 1000;
    LScore[LEntry] := FSave.ResearchScores[LInverted];
    for LRegion in FSave.Regions do
      Inc(LScore[LEntry], LRegion.ActivityXcom[LInverted] - LRegion.ActivityAlien[LInverted]);
    if FFinanceToggles[2] then
    begin
      if LMaint[LEntry] > LUpper then
        LUpper := Integer(LMaint[LEntry]);
      if LMaint[LEntry] < LLower then
        LLower := Integer(LMaint[LEntry]);
    end;
    if FFinanceToggles[3] then
    begin
      if LBalance[LEntry] > LUpper then
        LUpper := Integer(LBalance[LEntry]);
      if LBalance[LEntry] < LLower then
        LLower := Integer(LBalance[LEntry]);
    end;
    if FFinanceToggles[4] then
    begin
      if LScore[LEntry] > LUpper then
        LUpper := LScore[LEntry];
      if LScore[LEntry] < LLower then
        LLower := LScore[LEntry];
    end;
  end;
  for LEntry := 0 to Min(Length(FSave.ExpendituresList), 12) - 1 do
  begin
    LExpend[LEntry] := FSave.ExpendituresList[Length(FSave.ExpendituresList) - (LEntry + 1)] div 1000;
    LIncome[LEntry] := FSave.IncomesList[Length(FSave.IncomesList) - (LEntry + 1)] div 1000;
    if FFinanceToggles[0] and (LIncome[LEntry] > LUpper) then
      LUpper := Integer(LIncome[LEntry]);
    if FFinanceToggles[1] and (LExpend[LEntry] > LUpper) then
      LUpper := Integer(LExpend[LEntry]);
  end;
  LScale := TXcomGraphScale.Fit(LUpper, LLower, 250);
  for LButton := 0 to 4 do
  begin
    FFinanceLines[LButton].Visible := FFinanceToggles[LButton];
    FFinanceLines[LButton].ClearLines;
  end;
  LPoints := TList<Integer>.Create;
  try
    for LButton := 0 to 4 do
    begin
      LPoints.Clear;
      for LIter := 0 to 11 do
      begin
        LX := 312 - (LIter * 17);
        case LButton of
          0: LValue := LIncome[LIter];
          1: LValue := LExpend[LIter];
          2: LValue := LMaint[LIter];
          3: LValue := LBalance[LIter];
        else
          LValue := LScore[LIter];
        end;
        LY := LScale.PointY(LValue);
        LPoints.Add(LY);
        if LButton mod 2 = 1 then
          LOffset := 8
        else
          LOffset := 0;
        if LPoints.Count > 1 then
          FFinanceLines[LButton].Line(LX, LY, LX + 17, LPoints[LPoints.Count - 2],
            Byte(((LButton div 2) + 1) * 16 + LOffset));
      end;
    end;
  finally
    LPoints.Free;
  end;
  UpdateScale(LScale);
  FTxtFactor.Visible := True;
end;

procedure TXcomGraphsState.ShiftButtons(AAction: TXcomAction);
begin
  // only the screens of regions and countries have lists of buttons
  if FFinance then
    Exit;
  if FCountry then
  begin
    if FCountryToggles.Count <= MAX_BUTTONS then
      Exit;
    if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
      ScrollButtons(FCountryToggles, FBtnCountries, FButCountriesOffset, -1)
    else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
      ScrollButtons(FCountryToggles, FBtnCountries, FButCountriesOffset, 1);
  end
  else
  begin
    if FRegionToggles.Count <= MAX_BUTTONS then
      Exit;
    if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
      ScrollButtons(FRegionToggles, FBtnRegions, FButRegionsOffset, -1)
    else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
      ScrollButtons(FRegionToggles, FBtnRegions, FButRegionsOffset, 1);
  end;
end;

procedure TXcomGraphsState.ScrollButtons(AToggles: TObjectList<TXcomGraphButtonInfo>;
  AButtons: TList<TXcomToggleTextButton>; var AOffset: Integer; AStep: Integer);
var
  LIndex: Integer;
begin
  if (AStep + AOffset < 0) or (AOffset + AStep + MAX_BUTTONS >= AToggles.Count) then
    Exit;
  Inc(AOffset, AStep);
  LIndex := 0;
  while (AOffset + LIndex < AToggles.Count) and (LIndex < MAX_BUTTONS) and (LIndex < AButtons.Count) do
  begin
    AButtons[LIndex].SetText(AToggles[AOffset + LIndex].Name);
    AButtons[LIndex].SetInvertColor(AToggles[AOffset + LIndex].Color);
    AButtons[LIndex].SetPressed(AToggles[AOffset + LIndex].Pushed);
    Inc(LIndex);
  end;
end;

end.
