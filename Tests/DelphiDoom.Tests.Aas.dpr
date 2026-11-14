{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the AAS library of Quake III (DUnitX)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Aas;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.BotAi.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Types.pas',
  DelphiDoom.BotAi.Import.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.Aas.Types in '..\Libs\Aas\DelphiDoom.Aas.Types.pas',
  DelphiDoom.Aas.Intf in '..\Libs\Aas\DelphiDoom.Aas.Intf.pas',
  DelphiDoom.Aas.Printer in '..\Libs\Aas\DelphiDoom.Aas.Printer.pas',
  DelphiDoom.Aas.VectorMath in '..\Libs\Aas\DelphiDoom.Aas.VectorMath.pas',
  DelphiDoom.Aas.HeaderCipher in '..\Libs\Aas\DelphiDoom.Aas.HeaderCipher.pas',
  DelphiDoom.Aas.ByteSwapper in '..\Libs\Aas\DelphiDoom.Aas.ByteSwapper.pas',
  DelphiDoom.Aas.AasFile in '..\Libs\Aas\DelphiDoom.Aas.AasFile.pas',
  DelphiDoom.Aas.Reader in '..\Libs\Aas\DelphiDoom.Aas.Reader.pas',
  DelphiDoom.Aas.BoxMath in '..\Libs\Aas\DelphiDoom.Aas.BoxMath.pas',
  DelphiDoom.Aas.Sampler in '..\Libs\Aas\DelphiDoom.Aas.Sampler.pas',
  DelphiDoom.Aas.AreaQuery in '..\Libs\Aas\DelphiDoom.Aas.AreaQuery.pas',
  DelphiDoom.Aas.Tracer in '..\Libs\Aas\DelphiDoom.Aas.Tracer.pas',
  DelphiDoom.Aas.FaceTester in '..\Libs\Aas\DelphiDoom.Aas.FaceTester.pas',
  DelphiDoom.Aas.BoxAreas in '..\Libs\Aas\DelphiDoom.Aas.BoxAreas.pas',
  DelphiDoom.Aas.Route.Types in '..\Libs\Aas\DelphiDoom.Aas.Route.Types.pas',
  DelphiDoom.Aas.Route.Intf in '..\Libs\Aas\DelphiDoom.Aas.Route.Intf.pas',
  DelphiDoom.Aas.Route.Data in '..\Libs\Aas\DelphiDoom.Aas.Route.Data.pas',
  DelphiDoom.Aas.Route.Cache in '..\Libs\Aas\DelphiDoom.Aas.Route.Cache.pas',
  DelphiDoom.Aas.Route.CacheStore in '..\Libs\Aas\DelphiDoom.Aas.Route.CacheStore.pas',
  DelphiDoom.Aas.Route.Alternative in '..\Libs\Aas\DelphiDoom.Aas.Route.Alternative.pas',
  DelphiDoom.Aas.Route.Router in '..\Libs\Aas\DelphiDoom.Aas.Route.Router.pas',
  DelphiDoom.Aas.Factory in '..\Libs\Aas\DelphiDoom.Aas.Factory.pas',
  DelphiDoom.Tests.Aas.Sample in 'Source\DelphiDoom.Tests.Aas.Sample.pas',
  DelphiDoom.Tests.Aas.Support in 'Source\DelphiDoom.Tests.Aas.Support.pas',
  DelphiDoom.Tests.Aas.ScenarioRunner in 'Source\DelphiDoom.Tests.Aas.ScenarioRunner.pas',
  DelphiDoom.Tests.Aas.Golden in 'Source\DelphiDoom.Tests.Aas.Golden.pas',
  DelphiDoom.Tests.Aas.Reader in 'Source\DelphiDoom.Tests.Aas.Reader.pas',
  DelphiDoom.Tests.Aas.Sampling in 'Source\DelphiDoom.Tests.Aas.Sampling.pas',
  DelphiDoom.Tests.Aas.OpenArena in 'Source\DelphiDoom.Tests.Aas.OpenArena.pas',
  DelphiDoom.Aas.D3.Types in '..\Libs\Aas\DelphiDoom.Aas.D3.Types.pas',
  DelphiDoom.Aas.D3.Intf in '..\Libs\Aas\DelphiDoom.Aas.D3.Intf.pas',
  DelphiDoom.Aas.D3.TravelTime in '..\Libs\Aas\DelphiDoom.Aas.D3.TravelTime.pas',
  DelphiDoom.Aas.D3.Topology in '..\Libs\Aas\DelphiDoom.Aas.D3.Topology.pas',
  DelphiDoom.Aas.D3.RoutingCache in '..\Libs\Aas\DelphiDoom.Aas.D3.RoutingCache.pas',
  DelphiDoom.Aas.D3.CacheStore in '..\Libs\Aas\DelphiDoom.Aas.D3.CacheStore.pas',
  DelphiDoom.Aas.D3.Router in '..\Libs\Aas\DelphiDoom.Aas.D3.Router.pas',
  DelphiDoom.Aas.D3.Obstacles in '..\Libs\Aas\DelphiDoom.Aas.D3.Obstacles.pas',
  DelphiDoom.Aas.D3.PathFinder in '..\Libs\Aas\DelphiDoom.Aas.D3.PathFinder.pas',
  DelphiDoom.Aas.D3.WallEdges in '..\Libs\Aas\DelphiDoom.Aas.D3.WallEdges.pas',
  DelphiDoom.Aas.D3.Navigator in '..\Libs\Aas\DelphiDoom.Aas.D3.Navigator.pas',
  DelphiDoom.Aas.D3.Avoid.Types in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.Types.pas',
  DelphiDoom.Aas.D3.Avoid.Intf in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.Intf.pas',
  DelphiDoom.Aas.D3.Avoid.Obstacle in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.Obstacle.pas',
  DelphiDoom.Aas.D3.Avoid.ObstacleSet in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.ObstacleSet.pas',
  DelphiDoom.Aas.D3.Avoid.ObstacleCollector in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.ObstacleCollector.pas',
  DelphiDoom.Aas.D3.Avoid.PathNode in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.PathNode.pas',
  DelphiDoom.Aas.D3.Avoid.PathTree in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.PathTree.pas',
  DelphiDoom.Aas.D3.Avoid.PathOptimizer in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.PathOptimizer.pas',
  DelphiDoom.Aas.D3.Avoid.PathFinder in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.PathFinder.pas',
  DelphiDoom.Aas.D3.Avoid.Ballistics in '..\Libs\Aas\DelphiDoom.Aas.D3.Avoid.Ballistics.pas',
  DelphiDoom.Aas.D3.Factory in '..\Libs\Aas\DelphiDoom.Aas.D3.Factory.pas',
  DelphiDoom.Tests.Aas.D3.Support in 'Source\DelphiDoom.Tests.Aas.D3.Support.pas',
  DelphiDoom.Tests.Aas.Route.Units in 'Source\DelphiDoom.Tests.Aas.Route.Units.pas',
  DelphiDoom.Tests.Aas.Route.Scenario in 'Source\DelphiDoom.Tests.Aas.Route.Scenario.pas',
  DelphiDoom.Tests.Aas.Route.Golden in 'Source\DelphiDoom.Tests.Aas.Route.Golden.pas',
  DelphiDoom.Tests.Aas.D3.Units in 'Source\DelphiDoom.Tests.Aas.D3.Units.pas',
  DelphiDoom.Tests.Aas.D3.Scenario in 'Source\DelphiDoom.Tests.Aas.D3.Scenario.pas',
  DelphiDoom.Tests.Aas.D3.Golden in 'Source\DelphiDoom.Tests.Aas.D3.Golden.pas',
  DelphiDoom.Tests.Aas.D3.AvoidScenario in 'Source\DelphiDoom.Tests.Aas.D3.AvoidScenario.pas',
  DelphiDoom.Tests.Aas.D3.AvoidGolden in 'Source\DelphiDoom.Tests.Aas.D3.AvoidGolden.pas',
  DelphiDoom.Tests.Aas.D3.Avoid in 'Source\DelphiDoom.Tests.Aas.D3.Avoid.pas',
  DelphiDoom.Tests.Aas.D3.Routing in 'Source\DelphiDoom.Tests.Aas.D3.Routing.pas';

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
