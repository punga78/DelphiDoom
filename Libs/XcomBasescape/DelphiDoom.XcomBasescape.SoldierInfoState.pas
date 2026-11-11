{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SoldierInfoState of OpenXcom (the       }
{  stats, rank, missions, kills and craft of a soldier)                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldierInfoState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomUi.Bar,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomMod.UnitStats;

type
  /// <summary>
  ///   The soldier of a base (or a dead one, when there is no base: the memorial): the eleven stats with their bars
  ///   (the stat with the armor, the maximum, the stat at the start), the rank, missions, kills, craft, wound
  ///   recovery and psionic training. The name can be edited; the buttons go to the previous and next soldier,
  ///   change the armor and sack the soldier. The diary is not ported
  /// </summary>
  TXcomSoldierInfoState = class(TXcomState)
  strict private
    const
      StatCount = 11;
    var
    FBase: TXcomBase;
    FList: TObjectList<TXcomSoldier>;
    FSoldierId: Integer;
    FSoldier: TXcomSoldier;
    FBackground: TXcomWidget;
    FRank: TXcomWidget;
    FBtnPrev: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FBtnNext: TXcomTextButton;
    FBtnArmor: TXcomTextButton;
    FEdtSoldier: TXcomTextEdit;
    FBtnSack: TXcomTextButton;
    FBtnDiary: TXcomTextButton;
    FTxtRank: TXcomText;
    FTxtMissions: TXcomText;
    FTxtKills: TXcomText;
    FTxtCraft: TXcomText;
    FTxtRecovery: TXcomText;
    FTxtPsionic: TXcomText;
    FTxtDead: TXcomText;
    FLabels: array[0..StatCount - 1] of TXcomText;
    FNumbers: array[0..StatCount - 1] of TXcomText;
    FBars: array[0..StatCount - 1] of TXcomBar;
    procedure AddStat(AIndex, AY: Integer; const AKey, ABarElement: string);
    procedure SetStat(AIndex, AWithArmor, ACurrent, AInitial: Integer);
    procedure OkClick(AAction: TXcomAction);
    procedure PrevClick(AAction: TXcomAction);
    procedure NextClick(AAction: TXcomAction);
    procedure ArmorClick(AAction: TXcomAction);
    procedure SackClick(AAction: TXcomAction);
    procedure EditChange(AAction: TXcomAction);
    procedure EditPress(AAction: TXcomAction);
  public
    /// <param name="ABase">The base; nil for the dead soldiers (not owned)</param>
    /// <param name="ASoldierId">The index in the list (for the dead, counted from the last)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer);
    procedure Init; override;
    property SoldierId: Integer read FSoldierId write FSoldierId;
    property Soldier: TXcomSoldier read FSoldier;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.SoldierDeath, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomMod.Armor,
  DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomBasescape.SackSoldierState,
  DelphiDoom.XcomBasescape.SoldierArmorState, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomBasescape.SellState;

{ TXcomSoldierInfoState }

constructor TXcomSoldierInfoState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer);
begin
  inherited Create(AHost);
  FBase := ABase;
  FSoldierId := ASoldierId;
  if FBase = nil then
  begin
    FList := TXcomStrategy.SavedGame(AHost).DeadSoldiers;
    if FSoldierId >= FList.Count then
      FSoldierId := 0
    else
      FSoldierId := FList.Count - (1 + FSoldierId);
  end
  else
    FList := FBase.Soldiers;
  FBackground := TXcomWidget.Create(320, 200, 0, 0);
  FRank := TXcomWidget.Create(26, 23, 4, 4);
  FBtnPrev := TXcomTextButton.Create(28, 14, 0, 33);
  FBtnOk := TXcomTextButton.Create(48, 14, 30, 33);
  FBtnNext := TXcomTextButton.Create(28, 14, 80, 33);
  FBtnArmor := TXcomTextButton.Create(110, 14, 130, 33);
  FEdtSoldier := TXcomTextEdit.Create(Self, 210, 16, 40, 9);
  FBtnSack := TXcomTextButton.Create(60, 14, 260, 33);
  FBtnDiary := TXcomTextButton.Create(60, 14, 260, 48);
  FTxtRank := TXcomText.Create(130, 9, 0, 48);
  FTxtMissions := TXcomText.Create(100, 9, 130, 48);
  FTxtKills := TXcomText.Create(100, 9, 200, 48);
  FTxtCraft := TXcomText.Create(130, 9, 0, 56);
  FTxtRecovery := TXcomText.Create(180, 9, 130, 56);
  FTxtPsionic := TXcomText.Create(150, 9, 0, 66);
  FTxtDead := TXcomText.Create(150, 9, 130, 33);
  SetInterface('soldierInfo');
  Add(FBackground);
  Add(FRank);
  Add(FBtnOk, 'button', 'soldierInfo');
  Add(FBtnPrev, 'button', 'soldierInfo');
  Add(FBtnNext, 'button', 'soldierInfo');
  Add(FBtnArmor, 'button', 'soldierInfo');
  Add(FEdtSoldier, 'text1', 'soldierInfo');
  Add(FBtnSack, 'button', 'soldierInfo');
  Add(FBtnDiary, 'button', 'soldierInfo');
  Add(FTxtRank, 'text1', 'soldierInfo');
  Add(FTxtMissions, 'text1', 'soldierInfo');
  Add(FTxtKills, 'text1', 'soldierInfo');
  Add(FTxtCraft, 'text1', 'soldierInfo');
  Add(FTxtRecovery, 'text1', 'soldierInfo');
  Add(FTxtPsionic, 'text2', 'soldierInfo');
  Add(FTxtDead, 'text2', 'soldierInfo');
  AddStat(0, 80, 'STR_TIME_UNITS', 'barTUs');
  AddStat(1, 91, 'STR_STAMINA', 'barEnergy');
  AddStat(2, 102, 'STR_HEALTH', 'barHealth');
  AddStat(3, 113, 'STR_BRAVERY', 'barBravery');
  AddStat(4, 124, 'STR_REACTIONS', 'barReactions');
  AddStat(5, 135, 'STR_FIRING_ACCURACY', 'barFiring');
  AddStat(6, 146, 'STR_THROWING_ACCURACY', 'barThrowing');
  AddStat(7, 157, 'STR_MELEE_ACCURACY', 'barMelee');
  AddStat(8, 168, 'STR_STRENGTH', 'barStrength');
  AddStat(9, 179, 'STR_PSIONIC_STRENGTH', 'barPsiStrength');
  AddStat(10, 190, 'STR_PSIONIC_SKILL', 'barPsiSkill');
  CenterAllSurfaces;
  Host.Resources.GetSurface('BACK06.SCR').Blit(FBackground);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnPrev.SetText('<<');
  FBtnNext.SetText('>>');
  // the dead are listed backwards: previous and next swap
  if FBase = nil then
  begin
    FBtnPrev.OnMouseClick(NextClick);
    FBtnPrev.OnKeyboardPress(NextClick, Host.Options.GetValue('keyBattlePrevUnit'));
    FBtnNext.OnMouseClick(PrevClick);
    FBtnNext.OnKeyboardPress(PrevClick, Host.Options.GetValue('keyBattleNextUnit'));
  end
  else
  begin
    FBtnPrev.OnMouseClick(PrevClick);
    FBtnPrev.OnKeyboardPress(PrevClick, Host.Options.GetValue('keyBattlePrevUnit'));
    FBtnNext.OnMouseClick(NextClick);
    FBtnNext.OnKeyboardPress(NextClick, Host.Options.GetValue('keyBattleNextUnit'));
  end;
  FBtnArmor.SetText(Tr('STR_ARMOR'));
  FBtnArmor.OnMouseClick(ArmorClick);
  FEdtSoldier.SetBig;
  FEdtSoldier.OnChange(EditChange);
  FEdtSoldier.OnMousePress(EditPress);
  FBtnSack.SetText(Tr('STR_SACK'));
  FBtnSack.OnMouseClick(SackClick);
  FBtnDiary.SetText(Tr('STR_DIARY'));
  FTxtPsionic.SetText(Tr('STR_IN_PSIONIC_TRAINING'));
