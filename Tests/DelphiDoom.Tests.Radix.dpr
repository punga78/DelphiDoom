{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the radix library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Radix;

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
  DelphiDoom.Radix.Types in '..\Libs\Radix\DelphiDoom.Radix.Types.pas',
  DelphiDoom.Radix.Intf in '..\Libs\Radix\DelphiDoom.Radix.Intf.pas',
  DelphiDoom.Radix.Container in '..\Libs\Radix\DelphiDoom.Radix.Container.pas',
  DelphiDoom.Radix.PaletteBuilder in '..\Libs\Radix\DelphiDoom.Radix.PaletteBuilder.pas',
  DelphiDoom.Radix.Context in '..\Libs\Radix\DelphiDoom.Radix.Context.pas',
  DelphiDoom.Radix.BitmapTable in '..\Libs\Radix\DelphiDoom.Radix.BitmapTable.pas',
  DelphiDoom.Radix.PalettePart in '..\Libs\Radix\DelphiDoom.Radix.PalettePart.pas',
  DelphiDoom.Radix.TexturePart in '..\Libs\Radix\DelphiDoom.Radix.TexturePart.pas',
  DelphiDoom.Radix.FlatPart in '..\Libs\Radix\DelphiDoom.Radix.FlatPart.pas',
  DelphiDoom.Radix.GraphicsPart in '..\Libs\Radix\DelphiDoom.Radix.GraphicsPart.pas',
  DelphiDoom.Radix.SmallFontPart in '..\Libs\Radix\DelphiDoom.Radix.SmallFontPart.pas',
  DelphiDoom.Radix.LumpGroupPart in '..\Libs\Radix\DelphiDoom.Radix.LumpGroupPart.pas',
  DelphiDoom.Radix.Translator in '..\Libs\Radix\DelphiDoom.Radix.Translator.pas',
  DelphiDoom.Radix.Factory in '..\Libs\Radix\DelphiDoom.Radix.Factory.pas',
  DelphiDoom.Tests.GameData.Scenarios in 'Source\DelphiDoom.Tests.GameData.Scenarios.pas',
  DelphiDoom.Tests.Radix.DatBuilder in 'Source\DelphiDoom.Tests.Radix.DatBuilder.pas',
  DelphiDoom.Tests.Radix.Container in 'Source\DelphiDoom.Tests.Radix.Container.pas',
  DelphiDoom.Tests.Radix.PaletteBuilder in 'Source\DelphiDoom.Tests.Radix.PaletteBuilder.pas',
  DelphiDoom.Tests.Radix.TexturePart in 'Source\DelphiDoom.Tests.Radix.TexturePart.pas',
  DelphiDoom.Tests.Radix.FlatPart in 'Source\DelphiDoom.Tests.Radix.FlatPart.pas',
  DelphiDoom.Tests.Radix.GraphicsPart in 'Source\DelphiDoom.Tests.Radix.GraphicsPart.pas',
  DelphiDoom.Tests.Radix.SmallFontPart in 'Source\DelphiDoom.Tests.Radix.SmallFontPart.pas',
  DelphiDoom.Tests.Radix.LumpGroupPart in 'Source\DelphiDoom.Tests.Radix.LumpGroupPart.pas',
  DelphiDoom.Tests.Radix.Translator in 'Source\DelphiDoom.Tests.Radix.Translator.pas';

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
