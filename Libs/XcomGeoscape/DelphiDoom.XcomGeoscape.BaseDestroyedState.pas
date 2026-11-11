{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - BaseDestroyedState of OpenXcom (the      }
{  aliens destroyed a base that nobody defended)                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.BaseDestroyedState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Ufo;

type
  /// <summary>
  ///   "The aliens have destroyed the undefended base": when it is made the retaliation mission of the region of the
  ///   base ends (its UFOs and the mission leave the saved game), OK takes the base off the saved game. The saved
  ///   game owns the base until then; nothing is owned here
  /// </summary>
  TXcomBaseDestroyedState = class(TXcomState)
  strict private
    FSave: TXcomSavedGame;
    FBase: TXcomBase;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtMessage: TXcomText;
    procedure EndRetaliation(const AOnUfoRemoving: TProc<TXcomUfo>);
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ASave">The saved game of the base (not owned)</param>
    /// <param name="AOnUfoRemoving">Called for each UFO of the retaliation before it is freed (the dogfights with it must go); can be nil</param>
    constructor Create(AHost: TXcomStateHost; ASave: TXcomSavedGame; ABase: TXcomBase;
      const AOnUfoRemoving: TProc<TXcomUfo> = nil);
    property OkButton: TXcomTextButton read FBtnOk;
    property MessageText: TXcomText read FTxtMessage;
  end;

implementation

uses
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomMod.RuleAlienMission, DelphiDoom.XcomSave.Region,
  DelphiDoom.XcomSave.AlienMission, DelphiDoom.XcomStrategy.Geography;

{ TXcomBaseDestroyedState }

constructor TXcomBaseDestroyedState.Create(AHost: TXcomStateHost; ASave: TXcomSavedGame; ABase: TXcomBase;
  const AOnUfoRemoving: TProc<TXcomUfo>);
begin
  inherited Create(AHost);
  FSave := ASave;
  FBase := ABase;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20);
  FBtnOk := TXcomTextButton.Create(100, 20, 110, 142);
  FTxtMessage := TXcomText.Create(224, 48, 48, 76);
  SetInterface('baseDestroyed');
  Add(FWindow, 'window', 'baseDestroyed');
  Add(FBtnOk, 'button', 'baseDestroyed');
  Add(FTxtMessage, 'text', 'baseDestroyed');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK15.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetBig;
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(Tr('STR_THE_ALIENS_HAVE_DESTROYED_THE_UNDEFENDED_BASE').Arg(FBase.Name));
  EndRetaliation(AOnUfoRemoving);
end;

procedure TXcomBaseDestroyedState.EndRetaliation(const AOnUfoRemoving: TProc<TXcomUfo>);
var
  LRegion: TXcomRegion;
  LMission, LFound: TXcomAlienMission;
  LIndex: Integer;
begin
  // a base outside every region: the C++ reads past the end of the list; here no mission ends
  LRegion := TXcomGeography.LocateRegion(FSave, FBase.Longitude, FBase.Latitude);
  if not Assigned(LRegion) then
    Exit;
  // SavedGame::findAlienMission(region, OBJECTIVE_RETALIATION)
  LFound := nil;
  for LMission in FSave.ActiveMissions do
    if (LMission.Region = LRegion.Rules.RegionType) and
      (LMission.Rule.Objective = TXcomRuleAlienMission.OBJECTIVE_RETALIATION) then
    begin
      LFound := LMission;
      Break;
    end;
  if not Assigned(LFound) then
    Exit;
  LIndex := 0;
  while LIndex < FSave.Ufos.Count do
    if FSave.Ufos[LIndex].Mission = LFound then
    begin
      if Assigned(AOnUfoRemoving) then
        AOnUfoRemoving(FSave.Ufos[LIndex]);
      FSave.Ufos.Delete(LIndex);
    end
    else
      Inc(LIndex);
  FSave.ActiveMissions.Remove(LFound);
end;

procedure TXcomBaseDestroyedState.OkClick(AAction: TXcomAction);
var
  LSave: TXcomSavedGame;
  LBase: TXcomBase;
begin
  LSave := FSave;
  LBase := FBase;
  Host.PopState;
  // the list owns the base: it is freed here
  LSave.Bases.Remove(LBase);
end;

end.
