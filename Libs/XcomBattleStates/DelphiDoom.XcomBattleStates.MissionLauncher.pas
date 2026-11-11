{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - from the geoscape to the       }
{  battle: the generator, the briefing and the battlescape                      }
{  (ConfirmLandingState::btnYesClick and BriefingState::btnOkClick)             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.MissionLauncher;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.XcomBattleStates.Session.Intf,
  DelphiDoom.XcomBattleStates.Screens.Intf;

type
  /// <summary>
  ///   IXcomMissionLauncher of the game: makes the battle of the mission with the generator, stores it in the saved
  ///   game and pushes the briefing; OK of the briefing pushes the battlescape, the screen of the first turn and the
  ///   inventory of the soldiers (or "all aliens were killed in the crash" and the debriefing). A battle that the
  ///   generator cannot make is EXcomBattleException for the caller. The host, the screens and the audio are not
  ///   owned
  /// </summary>
  TXcomMissionLauncher = class(TInterfacedObject, IXcomMissionLauncher)
  strict private
    FHost: TXcomStateHost;
    FScreens: IXcomBattleScreens;
    FAudio: IXcomBattleAudio;
    procedure StartBattle(const ASession: IXcomBattleSession);
    procedure Generate(const ARequest: TXcomMissionRequest);
  public
    constructor Create(AHost: TXcomStateHost; const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio);
    procedure BeginMission(const ARequest: TXcomMissionRequest);
  end;

implementation

uses
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Services.Intf, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.TileEngine,
  DelphiDoom.XcomBattle.Generator, DelphiDoom.XcomBattle.LegacyRandom, DelphiDoom.XcomBattleStates.Graphics.Intf,
  DelphiDoom.XcomBattleStates.Factory, DelphiDoom.XcomBattleStates.BattlescapeState,
  DelphiDoom.XcomBattleStates.BriefingState, DelphiDoom.XcomBattleStates.AliensCrashState,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomMenu.OptionsTypes;

constructor TXcomMissionLauncher.Create(AHost: TXcomStateHost; const AScreens: IXcomBattleScreens;
  const AAudio: IXcomBattleAudio);
begin
  inherited Create;
  FHost := AHost;
  FScreens := AScreens;
  FAudio := AAudio;
end;

procedure TXcomMissionLauncher.BeginMission(const ARequest: TXcomMissionRequest);
begin
  try
    Generate(ARequest);
  except
    // a mission that cannot be generated must not end the game: the player reads why
    on E: Exception do
      FHost.PushState(TXcomErrorMessageState.ForOrigin(FHost, ooGeoscape, E.Message,
        PXcomColors(FHost.Resources.GetPalette('PAL_GEOSCAPE'))));
  end;
end;

procedure TXcomMissionLauncher.Generate(const ARequest: TXcomMissionRequest);
var
  LRuleset: TXcomRuleset;
  LSave: TXcomSavedGame;
  LContext: IXcomBattleContext;
  LGraphics: IXcomBattleGraphics;
  LBattle: TXcomSavedBattleGame;
  LEngine: IXcomGeneratorTileEngine;
  LGenerator: TXcomBattlescapeGenerator;
  LLegacy: TXcomLegacyRandom;
  LSession: IXcomBattleSession;
  LCraft: TXcomCraft;
begin
  LRuleset := TXcomStrategy.Ruleset(FHost);
  LSave := TXcomStrategy.SavedGame(FHost);
  LContext := TXcomBattleFactory.CreateContext(FHost);
  LGraphics := TXcomBattleFactory.CreateGraphics(FHost);
  LBattle := TXcomSavedBattleGame.Create(LContext);
  try
    LBattle.MissionType := ARequest.MissionType;
    // the engine of the generator: the session makes its own once the map has its size
    LEngine := TXcomTileEngine.Create(LBattle, LContext, LGraphics.VoxelData);
    // the colors of the units come from the rand() of the C library: any seed does
    LLegacy := TXcomLegacyRandom.Create(Cardinal(FHost.Clock.Ticks));
    try
      LGenerator := TXcomBattlescapeGenerator.Create(LRuleset, LBattle, LSave, LContext, LEngine, LLegacy);
      try
        if ARequest.WorldTexture >= 0 then
          LGenerator.SetWorldTexture(LRuleset.Globe.GetTexture(ARequest.WorldTexture));
        LGenerator.SetWorldShade(ARequest.WorldShade);
        LGenerator.SetCraft(ARequest.Craft);
        if Assigned(ARequest.Ufo) then
          LGenerator.SetUfo(ARequest.Ufo)
        else if Assigned(ARequest.Site) then
          LGenerator.SetMissionSite(ARequest.Site)
        else if Assigned(ARequest.AlienBase) then
          LGenerator.SetAlienBase(ARequest.AlienBase);
        LGenerator.SetAlienRace(ARequest.AlienRace);
        LGenerator.Run;
      finally
        LGenerator.Free;
      end;
    finally
      LLegacy.Free;
    end;
    LBattle.TileEngine := nil;
    LEngine := nil;
  except
    LBattle.Free;
    raise;
  end;
  // the session owns the battle from here
  LSession := TXcomBattleFactory.CreateSession(FHost, LBattle, LContext, LGraphics);
  LSession.StoreInSavedGame;
  LCraft := ARequest.Craft;
  FHost.PushState(TXcomBriefingState.Create(FHost, LRuleset, ARequest.MissionType, LCraft, nil,
    procedure
    begin
      StartBattle(LSession);
    end));
end;

procedure TXcomMissionLauncher.StartBattle(const ASession: IXcomBattleSession);
var
  LBattlescape: TXcomBattlescapeState;
  LLiveAliens: Integer;
  LLiveSoldiers: Integer;
  LDebriefing: TXcomState;
  LHost: TXcomStateHost;
  LNext: TXcomState;
begin
  LHost := FHost;
  LBattlescape := TXcomBattleFactory.CreateBattlescape(FHost, ASession, FScreens, FAudio) as TXcomBattlescapeState;
  LBattlescape.Game.TallyUnits(LLiveAliens, LLiveSoldiers);
  if LLiveAliens > 0 then
  begin
    FHost.PushState(LBattlescape);
    if Assigned(FScreens) then
    begin
      LNext := FScreens.NextTurn(LBattlescape);
      if Assigned(LNext) then
        FHost.PushState(LNext);
      // the soldiers are equipped before the first turn, without spending time units
      LNext := FScreens.Inventory(LBattlescape, False);
      if Assigned(LNext) then
        FHost.PushState(LNext);
    end;
  end
  else
  begin
    // the debriefing reads the battle now: the battlescape (and with it the battle) is freed right after
    LDebriefing := nil;
    if Assigned(FScreens) then
      LDebriefing := FScreens.Debriefing(LBattlescape);
    LBattlescape.Free;
    FHost.PushState(TXcomAliensCrashState.Create(FHost, ASession.Graphics.Surface('TAC00.SCR'),
      procedure
      begin
        if Assigned(LDebriefing) then
          LHost.PushState(LDebriefing);
      end));
  end;
end;

end.
