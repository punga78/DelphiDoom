{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the screen of the statistics   }
{  of a unit of the battle (UnitInfoState)                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.UnitInfoState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.Bar, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattleStates.BattlescapeState;

type
  /// <summary>The rows of the screen of the statistics, from the top</summary>
  TXcomUnitInfoRow = (uirTimeUnits, uirEnergy, uirHealth, uirFatalWounds, uirBravery, uirMorale, uirReactions,
    uirFiring, uirThrowing, uirMelee, uirStrength, uirPsiStrength, uirPsiSkill, uirFrontArmor, uirLeftArmor,
    uirRightArmor, uirRearArmor, uirUnderArmor);

  /// <summary>
  ///   The statistics of a unit over UNIBORD.PCK: a label, a number and a bar for each row, the name on top. A
  ///   click, the right button, Esc or the key of the statistics close it; the two buttons (not with a mind probe)
  ///   show the previous and the next soldier of the player.
  ///   Not ported: Options::maximizeInfoScreens (the change of the resolution of the screen), the extra buttons X1
  ///   and X2 of the mouse (the events do not carry them), the screen opened without a battlescape (from the
  ///   equipment of a craft: AParent is required)
  /// </summary>
  TXcomUnitInfoState = class(TXcomState)
  strict private
    FParent: TXcomBattlescapeState;
    FUnit: TXcomBattleUnit;
    FFromInventory: Boolean;
    FMindProbe: Boolean;
    FBackground: TXcomWidget;
    FExit: TXcomInteractiveSurface;
    FTxtName: TXcomText;
    FLabels: array[TXcomUnitInfoRow] of TXcomText;
    FNumbers: array[TXcomUnitInfoRow] of TXcomText;
    FBars: array[TXcomUnitInfoRow] of TXcomBar;
    FBtnPrev: TXcomTextButton;
    FBtnNext: TXcomTextButton;
    procedure ShowRow(ARow: TXcomUnitInfoRow; AValue, AMax: Integer);
    procedure SetRowVisible(ARow: TXcomUnitInfoRow; AVisible: Boolean);
    function PsiStrengthKnown: Boolean;
    function GetNumber(ARow: TXcomUnitInfoRow): TXcomText;
    function GetBar(ARow: TXcomUnitInfoRow): TXcomBar;
    function GetRowLabel(ARow: TXcomUnitInfoRow): TXcomText;
    procedure UnitChanged(AAction: TXcomAction);
    procedure BtnPrevClick(AAction: TXcomAction);
    procedure BtnNextClick(AAction: TXcomAction);
    procedure ExitClick(AAction: TXcomAction);
  public
    /// <param name="AParent">The battlescape that opens the screen: its session, its selection of the units</param>
    /// <param name="AUnit">The unit shown first</param>
    /// <param name="AFromInventory">The screen is opened from the inventory: only units with one are browsed</param>
    /// <param name="AMindProbe">The unit is seen with a mind probe: no browsing</param>
    constructor Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState; AUnit: TXcomBattleUnit;
      AFromInventory, AMindProbe: Boolean);
    /// <summary>init: the values of the unit, which can change after going into other screens</summary>
    procedure Init; override;
    /// <summary>handle: the right button of the mouse closes the screen</summary>
    procedure Handle(AAction: TXcomAction); override;
    /// <summary>The unit shown</summary>
    property CurrentUnit: TXcomBattleUnit read FUnit;
    property TxtName: TXcomText read FTxtName;
    property RowLabels[ARow: TXcomUnitInfoRow]: TXcomText read GetRowLabel;
    property Numbers[ARow: TXcomUnitInfoRow]: TXcomText read GetNumber;
    property Bars[ARow: TXcomUnitInfoRow]: TXcomBar read GetBar;
    /// <summary>nil with a mind probe</summary>
    property BtnPrev: TXcomTextButton read FBtnPrev;
    /// <summary>nil with a mind probe</summary>
    property BtnNext: TXcomTextButton read FBtnNext;
    property ExitSurface: TXcomInteractiveSurface read FExit;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomBattle.Types;

