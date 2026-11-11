{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the end of a battle in the game (the    }
{  debriefing and the screens that follow it)                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Debriefer;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomDebriefing.Types, DelphiDoom.XcomDebriefing.DebriefingState,
  DelphiDoom.XcomDebriefing.Debriefer.Intf;

type
  /// <summary>
  ///   IXcomMissionDebriefer on the saved game and the rules of the host: runs the debriefing and makes the screen.
  ///   When the player says OK the screens of DebriefingState::btnOkClick follow, pushed in the order of the C++ (so
  ///   the last one is the first that the player sees): the medals of the dead, the medals, the promotions, the items
  ///   that the craft misses, the containment (with its message) or the sale of what the stores cannot hold (with its
  ///   message), and the save of an ironman game or the autosave. A battle that is not part of a campaign
  ///   (monthsPassed = -1) goes back to the main menu instead. AOnFinished is called after all of that
  /// </summary>
  TXcomMissionDebriefer = class(TInterfacedObject, IXcomMissionDebriefer)
  strict private
    FHost: TXcomStateHost;
    FOptions: TXcomDebriefingOptions;
    FOnFinished: TXcomDebriefingFinished;
    FZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>;
    FMainMenu: TFunc<TXcomState>;
    FRules: TXcomRulesetRules;
    FRulesetOfRules: TXcomRuleset;
    function InterfaceColor(const AElement: string): Integer;
    procedure PushError(const AMessage: string; APalette: PXcomColors);
    procedure PushFollowingScreens(const AReport: TXcomDebriefingReport; APalette: PXcomColors);
  public
    /// <param name="AHost">The host of the states (the saved game and the rules come from it)</param>
    /// <param name="AOnFinished">Called when the player closes the debriefing, after the screens are pushed; can be nil</param>
    /// <param name="AZombieConverter">SavedBattleGame::convertUnit for a recovered zombie; can be nil</param>
    /// <param name="AMainMenu">Makes the main menu for a battle outside a campaign; nil: nothing replaces the states</param>
    constructor Create(AHost: TXcomStateHost; const AOptions: TXcomDebriefingOptions;
      const AOnFinished: TXcomDebriefingFinished; const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>;
      const AMainMenu: TFunc<TXcomState> = nil);
    destructor Destroy; override;
    function Debrief(const ABattle: TXcomSavedBattleGame): TXcomState;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomMenu.SaveGameState, DelphiDoom.XcomBasescape.SellState,
  DelphiDoom.XcomDebriefing.Debriefing, DelphiDoom.XcomDebriefing.CannotReequipState,
  DelphiDoom.XcomDebriefing.CommendationState, DelphiDoom.XcomDebriefing.CommendationLateState,
  DelphiDoom.XcomDebriefing.PromotionsState, DelphiDoom.XcomDebriefing.ManageAlienContainmentState;

const
  DEBRIEFING_INTERFACE = 'debriefing';
  ERROR_BACKGROUND = 'BACK01.SCR';

{ TXcomMissionDebriefer }

constructor TXcomMissionDebriefer.Create(AHost: TXcomStateHost; const AOptions: TXcomDebriefingOptions;
  const AOnFinished: TXcomDebriefingFinished; const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>;
  const AMainMenu: TFunc<TXcomState>);
begin
  inherited Create;
  FHost := AHost;
  FOptions := AOptions;
  FOnFinished := AOnFinished;
  FZombieConverter := AZombieConverter;
  FMainMenu := AMainMenu;
end;

destructor TXcomMissionDebriefer.Destroy;
begin
  FRules.Free;
  inherited Destroy;
end;

function TXcomMissionDebriefer.InterfaceColor(const AElement: string): Integer;
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  Result := 0;
  LInterface := FHost.Resources.GetInterface(DEBRIEFING_INTERFACE);
  if (LInterface <> nil) and LInterface.TryGetElement(AElement, LElement) then
    Result := LElement.Color;
end;

procedure TXcomMissionDebriefer.PushError(const AMessage: string; APalette: PXcomColors);
begin
  FHost.PushState(TXcomErrorMessageState.Create(FHost, AMessage, APalette, Byte(InterfaceColor('errorMessage')),
    ERROR_BACKGROUND, InterfaceColor('errorPalette')));
end;

procedure TXcomMissionDebriefer.PushFollowingScreens(const AReport: TXcomDebriefingReport; APalette: PXcomColors);
var
  LSave: TXcomSavedGame;
  LRuleset: TXcomRuleset;
  LCapacity: TXcomBaseCapacity;
  LSaver: IXcomSavedGameSaver;
  LLanguageText: string;
begin
  LSave := TXcomStrategy.SavedGame(FHost);
  LRuleset := TXcomStrategy.Ruleset(FHost);
  if LSave.MonthsPassed = -1 then
  begin
    if Assigned(FMainMenu) then
      FHost.SetState(FMainMenu());
    Exit;
  end;
  if AReport.DeadSoldiersCommended.Count > 0 then
    FHost.PushState(TXcomCommendationLateState.Create(FHost, AReport.DeadSoldiersCommended, LRuleset.Commendations));
  if AReport.SoldiersCommended.Count > 0 then
    FHost.PushState(TXcomCommendationState.Create(FHost, AReport.SoldiersCommended, LRuleset.Commendations));
  if not AReport.DestroyBase then
  begin
    if AReport.Promotions then
      FHost.PushState(TXcomPromotionsState.Create(FHost, LSave));
    if AReport.MissingItems.Count > 0 then
      FHost.PushState(TXcomCannotReequipState.Create(FHost, AReport.MissingItems));
    if AReport.ManageContainment then
    begin
      FHost.PushState(TXcomManageAlienContainmentState.Create(FHost, AReport.Base, LSave, LRuleset, ooBattlescape));
      LLanguageText := FHost.Language.GetString('STR_CONTAINMENT_EXCEEDED').Arg(AReport.Base.Name).Text;
      PushError(LLanguageText, APalette);
    end
    else if FOptions.StorageLimitsEnforced then
    begin
      LCapacity := TXcomBaseCapacity.Create(LRuleset);
      try
        if LCapacity.StoresOverfull(AReport.Base, 0) then
        begin
          FHost.PushState(TXcomSellState.Create(FHost, AReport.Base, True));
          LLanguageText := FHost.Language.GetString('STR_STORAGE_EXCEEDED').Arg(AReport.Base.Name).Text;
          PushError(LLanguageText, APalette);
        end;
      finally
        LCapacity.Free;
      end;
    end;
  end;
  // the autosave after the mission: a host that cannot save has none
  LSaver := FHost.SavedGameSaver;
  if LSaver <> nil then
  begin
    if LSaver.IsIronman then
      FHost.PushState(TXcomSaveGameState.Create(FHost, ooGeoscape, stIronman, APalette))
    else if FHost.Options.GetBool('autosave') then
      FHost.PushState(TXcomSaveGameState.Create(FHost, ooGeoscape, stAutoGeoscape, APalette));
  end;
end;

function TXcomMissionDebriefer.Debrief(const ABattle: TXcomSavedBattleGame): TXcomState;
var
  LRuleset: TXcomRuleset;
  LReport: TXcomDebriefingReport;
  LState: TXcomDebriefingState;
begin
  LRuleset := TXcomStrategy.Ruleset(FHost);
  if (not Assigned(FRules)) or (FRulesetOfRules <> LRuleset) then
  begin
    FRules.Free;
    FRules := TXcomRulesetRules.Create(LRuleset);
    FRulesetOfRules := LRuleset;
  end;
  LReport := TXcomDebriefing.Run(TXcomStrategy.SavedGame(FHost), ABattle, LRuleset, FRules, FOptions, FZombieConverter);
  // the closure runs when the player says OK: by then LState is the screen (it is still alive: a popped state is
  // freed on the next turn of the game), and its palette is the one that the messages take

  LState := TXcomDebriefingState.Create(FHost, LReport,
    procedure(const AReport: TXcomDebriefingReport)
    begin
      PushFollowingScreens(AReport, LState.Palette);
      if Assigned(FOnFinished) then
        FOnFinished(AReport);
    end, True);
  Result := LState;
end;

end.
