{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III shader time functions - parity with C    }
{                                                                              }
{  Runs Tests\Data\Decl\q3calc\scenario.txt with the classes of Libs\Decl and  }
{  compares the lines with q3calc.golden.txt, which is what the real          }
{  renderer\tr_shade_calc.c, tr_shade.c (ComputeTexCoords) and tr_noise.c of   }
{  Quake III printed; and Tests\Data\Decl\q3shader\remap.input.txt with        }
{  remap.golden.txt, what the real R_RemapShader of tr_shader.c printed        }
{  (Tools\Verifica\119; see Tests\Data\Decl\README.md).                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Q3ShaderCalcGolden;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.Decl.Q3ShaderCalcSupport;

type
  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderCalcGolden = class
  strict private
    function DataFolder: string;
    procedure Compare(const AGolden, AActual: TStringList; const AName: string);
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroTrShadeCalcC;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroRRemapShaderC;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions;

function TTestQ3ShaderCalcGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Decl\');
end;

procedure TTestQ3ShaderCalcGolden.Compare(const AGolden, AActual: TStringList; const AName: string);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AGolden.Count - 1 do
    if (LIndex >= AActual.Count) or (AGolden[LIndex] <> AActual[LIndex]) then
    begin
      AActual.SaveToFile(ChangeFileExt(ParamStr(0), '.' + AName + '.actual.txt'));
      if LIndex < AActual.Count then
        Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, AGolden[LIndex], AActual[LIndex]]))
      else
        Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, AGolden[LIndex]]));
    end;
  Assert.AreEqual(AGolden.Count, AActual.Count);
end;

procedure TTestQ3ShaderCalcGolden.DovrebbeDareLeStesseRisposteDelVeroTrShadeCalcC;
var
  LScenario, LGolden: TStringList;
  LRunner: TQ3CalcGoldenRunner;
begin
  LScenario := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TQ3CalcGoldenRunner.Create;
  try
    LScenario.LoadFromFile(DataFolder + 'q3calc\scenario.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'q3calc\q3calc.golden.txt', TEncoding.ANSI);
    Compare(LGolden, LRunner.Run(LScenario), 'q3calc');
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

procedure TTestQ3ShaderCalcGolden.DovrebbeDareLeStesseRisposteDelVeroRRemapShaderC;
var
  LScenario, LGolden: TStringList;
  LRunner: TQ3RemapGoldenRunner;
begin
  LScenario := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TQ3RemapGoldenRunner.Create;
  try
    LScenario.LoadFromFile(DataFolder + 'q3shader\remap.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'q3shader\remap.golden.txt', TEncoding.ANSI);
    Compare(LGolden, LRunner.Run(LScenario), 'remap');
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

end.
