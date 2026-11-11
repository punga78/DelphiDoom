{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the answers of the  }
{  real Projectile, getOriginVoxel, validateThrow and TileEngine::hit of       }
{  OpenXcom on maps of real MCD parts                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealProjectile;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.MapDataLoader,
  DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.McdPatch, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.TileEngine,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.Projectile, DelphiDoom.XcomBattle.Host.Intf,
  DelphiDoom.XcomBattle.State.Intf, DelphiDoom.XcomBattle.ExplosionState, DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>The part of BattlescapeGame that the calls read, with what the real harness gave it</summary>
  TFakeBattleHost = class(TInterfacedObject, IXcomBattleHost)
  strict private
    FSave: TXcomSavedBattleGame;
    FPanicHandled: Boolean;
    FCurrentActionType: Integer;
    FPushed: TList<IXcomBattleState>;
  public
    constructor Create(const ASave: TXcomSavedBattleGame);
    destructor Destroy; override;
    function PanicHandled: Boolean;
    function CurrentActionType: Integer;
    function ReservedAction: Integer;
    function CheckReservedTu(const AUnit: TXcomBattleUnit; ATimeUnits: Integer; AJustChecking: Boolean = False): Boolean;
    procedure StatePushNext(const AState: IXcomBattleState);
    procedure StatePushFront(const AState: IXcomBattleState);
    procedure StatePushBack(const AState: IXcomBattleState);
    procedure PopState;
    property PanicFlag: Boolean write FPanicHandled;
    property CurrentType: Integer write FCurrentActionType;
    property Pushed: TList<IXcomBattleState> read FPushed;
  end;

  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealProjectile = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FVoxels: TArray<Word>;
    FNextItemId: Integer;
    function DataFolder: string;
    class function FindUp(const ARelative: string; AFolder: Boolean): string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function P3(const APosition: TXcomPosition): string; static;
    class function ObstacleSum(const ABattle: TXcomSavedBattleGame): Cardinal; static;
    class function TrajectoryText(const ATrajectory: TList<TXcomPosition>): string; static;
    class function StateText(const ABattle: TXcomSavedBattleGame): string; static;
    class function FindUnit(const ABattle: TXcomSavedBattleGame; AId: Integer): TXcomBattleUnit; static;
    class function Pos3(const AText: string): TXcomPosition; static;
    function Answer(const ABattle: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
      const AHost: TFakeBattleHost; const AQuestion: string): string;
    function AnswerProjectile(const ABattle: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
      const AHost: TFakeBattleHost; const AParts: TArray<string>; const ALeft: string): string;
    function RunCase(const ABase: string): string;
  protected
    /// <summary>The game of the cases: TFTD (mod xcom2) or UFO (mod xcom1)</summary>
    function IsUfo: Boolean; virtual;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroProjectile;
  end;

  /// <summary>The same comparison on the terrains, the units and the weapons of UFO (projgen on the UFO data)</summary>
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealProjectileUfo = class(TTestXcomRealProjectile)
  protected
    function IsUfo: Boolean; override;
  end;

implementation

uses
  DelphiDoom.Tests.XcomBattle.GameData;

{ TTestXcomRealProjectileUfo }

function TTestXcomRealProjectileUfo.IsUfo: Boolean;
begin
  Result := True;
end;

function TTestXcomRealProjectile.IsUfo: Boolean;
begin
  Result := False;
end;

{ TFakeBattleHost }

constructor TFakeBattleHost.Create(const ASave: TXcomSavedBattleGame);
begin
  inherited Create;
  FSave := ASave;
  FPushed := TList<IXcomBattleState>.Create;
end;

destructor TFakeBattleHost.Destroy;
begin
  FPushed.Free;
  inherited Destroy;
end;

function TFakeBattleHost.PanicHandled: Boolean;
begin
  Result := FPanicHandled;
end;

function TFakeBattleHost.CurrentActionType: Integer;
begin
  Result := FCurrentActionType;
end;

function TFakeBattleHost.ReservedAction: Integer;
begin
  Result := FSave.TuReserved;
end;

function TFakeBattleHost.CheckReservedTu(const AUnit: TXcomBattleUnit; ATimeUnits: Integer;
  AJustChecking: Boolean): Boolean;
begin
  Result := ATimeUnits <= AUnit.TimeUnits;
end;

procedure TFakeBattleHost.StatePushNext(const AState: IXcomBattleState);
begin
  FPushed.Add(AState);
end;

procedure TFakeBattleHost.StatePushFront(const AState: IXcomBattleState);
begin
  FPushed.Insert(0, AState);
end;

procedure TFakeBattleHost.StatePushBack(const AState: IXcomBattleState);
begin
  FPushed.Add(AState);
end;

procedure TFakeBattleHost.PopState;
begin
  if FPushed.Count > 0 then
    FPushed.Delete(0);
end;

{ TTestXcomRealProjectile }

class function TTestXcomRealProjectile.FindUp(const ARelative: string; AFolder: Boolean): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 8 do
  begin
    Result := LFolder + ARelative;
    if (AFolder and DirectoryExists(Result)) or (not AFolder and FileExists(Result)) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

function TTestXcomRealProjectile.DataFolder: string;
var
  LFolder: string;
begin
  LFolder := GetEnvironmentVariable(TXcomTestGame.FolderVariable('DELPHIDOOM_XCOMBATTLE_PROJ', IsUfo));
  if LFolder <> '' then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LFolder := FindUp('Tests\Data\XcomBattle\' + TXcomTestGame.ScenarioFolder('proj', IsUfo), True);
  if LFolder <> '' then
    LFolder := IncludeTrailingPathDelimiter(LFolder);
  Result := LFolder;
end;

class function TTestXcomRealProjectile.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

procedure TTestXcomRealProjectile.SetupFixture;
var
  LPath: string;
  LBytes: TBytes;
  LIndex: Integer;
begin
  FData := TXcomRealData.Create(TXcomTestGame.Golden(IsUfo));
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    LPath := FindUp(TXcomTestGame.Loftemps(IsUfo), False);
    if LPath <> '' then
    begin
      LBytes := TFile.ReadAllBytes(LPath);
      SetLength(FVoxels, Length(LBytes) div 2);
      for LIndex := 0 to High(FVoxels) do
        FVoxels[LIndex] := Word(LBytes[LIndex * 2]) or (Word(LBytes[LIndex * 2 + 1]) shl 8);
    end;
  end;
end;

procedure TTestXcomRealProjectile.TearDownFixture;
begin
  FRuleset.Free;
  FData.Free;
end;

class function TTestXcomRealProjectile.FindUnit(const ABattle: TXcomSavedBattleGame; AId: Integer): TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in ABattle.Units do
    if LUnit.Id = AId then
      Exit(LUnit);
  raise Exception.CreateFmt('Unit %d not in the battle', [AId]);
end;

class function TTestXcomRealProjectile.P3(const APosition: TXcomPosition): string;
begin
  Result := Format('%d/%d/%d', [APosition.X, APosition.Y, APosition.Z]);
end;

class function TTestXcomRealProjectile.Pos3(const AText: string): TXcomPosition;
var
  LParts: TArray<string>;
begin
  LParts := AText.Split(['/']);
  Result := TXcomPosition.Make(StrToInt(LParts[0]), StrToInt(LParts[1]), StrToInt(LParts[2]));
end;

class function TTestXcomRealProjectile.ObstacleSum(const ABattle: TXcomSavedBattleGame): Cardinal;
var
  LIndex: Integer;
  LPart: Integer;
  LBits: Cardinal;
begin
  Result := 0;
  for LIndex := 0 to ABattle.MapSizeXyz - 1 do
  begin
    LBits := 0;
    for LPart := 0 to 31 do
      if ABattle.TileByIndex(LIndex).GetObstacle(LPart) then
        LBits := LBits or (Cardinal(1) shl LPart);
    Result := Result * 31 + LBits;
  end;
end;

class function TTestXcomRealProjectile.TrajectoryText(const ATrajectory: TList<TXcomPosition>): string;
var
  LHash: Cardinal;
  LPoint: TXcomPosition;
begin
  LHash := 17;
  for LPoint in ATrajectory do
    LHash := LHash * 31 + Cardinal(LPoint.X * 7 + LPoint.Y * 13 + LPoint.Z);
  Result := Format('n=%d', [ATrajectory.Count]);
  if ATrajectory.Count > 0 then
    Result := Result + Format(' first=%d/%d/%d last=%d/%d/%d', [ATrajectory.First.X, ATrajectory.First.Y,
      ATrajectory.First.Z, ATrajectory.Last.X, ATrajectory.Last.Y, ATrajectory.Last.Z]);
  Result := Result + Format(' h=%u', [LHash]);
end;

class function TTestXcomRealProjectile.StateText(const ABattle: TXcomSavedBattleGame): string;
var
  LIndex: Integer;
  LPart: Integer;
  LTile: TXcomTile;
  LDataId: Integer;
  LSetId: Integer;
  LValues: array[0..13] of Integer;
  LValue: Integer;
  LHash: Cardinal;
  LUnit: TXcomBattleUnit;
begin
  LHash := 2166136261;
  for LIndex := 0 to ABattle.MapSizeXyz - 1 do
  begin
    LTile := ABattle.TileByIndex(LIndex);
    for LPart := 0 to 3 do
    begin
      LTile.GetMapDataIds(LDataId, LSetId, LPart);
      LValues[LPart] := LDataId;
      LValues[4 + LPart] := LSetId;
    end;
    LValues[8] := LTile.Fire;
    LValues[9] := LTile.Smoke;
    LValues[10] := LTile.Explosive;
    LValues[11] := LTile.ExplosiveType;
    LValues[12] := LTile.Inventory.Count;
    LValues[13] := LTile.Overlaps;
    for LValue in LValues do
      LHash := (LHash xor Cardinal(LValue)) * 16777619;
  end;
  Result := Format('tiles=%u', [LHash]);
  for LUnit in ABattle.Units do
    Result := Result + Format(' u%d:%d,%d,%d,%d%d%d%d%d,%d,%d,%d,%d,%d', [LUnit.Id, LUnit.Health, LUnit.StunLevel,
      LUnit.Morale, LUnit.GetArmor(SIDE_FRONT), LUnit.GetArmor(SIDE_LEFT), LUnit.GetArmor(SIDE_RIGHT),
      LUnit.GetArmor(SIDE_REAR), LUnit.GetArmor(SIDE_UNDER), LUnit.GetFatalWounds, LUnit.Fire, LUnit.Status,
      LUnit.ExpFiring, LUnit.KilledBy]);
end;

function TTestXcomRealProjectile.AnswerProjectile(const ABattle: TXcomSavedBattleGame;
  const AEngine: TXcomTileEngine; const AHost: TFakeBattleHost; const AParts: TArray<string>;
  const ALeft: string): string;
var
  LUnit: TXcomBattleUnit;
  LAction: TXcomBattleAction;
  LWeapon: TXcomBattleItem;
  LAmmo: TXcomBattleItem;
  LProjectile: TXcomProjectile;
  LPrefix: string;
  LMode: Integer;
  LAccuracy: Integer;
  LExclude: Boolean;
  LOriginVoxel: TXcomPosition;
  LTargetVoxel: TXcomPosition;
  LResult: Integer;
  LCount: Integer;
  LIndex: Integer;
  LSteps: Integer;
  LText: string;
  LRules: TXcomRuleItem;
begin
  LUnit := FindUnit(ABattle, StrToInt(AParts[1]));
  if not Assigned(LUnit.Tile) then
    Exit('skip');
  LAction := TXcomBattleAction.Create;
  LAmmo := nil;
  LWeapon := nil;
  try
    LAction.Actor := LUnit;
    LAction.ActionType := StrToInt(AParts[4]);
    LAction.AutoShotCounter := StrToInt(AParts[5]);
    LAction.Target := Pos3(AParts[6]);
    LTargetVoxel := Pos3(AParts[7]);
    LMode := StrToInt(AParts[8]);
    LAccuracy := StrToInt(AParts[9]);
    ABattle.Random.SetSeed(StrToInt(AParts[10]));
    LExclude := AParts[11] = '1';
    LCount := StrToInt(AParts[12]);
    for LIndex := 1 to LCount do
      LAction.Waypoints.Add(TXcomPosition.Make(0, 0, 0));
    LOriginVoxel := Pos3(AParts[14]);
    LRules := FRuleset.Items.Find(AParts[2]);
    LWeapon := TXcomBattleItem.Create(LRules, FNextItemId);
    if AParts[3] = 'self' then
      LAmmo := LWeapon
    else if AParts[3] <> '-' then
    begin
      LAmmo := TXcomBattleItem.Create(FRuleset.Items.Find(AParts[3]), FNextItemId);
      LWeapon.SetAmmoItem(LAmmo);
    end;
    LAction.Weapon := LWeapon;
    for LIndex := 0 to ABattle.MapSizeXyz - 1 do
      ABattle.TileByIndex(LIndex).ResetObstacle;
    LProjectile :=TXcomProjectile.Create(ABattle, AEngine, AHost, TXcomProjectileOptions.Default, LAction,
      LUnit.Position, LTargetVoxel, LAmmo);
    try
      if LMode = 3 then
      begin
        LProjectile.ApplyAccuracy(LOriginVoxel, LTargetVoxel, LAccuracy / 100.0, AParts[15] = '1', AParts[16] = '1');
        Exit(Format('%s = nt=%s rng=%s', [ALeft, P3(LTargetVoxel), UIntToStr(ABattle.Random.Seed)]));
      end;
      if LMode = 0 then
        LResult := LProjectile.CalculateTrajectory(LAccuracy / 100.0)
      else if LMode = 1 then
        LResult := LProjectile.CalculateTrajectory(LAccuracy / 100.0, LOriginVoxel, LExclude)
      else
        LResult := LProjectile.CalculateThrow(LAccuracy / 100.0);
      LPrefix := Format('%s = %d %s rng=%s obst=%u speed=%d tv=%s rev=%d part=%d rangesprite=', [ALeft, LResult,
        TrajectoryText(LProjectile.Trajectory), UIntToStr(ABattle.Random.Seed), ObstacleSum(ABattle),
        LProjectile.Speed, P3(LProjectile.TargetVoxel), Ord(LProjectile.IsReversed), LProjectile.GetParticle(2)]);
      if (LAction.ActionType = BA_THROW) and Assigned(LProjectile.Item) then
        LPrefix := LPrefix + IntToStr(LProjectile.ItemFloorSprite)
      else
        LPrefix := LPrefix + '-9';
      if LProjectile.Trajectory.Count > 0 then
      begin
        LText := Format(' org=%s tgt=%s', [P3(LProjectile.GetOrigin), P3(LProjectile.GetTarget)]);
        LSteps := 0;
        while LProjectile.Move and (LSteps < 5000) do
          Inc(LSteps);
        LText := LText + Format(' steps=%d pos=%s pos-2=%s pos+3=%s rng2=%s', [LSteps, P3(LProjectile.GetPosition(0)),
          P3(LProjectile.GetPosition(-2)), P3(LProjectile.GetPosition(3)), UIntToStr(ABattle.Random.Seed)]);
        LPrefix := LPrefix + LText;
      end;
      Result := LPrefix;
    finally
      LProjectile.Free;
    end;
  finally
    if Assigned(LAmmo) and (LAmmo <> LWeapon) then
      LAmmo.Free;
    LWeapon.Free;
    LAction.Free;
  end;
end;

function TTestXcomRealProjectile.Answer(const ABattle: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
  const AHost: TFakeBattleHost; const AQuestion: string): string;
var
  LParts: TArray<string>;
  LLeft: string;
  LUnit: TXcomBattleUnit;
  LAction: TXcomBattleAction;
  LWeapon: TXcomBattleItem;
  LOrigin: TXcomPosition;
  LTarget: TXcomPosition;
  LOriginVoxel: TXcomPosition;
  LTile: TXcomTile;
  LForced: Boolean;
  LCurve: Double;
  LVoxelType: Integer;
  LValid: Boolean;
  LIndex: Integer;
  LHit: TXcomBattleUnit;
  LExclude: TXcomBattleUnit;
  LText: string;
  LState: IXcomBattleState;
begin
  Result := '';
  LLeft := Copy(AQuestion, 1, Pos(' = ', AQuestion + ' = ') - 1);
  LParts := LLeft.Split([' ']);
  if LParts[0] = 'panic' then
  begin
    AHost.PanicFlag := LParts[1] = '1';
    ABattle.TuReserved := StrToInt(LParts[3]);
    Result := AQuestion;
  end
  else if LParts[0] = 'skip' then
    Result := 'skip'
  else if LParts[0] = 'dir' then
    Result := Format('%s = %d', [LLeft, AEngine.GetDirectionTo(TXcomPosition.Make(StrToInt(LParts[1]),
      StrToInt(LParts[2]), StrToInt(LParts[3])), TXcomPosition.Make(StrToInt(LParts[4]), StrToInt(LParts[5]),
      StrToInt(LParts[6])))])
  else if LParts[0] = 'origin' then
  begin
    LUnit := FindUnit(ABattle, StrToInt(LParts[1]));
    LAction := TXcomBattleAction.Create;
    try
      LAction.Actor := LUnit;
      LAction.ActionType := StrToInt(LParts[2]);
      LAction.Target := Pos3(LParts[3]);
      LTile := ABattle.TileAt(Pos3(LParts[4]));
      Result := Format('%s = %s', [LLeft, P3(AEngine.GetOriginVoxel(LAction, LTile))]);
    finally
      LAction.Free;
    end;
  end
  else if LParts[0] = 'throw' then
  begin
    LUnit := FindUnit(ABattle, StrToInt(LParts[1]));
    LAction := TXcomBattleAction.Create;
    LWeapon := TXcomBattleItem.Create(FRuleset.Items.Find(LParts[2]), FNextItemId);
    try
      LAction.Actor := LUnit;
      LAction.ActionType := StrToInt(LParts[3]);
      LAction.Target := Pos3(LParts[4]);
      LAction.Weapon := LWeapon;
      LOriginVoxel := Pos3(LParts[5]);
      LTarget := Pos3(LParts[6]);
      LForced := LParts[7] = '1';
      LCurve := -1.0;
      LVoxelType := -2;
      for LIndex := 0 to ABattle.MapSizeXyz - 1 do
        ABattle.TileByIndex(LIndex).ResetObstacle;
      LValid := AEngine.ValidateThrow(LAction, LOriginVoxel, LTarget, LCurve, LVoxelType, LForced);
      Result := Format('%s = %d %s %d obst=%u', [LLeft, Ord(LValid), FormatFloat('0.000000000', LCurve, TFormatSettings.Invariant), LVoxelType,
        ObstacleSum(ABattle)]);
    finally
      LWeapon.Free;
      LAction.Free;
    end;
  end
  else if LParts[0] = 'proj' then
    Result := AnswerProjectile(ABattle, AEngine, AHost, LParts, LLeft)
  else if LParts[0] = 'hit' then
  begin
    LOrigin := Pos3(LParts[1]);
    LExclude := nil;
    if StrToInt(LParts[4]) <> 0 then
      LExclude := FindUnit(ABattle, StrToInt(LParts[4]));
    ABattle.Random.SetSeed(StrToInt(LParts[5]));
    AHost.CurrentType := StrToInt(LParts[6]);
    AHost.Pushed.Clear;
    LHit := AEngine.Hit(LOrigin, StrToInt(LParts[3]), StrToInt(LParts[2]), LExclude);
    if Assigned(LHit) then
      LText := IntToStr(LHit.Id)
    else
      LText := '0';
    Result := Format('%s = u%s rng=%s obj=%d pushed=%d', [LLeft, LText, UIntToStr(ABattle.Random.Seed),
      ABattle.ObjectivesDestroyed, AHost.Pushed.Count]);
    for LState in AHost.Pushed do
      if LState is TXcomExplosionState then
        Result := Result + ' explosion@' + P3(TXcomExplosionState(LState).Center);
    Result := Result + ' ' + StateText(ABattle);
  end;
end;

function TTestXcomRealProjectile.RunCase(const ABase: string): string;
var
  LBattle: TXcomSavedBattleGame;
  LContext: TXcomBattleContext;
  LLoader: TXcomMapDataLoader;
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
  LEngine: TXcomTileEngine;
  LEngineRef: IInterface;
  LHost: TFakeBattleHost;
  LHostRef: IXcomBattleHost;
  LLines: TStringList;
  LLine: string;
  LActual: string;
  LFailed: string;
  LFailures: Integer;
begin
  LFailed := '';
  LFailures := 0;
  FNextItemId := 90000;
  LContext := TXcomBattleContext.Create(TXcomRandom.Create(1), False, False, FRuleset.Constants.FireDamageRange[0],
    FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange, 0);
  LBattle := TXcomSavedBattleGame.Create(LContext);
  LLines := TStringList.Create;
  LEngine := nil;
  try
    LBattle.Load(TYamlFactory.CreateParser.Load(ReadText(ABase + '.yml')), FRuleset, 0,
      function(AId: Integer): TXcomSoldier
      begin
        Result := nil;
      end);
    LLoader := TXcomMapDataLoader.Create(FRuleset.Files);
    try
      for LSet in LBattle.MapDataSets do
      begin
        if not FRuleset.McdPatches.TryGetValue(LSet.Name, LPatch) then
          LPatch := nil;
        LLoader.LoadData(LSet, LPatch);
      end;
    finally
      LLoader.Free;
    end;
    LBattle.ResolveMapData;
    LBattle.Depth := 0;
    LEngine := TXcomTileEngine.Create(LBattle, LContext, FVoxels);
    LEngineRef := LEngine;
    LBattle.TileEngine := LEngine;
    LHost := TFakeBattleHost.Create(LBattle);
    LHostRef := LHost;
    LEngine.Host := LHostRef;
    LLines.LoadFromFile(ABase + '.txt', TEncoding.UTF8);
    for LLine in LLines do
    begin
      if LLine = '' then
        Continue;
      try
        LActual := Answer(LBattle, LEngine, LHost, LLine);
      except
        on E: Exception do
          LActual := 'EXCEPTION ' + E.ClassName + ': ' + E.Message;
      end;
      if LActual <> LLine then
      begin
        Inc(LFailures);
        if GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS') <> '' then
          TFile.AppendAllText(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS'), LLine + sLineBreak + '   <> ' + LActual +
            sLineBreak);
        if LFailures <= 6 then
          LFailed := LFailed + ExtractFileName(ABase) + ': ' + Copy(LLine, 1, 330) + sLineBreak + '   <> ' +
            Copy(LActual, 1, 330) + sLineBreak;
      end;
    end;
  finally
    LLines.Free;
    // the engine is not there when the load of the battle fails
    if Assigned(LEngine) then
      LEngine.Host := nil;
    LBattle.Free;
  end;
  if LFailures > 6 then
    LFailed := LFailed + Format('%s: %d differences in all', [ExtractFileName(ABase), LFailures]) + sLineBreak;
  Result := LFailed;
end;

procedure TTestXcomRealProjectile.DovrebbeDareLeStesseRisposteDelVeroProjectile;
var
  LFolder: string;
  LPath: string;
  LCount: Integer;
  LFailed: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or not Assigned(FRuleset) or (Length(FVoxels) = 0) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'proj*.txt') do
  begin
    LFailed := LFailed + RunCase(Copy(LPath, 1, Length(LPath) - 4));
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'Nessun file del proiettile');
  Assert.AreEqual('', LFailed, 'Risposte diverse dal vero OpenXcom');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealProjectile);
  TDUnitX.RegisterTestFixture(TTestXcomRealProjectileUfo);

end.