end;

procedure TXcomSoldierInfoState.AddStat(AIndex, AY: Integer; const AKey, ABarElement: string);
begin
  FLabels[AIndex] := TXcomText.Create(120, 9, 6, AY);
  FNumbers[AIndex] := TXcomText.Create(18, 9, 131, AY);
  FBars[AIndex] := TXcomBar.Create(170, 7, 150, AY);
  Add(FLabels[AIndex], 'text2', 'soldierInfo');
  Add(FNumbers[AIndex], 'numbers', 'soldierInfo');
  Add(FBars[AIndex], ABarElement, 'soldierInfo');
  FLabels[AIndex].SetText(Tr(AKey));
  FBars[AIndex].SetScale(1.0);
end;

procedure TXcomSoldierInfoState.SetStat(AIndex, AWithArmor, ACurrent, AInitial: Integer);
begin
  FNumbers[AIndex].SetText(IntToStr(AWithArmor));
  FBars[AIndex].SetMax(ACurrent);
  FBars[AIndex].SetValue(AWithArmor);
  FBars[AIndex].SetValue2(Min(AWithArmor, AInitial));
end;

procedure TXcomSoldierInfoState.Init;
var
  LInitial, LCurrent, LWithArmor: TXcomUnitStats;
  LSave: TXcomSavedGame;
  LRuleset: TXcomRuleset;
  LArmorType, LArmorText, LCraftName, LStatus, LName: string;
  LCraft: TXcomCraft;
  LPsiRequirements: TArray<string>;
  LPsiVisible: Boolean;
  LFrame: TXcomWidget;
