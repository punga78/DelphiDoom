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
  DelphiDoom.Palette.Types in '..\Framework\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.Intf in '..\Framework\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Video.Types in '..\Framework\Video\DelphiDoom.Video.Types.pas',
  DelphiDoom.Video.Intf in '..\Framework\Video\DelphiDoom.Video.Intf.pas',
  DelphiDoom.Palette.Converter in '..\Framework\Palette\DelphiDoom.Palette.Converter.pas',
  DelphiDoom.Palette.ScreenPalette in '..\Framework\Palette\DelphiDoom.Palette.ScreenPalette.pas',
  DelphiDoom.Video.PreserveTables in '..\Framework\Video\DelphiDoom.Video.PreserveTables.pas',
  DelphiDoom.Video.ScreenLayout in '..\Framework\Video\DelphiDoom.Video.ScreenLayout.pas',
  DelphiDoom.Video.TileGrid in '..\Framework\Video\DelphiDoom.Video.TileGrid.pas',
  DelphiDoom.Video.PageLayout in '..\Framework\Video\DelphiDoom.Video.PageLayout.pas',
  DelphiDoom.Video.BlitSlices in '..\Framework\Video\DelphiDoom.Video.BlitSlices.pas',
  DelphiDoom.Video.Stretch in '..\Framework\Video\DelphiDoom.Video.Stretch.pas',
  DelphiDoom.Video.ScreenOps in '..\Framework\Video\DelphiDoom.Video.ScreenOps.pas',
  DelphiDoom.Video.PatchPainter in '..\Framework\Video\DelphiDoom.Video.PatchPainter.pas',
  DelphiDoom.Video.PatchPainter32 in '..\Framework\Video\DelphiDoom.Video.PatchPainter32.pas',
  DelphiDoom.Video.PatchZoomer in '..\Framework\Video\DelphiDoom.Video.PatchZoomer.pas',
  DelphiDoom.Video.RectCopy in '..\Framework\Video\DelphiDoom.Video.RectCopy.pas',
  DelphiDoom.Video.SizeLimiter in '..\Framework\Video\DelphiDoom.Video.SizeLimiter.pas',
  DelphiDoom.Video.MemoryStallHack in '..\Framework\Video\DelphiDoom.Video.MemoryStallHack.pas',
  DelphiDoom.Video.WindowsDisplayMetrics in '..\Framework\Video\DelphiDoom.Video.WindowsDisplayMetrics.pas',
  DelphiDoom.Video.DisplayModeCatalog in '..\Framework\Video\DelphiDoom.Video.DisplayModeCatalog.pas',
  DelphiDoom.Video.WindowsDisplayModeSource in '..\Framework\Video\DelphiDoom.Video.WindowsDisplayModeSource.pas',
  DelphiDoom.Video.Services in '..\Framework\Video\DelphiDoom.Video.Services.pas',
  DelphiDoom.Video.DeferredNotifications in '..\Framework\Video\DelphiDoom.Video.DeferredNotifications.pas',
  DelphiDoom.Video.ModeChanger.Intf in '..\Framework\Video\DelphiDoom.Video.ModeChanger.Intf.pas',
  DelphiDoom.Video.ModeChanger in '..\Framework\Video\DelphiDoom.Video.ModeChanger.pas',
  DelphiDoom.Video.StandardResolutions in '..\Framework\Video\DelphiDoom.Video.StandardResolutions.pas',
  DelphiDoom.Video.Factory in '..\Framework\Video\DelphiDoom.Video.Factory.pas',
  DelphiDoom.CommandLine.Intf in '..\Framework\CommandLine\DelphiDoom.CommandLine.Intf.pas',
  DelphiDoom.Video.ScreenSizeResolver in '..\Framework\Video\DelphiDoom.Video.ScreenSizeResolver.pas',
  DelphiDoom.Tests.Video.PreserveTables in 'Source\DelphiDoom.Tests.Video.PreserveTables.pas',
  DelphiDoom.Tests.Video.TileGrid in 'Source\DelphiDoom.Tests.Video.TileGrid.pas',
  DelphiDoom.Tests.Video.PageLayout in 'Source\DelphiDoom.Tests.Video.PageLayout.pas',
  DelphiDoom.Tests.Video.BlitSlices in 'Source\DelphiDoom.Tests.Video.BlitSlices.pas',
  DelphiDoom.Tests.Video.ModeChanger in 'Source\DelphiDoom.Tests.Video.ModeChanger.pas',
  DelphiDoom.Tests.Video.StandardResolutions in 'Source\DelphiDoom.Tests.Video.StandardResolutions.pas',
  DelphiDoom.Tests.Video.Stretch in 'Source\DelphiDoom.Tests.Video.Stretch.pas',
  DelphiDoom.Tests.Video.ScreenOps in 'Source\DelphiDoom.Tests.Video.ScreenOps.pas',
  DelphiDoom.Tests.Video.PatchPainter in 'Source\DelphiDoom.Tests.Video.PatchPainter.pas',
  DelphiDoom.Tests.Video.PatchKernels in 'Source\DelphiDoom.Tests.Video.PatchKernels.pas',
  DelphiDoom.Tests.Video.RectCopy in 'Source\DelphiDoom.Tests.Video.RectCopy.pas',
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
