{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - parity with OpenXcom     }
{  (second family of objects)                                                   }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.ObjectGolden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.XcomSave.ObjectScenario;

type
  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-golden')]
  TTestXcomSaveObjectGolden = class(TObject)
  private
    function DataFile(const AName: string): string;
  public
    [Test]
    procedure DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiICasi;
    [Test]
    procedure DovrebbeAvereTuttiITipiDiOggettoELeEmissioni;
  end;

implementation

{ TTestXcomSaveObjectGolden }

function TTestXcomSaveObjectGolden.DataFile(const AName: string): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 6 do
  begin
    Result := LFolder + 'Tests\Data\XcomSave\' + AName;
    if FileExists(Result) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  raise Exception.CreateFmt('Data file %s not found', [AName]);
end;

procedure TTestXcomSaveObjectGolden.DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiICasi;
var
  LGolden, LActual: TStringList;
  LRunner: TXcomSaveObjectScenario;
  LIndex: Integer;
begin
  LGolden := TStringList.Create;
  LRunner := TXcomSaveObjectScenario.Create;
  try
    LGolden.LoadFromFile(DataFile('objects.golden.txt'), TEncoding.UTF8);
    LActual := LRunner.Run(TFile.ReadAllBytes(DataFile('objects.corpus.txt')));
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

procedure TTestXcomSaveObjectGolden.DovrebbeAvereTuttiITipiDiOggettoELeEmissioni;
var
  LGolden: TStringList;
  LText, LKind: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(DataFile('objects.golden.txt'), TEncoding.UTF8);
    LText := LGolden.Text;
    for LKind in ['waypoint', 'alienbase', 'missionsite', 'node', 'equip', 'EMIT good', 'dist=', 'YAML_ERR'] do
      Assert.IsTrue(Pos(LKind, LText) > 0, LKind);
  finally
    LGolden.Free;
  end;
end;

end.
