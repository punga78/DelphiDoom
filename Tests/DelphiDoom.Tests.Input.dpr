{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the input library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Input;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Framework\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Framework\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Framework\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Input.Types in '..\Framework\Input\DelphiDoom.Input.Types.pas',
  DelphiDoom.Input.Intf in '..\Framework\Input\DelphiDoom.Input.Intf.pas',
  DelphiDoom.Input.Poller in '..\Framework\Input\DelphiDoom.Input.Poller.pas',
  DelphiDoom.Input.WindowsKeyboard in '..\Framework\Input\DelphiDoom.Input.WindowsKeyboard.pas',
  DelphiDoom.Input.WindowsMouse in '..\Framework\Input\DelphiDoom.Input.WindowsMouse.pas',
  DelphiDoom.Input.WindowsJoystick in '..\Framework\Input\DelphiDoom.Input.WindowsJoystick.pas',
  DelphiDoom.Input.WindowsSystem in '..\Framework\Input\DelphiDoom.Input.WindowsSystem.pas',
  DelphiDoom.Input.Factory in '..\Framework\Input\DelphiDoom.Input.Factory.pas',
  DelphiDoom.Input.KeyboardLayout in '..\Framework\Input\DelphiDoom.Input.KeyboardLayout.pas',
  DelphiDoom.Input.EventScaling in '..\Framework\Input\DelphiDoom.Input.EventScaling.pas',
  DelphiDoom.Input.KeyNames in '..\Framework\Input\DelphiDoom.Input.KeyNames.pas',
  DelphiDoom.Tests.Input.Fakes in 'Source\DelphiDoom.Tests.Input.Fakes.pas',
  DelphiDoom.Tests.Input.Poller in 'Source\DelphiDoom.Tests.Input.Poller.pas',
  DelphiDoom.Tests.Input.Devices in 'Source\DelphiDoom.Tests.Input.Devices.pas',
  DelphiDoom.Tests.Input.WindowsSystem in 'Source\DelphiDoom.Tests.Input.WindowsSystem.pas',
  DelphiDoom.Tests.Input.KeyboardLayout in 'Source\DelphiDoom.Tests.Input.KeyboardLayout.pas',
  DelphiDoom.Tests.Input.EventScaling in 'Source\DelphiDoom.Tests.Input.EventScaling.pas',
  DelphiDoom.Tests.Input.KeyNames in 'Source\DelphiDoom.Tests.Input.KeyNames.pas';

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
