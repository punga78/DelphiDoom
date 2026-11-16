{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Wad library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Wad;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Wad.Types in '..\Framework\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Name in '..\Framework\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Text in '..\Framework\Wad\DelphiDoom.Wad.Text.pas',
  DelphiDoom.Wad.FileBase in '..\Framework\Wad\DelphiDoom.Wad.FileBase.pas',
  DelphiDoom.Wad.Intf in '..\Framework\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Indicators in '..\Framework\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\Framework\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Source.Wad in '..\Framework\Wad\DelphiDoom.Wad.Source.Wad.pas',
  DelphiDoom.Wad.Source.Wad2 in '..\Framework\Wad\DelphiDoom.Wad.Source.Wad2.pas',
  DelphiDoom.Wad.Source.Pak in '..\Framework\Wad\DelphiDoom.Wad.Source.Pak.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Framework\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Source.Zip in '..\Framework\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Wad.Source.Folder in '..\Framework\Wad\DelphiDoom.Wad.Source.Folder.pas',
  DelphiDoom.Wad.Source.SingleFile in '..\Framework\Wad\DelphiDoom.Wad.Source.SingleFile.pas',
  DelphiDoom.Wad.Directory in '..\Framework\Wad\DelphiDoom.Wad.Directory.pas',
  DelphiDoom.Wad.Builder in '..\Framework\Wad\DelphiDoom.Wad.Builder.pas',
  DelphiDoom.Wad.LumpCache in '..\Framework\Wad\DelphiDoom.Wad.LumpCache.pas',
  DelphiDoom.Wad.Level.Types in '..\Framework\Wad\DelphiDoom.Wad.Level.Types.pas',
  DelphiDoom.Wad.Pak.Types in '..\Framework\Wad\DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Pak.Intf in '..\Framework\Wad\DelphiDoom.Wad.Pak.Intf.pas',
  DelphiDoom.Wad.Pak.Names in '..\Framework\Wad\DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Wad.Pak.GameDirectories in '..\Framework\Wad\DelphiDoom.Wad.Pak.GameDirectories.pas',
  DelphiDoom.Wad.Pak.Index in '..\Framework\Wad\DelphiDoom.Wad.Pak.Index.pas',
  DelphiDoom.Wad.Pak.PathResolver in '..\Framework\Wad\DelphiDoom.Wad.Pak.PathResolver.pas',
  DelphiDoom.Wad.Factory in '..\Framework\Wad\DelphiDoom.Wad.Factory.pas',
  DelphiDoom.IdLib.Hashing.Types in '..\Framework\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Types.pas',
  DelphiDoom.IdLib.Hashing.Md4 in '..\Framework\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Md4.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Core.Intf in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Intf.pas',
  DelphiDoom.IdLib.Core.Exceptions in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Text.Types in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Types.pas',
  DelphiDoom.IdLib.Text.Token in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Token.pas',
  DelphiDoom.IdLib.Text.Str in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Str.pas',
  DelphiDoom.IdLib.Text.Lexer in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Lexer.pas',
  DelphiDoom.Wad.Fs.Types in '..\Framework\Wad\DelphiDoom.Wad.Fs.Types.pas',
  DelphiDoom.Wad.Fs.Intf in '..\Framework\Wad\DelphiDoom.Wad.Fs.Intf.pas',
  DelphiDoom.Wad.Fs.Write.Intf in '..\Framework\Wad\DelphiDoom.Wad.Fs.Write.Intf.pas',
  DelphiDoom.Wad.Fs.ModList.Intf in '..\Framework\Wad\DelphiDoom.Wad.Fs.ModList.Intf.pas',
  DelphiDoom.Wad.Fs.PureServer.Intf in '..\Framework\Wad\DelphiDoom.Wad.Fs.PureServer.Intf.pas',
  DelphiDoom.Wad.Fs.Paths in '..\Framework\Wad\DelphiDoom.Wad.Fs.Paths.pas',
  DelphiDoom.Wad.Fs.AddonParser in '..\Framework\Wad\DelphiDoom.Wad.Fs.AddonParser.pas',
  DelphiDoom.Wad.Fs.DiskWriter in '..\Framework\Wad\DelphiDoom.Wad.Fs.DiskWriter.pas',
  DelphiDoom.Wad.Fs.WriteFile in '..\Framework\Wad\DelphiDoom.Wad.Fs.WriteFile.pas',
  DelphiDoom.Wad.Fs.Writer in '..\Framework\Wad\DelphiDoom.Wad.Fs.Writer.pas',
  DelphiDoom.Wad.Fs.ModLister in '..\Framework\Wad\DelphiDoom.Wad.Fs.ModLister.pas',
  DelphiDoom.Wad.Fs.PackStatus in '..\Framework\Wad\DelphiDoom.Wad.Fs.PackStatus.pas',
  DelphiDoom.Wad.Fs.PureServer in '..\Framework\Wad\DelphiDoom.Wad.Fs.PureServer.pas',
  DelphiDoom.Wad.Fs.Disk in '..\Framework\Wad\DelphiDoom.Wad.Fs.Disk.pas',
  DelphiDoom.Wad.Fs.Pack in '..\Framework\Wad\DelphiDoom.Wad.Fs.Pack.pas',
  DelphiDoom.Wad.Fs.PackLoader in '..\Framework\Wad\DelphiDoom.Wad.Fs.PackLoader.pas',
  DelphiDoom.Wad.Fs.GameFile in '..\Framework\Wad\DelphiDoom.Wad.Fs.GameFile.pas',
  DelphiDoom.Wad.Fs.FileSystem in '..\Framework\Wad\DelphiDoom.Wad.Fs.FileSystem.pas',
  DelphiDoom.Wad.Fs.Factory in '..\Framework\Wad\DelphiDoom.Wad.Fs.Factory.pas',
  DelphiDoom.Wad.Dll.Intf in '..\Framework\Wad\DelphiDoom.Wad.Dll.Intf.pas',
  DelphiDoom.Wad.Dll.Text in '..\Framework\Wad\DelphiDoom.Wad.Dll.Text.pas',
  DelphiDoom.Wad.Dll.ErrorSink in '..\Framework\Wad\DelphiDoom.Wad.Dll.ErrorSink.pas',
  DelphiDoom.Wad.Dll.SourceAdapter in '..\Framework\Wad\DelphiDoom.Wad.Dll.SourceAdapter.pas',
  DelphiDoom.Wad.Dll.DirectoryAdapter in '..\Framework\Wad\DelphiDoom.Wad.Dll.DirectoryAdapter.pas',
  DelphiDoom.Wad.Dll.BuilderAdapter in '..\Framework\Wad\DelphiDoom.Wad.Dll.BuilderAdapter.pas',
  DelphiDoom.Wad.Dll.Engine in '..\Framework\Wad\DelphiDoom.Wad.Dll.Engine.pas',
  DelphiDoom.Wad.Dll.ClientCheck in '..\Framework\Wad\DelphiDoom.Wad.Dll.ClientCheck.pas',
  DelphiDoom.Wad.Dll.ClientSource in '..\Framework\Wad\DelphiDoom.Wad.Dll.ClientSource.pas',
  DelphiDoom.Wad.Dll.ClientDirectory in '..\Framework\Wad\DelphiDoom.Wad.Dll.ClientDirectory.pas',
  DelphiDoom.Wad.Dll.ClientBuilder in '..\Framework\Wad\DelphiDoom.Wad.Dll.ClientBuilder.pas',
  DelphiDoom.Wad.Dll.Client in '..\Framework\Wad\DelphiDoom.Wad.Dll.Client.pas',
  DelphiDoom.Wad.Dll.Loader in '..\Framework\Wad\DelphiDoom.Wad.Dll.Loader.pas',
  DelphiDoom.Tests.Wad.Helpers in 'Source\DelphiDoom.Tests.Wad.Helpers.pas',
  DelphiDoom.Tests.Wad.Name in 'Source\DelphiDoom.Tests.Wad.Name.pas',
  DelphiDoom.Tests.Wad.LumpText in 'Source\DelphiDoom.Tests.Wad.LumpText.pas',
  DelphiDoom.Tests.Wad.FileBase in 'Source\DelphiDoom.Tests.Wad.FileBase.pas',
  DelphiDoom.Tests.Wad.Sources in 'Source\DelphiDoom.Tests.Wad.Sources.pas',
  DelphiDoom.Tests.Wad.Directory in 'Source\DelphiDoom.Tests.Wad.Directory.pas',
  DelphiDoom.Tests.Wad.Builder in 'Source\DelphiDoom.Tests.Wad.Builder.pas',
  DelphiDoom.Tests.Wad.LumpCache in 'Source\DelphiDoom.Tests.Wad.LumpCache.pas',
  DelphiDoom.Tests.Wad.Level in 'Source\DelphiDoom.Tests.Wad.Level.pas',
  DelphiDoom.Tests.Wad.Dll in 'Source\DelphiDoom.Tests.Wad.Dll.pas',
  DelphiDoom.Tests.Wad.RealWads in 'Source\DelphiDoom.Tests.Wad.RealWads.pas',
  DelphiDoom.Tests.Wad.PakNames in 'Source\DelphiDoom.Tests.Wad.PakNames.pas',
  DelphiDoom.Tests.Wad.PakGameDirectories in 'Source\DelphiDoom.Tests.Wad.PakGameDirectories.pas',
  DelphiDoom.Tests.Wad.PakIndex in 'Source\DelphiDoom.Tests.Wad.PakIndex.pas',
  DelphiDoom.Tests.Wad.PakPathResolver in 'Source\DelphiDoom.Tests.Wad.PakPathResolver.pas',
  DelphiDoom.Tests.Wad.Pk3 in 'Source\DelphiDoom.Tests.Wad.Pk3.pas',
  DelphiDoom.Tests.Wad.MemoryDisk in 'Source\DelphiDoom.Tests.Wad.MemoryDisk.pas',
  DelphiDoom.Tests.Wad.GameFileSystem in 'Source\DelphiDoom.Tests.Wad.GameFileSystem.pas',
  DelphiDoom.Tests.Wad.MemoryWriteDisk in 'Source\DelphiDoom.Tests.Wad.MemoryWriteDisk.pas',
  DelphiDoom.Tests.Wad.GameFileWriter in 'Source\DelphiDoom.Tests.Wad.GameFileWriter.pas',
  DelphiDoom.Tests.Wad.PureServer in 'Source\DelphiDoom.Tests.Wad.PureServer.pas',
  DelphiDoom.Tests.Wad.ModLister in 'Source\DelphiDoom.Tests.Wad.ModLister.pas',
  DelphiDoom.Tests.Wad.AddonParser in 'Source\DelphiDoom.Tests.Wad.AddonParser.pas';

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
