{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the renderer library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Renderer;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Renderer.Types in '..\Libs\Renderer\DelphiDoom.Renderer.Types.pas',
  DelphiDoom.Video.Intf in '..\Libs\Video\DelphiDoom.Video.Intf.pas',
  DelphiDoom.Video.Types in '..\Libs\Video\DelphiDoom.Video.Types.pas',
  DelphiDoom.Palette.Intf in '..\Libs\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Palette.Types in '..\Libs\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Renderer.Intf in '..\Libs\Renderer\DelphiDoom.Renderer.Intf.pas',
  DelphiDoom.Renderer.TextureLookup in '..\Libs\Renderer\DelphiDoom.Renderer.TextureLookup.pas',
  DelphiDoom.Renderer.SpriteDefs in '..\Libs\Renderer\DelphiDoom.Renderer.SpriteDefs.pas',
  DelphiDoom.Renderer.SubsectorGrid in '..\Libs\Renderer\DelphiDoom.Renderer.SubsectorGrid.pas',
  DelphiDoom.Renderer.LumpRanges in '..\Libs\Renderer\DelphiDoom.Renderer.LumpRanges.pas',
  DelphiDoom.Renderer.SpriteTable in '..\Libs\Renderer\DelphiDoom.Renderer.SpriteTable.pas',
  DelphiDoom.Renderer.TextureMapping in '..\Libs\Renderer\DelphiDoom.Renderer.TextureMapping.pas',
  DelphiDoom.Renderer.PrecachePlan in '..\Libs\Renderer\DelphiDoom.Renderer.PrecachePlan.pas',
  DelphiDoom.Renderer.Profiles in '..\Libs\Renderer\DelphiDoom.Renderer.Profiles.pas',
  DelphiDoom.Renderer.SpriteSortPolicy in '..\Libs\Renderer\DelphiDoom.Renderer.SpriteSortPolicy.pas',
  DelphiDoom.Renderer.RadixSorter in '..\Libs\Renderer\DelphiDoom.Renderer.RadixSorter.pas',
  DelphiDoom.Renderer.MergeSorter in '..\Libs\Renderer\DelphiDoom.Renderer.MergeSorter.pas',
  DelphiDoom.Renderer.QuickSorter in '..\Libs\Renderer\DelphiDoom.Renderer.QuickSorter.pas',
  DelphiDoom.Renderer.SelectionSorter in '..\Libs\Renderer\DelphiDoom.Renderer.SelectionSorter.pas',
  DelphiDoom.Renderer.ViewTables in '..\Libs\Renderer\DelphiDoom.Renderer.ViewTables.pas',
  DelphiDoom.Renderer.Fake3DAngles in '..\Libs\Renderer\DelphiDoom.Renderer.Fake3DAngles.pas',
  DelphiDoom.Renderer.MonitorAspect in '..\Libs\Renderer\DelphiDoom.Renderer.MonitorAspect.pas',
  DelphiDoom.Renderer.Pk3TextHash in '..\Libs\Renderer\DelphiDoom.Renderer.Pk3TextHash.pas',
  DelphiDoom.Renderer.Pk3NameSelector in '..\Libs\Renderer\DelphiDoom.Renderer.Pk3NameSelector.pas',
  DelphiDoom.Renderer.LevelPrecalc in '..\Libs\Renderer\DelphiDoom.Renderer.LevelPrecalc.pas',
  DelphiDoom.Renderer.Factory in '..\Libs\Renderer\DelphiDoom.Renderer.Factory.pas',
  DelphiDoom.MathCore.Types in '..\Libs\GameMath\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\Libs\GameMath\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Libs\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.MathCore.X87Double in '..\Libs\GameMath\DelphiDoom.MathCore.X87Double.pas',
  DelphiDoom.Renderer.X87 in '..\Libs\Renderer\DelphiDoom.Renderer.X87.pas',
  DelphiDoom.Tests.MathCore.Fingerprint in 'Source\DelphiDoom.Tests.MathCore.Fingerprint.pas',
  DelphiDoom.Tests.Renderer.X87 in 'Source\DelphiDoom.Tests.Renderer.X87.pas',
  DelphiDoom.Tests.Renderer.Fakes in 'Source\DelphiDoom.Tests.Renderer.Fakes.pas',
  DelphiDoom.Tests.Renderer.TextureLookup in 'Source\DelphiDoom.Tests.Renderer.TextureLookup.pas',
  DelphiDoom.Tests.Renderer.SpriteDefs in 'Source\DelphiDoom.Tests.Renderer.SpriteDefs.pas',
  DelphiDoom.Tests.Renderer.SubsectorGrid in 'Source\DelphiDoom.Tests.Renderer.SubsectorGrid.pas',
  DelphiDoom.Tests.Renderer.LumpRanges in 'Source\DelphiDoom.Tests.Renderer.LumpRanges.pas',
  DelphiDoom.Tests.Renderer.SpriteTable in 'Source\DelphiDoom.Tests.Renderer.SpriteTable.pas',
  DelphiDoom.Tests.Renderer.TextureMapping in 'Source\DelphiDoom.Tests.Renderer.TextureMapping.pas',
  DelphiDoom.Tests.Renderer.Profiles in 'Source\DelphiDoom.Tests.Renderer.Profiles.pas',
  DelphiDoom.Tests.Renderer.SpriteSorters in 'Source\DelphiDoom.Tests.Renderer.SpriteSorters.pas',
  DelphiDoom.Tests.Renderer.ViewTables in 'Source\DelphiDoom.Tests.Renderer.ViewTables.pas',
  DelphiDoom.Tests.Renderer.Pk3NameSelector in 'Source\DelphiDoom.Tests.Renderer.Pk3NameSelector.pas',
  DelphiDoom.Tests.Renderer.MonitorAspect in 'Source\DelphiDoom.Tests.Renderer.MonitorAspect.pas',
  DelphiDoom.Tests.Renderer.PrecachePlan in 'Source\DelphiDoom.Tests.Renderer.PrecachePlan.pas',
  DelphiDoom.Tests.Renderer.LevelPrecalc in 'Source\DelphiDoom.Tests.Renderer.LevelPrecalc.pas';

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
