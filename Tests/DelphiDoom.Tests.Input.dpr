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
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Libs\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Libs\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Libs\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Input.Types in '..\Libs\Input\DelphiDoom.Input.Types.pas',
  DelphiDoom.Input.Intf in '..\Libs\Input\DelphiDoom.Input.Intf.pas',
  DelphiDoom.Input.Poller in '..\Libs\Input\DelphiDoom.Input.Poller.pas',
  DelphiDoom.Input.WindowsKeyboard in '..\Libs\Input\DelphiDoom.Input.WindowsKeyboard.pas',
  DelphiDoom.Input.WindowsMouse in '..\Libs\Input\DelphiDoom.Input.WindowsMouse.pas',
  DelphiDoom.Input.WindowsJoystick in '..\Libs\Input\DelphiDoom.Input.WindowsJoystick.pas',
  DelphiDoom.Input.Factory in '..\Libs\Input\DelphiDoom.Input.Factory.pas',
  DelphiDoom.Tests.Input.Fakes in 'Source\DelphiDoom.Tests.Input.Fakes.pas',
  DelphiDoom.Tests.Input.Poller in 'Source\DelphiDoom.Tests.Input.Poller.pas';

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
