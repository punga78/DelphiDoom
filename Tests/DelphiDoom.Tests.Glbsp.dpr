{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Glbsp library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Glbsp;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Zlib.Intf in '..\Libs\Zlib\DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Zlib.Native in '..\Libs\Zlib\DelphiDoom.Zlib.Native.pas',
  DelphiDoom.Zlib.Inflater in '..\Libs\Zlib\DelphiDoom.Zlib.Inflater.pas',
  DelphiDoom.Zlib.Deflater in '..\Libs\Zlib\DelphiDoom.Zlib.Deflater.pas',
  DelphiDoom.Zlib.Engine in '..\Libs\Zlib\DelphiDoom.Zlib.Engine.pas',
  DelphiDoom.Zlib.Client in '..\Libs\Zlib\DelphiDoom.Zlib.Client.pas',
  DelphiDoom.Zlib.Provider in '..\Libs\Zlib\DelphiDoom.Zlib.Provider.pas',
  DelphiDoom.Glbsp.Intf in '..\Libs\Glbsp\DelphiDoom.Glbsp.Intf.pas',
  DelphiDoom.Glbsp.Engine in '..\Libs\Glbsp\DelphiDoom.Glbsp.Engine.pas',
  DelphiDoom.Glbsp.Client in '..\Libs\Glbsp\DelphiDoom.Glbsp.Client.pas',
  DelphiDoom.Glbsp.Loader in '..\Libs\Glbsp\DelphiDoom.Glbsp.Loader.pas',
  DelphiDoom.Glbsp.Provider in '..\Libs\Glbsp\DelphiDoom.Glbsp.Provider.pas',
  DelphiDoom.Glbsp.Wad.Types in '..\Libs\Glbsp\DelphiDoom.Glbsp.Wad.Types.pas',
  DelphiDoom.Glbsp.Wad.Lump in '..\Libs\Glbsp\DelphiDoom.Glbsp.Wad.Lump.pas',
  DelphiDoom.Glbsp.Wad.Document in '..\Libs\Glbsp\DelphiDoom.Glbsp.Wad.Document.pas',
  DelphiDoom.Glbsp.Util in '..\Libs\Glbsp\DelphiDoom.Glbsp.Util.pas',
  DelphiDoom.Glbsp.Level.Raw in '..\Libs\Glbsp\DelphiDoom.Glbsp.Level.Raw.pas',
  DelphiDoom.Glbsp.Level.Types in '..\Libs\Glbsp\DelphiDoom.Glbsp.Level.Types.pas',
  DelphiDoom.Glbsp.Options in '..\Libs\Glbsp\DelphiDoom.Glbsp.Options.pas',
  DelphiDoom.Glbsp.Level.Data in '..\Libs\Glbsp\DelphiDoom.Glbsp.Level.Data.pas',
  DelphiDoom.Glbsp.Level.Loader in '..\Libs\Glbsp\DelphiDoom.Glbsp.Level.Loader.pas',
  DelphiDoom.Tests.Glbsp.Level.Loader in 'Source\DelphiDoom.Tests.Glbsp.Level.Loader.pas',
  DelphiDoom.Glbsp.Geometry in '..\Libs\Glbsp\DelphiDoom.Glbsp.Geometry.pas',
  DelphiDoom.Glbsp.Level.Analyzer in '..\Libs\Glbsp\DelphiDoom.Glbsp.Level.Analyzer.pas',
  DelphiDoom.Tests.Glbsp.Level.Analyzer in 'Source\DelphiDoom.Tests.Glbsp.Level.Analyzer.pas',
  DelphiDoom.Glbsp.Node.SuperBlocks in '..\Libs\Glbsp\DelphiDoom.Glbsp.Node.SuperBlocks.pas',
  DelphiDoom.Glbsp.Node.Partitioner in '..\Libs\Glbsp\DelphiDoom.Glbsp.Node.Partitioner.pas',
  DelphiDoom.Glbsp.Node.Builder in '..\Libs\Glbsp\DelphiDoom.Glbsp.Node.Builder.pas',
  DelphiDoom.Tests.Glbsp.Node.Builder in 'Source\DelphiDoom.Tests.Glbsp.Node.Builder.pas',
  DelphiDoom.Glbsp.Reject.Builder in '..\Libs\Glbsp\DelphiDoom.Glbsp.Reject.Builder.pas',
  DelphiDoom.Glbsp.Blockmap.Builder in '..\Libs\Glbsp\DelphiDoom.Glbsp.Blockmap.Builder.pas',
  DelphiDoom.Tests.Glbsp.Reject.Builder in 'Source\DelphiDoom.Tests.Glbsp.Reject.Builder.pas',
  DelphiDoom.Tests.Glbsp.Blockmap.Builder in 'Source\DelphiDoom.Tests.Glbsp.Blockmap.Builder.pas',
  DelphiDoom.Glbsp.Level.Writer in '..\Libs\Glbsp\DelphiDoom.Glbsp.Level.Writer.pas',
  DelphiDoom.Glbsp.Level.Processor in '..\Libs\Glbsp\DelphiDoom.Glbsp.Level.Processor.pas',
  DelphiDoom.Glbsp.Wad.Builder in '..\Libs\Glbsp\DelphiDoom.Glbsp.Wad.Builder.pas',
  DelphiDoom.Tests.Glbsp.Wad.Builder in 'Source\DelphiDoom.Tests.Glbsp.Wad.Builder.pas',
  DelphiDoom.Tests.Glbsp.Util in 'Source\DelphiDoom.Tests.Glbsp.Util.pas',
  DelphiDoom.Tests.Glbsp.Level.Raw in 'Source\DelphiDoom.Tests.Glbsp.Level.Raw.pas',
  DelphiDoom.Tests.Glbsp.Wad.Document in 'Source\DelphiDoom.Tests.Glbsp.Wad.Document.pas',
  DelphiDoom.Tests.Glbsp.Engine in 'Source\DelphiDoom.Tests.Glbsp.Engine.pas',
  DelphiDoom.Tests.Glbsp.Client in 'Source\DelphiDoom.Tests.Glbsp.Client.pas',
  DelphiDoom.Tests.Glbsp.Loader in 'Source\DelphiDoom.Tests.Glbsp.Loader.pas',
  DelphiDoom.Tests.Glbsp.Provider in 'Source\DelphiDoom.Tests.Glbsp.Provider.pas';

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

