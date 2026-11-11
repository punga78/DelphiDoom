{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom debriefing library against the real       }
{  DebriefingState of OpenXcom (Tools\Verifica\176\battle\debriefgen.cpp)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomDebriefing.Real;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.RegularExpressions, System.ZLib, System.Generics.Collections,
  DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomMod.StatString, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.SaveLink, DelphiDoom.XcomDebriefing.Types,
  DelphiDoom.XcomDebriefing.Debriefing, DelphiDoom.Tests.XcomBattle.RealBattle, DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>
  ///   The saved games of the end of a battle (units killed, stunned, mind controlled, left behind, items on the floor)
  ///   that the real DebriefingState evaluated: the library gives the same report, the same seed after and the same
  ///   saved game
  /// </summary>
  [TestFixture]
  [Category('xcom-debriefing')]
  [Category('xcom-debriefing-real')]
  TTestXcomRealDebriefing = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    class function DataFolder: string; static;
    class function ReadBytes(const APath: string): TBytes; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function Normalize(const AText: string): string; static;
    class function FirstDifference(const AExpected, AActual: string): string; static;
    function Describe(const AReport: TXcomDebriefingReport; const AGame: TXcomSavedGame; ASeed: UInt64;
      AWithStatStrings: Boolean): string;
    procedure CalcAllStatStrings(const AGame: TXcomSavedGame);
    function RunFolder(const AInputs, ATexts: string; out ACount: Integer): string;
    function RunCase(const AInputBase, ATextPath: string): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLoStessoResocontoEloStessoSalvataggioDelVeroDebriefingState;
    [Test]
    procedure DovrebbeRicalcolareLaStatStringDeiSoldatiComeIlVeroDebriefingState;
  end;

implementation

class function TTestXcomRealDebriefing.DataFolder: string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_XCOMDEBRIEF');
  if LFolder <> '' then
    Exit(IncludeTrailingPathDelimiter(LFolder));
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    if DirectoryExists(LFolder + 'Tests\Data\XcomDebriefing') then
      Exit(LFolder + 'Tests\Data\XcomDebriefing\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TTestXcomRealDebriefing.ReadBytes(const APath: string): TBytes;
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

class function TTestXcomRealDebriefing.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := ReadBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TTestXcomRealDebriefing.Normalize(const AText: string): string;
begin
  Result := TRegEx.Replace(AText.Replace(#13#10, #10).TrimRight([#10]), ':\n\s+\[\]', ': []');
end;

class function TTestXcomRealDebriefing.FirstDifference(const AExpected, AActual: string): string;
var
  LExpected, LActual: TArray<string>;
  LIndex: Integer;
  LLeft, LRight: string;
begin
  LExpected := AExpected.Split([#10]);
  LActual := AActual.Split([#10]);
  for LIndex := 0 to High(LExpected) + 1 do
  begin
    if LIndex <= High(LExpected) then
      LLeft := LExpected[LIndex]
    else
      LLeft := '(end)';
    if LIndex <= High(LActual) then
      LRight := LActual[LIndex]
    else
      LRight := '(end)';
    if LLeft <> LRight then
      Exit(Format('line %d expected [%s] actual [%s]', [LIndex, LLeft, LRight]));
  end;
  Result := 'no difference';
end;

procedure TTestXcomRealDebriefing.SetupFixture;
begin
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
  end;
end;

procedure TTestXcomRealDebriefing.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

function TTestXcomRealDebriefing.Describe(const AReport: TXcomDebriefingReport; const AGame: TXcomSavedGame;
  ASeed: UInt64; AWithStatStrings: Boolean): string;
var
  LLines: TStringList;
  LStat: TXcomDebriefingStat;
  LSoldier: TXcomSoldierImprovement;
  LMissing: TXcomReequipStat;
  LKeys: TArray<Integer>;
  LKey: Integer;
  LCommended: TXcomSoldier;
  LBase: TXcomBase;
begin
  LLines := TStringList.Create;
  try
    LLines.LineBreak := #10;
    LLines.Add('seed1=' + UIntToStr(ASeed));
    LLines.Add('title=' + AReport.Title);
    LLines.Add('rating=' + AReport.Rating);
    LLines.Add('recovery=' + AReport.RecoveryTitle);
    LLines.Add(Format('flags=%d%d0%d%d', [Ord(AReport.DestroyBase), Ord(AReport.ManageContainment),
      Ord(AReport.PositiveScore), Ord(AReport.Promotions)]));
    LLines.Add('pushed=' + IntToStr(Ord(AReport.NoContainment)));
    for LStat in AReport.Stats do
      LLines.Add(Format('stat|%s|%d|%d|%d', [LStat.Item, LStat.Quantity, LStat.Score, Ord(LStat.Recovery)]));
    for LSoldier in AReport.SoldierStats do
      LLines.Add(Format('soldier|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d', [LSoldier.Name, LSoldier.Stats.TimeUnits,
        LSoldier.Stats.Stamina, LSoldier.Stats.Health, LSoldier.Stats.Bravery, LSoldier.Stats.Reactions,
        LSoldier.Stats.Firing, LSoldier.Stats.Throwing, LSoldier.Stats.Strength, LSoldier.Stats.PsiStrength,
        LSoldier.Stats.PsiSkill, LSoldier.Stats.Melee]));
    for LMissing in AReport.MissingItems do
      LLines.Add(Format('missing|%s|%d|%s', [LMissing.Item, LMissing.Quantity, LMissing.CraftName]));
    LKeys := AReport.RecoveryStats.Keys.ToArray;
    TArray.Sort<Integer>(LKeys);
    for LKey in LKeys do
      LLines.Add(Format('special|%d|%s|%d', [LKey, AReport.RecoveryStats[LKey].Name, AReport.RecoveryStats[LKey].Value]));
    for LCommended in AReport.SoldiersCommended do
      LLines.Add('commended|' + IntToStr(LCommended.Id));
    for LCommended in AReport.DeadSoldiersCommended do
      LLines.Add('deadcommended|' + IntToStr(LCommended.Id));
    if AWithStatStrings then
      for LBase in AGame.Bases do
        for LCommended in LBase.Soldiers do
          LLines.Add(Format('statstring|%d|%s', [LCommended.Id, LCommended.StatString]));
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

procedure TTestXcomRealDebriefing.CalcAllStatStrings(const AGame: TXcomSavedGame);
var
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
begin
  // what Soldier::load does at its end for every soldier (Options::psiStrengthEval is off in the harness)
  for LBase in AGame.Bases do
    for LSoldier in LBase.Soldiers do
      LSoldier.CalcStatString(FRuleset.StatStrings, False);
end;

function TTestXcomRealDebriefing.RunCase(const AInputBase, ATextPath: string): string;
const
  // kStatStrings of debriefgen.cpp (DEBRIEF_STATSTRINGS): the TFTD mods have no stat strings
  STAT_STRINGS = '- string: "x"'#10'  psiStrength: [~, 30]'#10'- string: "P"'#10'  psiStrength: [80, ~]'#10 +
    '- string: "K"'#10'  psiSkill: [20, ~]'#10'- string: "b"'#10'  bravery: [60, ~]'#10 +
    '- string: "F"'#10'  firing: [60, ~]'#10'- string: "r"'#10'  reactions: [50, ~]'#10 +
    '- string: "S"'#10'  strength: [35, ~]'#10'- string: "t"'#10'  tu: [58, ~]'#10 +
    '- string: "h"'#10'  health: [0, 30]'#10'- string: "w"'#10'  firing: [0, 45]'#10'  throwing: [0, 60]'#10;
var
  LWithStatStrings: Boolean;
  LStatString: TXcomStatString;
  LFile: TArray<IYamlNode>;
  LBrief, LItem: IYamlNode;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LContext: TXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
  LReport: TXcomDebriefingReport;
  LOptions: TXcomDebriefingOptions;
  LInfo: TXcomSaveBriefInfo;
  LMods: TArray<string>;
  LExpected, LActual, LSeed: string;
  LAborted: Boolean;
  LLines: TStringList;
  LPost: string;
  LLine: string;
  LHead, LTail: TStringList;
begin
  Result := '';
  LFile := TYamlFactory.CreateParser.LoadAll(ReadText(AInputBase + '.pre.sav'));
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
  LExpected := TEncoding.UTF8.GetString(ReadBytes(ATextPath));
  LWithStatStrings := LExpected.Contains(#10'statstring|');
  LLines := TStringList.Create;
  try
    LLines.Text := LExpected;
    LSeed := Trim(LLines.Values['seed0']);
    LAborted := Trim(LLines.Values['aborted']) = '1';
  finally
    LLines.Free;
  end;
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  try
    if LWithStatStrings then
      for LItem in TYamlFactory.CreateParser.Load(YamlStringToText(STAT_STRINGS)).Items do
      begin
        LStatString := TXcomStatString.Create;
        FRuleset.StatStrings.Add(LStatString);
        LStatString.Load(LItem);
      end;
    LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
    if LWithStatStrings then
      CalcAllStatStrings(LGame);
    LContext := TXcomBattleContext.Create(LRandom);
    LBattle := TXcomBattleSaveLink.LoadBattle(LGame, FRuleset, LContext);
    try
      LRandom.SetSeed(StrToUInt64(LSeed));
      // the saved battle does not keep whether the player aborted: the harness says so
      LBattle.Aborted := LAborted;
      LOptions := TXcomDebriefingOptions.Default;
      // the harness has no texts: the language gives the key of the name of a craft
      LOptions.CraftName :=
        function(ACraft: TXcomCraft): string
        begin
          Result := 'STR_CRAFTNAME';
        end;
      LReport := TXcomDebriefing.Run(LGame, LBattle, FRuleset, FRules, LOptions, nil);
      try
        LActual := Describe(LReport, LGame, LRandom.Seed, LWithStatStrings);
        // the expected text without the lines that the port does not give (the first line, the lists, the totals)
        LHead := TStringList.Create;
        LTail := TStringList.Create;
        try
          LHead.LineBreak := #10;
          LTail.LineBreak := #10;
          LHead.Text := LExpected;
          for LLine in LHead do
            if (not LLine.StartsWith('seed0=')) and (not LLine.StartsWith('aborted=')) and
              (not LLine.StartsWith('total=')) and
              (not LLine.StartsWith('lists=')) then
              LTail.Add(LLine.Replace(' limits=0', ''));
          LExpected := LTail.Text;
        finally
          LTail.Free;
          LHead.Free;
        end;
        if Normalize(LExpected) <> Normalize(LActual) then
          Exit('report: ' + FirstDifference(Normalize(LExpected), Normalize(LActual)));
        LPost := YamlTextToString(LGame.Save(LInfo, LSettings, LRandom));
        LExpected := TEncoding.UTF8.GetString(ReadBytes(AInputBase + '.post.sav'));
        if (GetEnvironmentVariable('DEBRIEF_DUMP') <> '') and (Normalize(LExpected) <> Normalize(LPost)) then
          TFile.WriteAllText(IncludeTrailingPathDelimiter(GetEnvironmentVariable('DEBRIEF_DUMP')) +
            ExtractFileName(AInputBase) + '.actual.sav', Normalize(LPost), TEncoding.UTF8);
        if Normalize(LExpected) <> Normalize(LPost) then
          Exit('saved game: ' + FirstDifference(Normalize(LExpected), Normalize(LPost)));
      finally
        LReport.Free;
      end;
    finally
      LBattle.Free;
    end;
  finally
    LGame.Free;
    // the stat strings of the test do not stay in the ruleset of the fixture
    if LWithStatStrings then
      FRuleset.StatStrings.Clear;
  end;
end;

function TTestXcomRealDebriefing.RunFolder(const AInputs, ATexts: string; out ACount: Integer): string;
var
  LPath, LName, LResult: string;
begin
  // a case is a text of ATexts (debNNvV.txt); its saved games, before and after, are in AInputs
  Result := '';
  ACount := 0;
  for LPath in TDirectory.GetFiles(ATexts, 'deb*.txt') do
  begin
    LName := ChangeFileExt(ExtractFileName(LPath), '');
    LResult := RunCase(AInputs + LName, LPath);
    Inc(ACount);
    if LResult <> '' then
      Result := Result + LName + ': ' + LResult + sLineBreak;
  end;
end;

procedure TTestXcomRealDebriefing.DovrebbeDareLoStessoResocontoEloStessoSalvataggioDelVeroDebriefingState;
var
  LFolder, LFailed: string;
  LCount: Integer;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LFailed := RunFolder(LFolder, LFolder, LCount);
  System.Writeln(Format('debriefing parity, %d cases', [LCount]));
  Assert.IsTrue(LCount > 0, 'Nessun file deb*.txt trovato');
  Assert.AreEqual('', LFailed, Format('%d casi', [LCount]));
end;

procedure TTestXcomRealDebriefing.DovrebbeRicalcolareLaStatStringDeiSoldatiComeIlVeroDebriefingState;
var
  LFolder, LTexts, LFailed: string;
  LCount: Integer;
begin
  LFolder := DataFolder;
  if (LFolder = '') or (not Assigned(FRuleset)) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  // DELPHIDOOM_XCOMDEBRIEF_STAT: a folder written by debriefgen with DEBRIEF_STATSTRINGS (texts and saved games);
  // otherwise the texts of the repository, whose saved games are the ones of the folder above
  LTexts := GetEnvironmentVariable('DELPHIDOOM_XCOMDEBRIEF_STAT');
  if LTexts <> '' then
  begin
    LTexts := IncludeTrailingPathDelimiter(LTexts);
    LFolder := LTexts;
  end
  else
    LTexts := LFolder + 'statstring\';
  if not DirectoryExists(LTexts) then
  begin
    Assert.Pass('Nessuna cartella con i testi delle stat string');
    Exit;
  end;
  LFailed := RunFolder(LFolder, LTexts, LCount);
  System.Writeln(Format('debriefing stat strings, %d cases', [LCount]));
  Assert.IsTrue(LCount > 0, 'Nessun file deb*.txt trovato in ' + LTexts);
  Assert.AreEqual('', LFailed, Format('%d casi', [LCount]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealDebriefing);

end.
