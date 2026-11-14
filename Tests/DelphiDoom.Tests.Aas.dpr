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
  DelphiDoom.Aas.Editor.Intf in '..\Libs\Aas\DelphiDoom.Aas.Editor.Intf.pas',
  DelphiDoom.Aas.Cluster.Types in '..\Libs\Aas\DelphiDoom.Aas.Cluster.Types.pas',
  DelphiDoom.Aas.Cluster.Intf in '..\Libs\Aas\DelphiDoom.Aas.Cluster.Intf.pas',
  DelphiDoom.Aas.Cluster.World in '..\Libs\Aas\DelphiDoom.Aas.Cluster.World.pas',
  DelphiDoom.Aas.Cluster.Builder in '..\Libs\Aas\DelphiDoom.Aas.Cluster.Builder.pas',
  DelphiDoom.Aas.Cluster.PortalFinder in '..\Libs\Aas\DelphiDoom.Aas.Cluster.PortalFinder.pas',
  DelphiDoom.Aas.Cluster.Initializer in '..\Libs\Aas\DelphiDoom.Aas.Cluster.Initializer.pas',
  DelphiDoom.Aas.Optimize.Optimizer in '..\Libs\Aas\DelphiDoom.Aas.Optimize.Optimizer.pas',
  DelphiDoom.Aas.Route.Types in '..\Libs\Aas\DelphiDoom.Aas.Route.Types.pas',
  DelphiDoom.Aas.Route.Intf in '..\Libs\Aas\DelphiDoom.Aas.Route.Intf.pas',
  DelphiDoom.Aas.Route.Data in '..\Libs\Aas\DelphiDoom.Aas.Route.Data.pas',
  DelphiDoom.Aas.Route.Cache in '..\Libs\Aas\DelphiDoom.Aas.Route.Cache.pas',
  DelphiDoom.Aas.Route.CacheStore in '..\Libs\Aas\DelphiDoom.Aas.Route.CacheStore.pas',
  DelphiDoom.Aas.Route.Alternative in '..\Libs\Aas\DelphiDoom.Aas.Route.Alternative.pas',
  DelphiDoom.Aas.Route.Router in '..\Libs\Aas\DelphiDoom.Aas.Route.Router.pas',
  DelphiDoom.Aas.Route.RandomGoal in '..\Libs\Aas\DelphiDoom.Aas.Route.RandomGoal.pas',
  DelphiDoom.Aas.Move.Types in '..\Libs\Aas\DelphiDoom.Aas.Move.Types.pas',
  DelphiDoom.Aas.Move.Intf in '..\Libs\Aas\DelphiDoom.Aas.Move.Intf.pas',
  DelphiDoom.Aas.Move.Settings in '..\Libs\Aas\DelphiDoom.Aas.Move.Settings.pas',
  DelphiDoom.Aas.Move.Movement in '..\Libs\Aas\DelphiDoom.Aas.Move.Movement.pas',
  DelphiDoom.Aas.Move.CollisionWorld in '..\Libs\Aas\DelphiDoom.Aas.Move.CollisionWorld.pas',
  DelphiDoom.Aas.Links in '..\Libs\Aas\DelphiDoom.Aas.Links.pas',
  DelphiDoom.Aas.Main.Map in '..\Libs\Aas\DelphiDoom.Aas.Main.Map.pas',
  DelphiDoom.Aas.Main.InitSteps in '..\Libs\Aas\DelphiDoom.Aas.Main.InitSteps.pas',
  DelphiDoom.Aas.Main.MapBuilder in '..\Libs\Aas\DelphiDoom.Aas.Main.MapBuilder.pas',
  DelphiDoom.Aas.Main.Factory in '..\Libs\Aas\DelphiDoom.Aas.Main.Factory.pas',
  DelphiDoom.Aas.Entity.Types in '..\Libs\Aas\DelphiDoom.Aas.Entity.Types.pas',
  DelphiDoom.Aas.Main.Intf in '..\Libs\Aas\DelphiDoom.Aas.Main.Intf.pas',
  DelphiDoom.Aas.Entity.Table in '..\Libs\Aas\DelphiDoom.Aas.Entity.Table.pas',
  DelphiDoom.Aas.Main.StringIndexes in '..\Libs\Aas\DelphiDoom.Aas.Main.StringIndexes.pas',
  DelphiDoom.Aas.Main.System in '..\Libs\Aas\DelphiDoom.Aas.Main.System.pas',
  DelphiDoom.Aas.Bsp.Intf in '..\Libs\Aas\DelphiDoom.Aas.Bsp.Intf.pas',
  DelphiDoom.Aas.Bsp.CNumbers in '..\Libs\Aas\DelphiDoom.Aas.Bsp.CNumbers.pas',
  DelphiDoom.Aas.Bsp.Entities in '..\Libs\Aas\DelphiDoom.Aas.Bsp.Entities.pas',
  DelphiDoom.Aas.Bsp.CollisionModels in '..\Libs\Aas\DelphiDoom.Aas.Bsp.CollisionModels.pas',
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
  DelphiDoom.Tests.Aas.Cluster.Scenario in 'Source\DelphiDoom.Tests.Aas.Cluster.Scenario.pas',
  DelphiDoom.Tests.Aas.Cluster.Units in 'Source\DelphiDoom.Tests.Aas.Cluster.Units.pas',
  DelphiDoom.Tests.Aas.Cluster.Golden in 'Source\DelphiDoom.Tests.Aas.Cluster.Golden.pas',
  DelphiDoom.Tests.Aas.Route.Units in 'Source\DelphiDoom.Tests.Aas.Route.Units.pas',
  DelphiDoom.Tests.Aas.Bsp.Units in 'Source\DelphiDoom.Tests.Aas.Bsp.Units.pas',
  DelphiDoom.Tests.Aas.Main.Units in 'Source\DelphiDoom.Tests.Aas.Main.Units.pas',
  DelphiDoom.Tests.Aas.Bsp.Collision in 'Source\DelphiDoom.Tests.Aas.Bsp.Collision.pas',
  DelphiDoom.Tests.Aas.Move.Scenario in 'Source\DelphiDoom.Tests.Aas.Move.Scenario.pas',
  DelphiDoom.Tests.Aas.Route.Scenario in 'Source\DelphiDoom.Tests.Aas.Route.Scenario.pas',
  DelphiDoom.Tests.Aas.Route.Golden in 'Source\DelphiDoom.Tests.Aas.Route.Golden.pas',
  DelphiDoom.Tests.Aas.D3.Units in 'Source\DelphiDoom.Tests.Aas.D3.Units.pas',
  DelphiDoom.Tests.Aas.D3.Scenario in 'Source\DelphiDoom.Tests.Aas.D3.Scenario.pas',
  DelphiDoom.Tests.Aas.D3.Golden in 'Source\DelphiDoom.Tests.Aas.D3.Golden.pas',
  DelphiDoom.Tests.Aas.D3.AvoidScenario in 'Source\DelphiDoom.Tests.Aas.D3.AvoidScenario.pas',
  DelphiDoom.Tests.Aas.D3.AvoidGolden in 'Source\DelphiDoom.Tests.Aas.D3.AvoidGolden.pas',
  DelphiDoom.Tests.Aas.D3.Avoid in 'Source\DelphiDoom.Tests.Aas.D3.Avoid.pas',
  DelphiDoom.Tests.Aas.D3.Routing in 'Source\DelphiDoom.Tests.Aas.D3.Routing.pas',
  DelphiDoom.Aas.Reach.Types in '..\Libs\Aas\DelphiDoom.Aas.Reach.Types.pas',
  DelphiDoom.Aas.Reach.Intf in '..\Libs\Aas\DelphiDoom.Aas.Reach.Intf.pas',
  DelphiDoom.Aas.Reach.Vectors in '..\Libs\Aas\DelphiDoom.Aas.Reach.Vectors.pas',
  DelphiDoom.Aas.Reach.Format in '..\Libs\Aas\DelphiDoom.Aas.Reach.Format.pas',
  DelphiDoom.Aas.Reach.FloatMode in '..\Libs\Aas\DelphiDoom.Aas.Reach.FloatMode.pas',
  DelphiDoom.Aas.Reach.Geometry in '..\Libs\Aas\DelphiDoom.Aas.Reach.Geometry.pas',
  DelphiDoom.Aas.Reach.Physics in '..\Libs\Aas\DelphiDoom.Aas.Reach.Physics.pas',
  DelphiDoom.Aas.Reach.Heap in '..\Libs\Aas\DelphiDoom.Aas.Reach.Heap.pas',
  DelphiDoom.Aas.Reach.Context in '..\Libs\Aas\DelphiDoom.Aas.Reach.Context.pas',
  DelphiDoom.Aas.Reach.Part in '..\Libs\Aas\DelphiDoom.Aas.Reach.Part.pas',
  DelphiDoom.Aas.Reach.EdgePoints in '..\Libs\Aas\DelphiDoom.Aas.Reach.EdgePoints.pas',
  DelphiDoom.Aas.Reach.Swim in '..\Libs\Aas\DelphiDoom.Aas.Reach.Swim.pas',
  DelphiDoom.Aas.Reach.EqualFloor in '..\Libs\Aas\DelphiDoom.Aas.Reach.EqualFloor.pas',
  DelphiDoom.Aas.Reach.Step in '..\Libs\Aas\DelphiDoom.Aas.Reach.Step.pas',
  DelphiDoom.Aas.Reach.Jump in '..\Libs\Aas\DelphiDoom.Aas.Reach.Jump.pas',
  DelphiDoom.Aas.Reach.Ladder in '..\Libs\Aas\DelphiDoom.Aas.Reach.Ladder.pas',
  DelphiDoom.Aas.Reach.JumpPadInfo in '..\Libs\Aas\DelphiDoom.Aas.Reach.JumpPadInfo.pas',
  DelphiDoom.Aas.Reach.BestReachable in '..\Libs\Aas\DelphiDoom.Aas.Reach.BestReachable.pas',
  DelphiDoom.Aas.Reach.WeaponFlags in '..\Libs\Aas\DelphiDoom.Aas.Reach.WeaponFlags.pas',
  DelphiDoom.Aas.Reach.WeaponJump in '..\Libs\Aas\DelphiDoom.Aas.Reach.WeaponJump.pas',
  DelphiDoom.Aas.Reach.Grapple in '..\Libs\Aas\DelphiDoom.Aas.Reach.Grapple.pas',
  DelphiDoom.Aas.Reach.WalkOffLedge in '..\Libs\Aas\DelphiDoom.Aas.Reach.WalkOffLedge.pas',
  DelphiDoom.Aas.Reach.JumpPad in '..\Libs\Aas\DelphiDoom.Aas.Reach.JumpPad.pas',
  DelphiDoom.Aas.Reach.Teleport in '..\Libs\Aas\DelphiDoom.Aas.Reach.Teleport.pas',
  DelphiDoom.Aas.Reach.Elevator in '..\Libs\Aas\DelphiDoom.Aas.Reach.Elevator.pas',
  DelphiDoom.Aas.Reach.FuncBobbing in '..\Libs\Aas\DelphiDoom.Aas.Reach.FuncBobbing.pas',
  DelphiDoom.Aas.Reach.Calculator in '..\Libs\Aas\DelphiDoom.Aas.Reach.Calculator.pas',
  DelphiDoom.Aas.Reach.Factory in '..\Libs\Aas\DelphiDoom.Aas.Reach.Factory.pas',
  DelphiDoom.Tests.Aas.Reach.Scenario in 'Source\DelphiDoom.Tests.Aas.Reach.Scenario.pas',
  DelphiDoom.Tests.Aas.Reach.Worlds in 'Source\DelphiDoom.Tests.Aas.Reach.Worlds.pas',
  DelphiDoom.Tests.Aas.Reach.Golden in 'Source\DelphiDoom.Tests.Aas.Reach.Golden.pas',
  DelphiDoom.Tests.Aas.Reach.Units in 'Source\DelphiDoom.Tests.Aas.Reach.Units.pas',
  DelphiDoom.Tests.Aas.Links in 'Source\DelphiDoom.Tests.Aas.Links.pas';

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
