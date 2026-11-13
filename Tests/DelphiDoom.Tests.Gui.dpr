{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Gui library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Gui;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Scanner.IdCNumbers in '..\Libs\Scanner\DelphiDoom.Scanner.IdCNumbers.pas',
  DelphiDoom.Scanner.IdParser.Types in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Types.pas',
  DelphiDoom.Scanner.IdParser.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Intf.pas',
  DelphiDoom.Scanner.IdParser.Define in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Define.pas',
  DelphiDoom.Scanner.IdParser.GlobalDefines in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.GlobalDefines.pas',
  DelphiDoom.Scanner.IdParser.Evaluator in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Evaluator.pas',
  DelphiDoom.Scanner.IdParser in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.pas',
  DelphiDoom.Gui.Types in '..\Libs\Gui\DelphiDoom.Gui.Types.pas',
  DelphiDoom.Gui.Intf in '..\Libs\Gui\DelphiDoom.Gui.Intf.pas',
  DelphiDoom.Gui.DeviceContext.Intf in '..\Libs\Gui\DelphiDoom.Gui.DeviceContext.Intf.pas',
  DelphiDoom.Gui.StringPool in '..\Libs\Gui\DelphiDoom.Gui.StringPool.pas',
  DelphiDoom.Gui.PrecompilerSource in '..\Libs\Gui\DelphiDoom.Gui.PrecompilerSource.pas',
  DelphiDoom.Gui.PrecompilerLoader in '..\Libs\Gui\DelphiDoom.Gui.PrecompilerLoader.pas',
  DelphiDoom.Gui.IdLibLog in '..\Libs\Gui\DelphiDoom.Gui.IdLibLog.pas',
  DelphiDoom.Gui.ValueReader in '..\Libs\Gui\DelphiDoom.Gui.ValueReader.pas',
  DelphiDoom.Gui.Font.Types in '..\Libs\Gui\DelphiDoom.Gui.Font.Types.pas',
  DelphiDoom.Gui.Font in '..\Libs\Gui\DelphiDoom.Gui.Font.pas',
  DelphiDoom.Gui.FontReader in '..\Libs\Gui\DelphiDoom.Gui.FontReader.pas',
  DelphiDoom.Gui.FontRegistry in '..\Libs\Gui\DelphiDoom.Gui.FontRegistry.pas',
  DelphiDoom.Gui.Assets in '..\Libs\Gui\DelphiDoom.Gui.Assets.pas',
  DelphiDoom.Gui.Menu in '..\Libs\Gui\DelphiDoom.Gui.Menu.pas',
  DelphiDoom.Gui.ItemParser in '..\Libs\Gui\DelphiDoom.Gui.ItemParser.pas',
  DelphiDoom.Gui.MenuParser in '..\Libs\Gui\DelphiDoom.Gui.MenuParser.pas',
  DelphiDoom.Gui.MenuSet in '..\Libs\Gui\DelphiDoom.Gui.MenuSet.pas',
  DelphiDoom.Gui.AssetParser in '..\Libs\Gui\DelphiDoom.Gui.AssetParser.pas',
  DelphiDoom.Gui.MenuFileReader in '..\Libs\Gui\DelphiDoom.Gui.MenuFileReader.pas',
  DelphiDoom.Gui.ScriptCursor in '..\Libs\Gui\DelphiDoom.Gui.ScriptCursor.pas',
  DelphiDoom.Gui.ScriptRunner in '..\Libs\Gui\DelphiDoom.Gui.ScriptRunner.pas',
  DelphiDoom.Gui.Factory in '..\Libs\Gui\DelphiDoom.Gui.Factory.pas',
  DelphiDoom.Gui.Rectangle in '..\Libs\Gui\DelphiDoom.Gui.Rectangle.pas',
  DelphiDoom.Gui.UncountedObject in '..\Libs\Gui\DelphiDoom.Gui.UncountedObject.pas',
  DelphiDoom.Gui.Interpolator in '..\Libs\Gui\DelphiDoom.Gui.Interpolator.pas',
  DelphiDoom.Gui.Window.Types in '..\Libs\Gui\DelphiDoom.Gui.Window.Types.pas',
  DelphiDoom.Gui.WinVar.Base in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Base.pas',
  DelphiDoom.Gui.WinVar.Bool in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Bool.pas',
  DelphiDoom.Gui.WinVar.Int in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Int.pas',
  DelphiDoom.Gui.WinVar.Float in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Float.pas',
  DelphiDoom.Gui.WinVar.Str in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Str.pas',
  DelphiDoom.Gui.WinVar.Background in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Background.pas',
  DelphiDoom.Gui.WinVar.Vec2 in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Vec2.pas',
  DelphiDoom.Gui.WinVar.Vec3 in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Vec3.pas',
  DelphiDoom.Gui.WinVar.Vec4 in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Vec4.pas',
  DelphiDoom.Gui.WinVar.Rectangle in '..\Libs\Gui\DelphiDoom.Gui.WinVar.Rectangle.pas',
  DelphiDoom.Gui.Regs.Types in '..\Libs\Gui\DelphiDoom.Gui.Regs.Types.pas',
  DelphiDoom.Gui.Regs.Intf in '..\Libs\Gui\DelphiDoom.Gui.Regs.Intf.pas',
  DelphiDoom.Gui.Regs.Register in '..\Libs\Gui\DelphiDoom.Gui.Regs.Register.pas',
  DelphiDoom.Gui.Regs.RegisterList in '..\Libs\Gui\DelphiDoom.Gui.Regs.RegisterList.pas',
  DelphiDoom.Gui.Regs.Store in '..\Libs\Gui\DelphiDoom.Gui.Regs.Store.pas',
  DelphiDoom.Gui.Regs.Evaluator in '..\Libs\Gui\DelphiDoom.Gui.Regs.Evaluator.pas',
  DelphiDoom.Gui.Regs.Parser in '..\Libs\Gui\DelphiDoom.Gui.Regs.Parser.pas',
  DelphiDoom.Gui.Window.Intf in '..\Libs\Gui\DelphiDoom.Gui.Window.Intf.pas',
  DelphiDoom.Gui.Script in '..\Libs\Gui\DelphiDoom.Gui.Script.pas',
  DelphiDoom.Gui.Script.Parser in '..\Libs\Gui\DelphiDoom.Gui.Script.Parser.pas',
  DelphiDoom.Gui.Window.TimeLineEvent in '..\Libs\Gui\DelphiDoom.Gui.Window.TimeLineEvent.pas',
  DelphiDoom.Gui.Window.NamedEvent in '..\Libs\Gui\DelphiDoom.Gui.Window.NamedEvent.pas',
  DelphiDoom.Gui.Window.Transition in '..\Libs\Gui\DelphiDoom.Gui.Window.Transition.pas',
  DelphiDoom.Gui.Context in '..\Libs\Gui\DelphiDoom.Gui.Context.pas',
  DelphiDoom.Gui.Window in '..\Libs\Gui\DelphiDoom.Gui.Window.pas',
  DelphiDoom.Gui.Window.Choice in '..\Libs\Gui\DelphiDoom.Gui.Window.Choice.pas',
  DelphiDoom.Gui.Window.Edit in '..\Libs\Gui\DelphiDoom.Gui.Window.Edit.pas',
  DelphiDoom.Gui.Window.List in '..\Libs\Gui\DelphiDoom.Gui.Window.List.pas',
  DelphiDoom.Gui.Window.Slider in '..\Libs\Gui\DelphiDoom.Gui.Window.Slider.pas',
  DelphiDoom.Gui.Window.Bind in '..\Libs\Gui\DelphiDoom.Gui.Window.Bind.pas',
  DelphiDoom.Gui.Window.Render in '..\Libs\Gui\DelphiDoom.Gui.Window.Render.pas',
  DelphiDoom.Gui.Window.Marker in '..\Libs\Gui\DelphiDoom.Gui.Window.Marker.pas',
  DelphiDoom.Gui.Window.Field in '..\Libs\Gui\DelphiDoom.Gui.Window.Field.pas',
  DelphiDoom.Gui.Window.Factory in '..\Libs\Gui\DelphiDoom.Gui.Window.Factory.pas',
  DelphiDoom.Gui.UserInterface in '..\Libs\Gui\DelphiDoom.Gui.UserInterface.pas',
  DelphiDoom.Tests.Gui.Fakes in 'Source\DelphiDoom.Tests.Gui.Fakes.pas',
  DelphiDoom.Tests.Gui.WindowFakes in 'Source\DelphiDoom.Tests.Gui.WindowFakes.pas',
  DelphiDoom.Tests.Gui.WindowDump in 'Source\DelphiDoom.Tests.Gui.WindowDump.pas',
  DelphiDoom.Tests.Gui.WinVars in 'Source\DelphiDoom.Tests.Gui.WinVars.pas',
  DelphiDoom.Tests.Gui.Expressions in 'Source\DelphiDoom.Tests.Gui.Expressions.pas',
  DelphiDoom.Tests.Gui.WindowScripts in 'Source\DelphiDoom.Tests.Gui.WindowScripts.pas',
  DelphiDoom.Tests.Gui.Windows in 'Source\DelphiDoom.Tests.Gui.Windows.pas',
  DelphiDoom.Tests.Gui.WindowParity in 'Source\DelphiDoom.Tests.Gui.WindowParity.pas',
  DelphiDoom.Tests.Gui.Scenario in 'Source\DelphiDoom.Tests.Gui.Scenario.pas',
  DelphiDoom.Tests.Gui.Parity in 'Source\DelphiDoom.Tests.Gui.Parity.pas',
  DelphiDoom.Tests.Gui.Reading in 'Source\DelphiDoom.Tests.Gui.Reading.pas',
  DelphiDoom.Tests.Gui.Scripts in 'Source\DelphiDoom.Tests.Gui.Scripts.pas',
  DelphiDoom.Tests.Gui.Fonts in 'Source\DelphiDoom.Tests.Gui.Fonts.pas',
  DelphiDoom.Tests.Gui.Model in 'Source\DelphiDoom.Tests.Gui.Model.pas',
  DelphiDoom.Tests.Gui.Parsers in 'Source\DelphiDoom.Tests.Gui.Parsers.pas',
  DelphiDoom.Tests.Gui.OpenArena in 'Source\DelphiDoom.Tests.Gui.OpenArena.pas';

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
