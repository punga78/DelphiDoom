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
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Libs\MathCore\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.MathCore.TableFineSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineSine.pas',
  DelphiDoom.MathCore.TableFineTangent in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineTangent.pas',
  DelphiDoom.MathCore.TableTanToAngle in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngle.pas',
  DelphiDoom.MathCore.TableTanToAngleEx in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngleEx.pas',
  DelphiDoom.MathCore.TableFixedSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFixedSine.pas',
  DelphiDoom.MathCore.TableRandom in '..\Libs\MathCore\DelphiDoom.MathCore.TableRandom.pas',
  DelphiDoom.MathCore.TableSysRandom in '..\Libs\MathCore\DelphiDoom.MathCore.TableSysRandom.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.FixedMath in '..\Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.Trigonometry in '..\Libs\MathCore\DelphiDoom.MathCore.Trigonometry.pas',
  DelphiDoom.MathCore.VectorMath in '..\Libs\MathCore\DelphiDoom.MathCore.VectorMath.pas',
  DelphiDoom.MathCore.BoundingBox in '..\Libs\MathCore\DelphiDoom.MathCore.BoundingBox.pas',
  DelphiDoom.MathCore.IntegerStack in '..\Libs\MathCore\DelphiDoom.MathCore.IntegerStack.pas',
  DelphiDoom.MathCore.IntegerQueue in '..\Libs\MathCore\DelphiDoom.MathCore.IntegerQueue.pas',
  DelphiDoom.MathCore.GameRandom in '..\Libs\MathCore\DelphiDoom.MathCore.GameRandom.pas',
  DelphiDoom.MathCore.SystemEntropySource in '..\Libs\MathCore\DelphiDoom.MathCore.SystemEntropySource.pas',
  DelphiDoom.MathCore.StringHashTable in '..\Libs\MathCore\DelphiDoom.MathCore.StringHashTable.pas',
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.MathCore.Sha1 in '..\Libs\MathCore\DelphiDoom.MathCore.Sha1.pas',
  DelphiDoom.MathCore.Factory in '..\Libs\MathCore\DelphiDoom.MathCore.Factory.pas',
  DelphiDoom.Thinkers.Light.Types in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Types.pas',
  DelphiDoom.Thinkers.Light.Intf in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Intf.pas',
  DelphiDoom.Thinkers.Light.Neighbors in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Neighbors.pas',
  DelphiDoom.Thinkers.Light.FlickerRules.Standard in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.FlickerRules.Standard.pas',
  DelphiDoom.Thinkers.Light.FlickerRules.Strife in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.FlickerRules.Strife.pas',
  DelphiDoom.Thinkers.Light.FireFlicker in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.FireFlicker.pas',
  DelphiDoom.Thinkers.Light.Flash in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Flash.pas',
  DelphiDoom.Thinkers.Light.Strobe in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Strobe.pas',
  DelphiDoom.Thinkers.Light.Glow in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Glow.pas',
  DelphiDoom.Thinkers.Light.Scripted in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Scripted.pas',
  DelphiDoom.Thinkers.Light.Phase in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Phase.pas',
  DelphiDoom.Thinkers.Light.Sequence in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Sequence.pas',
  DelphiDoom.Thinkers.Light.Games in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Games.pas',
  DelphiDoom.Thinkers.Light.Factory in '..\Libs\Thinkers\DelphiDoom.Thinkers.Light.Factory.pas',
  DelphiDoom.Thinkers.Plane.Types in '..\Libs\Thinkers\DelphiDoom.Thinkers.Plane.Types.pas',
  DelphiDoom.Thinkers.Plane.Intf in '..\Libs\Thinkers\DelphiDoom.Thinkers.Plane.Intf.pas',
  DelphiDoom.Thinkers.Plane.Rules in '..\Libs\Thinkers\DelphiDoom.Thinkers.Plane.Rules.pas',
  DelphiDoom.Thinkers.Plane.Mover in '..\Libs\Thinkers\DelphiDoom.Thinkers.Plane.Mover.pas',
  DelphiDoom.Thinkers.Plane.Waggle in '..\Libs\Thinkers\DelphiDoom.Thinkers.Plane.Waggle.pas',
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
  DelphiDoom.Tests.Thinkers.PlaneRules in 'Source\DelphiDoom.Tests.Thinkers.PlaneRules.pas',
  DelphiDoom.Tests.Thinkers.PlaneMover in 'Source\DelphiDoom.Tests.Thinkers.PlaneMover.pas',
  DelphiDoom.Tests.Thinkers.PlaneWaggle in 'Source\DelphiDoom.Tests.Thinkers.PlaneWaggle.pas';

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
