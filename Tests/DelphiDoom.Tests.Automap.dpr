{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the automap library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Automap;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.TableFixedSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFixedSine.pas',
  DelphiDoom.MathCore.TableFineSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineSine.pas',
  DelphiDoom.MathCore.TableFineTangent in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineTangent.pas',
  DelphiDoom.MathCore.TableTanToAngle in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngle.pas',
  DelphiDoom.MathCore.TableTanToAngleEx in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngleEx.pas',
  DelphiDoom.MathCore.FixedMath in '..\Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.Trigonometry in '..\Libs\MathCore\DelphiDoom.MathCore.Trigonometry.pas',
  DelphiDoom.Automap.Types in '..\Libs\Automap\DelphiDoom.Automap.Types.pas',
  DelphiDoom.Automap.Intf in '..\Libs\Automap\DelphiDoom.Automap.Intf.pas',
  DelphiDoom.Automap.Transform in '..\Libs\Automap\DelphiDoom.Automap.Transform.pas',
  DelphiDoom.Automap.LineClipper in '..\Libs\Automap\DelphiDoom.Automap.LineClipper.pas',
  DelphiDoom.Automap.Rotation in '..\Libs\Automap\DelphiDoom.Automap.Rotation.pas',
  DelphiDoom.Automap.View in '..\Libs\Automap\DelphiDoom.Automap.View.pas',
  DelphiDoom.Automap.Marks in '..\Libs\Automap\DelphiDoom.Automap.Marks.pas',
  DelphiDoom.Automap.Factory in '..\Libs\Automap\DelphiDoom.Automap.Factory.pas',
  DelphiDoom.Tests.Automap.Fingerprint in 'Source\DelphiDoom.Tests.Automap.Fingerprint.pas',
  DelphiDoom.Tests.Automap.Golden in 'Source\DelphiDoom.Tests.Automap.Golden.pas',
  DelphiDoom.Tests.Automap.Scenarios in 'Source\DelphiDoom.Tests.Automap.Scenarios.pas',
  DelphiDoom.Tests.Automap.LibraryDriver in 'Source\DelphiDoom.Tests.Automap.LibraryDriver.pas',
  DelphiDoom.Tests.Automap.Parity in 'Source\DelphiDoom.Tests.Automap.Parity.pas',
  DelphiDoom.Tests.Automap.Types in 'Source\DelphiDoom.Tests.Automap.Types.pas',
  DelphiDoom.Tests.Automap.Transform in 'Source\DelphiDoom.Tests.Automap.Transform.pas',
  DelphiDoom.Tests.Automap.LineClipper in 'Source\DelphiDoom.Tests.Automap.LineClipper.pas',
  DelphiDoom.Tests.Automap.Rotation in 'Source\DelphiDoom.Tests.Automap.Rotation.pas',
  DelphiDoom.Tests.Automap.Marks in 'Source\DelphiDoom.Tests.Automap.Marks.pas',
  DelphiDoom.Tests.Automap.View in 'Source\DelphiDoom.Tests.Automap.View.pas',
  DelphiDoom.Tests.Automap.Factory in 'Source\DelphiDoom.Tests.Automap.Factory.pas';

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
