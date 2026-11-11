{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom basescape library - the statistics of the  }
{  game against the real StatisticsState of OpenXcom                            }
{  (Tools\Verifica\176\battle\statgen.cpp)                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomDebriefing.Statistics;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomBasescape.GameStatistics, DelphiDoom.Tests.XcomMod.RealData,
  DelphiDoom.Tests.XcomBattle.RealBattle;

type
  /// <summary>The 16 saved games of Tests\Data\XcomSave\realsave: the rows of the list of the real StatisticsState</summary>
  [TestFixture]
  [Category('xcom-basescape')]
  [Category('xcom-basescape-real')]
  TTestXcomGameStatistics = class(TObject)
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    class function FindUp(const ARelative: string): string; static;
    function Rows(const ASavePath: string): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeDareLeStesseRigheDelVeroStatisticsState;
  end;

implementation

class function TTestXcomGameStatistics.FindUp(const ARelative: string): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 0 to 7 do
  begin
    if DirectoryExists(LFolder + ARelative) then
      Exit(LFolder + ARelative);
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

procedure TTestXcomGameStatistics.SetupFixture;
begin
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
  end;
end;

procedure TTestXcomGameStatistics.TearDownFixture;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

function TTestXcomGameStatistics.Rows(const ASavePath: string): string;
var
  LGame: TXcomSavedGame;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LFile: TArray<IYamlNode>;
  LBytes: TBytes;
  LText: TYamlText;
  LRow: TXcomGameStatistic;
  LLines: TStringList;
begin
  LBytes := TFile.ReadAllBytes(ASavePath);
  SetLength(LText, Length(LBytes));
  Move(LBytes[0], LText[1], Length(LBytes));
  LFile := TYamlFactory.CreateParser.LoadAll(LText);
  LRandom := TXcomRandom.Create(1);
  LSettings := TXcomBattleDefaultSettings.Create;
  LGame := TXcomSavedGame.Create;
  LLines := TStringList.Create;
  try
    LLines.LineBreak := #10;
    LGame.Load(LFile, FRuleset, FRules, LSettings, False, LRandom);
    for LRow in TXcomGameStatistics.Calculate(LGame, FRuleset) do
      LLines.Add(LRow.LabelKey + '|' + LRow.Value);
    Result := LLines.Text;
  finally
    LLines.Free;
    LGame.Free;
  end;
end;

procedure TTestXcomGameStatistics.DovrebbeDareLeStesseRigheDelVeroStatisticsState;
var
  LSaves, LExpectedFolder, LPath, LFailed, LLine, LExpected: string;
  LLines, LClean: TStringList;
  LCount, LDots: Integer;
begin
  LSaves := FindUp('Tests\Data\XcomSave\realsave');
  LExpectedFolder := FindUp('Tests\Data\XcomDebriefing\stat');
  if (LSaves = '') or (LExpectedFolder = '') or (not Assigned(FRuleset)) then
  begin
    Assert.Pass('Senza i dati di TFTD e i file di parita'' il confronto non si fa');
    Exit;
  end;
  LCount := 0;
  LFailed := '';
  for LPath in TDirectory.GetFiles(LSaves, 'save??.sav') do
  begin
    LLines := TStringList.Create;
    LClean := TStringList.Create;
    try
      LLines.LineBreak := #10;
      LClean.LineBreak := #10;
      LLines.Text := TFile.ReadAllText(LExpectedFolder + '\' + ChangeFileExt(ExtractFileName(LPath), '') + '.stat.txt',
        TEncoding.UTF8);
      // the cells of a list with dots end with the dots; the first line is the title
      for LLine in LLines do
        if (LLine <> '') and (not LLine.StartsWith('title=')) then
        begin
          LDots := Pos('.', LLine);
          if (LDots > 0) and (LLine.IndexOf('|') > LDots) then
            LClean.Add(Copy(LLine, 1, LDots - 1) + Copy(LLine, LLine.IndexOf('|') + 1, MaxInt))
          else
            LClean.Add(LLine);
        end;
      LExpected := LClean.Text;
    finally
      LClean.Free;
      LLines.Free;
    end;
    Inc(LCount);
    if StringReplace(Rows(LPath), '|', '|', [rfReplaceAll]) <> StringReplace(LExpected, '|', '|', [rfReplaceAll]) then
      LFailed := LFailed + ExtractFileName(LPath) + sLineBreak;
  end;
  Assert.IsTrue(LCount > 0);
  Assert.AreEqual('', LFailed, Format('%d salvataggi', [LCount]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomGameStatistics);

end.
