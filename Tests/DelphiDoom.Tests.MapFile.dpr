{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the map file library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.MapFile;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.IdLib.Fakes in 'Source\DelphiDoom.Tests.IdLib.Fakes.pas',
  DelphiDoom.Tests.MapFile.AasReader in 'Source\DelphiDoom.Tests.MapFile.AasReader.pas',
  DelphiDoom.Tests.MapFile.AasDump in 'Source\DelphiDoom.Tests.MapFile.AasDump.pas',
  DelphiDoom.Tests.MapFile.AasGolden in 'Source\DelphiDoom.Tests.MapFile.AasGolden.pas',
  DelphiDoom.Tests.MapFile.AasSampler in 'Source\DelphiDoom.Tests.MapFile.AasSampler.pas',
  DelphiDoom.Tests.MapFile.AasWriter in 'Source\DelphiDoom.Tests.MapFile.AasWriter.pas',
  DelphiDoom.Tests.MapFile.BspFakeGrid in 'Source\DelphiDoom.Tests.MapFile.BspFakeGrid.pas',
  DelphiDoom.Tests.MapFile.BspGolden in 'Source\DelphiDoom.Tests.MapFile.BspGolden.pas',
  DelphiDoom.Tests.MapFile.BspOpenArena in 'Source\DelphiDoom.Tests.MapFile.BspOpenArena.pas',
  DelphiDoom.Tests.MapFile.BspPatches in 'Source\DelphiDoom.Tests.MapFile.BspPatches.pas',
  DelphiDoom.Tests.MapFile.BspReader in 'Source\DelphiDoom.Tests.MapFile.BspReader.pas',
  DelphiDoom.Tests.MapFile.BspRender in 'Source\DelphiDoom.Tests.MapFile.BspRender.pas',
  DelphiDoom.Tests.MapFile.BspSample in 'Source\DelphiDoom.Tests.MapFile.BspSample.pas',
  DelphiDoom.Tests.MapFile.BspValidator in 'Source\DelphiDoom.Tests.MapFile.BspValidator.pas',
  DelphiDoom.Tests.MapFile.BspWriter in 'Source\DelphiDoom.Tests.MapFile.BspWriter.pas',
  DelphiDoom.Tests.MapFile.Dump in 'Source\DelphiDoom.Tests.MapFile.Dump.pas',
  DelphiDoom.Tests.MapFile.Golden in 'Source\DelphiDoom.Tests.MapFile.Golden.pas',
  DelphiDoom.Tests.MapFile.Model in 'Source\DelphiDoom.Tests.MapFile.Model.pas',
  DelphiDoom.Tests.MapFile.Reader in 'Source\DelphiDoom.Tests.MapFile.Reader.pas',
  DelphiDoom.Tests.MapFile.ProcAreaLocator in 'Source\DelphiDoom.Tests.MapFile.ProcAreaLocator.pas',
  DelphiDoom.Tests.MapFile.ProcReader in 'Source\DelphiDoom.Tests.MapFile.ProcReader.pas',
  DelphiDoom.Tests.MapFile.ProcSample in 'Source\DelphiDoom.Tests.MapFile.ProcSample.pas',
  DelphiDoom.Tests.MapFile.ProcValidator in 'Source\DelphiDoom.Tests.MapFile.ProcValidator.pas',
  DelphiDoom.Tests.MapFile.ProcWriter in 'Source\DelphiDoom.Tests.MapFile.ProcWriter.pas',
  DelphiDoom.Tests.MapFile.Writer in 'Source\DelphiDoom.Tests.MapFile.Writer.pas';

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
