{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the screens that follow the            }
{  debriefing (DebriefingState::btnOkClick of OpenXcom)                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.FollowUp;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomDebriefing.Types;

type
  /// <summary>
  ///   What the player sees after OK on the debriefing. The screens are pushed in the order of the C++, so the last
  ///   one pushed is the first that shows: the medals of the dead, the medals, the promotions, the items that the
  ///   craft misses, the containment with its message or the sale of what the stores cannot hold with its message
  ///   (nothing of these three when the base was lost), then the save of an ironman game or the autosave. A battle
  ///   that is not part of a campaign (monthsPassed = -1) goes to the main menu and nothing else. The host, the saved
  ///   game and the ruleset are not owned
  /// </summary>
  TXcomDebriefingFollowUp = class
  strict private
    FHost: TXcomStateHost;
    FSavedGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FStorageLimitsEnforced: Boolean;
    FMainMenu: TFunc<TXcomState>;
    function InterfaceColor(const AElement: string): Integer;
    procedure PushError(const AMessageId, ABaseName: string; APalette: PXcomColors);
    procedure PushSave(APalette: PXcomColors);
  public
    /// <param name="AStorageLimitsEnforced">Options::storageLimitsEnforced</param>
    /// <param name="AMainMenu">Makes the main menu for a battle outside a campaign; nil: the states stay as they are</param>
    constructor Create(AHost: TXcomStateHost; const ASavedGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
      AStorageLimitsEnforced: Boolean; const AMainMenu: TFunc<TXcomState>);
    /// <summary>Pushes the screens for the report of a mission</summary>
    /// <param name="APalette">The palette of the debriefing screen: the messages and the save screen take it</param>
    procedure Push(const AReport: TXcomDebriefingReport; APalette: PXcomColors);
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomSave.BaseCapacity,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomMenu.SaveGameState,
  DelphiDoom.XcomBasescape.SellState, DelphiDoom.XcomDebriefing.CannotReequipState,
  DelphiDoom.XcomDebriefing.CommendationState, DelphiDoom.XcomDebriefing.CommendationLateState,
  DelphiDoom.XcomDebriefing.PromotionsState, DelphiDoom.XcomDebriefing.ManageAlienContainmentState;

const
  DEBRIEFING_INTERFACE = 'debriefing';
  ERROR_BACKGROUND = 'BACK01.SCR';

{ TXcomDebriefingFollowUp }

constructor TXcomDebriefingFollowUp.Create(AHost: TXcomStateHost; const ASavedGame: TXcomSavedGame;
  const ARuleset: TXcomRuleset; AStorageLimitsEnforced: Boolean; const AMainMenu: TFunc<TXcomState>);
begin
  inherited Create;
  FHost := AHost;
  FSavedGame := ASavedGame;
  FRuleset := ARuleset;
  FStorageLimitsEnforced := AStorageLimitsEnforced;
  FMainMenu := AMainMenu;
end;

function TXcomDebriefingFollowUp.InterfaceColor(const AElement: string): Integer;
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  Result := 0;
  LInterface := FHost.Resources.GetInterface(DEBRIEFING_INTERFACE);
  if (LInterface <> nil) and LInterface.TryGetElement(AElement, LElement) then
    Result := LElement.Color;
end;

procedure TXcomDebriefingFollowUp.PushError(const AMessageId, ABaseName: string; APalette: PXcomColors);
begin
  FHost.PushState(TXcomErrorMessageState.Create(FHost, FHost.Language.GetString(AMessageId).Arg(ABaseName).Text,
    APalette, Byte(InterfaceColor('errorMessage')), ERROR_BACKGROUND, InterfaceColor('errorPalette')));
end;

procedure TXcomDebriefingFollowUp.PushSave(APalette: PXcomColors);
var
  LSaver: IXcomSavedGameSaver;
begin
  // a host that cannot save has no autosave
  LSaver := FHost.SavedGameSaver;
  if LSaver = nil then
    Exit;
  if LSaver.IsIronman then
    FHost.PushState(TXcomSaveGameState.Create(FHost, ooGeoscape, stIronman, APalette))
  else if FHost.Options.GetBool('autosave') then
    FHost.PushState(TXcomSaveGameState.Create(FHost, ooGeoscape, stAutoGeoscape, APalette));
end;

procedure TXcomDebriefingFollowUp.Push(const AReport: TXcomDebriefingReport; APalette: PXcomColors);
var
  LCapacity: TXcomBaseCapacity;
  LOverfull: Boolean;
begin
  if FSavedGame.MonthsPassed = -1 then
  begin
    if Assigned(FMainMenu) then
      FHost.SetState(FMainMenu());
    Exit;
  end;
  if AReport.DeadSoldiersCommended.Count > 0 then
    FHost.PushState(TXcomCommendationLateState.Create(FHost, AReport.DeadSoldiersCommended, FRuleset.Commendations));
  if AReport.SoldiersCommended.Count > 0 then
    FHost.PushState(TXcomCommendationState.Create(FHost, AReport.SoldiersCommended, FRuleset.Commendations));
  if not AReport.DestroyBase then
  begin
    if AReport.Promotions then
      FHost.PushState(TXcomPromotionsState.Create(FHost, FSavedGame));
    if AReport.MissingItems.Count > 0 then
      FHost.PushState(TXcomCannotReequipState.Create(FHost, AReport.MissingItems));
    if AReport.ManageContainment then
    begin
      FHost.PushState(TXcomManageAlienContainmentState.Create(FHost, AReport.Base, FSavedGame, FRuleset,
        ooBattlescape));
      PushError('STR_CONTAINMENT_EXCEEDED', AReport.Base.Name, APalette);
    end
    else if FStorageLimitsEnforced then
    begin
      LCapacity := TXcomBaseCapacity.Create(FRuleset);
      try
        LOverfull := LCapacity.StoresOverfull(AReport.Base, 0);
      finally
        LCapacity.Free;
      end;
      if LOverfull then
      begin
        FHost.PushState(TXcomSellState.Create(FHost, AReport.Base, True));
        PushError('STR_STORAGE_EXCEEDED', AReport.Base.Name, APalette);
      end;
    end;
  end;
  PushSave(APalette);
end;

end.
