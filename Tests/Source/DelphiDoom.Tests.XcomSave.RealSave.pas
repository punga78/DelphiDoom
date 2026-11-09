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
  DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>The options of the default configuration of OpenXcom (diaries on)</summary>
  TXcomDefaultSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-real')]
  TTestXcomRealSave = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FRulesRef: IInterface;
    class function SaveFolder: string; static;
    class function ReadText(const APath: string): TYamlText; static;
    class function SameValue(const ALeft, ARight: string): Boolean; static;
    /// <summary>Equal texts, except the last bit of the speeds of the targets</summary>
    class function SameSave(const AExpected, AActual: TYamlText): Boolean; static;
    function Resave(const AText: TYamlText): TYamlText;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLeStesseSalvatagiDelVeroOpenXcom;
    [Test]
    procedure DovrebbeSollevareErroreSeIlFileNonHaDueDocumenti;
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

class function TTestXcomRealSave.SaveFolder: string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 6 do
  begin
    if DirectoryExists(LFolder + 'Tests\Data\XcomSave\realsave') then
      Exit(LFolder + 'Tests\Data\XcomSave\realsave\');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

procedure TTestXcomRealSave.SetupFixture;
begin
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
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
  LIndex: Integer;
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
  LIndex := 0;
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

initialization
  TDUnitX.RegisterTestFixture(TTestXcomRealSave);

end.
