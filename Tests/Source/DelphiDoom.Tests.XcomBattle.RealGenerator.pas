{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the generator of    }
{  battles against the real BattlescapeGenerator of OpenXcom                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealGenerator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.ZLib, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleTerrain, DelphiDoom.XcomMod.RuleUfo,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Base, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding,
  DelphiDoom.XcomBattle.Generator, DelphiDoom.XcomBattle.LegacyRandom, DelphiDoom.XcomBattle.Types,
  DelphiDoom.Tests.XcomBattle.RealBattle, DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>
  ///   Runs the generator on the scenarios that the real BattlescapeGenerator ran (the .sav before the run, the
  ///   .scn with the parameters and the seed, the .yml or .err after it) and compares the saved battle, the
  ///   random generator after the run and the errors
  /// </summary>
  TTestXcomRealGenerator = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FVoxels: TArray<Word>;
    function DataFolder: string;
    class function ReadText(const APath: string): TYamlText; static;
    class function Normalize(const AText: string): string; static;
    class function ReadExpected(const ABase: string): string; static;
    function RunScenario(const ABase: string; out AActual: string; out ASeed: UInt64): string;
  protected
    /// <summary>The golden of Mod::loadAll that tells the mods of the game (TFTD: xcom2, UFO: xcom1)</summary>
    function GoldenName: string; virtual;
    /// <summary>LOFTEMPS.DAT of the game, relative to the Reference folder</summary>
    function LoftempsRelative: string; virtual;
    /// <summary>The folder of the scenarios under Tests\Data\XcomBattle (empty: that folder itself)</summary>
    function ScenarioSubFolder: string; virtual;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLeStesseBattaglieDelVeroGeneratore;
  end;

  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealGeneratorTftd = class(TTestXcomRealGenerator)
  end;

  /// <summary>The same comparison on the UFO scenarios (mod xcom1, the real generator on the UFO data)</summary>
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealGeneratorUfo = class(TTestXcomRealGenerator)
  protected
    function GoldenName: string; override;
    function LoftempsRelative: string; override;
    function ScenarioSubFolder: string; override;
  end;

implementation

{ TTestXcomRealGenerator }

function TTestXcomRealGenerator.GoldenName: string;
begin
  Result := 'tftd.xcom2.golden.txt';
end;

function TTestXcomRealGenerator.LoftempsRelative: string;
begin
  Result := 'Reference\_dati\xcom_tftd\TFTD\TERRAIN\LOFTEMPS.DAT';
end;

function TTestXcomRealGenerator.ScenarioSubFolder: string;
begin
  Result := '';
end;

function TTestXcomRealGenerator.DataFolder: string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_GEN');
  if (LFolder <> '') and (ScenarioSubFolder = '') then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    if DirectoryExists(LFolder + 'Tests\Data\XcomBattle') then
      if (ScenarioSubFolder = '') or DirectoryExists(LFolder + 'Tests\Data\XcomBattle\' + ScenarioSubFolder) then
        Exit(LFolder + 'Tests\Data\XcomBattle\' + ScenarioSubFolder + '\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TTestXcomRealGenerator.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TTestXcomRealGenerator.Normalize(const AText: string): string;
begin
  Result := AText.Replace(#13#10, #10).TrimRight([#10]);
end;

class function TTestXcomRealGenerator.ReadExpected(const ABase: string): string;
var
  LSource: TFileStream;
  LDecompress: TZDecompressionStream;
  LTarget: TStringStream;
begin
  if not FileExists(ABase + '.yml.gz') then
    Exit(TFile.ReadAllText(ABase + '.yml', TEncoding.UTF8));
  LSource := TFileStream.Create(ABase + '.yml.gz', fmOpenRead or fmShareDenyWrite);
  try
    LDecompress := TZDecompressionStream.Create(LSource, 15 + 16);
    try
      LTarget := TStringStream.Create('', TEncoding.UTF8);
      try
        LTarget.CopyFrom(LDecompress, 0);
        Result := LTarget.DataString;
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

procedure TTestXcomRealGenerator.SetupFixture;
var
  LPath: string;
  LBytes: TBytes;
  LIndex: Integer;
  LFolder: string;
  LLevel: Integer;
begin
  FData := TXcomRealData.Create(GoldenName);
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
    LFolder := ExtractFilePath(ParamStr(0));
    LPath := '';
    for LLevel := 0 to 8 do
    begin
      if FileExists(LFolder + LoftempsRelative) then
      begin
        LPath := LFolder + LoftempsRelative;
        Break;
      end;
      LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
    end;
    if LPath <> '' then
    begin
      LBytes := TFile.ReadAllBytes(LPath);
      SetLength(FVoxels, Length(LBytes) div 2);
      for LIndex := 0 to High(FVoxels) do
        FVoxels[LIndex] := Word(LBytes[LIndex * 2]) or (Word(LBytes[LIndex * 2 + 1]) shl 8);
    end;
  end;
end;

procedure TTestXcomRealGenerator.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

function TTestXcomRealGenerator.RunScenario(const ABase: string; out AActual: string; out ASeed: UInt64): string;
var
  LScenario: TStringList;
  LSaveFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LBattle: TXcomSavedBattleGame;
  LContext: TXcomBattleContext;
  LEngine: TXcomTileEngine;
  LPathfinder: TXcomPathfinding;
  LGenerator: TXcomBattlescapeGenerator;
  LLegacy: TXcomLegacyRandom;
  LUfo: TXcomUfo;
  LCraft: TXcomCraft;
  LRunSeed: UInt64;
  LId: Integer;
  LUfoRules: TXcomRuleUfo;
  LParts: TArray<string>;
  LOrder: TArray<Integer>;
begin
  Result := '';
  AActual := '';
  ASeed := 0;
  LScenario := TStringList.Create;
  try
    LScenario.LoadFromFile(ABase + '.scn');
    LRunSeed := StrToUInt64(LScenario.Values['runseed']);
    LSaveFile := TYamlFactory.CreateParser.LoadAll(ReadText(ABase + '.sav'));
    LRandom := TXcomRandom.Create(LRunSeed);
    LSettings := TXcomBattleDefaultSettings.Create;
    LGame := TXcomSavedGame.Create;
    LLegacy := TXcomLegacyRandom.Create(Cardinal(LRunSeed));
    LUfo := nil;
    try
      LGame.Load(LSaveFile, FRuleset, FRules, LSettings, False, TXcomRandom.Create(1));
      LContext := TXcomBattleContext.Create(LRandom, False, False, FRuleset.Constants.FireDamageRange[0],
        FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange,
        FRuleset.Constants.ExplosiveDamageRange, 0);
      LBattle := TXcomSavedBattleGame.Create(LContext);
      try
        LBattle.MissionType := LScenario.Values['mission'];
        LPathfinder := TXcomPathfinding.Create(LBattle);
        LBattle.Pathfinder := LPathfinder;
        LEngine := TXcomTileEngine.Create(LBattle, LContext, FVoxels);
        if LScenario.Values['tileorder'] <> '' then
        begin
          LParts := LScenario.Values['tileorder'].Split([',']);
          SetLength(LOrder, Length(LParts));
          for LId := 0 to High(LParts) do
            LOrder[LId] := StrToInt(LParts[LId]);
          // the C++ keeps the tiles an explosion reaches in a std::set of pointers: the order of their addresses
          LEngine.SetDetonationOrder(LOrder);
        end;
        LBattle.TileEngine := LEngine;
        LGenerator := TXcomBattlescapeGenerator.Create(FRuleset, LBattle, LGame, LContext, LEngine, LLegacy);
        try
          LCraft := nil;
          if LScenario.Values['craft'] = '1' then
          begin
            LCraft := LGame.Bases[0].Crafts[0];
            LGenerator.SetCraft(LCraft);
          end
          else
            LGenerator.SetBase(LGame.Bases[0]);
          if LScenario.Values['ufo'] <> '' then
          begin
            LUfoRules := FRuleset.Ufos.Find(LScenario.Values['ufo']);
            LUfo := TXcomUfo.Create(LUfoRules);
            LUfo.SetLongitude(StrToFloat(LScenario.Values['uforlon'], TFormatSettings.Invariant));
            LUfo.SetLatitude(StrToFloat(LScenario.Values['uforlat'], TFormatSettings.Invariant));
            LUfo.Status := StrToInt(LScenario.Values['ufostatus']);
            LGenerator.SetUfo(LUfo);
          end;
          LGenerator.SetAlienRace(LScenario.Values['race']);
          LGenerator.SetAlienItemLevel(StrToInt(LScenario.Values['itemlevel']));
          LGenerator.SetWorldShade(StrToInt(LScenario.Values['shade']));
          LId := StrToInt(LScenario.Values['texture']);
          if LId >= 0 then
            LGenerator.SetWorldTexture(FRuleset.Globe.GetTexture(LId));
          if LScenario.Values['terrain'] <> '' then
            LGenerator.SetTerrain(FRuleset.Terrains.Find(LScenario.Values['terrain']));
          try
            LGenerator.Run;
            AActual := string(TYamlFactory.Dump(LBattle.Save));
          except
            on E: EXcomBattleException do
              Result := E.Message;
          end;
          ASeed := LRandom.Seed;
        finally
          LGenerator.Free;
        end;
      finally
        LBattle.Free;
      end;
    finally
      LUfo.Free;
      LLegacy.Free;
      LGame.Free;
    end;
  finally
    LScenario.Free;
  end;
end;

procedure TTestXcomRealGenerator.DovrebbeDareLeStesseBattaglieDelVeroGeneratore;
var
  LFolder: string;
  LPath: string;
  LBase: string;
  LCount: Integer;
  LOk: Integer;
  LFailed: string;
  LActual: string;
  LError: string;
  LSeed: UInt64;
  LScenario: TStringList;
  LDumpFolder: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) or (Length(FVoxels) = 0) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LDumpFolder := GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_GEN_DUMP');
  LCount := 0;
  LOk := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'gen*.scn') do
  begin
    LBase := Copy(LPath, 1, Length(LPath) - Length('.scn'));
    LError := RunScenario(LBase, LActual, LSeed);
    LScenario := TStringList.Create;
    try
      LScenario.LoadFromFile(LPath);
      if FileExists(LBase + '.err') then
      begin
        if LError <> TFile.ReadAllText(LBase + '.err', TEncoding.UTF8) then
          LFailed := LFailed + ExtractFileName(LBase) + '(errore: ' + LError + ') '
        else
          Inc(LOk);
      end
      else if LError <> '' then
        LFailed := LFailed + ExtractFileName(LBase) + '(errore inatteso: ' + LError + ') '
      else
      begin
        if LDumpFolder <> '' then
          TFile.WriteAllText(IncludeTrailingPathDelimiter(LDumpFolder) + ExtractFileName(LBase) + '.actual.yml',
            LActual, TEncoding.UTF8);
        if Normalize(LActual) <> Normalize(ReadExpected(LBase)) then
          LFailed := LFailed + ExtractFileName(LBase) + '(yml) '
        else if LSeed <> StrToUInt64(LScenario.Values['seedafter']) then
          LFailed := LFailed + ExtractFileName(LBase) + '(seme) '
        else
          Inc(LOk);
      end;
    finally
      LScenario.Free;
    end;
    Inc(LCount);
  end;
  TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('Scenari: %d, identici: %d', [LCount, LOk]));
  Assert.IsTrue(LCount > 0, 'Nessun file di scenario');
  Assert.AreEqual('', LFailed, 'Scenari diversi dal vero generatore');
end;

{ TTestXcomRealGeneratorUfo }

function TTestXcomRealGeneratorUfo.GoldenName: string;
begin
  Result := 'ufo.xcom1.golden.txt';
end;

function TTestXcomRealGeneratorUfo.LoftempsRelative: string;
begin
  Result := 'Reference\_dati\xcom_ufo\UFO Enemy Unkown\DOS game\GEODATA\LOFTEMPS.DAT';
end;

function TTestXcomRealGeneratorUfo.ScenarioSubFolder: string;
begin
  Result := 'ufo';
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealGeneratorTftd);
  TDUnitX.RegisterTestFixture(TTestXcomRealGeneratorUfo);

end.
