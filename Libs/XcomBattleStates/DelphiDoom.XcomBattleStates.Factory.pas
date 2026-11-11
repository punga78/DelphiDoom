{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the one place of the library   }
{  that knows its classes: the battle of a saved game and its screen            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Factory;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattleStates.Graphics.Intf, DelphiDoom.XcomBattleStates.Session.Intf,
  DelphiDoom.XcomBattleStates.Screens.Intf, DelphiDoom.XcomBattleStates.Screens;

type
  /// <summary>Assembles the battle of the game of a host (its saved game, its rules, its files)</summary>
  TXcomBattleFactory = class
  public
    /// <summary>The pictures of the battle on the files of the mod of the host</summary>
    class function CreateGraphics(AHost: TXcomStateHost): IXcomBattleGraphics; static;
    /// <summary>The context of a battle of the host: its generator and the damage ranges of its rules</summary>
    class function CreateContext(AHost: TXcomStateHost): IXcomBattleContext; static;
    /// <summary>
    ///   LoadGameState with a battle in the saved game: SavedBattleGame::load, loadMapResources, the engines, the
    ///   light and the field of view. Nil when the saved game of the host has no battle
    /// </summary>
    class function LoadSession(AHost: TXcomStateHost): IXcomBattleSession; static;
    /// <summary>A session around a battle that the generator has just made (owned by the session from now on)</summary>
    class function CreateSession(AHost: TXcomStateHost; ABattle: TXcomSavedBattleGame;
      const AContext: IXcomBattleContext; const AGraphics: IXcomBattleGraphics = nil): IXcomBattleSession; static;
    /// <summary>
    ///   The screens of the battle with the classes of the library and the debriefing of LibsXcomDebriefing on the
    ///   saved game of the host; the pause menu comes from the program (nil: the options button does nothing)
    /// </summary>
    /// <param name="AMainMenu">Makes the main menu that follows the debriefing of a battle outside a campaign; nil: nothing replaces the states</param>
    /// <param name="AAudio">The sounds of the battlescape of the next stage of a mission in more parts (nil: silent)</param>
    class function CreateScreens(AHost: TXcomStateHost; const AOptions: TXcomBattleOptionsScreen = nil;
      const AMainMenu: TFunc<TXcomState> = nil; const AAudio: IXcomBattleAudio = nil): IXcomBattleScreens; static;
    /// <summary>new BattlescapeState: the caller pushes it</summary>
    class function CreateBattlescape(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
      const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio): TXcomState; static;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Rules.Intf, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.SaveLink,
  DelphiDoom.XcomBattlescape.ModSprites, DelphiDoom.XcomBattleStates.Graphics, DelphiDoom.XcomBattleStates.Session,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomGeoscape.TargetNames,
  DelphiDoom.XcomDebriefing.Types, DelphiDoom.XcomDebriefing.Debriefer.Intf, DelphiDoom.XcomDebriefing.Debriefer,
  DelphiDoom.XcomBattleStates.StageLauncher, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomMenu.OptionsTypes;

class function TXcomBattleFactory.CreateGraphics(AHost: TXcomStateHost): IXcomBattleGraphics;
var
  LRules: IXcomGameRules;
begin
  LRules := TXcomStrategy.Rules(AHost);
  Result := TXcomBattleGraphics.Create(LRules.ModFiles, LRules, TXcomModSprites.Create(LRules.ModFiles),
    AHost.Resources.GetPalette('PAL_BATTLESCAPE'));
end;

class function TXcomBattleFactory.CreateContext(AHost: TXcomStateHost): IXcomBattleContext;
var
  LRuleset: TXcomRuleset;
begin
  LRuleset := TXcomStrategy.Ruleset(AHost);
  Result := TXcomBattleContext.Create(TXcomStrategy.Random(AHost), AHost.Options.GetBool('alienBleeding'),
    AHost.Options.GetBool('allowPsionicCapture'), LRuleset.Constants.FireDamageRange[0],
    LRuleset.Constants.FireDamageRange[1], LRuleset.Constants.DamageRange, LRuleset.Constants.ExplosiveDamageRange,
    AHost.Options.GetValue('battleExplosionHeight'));
end;

class function TXcomBattleFactory.LoadSession(AHost: TXcomStateHost): IXcomBattleSession;
var
  LSave: TXcomSavedGame;
  LContext: IXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
  LGraphics: IXcomBattleGraphics;
begin
  Result := nil;
  LSave := TXcomStrategy.SavedGame(AHost);
  if not Assigned(LSave.BattleGame) then
    Exit;
  LContext := CreateContext(AHost);
  // the pictures first: once the battle exists nothing may fail before the session owns it
  LGraphics := CreateGraphics(AHost);
  LBattle := TXcomBattleSaveLink.LoadBattle(LSave, TXcomStrategy.Ruleset(AHost), LContext);
  if not Assigned(LBattle) then
    Exit;
  Result := TXcomBattleSession.Create(LSave, LBattle, TXcomStrategy.Ruleset(AHost), TXcomStrategy.Random(AHost),
    LContext, LGraphics, True);
end;

class function TXcomBattleFactory.CreateSession(AHost: TXcomStateHost; ABattle: TXcomSavedBattleGame;
  const AContext: IXcomBattleContext; const AGraphics: IXcomBattleGraphics): IXcomBattleSession;
var
  LGraphics: IXcomBattleGraphics;
begin
  LGraphics := AGraphics;
  if not Assigned(LGraphics) then
    LGraphics := CreateGraphics(AHost);
  Result := TXcomBattleSession.Create(TXcomStrategy.SavedGame(AHost), ABattle, TXcomStrategy.Ruleset(AHost),
    TXcomStrategy.Random(AHost), AContext, LGraphics, False);
end;

class function TXcomBattleFactory.CreateScreens(AHost: TXcomStateHost;
  const AOptions: TXcomBattleOptionsScreen; const AMainMenu: TFunc<TXcomState>;
  const AAudio: IXcomBattleAudio): IXcomBattleScreens;
begin
  Result := TXcomBattleScreens.Create(
    function(AParent: TXcomState): TXcomState
    var
      LDebriefer: IXcomMissionDebriefer;
      LOptions: TXcomDebriefingOptions;
    begin
      // BattlescapeState::finishBattle: a mission in more parts goes on with its next stage, and the debriefing
      // comes at the end of the last one
      try
        Result := TXcomStageLauncher.TryNextStage(AHost, AParent, AAudio);
      except
        on E: Exception do
        begin
          // the battle cannot go on and cannot be debriefed (its map is gone): the player reads why
          TXcomStrategy.SavedGame(AHost).BattleGame := nil;
          Exit(TXcomErrorMessageState.ForOrigin(AHost, ooGeoscape, E.Message,
            PXcomColors(AHost.Resources.GetPalette('PAL_GEOSCAPE'))));
        end;
      end;
      if Assigned(Result) then
        Exit;
      // the options of the game as they are when the battle ends (the player can change them in the pause menu)
      LOptions := TXcomDebriefingOptions.Default;
      LOptions.StorageLimitsEnforced := AHost.Options.GetBool('storageLimitsEnforced');
      LOptions.FieldPromotions := AHost.Options.GetBool('fieldPromotions');
      LOptions.PsiStrengthEval := AHost.Options.GetBool('psiStrengthEval');
      LOptions.CraftName :=
        function(ACraft: TXcomCraft): string
        begin
          Result := TXcomTargetNames.Name(ACraft, AHost.Language);
        end;
      // the screen that the debriefer makes keeps what it needs, the debriefer itself can go. After OK the screens
      // of TXcomDebriefingFollowUp follow (medals, promotions, missing items, containment, sale, autosave)
      LDebriefer := TXcomMissionDebriefer.Create(AHost, LOptions, nil, nil, AMainMenu);
      Result := LDebriefer.Debrief((AParent as TXcomBattlescapeState).Session.Battle);
    end, AOptions);
end;

class function TXcomBattleFactory.CreateBattlescape(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
  const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio): TXcomState;
begin
  Result := TXcomBattlescapeState.Create(AHost, ASession, AScreens, AAudio);
end;

end.
