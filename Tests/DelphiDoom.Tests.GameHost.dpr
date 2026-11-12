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
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.GameHost.Types in '..\Libs\GameHost\DelphiDoom.GameHost.Types.pas',
  DelphiDoom.GameHost.Video.Intf in '..\Libs\GameHost\DelphiDoom.GameHost.Video.Intf.pas',
  DelphiDoom.GameHost.Events.Intf in '..\Libs\GameHost\DelphiDoom.GameHost.Events.Intf.pas',
  DelphiDoom.GameHost.PictureLayout in '..\Libs\GameHost\DelphiDoom.GameHost.PictureLayout.pas',
  DelphiDoom.GameHost.KeyState in '..\Libs\GameHost\DelphiDoom.GameHost.KeyState.pas',
  DelphiDoom.GameHost.VideoDeviceSelector in '..\Libs\GameHost\DelphiDoom.GameHost.VideoDeviceSelector.pas',
  DelphiDoom.GameHost.Win.Keyboard in '..\Libs\GameHost\DelphiDoom.GameHost.Win.Keyboard.pas',
  DelphiDoom.GameHost.Win.MessageTranslator in '..\Libs\GameHost\DelphiDoom.GameHost.Win.MessageTranslator.pas',
  DelphiDoom.GameHost.Win.Window in '..\Libs\GameHost\DelphiDoom.GameHost.Win.Window.pas',
  DelphiDoom.GameHost.Win.WindowDevice in '..\Libs\GameHost\DelphiDoom.GameHost.Win.WindowDevice.pas',
  DelphiDoom.GameHost.Win.GdiVideoDevice in '..\Libs\GameHost\DelphiDoom.GameHost.Win.GdiVideoDevice.pas',
  DelphiDoom.GameHost.Audio.Intf in '..\Libs\GameHost\DelphiDoom.GameHost.Audio.Intf.pas',
  DelphiDoom.GameHost.Win.PcmOutput in '..\Libs\GameHost\DelphiDoom.GameHost.Win.PcmOutput.pas',
  DelphiDoom.GameHost.Factory in '..\Libs\GameHost\DelphiDoom.GameHost.Factory.pas',
  DelphiDoom.Tests.GameHost.Fakes in 'Source\DelphiDoom.Tests.GameHost.Fakes.pas',
  DelphiDoom.Tests.GameHost.PictureLayout in 'Source\DelphiDoom.Tests.GameHost.PictureLayout.pas',
  DelphiDoom.Tests.GameHost.MessageTranslator in 'Source\DelphiDoom.Tests.GameHost.MessageTranslator.pas',
  DelphiDoom.Tests.GameHost.VideoDeviceSelector in 'Source\DelphiDoom.Tests.GameHost.VideoDeviceSelector.pas';

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
