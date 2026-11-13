{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the heads-up display library (DUnitX)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Hud;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  d_delphi in '..\Common\d_delphi.pas',
  DelphiDoom.Hud.Types in '..\Libs\Hud\DelphiDoom.Hud.Types.pas',
  DelphiDoom.Hud.Intf in '..\Libs\Hud\DelphiDoom.Hud.Intf.pas',
  DelphiDoom.Hud.TextLine in '..\Libs\Hud\DelphiDoom.Hud.TextLine.pas',
  DelphiDoom.Hud.ScrollingText in '..\Libs\Hud\DelphiDoom.Hud.ScrollingText.pas',
  DelphiDoom.Hud.InputText in '..\Libs\Hud\DelphiDoom.Hud.InputText.pas',
  DelphiDoom.Hud.Layout in '..\Libs\Hud\DelphiDoom.Hud.Layout.pas',
  DelphiDoom.Hud.TextLayout in '..\Libs\Hud\DelphiDoom.Hud.TextLayout.pas',
  DelphiDoom.Hud.FpsCounter in '..\Libs\Hud\DelphiDoom.Hud.FpsCounter.pas',
  DelphiDoom.Hud.ChatQueue in '..\Libs\Hud\DelphiDoom.Hud.ChatQueue.pas',
  DelphiDoom.Hud.KeyTables in '..\Libs\Hud\DelphiDoom.Hud.KeyTables.pas',
  DelphiDoom.Hud.LevelTime in '..\Libs\Hud\DelphiDoom.Hud.LevelTime.pas',
  DelphiDoom.Hud.MapTitle in '..\Libs\Hud\DelphiDoom.Hud.MapTitle.pas',
  DelphiDoom.Hud.Crosshair in '..\Libs\Hud\DelphiDoom.Hud.Crosshair.pas',
  DelphiDoom.Hud.MessageBar in '..\Libs\Hud\DelphiDoom.Hud.MessageBar.pas',
  DelphiDoom.Hud.Chat in '..\Libs\Hud\DelphiDoom.Hud.Chat.pas',
  DelphiDoom.Hud.View in '..\Libs\Hud\DelphiDoom.Hud.View.pas',
  DelphiDoom.Hud.HeadsUp in '..\Libs\Hud\DelphiDoom.Hud.HeadsUp.pas',
  DelphiDoom.Hud.Factory in '..\Libs\Hud\DelphiDoom.Hud.Factory.pas';

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
