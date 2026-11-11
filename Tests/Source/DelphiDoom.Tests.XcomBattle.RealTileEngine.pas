{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the answers of the  }
{  real TileEngine of OpenXcom on maps of real MCD parts and the real LOFTEMPS   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealTileEngine;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Tests.Xcom.Skip,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.MapDataLoader,
  DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.McdPatch, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.Directions, DelphiDoom.XcomBattle.TileEngine, DelphiDoom.Tests.XcomMod.RealData;

type
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealTileEngine = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FVoxels: TArray<Word>;
    function DataFolder: string;
    class function FindUp(const ARelative: string; AFolder: Boolean): string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function MapText(const ABattle: TXcomSavedBattleGame; AWhat: Integer): string; static;
    class function TileStateHash(const ABattle: TXcomSavedBattleGame): Cardinal; static;
    class function TrajectoryText(const ATrajectory: TList<TXcomPosition>): string; static;
    class function FindUnit(const ABattle: TXcomSavedBattleGame; AId: Integer): TXcomBattleUnit; static;
    function Answer(const ABattle: TXcomSavedBattleGame; const AEngine: TXcomTileEngine; const AUnits: TList<TXcomBattleUnit>;
      const AQuestion: string): string;
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
    procedure DovrebbeDareLeStesseRisposteDelVeroTileEngine;
    [Test]
    procedure UnaFormaCheLoftempsNonHaDovrebbeEssereVuota;
  end;

  /// <summary>The same comparison on the terrains and the units of UFO (enginegen on the UFO data)</summary>
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealTileEngineUfo = class(TTestXcomRealTileEngine)
  protected
    function IsUfo: Boolean; override;
  end;

implementation

uses
  DelphiDoom.Tests.XcomBattle.GameData;

{ TTestXcomRealTileEngineUfo }

function TTestXcomRealTileEngineUfo.IsUfo: Boolean;
begin
  Result := True;
end;

function TTestXcomRealTileEngine.IsUfo: Boolean;
begin
  Result := False;
end;

{ TTestXcomRealTileEngine }

class function TTestXcomRealTileEngine.FindUp(const ARelative: string; AFolder: Boolean): string;
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

function TTestXcomRealTileEngine.DataFolder: string;
var
  LFolder: string;
begin
  LFolder := GetEnvironmentVariable(TXcomTestGame.FolderVariable('DELPHIDOOM_XCOMBATTLE_ENGINE', IsUfo));
  if LFolder <> '' then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LFolder := FindUp('Tests\Data\XcomBattle\' + TXcomTestGame.ScenarioFolder('engine', IsUfo), True);
  if LFolder <> '' then
    LFolder := IncludeTrailingPathDelimiter(LFolder);
  Result := LFolder;
end;

class function TTestXcomRealTileEngine.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

procedure TTestXcomRealTileEngine.SetupFixture;
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

procedure TTestXcomRealTileEngine.TearDownFixture;
begin
  FRuleset.Free;
  FData.Free;
end;

class function TTestXcomRealTileEngine.FindUnit(const ABattle: TXcomSavedBattleGame; AId: Integer): TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  for LUnit in ABattle.Units do
    if LUnit.Id = AId then
      Exit(LUnit);
  raise Exception.CreateFmt('Unit %d not in the battle', [AId]);
end;

class function TTestXcomRealTileEngine.MapText(const ABattle: TXcomSavedBattleGame; AWhat: Integer): string;
var
  LIndex: Integer;
  LTile: TXcomTile;
  LValue: Integer;
begin
  Result := '';
  for LIndex := 0 to ABattle.MapSizeXyz - 1 do
  begin
    LTile := ABattle.TileByIndex(LIndex);
    if AWhat = 0 then
      LValue := LTile.GetShade
    else
    begin
      LValue := LTile.Visible * 8;
      if LTile.IsDiscovered(0) then
        Inc(LValue, 1);
      if LTile.IsDiscovered(1) then
        Inc(LValue, 2);
      if LTile.IsDiscovered(2) then
        Inc(LValue, 4);
    end;
    Result := Result + IntToStr(LValue) + ',';
  end;
end;

class function TTestXcomRealTileEngine.TileStateHash(const ABattle: TXcomSavedBattleGame): Cardinal;
var
  LIndex: Integer;
  LPart: Integer;
  LTile: TXcomTile;
  LDataId: Integer;
  LSetId: Integer;
  LValues: array[0..13] of Integer;
  LValue: Integer;
begin
  Result := 2166136261;
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
      Result := (Result xor Cardinal(LValue)) * 16777619;
  end;
end;

class function TTestXcomRealTileEngine.TrajectoryText(const ATrajectory: TList<TXcomPosition>): string;
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

function TTestXcomRealTileEngine.Answer(const ABattle: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
  const AUnits: TList<TXcomBattleUnit>; const AQuestion: string): string;
var
  LParts: TArray<string>;
  LLeft: string;
  LShade: Integer;
  LUnit: TXcomBattleUnit;
  LOther: TXcomBattleUnit;
  LSpotted: Boolean;
  LIndex: Integer;
  LOtherIndex: Integer;
  LUnitIds: string;
  LOrigin: TXcomPosition;
  LTarget: TXcomPosition;
  LScan: TXcomPosition;
  LCan: Boolean;
  LExposure: Integer;
  LTrajectory: TList<TXcomPosition>;
  LStart: TXcomPosition;
  LDirection: Integer;
  LEnd: TXcomPosition;
  LType: Integer;
  LSkip: Boolean;
  LResult: Integer;
  LExclude: TXcomBattleUnit;
  LStore: Boolean;
  LVoxel: Boolean;
  LCurve: Double;
  LDelta: TXcomPosition;
  LVisibleText: string;
  LCount: Integer;
  LOrder: TArray<string>;
  LIds: TArray<Integer>;
begin
  Result := '';
  LLeft := Copy(AQuestion, 1, Pos(' = ', AQuestion + ' = ') - 1);
  LParts := LLeft.Split([' ']);
  if LParts[0] = 'tileorder' then
  begin
    LOrder := AQuestion.Substring(12).Split([','], TStringSplitOptions.ExcludeEmpty);
    SetLength(LIds, Length(LOrder));
    for LIndex := 0 to High(LOrder) do
      LIds[LIndex] := StrToInt(LOrder[LIndex]);
    AEngine.SetDetonationOrder(LIds);
    Result := AQuestion;
  end
  else if LParts[0] = 'light' then
  begin
    LShade := StrToInt(LParts[1]);
    ABattle.GlobalShade := LShade;
    AEngine.CalculateSunShading;
    AEngine.CalculateTerrainLighting;
    AEngine.CalculateUnitLighting;
    Result := Format('light %d = %s', [LShade, MapText(ABattle, 0)]);
  end
  else if LParts[0] = 'shade' then
  begin
    ABattle.GlobalShade := StrToInt(LParts[1]);
    AEngine.CalculateSunShading;
    AEngine.CalculateTerrainLighting;
    AEngine.CalculateUnitLighting;
    Result := Format('shade %d', [ABattle.GlobalShade]);
  end
  else if LParts[0] = 'fov' then
  begin
    LUnit := FindUnit(ABattle, StrToInt(LParts[1]));
    LSpotted := AEngine.CalculateFovOfUnit(LUnit);
    LUnitIds := '';
    for LOther in LUnit.VisibleUnits do
      LUnitIds := LUnitIds + IntToStr(LOther.Id) + ',';
    Result := Format('fov %d = %d units=%s spotted=%d map=%s', [LUnit.Id, Ord(LSpotted), LUnitIds,
      LUnit.UnitsSpottedThisTurn.Count, MapText(ABattle, 1)]);
  end
  else if LParts[0] = 'fovall' then
  begin
    AEngine.RecalculateFov;
    Result := 'fovall map=' + MapText(ABattle, 1);
  end
  else if LParts[0] = 'visible' then
  begin
    LUnit := FindUnit(ABattle, StrToInt(LParts[1]));
    LVisibleText := '';
    for LOtherIndex := 0 to AUnits.Count - 1 do
      if (AUnits[LOtherIndex] <> LUnit) and Assigned(AUnits[LOtherIndex].Tile) then
        LVisibleText := LVisibleText + ' ' + IntToStr(Ord(AEngine.Visible(LUnit, AUnits[LOtherIndex].Tile)));
    Result := Format('visible %d =%s tilesvis=%d', [LUnit.Id, LVisibleText, LUnit.VisibleTiles.Count]);
  end
  else if LParts[0] = 'target' then
  begin
    LUnit := FindUnit(ABattle, StrToInt(LParts[1]));
    LOther := FindUnit(ABattle, StrToInt(LParts[2]));
    LOrigin := AEngine.GetSightOriginVoxel(LUnit);
    LCan := AEngine.CanTargetUnit(LOrigin, LOther.Tile, LScan, LUnit, False);
    LExposure := AEngine.CheckVoxelExposure(LOrigin, LOther.Tile, LUnit, nil);
    if not LCan then
      LScan := TXcomPosition.Make(0, 0, 0);
    Result := Format('target %d %d = %d scan=%d/%d/%d exposure=%d origin=%d/%d/%d', [LUnit.Id, LOther.Id, Ord(LCan),
      LScan.X, LScan.Y, LScan.Z, LExposure, LOrigin.X, LOrigin.Y, LOrigin.Z]);
  end
  else if LParts[0] = 'block' then
  begin
    LStart := TXcomPosition.Make(StrToInt(LParts[1]), StrToInt(LParts[2]), StrToInt(LParts[3]));
    LDirection := StrToInt(LParts[4]);
    LType := StrToInt(LParts[5]);
    LSkip := LParts[6] = '1';
    LEnd := LStart + TXcomDirections.ToVector(LDirection);
    Result := Format('block %s = h%d v%d', [LLeft.Substring(6), AEngine.HorizontalBlockage(ABattle.TileAt(LStart),
      ABattle.TileAt(LEnd), LType, LSkip), AEngine.VerticalBlockage(ABattle.TileAt(LStart), ABattle.TileAt(LEnd),
      LType, LSkip)]);
  end
  else if LParts[0] = 'line' then
  begin
    LOrigin := TXcomPosition.Make(StrToInt(LParts[1]), StrToInt(LParts[2]), StrToInt(LParts[3]));
    LTarget := TXcomPosition.Make(StrToInt(LParts[4]), StrToInt(LParts[5]), StrToInt(LParts[6]));
    LExclude := nil;
    if StrToInt(LParts[7]) <> 0 then
      LExclude := FindUnit(ABattle, StrToInt(LParts[7]));
    LStore := LParts[8] = '1';
    LVoxel := LParts[9] = '1';
    LTrajectory := TList<TXcomPosition>.Create;
    try
      LResult := AEngine.CalculateLine(LOrigin, LTarget, LStore, LTrajectory, LExclude, LVoxel);
      Result := Format('line %s = %d %s', [LLeft.Substring(5), LResult, TrajectoryText(LTrajectory)]);
    finally
      LTrajectory.Free;
    end;
  end
  else if LParts[0] = 'voxel' then
  begin
    LOrigin := TXcomPosition.Make(StrToInt(LParts[1]), StrToInt(LParts[2]), StrToInt(LParts[3]));
    Result := Format('voxel %s = %d shade=%d vis=%d', [LLeft.Substring(6), AEngine.VoxelCheck(LOrigin, nil),
      AEngine.CastedShade(LOrigin), Ord(AEngine.IsVoxelVisible(LOrigin))]);
  end
  else if LParts[0] = 'parabola' then
  begin
    LOrigin := TXcomPosition.Make(StrToInt(LParts[1]), StrToInt(LParts[2]), StrToInt(LParts[3]));
    LTarget := TXcomPosition.Make(StrToInt(LParts[4]), StrToInt(LParts[5]), StrToInt(LParts[6]));
    LCurve := StrToInt(LParts[7]) / 10.0;
    LDelta := TXcomPosition.Make(StrToInt(LParts[8]), StrToInt(LParts[9]), StrToInt(LParts[10]));
    LStore := LParts[11] = '1';
    LTrajectory := TList<TXcomPosition>.Create;
    try
      LResult := AEngine.CalculateParabola(LOrigin, LTarget, LStore, LTrajectory, nil, LCurve, LDelta);
      Result := Format('parabola %s = %d %s', [LLeft.Substring(9), LResult, TrajectoryText(LTrajectory)]);
    finally
      LTrajectory.Free;
    end;
  end
  else if LParts[0] = 'dist' then
  begin
    LOrigin := TXcomPosition.Make(StrToInt(LParts[1]), StrToInt(LParts[2]), StrToInt(LParts[3]));
    LTarget := TXcomPosition.Make(StrToInt(LParts[4]), StrToInt(LParts[5]), StrToInt(LParts[6]));
    Result := Format('dist %s = %d %d %d', [LLeft.Substring(5), AEngine.Distance(LOrigin, LTarget),
      AEngine.DistanceSq(LOrigin, LTarget), AEngine.DistanceSq(LOrigin, LTarget, False)]);
  end
  else if LParts[0] = 'explode' then
  begin
    LOrigin := TXcomPosition.Make(StrToInt(LParts[1]), StrToInt(LParts[2]), StrToInt(LParts[3]));
    LExclude := nil;
    if StrToInt(LParts[7]) <> 0 then
      LExclude := FindUnit(ABattle, StrToInt(LParts[7]));
    ABattle.Random.SetSeed(StrToInt(LParts[8]));
    AEngine.Explode(LOrigin, StrToInt(LParts[5]), StrToInt(LParts[4]), StrToInt(LParts[6]), LExclude);
    LVisibleText := '';
    for LOther in ABattle.Units do
      LVisibleText := LVisibleText + Format(' u%d:%d,%d,%d,%d%d%d%d%d,%d,%d,%d,%d,%d', [LOther.Id, LOther.Health,
        LOther.StunLevel, LOther.Morale, LOther.GetArmor(SIDE_FRONT), LOther.GetArmor(SIDE_LEFT),
        LOther.GetArmor(SIDE_RIGHT), LOther.GetArmor(SIDE_REAR), LOther.GetArmor(SIDE_UNDER), LOther.GetFatalWounds,
        LOther.Fire, LOther.Status, LOther.ExpFiring, LOther.KilledBy]);
    Result := Format('explode %s = rng=%s tiles=%u%s', [LLeft.Substring(8), UIntToStr(ABattle.Random.Seed),
      TileStateHash(ABattle), LVisibleText]);
  end
  else if LParts[0] = 'doors' then
  begin
    LCount := AEngine.CloseUfoDoors;
    Result := Format('doors = %d map=%s', [LCount, MapText(ABattle, 1)]);
  end;
end;

function TTestXcomRealTileEngine.RunCase(const ABase: string): string;
var
  LBattle: TXcomSavedBattleGame;
  LContext: TXcomBattleContext;
  LLoader: TXcomMapDataLoader;
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
  LEngine: TXcomTileEngine;
  LEngineRef: IInterface;
  LLines: TStringList;
  LLine: string;
  LActual: string;
  LFailed: string;
  LUnits: TList<TXcomBattleUnit>;
  LUnit: TXcomBattleUnit;
begin
  LFailed := '';
  // the ranges of the ruleset (Mod::DAMAGE_RANGE and the others are statics of the C++)
  LContext := TXcomBattleContext.Create(TXcomRandom.Create(1), False, False, FRuleset.Constants.FireDamageRange[0],
    FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange, 0);
  LBattle := TXcomSavedBattleGame.Create(LContext);
  LLines := TStringList.Create;
  LUnits := TList<TXcomBattleUnit>.Create;
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
    for LUnit in LBattle.Units do
      LUnits.Add(LUnit);
    LEngine := TXcomTileEngine.Create(LBattle, LContext, FVoxels);
    LEngineRef := LEngine;
    LBattle.TileEngine := LEngine;
    LLines.LoadFromFile(ABase + '.txt', TEncoding.UTF8);
    for LLine in LLines do
    begin
      if LLine = '' then
        Continue;
      LActual := Answer(LBattle, LEngine, LUnits, LLine);
      if LActual <> LLine then
        LFailed := LFailed + ExtractFileName(ABase) + ': ' + Copy(LLine, 1, 160) + sLineBreak + '   <> ' +
          Copy(LActual, 1, 160) + sLineBreak;
    end;
  finally
    LUnits.Free;
    LLines.Free;
    LBattle.Free;
  end;
  Result := LFailed;
end;

procedure TTestXcomRealTileEngine.DovrebbeDareLeStesseRisposteDelVeroTileEngine;
var
  LFolder: string;
  LPath: string;
  LCount: Integer;
  LFailed: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or not Assigned(FRuleset) or (Length(FVoxels) = 0) then
  begin
    TXcomTestSkip.Ignore('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'engine*.txt') do
  begin
    LFailed := LFailed + RunCase(Copy(LPath, 1, Length(LPath) - 4));
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'Nessun file del motore delle tegole');
  Assert.AreEqual('', LFailed, 'Risposte diverse dal vero OpenXcom');
end;

procedure TTestXcomRealTileEngine.UnaFormaCheLoftempsNonHaDovrebbeEssereVuota;
var
  LFiles: TArray<string>;
  LBattle: TXcomSavedBattleGame;
  LContext: TXcomBattleContext;
  LLoader: TXcomMapDataLoader;
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
  LEngine: TXcomTileEngine;
  LEngineRef: IInterface;
  LIndex: Integer;
  LTile: TXcomTile;
  LHeight: Integer;
  LChecked: Integer;
begin
  if (DataFolder = '') or not Assigned(FRuleset) or (Length(FVoxels) = 0) then
  begin
    Assert.Pass('Senza i dati del gioco la prova non si fa');
    Exit;
  end;
  LFiles := TDirectory.GetFiles(DataFolder, 'engine*.txt');
  Assert.IsTrue(Length(LFiles) > 0);
  LContext := TXcomBattleContext.Create(TXcomRandom.Create(1), False, False, FRuleset.Constants.FireDamageRange[0],
    FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange, 0);
  LBattle := TXcomSavedBattleGame.Create(LContext);
  try
    LBattle.Load(TYamlFactory.CreateParser.Load(ReadText(Copy(LFiles[0], 1, Length(LFiles[0]) - 4) + '.yml')),
      FRuleset, 0,
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
    // a LOFTEMPS.DAT with one shape only (the TFTD of the floppies copied the short file of GEODATA over the one
    // of TERRAIN, and a battle on the cargo ship ended with "a voxel is outside the LOFT data")
    LEngine := TXcomTileEngine.Create(LBattle, LContext, Copy(FVoxels, 0, 16));
    LEngineRef := LEngine;
    LBattle.TileEngine := LEngine;
    LChecked := 0;
    for LIndex := 0 to LBattle.MapSizeXyz - 1 do
    begin
      LTile := LBattle.TileAt(TXcomPosition.Make(LIndex mod LBattle.MapSizeX,
        (LIndex div LBattle.MapSizeX) mod LBattle.MapSizeY, LIndex div (LBattle.MapSizeX * LBattle.MapSizeY)));
      if LTile.IsVoid then
        Continue;
      for LHeight := 0 to 11 do
      begin
        LEngine.VoxelCheck(TXcomPosition.Make(LTile.Position.X * 16 + 8, LTile.Position.Y * 16 + 8,
          LTile.Position.Z * 24 + LHeight * 2), nil, True);
        Inc(LChecked);
      end;
    end;
    Assert.IsTrue(LChecked > 0, 'la mappa ha tegole con parti');
  finally
    LBattle.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealTileEngine);
  TDUnitX.RegisterTestFixture(TTestXcomRealTileEngineUfo);

end.
