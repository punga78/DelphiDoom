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
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Renderer.Types in '..\IdTech1\Renderer\DelphiDoom.Renderer.Types.pas',
  DelphiDoom.Video.Intf in '..\Framework\Video\DelphiDoom.Video.Intf.pas',
  DelphiDoom.Video.Types in '..\Framework\Video\DelphiDoom.Video.Types.pas',
  DelphiDoom.Palette.Intf in '..\Framework\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Palette.Types in '..\Framework\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Renderer.Intf in '..\IdTech1\Renderer\DelphiDoom.Renderer.Intf.pas',
  DelphiDoom.Renderer.TextureLookup in '..\IdTech1\Renderer\DelphiDoom.Renderer.TextureLookup.pas',
  DelphiDoom.Renderer.SpriteDefs in '..\IdTech1\Renderer\DelphiDoom.Renderer.SpriteDefs.pas',
  DelphiDoom.Renderer.SubsectorGrid in '..\IdTech1\Renderer\DelphiDoom.Renderer.SubsectorGrid.pas',
  DelphiDoom.Renderer.LumpRanges in '..\IdTech1\Renderer\DelphiDoom.Renderer.LumpRanges.pas',
  DelphiDoom.Renderer.SpriteTable in '..\IdTech1\Renderer\DelphiDoom.Renderer.SpriteTable.pas',
  DelphiDoom.Renderer.TextureMapping in '..\IdTech1\Renderer\DelphiDoom.Renderer.TextureMapping.pas',
  DelphiDoom.Renderer.PrecachePlan in '..\IdTech1\Renderer\DelphiDoom.Renderer.PrecachePlan.pas',
  DelphiDoom.Renderer.Profiles in '..\IdTech1\Renderer\DelphiDoom.Renderer.Profiles.pas',
  DelphiDoom.Renderer.SpriteSortPolicy in '..\IdTech1\Renderer\DelphiDoom.Renderer.SpriteSortPolicy.pas',
  DelphiDoom.Renderer.RadixSorter in '..\IdTech1\Renderer\DelphiDoom.Renderer.RadixSorter.pas',
  DelphiDoom.Renderer.MergeSorter in '..\IdTech1\Renderer\DelphiDoom.Renderer.MergeSorter.pas',
  DelphiDoom.Renderer.QuickSorter in '..\IdTech1\Renderer\DelphiDoom.Renderer.QuickSorter.pas',
  DelphiDoom.Renderer.SelectionSorter in '..\IdTech1\Renderer\DelphiDoom.Renderer.SelectionSorter.pas',
  DelphiDoom.Renderer.ViewTables in '..\IdTech1\Renderer\DelphiDoom.Renderer.ViewTables.pas',
  DelphiDoom.Renderer.Fake3DAngles in '..\IdTech1\Renderer\DelphiDoom.Renderer.Fake3DAngles.pas',
  DelphiDoom.Renderer.MonitorAspect in '..\IdTech1\Renderer\DelphiDoom.Renderer.MonitorAspect.pas',
  DelphiDoom.Renderer.Pk3TextHash in '..\IdTech1\Renderer\DelphiDoom.Renderer.Pk3TextHash.pas',
  DelphiDoom.Renderer.Pk3NameSelector in '..\IdTech1\Renderer\DelphiDoom.Renderer.Pk3NameSelector.pas',
  DelphiDoom.Renderer.LevelPrecalc in '..\IdTech1\Renderer\DelphiDoom.Renderer.LevelPrecalc.pas',
  DelphiDoom.Renderer.Factory in '..\IdTech1\Renderer\DelphiDoom.Renderer.Factory.pas',
  DelphiDoom.MathCore.Types in '..\Framework\GameMath\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\Framework\GameMath\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Framework\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.MathCore.X87Double in '..\Framework\GameMath\DelphiDoom.MathCore.X87Double.pas',
  DelphiDoom.Renderer.LightIndex in '..\IdTech1\Renderer\DelphiDoom.Renderer.LightIndex.pas',
  DelphiDoom.Renderer.SlopesX87 in '..\IdTech1\Renderer\DelphiDoom.Renderer.SlopesX87.pas',
  DelphiDoom.Renderer.X87 in '..\IdTech1\Renderer\DelphiDoom.Renderer.X87.pas',
  DelphiDoom.Tests.MathCore.Fingerprint in 'Source\DelphiDoom.Tests.MathCore.Fingerprint.pas',
  DelphiDoom.Tests.Renderer.X87 in 'Source\DelphiDoom.Tests.Renderer.X87.pas',
  DelphiDoom.Tests.Renderer.LightIndex in 'Source\DelphiDoom.Tests.Renderer.LightIndex.pas',
  DelphiDoom.Tests.Renderer.SlopesX87 in 'Source\DelphiDoom.Tests.Renderer.SlopesX87.pas',
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
