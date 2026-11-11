{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SoldiersState of OpenXcom (the list of }
{  the soldiers of a base)                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldiersState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   The soldiers of a base: name, rank and craft (or wounded, or none: in the second color). The screens that
  ///   the psi training button, the memorial and a click on a soldier open are not ported: they do nothing
  /// </summary>
  TXcomSoldiersState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnPsiTraining: TXcomTextButton;
    FBtnMemorial: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtName: TXcomText;
    FTxtRank: TXcomText;
    FTxtCraft: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure ListClick(AAction: TXcomAction);
    procedure MemorialClick(AAction: TXcomAction);
    procedure PsiTrainingClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    procedure Init; override;
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomBasescape.SoldierInfoState,
  DelphiDoom.XcomBasescape.SoldierMemorialState, DelphiDoom.XcomBasescape.AllocatePsiTrainingState;

{ TXcomSoldiersState }

constructor TXcomSoldiersState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LPsiButtonVisible: Boolean;
  LCapacity: TXcomBaseCapacity;
begin
  inherited Create(AHost);
  FBase := ABase;
  LCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(AHost));
  try
    LPsiButtonVisible := Host.Options.GetBool('anytimePsiTraining') and (LCapacity.AvailablePsiLabs(FBase) > 0);
  finally
    LCapacity.Free;
  end;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  if LPsiButtonVisible then
  begin
    FBtnOk := TXcomTextButton.Create(96, 16, 216, 176);
    FBtnPsiTraining := TXcomTextButton.Create(96, 16, 112, 176);
    FBtnMemorial := TXcomTextButton.Create(96, 16, 8, 176);
  end
  else
  begin
    FBtnOk := TXcomTextButton.Create(148, 16, 164, 176);
    FBtnPsiTraining := TXcomTextButton.Create(148, 16, 164, 176);
    FBtnMemorial := TXcomTextButton.Create(148, 16, 8, 176);
  end;
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtName := TXcomText.Create(114, 9, 16, 32);
  FTxtRank := TXcomText.Create(102, 9, 130, 32);
  FTxtCraft := TXcomText.Create(82, 9, 222, 32);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 40);
  SetInterface('soldierList');
  Add(FWindow, 'window', 'soldierList');
  Add(FBtnOk, 'button', 'soldierList');
  Add(FBtnPsiTraining, 'button', 'soldierList');
  Add(FBtnMemorial, 'button', 'soldierList');
  Add(FTxtTitle, 'text1', 'soldierList');
  Add(FTxtName, 'text2', 'soldierList');
  Add(FTxtRank, 'text2', 'soldierList');
  Add(FTxtCraft, 'text2', 'soldierList');
  Add(FList, 'list', 'soldierList');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnPsiTraining.SetText(Tr('STR_PSI_TRAINING'));
  FBtnPsiTraining.Visible := LPsiButtonVisible;
  FBtnPsiTraining.OnMouseClick(PsiTrainingClick);
  FBtnMemorial.SetText(Tr('STR_MEMORIAL'));
  FBtnMemorial.OnMouseClick(MemorialClick);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_SOLDIER_LIST'));
  FTxtName.SetText(Tr('STR_NAME_UC'));
  FTxtRank.SetText(Tr('STR_RANK'));
  FTxtCraft.SetText(Tr('STR_CRAFT'));
  FList.SetColumns([114, 92, 74]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  FList.OnMouseClick(ListClick);
end;

procedure TXcomSoldiersState.Init;
var
  LSoldier: TXcomSoldier;
  LRow: Integer;
begin
  inherited Init;
  LRow := 0;
  FList.ClearList;
  for LSoldier in FBase.Soldiers do
  begin
    FList.AddRow([LSoldier.Name, Tr(TXcomBaseNames.RankKey(LSoldier.Rank)).Text,
      TXcomBaseNames.CraftText(LSoldier, Host.Language)]);
    if not Assigned(LSoldier.Craft) then
      FList.SetRowColor(LRow, FList.GetSecondaryColor);
    Inc(LRow);
  end;
  if (LRow > 0) and (FList.GetScroll >= LRow) then
    FList.ScrollTo(0);
end;

procedure TXcomSoldiersState.ListClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomSoldierInfoState.Create(Host, FBase, FList.GetSelectedRow));
end;

procedure TXcomSoldiersState.PsiTrainingClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomAllocatePsiTrainingState.Create(Host, FBase));
end;

procedure TXcomSoldiersState.MemorialClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomSoldierMemorialState.Create(Host));
end;

procedure TXcomSoldiersState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
