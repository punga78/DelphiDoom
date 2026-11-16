{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the texture definitions library (DUnitX)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.TextureDefs;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Framework\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Framework\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.TextureDefs.Types in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.Types.pas',
  DelphiDoom.TextureDefs.Intf in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.Intf.pas',
  DelphiDoom.TextureDefs.Names in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.Names.pas',
  DelphiDoom.TextureDefs.FlatSizes in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.FlatSizes.pas',
  DelphiDoom.TextureDefs.PatchNamesReader in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.PatchNamesReader.pas',
  DelphiDoom.TextureDefs.TextureLumpReader in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.TextureLumpReader.pas',
  DelphiDoom.TextureDefs.Pk3Reader in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.Pk3Reader.pas',
  DelphiDoom.TextureDefs.FlatInfoParser in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.FlatInfoParser.pas',
  DelphiDoom.TextureDefs.Loader in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.Loader.pas',
  DelphiDoom.TextureDefs.Factory in '..\IdTech1\TextureDefs\DelphiDoom.TextureDefs.Factory.pas',
  DelphiDoom.Tests.TextureDefs.Corpus in 'Source\DelphiDoom.Tests.TextureDefs.Corpus.pas',
  DelphiDoom.Tests.TextureDefs.Fakes in 'Source\DelphiDoom.Tests.TextureDefs.Fakes.pas',
  DelphiDoom.Tests.TextureDefs.Types in 'Source\DelphiDoom.Tests.TextureDefs.Types.pas',
  DelphiDoom.Tests.TextureDefs.Names in 'Source\DelphiDoom.Tests.TextureDefs.Names.pas',
  DelphiDoom.Tests.TextureDefs.FlatSizes in 'Source\DelphiDoom.Tests.TextureDefs.FlatSizes.pas',
  DelphiDoom.Tests.TextureDefs.PatchNamesReader in 'Source\DelphiDoom.Tests.TextureDefs.PatchNamesReader.pas',
  DelphiDoom.Tests.TextureDefs.TextureLumpReader in 'Source\DelphiDoom.Tests.TextureDefs.TextureLumpReader.pas',
  DelphiDoom.Tests.TextureDefs.Pk3Reader in 'Source\DelphiDoom.Tests.TextureDefs.Pk3Reader.pas',
  DelphiDoom.Tests.TextureDefs.FlatInfoParser in 'Source\DelphiDoom.Tests.TextureDefs.FlatInfoParser.pas',
  DelphiDoom.Tests.TextureDefs.Loader in 'Source\DelphiDoom.Tests.TextureDefs.Loader.pas',
  DelphiDoom.Tests.TextureDefs.Factory in 'Source\DelphiDoom.Tests.TextureDefs.Factory.pas',
  DelphiDoom.Tests.TextureDefs.Parity in 'Source\DelphiDoom.Tests.TextureDefs.Parity.pas';

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
