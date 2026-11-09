{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the endoom library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Endoom;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Endoom.Types in '..\Libs\Endoom\DelphiDoom.Endoom.Types.pas',
  DelphiDoom.Endoom.Intf in '..\Libs\Endoom\DelphiDoom.Endoom.Intf.pas',
  DelphiDoom.Endoom.Renderer in '..\Libs\Endoom\DelphiDoom.Endoom.Renderer.pas',
  DelphiDoom.Endoom.Session in '..\Libs\Endoom\DelphiDoom.Endoom.Session.pas',
  DelphiDoom.Endoom.ColorQuantizer in '..\Libs\Endoom\DelphiDoom.Endoom.ColorQuantizer.pas',
  DelphiDoom.Endoom.Screen in '..\Libs\Endoom\DelphiDoom.Endoom.Screen.pas',
  DelphiDoom.Endoom.Drawing in '..\Libs\Endoom\DelphiDoom.Endoom.Drawing.pas',
  DelphiDoom.Endoom.TextPaste in '..\Libs\Endoom\DelphiDoom.Endoom.TextPaste.pas',
  DelphiDoom.Endoom.DosFont in '..\Libs\Endoom\DelphiDoom.Endoom.DosFont.pas',
  DelphiDoom.Endoom.FontSource in '..\Libs\Endoom\DelphiDoom.Endoom.FontSource.pas',
  DelphiDoom.Endoom.ScreenImage in '..\Libs\Endoom\DelphiDoom.Endoom.ScreenImage.pas',
  DelphiDoom.Endoom.Factory in '..\Libs\Endoom\DelphiDoom.Endoom.Factory.pas',
  DelphiDoom.Tests.Endoom.Digest in 'Source\DelphiDoom.Tests.Endoom.Digest.pas',
  DelphiDoom.Tests.Endoom.EditorScenarios in 'Source\DelphiDoom.Tests.Endoom.EditorScenarios.pas',
  DelphiDoom.Tests.Endoom.EditorHelper in 'Source\DelphiDoom.Tests.Endoom.EditorHelper.pas',
  DelphiDoom.Tests.Endoom.Fixtures in 'Source\DelphiDoom.Tests.Endoom.Fixtures.pas',
  DelphiDoom.Tests.Endoom.Renderer in 'Source\DelphiDoom.Tests.Endoom.Renderer.pas',
  DelphiDoom.Tests.Endoom.Session in 'Source\DelphiDoom.Tests.Endoom.Session.pas',
  DelphiDoom.Tests.Endoom.Screen in 'Source\DelphiDoom.Tests.Endoom.Screen.pas',
  DelphiDoom.Tests.Endoom.ColorQuantizer in 'Source\DelphiDoom.Tests.Endoom.ColorQuantizer.pas',
  DelphiDoom.Tests.Endoom.Drawing in 'Source\DelphiDoom.Tests.Endoom.Drawing.pas',
  DelphiDoom.Tests.Endoom.TextPaste in 'Source\DelphiDoom.Tests.Endoom.TextPaste.pas',
  DelphiDoom.Tests.Endoom.ScreenImage in 'Source\DelphiDoom.Tests.Endoom.ScreenImage.pas';

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
