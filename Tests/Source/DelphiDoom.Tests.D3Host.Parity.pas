{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 host library - parity with the real C++     }
{  (idCommon of Common.cpp and idEventLoop of EventLoop.cpp)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Host.Parity;

interface

uses
  DUnitX.TestFramework, DelphiDoom.D3Host.Common, DelphiDoom.Tests.D3Host.World;

type
  /// <summary>
  ///   Every scenario of Tests\Data\D3Host\scenarios runs on the Delphi classes and must write the golden
  ///   file that the real C++ wrote (Tools\Verifica\255\Build-Harness.ps1: EventLoop.cpp as it is, the
  ///   functions of Common.cpp cut out of the source, against traced fakes of the engine)
  /// </summary>
  [TestFixture]
  [Category('D3Host')]
  TTestD3HostParity = class
  strict private
    FWorld: TD3FakeWorld;
    FHost: TD3CommonHost;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('Stampa', 'printing')]
    [TestCase('TroncamentoDelTesto', 'truncation')]
    [TestCase('Avvisi', 'warnings')]
    [TestCase('ErroreConRenderer', 'errors')]
    [TestCase('ErroreSenzaRendererEFatale', 'errors_nogl')]
    [TestCase('ErroreConCopyFiles', 'errors_copyfiles')]
    [TestCase('ErroreDentroUnErrore', 'errors_recursion')]
    [TestCase('TempestaDiErrori', 'errors_storm')]
    [TestCase('ErroreConGliEditor', 'errors_editors')]
    [TestCase('ErroreFatale', 'errors_fatal')]
    [TestCase('FileDiLog', 'logfile')]
    [TestCase('FileDiLogCheNonSiApre', 'logfile_failed')]
    [TestCase('RigaDiComando', 'commandline')]
    [TestCase('ModoStrumenti', 'toolmode')]
    [TestCase('CicloDegliEventi', 'events')]
    [TestCase('EventiInseriti', 'events_push')]
    [TestCase('DiarioDegliEventi', 'events_journal')]
    [TestCase('DiarioCheNonSiApre', 'events_journal_missing')]
    procedure LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.D3Host.Factory, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.D3Host.Scenario;

procedure TTestD3HostParity.Setup;
begin
  FWorld := TD3FakeWorld.Create;
  FHost := TD3HostFactory.CreateCommon(FWorld.Services);
end;

procedure TTestD3HostParity.TearDown;
begin
  FHost.Free;
  FWorld.Free;
end;

procedure TTestD3HostParity.LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
var
  LScenario: TStringList;
  LGolden: TStringList;
  LRunner: TD3ScenarioRunner;
begin
  LScenario := TTestFiles.Lines(TTestFiles.DataFile('D3Host', 'scenarios\' + AScenario + '.scn'));
  LGolden := TTestFiles.Lines(TTestFiles.DataFile('D3Host', 'golden\' + AScenario + '.golden.txt'));
  LRunner := TD3ScenarioRunner.Create(FWorld, FHost);
  try
    LRunner.Run(LScenario);
    TTestGolden.AssertSameLines(LGolden, FWorld.Trace);
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3HostParity);

end.
