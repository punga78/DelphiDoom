{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - parity with the real C++     }
{  (KeyInput.cpp, EditField.cpp, UsercmdGen.cpp, Console.cpp and the life      }
{  cycle of Common.cpp)                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.HostParity;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Every scenario of Tests\Data\D3Host\scenarios_host runs on the Delphi classes and must write the golden file
  ///   that the real C++ wrote (Tools\Verifica\255\Build-Harness-Host.ps1: the real KeyInput.cpp, EditField.cpp and
  ///   UsercmdGen.cpp, the real bodies of Console.cpp and of the life cycle of Common.cpp, against traced fakes)
  /// </summary>
  [TestFixture]
  [Category('D3Host')]
  TTestD3HostHostParity = class
  public
    [Test]
    [TestCase('NomiDeiTasti', 'keys_names')]
    [TestCase('AssociazioniDeiTasti', 'keys_bindings')]
    [TestCase('StatoDeiTasti', 'keys_states')]
    [TestCase('CodiciDiTrucco', 'keys_cheats')]
    [TestCase('CampoDiTestoModifica', 'field_edit')]
    [TestCase('CampoDiTestoCompletamento', 'field_complete')]
    [TestCase('UsercmdDaTastiera', 'usercmd_keys')]
    [TestCase('UsercmdDaMouse', 'usercmd_mouse')]
    [TestCase('UsercmdVari', 'usercmd_misc')]
    [TestCase('ConsoleStampa', 'console_print')]
    [TestCase('ConsoleEventi', 'console_events')]
    [TestCase('ConsoleVarie', 'console_misc')]
    [TestCase('CicloDiVitaAvvio', 'life_init')]
    [TestCase('CicloDiVitaFotogramma', 'life_frame')]
    [TestCase('CicloDiVitaChiusura', 'life_shutdown')]
    procedure LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.D3Host.HostScenario;

procedure TTestD3HostHostParity.LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
var
  LScenario: TStringList;
  LGolden: TStringList;
  LRunner: THostScenarioRunner;
begin
  LScenario := TTestFiles.Lines(TTestFiles.DataFile('D3Host', 'scenarios_host\' + AScenario + '.scn'));
  LGolden := TTestFiles.Lines(TTestFiles.DataFile('D3Host', 'golden_host\' + AScenario + '.golden.txt'));
  LRunner := THostScenarioRunner.Create;
  try
    LRunner.Run(LScenario);
    TTestGolden.AssertSameLines(LGolden, LRunner.Trace);
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3HostHostParity);

end.
