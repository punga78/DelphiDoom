{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - how many instructions a second       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Performance;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   The sieve of TQvmPrograms on a 4 MB image, the same program Tools\Verifica\120 runs on the C at -O2
  ///   (qvmrun_o2 bench bench.qvm test 0 limit repetitions). The speed is written to the log of the test,
  ///   with no threshold: a machine that is busy would make the test fail for no reason. What is checked
  ///   is the answer and the number of instructions, which do not depend on the time
  /// </summary>
  [TestFixture]
  [Category('Qvm')]
  TTestQvmPerformance = class
  public
    [Test]
    procedure IlCrivelloDovrebbeDareIPrimiEDireQuanteIstruzioniAlSecondo;
  end;

implementation

uses
  System.Diagnostics, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory, DelphiDoom.Tests.Qvm.Programs,
  DelphiDoom.Tests.Qvm.Support;

const
  BENCH_IMAGE = 1 shl 22;
  BENCH_LIMIT = 2000000;
  // the primes below two millions
  BENCH_PRIMES = 148933;
  BENCH_REPETITIONS = 5;

procedure TTestQvmPerformance.IlCrivelloDovrebbeDareIPrimiEDireQuanteIstruzioniAlSecondo;
var
  LMachine: IQvmMachine;
  LFile: TBytes;
  LWatch: TStopwatch;
  LIndex: Integer;
  LBest, LSeconds: Double;
  LInstructions: Int64;
begin
  LFile := TQvmPrograms.Sieve(BENCH_IMAGE);
  LMachine := TQvmFactory.CreateMachine('bench', LFile, TQvmNullHost.Create);
  LBest := 0;
  for LIndex := 1 to BENCH_REPETITIONS do
  begin
    LMachine.Restart(LFile);
    LWatch := TStopwatch.StartNew;
    Assert.AreEqual(BENCH_PRIMES, LMachine.Call(0, [BENCH_LIMIT]));
    LSeconds := LWatch.Elapsed.TotalSeconds;
    if (LBest = 0) or (LSeconds < LBest) then
      LBest := LSeconds;
  end;
  // every run does the same
  LInstructions := LMachine.InstructionsExecuted div BENCH_REPETITIONS;
  Assert.IsTrue(LInstructions > 50000000);
  if LBest > 0 then
    TQvmScenarioRunner.Report(Format('%d istruzioni in %.3f s (la migliore di %d): ' +
      '%.1f milioni di istruzioni al secondo, %d bit', [LInstructions, LBest, BENCH_REPETITIONS,
      LInstructions / LBest / 1E6, SizeOf(Pointer) * 8]));
end;

end.
