{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the Quake III console with the real C code            }
{                                                                              }
{  The files *.golden.txt in Tests\Data\Console\Q3 are the output of the real  }
{  cmd.c and cvar.c of Quake III (compiled with gcc, see                       }
{  Tools\Verifica\113q3) on the scenarios *.scn, written for the tests. The    }
{  Delphi classes must give the same lines.                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Tests.Console.Q3.Scenario;

type
  [TestFixture]
  [Category('console')]
  TTestQ3Golden = class(TObject)
  private
    FFolder: string;
    procedure CompareScenario(const AName: string);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerIComandi;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCPerLeCvar;
  end;

implementation

procedure TTestQ3Golden.Setup;
begin
  FFolder := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\Tests\Data\Console\Q3'));
end;

procedure TTestQ3Golden.CompareScenario(const AName: string);
var
  LPlayer: TQ3ScenarioPlayer;
  LActual: TStringList;
  LExpected: TStringList;
  LIndex: Integer;
begin
  LExpected := TStringList.Create;
  LPlayer := TQ3ScenarioPlayer.Create;
  try
    LExpected.LoadFromFile(TPath.Combine(FFolder, AName + '.golden.txt'), TEncoding.ANSI);
    LActual := LPlayer.Run(TPath.Combine(FFolder, AName + '.scn'));
    try
      for LIndex := 0 to LExpected.Count - 1 do
      begin
        Assert.IsTrue(LIndex < LActual.Count, Format('%s: the output ends at line %d', [AName, LIndex + 1]));
        Assert.AreEqual(LExpected[LIndex], LActual[LIndex], Format('%s, line %d', [AName, LIndex + 1]));
      end;
      Assert.AreEqual(LExpected.Count, LActual.Count, AName + ': number of lines');
    finally
      LActual.Free;
    end;
  finally
    LPlayer.Free;
    LExpected.Free;
  end;
end;

procedure TTestQ3Golden.DovrebbeDareLeStesseRisposteDelCPerIComandi;
begin
  CompareScenario('commands');
end;

procedure TTestQ3Golden.DovrebbeDareLeStesseRisposteDelCPerLeCvar;
begin
  CompareScenario('cvars');
end;

end.
