{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - parity with OpenXcom      }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Golden;

interface

uses
  DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Shared.Files,
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Tests.XcomSave.Scenario;

type
  [TestFixture]
  [Category('xcom-save')]
  [Category('xcom-save-golden')]
  TTestXcomSaveGolden = class(TObject)
  private
    function DataFile(const AName: string): string;
  public
    [Test]
    procedure DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiICasi;
    [Test]
    procedure DovrebbeAvereTuttiITipiDiOggettoELeEmissioni;
  end;

implementation

{ TTestXcomSaveGolden }

function TTestXcomSaveGolden.DataFile(const AName: string): string;
begin
  Result := TTestFiles.DataFile('XcomSave', AName);
end;

procedure TTestXcomSaveGolden.DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiICasi;
var
  LGolden, LActual: TStringList;
  LRunner: TXcomSaveScenario;
begin
  LGolden := TStringList.Create;
  LRunner := TXcomSaveScenario.Create;
  try
    LGolden.LoadFromFile(DataFile('save.golden.txt'), TEncoding.UTF8);
    LActual := LRunner.Run(TFile.ReadAllBytes(DataFile('save.corpus.txt')));
    TTestGolden.AssertSameLines(LGolden, LActual);
  finally
    LRunner.Free;
    LGolden.Free;
  end;
end;

procedure TTestXcomSaveGolden.DovrebbeAvereTuttiITipiDiOggettoELeEmissioni;
var
  LGolden: TStringList;
  LText, LKind: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(DataFile('save.golden.txt'), TEncoding.UTF8);
    LText := LGolden.Text;
    for LKind in ['gametime', 'country', 'region', 'project', 'binary', 'EMIT good', 'adv=', 'month 3', 'r2 ',
      'progress=STR_', 'doubles=', 'skip'] do
      Assert.IsTrue(Pos(LKind, LText) > 0, LKind);
  finally
    LGolden.Free;
  end;
end;

end.
