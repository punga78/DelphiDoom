{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - AllocatePsiTrainingState of OpenXcom    }
{  (who trains in the psionic laboratories of a base)                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.AllocatePsiTrainingState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   The soldiers of a base with their psionic strength and skill; a click puts one in the training or takes him
  ///   out, as long as the laboratories have room
  /// </summary>
  TXcomAllocatePsiTrainingState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FLabSpace: Integer;
    FWindow: TXcomWindow;
    FTxtTitle: TXcomText;
    FTxtRemaining: TXcomText;
    FTxtName: TXcomText;
    FTxtPsiStrength: TXcomText;
    FTxtPsiSkill: TXcomText;
    FTxtTraining: TXcomText;
    FBtnOk: TXcomTextButton;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure ListClick(AAction: TXcomAction);
    procedure ShowRemaining;
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    property List: TXcomTextList read FList;
    property LabSpace: Integer read FLabSpace;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomBasescape.PsiRequirements;

{ TXcomAllocatePsiTrainingState }

constructor TXcomAllocatePsiTrainingState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LCapacity: TXcomBaseCapacity;
  LSoldier: TXcomSoldier;
  LStrength, LSkill: string;
  LRow: Integer;
  LEvaluate: Boolean;
begin
  inherited Create(AHost);
  FBase := ABase;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FTxtTitle := TXcomText.Create(300, 17, 10, 8);
  FTxtRemaining := TXcomText.Create(300, 10, 10, 24);
  FTxtName := TXcomText.Create(64, 10, 10, 40);
  FTxtPsiStrength := TXcomText.Create(80, 20, 124, 32);
  FTxtPsiSkill := TXcomText.Create(80, 20, 188, 32);
  FTxtTraining := TXcomText.Create(48, 20, 270, 32);
  FBtnOk := TXcomTextButton.Create(160, 14, 80, 174);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 290, 112, 8, 52);
  SetInterface('allocatePsi');
  Add(FWindow, 'window', 'allocatePsi');
  Add(FBtnOk, 'button', 'allocatePsi');
  Add(FTxtName, 'text', 'allocatePsi');
  Add(FTxtTitle, 'text', 'allocatePsi');
  Add(FTxtRemaining, 'text', 'allocatePsi');
  Add(FTxtPsiStrength, 'text', 'allocatePsi');
  Add(FTxtPsiSkill, 'text', 'allocatePsi');
  Add(FTxtTraining, 'text', 'allocatePsi');
  Add(FList, 'list', 'allocatePsi');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_PSIONIC_TRAINING'));
  LCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(AHost));
  try
    FLabSpace := LCapacity.AvailablePsiLabs(FBase) - LCapacity.UsedPsiLabs(FBase);
  finally
    LCapacity.Free;
  end;
  ShowRemaining;
  FTxtName.SetText(Tr('STR_NAME'));
  FTxtPsiStrength.SetText(Tr('STR_PSIONIC__STRENGTH'));
  FTxtPsiSkill.SetText(Tr('STR_PSIONIC_SKILL_IMPROVEMENT'));
  FTxtTraining.SetText(Tr('STR_IN_TRAINING'));
  FList.SetAlign(haRight, 3);
  FList.SetColumns([114, 80, 62, 30]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(2);
  FList.OnMouseClick(ListClick);
  LEvaluate := Host.Options.GetBool('psiStrengthEval') and
    TXcomStrategy.SavedGame(AHost).IsResearched(TXcomPsiRequirements.Resolve(TXcomStrategy.Ruleset(AHost)));
  LRow := 0;
  for LSoldier in FBase.Soldiers do
  begin
    if (LSoldier.CurrentStats.PsiSkill > 0) or LEvaluate then
    begin
      LStrength := '   ' + IntToStr(LSoldier.CurrentStats.PsiStrength);
      if Host.Options.GetBool('allowPsiStrengthImprovement') then
        LStrength := LStrength + '/+' + IntToStr(LSoldier.PsiStrImprovement);
    end
    else
      LStrength := Tr('STR_UNKNOWN').Text;
    if LSoldier.CurrentStats.PsiSkill > 0 then
      LSkill := IntToStr(LSoldier.CurrentStats.PsiSkill) + '/+' + IntToStr(LSoldier.Improvement)
    else
      LSkill := '0/+0';
    if LSoldier.PsiTraining then
    begin
      FList.AddRow([LSoldier.Name, LStrength, LSkill, Tr('STR_YES').Text]);
      FList.SetRowColor(LRow, FList.GetSecondaryColor);
    end
    else
    begin
      FList.AddRow([LSoldier.Name, LStrength, LSkill, Tr('STR_NO').Text]);
      FList.SetRowColor(LRow, FList.GetColor);
    end;
    Inc(LRow);
  end;
end;

procedure TXcomAllocatePsiTrainingState.ShowRemaining;
begin
  FTxtRemaining.SetText(Tr('STR_REMAINING_PSI_LAB_CAPACITY').Arg(FLabSpace));
end;

procedure TXcomAllocatePsiTrainingState.OkClick(AAction: TXcomAction);
begin
  // calcStatString: the TFTD mods have no stat strings, there is nothing to recompute
  Host.PopState;
end;

procedure TXcomAllocatePsiTrainingState.ListClick(AAction: TXcomAction);
var
  LCapacity: TXcomBaseCapacity;
  LSelected: Integer;
  LSoldier: TXcomSoldier;
  LHasRoom: Boolean;
begin
  if AAction.Details^.Button <> XCOM_BUTTON_LEFT then
    Exit;
  LSelected := FList.GetSelectedRow;
  LSoldier := FBase.Soldiers[LSelected];
  if not LSoldier.PsiTraining then
  begin
    LCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(Host));
    try
      LHasRoom := LCapacity.UsedPsiLabs(FBase) < LCapacity.AvailablePsiLabs(FBase);
    finally
      LCapacity.Free;
    end;
    if LHasRoom then
    begin
      FList.SetCellText(LSelected, 3, Tr('STR_YES').Text);
      FList.SetRowColor(LSelected, FList.GetSecondaryColor);
      Dec(FLabSpace);
      ShowRemaining;
      LSoldier.PsiTraining := True;
    end;
  end
  else
  begin
    FList.SetCellText(LSelected, 3, Tr('STR_NO').Text);
    FList.SetRowColor(LSelected, FList.GetColor);
    Inc(FLabSpace);
    ShowRemaining;
    LSoldier.PsiTraining := False;
  end;
end;

end.
