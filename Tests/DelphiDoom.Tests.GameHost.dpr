{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the game host library (DUnitX)                     }
{  No window is made: the messages are made up and the displays are fakes       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.GameHost;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.GameHost.Types in '..\Framework\GameHost\DelphiDoom.GameHost.Types.pas',
  DelphiDoom.GameHost.Video.Intf in '..\Framework\GameHost\DelphiDoom.GameHost.Video.Intf.pas',
  DelphiDoom.GameHost.Events.Intf in '..\Framework\GameHost\DelphiDoom.GameHost.Events.Intf.pas',
  DelphiDoom.GameHost.PictureLayout in '..\Framework\GameHost\DelphiDoom.GameHost.PictureLayout.pas',
  DelphiDoom.GameHost.KeyState in '..\Framework\GameHost\DelphiDoom.GameHost.KeyState.pas',
  DelphiDoom.GameHost.VideoDeviceSelector in '..\Framework\GameHost\DelphiDoom.GameHost.VideoDeviceSelector.pas',
  DelphiDoom.GameHost.Win.Keyboard in '..\Framework\GameHost\DelphiDoom.GameHost.Win.Keyboard.pas',
  DelphiDoom.GameHost.Win.MessageTranslator in '..\Framework\GameHost\DelphiDoom.GameHost.Win.MessageTranslator.pas',
  DelphiDoom.GameHost.Win.Window in '..\Framework\GameHost\DelphiDoom.GameHost.Win.Window.pas',
  DelphiDoom.GameHost.Win.WindowDevice in '..\Framework\GameHost\DelphiDoom.GameHost.Win.WindowDevice.pas',
  DelphiDoom.GameHost.Win.GdiVideoDevice in '..\Framework\GameHost\DelphiDoom.GameHost.Win.GdiVideoDevice.pas',
  DelphiDoom.GameHost.Audio.Intf in '..\Framework\GameHost\DelphiDoom.GameHost.Audio.Intf.pas',
  DelphiDoom.GameHost.Win.PcmOutput in '..\Framework\GameHost\DelphiDoom.GameHost.Win.PcmOutput.pas',
  DelphiDoom.GameHost.Factory in '..\Framework\GameHost\DelphiDoom.GameHost.Factory.pas',
  DelphiDoom.Tests.GameHost.Fakes in 'Source\DelphiDoom.Tests.GameHost.Fakes.pas',
  DelphiDoom.Tests.GameHost.PictureLayout in 'Source\DelphiDoom.Tests.GameHost.PictureLayout.pas',
  DelphiDoom.Tests.GameHost.MessageTranslator in 'Source\DelphiDoom.Tests.GameHost.MessageTranslator.pas',
  DelphiDoom.Tests.GameHost.VideoDeviceSelector in 'Source\DelphiDoom.Tests.GameHost.VideoDeviceSelector.pas',
  DelphiDoom.GameHost.Win.GdiBlitter in '..\Framework\GameHost\DelphiDoom.GameHost.Win.GdiBlitter.pas',
  DelphiDoom.Engine.Video.FramePresenter.Intf in '..\Base\DelphiDoom.Engine.Video.FramePresenter.Intf.pas',
  DelphiDoom.Engine.Video.GdiPresenter in '..\Base\DelphiDoom.Engine.Video.GdiPresenter.pas',
  DelphiDoom.Tests.GameHost.GdiBlitter in 'Source\DelphiDoom.Tests.GameHost.GdiBlitter.pas',
  DelphiDoom.Tests.GameHost.EngineGdiPresenter in 'Source\DelphiDoom.Tests.GameHost.EngineGdiPresenter.pas',
  DelphiDoom.GameHost.KeyLatch in '..\Framework\GameHost\DelphiDoom.GameHost.KeyLatch.pas',
  DelphiDoom.Tests.GameHost.KeyLatch in 'Source\DelphiDoom.Tests.GameHost.KeyLatch.pas',
  DelphiDoom.GameHost.MouseState in '..\Framework\GameHost\DelphiDoom.GameHost.MouseState.pas',
  DelphiDoom.GameHost.EventFanOut in '..\Framework\GameHost\DelphiDoom.GameHost.EventFanOut.pas',
  DelphiDoom.GameHost.Win.CursorArea in '..\Framework\GameHost\DelphiDoom.GameHost.Win.CursorArea.pas',
  DelphiDoom.Tests.GameHost.MouseState in 'Source\DelphiDoom.Tests.GameHost.MouseState.pas',
  DelphiDoom.Input.Types in '..\Framework\Input\DelphiDoom.Input.Types.pas',
  DelphiDoom.Input.Intf in '..\Framework\Input\DelphiDoom.Input.Intf.pas',
  DelphiDoom.GameHost.WindowMouse in '..\Framework\GameHost\DelphiDoom.GameHost.WindowMouse.pas',
  DelphiDoom.Tests.GameHost.WindowMouse in 'Source\DelphiDoom.Tests.GameHost.WindowMouse.pas',
  DelphiDoom.GameHost.ForegroundGate in '..\Framework\GameHost\DelphiDoom.GameHost.ForegroundGate.pas',
  DelphiDoom.Tests.GameHost.ForegroundGate in 'Source\DelphiDoom.Tests.GameHost.ForegroundGate.pas';

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
