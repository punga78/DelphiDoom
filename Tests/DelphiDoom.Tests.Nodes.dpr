{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Nodes library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Nodes;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Nodes.Types in '..\Libs\Nodes\DelphiDoom.Nodes.Types.pas',
  DelphiDoom.Nodes.Intf in '..\Libs\Nodes\DelphiDoom.Nodes.Intf.pas',
  DelphiDoom.Nodes.Adler32 in '..\Libs\Nodes\DelphiDoom.Nodes.Adler32.pas',
  DelphiDoom.Nodes.GlDetector in '..\Libs\Nodes\DelphiDoom.Nodes.GlDetector.pas',
  DelphiDoom.Nodes.GlParser in '..\Libs\Nodes\DelphiDoom.Nodes.GlParser.pas',
  DelphiDoom.Nodes.Gwa in '..\Libs\Nodes\DelphiDoom.Nodes.Gwa.pas',
  DelphiDoom.Nodes.GwaReader in '..\Libs\Nodes\DelphiDoom.Nodes.GwaReader.pas',
  DelphiDoom.Nodes.GlMapFinder in '..\Libs\Nodes\DelphiDoom.Nodes.GlMapFinder.pas',
  DelphiDoom.Nodes.VanillaParser in '..\Libs\Nodes\DelphiDoom.Nodes.VanillaParser.pas',
  DelphiDoom.Nodes.MapScanner in '..\Libs\Nodes\DelphiDoom.Nodes.MapScanner.pas',
  DelphiDoom.Nodes.HexenConverter in '..\Libs\Nodes\DelphiDoom.Nodes.HexenConverter.pas',
  DelphiDoom.Nodes.PwadAssembler in '..\Libs\Nodes\DelphiDoom.Nodes.PwadAssembler.pas',
  DelphiDoom.Nodes.GlbspInputBuilder in '..\Libs\Nodes\DelphiDoom.Nodes.GlbspInputBuilder.pas',
  DelphiDoom.Nodes.Factory in '..\Libs\Nodes\DelphiDoom.Nodes.Factory.pas',
  DelphiDoom.Tests.Nodes.Fakes in 'Source\DelphiDoom.Tests.Nodes.Fakes.pas',
  DelphiDoom.Tests.Nodes.Types in 'Source\DelphiDoom.Tests.Nodes.Types.pas',
  DelphiDoom.Tests.Nodes.Adler32 in 'Source\DelphiDoom.Tests.Nodes.Adler32.pas',
  DelphiDoom.Tests.Nodes.GlDetector in 'Source\DelphiDoom.Tests.Nodes.GlDetector.pas',
  DelphiDoom.Tests.Nodes.GlParser in 'Source\DelphiDoom.Tests.Nodes.GlParser.pas',
  DelphiDoom.Tests.Nodes.GwaReader in 'Source\DelphiDoom.Tests.Nodes.GwaReader.pas',
  DelphiDoom.Tests.Nodes.GlMapFinder in 'Source\DelphiDoom.Tests.Nodes.GlMapFinder.pas',
  DelphiDoom.Tests.Nodes.VanillaParser in 'Source\DelphiDoom.Tests.Nodes.VanillaParser.pas',
  DelphiDoom.Tests.Nodes.MapScanner in 'Source\DelphiDoom.Tests.Nodes.MapScanner.pas',
  DelphiDoom.Tests.Nodes.HexenConverter in 'Source\DelphiDoom.Tests.Nodes.HexenConverter.pas',
  DelphiDoom.Tests.Nodes.PwadAssembler in 'Source\DelphiDoom.Tests.Nodes.PwadAssembler.pas',
  DelphiDoom.Tests.Nodes.GlbspInputBuilder in 'Source\DelphiDoom.Tests.Nodes.GlbspInputBuilder.pas',
  DelphiDoom.Tests.Nodes.Factory in 'Source\DelphiDoom.Tests.Nodes.Factory.pas';

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