const
  FIRST_ROW_Y = 38;
  ROW_STEP = 9;
  UNIT_SOLDIER = 'SOLDIER';
  ROW_LABELS: array[TXcomUnitInfoRow] of string = ('STR_TIME_UNITS', 'STR_ENERGY', 'STR_HEALTH',
    'STR_FATAL_WOUNDS', 'STR_BRAVERY', 'STR_MORALE', 'STR_REACTIONS', 'STR_FIRING_ACCURACY',
    'STR_THROWING_ACCURACY', 'STR_MELEE_ACCURACY', 'STR_STRENGTH', 'STR_PSIONIC_STRENGTH', 'STR_PSIONIC_SKILL',
    'STR_FRONT_ARMOR_UC', 'STR_LEFT_ARMOR_UC', 'STR_RIGHT_ARMOR_UC', 'STR_REAR_ARMOR_UC', 'STR_UNDER_ARMOR_UC');
  ROW_BARS: array[TXcomUnitInfoRow] of string = ('barTUs', 'barEnergy', 'barHealth', 'barWounds', 'barBravery',
    'barMorale', 'barReactions', 'barFiring', 'barThrowing', 'barMelee', 'barStrength', 'barPsiStrength',
    'barPsiSkill', 'barFrontArmor', 'barLeftArmor', 'barRightArmor', 'barRearArmor', 'barUnderArmor');

constructor TXcomUnitInfoState.Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState;
  AUnit: TXcomBattleUnit; AFromInventory, AMindProbe: Boolean);
var
  LRow: TXcomUnitInfoRow;
  LY: Integer;
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
  LColor, LColor2: Byte;
  LBorder: TXcomSurface;
begin
  inherited Create(AHost);
  FParent := AParent;
  FUnit := AUnit;
  FFromInventory := AFromInventory;
  FMindProbe := AMindProbe;
  FBackground := TXcomWidget.Create(320, 200, 0, 0);
  FExit := TXcomInteractiveSurface.Create(320, 180, 0, 20);
  FTxtName := TXcomText.Create(288, 17, 16, 4);
  LY := FIRST_ROW_Y;
  for LRow := Low(TXcomUnitInfoRow) to High(TXcomUnitInfoRow) do
  begin
    FLabels[LRow] := TXcomText.Create(140, 9, 8, LY);
    FNumbers[LRow] := TXcomText.Create(18, 9, 150, LY);
    FBars[LRow] := TXcomBar.Create(150, 5, 170, LY + 1);
    Inc(LY, ROW_STEP);
  end;
  if not FMindProbe then
  begin
    FBtnPrev := TXcomTextButton.Create(14, 18, 2, 2);
    FBtnNext := TXcomTextButton.Create(14, 18, 304, 2);
  end;
  // setPalette("PAL_BATTLESCAPE"), whatever the depth of the battle: the cursor color of the battlescape, then
  // the colors that the pictures of the battle have at depth 0
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(AParent.Session.Graphics.Palette(0), 0, 256);
  // State::setPalette, Mod::setPalette: the pictures of the battle take the palette at once
  AParent.Session.Graphics.SetPalette(@Palette^[0]);
  Add(FBackground);
  Add(FExit);
  Add(FTxtName, 'textName', 'stats');
  for LRow := Low(TXcomUnitInfoRow) to High(TXcomUnitInfoRow) do
  begin
    Add(FLabels[LRow]);
    Add(FNumbers[LRow]);
    Add(FBars[LRow], ROW_BARS[LRow], 'stats');
  end;
  if not FMindProbe then
  begin
    Add(FBtnPrev, 'button', 'stats');
    Add(FBtnNext, 'button', 'stats');
  end;
  CenterAllSurfaces;
  LBorder := AParent.Session.Graphics.Surface('UNIBORD.PCK');
  if Assigned(LBorder) then
    LBorder.Blit(FBackground);
  FExit.OnMouseClick(ExitClick);
  FExit.OnKeyboardPress(ExitClick, Host.Options.KeyCancel);
  FExit.OnKeyboardPress(ExitClick, Host.Options.GetValue('keyBattleStats'));
  LColor := 0;
  LColor2 := 0;
  LInterface := Host.Resources.GetInterface('stats');
  if Assigned(LInterface) and LInterface.TryGetElement('text', LElement) then
  begin
    LColor := Byte(LElement.Color);
    LColor2 := Byte(LElement.Color2);
  end;
  FTxtName.SetAlign(haCenter);
  FTxtName.SetBig;
  FTxtName.SetHighContrast(True);
  for LRow := Low(TXcomUnitInfoRow) to High(TXcomUnitInfoRow) do
  begin
    FLabels[LRow].SetColor(LColor);
    FLabels[LRow].SetHighContrast(True);
    FLabels[LRow].SetText(Tr(ROW_LABELS[LRow]));
    FNumbers[LRow].SetColor(LColor2);
    FNumbers[LRow].SetHighContrast(True);
    FBars[LRow].SetScale(1.0);
  end;
  if not FMindProbe then
  begin
    FBtnPrev.SetText('<<');
    FBtnPrev.OnMouseClick(BtnPrevClick);
    FBtnPrev.OnKeyboardPress(BtnPrevClick, Host.Options.GetValue('keyBattlePrevUnit'));
    FBtnNext.SetText('>>');
    FBtnNext.OnMouseClick(BtnNextClick);
    FBtnNext.OnKeyboardPress(BtnNextClick, Host.Options.GetValue('keyBattleNextUnit'));
  end;
