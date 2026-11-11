{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom saved game library - the real saved       }
{  games written by OpenXcom (parity of load and save with the real objects)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.RealSave;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.AnsiStrings, DUnitX.TestFramework, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf,
  DelphiDoom.XcomSave.NewGame, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity,
  DelphiDoom.Yaml.Convert,
  DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>The options of the default configuration of OpenXcom (diaries on)</summary>
  TXcomDefaultSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

  TTestXcomRealSave = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FRulesRef: IInterface;
    function SaveFolder: string;
    class function ReadText(const APath: string): TYamlText; static;
    class function SameValue(const ALeft, ARight: string): Boolean; static;
    /// <summary>Equal texts, except the last bit of the speeds of the targets</summary>
    class function SameSave(const AExpected, AActual: TYamlText): Boolean; static;
    function Resave(const AText: TYamlText): TYamlText;
  protected
    /// <summary>The golden of Mod::loadAll that tells the mods and the files of the game</summary>
    function GoldenName: string; virtual;
    /// <summary>The folder of Tests\Data\XcomSave with the saved games of the real OpenXcom</summary>
    function SaveFolderName: string; virtual;
    /// <summary>The file of Tests\Data\XcomSave with the capacities that the real Base gave</summary>
    function CapacityFileName: string; virtual;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLeCapacitaDelleBasiDelVeroOpenXcom;
    [Test]
    procedure DovrebbeDareLeStesseSalvatagiDelVeroOpenXcom;
    [Test]
    procedure DovrebbeFareLaPartitaNuovaComeIlVeroNewSave;
    [Test]
    procedure DovrebbeSollevareErroreSeIlFileNonHaDueDocumenti;
  end;

  /// <summary>The same tests with the saved games of the real OpenXcom on the UFO mod xcom1</summary>
  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-real')]
  TTestXcomRealSaveUfo = class(TTestXcomRealSave)
  protected
    function GoldenName: string; override;
    function SaveFolderName: string; override;
    function CapacityFileName: string; override;
  end;

  /// <summary>The tests with the saved games of the real OpenXcom on the TFTD mod xcom2</summary>
  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-real')]
  TTestXcomRealSaveTftd = class(TTestXcomRealSave)
  end;

implementation

{ TXcomDefaultSettings }

function TXcomDefaultSettings.SoldierDiaries: Boolean;
begin
  Result := True;
end;

function TXcomDefaultSettings.AllowPsiStrengthImprovement: Boolean;
begin
  Result := False;
end;

function TXcomDefaultSettings.PsiStrengthEval: Boolean;
begin
  Result := False;
end;

{ TTestXcomRealSave }

function TTestXcomRealSave.GoldenName: string;
begin
  Result := 'tftd.xcom2.golden.txt';
end;

function TTestXcomRealSave.SaveFolderName: string;
begin
  Result := 'realsave';
end;

function TTestXcomRealSave.CapacityFileName: string;
begin
  Result := 'capacity.golden.txt';
end;

function TTestXcomRealSave.SaveFolder: string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    if DirectoryExists(LFolder + 'Tests\Data\XcomSave\' + SaveFolderName) then
      Exit(LFolder + 'Tests\Data\XcomSave\' + SaveFolderName + '\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

procedure TTestXcomRealSave.SetupFixture;
begin
  FData := TXcomRealData.Create(GoldenName);
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
    FRulesRef := nil;
  end;
end;

procedure TTestXcomRealSave.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

class function TTestXcomRealSave.SameValue(const ALeft, ARight: string): Boolean;
var
  LLeft, LRight: Double;
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Invariant;
  if not TryStrToFloat(Trim(Copy(ALeft, Pos(':', ALeft) + 1, MaxInt)), LLeft, LFormat) or
    not TryStrToFloat(Trim(Copy(ARight, Pos(':', ARight) + 1, MaxInt)), LRight, LFormat) then
    Exit(False);
  Result := Abs(LLeft - LRight) <= 1E-15 * Abs(LLeft);
end;

class function TTestXcomRealSave.SameSave(const AExpected, AActual: TYamlText): Boolean;
const
  // the speeds that a target recomputes when the game is loaded: the last bit depends on the x87
  TOLERATED: array[0..2] of string = ('speedLon:', 'speedLat:', 'speedRadian:');
var
  LExpected, LActual: TStringList;
  LIndex, LKey: Integer;
  LLine: string;
begin
  if AExpected = AActual then
    Exit(True);
  LExpected := TStringList.Create;
  LActual := TStringList.Create;
  try
    LExpected.Text := string(AExpected);
    LActual.Text := string(AActual);
    if LExpected.Count <> LActual.Count then
      Exit(False);
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if LExpected[LIndex] = LActual[LIndex] then
        Continue;
      LLine := Trim(LExpected[LIndex]);
      Result := False;
      for LKey := 0 to High(TOLERATED) do
        if LLine.StartsWith(TOLERATED[LKey]) and SameValue(LExpected[LIndex], LActual[LIndex]) then
          Result := True;
      if not Result then
        Exit(False);
    end;
    Result := True;
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

class function TTestXcomRealSave.ReadText(const APath: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(APath);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

function TTestXcomRealSave.Resave(const AText: TYamlText): TYamlText;
var
  LFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LInfo: TXcomSaveBriefInfo;
  LBrief, LItem: IYamlNode;
  LMods: TArray<string>;
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
  LSettings := TXcomDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  try
    LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
    Result := LGame.Save(LInfo, LSettings, LRandom);
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomRealSave.DovrebbeDareLeCapacitaDelleBasiDelVeroOpenXcom;
var
  LFolder, LGoldenPath, LText: string;
  LGolden, LActual: TStringList;
  LFile: TArray<IYamlNode>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LCapacity: TXcomBaseCapacity;
  LBase: TXcomBase;
  LSave, LIndex: Integer;
  LFormat: string;
begin
  LFolder := SaveFolder;
  LGoldenPath := LFolder + '..\' + CapacityFileName;
  if (LFolder = '') or not Assigned(FRuleset) or not TFile.Exists(LGoldenPath) then
  begin
    Assert.Pass('senza i dati di TFTD o i salvataggi il confronto non si fa');
    Exit;
  end;
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  LCapacity := TXcomBaseCapacity.Create(FRuleset);
  try
    LGolden.LoadFromFile(LGoldenPath);
    LRandom := TXcomRandom.Create(1);
    LSettings := TXcomDefaultSettings.Create;
    for LSave := 0 to 15 do
    begin
      LFile := TYamlFactory.CreateParser.LoadAll(ReadText(LFolder + Format('save%.2d.sav', [LSave])));
      LGame := TXcomSavedGame.Create;
      try
        LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
        LActual.Add(Format('save|%d|bases=%d|maintenance=%d', [LSave, LGame.Bases.Count,
          LCapacity.BaseMaintenance(LGame)]));
        for LIndex := 0 to LGame.Bases.Count - 1 do
        begin
          LBase := LGame.Bases[LIndex];
          LText := Format('base|%d|%d|', [LSave, LIndex]);
          LActual.Add(LText + Format('soldiers=%d,%d,%d,%d|scientists=%d,%d,%d|engineers=%d,%d,%d|quarters=%d,%d',
            [LBase.AvailableSoldiers(False), LBase.AvailableSoldiers(True), LCapacity.TotalSoldiers(LBase),
            LBase.Soldiers.Count, LCapacity.AvailableScientists(LBase), LCapacity.TotalScientists(LBase),
            LBase.Scientists, LCapacity.AvailableEngineers(LBase), LCapacity.TotalEngineers(LBase), LBase.Engineers,
            LCapacity.UsedQuarters(LBase), LCapacity.AvailableQuarters(LBase)]));
          LFormat := string(TYamlConvert.FormatGeneral(LCapacity.UsedStores(LBase), 17));
          LActual.Add(LText + Format('stores=%s,%d,%s,%d|laboratories=%d,%d,%d|workshops=%d,%d,%d|hangars=%d,%d',
            [LFormat, LCapacity.AvailableStores(LBase),
            string(TYamlConvert.FormatGeneral(LCapacity.IgnoredStores(LBase), 17)),
            Ord(LCapacity.StoresOverfull(LBase, 0)), LCapacity.UsedLaboratories(LBase),
            LCapacity.AvailableLaboratories(LBase), LCapacity.FreeLaboratories(LBase),
            LCapacity.UsedWorkshops(LBase), LCapacity.AvailableWorkshops(LBase), LCapacity.FreeWorkshops(LBase),
            LCapacity.UsedHangars(LBase), LCapacity.AvailableHangars(LBase)]));
          LActual.Add(LText + Format('psi=%d,%d|containment=%d,%d|defense=%d|gravs=%d|detection=%d',
            [LCapacity.UsedPsiLabs(LBase), LCapacity.AvailablePsiLabs(LBase), LCapacity.UsedContainment(LBase),
            LCapacity.AvailableContainment(LBase), LCapacity.DefenseValue(LBase), LCapacity.GravShields(LBase),
            LCapacity.DetectionChance(LBase)]));
          LActual.Add(LText + Format('maintenance=%d,%d,%d,%d', [LCapacity.CraftMaintenance(LBase),
            LCapacity.PersonnelMaintenance(LBase), LCapacity.FacilityMaintenance(LBase),
            LCapacity.MonthlyMaintenance(LBase)]));
        end;
      finally
        LGame.Free;
      end;
    end;
    Assert.AreEqual(LGolden.Count, LActual.Count, 'numero di righe');
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex + 1));
  finally
    LCapacity.Free;
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestXcomRealSave.DovrebbeDareLeStesseSalvatagiDelVeroOpenXcom;
var
  LFolder, LPath, LExpectedPath: string;
  LExpected, LActual: TYamlText;
  LCount: Integer;
  LFailed: string;
begin
  LFailed := '';
  LFolder := SaveFolder;
  if (LFolder = '') or not Assigned(FRuleset) then
  begin
    Assert.Pass('senza i dati di TFTD o i salvataggi il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  for LPath in TDirectory.GetFiles(LFolder, '*.sav') do
  begin
    if LPath.EndsWith('.re.sav') then
      Continue;
    LExpectedPath := ChangeFileExt(LPath, '.re.sav');
    // the C++ wrote the files in text mode: CRLF on Windows (the emitter writes LF)
    LExpected := System.AnsiStrings.StringReplace(ReadText(LExpectedPath), #13#10, #10, [rfReplaceAll]);
    LActual := Resave(ReadText(LPath));
    if not SameSave(LExpected, LActual) then
      LFailed := LFailed + ' ' + ExtractFileName(LPath);
    Inc(LCount);
  end;
  Assert.IsTrue(LCount > 0, 'nessun salvataggio nella cartella');
  Assert.AreEqual('', LFailed, 'salvataggi che differiscono dal C++');
end;

procedure TTestXcomRealSave.DovrebbeFareLaPartitaNuovaComeIlVeroNewSave;
var
  LFolder: string;
  LInfo: TXcomSaveBriefInfo;
  LFile: TArray<IYamlNode>;
  LBrief, LItem: IYamlNode;
  LMods: TArray<string>;
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LCraft: TXcomCraft;
  LVariant: Integer;
  LOriginal: TYamlText;
begin
  LFolder := SaveFolder;
  if (LFolder = '') or not Assigned(FRuleset) then
  begin
    Assert.Pass('senza i dati di TFTD o i salvataggi il confronto non si fa');
    Exit;
  end;
  // save00.sav is Mod::newSave() with the generator seeded with 1761, and then the changes of Play(0) of savegen.cpp
  LOriginal := System.AnsiStrings.StringReplace(ReadText(LFolder + 'save00.sav'), #13#10, #10, [rfReplaceAll]);
  LFile := TYamlFactory.CreateParser.LoadAll(LOriginal);
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
  LRandom := TXcomRandom.Create(1761);
  LSettings := TXcomDefaultSettings.Create;
  LGame := TXcomNewGame.Create(FRuleset, FRules, LSettings, LRandom).NewSave;
  try
    LVariant := 0;
    LGame.Difficulty := LVariant mod 5;
    LGame.GlobeZoom := LVariant mod 6;
    LGame.GlobeLongitude := 0.1 * LVariant;
    LGame.GlobeLatitude := -0.05 * LVariant;
    LGame.Bases[0].Name := 'Base ' + IntToStr(LVariant);
    LGame.Bases[0].SetLongitude(0.5 + 0.1 * LVariant);
    LGame.Bases[0].SetLatitude(0.2);
    for LCraft in LGame.Bases[0].Crafts do
    begin
      LCraft.SetLongitude(LGame.Bases[0].Longitude);
      LCraft.SetLatitude(LGame.Bases[0].Latitude);
    end;
    Assert.IsTrue(SameSave(LOriginal, LGame.Save(LInfo, LSettings, LRandom)),
      'la partita nuova differisce da Mod::newSave');
  finally
    LGame.Free;
  end;
end;

procedure TTestXcomRealSave.DovrebbeSollevareErroreSeIlFileNonHaDueDocumenti;
var
  LGame: TXcomSavedGame;
begin
  if not Assigned(FRuleset) then
  begin
    Assert.Pass('senza i dati di TFTD il confronto non si fa');
    Exit;
  end;
  LGame := TXcomSavedGame.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LGame.Load(nil, FRuleset, FRules, TXcomDefaultSettings.Create, False, TXcomRandom.Create(1));
      end);
  finally
    LGame.Free;
  end;
end;

{ TTestXcomRealSaveUfo }

function TTestXcomRealSaveUfo.GoldenName: string;
begin
  Result := 'ufo.xcom1.golden.txt';
end;

function TTestXcomRealSaveUfo.SaveFolderName: string;
begin
  Result := 'realsave_ufo';
end;

function TTestXcomRealSaveUfo.CapacityFileName: string;
begin
  Result := 'capacity_ufo.golden.txt';
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealSaveTftd);
  TDUnitX.RegisterTestFixture(TTestXcomRealSaveUfo);

end.
