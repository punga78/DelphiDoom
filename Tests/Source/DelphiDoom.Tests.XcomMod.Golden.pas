{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - parity with OpenXcom         }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.XcomMod.Scenario;

type
  [TestFixture]
  [Category('xcom-mod')]
  [Category('xcom-mod-golden')]
  TTestXcomModGolden = class(TObject)
  private
    function DataFile(const AName: string): string;
    function Lines(const AName: string): TStringList;
  public
    [Test]
    procedure DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiICasi;
    [Test]
    procedure DovrebbeAvereTuttiITipiDiRegolaEdErrori;
  end;

implementation

{ TTestXcomModGolden }

function TTestXcomModGolden.DataFile(const AName: string): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 6 do
  begin
    Result := LFolder + 'Tests\Data\XcomMod\' + AName;
    if FileExists(Result) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  raise Exception.CreateFmt('Data file %s not found', [AName]);
end;

function TTestXcomModGolden.Lines(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.LoadFromFile(DataFile(AName), TEncoding.UTF8);
  except
    Result.Free;
    raise;
  end;
end;

procedure TTestXcomModGolden.DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiICasi;
var
  LGolden, LActual: TStringList;
  LRunner: TXcomRuleScenario;
  LCorpus: TBytes;
  LIndex: Integer;
begin
  LCorpus := TFile.ReadAllBytes(DataFile('rules.corpus.txt'));
  LGolden := Lines('rules.golden.txt');
  LRunner := TXcomRuleScenario.Create;
  try
    LActual := LRunner.Run(LCorpus);
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= LActual.Count then
        Assert.Fail(Format('mancano le righe dalla %d: "%s"', [LIndex + 1, LGolden[LIndex]]));
      if LGolden[LIndex] <> LActual[LIndex] then
        Assert.Fail(Format('riga %d: atteso "%s" ottenuto "%s"', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]));
    end;
    Assert.AreEqual(LGolden.Count, LActual.Count, 'numero di righe');
  finally
    LRunner.Free;
    LGolden.Free;
  end;
end;

procedure TTestXcomModGolden.DovrebbeAvereTuttiITipiDiRegolaEdErrori;
var
  LGolden: TStringList;
  LText: string;
  LKind: string;
begin
  LGolden := Lines('rules.golden.txt');
  try
    LText := LGolden.Text;
    for LKind in ['inventory', 'country', 'region', 'research', 'manufacture', 'race', 'trajectory', 'MOD_ERR',
      'YAML_ERR', 'cost=undefined', 'point 0'] do
      Assert.IsTrue(Pos(LKind, LText) > 0, LKind);
  finally
    LGolden.Free;
  end;
end;

end.
