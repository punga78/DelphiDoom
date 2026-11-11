{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the thinking of the  }
{  AI against the real AIModule::think of OpenXcom                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealAI;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.ZLib, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Node, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.SaveLink, DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.AIModule, DelphiDoom.XcomBattle.AIThinker,
  DelphiDoom.Tests.XcomBattle.RealBattle, DelphiDoom.Tests.XcomMod.RealData;

type
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealAI = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FVoxels: TArray<Word>;
    class function DataFolder: string; static;
    class function FindUp(const ARelative: string; AFolder: Boolean): string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function ReadBytes(const APath: string): TBytes; static;
    class function P3(const APosition: TXcomPosition): string; static;
    class function Pos3(const AText: string): TXcomPosition; static;
    function Think(const ABattle: TXcomSavedBattleGame; const AThinker: TXcomAIThinker;
      const AEngine: TXcomTileEngine; const AQuestion: string): string;
    function RunCase(const ABase: string): string;
    function RunPaths(const ABase: string): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLeStesseDecisioniDelVeroAIModule;
    [Test]
    procedure DovrebbeDareLeStesseStradeDelVeroPathfindingSuLeMappeVere;
  end;

implementation

{ TTestXcomRealAI }

class function TTestXcomRealAI.FindUp(const ARelative: string; AFolder: Boolean): string;
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

class function TTestXcomRealAI.DataFolder: string;
var
  LFolder: string;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_AI');
  if LFolder <> '' then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LFolder := FindUp('Tests\Data\XcomBattle\ai', True);
  if LFolder <> '' then
    LFolder := IncludeTrailingPathDelimiter(LFolder);
  Result := LFolder;
end;

class function TTestXcomRealAI.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := ReadBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TTestXcomRealAI.ReadBytes(const APath: string): TBytes;
var
  LSource: TFileStream;
  LDecompress: TZDecompressionStream;
  LTarget: TBytesStream;
begin
  if not FileExists(APath + '.gz') then
    Exit(TFile.ReadAllBytes(APath));
  LSource := TFileStream.Create(APath + '.gz', fmOpenRead or fmShareDenyWrite);
  try
    LDecompress := TZDecompressionStream.Create(LSource, 15 + 16);
    try
      LTarget := TBytesStream.Create;
      try
        LTarget.CopyFrom(LDecompress, 0);
        Result := Copy(LTarget.Bytes, 0, LTarget.Size);
      finally
        LTarget.Free;
      end;
    finally
      LDecompress.Free;
    end;
  finally
    LSource.Free;
  end;
end;

class function TTestXcomRealAI.P3(const APosition: TXcomPosition): string;
begin
  Result := Format('%d/%d/%d', [APosition.X, APosition.Y, APosition.Z]);
end;

class function TTestXcomRealAI.Pos3(const AText: string): TXcomPosition;
var
  LParts: TArray<string>;
begin
  LParts := AText.Split(['/']);
  Result := TXcomPosition.Make(StrToInt(LParts[0]), StrToInt(LParts[1]), StrToInt(LParts[2]));
end;

procedure TTestXcomRealAI.SetupFixture;
var
  LPath: string;
  LBytes: TBytes;
  LIndex: Integer;
begin
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
    LPath := FindUp('Reference\_dati\xcom_tftd\TFTD\TERRAIN\LOFTEMPS.DAT', False);
    if LPath <> '' then
    begin
      LBytes := TFile.ReadAllBytes(LPath);
      SetLength(FVoxels, Length(LBytes) div 2);
      for LIndex := 0 to High(FVoxels) do
        FVoxels[LIndex] := Word(LBytes[LIndex * 2]) or (Word(LBytes[LIndex * 2 + 1]) shl 8);
    end;
  end;
end;

procedure TTestXcomRealAI.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

function TTestXcomRealAI.Think(const ABattle: TXcomSavedBattleGame; const AThinker: TXcomAIThinker;
  const AEngine: TXcomTileEngine; const AQuestion: string): string;
var
  LLeft: string;
  LParts: TArray<string>;
  LUnit: TXcomBattleUnit;
  LCandidate: TXcomBattleUnit;
  LModule: TXcomAIModule;
  LAction: TXcomBattleAction;
  LMoved: TXcomPosition;
  LText: string;
  LWaypoint: TXcomPosition;
  LWeaponId: Integer;
  LCharging: Integer;
  LAggro: Integer;
  LToNode: Integer;
  LFromNode: Integer;
begin
  LLeft := Copy(AQuestion, 1, Pos(' = ', AQuestion + ' = ') - 1);
  LParts := LLeft.Split([' ']);
  LUnit := nil;
  for LCandidate in ABattle.Units do
    if LCandidate.Id = StrToInt(LParts[1]) then
      LUnit := LCandidate;
  if not Assigned(LUnit) then
    raise Exception.CreateFmt('Unit %s not in the battle', [LParts[1]]);
  LMoved := Pos3(LParts[4]);
  if LMoved.X >= 0 then
  begin
    if not ABattle.SetUnitPosition(LUnit, LMoved) then
      raise Exception.Create('The unit could not be moved');
    AEngine.RecalculateFov;
  end;
  ABattle.Random.SetSeed(StrToUInt64(LParts[2]));
  LModule := LUnit.AI as TXcomAIModule;
  LAction := TXcomBattleAction.Create;
  try
    LAction.Number := StrToInt(LParts[3]);
    AThinker.Think(LModule, LAction);
    if Assigned(LAction.Weapon) then
      LWeaponId := LAction.Weapon.Id
    else
      LWeaponId := 0;
    LText := Format('%s = type=%d target=%s weapon=%d facing=%d final=%d desperate=%d number=%d tu=%d wp=%d',
      [LLeft, LAction.ActionType, P3(LAction.Target), LWeaponId, LAction.FinalFacing, Ord(LAction.FinalAction),
      Ord(LAction.Desperate), LAction.Number, LAction.TimeUnits, LAction.Waypoints.Count]);
    for LWaypoint in LAction.Waypoints do
      LText := LText + ':' + P3(LWaypoint);
    if Assigned(LUnit.Charging) then
      LCharging := LUnit.Charging.Id
    else
      LCharging := 0;
    if Assigned(LModule.AggroTarget) then
      LAggro := LModule.AggroTarget.Id
    else
      LAggro := 0;
    LToNode := -1;
    LFromNode := -1;
    if Assigned(LModule.ToNode) then
      LToNode := LModule.ToNode.Id;
    if Assigned(LModule.FromNode) then
      LFromNode := LModule.FromNode.Id;
    Result := Format('%s mode=%d reserve=%d esc=%d amb=%d to=%d from=%d pos=%s dir=%d utu=%d charging=%d hiding=%d ' +
      'aggro=%d known=%d vis=%d spot=%d rng=%s', [LText, LModule.AIMode, LModule.ReserveMode, LModule.EscapeTus,
      LModule.AmbushTus, LToNode, LFromNode, P3(LUnit.Position), LUnit.Direction, LUnit.TimeUnits, LCharging,
      Ord(LUnit.IsHiding), LAggro, LModule.KnownEnemies, LModule.VisibleEnemies, LModule.SpottingEnemies,
      UIntToStr(ABattle.Random.Seed)]);
  finally
    LAction.Free;
  end;
end;

function TTestXcomRealAI.RunCase(const ABase: string): string;
var
  LFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LContext: TXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
  LEngine: TXcomTileEngine;
  LEngineRef: IInterface;
  LPathfinding: TXcomPathfinding;
  LPathfindingRef: IInterface;
  LThinker: TXcomAIThinker;
  LConfig: TXcomAIConfig;
  LLines: TStringList;
  LLine: string;
  LActual: string;
  LFailed: string;
  LFailures: Integer;
begin
  LFailed := '';
  LFailures := 0;
  LFile := TYamlFactory.CreateParser.LoadAll(ReadText(ABase + '.after.sav'));
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  LLines := TStringList.Create;
  try
    LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
    LContext := TXcomBattleContext.Create(LRandom, False, False, FRuleset.Constants.FireDamageRange[0],
      FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange, 0);
    LBattle := TXcomBattleSaveLink.LoadBattle(LGame, FRuleset, LContext);
    try
      LEngine := TXcomTileEngine.Create(LBattle, LContext, FVoxels);
      LEngineRef := LEngine;
      LBattle.TileEngine := LEngine;
      LPathfinding := TXcomPathfinding.Create(LBattle);
      LPathfindingRef := LPathfinding;
      LBattle.Pathfinder := LPathfinding;
      LEngine.CalculateSunShading;
      LEngine.CalculateTerrainLighting;
      LEngine.CalculateUnitLighting;
      LEngine.RecalculateFov;
      LConfig.DifficultyCoefficient := FRuleset.Settings.DifficultyCoefficient[LGame.Difficulty];
      LConfig.TurnUseGrenade := FRuleset.Settings.TurnAIUseGrenade;
      LConfig.TurnUseBlaster := FRuleset.Settings.TurnAIUseBlaster;
      LConfig.ExplosionHeight := 0;
      LThinker := TXcomAIThinker.Create(LBattle, LEngine, LPathfinding, LConfig);
      try
        LLines.Text := TEncoding.UTF8.GetString(ReadBytes(ABase + '.ai'));
        for LLine in LLines do
        begin
          if LLine = '' then
            Continue;
          try
            LActual := Think(LBattle, LThinker, LEngine, LLine);
          except
            on E: Exception do
              LActual := 'EXCEPTION ' + E.ClassName + ': ' + E.Message;
          end;
          if LActual <> LLine then
          begin
            Inc(LFailures);
            if GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS') <> '' then
              TFile.AppendAllText(GetEnvironmentVariable('DELPHIDOOM_XCOM_FAILS'), LLine + sLineBreak + '   <> ' +
                LActual + sLineBreak);
            if LFailures <= 4 then
              LFailed := LFailed + ExtractFileName(ABase) + ': ' + LLine + sLineBreak + '   <> ' + LActual + sLineBreak;
          end;
        end;
      finally
        LThinker.Free;
      end;
    finally
      LBattle.Free;
    end;
  finally
    LLines.Free;
    LGame.Free;
  end;
  if LFailures > 4 then
    LFailed := LFailed + Format('%s: %d differences in all', [ExtractFileName(ABase), LFailures]) + sLineBreak;
  Result := LFailed;
end;

function TTestXcomRealAI.RunPaths(const ABase: string): string;
var
  LFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LContext: TXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
  LEngine: TXcomTileEngine;
  LEngineRef: IInterface;
  LPathfinding: TXcomPathfinding;
  LPathfindingRef: IInterface;
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LUnit: TXcomBattleUnit;
  LCandidate: TXcomBattleUnit;
  LNode: TXcomNode;
  LActual: string;
  LFailures: Integer;
  LDirections: string;
  LStep: Integer;
  LTuCost: Integer;
  LEndPosition: TXcomPosition;
begin
  Result := '';
  LFailures := 0;
  LFile := TYamlFactory.CreateParser.LoadAll(ReadText(ABase + '.after.sav'));
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  LLines := TStringList.Create;
  try
    LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
    LContext := TXcomBattleContext.Create(LRandom, False, False, FRuleset.Constants.FireDamageRange[0],
      FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange, 0);
    LBattle := TXcomBattleSaveLink.LoadBattle(LGame, FRuleset, LContext);
    try
      LEngine := TXcomTileEngine.Create(LBattle, LContext, FVoxels);
      LEngineRef := LEngine;
      LBattle.TileEngine := LEngine;
      LPathfinding := TXcomPathfinding.Create(LBattle);
      LPathfindingRef := LPathfinding;
      LBattle.Pathfinder := LPathfinding;
      LEngine.CalculateSunShading;
      LEngine.CalculateTerrainLighting;
      LEngine.CalculateUnitLighting;
      LEngine.RecalculateFov;
      LLines.Text := TEncoding.UTF8.GetString(ReadBytes(ABase + '.aip'));
      for LLine in LLines do
      begin
        if LLine = '' then
          Continue;
        LParts := Copy(LLine, 1, Pos(' = ', LLine) - 1).Split([' ']);
        LUnit := nil;
        for LCandidate in LBattle.Units do
          if LCandidate.Id = StrToInt(LParts[1]) then
            LUnit := LCandidate;
        if LParts[0] = 'tu' then
        begin
          LPathfinding.SetUnit(LUnit);
          LTuCost := LPathfinding.GetTuCost(LUnit.Position, StrToInt(LParts[2]), LEndPosition, LUnit, nil, False);
          LActual := Format('%s = %d %s', [Copy(LLine, 1, Pos(' = ', LLine) - 1), LTuCost, P3(LEndPosition)]);
          if LActual <> LLine then
          begin
            Inc(LFailures);
            if LFailures <= 5 then
              Result := Result + ExtractFileName(ABase) + ': ' + LLine + sLineBreak + '   <> ' + LActual + sLineBreak;
          end;
          Continue;
        end;
        LNode := LBattle.Nodes[StrToInt(LParts[2])];
        LPathfinding.Calculate(LUnit, LNode.Position);
        LDirections := '';
        for LStep in LPathfinding.Path do
          LDirections := LDirections + IntToStr(LStep);
        LActual := Format('%s = %d %d %d dirs=%s', [Copy(LLine, 1, Pos(' = ', LLine) - 1), LPathfinding.GetStartDirection,
          LPathfinding.TotalTuCost, Length(LPathfinding.Path), LDirections]);
        LPathfinding.AbortPath;
        if LActual <> LLine then
        begin
          Inc(LFailures);
          if LFailures <= 5 then
            Result := Result + ExtractFileName(ABase) + ': ' + LLine + sLineBreak + '   <> ' + LActual + sLineBreak;
        end;
      end;
    finally
      LBattle.Free;
    end;
  finally
    LLines.Free;
    LGame.Free;
  end;
  if LFailures > 5 then
    Result := Result + Format('%s: %d paths differ', [ExtractFileName(ABase), LFailures]) + sLineBreak;
end;

procedure TTestXcomRealAI.DovrebbeDareLeStesseStradeDelVeroPathfindingSuLeMappeVere;
var
  LFolder: string;
  LPath: string;
  LCount: Integer;
  LFailed: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) or (Length(FVoxels) = 0) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'gen*.aip*') do
    if LPath.EndsWith('.aip') or LPath.EndsWith('.aip.gz') then
    begin
      LFailed := LFailed + RunPaths(LPath.Substring(0, LPath.LastIndexOf('.aip')));
      Inc(LCount);
    end;
  Assert.IsTrue(LCount > 0, 'Nessun file delle strade');
  Assert.AreEqual('', LFailed, 'Strade diverse dal vero OpenXcom');
end;

procedure TTestXcomRealAI.DovrebbeDareLeStesseDecisioniDelVeroAIModule;
var
  LFolder: string;
  LPath: string;
  LCount: Integer;
  LFailed: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) or (Length(FVoxels) = 0) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'gen*.ai*') do
    if LPath.EndsWith('.ai') or LPath.EndsWith('.ai.gz') then
    begin
      LFailed := LFailed + RunCase(LPath.Substring(0, LPath.LastIndexOf('.ai')));
      Inc(LCount);
    end;
  Assert.IsTrue(LCount > 0, 'Nessun file dell''IA');
  Assert.AreEqual('', LFailed, 'Decisioni diverse dal vero OpenXcom');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealAI);

end.
