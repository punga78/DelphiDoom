{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the idTech 4 console with the real C++ code           }
{                                                                              }
{  The files *.golden.txt in Tests\Data\Console\IdTech4 are the output of the  }
{  real idCmdSystemLocal and idCVarSystemLocal of Doom 3 (compiled with        }
{  bcc32c, see README.md there) on the scenarios *.scn, written for the tests. }
{  The Delphi classes must give the same lines.                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.IdTech4.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Tests.Console.IdTech4.Scenario;

type
  [TestFixture]
  [Category('console')]
  TTestIdTech4Golden = class(TObject)
  private
    FFolder: string;
    procedure CompareScenario(const AName: string);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCppPerICommandi;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCppPerLeCvar;
  end;

implementation

procedure TTestIdTech4Golden.Setup;
begin
  FFolder := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\Tests\Data\Console\IdTech4'));
end;

procedure TTestIdTech4Golden.CompareScenario(const AName: string);
var
  LPlayer: TIdTech4ScenarioPlayer;
  LActual, LExpected: TStringList;
  LIndex: Integer;
begin
  LExpected := TStringList.Create;
  LPlayer := TIdTech4ScenarioPlayer.Create;
  try
    LExpected.LoadFromFile(TPath.Combine(FFolder, AName + '.golden.txt'));
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

procedure TTestIdTech4Golden.DovrebbeDareLeStesseRisposteDelCppPerICommandi;
begin
  CompareScenario('commands');
end;

procedure TTestIdTech4Golden.DovrebbeDareLeStesseRisposteDelCppPerLeCvar;
begin
  CompareScenario('cvars');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestIdTech4Golden);

end.
