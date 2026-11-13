{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - parity with the real be_aas_file.c   }
{  and be_aas_sample.c of Quake III Arena (aas.golden.txt)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   aas.golden.txt is what Tools\Verifica\122\aasgen.exe prints: the real be_aas_file.c and
  ///   be_aas_sample.c, compiled by gcc, load eight small files and sample them with points of a
  ///   fixed seed. The runner does the same with the classes of the library; the comparison
  ///   is exact (float bits, CRC-32 of the lumps, the texts printed to the game).
  /// </summary>
  [TestFixture]
  [Category('Aas')]
  TTestAasGolden = class
  strict private
    function DataFolder: string;
  public
    [Test]
    procedure LeClassiDovrebbeDareLeStesseRisposteDelC;
    [Test]
    procedure IlGoldenDovrebbeAvereOttoCasiEIPuntiCampionati;
  end;

implementation

uses
  DelphiDoom.Tests.Aas.ScenarioRunner;

{ TTestAasGolden }

function TTestAasGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Aas\');
end;

procedure TTestAasGolden.LeClassiDovrebbeDareLeStesseRisposteDelC;
var
  LExpected, LActual: TStringList;
  LRunner: TAasScenarioRunner;
  LIndex: Integer;
begin
  LExpected := TStringList.Create;
  LActual := TStringList.Create;
  try
    LExpected.LoadFromFile(DataFolder + 'aas.golden.txt');
    LRunner := TAasScenarioRunner.Create(LActual);
    try
      LRunner.Run;
    finally
      LRunner.Free;
    end;
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if LIndex >= LActual.Count then
        Assert.Fail(Format('line %d: the golden has "%s", the library nothing', [LIndex + 1, LExpected[LIndex]]));
      if LExpected[LIndex] <> LActual[LIndex] then
        Assert.Fail(Format('line %d: golden "%s", library "%s"', [LIndex + 1, LExpected[LIndex], LActual[LIndex]]));
    end;
    Assert.AreEqual<Integer>(LExpected.Count, LActual.Count);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestAasGolden.IlGoldenDovrebbeAvereOttoCasiEIPuntiCampionati;
var
  LExpected: TStringList;
  LCases, LPoints, LTraces, LBoxes: Integer;
  LLine: string;
begin
  LExpected := TStringList.Create;
  try
    LExpected.LoadFromFile(DataFolder + 'aas.golden.txt');
    LCases := 0;
    LPoints := 0;
    LTraces := 0;
    LBoxes := 0;
    for LLine in LExpected do
    begin
      if LLine.StartsWith('case ') then
        Inc(LCases)
      else if LLine.StartsWith('pt ') then
        Inc(LPoints)
      else if LLine.StartsWith('tb ') then
        Inc(LTraces)
      else if LLine.StartsWith('box ') then
        Inc(LBoxes);
    end;
    Assert.AreEqual<Integer>(8, LCases);
    Assert.AreEqual<Integer>(4 * 120, LPoints);
    Assert.AreEqual<Integer>(4 * 160, LTraces);
    Assert.AreEqual<Integer>(4 * 60, LBoxes);
  finally
    LExpected.Free;
  end;
end;

end.
