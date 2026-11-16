{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the thinkers library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Thinkers;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Types in '..\Framework\GameMath\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Framework\GameMath\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.MathCore.TableFineSine in '..\Framework\GameMath\DelphiDoom.MathCore.TableFineSine.pas',
  DelphiDoom.MathCore.TableFineTangent in '..\Framework\GameMath\DelphiDoom.MathCore.TableFineTangent.pas',
  DelphiDoom.MathCore.TableTanToAngle in '..\Framework\GameMath\DelphiDoom.MathCore.TableTanToAngle.pas',
  DelphiDoom.MathCore.TableTanToAngleEx in '..\Framework\GameMath\DelphiDoom.MathCore.TableTanToAngleEx.pas',
  DelphiDoom.MathCore.TableFixedSine in '..\Framework\GameMath\DelphiDoom.MathCore.TableFixedSine.pas',
  DelphiDoom.MathCore.TableRandom in '..\Framework\GameMath\DelphiDoom.MathCore.TableRandom.pas',
  DelphiDoom.MathCore.TableSysRandom in '..\Framework\GameMath\DelphiDoom.MathCore.TableSysRandom.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Framework\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.FixedMath in '..\Framework\GameMath\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.Trigonometry in '..\Framework\GameMath\DelphiDoom.MathCore.Trigonometry.pas',
  DelphiDoom.MathCore.VectorMath in '..\Framework\GameMath\DelphiDoom.MathCore.VectorMath.pas',
  DelphiDoom.MathCore.BoundingBox in '..\Framework\GameMath\DelphiDoom.MathCore.BoundingBox.pas',
  DelphiDoom.MathCore.IntegerStack in '..\Framework\MathCore\DelphiDoom.MathCore.IntegerStack.pas',
  DelphiDoom.MathCore.IntegerQueue in '..\Framework\MathCore\DelphiDoom.MathCore.IntegerQueue.pas',
  DelphiDoom.MathCore.GameRandom in '..\Framework\GameMath\DelphiDoom.MathCore.GameRandom.pas',
  DelphiDoom.MathCore.SystemEntropySource in '..\Framework\GameMath\DelphiDoom.MathCore.SystemEntropySource.pas',
  DelphiDoom.MathCore.StringHashTable in '..\Framework\GameMath\DelphiDoom.MathCore.StringHashTable.pas',
  DelphiDoom.MathCore.Crc32 in '..\Framework\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.MathCore.Sha1 in '..\Framework\MathCore\DelphiDoom.MathCore.Sha1.pas',
  DelphiDoom.MathCore.Factory in '..\Framework\GameMath\DelphiDoom.MathCore.Factory.pas',
  DelphiDoom.Thinkers.Light.Types in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Types.pas',
  DelphiDoom.Thinkers.Light.Intf in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Intf.pas',
  DelphiDoom.Thinkers.Light.Neighbors in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Neighbors.pas',
  DelphiDoom.Thinkers.Light.FlickerRules.Standard in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.FlickerRules.Standard.pas',
  DelphiDoom.Thinkers.Light.FlickerRules.Strife in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.FlickerRules.Strife.pas',
  DelphiDoom.Thinkers.Light.FireFlicker in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.FireFlicker.pas',
  DelphiDoom.Thinkers.Light.Flash in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Flash.pas',
  DelphiDoom.Thinkers.Light.Strobe in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Strobe.pas',
  DelphiDoom.Thinkers.Light.Glow in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Glow.pas',
  DelphiDoom.Thinkers.Light.Scripted in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Scripted.pas',
  DelphiDoom.Thinkers.Light.Phase in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Phase.pas',
  DelphiDoom.Thinkers.Light.Sequence in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Sequence.pas',
  DelphiDoom.Thinkers.Light.Games in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Games.pas',
  DelphiDoom.Thinkers.Light.Factory in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Light.Factory.pas',
  DelphiDoom.Thinkers.Platform.Types in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Platform.Types.pas',
  DelphiDoom.Thinkers.Platform.Intf in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Platform.Intf.pas',
  DelphiDoom.Thinkers.Platform.Games in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Platform.Games.pas',
  DelphiDoom.Thinkers.Platform.Machine in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Platform.Machine.pas',
  DelphiDoom.Thinkers.Platform.UdmfMachine in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Platform.UdmfMachine.pas',
  DelphiDoom.Thinkers.Platform.Factory in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Platform.Factory.pas',
  DelphiDoom.Thinkers.Teleport.Intf in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Teleport.Intf.pas',
  DelphiDoom.Thinkers.Teleport.Geometry in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Teleport.Geometry.pas',
  DelphiDoom.Thinkers.Teleport.LineExit in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Teleport.LineExit.pas',
  DelphiDoom.Thinkers.Teleport.Placement in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Teleport.Placement.pas',
  DelphiDoom.Thinkers.Door.Types in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Door.Types.pas',
  DelphiDoom.Thinkers.Door.Intf in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Door.Intf.pas',
  DelphiDoom.Thinkers.Door.Profiles in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Door.Profiles.pas',
  DelphiDoom.Thinkers.Door.Runner in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Door.Runner.pas',
  DelphiDoom.Thinkers.Door.Spawner in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Door.Spawner.pas',
  DelphiDoom.Thinkers.Door.Factory in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Door.Factory.pas',
  DelphiDoom.Thinkers.Plane.Types in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Plane.Types.pas',
  DelphiDoom.Thinkers.Plane.Intf in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Plane.Intf.pas',
  DelphiDoom.Thinkers.Plane.Rules in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Plane.Rules.pas',
  DelphiDoom.Thinkers.Plane.Mover in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Plane.Mover.pas',
  DelphiDoom.Thinkers.Plane.Waggle in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Plane.Waggle.pas',
  DelphiDoom.Thinkers.List in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.List.pas',
  DelphiDoom.Thinkers.ActiveSlots in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.ActiveSlots.pas',
  delphidoom.thinkers.bodyqueue in '..\IdTech1\Thinkers\delphidoom.thinkers.bodyqueue.pas',
  DelphiDoom.Thinkers.LevelTotals in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.LevelTotals.pas',
  DelphiDoom.Thinkers.RespawnQueue in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.RespawnQueue.pas',
  DelphiDoom.Thinkers.Scroll.Step in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Scroll.Step.pas',
  DelphiDoom.Thinkers.Scroll.Spawner in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Scroll.Spawner.pas',
  DelphiDoom.Thinkers.Floor.Types in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Floor.Types.pas',
  DelphiDoom.Thinkers.Floor.Games in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Floor.Games.pas',
  DelphiDoom.Thinkers.Floor.Machine in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Floor.Machine.pas',
  DelphiDoom.Thinkers.Ceiling.Types in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Ceiling.Types.pas',
  DelphiDoom.Thinkers.Ceiling.Games in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Ceiling.Games.pas',
  DelphiDoom.Thinkers.Ceiling.Machine in '..\IdTech1\Thinkers\DelphiDoom.Thinkers.Ceiling.Machine.pas',
  DelphiDoom.Tests.Thinkers.Fakes in 'Source\DelphiDoom.Tests.Thinkers.Fakes.pas',
  DelphiDoom.Tests.Thinkers.OldLights in 'Source\DelphiDoom.Tests.Thinkers.OldLights.pas',
  DelphiDoom.Tests.Thinkers.OldPlanes in 'Source\DelphiDoom.Tests.Thinkers.OldPlanes.pas',
  DelphiDoom.Tests.Thinkers.PlaneFakes in 'Source\DelphiDoom.Tests.Thinkers.PlaneFakes.pas',
  DelphiDoom.Tests.Thinkers.LightNeighbors in 'Source\DelphiDoom.Tests.Thinkers.LightNeighbors.pas',
  DelphiDoom.Tests.Thinkers.LightFlickerRules in 'Source\DelphiDoom.Tests.Thinkers.LightFlickerRules.pas',
  DelphiDoom.Tests.Thinkers.LightFireFlicker in 'Source\DelphiDoom.Tests.Thinkers.LightFireFlicker.pas',
  DelphiDoom.Tests.Thinkers.LightFlash in 'Source\DelphiDoom.Tests.Thinkers.LightFlash.pas',
  DelphiDoom.Tests.Thinkers.LightStrobe in 'Source\DelphiDoom.Tests.Thinkers.LightStrobe.pas',
  DelphiDoom.Tests.Thinkers.LightGlow in 'Source\DelphiDoom.Tests.Thinkers.LightGlow.pas',
  DelphiDoom.Tests.Thinkers.LightScripted in 'Source\DelphiDoom.Tests.Thinkers.LightScripted.pas',
  DelphiDoom.Tests.Thinkers.LightPhase in 'Source\DelphiDoom.Tests.Thinkers.LightPhase.pas',
  DelphiDoom.Tests.Thinkers.LightSequence in 'Source\DelphiDoom.Tests.Thinkers.LightSequence.pas',
  DelphiDoom.Tests.Thinkers.LightGames in 'Source\DelphiDoom.Tests.Thinkers.LightGames.pas',
  DelphiDoom.Tests.Thinkers.PlatFakes in 'Source\DelphiDoom.Tests.Thinkers.PlatFakes.pas',
  DelphiDoom.Tests.Thinkers.OldPlats in 'Source\DelphiDoom.Tests.Thinkers.OldPlats.pas',
  DelphiDoom.Tests.Thinkers.PlatGames in 'Source\DelphiDoom.Tests.Thinkers.PlatGames.pas',
  DelphiDoom.Tests.Thinkers.PlatMachine in 'Source\DelphiDoom.Tests.Thinkers.PlatMachine.pas',
  DelphiDoom.Tests.Thinkers.PlatUdmfMachine in 'Source\DelphiDoom.Tests.Thinkers.PlatUdmfMachine.pas',
  DelphiDoom.Tests.Thinkers.TeleportGeometry in 'Source\DelphiDoom.Tests.Thinkers.TeleportGeometry.pas',
  DelphiDoom.Tests.Thinkers.TeleportLineExit in 'Source\DelphiDoom.Tests.Thinkers.TeleportLineExit.pas',
  DelphiDoom.Tests.Thinkers.TeleportPlacement in 'Source\DelphiDoom.Tests.Thinkers.TeleportPlacement.pas',
  DelphiDoom.Tests.Thinkers.DoorFakes in 'Source\DelphiDoom.Tests.Thinkers.DoorFakes.pas',
  DelphiDoom.Tests.Thinkers.OldDoors in 'Source\DelphiDoom.Tests.Thinkers.OldDoors.pas',
  DelphiDoom.Tests.Thinkers.DoorProfiles in 'Source\DelphiDoom.Tests.Thinkers.DoorProfiles.pas',
  DelphiDoom.Tests.Thinkers.DoorRunner in 'Source\DelphiDoom.Tests.Thinkers.DoorRunner.pas',
  DelphiDoom.Tests.Thinkers.DoorSpawner in 'Source\DelphiDoom.Tests.Thinkers.DoorSpawner.pas',
  DelphiDoom.Tests.Thinkers.PlaneRules in 'Source\DelphiDoom.Tests.Thinkers.PlaneRules.pas',
  DelphiDoom.Tests.Thinkers.PlaneMover in 'Source\DelphiDoom.Tests.Thinkers.PlaneMover.pas',
  DelphiDoom.Tests.Thinkers.PlaneWaggle in 'Source\DelphiDoom.Tests.Thinkers.PlaneWaggle.pas',
  DelphiDoom.Tests.Thinkers.OldList in 'Source\DelphiDoom.Tests.Thinkers.OldList.pas',
  DelphiDoom.Tests.Thinkers.List in 'Source\DelphiDoom.Tests.Thinkers.List.pas',
  DelphiDoom.Tests.Thinkers.BodyQueue in 'Source\DelphiDoom.Tests.Thinkers.BodyQueue.pas',
  DelphiDoom.Tests.Thinkers.ActiveSlots in 'Source\DelphiDoom.Tests.Thinkers.ActiveSlots.pas',
  DelphiDoom.Tests.Thinkers.LevelTotals in 'Source\DelphiDoom.Tests.Thinkers.LevelTotals.pas',
  DelphiDoom.Tests.Thinkers.RespawnQueue in 'Source\DelphiDoom.Tests.Thinkers.RespawnQueue.pas',
  DelphiDoom.Tests.Thinkers.OldScroll in 'Source\DelphiDoom.Tests.Thinkers.OldScroll.pas',
  DelphiDoom.Tests.Thinkers.ScrollStep in 'Source\DelphiDoom.Tests.Thinkers.ScrollStep.pas',
  DelphiDoom.Tests.Thinkers.ScrollSpawner in 'Source\DelphiDoom.Tests.Thinkers.ScrollSpawner.pas',
  DelphiDoom.Tests.Thinkers.OldCeilings in 'Source\DelphiDoom.Tests.Thinkers.OldCeilings.pas',
  DelphiDoom.Tests.Thinkers.OldCeilingsHeretic in 'Source\DelphiDoom.Tests.Thinkers.OldCeilingsHeretic.pas',
  DelphiDoom.Tests.Thinkers.CeilingMachine in 'Source\DelphiDoom.Tests.Thinkers.CeilingMachine.pas',
  DelphiDoom.Tests.Thinkers.OldFloors in 'Source\DelphiDoom.Tests.Thinkers.OldFloors.pas',
  DelphiDoom.Tests.Thinkers.FloorMachine in 'Source\DelphiDoom.Tests.Thinkers.FloorMachine.pas';

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
