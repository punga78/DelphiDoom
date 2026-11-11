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
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Base,
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
    procedure Generate(const ARequest: TXcomMissionRequest);
    function Describe(const AError: Exception): string;
  public
    constructor Create(AHost: TXcomStateHost; const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio);
    procedure BeginMission(const ARequest: TXcomMissionRequest);
    /// <summary>
    ///   BriefingState::btnOkClick: the battlescape of the session, the screen of the first turn and the inventory
    ///   (or, with no alien alive, the message of the crash and the debriefing). Also for the next stage of a mission
    /// </summary>
    class procedure StartBattle(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
      const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio); static;
  end;

implementation

uses
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Services.Intf, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.TileEngine,
  DelphiDoom.XcomBattle.Pathfinding,
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

function TXcomMissionLauncher.Describe(const AError: Exception): string;
begin
  Result := AError.Message;
  // a defect of the program, not a mission that the rules cannot make: the address in the terms of the .map of the
  // executable (the image can be relocated) says where
  if (AError is EAccessViolation) and (ExceptAddr <> nil) then
    Result := Result + ' [map ' + IntToHex(NativeUInt(ExceptAddr) - NativeUInt(HInstance) + $400000, 8) + ']';
end;

procedure TXcomMissionLauncher.BeginMission(const ARequest: TXcomMissionRequest);
begin
  try
    Generate(ARequest);
  except
    // a mission that cannot be generated must not end the game: the player reads why
    on E: Exception do
      FHost.PushState(TXcomErrorMessageState.ForOrigin(FHost, ooGeoscape, Describe(E),
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
  LBase: TXcomBase;
  LPathfinder: IXcomBattlePathfinder;
  LHost: TXcomStateHost;
  LScreens: IXcomBattleScreens;
  LAudio: IXcomBattleAudio;
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
    // SavedBattleGame::setUnitPosition asks the pathfinding whether a large unit fits: without one, a battle with
    // a 2x2 unit (a tank, a large alien) was an access violation. The session makes its own afterwards too
    LPathfinder := TXcomPathfinding.Create(LBattle);
    LBattle.Pathfinder := LPathfinder;
    // the colors of the units come from the rand() of the C library: any seed does
    LLegacy := TXcomLegacyRandom.Create(Cardinal(FHost.Clock.Ticks));
    try
      LGenerator := TXcomBattlescapeGenerator.Create(LRuleset, LBattle, LSave, LContext, LEngine, LLegacy);
      try
        if ARequest.WorldTexture >= 0 then
          LGenerator.SetWorldTexture(LRuleset.Globe.GetTexture(ARequest.WorldTexture));
        LGenerator.SetWorldShade(ARequest.WorldShade);
        if Assigned(ARequest.Craft) then
          LGenerator.SetCraft(ARequest.Craft);
        if Assigned(ARequest.Base) then
          LGenerator.SetBase(ARequest.Base);
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
    LBattle.Pathfinder := nil;
    LPathfinder := nil;
  except
    LBattle.Free;
    raise;
  end;
  // the session owns the battle from here
  LSession := TXcomBattleFactory.CreateSession(FHost, LBattle, LContext, LGraphics);
  LSession.StoreInSavedGame;
  LCraft := ARequest.Craft;
  LBase := ARequest.Base;
  // the briefing can outlive the launcher: its closure keeps what it needs, not Self
  LHost := FHost;
  LScreens := FScreens;
  LAudio := FAudio;
  FHost.PushState(TXcomBriefingState.Create(FHost, LRuleset, ARequest.MissionType, LCraft, LBase,
    procedure
    begin
      StartBattle(LHost, LSession, LScreens, LAudio);
    end));
end;

class procedure TXcomMissionLauncher.StartBattle(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
  const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio);
var
  LBattlescape: TXcomBattlescapeState;
  LLiveAliens: Integer;
  LLiveSoldiers: Integer;
  LDebriefing: TXcomState;
  LNext: TXcomState;
begin
  LBattlescape := TXcomBattleFactory.CreateBattlescape(AHost, ASession, AScreens, AAudio) as TXcomBattlescapeState;
  LBattlescape.Game.TallyUnits(LLiveAliens, LLiveSoldiers);
  if LLiveAliens > 0 then
  begin
    AHost.PushState(LBattlescape);
    if Assigned(AScreens) then
    begin
      LNext := AScreens.NextTurn(LBattlescape);
      if Assigned(LNext) then
        AHost.PushState(LNext);
      // the soldiers are equipped before the first turn, without spending time units
      LNext := AScreens.Inventory(LBattlescape, False);
      if Assigned(LNext) then
        AHost.PushState(LNext);
    end;
  end
  else
  begin
    // the debriefing reads the battle now: the battlescape (and with it the battle) is freed right after
    LDebriefing := nil;
    if Assigned(AScreens) then
      LDebriefing := AScreens.Debriefing(LBattlescape);
    LBattlescape.Free;
    AHost.PushState(TXcomAliensCrashState.Create(AHost, ASession.Graphics.Surface('TAC00.SCR'),
      procedure
      begin
        if Assigned(LDebriefing) then
          AHost.PushState(LDebriefing);
      end));
  end;
end;

end.
