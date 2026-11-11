{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - CommendationLateState of OpenXcom (the }
{  medals of the soldiers that died in the mission: "Lost in service")          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.CommendationLateState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.RuleCommendations, DelphiDoom.XcomSave.Soldier;

type
  /// <summary>
  ///   The dead soldiers with new medals: a row with the name, the rank and the kills of each, and under it its new
  ///   medals with the level. The medals that are shown stop being new (makeOld). The soldiers and the rules are not
  ///   owned and are not kept after the constructor
  /// </summary>
  TXcomCommendationLateState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure FillList(const ASoldiers: TList<TXcomSoldier>; const ARules: TXcomStringMap<TXcomRuleCommendations>);
  public
    /// <param name="ASoldiers">The dead soldiers with new medals (_deadSoldiersCommended)</param>
    /// <param name="ARules">Mod::getCommendationsList</param>
    constructor Create(AHost: TXcomStateHost; const ASoldiers: TList<TXcomSoldier>;
      const ARules: TXcomStringMap<TXcomRuleCommendations>);
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomBasescape.Names,
  DelphiDoom.XcomDebriefing.CommendationNames;

{ TXcomCommendationLateState }

constructor TXcomCommendationLateState.Create(AHost: TXcomStateHost; const ASoldiers: TList<TXcomSoldier>;
  const ARules: TXcomStringMap<TXcomRuleCommendations>);
begin
  inherited Create(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TXcomText.Create(300, 16, 10, 8);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 32);
  SetInterface('commendationsLate');
  Add(FWindow, 'window', 'commendationsLate');
  Add(FBtnOk, 'button', 'commendationsLate');
  Add(FTxtTitle, 'text', 'commendationsLate');
  Add(FList, 'list', 'commendationsLate');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_LOST_IN_SERVICE'));
  FList.SetColumns([51, 51, 51, 51, 84]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  FList.SetFlooding(True);
  FillList(ASoldiers, ARules);
end;

procedure TXcomCommendationLateState.FillList(const ASoldiers: TList<TXcomSoldier>;
  const ARules: TXcomStringMap<TXcomRuleCommendations>);
var
  LRuleIndex: Integer;
  LModular: Boolean;
  LNoun, LType, LName: string;
  LSoldier: TXcomSoldier;
  LCommendation: TXcomSoldierCommendation;
begin
  for LSoldier in ASoldiers do
  begin
    FList.AddRow([LSoldier.Name, '', Tr(TXcomBaseNames.RankKey(LSoldier.Rank)).Text, '',
      Tr('STR_KILLS').Arg(LSoldier.Diary.KillTotal).Text]);
    LRuleIndex := 0;
    // a medal with a noun is gone through once for every noun: the index moves on only when no noun was found
    while LRuleIndex < ARules.Count do
    begin
      LType := ARules.Key(LRuleIndex);
      LModular := False;
      LNoun := TXcomCommendationNames.NO_NOUN;
      for LCommendation in LSoldier.Diary.Commendations do
        if (LCommendation.CommendationType = LType) and LCommendation.IsNew and
          (LNoun = TXcomCommendationNames.NO_NOUN) then
        begin
          LCommendation.MakeOld;
          if LCommendation.Noun <> TXcomCommendationNames.NO_NOUN then
          begin
            LNoun := LCommendation.Noun;
            LModular := True;
          end;
          if LModular then
            LName := '   ' + Tr(LType).Arg(Tr(LNoun).Text).Text
          else
            LName := '   ' + Tr(LType).Text;
          FList.AddRow([LName, '', '', '',
            Tr(TXcomCommendationNames.LevelKey(ARules.Value(LRuleIndex), LCommendation)).Text]);
          Break;
        end;
      if LNoun = TXcomCommendationNames.NO_NOUN then
        Inc(LRuleIndex);
    end;
  end;
end;

procedure TXcomCommendationLateState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
