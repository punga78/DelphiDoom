{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the briefing before a mission  }
{  (BriefingState: title, target, craft and the text of the mission)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.BriefingState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   The screen that tells the mission before the battle. OK pops it and calls AOnOk, which starts the battlescape
  ///   (BriefingState::btnOkClick is there, with the classes of the battle). Not ported: the cutscene of a
  ///   deployment and the change of resolution between geoscape and battlescape
  /// </summary>
  TXcomBriefingState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle, FTxtTarget, FTxtCraft, FTxtBriefing: TXcomText;
    FMusicId: string;
    FOnOk: TProc;
    procedure BtnOkClick(AAction: TXcomAction);
  public
    /// <param name="ARuleset">The rules, for the deployment of the mission</param>
    /// <param name="AMission">SavedBattleGame::getMissionType</param>
    /// <param name="ACraft">The craft that landed, or nil</param>
    /// <param name="ABase">The base that is defended, or nil</param>
    /// <param name="AOnOk">Called after the state was popped; can be nil</param>
    constructor Create(AHost: TXcomStateHost; ARuleset: TXcomRuleset; const AMission: string; ACraft: TXcomCraft;
      ABase: TXcomBase; const AOnOk: TProc);
    procedure Init; override;
    property TitleText: TXcomText read FTxtTitle;
    property TargetText: TXcomText read FTxtTarget;
    property CraftText: TXcomText read FTxtCraft;
    property OkButton: TXcomTextButton read FBtnOk;
  end;

implementation

uses
  DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomGeoscape.TargetNames;

constructor TXcomBriefingState.Create(AHost: TXcomStateHost; ARuleset: TXcomRuleset; const AMission: string;
  ACraft: TXcomCraft; ABase: TXcomBase; const AOnOk: TProc);
var
  LDeployment: TXcomAlienDeployment;
  LData: TXcomBriefingData;
  LTitle: string;
  LDescription: string;
  LCraftText: string;
begin
  inherited Create(AHost);
  FOnOk := AOnOk;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(120, 18, 100, 164);
  FTxtTitle := TXcomText.Create(300, 32, 16, 24);
  FTxtTarget := TXcomText.Create(300, 17, 16, 40);
  FTxtCraft := TXcomText.Create(300, 17, 16, 56);
  FTxtBriefing := TXcomText.Create(274, 94, 16, 72);
  LDeployment := ARuleset.AlienDeployments.Find(AMission);
  // landing site or crash site: the deployment of the UFO
  if (not Assigned(LDeployment)) and Assigned(ACraft) and (ACraft.Destination is TXcomUfo) then
    LDeployment := ARuleset.AlienDeployments.Find(TXcomUfo(ACraft.Destination).Rules.UfoType);
  LTitle := AMission;
  LDescription := LTitle + '_BRIEFING';
  if not Assigned(LDeployment) then
  begin
    // none defined - should never happen, but better safe than sorry
    SetPalette('PAL_GEOSCAPE', 0);
    FMusicId := 'GMDEFEND';
    FWindow.SetBackground(Host.Resources.GetSurface('BACK16.SCR'));
  end
  else
  begin
    LData := LDeployment.BriefingData;
    SetPalette('PAL_GEOSCAPE', LData.Palette);
    FWindow.SetBackground(Host.Resources.GetSurface(LData.Background));
    FTxtCraft.Y := 56 + LData.TextOffset;
    FTxtBriefing.Y := 72 + LData.TextOffset;
    FTxtTarget.Visible := LData.ShowTarget;
    FTxtCraft.Visible := LData.ShowCraft;
    FMusicId := LData.Music;
    if LData.Title <> '' then
      LTitle := LData.Title;
    if LData.Desc <> '' then
      LDescription := LData.Desc;
  end;
  Add(FWindow, 'window', 'briefing');
  Add(FBtnOk, 'button', 'briefing');
  Add(FTxtTitle, 'text', 'briefing');
  Add(FTxtTarget, 'text', 'briefing');
  Add(FTxtCraft, 'text', 'briefing');
  Add(FTxtBriefing, 'text', 'briefing');
  CenterAllSurfaces;
  FBtnOk.SetText(Tr('STR_OK').Text);
  FBtnOk.OnMouseClick(BtnOkClick);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTarget.SetBig;
  FTxtCraft.SetBig;
  LCraftText := '';
  if Assigned(ACraft) then
  begin
    if Assigned(ACraft.Destination) then
      FTxtTarget.SetText(TXcomTargetNames.Name(ACraft.Destination, Host.Language));
    LCraftText := Tr('STR_CRAFT_').Arg(TXcomTargetNames.Name(ACraft, Host.Language)).Text;
  end
  else if Assigned(ABase) then
    LCraftText := Tr('STR_BASE_UC_').Arg(ABase.Name).Text;
  FTxtCraft.SetText(LCraftText);
  FTxtTitle.SetText(Tr(LTitle).Text);
  FTxtBriefing.SetWordWrap(True);
  FTxtBriefing.SetText(Tr(LDescription).Text);
end;

procedure TXcomBriefingState.Init;
begin
  inherited Init;
  Host.PlayMusic(FMusicId);
end;

procedure TXcomBriefingState.BtnOkClick(AAction: TXcomAction);
var
  LOnOk: TProc;
begin
  // the state is freed by the game after the pop: the handler is kept in a local
  LOnOk := FOnOk;
  Host.PopState;
  if Assigned(LOnOk) then
    LOnOk();
end;

end.
