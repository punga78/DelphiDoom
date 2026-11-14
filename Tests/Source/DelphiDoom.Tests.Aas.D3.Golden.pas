{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 AAS navigation - parity with the real C++   }
{                                                                              }
{  route.golden.txt and route_small.golden.txt are what the real idAASLocal    }
{  (AAS.cpp, AAS_routing.cpp, AAS_pathing.cpp, compiled with bcc32c by         }
{  Tools\Verifica\109\Build-Harness.ps1) prints for the scenario.              }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('AasD3')]
  TTestAasD3Golden = class
  strict private
    procedure Compare(const AGoldenName: string; const AMaxCacheMemory: Integer);
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdAasLocal;
    [Test]
    procedure DovrebbeDareLeStesseRispostePerLaCacheDiCinquantaVoci;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.Aas.D3.Support, DelphiDoom.Tests.Aas.D3.Scenario;

{ TTestAasD3Golden }

procedure TTestAasD3Golden.Compare(const AGoldenName: string; const AMaxCacheMemory: Integer);
var
  LCases, LActual, LGolden, LExpected: TStringList;
  LRunner: TD3ScenarioRunner;
  LLine: string;
  LIndex: Integer;
begin
  LCases := TStringList.Create;
  LActual := TStringList.Create;
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(D3DataFolder + AGoldenName), AGoldenName + ' not found in ' + D3DataFolder);
    LCases.LoadFromFile(D3DataFolder + 'cases.txt');
    LRunner := TD3ScenarioRunner.Create(LActual, AMaxCacheMemory);
    try
      LRunner.Run(LCases);
    finally
      LRunner.Free;
    end;
    LGolden.LoadFromFile(D3DataFolder + AGoldenName);
    // the loading of the file prints three lines in the C++ and the scenario does not load a file
    for LLine in LGolden do
      if (Copy(LLine, 1, 15) <> 'P: [Load AAS]\n') and (Copy(LLine, 1, 11) <> 'P: loading ') and (LLine <> 'P: done.\n') then
        LExpected.Add(LLine);
    if LActual.Text <> LExpected.Text then
    begin
      LActual.SaveToFile(ExtractFilePath(ParamStr(0)) + ChangeFileExt(AGoldenName, '') + '.actual.txt');
      for LIndex := 0 to LExpected.Count - 1 do
        if (LIndex >= LActual.Count) or (LActual[LIndex] <> LExpected[LIndex]) then
        begin
          if LIndex < LActual.Count then
            LLine := LActual[LIndex]
          else
            LLine := '(none)';
          Assert.Fail(Format('first difference at line %d: expected "%s", got "%s"', [LIndex + 1, LExpected[LIndex], LLine]));
        end;
      Assert.AreEqual(LExpected.Count, LActual.Count, 'number of lines');
    end;
  finally
    LExpected.Free;
    LGolden.Free;
    LActual.Free;
    LCases.Free;
  end;
end;

procedure TTestAasD3Golden.DovrebbeDareLeStesseRisposteDelVeroIdAasLocal;
begin
  Compare('route.golden.txt', 2 * 1024 * 1024);
end;

procedure TTestAasD3Golden.DovrebbeDareLeStesseRispostePerLaCacheDiCinquantaVoci;
begin
  Compare('route_small.golden.txt', 3000);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasD3Golden);

end.