begin
  inherited Init;
  if FList.Count = 0 then
  begin
    Host.PopState;
    Exit;
  end;
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  FSoldier := FList[FSoldierId];
  LSave := TXcomStrategy.SavedGame(Host);
  LRuleset := TXcomStrategy.Ruleset(Host);
  FEdtSoldier.SetBig;
  FEdtSoldier.SetText(FSoldier.Name);
  LInitial := FSoldier.InitialStats;
  LCurrent := FSoldier.CurrentStats;
  LWithArmor := LCurrent + FSoldier.Armor.Stats;
  // the rank sprite is drawn in the corner of its own surface
  TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(42 + FSoldier.Rank).X := 0;
  TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(42 + FSoldier.Rank).Y := 0;
  TXcomStrategy.Rules(Host).GetSurfaceSet('BASEBITS.PCK').GetFrame(42 + FSoldier.Rank).Blit(FRank);
  SetStat(0, LWithArmor.TimeUnits, LCurrent.TimeUnits, LInitial.TimeUnits);
  SetStat(1, LWithArmor.Stamina, LCurrent.Stamina, LInitial.Stamina);
  SetStat(2, LWithArmor.Health, LCurrent.Health, LInitial.Health);
  SetStat(3, LWithArmor.Bravery, LCurrent.Bravery, LInitial.Bravery);
  SetStat(4, LWithArmor.Reactions, LCurrent.Reactions, LInitial.Reactions);
  SetStat(5, LWithArmor.Firing, LCurrent.Firing, LInitial.Firing);
  SetStat(6, LWithArmor.Throwing, LCurrent.Throwing, LInitial.Throwing);
  SetStat(7, LWithArmor.Melee, LCurrent.Melee, LInitial.Melee);
  SetStat(8, LWithArmor.Strength, LCurrent.Strength, LInitial.Strength);
  LArmorType := FSoldier.Armor.ArmorType;
  if LArmorType = FSoldier.Rules.ArmorName then
    LArmorText := Tr('STR_ARMOR_').Arg(Tr(LArmorType).Text).Text
  else
    LArmorText := Tr(LArmorType).Text;
  FBtnArmor.SetText(LArmorText);
  LCraft := nil;
  if FSoldier.Craft <> nil then
    LCraft := TXcomCraft(FSoldier.Craft);
  FBtnSack.Visible := (LSave.MonthsPassed > -1) and not (Assigned(LCraft) and (LCraft.Status = 'STR_OUT'));
  FTxtRank.SetText(Tr('STR_RANK_').Arg(Tr(TXcomBaseNames.RankKey(FSoldier.Rank)).Text));
  FTxtMissions.SetText(Tr('STR_MISSIONS').Arg(FSoldier.Missions));
  FTxtKills.SetText(Tr('STR_KILLS').Arg(FSoldier.Kills));
  if LCraft = nil then
    LCraftName := Tr('STR_NONE_UC').Text
  else
    LCraftName := TXcomBaseNames.CraftName(LCraft, Host.Language);
  FTxtCraft.SetText(Tr('STR_CRAFT_').Arg(LCraftName));
  if FSoldier.WoundRecovery > 0 then
    FTxtRecovery.SetText(Tr('STR_WOUND_RECOVERY').Arg(Tr('STR_DAY', FSoldier.WoundRecovery).Text))
  else
    FTxtRecovery.SetText('');
  FTxtPsionic.Visible := FSoldier.PsiTraining;
  // Mod::getPsiRequirements: the requirements of the first facility with psionic laboratories
  LPsiRequirements := nil;
  for LName in LRuleset.Facilities.Index do
    if LRuleset.Facilities.Find(LName).PsiLaboratories > 0 then
    begin
      LPsiRequirements := LRuleset.Facilities.Find(LName).Requirements;
      Break;
    end;
  LPsiVisible := (LCurrent.PsiSkill > 0) or (Host.Options.GetBool('psiStrengthEval') and
    LSave.IsResearched(LPsiRequirements));
  if LPsiVisible then
    SetStat(9, LWithArmor.PsiStrength, LCurrent.PsiStrength, LInitial.PsiStrength);
  FLabels[9].Visible := LPsiVisible;
  FNumbers[9].Visible := LPsiVisible;
  FBars[9].Visible := LPsiVisible;
  if LCurrent.PsiSkill > 0 then
    SetStat(10, LWithArmor.PsiSkill, LCurrent.PsiSkill, LInitial.PsiSkill);
  FLabels[10].Visible := LCurrent.PsiSkill > 0;
  FNumbers[10].Visible := LCurrent.PsiSkill > 0;
  FBars[10].Visible := LCurrent.PsiSkill > 0;
  if FBase = nil then
  begin
    // the dead can't talk
    FBtnArmor.Visible := False;
    FBtnSack.Visible := False;
    FTxtCraft.Visible := False;
    FTxtDead.Visible := True;
    LStatus := 'STR_MISSING_IN_ACTION';
    if Assigned(FSoldier.Death) and Assigned(FSoldier.Death.Cause) then
      LStatus := 'STR_KILLED_IN_ACTION';
    FTxtDead.SetText(Tr(LStatus, FSoldier.Gender).Text);
  end
  else
    FTxtDead.Visible := False;
