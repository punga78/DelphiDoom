{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the idLib text (DUnitX)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.IdLib.Text;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.IdLib.Core.Exceptions in '..\Libs\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Core.Intf in '..\Libs\IdLib\Core\DelphiDoom.IdLib.Core.Intf.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Text.Str in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Str.pas',
  DelphiDoom.IdLib.Text.Types in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Types.pas',
  DelphiDoom.IdLib.Text.Token in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Token.pas',
  DelphiDoom.IdLib.Text.Lexer in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Lexer.pas',
  DelphiDoom.Tests.IdLib.Golden in 'Source\DelphiDoom.Tests.IdLib.Golden.pas',
  DelphiDoom.Tests.IdLib.Fakes in 'Source\DelphiDoom.Tests.IdLib.Fakes.pas',
  DelphiDoom.Tests.IdLib.Text.StrCases in 'Source\DelphiDoom.Tests.IdLib.Text.StrCases.pas',
  DelphiDoom.Tests.IdLib.Text.Str in 'Source\DelphiDoom.Tests.IdLib.Text.Str.pas',
  DelphiDoom.Tests.IdLib.Text.LexerCases in 'Source\DelphiDoom.Tests.IdLib.Text.LexerCases.pas',
  DelphiDoom.Tests.IdLib.Text.Lexer in 'Source\DelphiDoom.Tests.IdLib.Text.Lexer.pas';

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