end;

function TXcomUnitInfoState.GetNumber(ARow: TXcomUnitInfoRow): TXcomText;
begin
  Result := FNumbers[ARow];
end;

function TXcomUnitInfoState.GetBar(ARow: TXcomUnitInfoRow): TXcomBar;
begin
  Result := FBars[ARow];
end;

function TXcomUnitInfoState.GetRowLabel(ARow: TXcomUnitInfoRow): TXcomText;
begin
  Result := FLabels[ARow];
end;

procedure TXcomUnitInfoState.ShowRow(ARow: TXcomUnitInfoRow; AValue, AMax: Integer);
begin
  FNumbers[ARow].SetText(IntToStr(AValue));
  FBars[ARow].SetMax(AMax);
  FBars[ARow].SetValue(AValue);
end;

procedure TXcomUnitInfoState.SetRowVisible(ARow: TXcomUnitInfoRow; AVisible: Boolean);
begin
  FLabels[ARow].Visible := AVisible;
  FNumbers[ARow].Visible := AVisible;
  FBars[ARow].Visible := AVisible;
end;

function TXcomUnitInfoState.PsiStrengthKnown: Boolean;
var
  LRuleset: TXcomRuleset;
  LName: string;
  LRequirements: TArray<string>;
begin
  if FUnit.Stats.PsiSkill > 0 then
    Exit(True);
  if not Host.Options.GetBool('psiStrengthEval') then
    Exit(False);
  // Mod::getPsiRequirements: what the first facility with psionic laboratories requires
  LRequirements := nil;
  LRuleset := FParent.Session.Ruleset;
  for LName in LRuleset.Facilities.Index do
    if LRuleset.Facilities.Find(LName).PsiLaboratories > 0 then
    begin
      LRequirements := LRuleset.Facilities.Find(LName).Requirements;
      Break;
    end;
  Result := FParent.Session.SavedGame.IsResearched(LRequirements);
end;

procedure TXcomUnitInfoState.Init;
var
  LStats: TXcomUnitStats;
  LName: string;
  LShown: Boolean;
