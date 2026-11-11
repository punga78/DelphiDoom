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
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomDebriefing.Types, DelphiDoom.XcomDebriefing.DebriefingState,
  DelphiDoom.XcomDebriefing.Debriefer.Intf;

type
  /// <summary>
  ///   IXcomMissionDebriefer on the saved game and the rules of the host: runs the debriefing and makes the screen; when
  ///   the player says OK and the craft misses items, CannotReequipState follows. The other screens that follow in the C++
  ///   (commendations, promotions, containment, storage, the autosave) are for the host: AOnFinished gets the report
  /// </summary>
  TXcomMissionDebriefer = class(TInterfacedObject, IXcomMissionDebriefer)
  strict private
    FHost: TXcomStateHost;
    FOptions: TXcomDebriefingOptions;
    FOnFinished: TXcomDebriefingFinished;
    FZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>;
    FRules: TXcomRulesetRules;
    FRulesetOfRules: TXcomRuleset;
  public
    /// <param name="AHost">The host of the states (the saved game and the rules come from it)</param>
    /// <param name="AOnFinished">Called when the player closes the debriefing, after the screens of this library; can be nil</param>
    /// <param name="AZombieConverter">SavedBattleGame::convertUnit for a recovered zombie; can be nil</param>
    constructor Create(AHost: TXcomStateHost; const AOptions: TXcomDebriefingOptions;
      const AOnFinished: TXcomDebriefingFinished; const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>);
    destructor Destroy; override;
    function Debrief(const ABattle: TXcomSavedBattleGame): TXcomState;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomDebriefing.Debriefing,
  DelphiDoom.XcomDebriefing.CannotReequipState;

{ TXcomMissionDebriefer }

constructor TXcomMissionDebriefer.Create(AHost: TXcomStateHost; const AOptions: TXcomDebriefingOptions;
  const AOnFinished: TXcomDebriefingFinished; const AZombieConverter: TFunc<TXcomBattleUnit, TXcomBattleUnit>);
begin
  inherited Create;
  FHost := AHost;
  FOptions := AOptions;
  FOnFinished := AOnFinished;
  FZombieConverter := AZombieConverter;
end;

destructor TXcomMissionDebriefer.Destroy;
begin
  FRules.Free;
  inherited Destroy;
end;

function TXcomMissionDebriefer.Debrief(const ABattle: TXcomSavedBattleGame): TXcomState;
var
  LRuleset: TXcomRuleset;
  LReport: TXcomDebriefingReport;
  LHost: TXcomStateHost;
begin
  LRuleset := TXcomStrategy.Ruleset(FHost);
  if (not Assigned(FRules)) or (FRulesetOfRules <> LRuleset) then
  begin
    FRules.Free;
    FRules := TXcomRulesetRules.Create(LRuleset);
    FRulesetOfRules := LRuleset;
  end;
  LReport := TXcomDebriefing.Run(TXcomStrategy.SavedGame(FHost), ABattle, LRuleset, FRules, FOptions, FZombieConverter);
  LHost := FHost;
  Result := TXcomDebriefingState.Create(FHost, LReport,
    procedure(const AReport: TXcomDebriefingReport)
    begin
      if AReport.MissingItems.Count > 0 then
        LHost.PushState(TXcomCannotReequipState.Create(LHost, AReport.MissingItems));
      if Assigned(FOnFinished) then
        FOnFinished(AReport);
    end, True);
end;

end.
