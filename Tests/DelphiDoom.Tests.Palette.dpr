{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the palette library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Palette;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Video.Intf in '..\Framework\Video\DelphiDoom.Video.Intf.pas',
  DelphiDoom.Palette.Converter in '..\Framework\Palette\DelphiDoom.Palette.Converter.pas',
  DelphiDoom.Palette.ScreenPalette in '..\Framework\Palette\DelphiDoom.Palette.ScreenPalette.pas',
  DelphiDoom.Video.SizeLimiter in '..\Framework\Video\DelphiDoom.Video.SizeLimiter.pas',
  DelphiDoom.Video.MemoryStallHack in '..\Framework\Video\DelphiDoom.Video.MemoryStallHack.pas',
  DelphiDoom.Video.WindowsDisplayMetrics in '..\Framework\Video\DelphiDoom.Video.WindowsDisplayMetrics.pas',
  DelphiDoom.Video.Services in '..\Framework\Video\DelphiDoom.Video.Services.pas',
  DelphiDoom.Video.Factory in '..\Framework\Video\DelphiDoom.Video.Factory.pas',
  DelphiDoom.Palette.Types in '..\Framework\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.Intf in '..\Framework\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Palette.GammaData in '..\Framework\Palette\DelphiDoom.Palette.GammaData.pas',
  DelphiDoom.Palette.Profiles in '..\Framework\Palette\DelphiDoom.Palette.Profiles.pas',
  DelphiDoom.Palette.ColorMatcher in '..\Framework\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Palette.NearestColor in '..\Framework\Palette\DelphiDoom.Palette.NearestColor.pas',
  DelphiDoom.Palette.Builder in '..\Framework\Palette\DelphiDoom.Palette.Builder.pas',
  DelphiDoom.Palette.TranslationBuilder in '..\Framework\Palette\DelphiDoom.Palette.TranslationBuilder.pas',
  DelphiDoom.Palette.PlayerTranslations.Doom in '..\Framework\Palette\DelphiDoom.Palette.PlayerTranslations.Doom.pas',
  DelphiDoom.Palette.PlayerTranslations.Heretic in '..\Framework\Palette\DelphiDoom.Palette.PlayerTranslations.Heretic.pas',
  DelphiDoom.Palette.PlayerTranslations.Strife in '..\Framework\Palette\DelphiDoom.Palette.PlayerTranslations.Strife.pas',
  DelphiDoom.Palette.GammaTables in '..\Framework\Palette\DelphiDoom.Palette.GammaTables.pas',
  DelphiDoom.Palette.ColormapPreparer in '..\Framework\Palette\DelphiDoom.Palette.ColormapPreparer.pas',
  DelphiDoom.Palette.LightTables in '..\Framework\Palette\DelphiDoom.Palette.LightTables.pas',
  DelphiDoom.Palette.TranslationNames in '..\Framework\Palette\DelphiDoom.Palette.TranslationNames.pas',
  DelphiDoom.Palette.TranslationBlood in '..\Framework\Palette\DelphiDoom.Palette.TranslationBlood.pas',
  DelphiDoom.Palette.PrecalcTables in '..\Framework\Palette\DelphiDoom.Palette.PrecalcTables.pas',
  DelphiDoom.Palette.BufferFixer in '..\Framework\Palette\DelphiDoom.Palette.BufferFixer.pas',
  DelphiDoom.Palette.Unpacker in '..\Framework\Palette\DelphiDoom.Palette.Unpacker.pas',
  DelphiDoom.Palette.Factory in '..\Framework\Palette\DelphiDoom.Palette.Factory.pas',
  DelphiDoom.Tests.Palette.Digest in 'Source\DelphiDoom.Tests.Palette.Digest.pas',
  DelphiDoom.Tests.Palette.Fixtures in 'Source\DelphiDoom.Tests.Palette.Fixtures.pas',
  DelphiDoom.Tests.Palette.Fakes in 'Source\DelphiDoom.Tests.Palette.Fakes.pas',
  DelphiDoom.Tests.Palette.Parity in 'Source\DelphiDoom.Tests.Palette.Parity.pas',
  DelphiDoom.Tests.Palette.Behavior in 'Source\DelphiDoom.Tests.Palette.Behavior.pas',
  DelphiDoom.Tests.Palette.TranslationBlood in 'Source\DelphiDoom.Tests.Palette.TranslationBlood.pas',
  DelphiDoom.Palette.GamePaletteData in '..\Framework\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Palette.GamePalettes in '..\Framework\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Tests.Sound.Digest in 'Source\DelphiDoom.Tests.Sound.Digest.pas',
  DelphiDoom.Tests.Font.Golden in 'Source\DelphiDoom.Tests.Font.Golden.pas',
  DelphiDoom.Tests.Font.Scenarios in 'Source\DelphiDoom.Tests.Font.Scenarios.pas',
  DelphiDoom.Palette.ColorRegionLumps in '..\Framework\Palette\DelphiDoom.Palette.ColorRegionLumps.pas',
  DelphiDoom.Tests.Palette.ColorRegionLumps in 'Source\DelphiDoom.Tests.Palette.ColorRegionLumps.pas',
  DelphiDoom.Tests.Palette.GamePalettes in 'Source\DelphiDoom.Tests.Palette.GamePalettes.pas',
  DelphiDoom.Tests.Palette.NearestColor in 'Source\DelphiDoom.Tests.Palette.NearestColor.pas',
  DelphiDoom.Tests.Palette.ScreenPalette in 'Source\DelphiDoom.Tests.Palette.ScreenPalette.pas';

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
