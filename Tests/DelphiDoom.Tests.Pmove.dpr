{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the pmove library - the player movement of        }
{  Quake III Arena (DUnitX)                                                    }
{                                                                              }
{  The library derives from the Quake III Arena GPL Source Code (GPL v2 or     }
{  later): this test program is GPL v2 or later as well                        }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Pmove;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Log in '..\Framework\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Recorder in '..\Framework\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Net.Q3.Types in '..\Libs\NetQ3\DelphiDoom.Net.Q3.Types.pas',
  DelphiDoom.Collision.Q3.Types in '..\Libs\Collision\DelphiDoom.Collision.Q3.Types.pas',
  DelphiDoom.Collision.Q3.Intf in '..\Libs\Collision\DelphiDoom.Collision.Q3.Intf.pas',
  DelphiDoom.Collision.Q3.Math in '..\Libs\Collision\DelphiDoom.Collision.Q3.Math.pas',
  DelphiDoom.Collision.Q3.ClipMap in '..\Libs\Collision\DelphiDoom.Collision.Q3.ClipMap.pas',
  DelphiDoom.Collision.Q3.BoxHull in '..\Libs\Collision\DelphiDoom.Collision.Q3.BoxHull.pas',
  DelphiDoom.Collision.Q3.AreaFlood in '..\Libs\Collision\DelphiDoom.Collision.Q3.AreaFlood.pas',
  DelphiDoom.Collision.Q3.Loader in '..\Libs\Collision\DelphiDoom.Collision.Q3.Loader.pas',
  DelphiDoom.Collision.Q3.LeafLister in '..\Libs\Collision\DelphiDoom.Collision.Q3.LeafLister.pas',
  DelphiDoom.Collision.Q3.PointLocator in '..\Libs\Collision\DelphiDoom.Collision.Q3.PointLocator.pas',
  DelphiDoom.Collision.Q3.PositionTester in '..\Libs\Collision\DelphiDoom.Collision.Q3.PositionTester.pas',
  DelphiDoom.Collision.Q3.Tracer in '..\Libs\Collision\DelphiDoom.Collision.Q3.Tracer.pas',
  DelphiDoom.Collision.Q3.Model in '..\Libs\Collision\DelphiDoom.Collision.Q3.Model.pas',
  DelphiDoom.Collision.Q3.Factory in '..\Libs\Collision\DelphiDoom.Collision.Q3.Factory.pas',
  DelphiDoom.Pmove.Types in '..\Libs\Pmove\DelphiDoom.Pmove.Types.pas',
  DelphiDoom.Pmove.Intf in '..\Libs\Pmove\DelphiDoom.Pmove.Intf.pas',
  DelphiDoom.Pmove.Vector in '..\Libs\Pmove\DelphiDoom.Pmove.Vector.pas',
  DelphiDoom.Pmove.Items in '..\Libs\Pmove\DelphiDoom.Pmove.Items.pas',
  DelphiDoom.Pmove.State in '..\Libs\Pmove\DelphiDoom.Pmove.State.pas',
  DelphiDoom.Pmove.Events in '..\Libs\Pmove\DelphiDoom.Pmove.Events.pas',
  DelphiDoom.Pmove.Physics in '..\Libs\Pmove\DelphiDoom.Pmove.Physics.pas',
  DelphiDoom.Pmove.Slider in '..\Libs\Pmove\DelphiDoom.Pmove.Slider.pas',
  DelphiDoom.Pmove.Body in '..\Libs\Pmove\DelphiDoom.Pmove.Body.pas',
  DelphiDoom.Pmove.Ground in '..\Libs\Pmove\DelphiDoom.Pmove.Ground.pas',
  DelphiDoom.Pmove.AirMover in '..\Libs\Pmove\DelphiDoom.Pmove.AirMover.pas',
  DelphiDoom.Pmove.WaterMover in '..\Libs\Pmove\DelphiDoom.Pmove.WaterMover.pas',
  DelphiDoom.Pmove.FlyMover in '..\Libs\Pmove\DelphiDoom.Pmove.FlyMover.pas',
  DelphiDoom.Pmove.WalkMover in '..\Libs\Pmove\DelphiDoom.Pmove.WalkMover.pas',
  DelphiDoom.Pmove.Weapon in '..\Libs\Pmove\DelphiDoom.Pmove.Weapon.pas',
  DelphiDoom.Pmove.Footsteps in '..\Libs\Pmove\DelphiDoom.Pmove.Footsteps.pas',
  DelphiDoom.Pmove.ViewAngles in '..\Libs\Pmove\DelphiDoom.Pmove.ViewAngles.pas',
  DelphiDoom.Pmove.Parts in '..\Libs\Pmove\DelphiDoom.Pmove.Parts.pas',
  DelphiDoom.Pmove.Mover in '..\Libs\Pmove\DelphiDoom.Pmove.Mover.pas',
  DelphiDoom.Pmove.CollisionTrace in '..\Libs\Pmove\DelphiDoom.Pmove.CollisionTrace.pas',
  DelphiDoom.Pmove.Factory in '..\Libs\Pmove\DelphiDoom.Pmove.Factory.pas',
  DelphiDoom.Tests.Shared.Files in 'Source\DelphiDoom.Tests.Shared.Files.pas',
  DelphiDoom.Tests.Shared.Fnv in 'Source\DelphiDoom.Tests.Shared.Fnv.pas',
  DelphiDoom.Tests.Shared.Skip in 'Source\DelphiDoom.Tests.Shared.Skip.pas',
  DelphiDoom.Tests.Collision.Q3Support in 'Source\DelphiDoom.Tests.Collision.Q3Support.pas',
  DelphiDoom.Tests.Pmove.Support.World in 'Source\DelphiDoom.Tests.Pmove.Support.World.pas',
  DelphiDoom.Tests.Pmove.Support.Golden in 'Source\DelphiDoom.Tests.Pmove.Support.Golden.pas',
  DelphiDoom.Tests.Pmove.Parity in 'Source\DelphiDoom.Tests.Pmove.Parity.pas',
  DelphiDoom.Tests.Pmove.Mover in 'Source\DelphiDoom.Tests.Pmove.Mover.pas',
  DelphiDoom.Tests.Pmove.Parts in 'Source\DelphiDoom.Tests.Pmove.Parts.pas',
  DelphiDoom.Tests.Pmove.Collision in 'Source\DelphiDoom.Tests.Pmove.Collision.pas';

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
