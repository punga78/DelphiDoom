{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the video library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Video;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Video.Types in '..\Libs\Video\DelphiDoom.Video.Types.pas',
  DelphiDoom.Video.Intf in '..\Libs\Video\DelphiDoom.Video.Intf.pas',
  DelphiDoom.Video.PaletteConverter in '..\Libs\Video\DelphiDoom.Video.PaletteConverter.pas',
  DelphiDoom.Video.SizeLimiter in '..\Libs\Video\DelphiDoom.Video.SizeLimiter.pas',
  DelphiDoom.Video.MemoryStallHack in '..\Libs\Video\DelphiDoom.Video.MemoryStallHack.pas',
  DelphiDoom.Video.WindowsDisplayMetrics in '..\Libs\Video\DelphiDoom.Video.WindowsDisplayMetrics.pas',
  DelphiDoom.Video.DisplayModeCatalog in '..\Libs\Video\DelphiDoom.Video.DisplayModeCatalog.pas',
  DelphiDoom.Video.WindowsDisplayModeSource in '..\Libs\Video\DelphiDoom.Video.WindowsDisplayModeSource.pas',
  DelphiDoom.Video.Services in '..\Libs\Video\DelphiDoom.Video.Services.pas',
  DelphiDoom.Video.DeferredNotifications in '..\Libs\Video\DelphiDoom.Video.DeferredNotifications.pas',
  DelphiDoom.Video.Factory in '..\Libs\Video\DelphiDoom.Video.Factory.pas',
  DelphiDoom.CommandLine.Intf in '..\Libs\CommandLine\DelphiDoom.CommandLine.Intf.pas',
  DelphiDoom.Video.ScreenSizeResolver in '..\Libs\Video\DelphiDoom.Video.ScreenSizeResolver.pas',
  DelphiDoom.Tests.Video.ScreenSizeResolver in 'Source\DelphiDoom.Tests.Video.ScreenSizeResolver.pas',
  DelphiDoom.Tests.Video.Services in 'Source\DelphiDoom.Tests.Video.Services.pas',
  DelphiDoom.Tests.Video.DisplayModeCatalog in 'Source\DelphiDoom.Tests.Video.DisplayModeCatalog.pas',
  DelphiDoom.Tests.Video.WindowsDisplayModeSource in 'Source\DelphiDoom.Tests.Video.WindowsDisplayModeSource.pas',
  DelphiDoom.Tests.Video.DeferredNotifications in 'Source\DelphiDoom.Tests.Video.DeferredNotifications.pas';

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
