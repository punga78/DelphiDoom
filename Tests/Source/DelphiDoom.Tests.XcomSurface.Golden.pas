{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - parity with OpenXcom         }
{                                                                              }
{  surface.script.txt has 3000 random operations (fill, clear, offset, invert,  }
{  copy, blit with crop and color key, shaded blits, resize, clone, palettes)   }
{  and 60 sprite fonts; surface.golden.txt is what the real Surface and Font    }
{  of OpenXcom, linked with SDL 1.2, printed for them (Tests\Data\README.md)    }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.Golden;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Tests.XcomSurface.Script;

type
  [TestFixture]
  [Category('xcom-surface')]
  [Category('xcom-surface-golden')]
  TTestXcomSurfaceGolden = class(TObject)
  private
    function DataFile(const AName: string): string;
    function Lines(const AName: string): TStringList;
  public
    [Test]
    procedure DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiGliScenari;
    [Test]
    procedure DovrebbeRipetereLoStessoRisultatoAOgniEsecuzione;
  end;

implementation

{ TTestXcomSurfaceGolden }

function TTestXcomSurfaceGolden.DataFile(const AName: string): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 6 do
  begin
    Result := LFolder + 'Tests\Data\XcomSurface\' + AName;
    if FileExists(Result) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  raise Exception.CreateFmt('Data file %s not found', [AName]);
end;

function TTestXcomSurfaceGolden.Lines(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.LoadFromFile(DataFile(AName));
  except
    Result.Free;
    raise;
  end;
end;

procedure TTestXcomSurfaceGolden.DovrebbeDareLeStesseRigheDiOpenXcomSuTuttiGliScenari;
var
  LScript, LGolden: TStringList;
  LRunner: TXcomSurfaceScript;
  LActual: TStringList;
  LIndex: Integer;
begin
  LScript := Lines('surface.script.txt');
  LGolden := Lines('surface.golden.txt');
  LRunner := TXcomSurfaceScript.Create;
  try
    LActual := LRunner.Run(LScript);
    Assert.AreEqual(LGolden.Count, LActual.Count, 'numero di righe');
    for LIndex := 0 to LGolden.Count - 1 do
      if LGolden[LIndex] <> LActual[LIndex] then
        Assert.Fail(Format('riga %d: atteso "%s" ottenuto "%s"', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]));
  finally
    LRunner.Free;
    LGolden.Free;
    LScript.Free;
  end;
end;

procedure TTestXcomSurfaceGolden.DovrebbeRipetereLoStessoRisultatoAOgniEsecuzione;
var
  LScript: TStringList;
  LFirst, LSecond: TXcomSurfaceScript;
begin
  LScript := Lines('surface.script.txt');
  LFirst := TXcomSurfaceScript.Create;
  LSecond := TXcomSurfaceScript.Create;
  try
    Assert.AreEqual(LFirst.Run(LScript).Text, LSecond.Run(LScript).Text);
  finally
    LSecond.Free;
    LFirst.Free;
    LScript.Free;
  end;
end;

end.
