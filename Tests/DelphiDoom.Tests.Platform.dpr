{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the platform library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Platform;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Platform.Types in '..\Framework\Platform\DelphiDoom.Platform.Types.pas',
  DelphiDoom.Platform.Intf in '..\Framework\Platform\DelphiDoom.Platform.Intf.pas',
  DelphiDoom.Platform.FileStore in '..\Framework\Platform\DelphiDoom.Platform.FileStore.pas',
  DelphiDoom.Platform.TempFiles in '..\Framework\Platform\DelphiDoom.Platform.TempFiles.pas',
  DelphiDoom.Platform.WindowsVersionSource in '..\Framework\Platform\DelphiDoom.Platform.WindowsVersionSource.pas',
  DelphiDoom.Platform.OperatingSystemInfo in '..\Framework\Platform\DelphiDoom.Platform.OperatingSystemInfo.pas',
  DelphiDoom.Platform.WindowsCpuInfo in '..\Framework\Platform\DelphiDoom.Platform.WindowsCpuInfo.pas',
  DelphiDoom.Platform.PeImageReader in '..\Framework\Platform\DelphiDoom.Platform.PeImageReader.pas',
  DelphiDoom.Platform.ExecutableInfo in '..\Framework\Platform\DelphiDoom.Platform.ExecutableInfo.pas',
  DelphiDoom.Platform.WindowsDriveInfo in '..\Framework\Platform\DelphiDoom.Platform.WindowsDriveInfo.pas',
  DelphiDoom.Platform.WindowsDisplayDpi in '..\Framework\Platform\DelphiDoom.Platform.WindowsDisplayDpi.pas',
  DelphiDoom.Platform.WindowsThreadPriority in '..\Framework\Platform\DelphiDoom.Platform.WindowsThreadPriority.pas',
  DelphiDoom.Platform.Services in '..\Framework\Platform\DelphiDoom.Platform.Services.pas',
  DelphiDoom.Platform.Factory in '..\Framework\Platform\DelphiDoom.Platform.Factory.pas',
  DelphiDoom.Platform.FolderFiles.Intf in '..\Framework\Platform\DelphiDoom.Platform.FolderFiles.Intf.pas',
  DelphiDoom.Platform.FolderFiles in '..\Framework\Platform\DelphiDoom.Platform.FolderFiles.pas',
  DelphiDoom.Platform.FolderFiles.Factory in '..\Framework\Platform\DelphiDoom.Platform.FolderFiles.Factory.pas',
  DelphiDoom.Platform.DataFolder.Intf in '..\Framework\Platform\DelphiDoom.Platform.DataFolder.Intf.pas',
  DelphiDoom.Platform.DataFolder in '..\Framework\Platform\DelphiDoom.Platform.DataFolder.pas',
  DelphiDoom.Platform.DataFolder.Disk in '..\Framework\Platform\DelphiDoom.Platform.DataFolder.Disk.pas',
  DelphiDoom.Platform.DataFolder.Factory in '..\Framework\Platform\DelphiDoom.Platform.DataFolder.Factory.pas',
  DelphiDoom.Tests.Platform.Fakes in 'Source\DelphiDoom.Tests.Platform.Fakes.pas',
  DelphiDoom.Tests.Platform.TempFiles in 'Source\DelphiDoom.Tests.Platform.TempFiles.pas',
  DelphiDoom.Tests.Platform.FileStore in 'Source\DelphiDoom.Tests.Platform.FileStore.pas',
  DelphiDoom.Tests.Platform.DataFolder in 'Source\DelphiDoom.Tests.Platform.DataFolder.pas',
  DelphiDoom.Tests.Platform.FolderFiles in 'Source\DelphiDoom.Tests.Platform.FolderFiles.pas',
  DelphiDoom.Tests.Platform.OperatingSystemInfo in 'Source\DelphiDoom.Tests.Platform.OperatingSystemInfo.pas',
  DelphiDoom.Tests.Platform.PeImageReader in 'Source\DelphiDoom.Tests.Platform.PeImageReader.pas',
  DelphiDoom.Tests.Platform.ExecutableInfo in 'Source\DelphiDoom.Tests.Platform.ExecutableInfo.pas',
  DelphiDoom.Tests.Platform.Machine in 'Source\DelphiDoom.Tests.Platform.Machine.pas';

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
