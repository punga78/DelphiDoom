{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - a battle in progress with its  }
{  engines (SavedBattleGame::initUtilities and what BattlescapeState makes)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.Session;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Services.Intf, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding, DelphiDoom.XcomBattle.View.Intf,
  DelphiDoom.XcomBattle.Options, DelphiDoom.XcomBattle.BattlescapeGame, DelphiDoom.XcomBattle.AIThinker,
  DelphiDoom.XcomBattleStates.Graphics.Intf, DelphiDoom.XcomBattleStates.Session.Intf;

type
  /// <summary>
  ///   IXcomBattleSession: owns the saved battle it is given, makes the engine of the tiles and the pathfinding and
  ///   ties them to the battle. The saved game, the rules and the pictures are not owned
  /// </summary>
  TXcomBattleSession = class(TInterfacedObject, IXcomBattleSession)
  strict private
    FSavedGame: TXcomSavedGame;
    FBattle: TXcomSavedBattleGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FGraphics: IXcomBattleGraphics;
    FEngine: TXcomTileEngine;
    FEngineRef: IXcomBattleTileEngine;
    FPathfinding: TXcomPathfinding;
    FPathfindingRef: IXcomBattlePathfinder;
    FThinker: TXcomAIThinker;
  public
    /// <param name="ABattle">The battle, loaded or generated, with the data of its map: owned from now on</param>
    /// <param name="AContext">The context the battle was made with (the generator, the damage ranges)</param>
    /// <param name="ALight">
    ///   The end of SavedBattleGame::loadMapResources: the light and the field of view are computed (a battle just
    ///   loaded from a file; the generator has already done it for a new one)
    /// </param>
    constructor Create(ASavedGame: TXcomSavedGame; ABattle: TXcomSavedBattleGame; ARuleset: TXcomRuleset;
      const ARandom: IXcomRandom; const AContext: IXcomBattleContext; const AGraphics: IXcomBattleGraphics;
      ALight: Boolean);
    destructor Destroy; override;
    function Battle: TXcomSavedBattleGame;
    function TileEngine: TXcomTileEngine;
    function Pathfinding: TXcomPathfinding;
    function Ruleset: TXcomRuleset;
    function Random: IXcomRandom;
    function Graphics: IXcomBattleGraphics;
    function SavedGame: TXcomSavedGame;
    function CreateGame(const AView: IXcomBattleView; const AOptions: TXcomBattleOptions): TXcomBattlescapeGame;
    procedure StoreInSavedGame;
  end;

implementation

uses
  DelphiDoom.XcomBattle.ReactionFire, DelphiDoom.XcomBattle.SaveLink;

constructor TXcomBattleSession.Create(ASavedGame: TXcomSavedGame; ABattle: TXcomSavedBattleGame;
  ARuleset: TXcomRuleset; const ARandom: IXcomRandom; const AContext: IXcomBattleContext;
  const AGraphics: IXcomBattleGraphics; ALight: Boolean);
var
  LConfig: TXcomAIConfig;
begin
  inherited Create;
  FSavedGame := ASavedGame;
  FBattle := ABattle;
  FRuleset := ARuleset;
  FRandom := ARandom;
  FGraphics := AGraphics;
  FEngine := TXcomTileEngine.Create(ABattle, AContext, AGraphics.VoxelData);
  FEngineRef := FEngine;
  FBattle.TileEngine := FEngineRef;
  FPathfinding := TXcomPathfinding.Create(ABattle);
  FPathfindingRef := FPathfinding;
  FBattle.Pathfinder := FPathfindingRef;
  if ALight then
  begin
    FEngine.CalculateSunShading;
    FEngine.CalculateTerrainLighting;
    FEngine.CalculateUnitLighting;
    FEngine.RecalculateFov;
  end;
  LConfig.DifficultyCoefficient := ARuleset.Settings.DifficultyCoefficient[ASavedGame.Difficulty];
  LConfig.TurnUseGrenade := ARuleset.Settings.TurnAIUseGrenade;
  LConfig.TurnUseBlaster := ARuleset.Settings.TurnAIUseBlaster;
  LConfig.ExplosionHeight := 0;
  FThinker := TXcomAIThinker.Create(ABattle, FEngine, FPathfinding, LConfig);
end;

destructor TXcomBattleSession.Destroy;
begin
  FThinker.Free;
  // the battle refers to its engines: it lets them go first
  if Assigned(FBattle) then
  begin
    FBattle.TileEngine := nil;
    FBattle.Pathfinder := nil;
  end;
  FPathfindingRef := nil;
  FEngineRef := nil;
  FBattle.Free;
  inherited Destroy;
end;

function TXcomBattleSession.Battle: TXcomSavedBattleGame;
begin
  Result := FBattle;
end;

function TXcomBattleSession.TileEngine: TXcomTileEngine;
begin
  Result := FEngine;
end;

function TXcomBattleSession.Pathfinding: TXcomPathfinding;
begin
  Result := FPathfinding;
end;

function TXcomBattleSession.Ruleset: TXcomRuleset;
begin
  Result := FRuleset;
end;

function TXcomBattleSession.Random: IXcomRandom;
begin
  Result := FRandom;
end;

function TXcomBattleSession.Graphics: IXcomBattleGraphics;
begin
  Result := FGraphics;
end;

function TXcomBattleSession.SavedGame: TXcomSavedGame;
begin
  Result := FSavedGame;
end;

function TXcomBattleSession.CreateGame(const AView: IXcomBattleView;
  const AOptions: TXcomBattleOptions): TXcomBattlescapeGame;
var
  LNames: TArray<string>;
  LIndex: Integer;
begin
  Result := TXcomBattlescapeGame.Create(FBattle, FEngine, FPathfinding, FRuleset, AOptions, AView,
    FSavedGame.Difficulty);
  try
    SetLength(LNames, FSavedGame.Discovered.Count);
    for LIndex := 0 to FSavedGame.Discovered.Count - 1 do
      LNames[LIndex] := FSavedGame.Discovered[LIndex].Name;
    Result.ReactionFire := TXcomReactionFire.Create(Result, FThinker, TXcomReactionFire.ResearchOf(LNames));
    Result.MissionCount := FSavedGame.MissionStatistics.Count;
    Result.AIThinker := FThinker;
  except
    Result.Free;
    raise;
  end;
end;

procedure TXcomBattleSession.StoreInSavedGame;
begin
  TXcomBattleSaveLink.StoreBattle(FSavedGame, FBattle);
end;

end.
