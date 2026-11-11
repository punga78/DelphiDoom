{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape library - the battle inside   }
{  a saved game against the real SavedGame of OpenXcom                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattle.RealSaveLink;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.RegularExpressions, System.ZLib, DUnitX.TestFramework, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.SaveLink,
  DelphiDoom.Tests.XcomBattle.RealBattle, DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>
  ///   The saved games that the real SavedGame::save wrote with a battleGame: the library reads them, gives the
  ///   battle and writes the same file; the battle written again is what the real load and save of it gives
  /// </summary>
  [TestFixture]
  [Category('xcom-battle')]
  [Category('xcom-battle-real')]
  TTestXcomRealSaveLink = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    class function DataFolder: string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function ReadGzOrText(const APath: string): string; static;
    class function Normalize(const AText: string): string; static;
    function Resave(const AText: TYamlText; out ABattleText: string): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareGliStessiSalvataggiConBattagliaDelVeroOpenXcom;
    [Test]
    procedure DovrebbeDareNilSeIlSalvataggioNonHaUnaBattaglia;
  end;

implementation

class function TTestXcomRealSaveLink.DataFolder: string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_GEN');
  if LFolder <> '' then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    if DirectoryExists(LFolder + 'Tests\Data\XcomBattle') then
      Exit(LFolder + 'Tests\Data\XcomBattle\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TTestXcomRealSaveLink.ReadGzOrText(const APath: string): string;
var
  LSource: TFileStream;
  LDecompress: TZDecompressionStream;
  LTarget: TStringStream;
begin
  if not FileExists(APath + '.gz') then
    Exit(TFile.ReadAllText(APath, TEncoding.UTF8));
  LSource := TFileStream.Create(APath + '.gz', fmOpenRead or fmShareDenyWrite);
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

class function TTestXcomRealSaveLink.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
  LText: string;
begin
  if FileExists(APath + '.gz') then
  begin
    LText := ReadGzOrText(APath);
    LBytes := TEncoding.UTF8.GetBytes(LText);
  end
  else
    LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TTestXcomRealSaveLink.Normalize(const AText: string): string;
begin
  // an empty list that yaml-cpp wrote as a block ("key:" and "[]" on the next line) is the same list that the
  // parser gives back in flow style ("key: []"): the document is kept as it was read
  Result := TRegEx.Replace(AText.Replace(#13#10, #10).TrimRight([#10]), ':\n\s+\[\]', ': []');
end;

procedure TTestXcomRealSaveLink.SetupFixture;
begin
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
  end;
end;

procedure TTestXcomRealSaveLink.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

function TTestXcomRealSaveLink.Resave(const AText: TYamlText; out ABattleText: string): string;
var
  LFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LInfo: TXcomSaveBriefInfo;
  LBrief: IYamlNode;
  LItem: IYamlNode;
  LMods: TArray<string>;
  LBattle: TXcomSavedBattleGame;
begin
  LFile := TYamlFactory.CreateParser.LoadAll(AText);
  LBrief := LFile[0];
  LInfo.Version := YamlTextToString(LBrief.Find(YamlStringToText('version')).AsString);
  LInfo.Engine := YamlTextToString(LBrief.Find(YamlStringToText('engine')).AsString);
  LInfo.Build := YamlTextToString(LBrief.Find(YamlStringToText('build')).AsString);
  SetLength(LMods, 0);
  for LItem in LBrief.Find(YamlStringToText('mods')).Items do
  begin
    SetLength(LMods, Length(LMods) + 1);
    LMods[High(LMods)] := YamlTextToString(LItem.AsString);
  end;
  LInfo.Mods := LMods;
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  try
    LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
    LBattle := TXcomBattleSaveLink.LoadBattle(LGame, FRuleset, TXcomBattleContext.Create(LRandom));
    try
      ABattleText := string(TYamlFactory.Dump(LBattle.Save));
      // the saved game keeps the document of the battle as it was read
      Result := string(LGame.Save(LInfo, LSettings, LRandom));
    finally
      LBattle.Free;
    end;
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomRealSaveLink.DovrebbeDareGliStessiSalvataggiConBattagliaDelVeroOpenXcom;
var
  LFolder: string;
  LPath: string;
  LBase: string;
  LFile: string;
  LCount: Integer;
  LFailed: string;
  LSave: string;
  LBattle: string;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LFolder, 'gen*.after.sav*') do
  begin
    LFile := LPath;
    if LFile.EndsWith('.gz') then
      LFile := Copy(LFile, 1, Length(LFile) - 3);
    LBase := Copy(LFile, 1, Length(LFile) - Length('.after.sav'));
    LSave := Resave(ReadText(LFile), LBattle);
    if GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_GEN_DUMP') <> '' then
    begin
      TFile.WriteAllText(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_GEN_DUMP')) +
        ExtractFileName(LBase) + '.link.sav', LSave);
      TFile.WriteAllText(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DELPHIDOOM_XCOMBATTLE_GEN_DUMP')) +
        ExtractFileName(LBase) + '.link.yml', LBattle);
    end;
    if Normalize(LSave) <> Normalize(ReadGzOrText(LFile)) then
      LFailed := LFailed + ExtractFileName(LBase) + '(sav) ';
    if Normalize(LBattle) <> Normalize(ReadGzOrText(LBase + '.re.yml')) then
      LFailed := LFailed + ExtractFileName(LBase) + '(battaglia) ';
    Inc(LCount);
  end;
  TDUnitX.CurrentRunner.Log(TLogLevel.Information, Format('Salvataggi confrontati: %d', [LCount]));
  Assert.IsTrue(LCount > 0, 'Nessun salvataggio con battaglia');
  Assert.AreEqual('', LFailed, 'Salvataggi diversi dal vero OpenXcom');
end;

procedure TTestXcomRealSaveLink.DovrebbeDareNilSeIlSalvataggioNonHaUnaBattaglia;
var
  LGame: TXcomSavedGame;
begin
  LGame := TXcomSavedGame.Create;
  try
    Assert.IsNull(TXcomBattleSaveLink.LoadBattle(LGame, FRuleset, TXcomBattleContext.Create(TXcomRandom.Create(1))));
  finally
    LGame.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealSaveLink);

end.
