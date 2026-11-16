{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the racing library (DUnitX)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Racing;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Racing.Types in '..\Games\Racing\DelphiDoom.Racing.Types.pas',
  DelphiDoom.Racing.Intf in '..\Games\Racing\DelphiDoom.Racing.Intf.pas',
  DelphiDoom.Racing.Math in '..\Games\Racing\DelphiDoom.Racing.Math.pas',
  DelphiDoom.Racing.CarData in '..\Games\Racing\DelphiDoom.Racing.CarData.pas',
  DelphiDoom.Racing.GearBox in '..\Games\Racing\DelphiDoom.Racing.GearBox.pas',
  DelphiDoom.Racing.Ground in '..\Games\Racing\DelphiDoom.Racing.Ground.pas',
  DelphiDoom.Racing.CarSounds in '..\Games\Racing\DelphiDoom.Racing.CarSounds.pas',
  DelphiDoom.Racing.Particles in '..\Games\Racing\DelphiDoom.Racing.Particles.pas',
  DelphiDoom.Racing.Track in '..\Games\Racing\DelphiDoom.Racing.Track.pas',
  DelphiDoom.Racing.Physics in '..\Games\Racing\DelphiDoom.Racing.Physics.pas',
  DelphiDoom.Racing.AiDriver in '..\Games\Racing\DelphiDoom.Racing.AiDriver.pas',
  DelphiDoom.Racing.PlayerDriver in '..\Games\Racing\DelphiDoom.Racing.PlayerDriver.pas',
  DelphiDoom.Racing.ScoreTable in '..\Games\Racing\DelphiDoom.Racing.ScoreTable.pas',
  DelphiDoom.Racing.GridAssigner in '..\Games\Racing\DelphiDoom.Racing.GridAssigner.pas',
  DelphiDoom.Racing.RaceState in '..\Games\Racing\DelphiDoom.Racing.RaceState.pas',
  DelphiDoom.Racing.Championship in '..\Games\Racing\DelphiDoom.Racing.Championship.pas',
  DelphiDoom.Racing.PathReader in '..\Games\Racing\DelphiDoom.Racing.PathReader.pas',
  DelphiDoom.Racing.Factory in '..\Games\Racing\DelphiDoom.Racing.Factory.pas',
  DelphiDoom.Tests.Racing.Scenarios in 'Source\DelphiDoom.Tests.Racing.Scenarios.pas',
  DelphiDoom.Tests.Racing.Fakes in 'Source\DelphiDoom.Tests.Racing.Fakes.pas',
  DelphiDoom.Tests.Racing.LibraryTarget in 'Source\DelphiDoom.Tests.Racing.LibraryTarget.pas',
  DelphiDoom.Tests.Racing.Parity in 'Source\DelphiDoom.Tests.Racing.Parity.pas',
  DelphiDoom.Tests.Racing.Math in 'Source\DelphiDoom.Tests.Racing.Math.pas',
  DelphiDoom.Tests.Racing.GearBox in 'Source\DelphiDoom.Tests.Racing.GearBox.pas',
  DelphiDoom.Tests.Racing.Ground in 'Source\DelphiDoom.Tests.Racing.Ground.pas',
  DelphiDoom.Tests.Racing.CarSounds in 'Source\DelphiDoom.Tests.Racing.CarSounds.pas',
  DelphiDoom.Tests.Racing.Particles in 'Source\DelphiDoom.Tests.Racing.Particles.pas',
  DelphiDoom.Tests.Racing.Track in 'Source\DelphiDoom.Tests.Racing.Track.pas',
  DelphiDoom.Tests.Racing.Physics in 'Source\DelphiDoom.Tests.Racing.Physics.pas',
  DelphiDoom.Tests.Racing.AiDriver in 'Source\DelphiDoom.Tests.Racing.AiDriver.pas',
  DelphiDoom.Tests.Racing.PlayerDriver in 'Source\DelphiDoom.Tests.Racing.PlayerDriver.pas',
  DelphiDoom.Tests.Racing.ScoreTable in 'Source\DelphiDoom.Tests.Racing.ScoreTable.pas',
  DelphiDoom.Tests.Racing.GridAssigner in 'Source\DelphiDoom.Tests.Racing.GridAssigner.pas',
  DelphiDoom.Tests.Racing.PathReader in 'Source\DelphiDoom.Tests.Racing.PathReader.pas',
  DelphiDoom.Tests.Racing.CarData in 'Source\DelphiDoom.Tests.Racing.CarData.pas',
  DelphiDoom.Racing.TextFormat in '..\Games\Racing\DelphiDoom.Racing.TextFormat.pas',
  DelphiDoom.Tests.Racing.TextFormat in 'Source\DelphiDoom.Tests.Racing.TextFormat.pas',
  DelphiDoom.Racing.PlayerEventRelay in '..\Games\Racing\DelphiDoom.Racing.PlayerEventRelay.pas',
  DelphiDoom.Racing.RaceController in '..\Games\Racing\DelphiDoom.Racing.RaceController.pas',
  DelphiDoom.Tests.Racing.RaceController in 'Source\DelphiDoom.Tests.Racing.RaceController.pas',
  DelphiDoom.Racing.CarCollisions in '..\Games\Racing\DelphiDoom.Racing.CarCollisions.pas',
  DelphiDoom.Tests.Racing.CarCollisions in 'Source\DelphiDoom.Tests.Racing.CarCollisions.pas',
  DelphiDoom.Racing.SaveGameCodec in '..\Games\Racing\DelphiDoom.Racing.SaveGameCodec.pas',
  DelphiDoom.Tests.Racing.SaveGameCodec in 'Source\DelphiDoom.Tests.Racing.SaveGameCodec.pas';

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
