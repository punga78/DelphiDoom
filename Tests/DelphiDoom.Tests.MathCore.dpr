{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the math core library (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.MathCore;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Libs\MathCore\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.MathCore.TableFineSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineSine.pas',
  DelphiDoom.MathCore.TableFineTangent in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineTangent.pas',
  DelphiDoom.MathCore.TableTanToAngle in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngle.pas',
  DelphiDoom.MathCore.TableTanToAngleEx in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngleEx.pas',
  DelphiDoom.MathCore.TableFixedSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFixedSine.pas',
  DelphiDoom.MathCore.TableRandom in '..\Libs\MathCore\DelphiDoom.MathCore.TableRandom.pas',
  DelphiDoom.MathCore.TableSysRandom in '..\Libs\MathCore\DelphiDoom.MathCore.TableSysRandom.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.FixedMath in '..\Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.Trigonometry in '..\Libs\MathCore\DelphiDoom.MathCore.Trigonometry.pas',
  DelphiDoom.MathCore.VectorMath in '..\Libs\MathCore\DelphiDoom.MathCore.VectorMath.pas',
  DelphiDoom.MathCore.BoundingBox in '..\Libs\MathCore\DelphiDoom.MathCore.BoundingBox.pas',
  DelphiDoom.MathCore.IntegerStack in '..\Libs\MathCore\DelphiDoom.MathCore.IntegerStack.pas',
  DelphiDoom.MathCore.IntegerQueue in '..\Libs\MathCore\DelphiDoom.MathCore.IntegerQueue.pas',
  DelphiDoom.MathCore.GameRandom in '..\Libs\MathCore\DelphiDoom.MathCore.GameRandom.pas',
  DelphiDoom.MathCore.SystemEntropySource in '..\Libs\MathCore\DelphiDoom.MathCore.SystemEntropySource.pas',
  DelphiDoom.MathCore.StringHashTable in '..\Libs\MathCore\DelphiDoom.MathCore.StringHashTable.pas',
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.MathCore.Sha1 in '..\Libs\MathCore\DelphiDoom.MathCore.Sha1.pas',
  DelphiDoom.MathCore.Factory in '..\Libs\MathCore\DelphiDoom.MathCore.Factory.pas',
  DelphiDoom.Tests.MathCore.Fingerprint in 'Source\DelphiDoom.Tests.MathCore.Fingerprint.pas',
  DelphiDoom.Tests.MathCore.Samples in 'Source\DelphiDoom.Tests.MathCore.Samples.pas',
  DelphiDoom.Tests.MathCore.Golden in 'Source\DelphiDoom.Tests.MathCore.Golden.pas',
  DelphiDoom.Tests.MathCore.PairRunner in 'Source\DelphiDoom.Tests.MathCore.PairRunner.pas',
  DelphiDoom.Tests.MathCore.FixedMath in 'Source\DelphiDoom.Tests.MathCore.FixedMath.pas',
  DelphiDoom.Tests.MathCore.Trigonometry in 'Source\DelphiDoom.Tests.MathCore.Trigonometry.pas',
  DelphiDoom.Tests.MathCore.VectorMath in 'Source\DelphiDoom.Tests.MathCore.VectorMath.pas',
  DelphiDoom.Tests.MathCore.BoundingBox in 'Source\DelphiDoom.Tests.MathCore.BoundingBox.pas',
  DelphiDoom.Tests.MathCore.GameRandom in 'Source\DelphiDoom.Tests.MathCore.GameRandom.pas',
  DelphiDoom.Tests.MathCore.StringHashTable in 'Source\DelphiDoom.Tests.MathCore.StringHashTable.pas',
  DelphiDoom.Tests.MathCore.IntegerStack in 'Source\DelphiDoom.Tests.MathCore.IntegerStack.pas',
  DelphiDoom.Tests.MathCore.IntegerQueue in 'Source\DelphiDoom.Tests.MathCore.IntegerQueue.pas',
  DelphiDoom.Tests.MathCore.Crc32 in 'Source\DelphiDoom.Tests.MathCore.Crc32.pas',
  DelphiDoom.Tests.MathCore.Sha1 in 'Source\DelphiDoom.Tests.MathCore.Sha1.pas',
  DelphiDoom.Tests.MathCore.SystemEntropySource in 'Source\DelphiDoom.Tests.MathCore.SystemEntropySource.pas',
  DelphiDoom.Tests.MathCore.Factory in 'Source\DelphiDoom.Tests.MathCore.Factory.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
