{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the OpenGL math library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.GlMath;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.GlMath.Types in '..\Libs\GlMath\DelphiDoom.GlMath.Types.pas',
  DelphiDoom.GlMath.Intf in '..\Libs\GlMath\DelphiDoom.GlMath.Intf.pas',
  DelphiDoom.GlMath.AngleClipper in '..\Libs\GlMath\DelphiDoom.GlMath.AngleClipper.pas',
  DelphiDoom.GlMath.ViewAngle in '..\Libs\GlMath\DelphiDoom.GlMath.ViewAngle.pas',
  DelphiDoom.GlMath.Factory in '..\Libs\GlMath\DelphiDoom.GlMath.Factory.pas',
  DelphiDoom.Tests.GlMath.Fingerprint in 'Source\DelphiDoom.Tests.GlMath.Fingerprint.pas',
  DelphiDoom.Tests.GlMath.Golden in 'Source\DelphiDoom.Tests.GlMath.Golden.pas',
  DelphiDoom.Tests.GlMath.Scenarios in 'Source\DelphiDoom.Tests.GlMath.Scenarios.pas',
  DelphiDoom.Tests.GlMath.Subject in 'Source\DelphiDoom.Tests.GlMath.Subject.pas',
  DelphiDoom.Tests.GlMath.AngleClipper in 'Source\DelphiDoom.Tests.GlMath.AngleClipper.pas',
  DelphiDoom.Tests.GlMath.ViewAngle in 'Source\DelphiDoom.Tests.GlMath.ViewAngle.pas';

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
