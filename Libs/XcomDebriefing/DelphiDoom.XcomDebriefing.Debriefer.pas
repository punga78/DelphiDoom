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
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomDebriefing.Types,
  DelphiDoom.XcomDebriefing.DebriefingState, DelphiDoom.XcomDebriefing.Debriefer.Intf;

type
  /// <summary>
  ///   IXcomMissionDebriefer on the saved game and the rules of the host: runs the debriefing and makes the screen,
  ///   which owns the report. When the player says OK the screens of TXcomDebriefingFollowUp follow (medals,
  ///   promotions, missing items, containment or sale, the autosave; the main menu for a battle outside a campaign),
  ///   and then AOnFinished is called
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
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomDebriefing.Debriefing,
  DelphiDoom.XcomDebriefing.FollowUp;

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

function TXcomMissionDebriefer.Debrief(const ABattle: TXcomSavedBattleGame): TXcomState;
var
  LRuleset: TXcomRuleset;
  LSave: TXcomSavedGame;
  LReport: TXcomDebriefingReport;
  LState: TXcomDebriefingState;
  LHost: TXcomStateHost;
  LLimits: Boolean;
  LMainMenu: TFunc<TXcomState>;
  LOnFinished: TXcomDebriefingFinished;
begin
  LRuleset := TXcomStrategy.Ruleset(FHost);
  LSave := TXcomStrategy.SavedGame(FHost);
  if (not Assigned(FRules)) or (FRulesetOfRules <> LRuleset) then
  begin
    FRules.Free;
    FRules := TXcomRulesetRules.Create(LRuleset);
    FRulesetOfRules := LRuleset;
  end;
  LReport := TXcomDebriefing.Run(LSave, ABattle, LRuleset, FRules, FOptions, FZombieConverter);
  // the closure runs when the player says OK, maybe after this object is gone: it keeps copies, not Self. By then
  // LState is the screen (still alive: a popped state is freed on the next turn of the game), and its palette is
  // the one that the messages take
  LHost := FHost;
  LLimits := FOptions.StorageLimitsEnforced;
  LMainMenu := FMainMenu;
  LOnFinished := FOnFinished;
  LState := TXcomDebriefingState.Create(LHost, LReport,
    procedure(const AReport: TXcomDebriefingReport)
    var
      LFollowUp: TXcomDebriefingFollowUp;
    begin
      LFollowUp := TXcomDebriefingFollowUp.Create(LHost, TXcomStrategy.SavedGame(LHost),
        TXcomStrategy.Ruleset(LHost), LLimits, LMainMenu);
      try
        LFollowUp.Push(AReport, LState.Palette);
      finally
        LFollowUp.Free;
      end;
      if Assigned(LOnFinished) then
        LOnFinished(AReport);
    end, True);
  // DebriefingState::init: the music of a mission that went well, or badly
  if LReport.PositiveScore then
    LState.Music := LRuleset.Settings.GoodDebriefingMusic
  else
    LState.Music := LRuleset.Settings.BadDebriefingMusic;
  Result := LState;
end;

end.
