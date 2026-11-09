{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the OPL2 library and the X-COM Adlib player        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the chip is derived from fmopl.c, LGPL 2.1 or later; the player from        }
{  OpenXcom, GPL v3 or later: see Libs\Opl\README.md)                           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Opl;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Xcom.Types in '..\Libs\XcomFormats\DelphiDoom.Xcom.Types.pas',
  DelphiDoom.Xcom.Intf in '..\Libs\XcomFormats\DelphiDoom.Xcom.Intf.pas',
  DelphiDoom.Xcom.CatArchive in '..\Libs\XcomFormats\DelphiDoom.Xcom.CatArchive.pas',
  DelphiDoom.Opl.Types in '..\Libs\Opl\DelphiDoom.Opl.Types.pas',
  DelphiDoom.Opl.Intf in '..\Libs\Opl\DelphiDoom.Opl.Intf.pas',
  DelphiDoom.Opl.Tables in '..\Libs\Opl\DelphiDoom.Opl.Tables.pas',
  DelphiDoom.Opl.Noise in '..\Libs\Opl\DelphiDoom.Opl.Noise.pas',
  DelphiDoom.Opl.Chip in '..\Libs\Opl\DelphiDoom.Opl.Chip.pas',
  DelphiDoom.Opl.Factory in '..\Libs\Opl\DelphiDoom.Opl.Factory.pas',
  DelphiDoom.XcomAdlib.Types in '..\Libs\Opl\DelphiDoom.XcomAdlib.Types.pas',
  DelphiDoom.XcomAdlib.Intf in '..\Libs\Opl\DelphiDoom.XcomAdlib.Intf.pas',
  DelphiDoom.XcomAdlib.RegisterWriter in '..\Libs\Opl\DelphiDoom.XcomAdlib.RegisterWriter.pas',
  DelphiDoom.XcomAdlib.Sequencer in '..\Libs\Opl\DelphiDoom.XcomAdlib.Sequencer.pas',
  DelphiDoom.XcomAdlib.Player in '..\Libs\Opl\DelphiDoom.XcomAdlib.Player.pas',
  DelphiDoom.XcomAdlib.CatSource in '..\Libs\Opl\DelphiDoom.XcomAdlib.CatSource.pas',
  DelphiDoom.XcomAdlib.Factory in '..\Libs\Opl\DelphiDoom.XcomAdlib.Factory.pas',
  DelphiDoom.Tests.Opl.Recorder in 'Source\DelphiDoom.Tests.Opl.Recorder.pas',
  DelphiDoom.Tests.Opl.Script in 'Source\DelphiDoom.Tests.Opl.Script.pas',
  DelphiDoom.Tests.Opl.Golden in 'Source\DelphiDoom.Tests.Opl.Golden.pas',
  DelphiDoom.Tests.Opl.Chip in 'Source\DelphiDoom.Tests.Opl.Chip.pas',
  DelphiDoom.Tests.Opl.Player in 'Source\DelphiDoom.Tests.Opl.Player.pas';

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