begin
  inherited Init;
  // State::init, Mod::setPalette: the pictures of the battle follow the palette of the state on screen
  FParent.Session.Graphics.SetPalette(@Palette^[0]);
  LStats := FUnit.Stats;
  ShowRow(uirTimeUnits, FUnit.TimeUnits, LStats.TimeUnits);
  // aliens have their rank in their "name", soldiers don't
  LName := '';
  if FUnit.UnitType = UNIT_SOLDIER then
    LName := Tr(FUnit.RankString).Text + ' ';
  LName := LName + FUnit.DisplayName(
    function(AId: string): string
    begin
      Result := Tr(AId).Text;
    end, False);
  FTxtName.SetBig;
  FTxtName.SetText(LName);
  ShowRow(uirEnergy, FUnit.Energy, LStats.Stamina);
  ShowRow(uirHealth, FUnit.Health, LStats.Health);
  FBars[uirHealth].SetValue2(FUnit.StunLevel);
  ShowRow(uirFatalWounds, FUnit.GetFatalWounds, FUnit.GetFatalWounds);
  ShowRow(uirBravery, LStats.Bravery, LStats.Bravery);
  ShowRow(uirMorale, FUnit.Morale, 100);
  ShowRow(uirReactions, LStats.Reactions, LStats.Reactions);
  // the accuracies fall with the health
  ShowRow(uirFiring, (LStats.Firing * FUnit.Health) div LStats.Health, LStats.Firing);
  ShowRow(uirThrowing, (LStats.Throwing * FUnit.Health) div LStats.Health, LStats.Throwing);
  ShowRow(uirMelee, (LStats.Melee * FUnit.Health) div LStats.Health, LStats.Melee);
  ShowRow(uirStrength, LStats.Strength, LStats.Strength);
  LShown := PsiStrengthKnown;
  if LShown then
    ShowRow(uirPsiStrength, LStats.PsiStrength, LStats.PsiStrength);
  SetRowVisible(uirPsiStrength, LShown);
  LShown := LStats.PsiSkill > 0;
  if LShown then
    ShowRow(uirPsiSkill, LStats.PsiSkill, LStats.PsiSkill);
  SetRowVisible(uirPsiSkill, LShown);
  ShowRow(uirFrontArmor, FUnit.GetArmor(SIDE_FRONT), FUnit.GetMaxArmor(SIDE_FRONT));
  ShowRow(uirLeftArmor, FUnit.GetArmor(SIDE_LEFT), FUnit.GetMaxArmor(SIDE_LEFT));
  ShowRow(uirRightArmor, FUnit.GetArmor(SIDE_RIGHT), FUnit.GetMaxArmor(SIDE_RIGHT));
  ShowRow(uirRearArmor, FUnit.GetArmor(SIDE_REAR), FUnit.GetMaxArmor(SIDE_REAR));
  ShowRow(uirUnderArmor, FUnit.GetArmor(SIDE_UNDER), FUnit.GetMaxArmor(SIDE_UNDER));
end;

procedure TXcomUnitInfoState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if (AAction.Details.Kind = ekMouseDown) and (AAction.Details.Button = XCOM_BUTTON_RIGHT) then
    ExitClick(AAction);
end;

procedure TXcomUnitInfoState.UnitChanged(AAction: TXcomAction);
begin
  FUnit := FParent.Session.Battle.SelectedUnit;
  if Assigned(FUnit) then
    Init
  else
    ExitClick(AAction);
end;

procedure TXcomUnitInfoState.BtnPrevClick(AAction: TXcomAction);
begin
  FParent.SelectPreviousPlayerUnit(False, False, FFromInventory);
  UnitChanged(AAction);
end;

procedure TXcomUnitInfoState.BtnNextClick(AAction: TXcomAction);
begin
  FParent.SelectNextPlayerUnit(False, False, FFromInventory);
  UnitChanged(AAction);
end;

procedure TXcomUnitInfoState.ExitClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
