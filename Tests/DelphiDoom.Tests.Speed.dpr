{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the speed library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Speed;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.GameData.Types in '..\Libs\GameData\DelphiDoom.GameData.Types.pas',
  DelphiDoom.GameData.Intf in '..\Libs\GameData\DelphiDoom.GameData.Intf.pas',
  DelphiDoom.GameData.PatchBuilder in '..\Libs\GameData\DelphiDoom.GameData.PatchBuilder.pas',
  DelphiDoom.GameData.WadComposer in '..\Libs\GameData\DelphiDoom.GameData.WadComposer.pas',
  DelphiDoom.GameData.Factory in '..\Libs\GameData\DelphiDoom.GameData.Factory.pas',
  DelphiDoom.Speed.Types in '..\Libs\Speed\DelphiDoom.Speed.Types.pas',
  DelphiDoom.Speed.Intf in '..\Libs\Speed\DelphiDoom.Speed.Intf.pas',
  DelphiDoom.Speed.Names in '..\Libs\Speed\DelphiDoom.Speed.Names.pas',
  DelphiDoom.Speed.Container in '..\Libs\Speed\DelphiDoom.Speed.Container.pas',
  DelphiDoom.Speed.PaletteBuilder in '..\Libs\Speed\DelphiDoom.Speed.PaletteBuilder.pas',
  DelphiDoom.Speed.Is2Decoder in '..\Libs\Speed\DelphiDoom.Speed.Is2Decoder.pas',
  DelphiDoom.Speed.CircuitReader in '..\Libs\Speed\DelphiDoom.Speed.CircuitReader.pas',
  DelphiDoom.Speed.LevelBuilder in '..\Libs\Speed\DelphiDoom.Speed.LevelBuilder.pas',
  DelphiDoom.Speed.FontData in '..\Libs\Speed\DelphiDoom.Speed.FontData.pas',
  DelphiDoom.Speed.FontBuilder in '..\Libs\Speed\DelphiDoom.Speed.FontBuilder.pas',
  DelphiDoom.Speed.RawSound in '..\Libs\Speed\DelphiDoom.Speed.RawSound.pas',
  DelphiDoom.Speed.MapBitmapBuilder in '..\Libs\Speed\DelphiDoom.Speed.MapBitmapBuilder.pas',
  DelphiDoom.Speed.Translator in '..\Libs\Speed\DelphiDoom.Speed.Translator.pas',
  DelphiDoom.Speed.Factory in '..\Libs\Speed\DelphiDoom.Speed.Factory.pas',
  DelphiDoom.Tests.GameData.Scenarios in 'Source\DelphiDoom.Tests.GameData.Scenarios.pas',
  DelphiDoom.Tests.Speed.Fakes in 'Source\DelphiDoom.Tests.Speed.Fakes.pas',
  DelphiDoom.Tests.Speed.JclBuilder in 'Source\DelphiDoom.Tests.Speed.JclBuilder.pas',
  DelphiDoom.Tests.Speed.Names in 'Source\DelphiDoom.Tests.Speed.Names.pas',
  DelphiDoom.Tests.Speed.Container in 'Source\DelphiDoom.Tests.Speed.Container.pas',
  DelphiDoom.Tests.Speed.Is2Decoder in 'Source\DelphiDoom.Tests.Speed.Is2Decoder.pas',
  DelphiDoom.Tests.Speed.PaletteBuilder in 'Source\DelphiDoom.Tests.Speed.PaletteBuilder.pas',
  DelphiDoom.Tests.Speed.CircuitReader in 'Source\DelphiDoom.Tests.Speed.CircuitReader.pas',
  DelphiDoom.Tests.Speed.LevelBuilder in 'Source\DelphiDoom.Tests.Speed.LevelBuilder.pas',
  DelphiDoom.Tests.Speed.RawSound in 'Source\DelphiDoom.Tests.Speed.RawSound.pas',
  DelphiDoom.Tests.Speed.MapBitmapBuilder in 'Source\DelphiDoom.Tests.Speed.MapBitmapBuilder.pas',
  DelphiDoom.Tests.Speed.Translator in 'Source\DelphiDoom.Tests.Speed.Translator.pas';

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
