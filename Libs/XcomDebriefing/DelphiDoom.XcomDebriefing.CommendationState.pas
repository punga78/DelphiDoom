{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - CommendationState of OpenXcom (the     }
{  medals that the soldiers got in the mission)                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.CommendationState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomSave.Soldier;

type
  /// <summary>
  ///   The new medals by kind: a row with the name of the medal (with its noun, when it has one) and under it the
  ///   soldiers that got it with the level. The medals that are shown stop being new (makeOld). The soldiers and the
  ///   rules are not owned and are not kept after the constructor
  /// </summary>
  TXcomCommendationState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure FillList(const ASoldiers: TList<TXcomSoldier>; const ARules: TXcomStringMap<TXcomRuleCommendations>);
  public
    /// <param name="ASoldiers">The soldiers with new medals (_soldiersCommended)</param>
    /// <param name="ARules">Mod::getCommendationsList</param>
    constructor Create(AHost: TXcomStateHost; const ASoldiers: TList<TXcomSoldier>;
      const ARules: TXcomStringMap<TXcomRuleCommendations>);
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomDebriefing.CommendationNames;

{ TXcomCommendationState }

constructor TXcomCommendationState.Create(AHost: TXcomStateHost; const ASoldiers: TList<TXcomSoldier>;
  const ARules: TXcomStringMap<TXcomRuleCommendations>);
begin
  inherited Create(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TXcomText.Create(300, 16, 10, 8);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 32);
  SetInterface('commendations');
  Add(FWindow, 'window', 'commendations');
  Add(FBtnOk, 'button', 'commendations');
  Add(FTxtTitle, 'heading', 'commendations');
  Add(FList, 'list', 'commendations');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetText(Tr('STR_MEDALS'));
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FList.SetColumns([204, 84]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  FillList(ASoldiers, ARules);
end;

procedure TXcomCommendationState.FillList(const ASoldiers: TList<TXcomSoldier>;
  const ARules: TXcomStringMap<TXcomRuleCommendations>);
var
  LRuleIndex, LRow, LTitleRow: Integer;
  LModular, LTitleChosen: Boolean;
  LNoun, LType: string;
  LSoldier: TXcomSoldier;
  LCommendation: TXcomSoldierCommendation;
begin
  LRow := 0;
  LTitleChosen := True;
  LRuleIndex := 0;
  // a medal with a noun is gone through once for every noun: the index moves on only when no noun was found
  while LRuleIndex < ARules.Count do
  begin
    LType := ARules.Key(LRuleIndex);
    LModular := False;
    LNoun := TXcomCommendationNames.NO_NOUN;
    if LTitleChosen then
    begin
      // a blank row that gets the name of the medal later
      FList.AddRow(['', '']);
      Inc(LRow);
    end;
    LTitleChosen := False;
    LTitleRow := LRow - 1;
    for LSoldier in ASoldiers do
      for LCommendation in LSoldier.Diary.Commendations do
        if (LCommendation.CommendationType = LType) and LCommendation.IsNew and
          (LNoun = TXcomCommendationNames.NO_NOUN) then
        begin
          LCommendation.MakeOld;
          Inc(LRow);
          if LCommendation.Noun <> TXcomCommendationNames.NO_NOUN then
          begin
            LNoun := LCommendation.Noun;
            LModular := True;
          end;
          FList.AddRow(['   ' + LSoldier.Name,
            Tr(TXcomCommendationNames.LevelKey(ARules.Value(LRuleIndex), LCommendation)).Text]);
          Break;
        end;
    if LTitleRow <> LRow - 1 then
    begin
      if LModular then
        FList.SetCellText(LTitleRow, 0, Tr(LType).Arg(Tr(LNoun).Text).Text)
      else
        FList.SetCellText(LTitleRow, 0, Tr(LType).Text);
      FList.SetRowColor(LTitleRow, FList.GetSecondaryColor);
      LTitleChosen := True;
    end;
    if LNoun = TXcomCommendationNames.NO_NOUN then
      Inc(LRuleIndex);
  end;
end;

procedure TXcomCommendationState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
