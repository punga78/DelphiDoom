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
  DelphiDoom.Video.Intf in '..\Libs\Video\DelphiDoom.Video.Intf.pas',
  DelphiDoom.Video.PaletteConverter in '..\Libs\Video\DelphiDoom.Video.PaletteConverter.pas',
  DelphiDoom.Video.SizeLimiter in '..\Libs\Video\DelphiDoom.Video.SizeLimiter.pas',
  DelphiDoom.Video.MemoryStallHack in '..\Libs\Video\DelphiDoom.Video.MemoryStallHack.pas',
  DelphiDoom.Video.WindowsDisplayMetrics in '..\Libs\Video\DelphiDoom.Video.WindowsDisplayMetrics.pas',
  DelphiDoom.Video.Services in '..\Libs\Video\DelphiDoom.Video.Services.pas',
  DelphiDoom.Video.Factory in '..\Libs\Video\DelphiDoom.Video.Factory.pas',
  DelphiDoom.Palette.Types in '..\Libs\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.Intf in '..\Libs\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Palette.GammaData in '..\Libs\Palette\DelphiDoom.Palette.GammaData.pas',
  DelphiDoom.Palette.Profiles in '..\Libs\Palette\DelphiDoom.Palette.Profiles.pas',
  DelphiDoom.Palette.ColorMatcher in '..\Libs\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Palette.Builder in '..\Libs\Palette\DelphiDoom.Palette.Builder.pas',
  DelphiDoom.Palette.TranslationBuilder in '..\Libs\Palette\DelphiDoom.Palette.TranslationBuilder.pas',
  DelphiDoom.Palette.PlayerTranslations.Doom in '..\Libs\Palette\DelphiDoom.Palette.PlayerTranslations.Doom.pas',
  DelphiDoom.Palette.PlayerTranslations.Heretic in '..\Libs\Palette\DelphiDoom.Palette.PlayerTranslations.Heretic.pas',
  DelphiDoom.Palette.PlayerTranslations.Strife in '..\Libs\Palette\DelphiDoom.Palette.PlayerTranslations.Strife.pas',
  DelphiDoom.Palette.GammaTables in '..\Libs\Palette\DelphiDoom.Palette.GammaTables.pas',
  DelphiDoom.Palette.ColormapPreparer in '..\Libs\Palette\DelphiDoom.Palette.ColormapPreparer.pas',
  DelphiDoom.Palette.LightTables in '..\Libs\Palette\DelphiDoom.Palette.LightTables.pas',
  DelphiDoom.Palette.TranslationNames in '..\Libs\Palette\DelphiDoom.Palette.TranslationNames.pas',
  DelphiDoom.Palette.TranslationBlood in '..\Libs\Palette\DelphiDoom.Palette.TranslationBlood.pas',
  DelphiDoom.Palette.PrecalcTables in '..\Libs\Palette\DelphiDoom.Palette.PrecalcTables.pas',
  DelphiDoom.Palette.BufferFixer in '..\Libs\Palette\DelphiDoom.Palette.BufferFixer.pas',
  DelphiDoom.Palette.Unpacker in '..\Libs\Palette\DelphiDoom.Palette.Unpacker.pas',
  DelphiDoom.Palette.Factory in '..\Libs\Palette\DelphiDoom.Palette.Factory.pas',
  DelphiDoom.Tests.Palette.Digest in 'Source\DelphiDoom.Tests.Palette.Digest.pas',
  DelphiDoom.Tests.Palette.Fixtures in 'Source\DelphiDoom.Tests.Palette.Fixtures.pas',
  DelphiDoom.Tests.Palette.Fakes in 'Source\DelphiDoom.Tests.Palette.Fakes.pas',
  DelphiDoom.Tests.Palette.Parity in 'Source\DelphiDoom.Tests.Palette.Parity.pas',
  DelphiDoom.Tests.Palette.Behavior in 'Source\DelphiDoom.Tests.Palette.Behavior.pas',
  DelphiDoom.Tests.Palette.TranslationBlood in 'Source\DelphiDoom.Tests.Palette.TranslationBlood.pas';

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
