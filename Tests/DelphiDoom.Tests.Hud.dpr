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
{$IFNDEF CPUX86}
  DelphiDoom.MathCore.Types in '..\Framework\GameMath\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\Framework\GameMath\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.MemoryFill in '..\Framework\MathCore\DelphiDoom.MathCore.MemoryFill.pas',
{$ENDIF}
  d_delphi in '..\Common\d_delphi.pas',
  DelphiDoom.Hud.Types in '..\IdTech1\Hud\DelphiDoom.Hud.Types.pas',
  DelphiDoom.Hud.Intf in '..\IdTech1\Hud\DelphiDoom.Hud.Intf.pas',
  DelphiDoom.Hud.TextLine in '..\IdTech1\Hud\DelphiDoom.Hud.TextLine.pas',
  DelphiDoom.Hud.ScrollingText in '..\IdTech1\Hud\DelphiDoom.Hud.ScrollingText.pas',
  DelphiDoom.Hud.InputText in '..\IdTech1\Hud\DelphiDoom.Hud.InputText.pas',
  DelphiDoom.Hud.Layout in '..\IdTech1\Hud\DelphiDoom.Hud.Layout.pas',
  DelphiDoom.Hud.TextLayout in '..\IdTech1\Hud\DelphiDoom.Hud.TextLayout.pas',
  DelphiDoom.Hud.FpsCounter in '..\IdTech1\Hud\DelphiDoom.Hud.FpsCounter.pas',
  DelphiDoom.Hud.ChatQueue in '..\IdTech1\Hud\DelphiDoom.Hud.ChatQueue.pas',
  DelphiDoom.Hud.KeyTables in '..\IdTech1\Hud\DelphiDoom.Hud.KeyTables.pas',
  DelphiDoom.Hud.LevelTime in '..\IdTech1\Hud\DelphiDoom.Hud.LevelTime.pas',
  DelphiDoom.Hud.MapTitle in '..\IdTech1\Hud\DelphiDoom.Hud.MapTitle.pas',
  DelphiDoom.Hud.Crosshair in '..\IdTech1\Hud\DelphiDoom.Hud.Crosshair.pas',
  DelphiDoom.Hud.MessageBar in '..\IdTech1\Hud\DelphiDoom.Hud.MessageBar.pas',
  DelphiDoom.Hud.Chat in '..\IdTech1\Hud\DelphiDoom.Hud.Chat.pas',
  DelphiDoom.Hud.View in '..\IdTech1\Hud\DelphiDoom.Hud.View.pas',
  DelphiDoom.Hud.HeadsUp in '..\IdTech1\Hud\DelphiDoom.Hud.HeadsUp.pas',
  DelphiDoom.Hud.Factory in '..\IdTech1\Hud\DelphiDoom.Hud.Factory.pas',
  DelphiDoom.Tests.Hud.Fakes in 'Source\DelphiDoom.Tests.Hud.Fakes.pas',
  DelphiDoom.Tests.Hud.Legacy in 'Source\DelphiDoom.Tests.Hud.Legacy.pas',
  DelphiDoom.Tests.Hud.TextLine in 'Source\DelphiDoom.Tests.Hud.TextLine.pas',
  DelphiDoom.Tests.Hud.ScrollingText in 'Source\DelphiDoom.Tests.Hud.ScrollingText.pas',
  DelphiDoom.Tests.Hud.InputText in 'Source\DelphiDoom.Tests.Hud.InputText.pas',
  DelphiDoom.Tests.Hud.Layout in 'Source\DelphiDoom.Tests.Hud.Layout.pas',
  DelphiDoom.Tests.Hud.TextLayout in 'Source\DelphiDoom.Tests.Hud.TextLayout.pas',
  DelphiDoom.Tests.Hud.FpsCounter in 'Source\DelphiDoom.Tests.Hud.FpsCounter.pas',
  DelphiDoom.Tests.Hud.ChatQueue in 'Source\DelphiDoom.Tests.Hud.ChatQueue.pas',
  DelphiDoom.Tests.Hud.KeyTables in 'Source\DelphiDoom.Tests.Hud.KeyTables.pas',
  DelphiDoom.Tests.Hud.LevelTime in 'Source\DelphiDoom.Tests.Hud.LevelTime.pas',
  DelphiDoom.Tests.Hud.MapTitle in 'Source\DelphiDoom.Tests.Hud.MapTitle.pas',
  DelphiDoom.Tests.Hud.Crosshair in 'Source\DelphiDoom.Tests.Hud.Crosshair.pas',
  DelphiDoom.Tests.Hud.MessageBar in 'Source\DelphiDoom.Tests.Hud.MessageBar.pas',
  DelphiDoom.Tests.Hud.Chat in 'Source\DelphiDoom.Tests.Hud.Chat.pas',
  DelphiDoom.Tests.Hud.HeadsUp in 'Source\DelphiDoom.Tests.Hud.HeadsUp.pas',
  DelphiDoom.Tests.Hud.Factory in 'Source\DelphiDoom.Tests.Hud.Factory.pas',
  DelphiDoom.Tests.Hud.Parity in 'Source\DelphiDoom.Tests.Hud.Parity.pas';

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
