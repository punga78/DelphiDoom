{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the voxel library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Voxel;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Libs\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.Voxel.Types in '..\Libs\Voxel\DelphiDoom.Voxel.Types.pas',
  DelphiDoom.Voxel.Intf in '..\Libs\Voxel\DelphiDoom.Voxel.Intf.pas',
  DelphiDoom.Voxel.Colors in '..\Libs\Voxel\DelphiDoom.Voxel.Colors.pas',
  DelphiDoom.Voxel.ByteReader in '..\Libs\Voxel\DelphiDoom.Voxel.ByteReader.pas',
  DelphiDoom.Voxel.KvxPalette in '..\Libs\Voxel\DelphiDoom.Voxel.KvxPalette.pas',
  DelphiDoom.Voxel.Model in '..\Libs\Voxel\DelphiDoom.Voxel.Model.pas',
  DelphiDoom.Voxel.Cube in '..\Libs\Voxel\DelphiDoom.Voxel.Cube.pas',
  DelphiDoom.Voxel.CubeBuilder in '..\Libs\Voxel\DelphiDoom.Voxel.CubeBuilder.pas',
  DelphiDoom.Voxel.Format.Ddvox in '..\Libs\Voxel\DelphiDoom.Voxel.Format.Ddvox.pas',
  DelphiDoom.Voxel.Format.Ddmesh in '..\Libs\Voxel\DelphiDoom.Voxel.Format.Ddmesh.pas',
  DelphiDoom.Voxel.Format.Kvx in '..\Libs\Voxel\DelphiDoom.Voxel.Format.Kvx.pas',
  DelphiDoom.Voxel.Format.Slab6 in '..\Libs\Voxel\DelphiDoom.Voxel.Format.Slab6.pas',
  DelphiDoom.Voxel.Loader in '..\Libs\Voxel\DelphiDoom.Voxel.Loader.pas',
  DelphiDoom.Voxel.PatchBuilder in '..\Libs\Voxel\DelphiDoom.Voxel.PatchBuilder.pas',
  DelphiDoom.Voxel.DefinitionParser in '..\Libs\Voxel\DelphiDoom.Voxel.DefinitionParser.pas',
  DelphiDoom.Voxel.SpriteNames in '..\Libs\Voxel\DelphiDoom.Voxel.SpriteNames.pas',
  DelphiDoom.Voxel.Factory in '..\Libs\Voxel\DelphiDoom.Voxel.Factory.pas',
  DelphiDoom.Tests.Voxel.Fingerprint in 'Source\DelphiDoom.Tests.Voxel.Fingerprint.pas',
  DelphiDoom.Tests.Voxel.Golden in 'Source\DelphiDoom.Tests.Voxel.Golden.pas',
  DelphiDoom.Tests.Voxel.Samples in 'Source\DelphiDoom.Tests.Voxel.Samples.pas',
  DelphiDoom.Tests.Voxel.Scenarios in 'Source\DelphiDoom.Tests.Voxel.Scenarios.pas',
  DelphiDoom.Tests.Voxel.Fakes in 'Source\DelphiDoom.Tests.Voxel.Fakes.pas',
  DelphiDoom.Tests.Voxel.Subject in 'Source\DelphiDoom.Tests.Voxel.Subject.pas',
  DelphiDoom.Tests.Voxel.Parity in 'Source\DelphiDoom.Tests.Voxel.Parity.pas',
  DelphiDoom.Tests.Voxel.ByteReader in 'Source\DelphiDoom.Tests.Voxel.ByteReader.pas',
  DelphiDoom.Tests.Voxel.Colors in 'Source\DelphiDoom.Tests.Voxel.Colors.pas',
  DelphiDoom.Tests.Voxel.KvxPalette in 'Source\DelphiDoom.Tests.Voxel.KvxPalette.pas',
  DelphiDoom.Tests.Voxel.Model in 'Source\DelphiDoom.Tests.Voxel.Model.pas',
  DelphiDoom.Tests.Voxel.CubeBuilder in 'Source\DelphiDoom.Tests.Voxel.CubeBuilder.pas',
  DelphiDoom.Tests.Voxel.Ddvox in 'Source\DelphiDoom.Tests.Voxel.Ddvox.pas',
  DelphiDoom.Tests.Voxel.Ddmesh in 'Source\DelphiDoom.Tests.Voxel.Ddmesh.pas',
  DelphiDoom.Tests.Voxel.Kvx in 'Source\DelphiDoom.Tests.Voxel.Kvx.pas',
  DelphiDoom.Tests.Voxel.Slab6 in 'Source\DelphiDoom.Tests.Voxel.Slab6.pas',
  DelphiDoom.Tests.Voxel.Loader in 'Source\DelphiDoom.Tests.Voxel.Loader.pas',
  DelphiDoom.Tests.Voxel.PatchBuilder in 'Source\DelphiDoom.Tests.Voxel.PatchBuilder.pas',
  DelphiDoom.Tests.Voxel.DefinitionParser in 'Source\DelphiDoom.Tests.Voxel.DefinitionParser.pas',
  DelphiDoom.Tests.Voxel.Factory in 'Source\DelphiDoom.Tests.Voxel.Factory.pas',
  DelphiDoom.Tests.Voxel.SpriteNames in 'Source\DelphiDoom.Tests.Voxel.SpriteNames.pas',
  DelphiDoom.Tests.Voxel.Pk3 in 'Source\DelphiDoom.Tests.Voxel.Pk3.pas';

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
