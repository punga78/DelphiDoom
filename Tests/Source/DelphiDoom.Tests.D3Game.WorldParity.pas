{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - parity with the real C++     }
{  (the triggers of Trigger.cpp, the movers and doors of Mover.cpp, the        }
{  parametric physics, the targets of Entity.cpp and the event queue)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.WorldParity;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.D3Game.WorldRig;

type
  /// <summary>
  ///   Every scenario of Tests\Data\D3World\scenarios runs on the Delphi classes and must write the golden file that the
  ///   real C++ wrote (Tools\Verifica\255\Build-Harness-World.ps1: the real Trigger.h, Mover.h and idEntityPtr, the real
  ///   event queue and the real bodies of Trigger.cpp, Mover.cpp, Physics_Parametric.cpp, Entity.cpp and Game_local.cpp)
  /// </summary>
  [TestFixture]
  [Category('D3Game')]
  TTestD3GameWorldParity = class
  strict private
    FRig: TD3WorldRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('TriggerMultiOnceRelay', 'triggers_multi')]
    [TestCase('TriggerTimerCountHurtFade', 'triggers_others')]
    [TestCase('PorteMovimentoLineare', 'door')]
    [TestCase('SquadraDiPorte', 'door_team')]
    [TestCase('MoverMoveToPosAccelDecel', 'mover')]
    [TestCase('MoverRotazione', 'mover_rotate')]
    procedure LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.D3Game.WorldScenario;

procedure TTestD3GameWorldParity.Setup;
begin
  FRig := TD3WorldRig.Create;
end;

procedure TTestD3GameWorldParity.TearDown;
begin
  FRig.Free;
end;

procedure TTestD3GameWorldParity.LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
var
  LScenario: TStringList;
  LGolden: TStringList;
  LRunner: TD3WorldScenarioRunner;
  LTraceFolder: string;
begin
  LScenario := TTestFiles.Lines(TTestFiles.DataFile('D3World', 'scenarios\' + AScenario + '.scn'));
  LGolden := TTestFiles.Lines(TTestFiles.DataFile('D3World', 'golden\' + AScenario + '.golden.txt'));
  LRunner := TD3WorldScenarioRunner.Create(FRig);
  try
    LRunner.Run(LScenario);
    // DD_D3GAME_TRACE=<folder>: keeps the whole trace of the run, to compare it with the golden by hand
    LTraceFolder := GetEnvironmentVariable('DD_D3GAME_TRACE');
    if LTraceFolder <> '' then
      FRig.World.Trace.SaveToFile(IncludeTrailingPathDelimiter(LTraceFolder) + AScenario + '.world.trace.txt');
    TTestGolden.AssertSameLines(LGolden, FRig.World.Trace);
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3GameWorldParity);

end.
