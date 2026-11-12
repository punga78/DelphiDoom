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
  DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Shared.Files,
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
begin
  Result := TTestFiles.DataFile('XcomSave', AName);
end;

procedure TTestXcomSaveObjectGolden.DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiICasi;
var
  LGolden, LActual: TStringList;
  LRunner: TXcomSaveObjectScenario;
begin
  LGolden := TStringList.Create;
  LRunner := TXcomSaveObjectScenario.Create;
  try
    LGolden.LoadFromFile(DataFile('objects.golden.txt'), TEncoding.UTF8);
    LActual := LRunner.Run(TFile.ReadAllBytes(DataFile('objects.corpus.txt')));
    TTestGolden.AssertSameLines(LGolden, LActual);
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
