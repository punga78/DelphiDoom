{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the next stage of a mission    }
{  in more parts (the branch of BattlescapeState::finishBattle that calls       }
{  BattlescapeGenerator::nextStage and pushes the briefing again)               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.StageLauncher;

interface

uses
  DelphiDoom.XcomEngine.Ticks,
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattleStates.Screens.Intf;

type
  /// <summary>
  ///   What happens when a battle ends and its deployment has a next stage: with soldiers on the exit (after an
  ///   abort) or alive (after a victory) the same saved battle gets the map and the aliens of the next stage and the
  ///   briefing shows again; the debriefing comes only at the end of the last stage. Nothing is kept: the host, the
  ///   battlescape that is closing and the audio are the caller's
  /// </summary>
  TXcomStageLauncher = class
  strict private
    class function UnitsInExit(const ABattle: TXcomSavedBattleGame): Integer; static;
    class procedure Generate(AHost: TXcomStateHost; const ABattle: TXcomSavedBattleGame); static;
  public
    /// <summary>
    ///   The deployment of the battle (by its mission type, or by the UFO of the saved game that is in the
    ///   battlescape) names a next stage: its type, else ''
    /// </summary>
    class function NextStageOf(const ARuleset: TXcomRuleset; const ASavedGame: TXcomSavedGame;
      const ABattle: TXcomSavedBattleGame): string; static;
    /// <summary>
    ///   Called while the battlescape AParent finishes its battle (before it is popped). Nil: the mission is over and
    ///   the debriefing follows. Else the battle has become its next stage, in a new session that the returned
    ///   briefing keeps; OK of the briefing starts the battlescape with the screens of AParent and AAudio.
    ///   Declared difference: the number of soldiers that finishBattle receives is worked out here (on the exit
    ///   after an abort, alive otherwise), so a turn limit that forces a defeat still goes on to the next stage if
    ///   soldiers stand on the exit
    /// </summary>
    class function TryNextStage(AHost: TXcomStateHost; AParent: TXcomState; const AAudio: IXcomBattleAudio)
      : TXcomState; static;
    /// <summary>
    ///   The number that finishBattle receives, worked out from the battle of the battlescape AParent: the soldiers
    ///   on the exit after an abort, the ones alive otherwise
    /// </summary>
    class function SoldiersLeft(AParent: TXcomState): Integer; static;
    /// <summary>
    ///   The cutscene of the deployment that follows the end of the mission (abortCutscene after an abort,
    ///   loseCutscene with no soldier left, winCutscene otherwise); '' when there is none
    /// </summary>
    class function EndCutsceneOf(const ARuleset: TXcomRuleset; const ASavedGame: TXcomSavedGame;
      const ABattle: TXcomSavedBattleGame; ASoldiersLeft: Integer): string; static;
  end;

implementation

uses
  DelphiDoom.XcomMod.AlienDeployment, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf,
  DelphiDoom.XcomBattle.Services.Intf, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.TileEngine,
  DelphiDoom.XcomBattle.Generator, DelphiDoom.XcomBattle.LegacyRandom,
  DelphiDoom.XcomBattleStates.Graphics.Intf, DelphiDoom.XcomBattleStates.Session.Intf,
  DelphiDoom.XcomBattleStates.Session, DelphiDoom.XcomBattleStates.Factory,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.XcomBattleStates.BriefingState,
  DelphiDoom.XcomBattleStates.MissionLauncher;

const
  /// <summary>SpecialTileType END_POINT</summary>
  END_POINT = 13;

{ TXcomStageLauncher }

class function TXcomStageLauncher.NextStageOf(const ARuleset: TXcomRuleset; const ASavedGame: TXcomSavedGame;
  const ABattle: TXcomSavedBattleGame): string;
var
  LDeployment: TXcomAlienDeployment;
  LUfo: TXcomUfo;
begin
  Result := '';
  LDeployment := ARuleset.AlienDeployments.Find(ABattle.MissionType);
  if not Assigned(LDeployment) then
    for LUfo in ASavedGame.Ufos do
      if LUfo.InBattlescape then
      begin
        LDeployment := ARuleset.AlienDeployments.Find(LUfo.Rules.UfoType);
        Break;
      end;
  if Assigned(LDeployment) then
    Result := LDeployment.NextStage;
end;

class function TXcomStageLauncher.SoldiersLeft(AParent: TXcomState): Integer;
var
  LBattlescape: TXcomBattlescapeState;
  LLiveAliens: Integer;
begin
  LBattlescape := AParent as TXcomBattlescapeState;
  if LBattlescape.Session.Battle.Aborted then
    Result := UnitsInExit(LBattlescape.Session.Battle)
  else
    LBattlescape.Game.TallyUnits(LLiveAliens, Result);
end;

class function TXcomStageLauncher.EndCutsceneOf(const ARuleset: TXcomRuleset; const ASavedGame: TXcomSavedGame;
  const ABattle: TXcomSavedBattleGame; ASoldiersLeft: Integer): string;
var
  LDeployment: TXcomAlienDeployment;
  LUfo: TXcomUfo;
begin
  Result := '';
  LDeployment := ARuleset.AlienDeployments.Find(ABattle.MissionType);
  if not Assigned(LDeployment) then
    for LUfo in ASavedGame.Ufos do
      if LUfo.InBattlescape then
      begin
        LDeployment := ARuleset.AlienDeployments.Find(LUfo.Rules.UfoType);
        Break;
      end;
  if not Assigned(LDeployment) then
    Exit;
  if ABattle.Aborted then
    Result := LDeployment.AbortCutscene
  else if ASoldiersLeft = 0 then
    Result := LDeployment.LoseCutscene
  else
    Result := LDeployment.WinCutscene;
end;

class function TXcomStageLauncher.UnitsInExit(const ABattle: TXcomSavedBattleGame): Integer;
var
  LUnit: TXcomBattleUnit;
  LTile: TXcomTile;
  LFloor: TXcomMapData;
begin
  // AbortMissionState: the units of the player that stand on the exit
  Result := 0;
  for LUnit in ABattle.Units do
  begin
    if (LUnit.OriginalFaction <> FACTION_PLAYER) or (LUnit.Status = STATUS_DEAD) or
      (LUnit.Status = STATUS_IGNORE_ME) then
      Continue;
    LTile := ABattle.TileAt(LUnit.Position);
    if not Assigned(LTile) then
      Continue;
    LFloor := LTile.MapData[XCOM_PART_FLOOR];
    if Assigned(LFloor) and (LFloor.SpecialType = END_POINT) then
      Inc(Result);
  end;
end;

class procedure TXcomStageLauncher.Generate(AHost: TXcomStateHost; const ABattle: TXcomSavedBattleGame);
var
  LGraphics: IXcomBattleGraphics;
  LEngine: IXcomGeneratorTileEngine;
  LEngineRef: IXcomBattleTileEngine;
  LLegacy: TXcomLegacyRandom;
  LGenerator: TXcomBattlescapeGenerator;
  LTileEngine: TXcomTileEngine;
begin
  LGraphics := TXcomBattleFactory.CreateGraphics(AHost);
  // the engine of the generator (which makes its own pathfinding for the stage): the session makes its own once
  // the new map has its size
  LTileEngine := TXcomTileEngine.Create(ABattle, ABattle.Context, LGraphics.VoxelData);
  LEngine := LTileEngine;
  LEngineRef := LTileEngine;
  ABattle.TileEngine := LEngineRef;
  try
    LLegacy := TXcomLegacyRandom.Create(Cardinal(TXcomTicks.Now(AHost.Clock)));
    try
      LGenerator := TXcomBattlescapeGenerator.Create(TXcomStrategy.Ruleset(AHost), ABattle,
        TXcomStrategy.SavedGame(AHost), ABattle.Context, LEngine, LLegacy);
      try
        LGenerator.NextStage;
      finally
        LGenerator.Free;
      end;
    finally
      LLegacy.Free;
    end;
  finally
    ABattle.TileEngine := nil;
  end;
end;

class function TXcomStageLauncher.TryNextStage(AHost: TXcomStateHost; AParent: TXcomState;
  const AAudio: IXcomBattleAudio): TXcomState;
var
  LBattlescape: TXcomBattlescapeState;
  LBattle: TXcomSavedBattleGame;
  LNextStage: string;
  LInExit: Integer;
  LSession: IXcomBattleSession;
  LScreens: IXcomBattleScreens;
  LAudio: IXcomBattleAudio;
begin
  Result := nil;
  LBattlescape := AParent as TXcomBattlescapeState;
  // only a battle that was fought to its end goes on (not the one that the crash of the UFO ended before it began)
  if not LBattlescape.Finished then
    Exit;
  LBattle := LBattlescape.Session.Battle;
  LNextStage := NextStageOf(TXcomStrategy.Ruleset(AHost), TXcomStrategy.SavedGame(AHost), LBattle);
  if LNextStage = '' then
    Exit;
  LInExit := SoldiersLeft(AParent);
  if LInExit = 0 then
    Exit;
  LBattle.MissionType := LNextStage;
  // a stage that cannot be made is an exception for the caller: the battle then stays with the session of the
  // battlescape that is closing and is freed with it
  Generate(AHost, LBattle);
  // the battle leaves that session and goes on in a new one, with engines for the new map
  LBattle := (LBattlescape.Session as TXcomBattleSession).ReleaseBattle;
  LSession := TXcomBattleFactory.CreateSession(AHost, LBattle, LBattle.Context, LBattlescape.Session.Graphics);
  LSession.StoreInSavedGame;
  LScreens := LBattlescape.Screens;
  LAudio := AAudio;
  // BriefingState(0, 0): neither a craft nor a base, the texts of the deployment of the stage
  Result := TXcomBriefingState.Create(AHost, TXcomStrategy.Ruleset(AHost), LNextStage, nil, nil,
    procedure
    begin
      TXcomMissionLauncher.StartBattle(AHost, LSession, LScreens, LAudio);
    end);
end;

end.
