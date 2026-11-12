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
  DelphiDoom.Racing.Types in '..\Libs\Racing\DelphiDoom.Racing.Types.pas',
  DelphiDoom.Racing.Intf in '..\Libs\Racing\DelphiDoom.Racing.Intf.pas',
  DelphiDoom.Racing.Math in '..\Libs\Racing\DelphiDoom.Racing.Math.pas',
  DelphiDoom.Racing.CarData in '..\Libs\Racing\DelphiDoom.Racing.CarData.pas',
  DelphiDoom.Racing.GearBox in '..\Libs\Racing\DelphiDoom.Racing.GearBox.pas',
  DelphiDoom.Racing.Ground in '..\Libs\Racing\DelphiDoom.Racing.Ground.pas',
  DelphiDoom.Racing.CarSounds in '..\Libs\Racing\DelphiDoom.Racing.CarSounds.pas',
  DelphiDoom.Racing.Particles in '..\Libs\Racing\DelphiDoom.Racing.Particles.pas',
  DelphiDoom.Racing.Track in '..\Libs\Racing\DelphiDoom.Racing.Track.pas',
  DelphiDoom.Racing.Physics in '..\Libs\Racing\DelphiDoom.Racing.Physics.pas',
  DelphiDoom.Racing.AiDriver in '..\Libs\Racing\DelphiDoom.Racing.AiDriver.pas',
  DelphiDoom.Racing.PlayerDriver in '..\Libs\Racing\DelphiDoom.Racing.PlayerDriver.pas',
  DelphiDoom.Racing.ScoreTable in '..\Libs\Racing\DelphiDoom.Racing.ScoreTable.pas',
  DelphiDoom.Racing.GridAssigner in '..\Libs\Racing\DelphiDoom.Racing.GridAssigner.pas',
  DelphiDoom.Racing.RaceState in '..\Libs\Racing\DelphiDoom.Racing.RaceState.pas',
  DelphiDoom.Racing.Championship in '..\Libs\Racing\DelphiDoom.Racing.Championship.pas',
  DelphiDoom.Racing.PathReader in '..\Libs\Racing\DelphiDoom.Racing.PathReader.pas',
  DelphiDoom.Racing.Factory in '..\Libs\Racing\DelphiDoom.Racing.Factory.pas',
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
  DelphiDoom.Racing.TextFormat in '..\Libs\Racing\DelphiDoom.Racing.TextFormat.pas',
  DelphiDoom.Tests.Racing.TextFormat in 'Source\DelphiDoom.Tests.Racing.TextFormat.pas';

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
