{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the generator of a battle             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Generator;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleTerrain,
  DelphiDoom.XcomMod.MapScript, DelphiDoom.XcomMod.Texture, DelphiDoom.XcomMod.AlienDeployment,
  DelphiDoom.XcomMod.MapData, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.MissionSite,
  DelphiDoom.XcomSave.AlienBase, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Intf,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Services.Intf,
  DelphiDoom.XcomBattle.LegacyRandom, DelphiDoom.XcomBattle.GeneratorState, DelphiDoom.XcomBattle.MapGenerator,
  DelphiDoom.XcomBattle.UnitDeployer;

type
  /// <summary>
  ///   Makes the battle of a mission (BattlescapeGenerator): the terrain from the deployment or the world
  ///   texture, the map from its script, the objectives, the X-COM units, the aliens, the civilians, the fuel and
  ///   explosion of a UFO, the music and the light. Not ported: nextStage (the second stage of a mission) and
  ///   runInventory (the inventory screen)
  /// </summary>
  TXcomBattlescapeGenerator = class
  strict private
    FState: TXcomGeneratorState;
    FTarget: TXcomTarget;
    FTexture: TXcomTexture;
    FMapGenerator: TXcomMapGenerator;
    FDeployer: TXcomUnitDeployer;
    procedure SetupObjectives(const ADeployment: TXcomAlienDeployment);
    procedure SetDepth(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
    procedure SetMusic(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
    procedure Generate;
  public
    /// <param name="ASave">The empty saved battle that gets the battle; its mission type says what to make</param>
    /// <param name="ALegacyRandom">The C library rand() (srand done by the caller): only the look of the units</param>
    constructor Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame; const AGame: TXcomSavedGame;
      const AContext: IXcomBattleContext; const ATileEngine: IXcomGeneratorTileEngine;
      const ALegacyRandom: TXcomLegacyRandom; AAllowAutoLoadout: Boolean = True);
    destructor Destroy; override;
    /// <summary>setCraft: the X-COM craft in the battle</summary>
    procedure SetCraft(const ACraft: TXcomCraft);
    /// <summary>setUfo</summary>
    procedure SetUfo(const AUfo: TXcomUfo);
    /// <summary>setBase: the X-COM base (a base defense, or a battle without craft)</summary>
    procedure SetBase(const ABase: TXcomBase);
    /// <summary>setMissionSite: the site decides the terrain of its texture</summary>
    procedure SetMissionSite(const ASite: TXcomMissionSite);
    /// <summary>setAlienBase</summary>
    procedure SetAlienBase(const ABase: TXcomAlienBase);
    /// <summary>setWorldTexture: the polygon of the globe where the UFO is; it gives the terrain</summary>
    procedure SetWorldTexture(const ATexture: TXcomTexture);
    /// <summary>setWorldShade: 0 to 15</summary>
    procedure SetWorldShade(AShade: Integer);
    procedure SetAlienRace(const ARace: string);
    procedure SetAlienItemLevel(ALevel: Integer);
    procedure SetTerrain(const ATerrain: TXcomRuleTerrain);
    /// <summary>
    ///   run. Placing a large unit, or a unit next to a friend, asks the pathfinder of the battle whether a step is
    ///   blocked (SavedBattleGame::initUtilities gives it in the C++): a battle that has none gets one for the run
    /// </summary>
    procedure Run;
  end;

implementation

uses
  DelphiDoom.XcomBattle.Pathfinding;

const
  SNoDeployment = 'Alien deployment %s not found.';
  SNoTerrain = 'Map generator encountered an error: No valid terrain found.';
  SScriptNotFound = 'Map generator encountered an error: %s script not found.';
  SNoAliens = 'Map generator encountered an error: no alien units could be placed on the map.';

{ TXcomBattlescapeGenerator }

constructor TXcomBattlescapeGenerator.Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame;
  const AGame: TXcomSavedGame; const AContext: IXcomBattleContext; const ATileEngine: IXcomGeneratorTileEngine;
  const ALegacyRandom: TXcomLegacyRandom; AAllowAutoLoadout: Boolean);
begin
  inherited Create;
  FState := TXcomGeneratorState.Create(ARuleset, ASave, AGame, AContext, ATileEngine, ALegacyRandom,
    AAllowAutoLoadout);
  FMapGenerator := TXcomMapGenerator.Create(FState);
  FDeployer := TXcomUnitDeployer.Create(FState);
end;

destructor TXcomBattlescapeGenerator.Destroy;
begin
  FDeployer.Free;
  FMapGenerator.Free;
  FState.Free;
  inherited Destroy;
end;

procedure TXcomBattlescapeGenerator.SetCraft(const ACraft: TXcomCraft);
begin
  FState.Craft := ACraft;
  ACraft.SetInBattlescape(True);
end;

procedure TXcomBattlescapeGenerator.SetUfo(const AUfo: TXcomUfo);
begin
  FState.Ufo := AUfo;
  AUfo.SetInBattlescape(True);
end;

procedure TXcomBattlescapeGenerator.SetBase(const ABase: TXcomBase);
begin
  FState.Base := ABase;
  ABase.InBattlescape := True;
end;

procedure TXcomBattlescapeGenerator.SetMissionSite(const ASite: TXcomMissionSite);
begin
  FTarget := ASite;
  ASite.InBattlescape := True;
end;

procedure TXcomBattlescapeGenerator.SetAlienBase(const ABase: TXcomAlienBase);
begin
  ABase.InBattlescape := True;
end;

procedure TXcomBattlescapeGenerator.SetWorldTexture(const ATexture: TXcomTexture);
begin
  FTexture := ATexture;
end;

procedure TXcomBattlescapeGenerator.SetWorldShade(AShade: Integer);
begin
  if AShade > 15 then
    AShade := 15;
  if AShade < 0 then
    AShade := 0;
  FState.WorldShade := AShade;
end;

procedure TXcomBattlescapeGenerator.SetAlienRace(const ARace: string);
begin
  FState.AlienRace := ARace;
end;

procedure TXcomBattlescapeGenerator.SetAlienItemLevel(ALevel: Integer);
begin
  FState.AlienItemLevel := ALevel;
end;

procedure TXcomBattlescapeGenerator.SetTerrain(const ATerrain: TXcomRuleTerrain);
begin
  FState.Terrain := ATerrain;
end;

procedure TXcomBattlescapeGenerator.SetupObjectives(const ADeployment: TXcomAlienDeployment);
var
  LTargetType: Integer;
  LObjectives: Integer;
  LActualCount: Integer;
  LIndex: Integer;
  LPart: Integer;
  LTile: TXcomTile;
begin
  LTargetType := ADeployment.ObjectiveType;
  if LTargetType > -1 then
  begin
    LObjectives := ADeployment.ObjectivesRequired;
    LActualCount := 0;
    for LIndex := 0 to FState.Save.MapSizeXyz - 1 do
    begin
      LTile := FState.Save.TileByIndex(LIndex);
      for LPart := XCOM_PART_FLOOR to XCOM_PART_OBJECT do
        if Assigned(LTile.MapData[LPart]) and (LTile.MapData[LPart].SpecialType = LTargetType) then
          Inc(LActualCount);
    end;
    if LActualCount > 0 then
    begin
      FState.Save.ObjectiveType := LTargetType;
      if (LActualCount < LObjectives) or (LObjectives = 0) then
        FState.Save.SetObjectiveCount(LActualCount)
      else
        FState.Save.SetObjectiveCount(LObjectives);
    end;
  end;
end;

procedure TXcomBattlescapeGenerator.SetDepth(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
begin
  if (FState.Save.Depth > 0) and (not ANextStage) then
    Exit;
  if ADeployment.MaxDepth > 0 then
    FState.Save.Depth := FState.Random.Generate(ADeployment.MinDepth, ADeployment.MaxDepth)
  else if (FState.Terrain.MaxDepth > 0) or ANextStage then
    FState.Save.Depth := FState.Random.Generate(FState.Terrain.MinDepth, FState.Terrain.MaxDepth);
end;

procedure TXcomBattlescapeGenerator.SetMusic(const ADeployment: TXcomAlienDeployment; ANextStage: Boolean);
begin
  if Length(ADeployment.Music) > 0 then
    FState.Save.Music := ADeployment.Music[FState.Random.Generate(0, Length(ADeployment.Music) - 1)]
  else if Length(FState.Terrain.Music) > 0 then
    FState.Save.Music := FState.Terrain.Music[FState.Random.Generate(0, Length(FState.Terrain.Music) - 1)]
  else if ANextStage then
    FState.Save.Music := '';
end;

procedure TXcomBattlescapeGenerator.Run;
var
  LPathfinder: IXcomBattlePathfinder;
begin
  if Assigned(FState.Save.Pathfinder) then
  begin
    Generate;
    Exit;
  end;
  // the blocked steps do not read the nodes of the pathfinder: it can be made before the map has its size
  LPathfinder := TXcomPathfinding.Create(FState.Save);
  FState.Save.Pathfinder := LPathfinder;
  try
    Generate;
  finally
    FState.Save.Pathfinder := nil;
  end;
end;

procedure TXcomBattlescapeGenerator.Generate;
var
  LDeployment: TXcomAlienDeployment;
  LName: string;
  LTerrainName: string;
  LPick: Integer;
  LTarget: TXcomTarget;
  LScript: TObjectList<TXcomMapScript>;
  LUnitCount: Integer;
begin
  if Assigned(FState.Ufo) then
    LName := FState.Ufo.Rules.UfoType
  else
    LName := FState.Save.MissionType;
  LDeployment := FState.Ruleset.AlienDeployments.Find(LName);
  if not Assigned(LDeployment) then
    raise EXcomBattleException.CreateFmt(SNoDeployment, [LName]);
  FState.Save.TurnLimit := LDeployment.TurnLimit;
  FState.Save.ChronoTrigger := LDeployment.ChronoTrigger;
  FState.Save.CheatTurn := LDeployment.CheatTurn;
  FState.MapSizeX := LDeployment.Width;
  FState.MapSizeY := LDeployment.MapLength;
  FState.MapSizeZ := LDeployment.Height;
  FState.UnitSequence := MAX_SOLDIER_ID;
  if not Assigned(FState.Terrain) then
  begin
    if (not Assigned(FTexture)) or (Length(FTexture.Terrain) = 0) or (Length(LDeployment.Terrains) > 0) then
    begin
      if Length(LDeployment.Terrains) > 0 then
      begin
        LPick := FState.Random.Generate(0, Length(LDeployment.Terrains) - 1);
        FState.Terrain := FState.Ruleset.Terrains.Find(LDeployment.Terrains[LPick]);
      end
      else
        FState.Terrain := FState.Ruleset.Terrains.Find(FState.Ruleset.Terrains.Index[0]);
    end
    else
    begin
      LTarget := FState.Ufo;
      if Assigned(FTarget) then
        LTarget := FTarget;
      LTerrainName := FTexture.GetRandomTerrain(LTarget.Longitude, LTarget.Latitude, FState.Random);
      FState.Terrain := FState.Ruleset.Terrains.Find(LTerrainName);
    end;
  end;
  if not Assigned(FState.Terrain) then
    raise EXcomBattleException.Create(SNoTerrain);
  SetDepth(LDeployment, False);
  if LDeployment.Shade <> -1 then
    FState.WorldShade := LDeployment.Shade;
  if not FState.Ruleset.MapScripts.TryGetValue(FState.Terrain.Script, LScript) then
    LScript := nil;
  if FState.Ruleset.MapScripts.ContainsKey(LDeployment.Script) then
    FState.Ruleset.MapScripts.TryGetValue(LDeployment.Script, LScript)
  else if LDeployment.Script <> '' then
    raise EXcomBattleException.CreateFmt(SScriptNotFound, [LDeployment.Script]);
  if not Assigned(LScript) then
    raise EXcomBattleException.CreateFmt(SScriptNotFound, [FState.Terrain.Script]);
  FMapGenerator.Generate(LScript);
  SetupObjectives(LDeployment);
  FDeployer.DeployXcom;
  LUnitCount := FState.Save.Units.Count;
  FDeployer.DeployAliens(LDeployment);
  if LUnitCount = FState.Save.Units.Count then
    raise EXcomBattleException.Create(SNoAliens);
  FDeployer.DeployCivilians(LDeployment.Civilians);
  if FState.GenerateFuel then
    FDeployer.FuelPowerSources;
  if Assigned(FState.Ufo) and (FState.Ufo.Status = TXcomUfo.STATUS_CRASHED) then
    FDeployer.ExplodePowerSources;
  SetMusic(LDeployment, False);
  FState.Save.GlobalShade := FState.WorldShade;
  FState.TileEngine.CalculateSunShading;
  FState.TileEngine.CalculateTerrainLighting;
  FState.TileEngine.CalculateUnitLighting;
end;

end.