end;

procedure TXcomSoldierInfoState.EditPress(AAction: TXcomAction);
begin
  if FBase = nil then
    FEdtSoldier.SetFocus(False);
end;

procedure TXcomSoldierInfoState.EditChange(AAction: TXcomAction);
begin
  FSoldier.Name := FEdtSoldier.GetText;
end;

procedure TXcomSoldierInfoState.OkClick(AAction: TXcomAction);
var
  LInterface: TXcomRuleInterface;
  LMessage, LPalette: TXcomInterfaceElement;
  LCapacity: TXcomBaseCapacity;
begin
  Host.PopState;
  if (TXcomStrategy.SavedGame(Host).MonthsPassed > -1) and Host.Options.GetBool('storageLimitsEnforced') and
    (FBase <> nil) then
  begin
    LCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(Host));
    try
      if LCapacity.StoresOverfull(FBase, 0) then
      begin
        LMessage := Default(TXcomInterfaceElement);
        LPalette := Default(TXcomInterfaceElement);
        LPalette.Color := -1;
        LInterface := Host.Resources.GetInterface('soldierInfo');
        if LInterface <> nil then
        begin
          LInterface.TryGetElement('errorMessage', LMessage);
          LInterface.TryGetElement('errorPalette', LPalette);
        end;
        Host.PushState(TXcomSellState.Create(Host, FBase));
        Host.PushState(TXcomErrorMessageState.Create(Host, Tr('STR_STORAGE_EXCEEDED').Arg(FBase.Name), Palette,
          Byte(LMessage.Color), 'BACK01.SCR', LPalette.Color));
      end;
    finally
      LCapacity.Free;
    end;
  end;
end;

procedure TXcomSoldierInfoState.PrevClick(AAction: TXcomAction);
begin
  if FSoldierId = 0 then
    FSoldierId := FList.Count - 1
  else
    Dec(FSoldierId);
  Init;
end;

procedure TXcomSoldierInfoState.NextClick(AAction: TXcomAction);
begin
  Inc(FSoldierId);
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  Init;
end;

procedure TXcomSoldierInfoState.ArmorClick(AAction: TXcomAction);
begin
  if (FSoldier.Craft = nil) or (TXcomCraft(FSoldier.Craft).Status <> 'STR_OUT') then
    Host.PushState(TXcomSoldierArmorState.Create(Host, FBase, FSoldierId));
end;

procedure TXcomSoldierInfoState.SackClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomSackSoldierState.Create(Host, FBase, FSoldierId));
end;

end.
