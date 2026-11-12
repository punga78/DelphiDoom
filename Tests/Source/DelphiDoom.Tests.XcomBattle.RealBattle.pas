{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the saved battles   }
{  written by OpenXcom (parity of load and save with the real objects)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealBattle;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip,
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.MapDataLoader, DelphiDoom.XcomMod.MapDataSet, DelphiDoom.XcomMod.McdPatch,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Base, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>The options of the default configuration of OpenXcom (diaries on)</summary>
  TXcomBattleDefaultSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealBattle = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    class function DataFolder: string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function Normalize(const AText: string): string; static;
    function Resave(const ABase: string): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLeStesseBattagliaDelVeroOpenXcom;
  end;

implementation

{ TXcomBattleDefaultSettings }

function TXcomBattleDefaultSettings.SoldierDiaries: Boolean;
begin
  Result := True;
end;

function TXcomBattleDefaultSettings.AllowPsiStrengthImprovement: Boolean;
begin
  Result := False;
end;

function TXcomBattleDefaultSettings.PsiStrengthEval: Boolean;
begin
  Result := False;
end;

{ TTestXcomRealBattle }

class function TTestXcomRealBattle.DataFolder: string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    if DirectoryExists(LFolder + 'Tests\Data\XcomBattle') then
      Exit(LFolder + 'Tests\Data\XcomBattle\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TTestXcomRealBattle.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TTestXcomRealBattle.Normalize(const AText: string): string;
begin
  Result := AText.Replace(#13#10, #10).TrimRight([#10]);
end;

procedure TTestXcomRealBattle.SetupFixture;
begin
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
  end;
end;

procedure TTestXcomRealBattle.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

function TTestXcomRealBattle.Resave(const ABase: string): string;
var
  LSaveFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LBattle: TXcomSavedBattleGame;
  LNode: IYamlNode;
  LContext: TXcomBattleContext;
  LLoader: TXcomMapDataLoader;
  LSet: TXcomMapDataSet;
  LPatch: TXcomMcdPatch;
begin
  LSaveFile := TYamlFactory.CreateParser.LoadAll(ReadText(ABase + '.sav'));
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  try
    LGame.Load(LSaveFile, FRuleset, FRules, LSettings, False, LRandom);
    LNode := TYamlFactory.CreateParser.Load(ReadText(ABase + '.yml'));
    LContext := TXcomBattleContext.Create(LRandom);
    LBattle := TXcomSavedBattleGame.Create(LContext);
    try
      LBattle.Load(LNode, FRuleset, LGame.Difficulty,
        function(AId: Integer): TXcomSoldier
        var
          LBase: TXcomBase;
          LSoldier: TXcomSoldier;
        begin
          for LBase in LGame.Bases do
            for LSoldier in LBase.Soldiers do
              if LSoldier.Id = AId then
                Exit(LSoldier);
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
      Result := string(TYamlFactory.Dump(LBattle.Save));
    finally
      LBattle.Free;
    end;
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomRealBattle.DovrebbeDareLeStesseBattagliaDelVeroOpenXcom;
var
  LFolder: string;
  LPath: string;
  LCount: Integer;
  LFailed: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or not Assigned(FRuleset) then
  begin
    TTestSkip.Ignore('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'battle*.re.yml') do
  begin
    if Normalize(TFile.ReadAllText(LPath, TEncoding.UTF8)) <>
      Normalize(Resave(Copy(LPath, 1, Length(LPath) - Length('.re.yml')))) then
      LFailed := LFailed + ExtractFileName(LPath) + ' ';
    Inc(LCount);
  end;
  TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('Battaglie confrontate: %d', [LCount]));
  Assert.IsTrue(LCount > 0, 'Nessun file di battaglia');
  Assert.AreEqual('', LFailed, 'Battaglie diverse dal vero OpenXcom');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealBattle);

end.
