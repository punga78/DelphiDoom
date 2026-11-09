{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the endoom library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Endoom;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Endoom.Types in '..\Libs\Endoom\DelphiDoom.Endoom.Types.pas',
  DelphiDoom.Endoom.Intf in '..\Libs\Endoom\DelphiDoom.Endoom.Intf.pas',
  DelphiDoom.Endoom.Renderer in '..\Libs\Endoom\DelphiDoom.Endoom.Renderer.pas',
  DelphiDoom.Endoom.Session in '..\Libs\Endoom\DelphiDoom.Endoom.Session.pas',
  DelphiDoom.Endoom.ColorQuantizer in '..\Libs\Endoom\DelphiDoom.Endoom.ColorQuantizer.pas',
  DelphiDoom.Endoom.Screen in '..\Libs\Endoom\DelphiDoom.Endoom.Screen.pas',
  DelphiDoom.Endoom.Drawing in '..\Libs\Endoom\DelphiDoom.Endoom.Drawing.pas',
  DelphiDoom.Endoom.TextPaste in '..\Libs\Endoom\DelphiDoom.Endoom.TextPaste.pas',
  DelphiDoom.Endoom.DosFont in '..\Libs\Endoom\DelphiDoom.Endoom.DosFont.pas',
  DelphiDoom.Endoom.FontSource in '..\Libs\Endoom\DelphiDoom.Endoom.FontSource.pas',
  DelphiDoom.Endoom.ScreenImage in '..\Libs\Endoom\DelphiDoom.Endoom.ScreenImage.pas',
  DelphiDoom.Endoom.TextArt.Types in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Types.pas',
  DelphiDoom.Endoom.TextArt.Intf in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Intf.pas',
  DelphiDoom.Endoom.TextArt.BackgroundOnly in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundOnly.pas',
  DelphiDoom.Endoom.TextArt.BackgroundForeground in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundForeground.pas',
  DelphiDoom.Endoom.TextArt.Dither in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Dither.pas',
  DelphiDoom.Endoom.TextArt.SpecialChars in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.SpecialChars.pas',
  DelphiDoom.Endoom.TextArt.Converter in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Converter.pas',
  DelphiDoom.Endoom.TextArt.Factory in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Factory.pas',
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Imaging.Resampler in '..\Libs\Imaging\DelphiDoom.Imaging.Resampler.pas',
  DelphiDoom.Endoom.Factory in '..\Libs\Endoom\DelphiDoom.Endoom.Factory.pas',
  DelphiDoom.Tests.Endoom.Digest in 'Source\DelphiDoom.Tests.Endoom.Digest.pas',
  DelphiDoom.Tests.Endoom.EditorScenarios in 'Source\DelphiDoom.Tests.Endoom.EditorScenarios.pas',
  DelphiDoom.Tests.Endoom.EditorHelper in 'Source\DelphiDoom.Tests.Endoom.EditorHelper.pas',
  DelphiDoom.Tests.Imaging.ResampleCases in 'Source\DelphiDoom.Tests.Imaging.ResampleCases.pas',
  DelphiDoom.Tests.Endoom.Fixtures in 'Source\DelphiDoom.Tests.Endoom.Fixtures.pas',
  DelphiDoom.Tests.Endoom.Renderer in 'Source\DelphiDoom.Tests.Endoom.Renderer.pas',
  DelphiDoom.Tests.Endoom.Session in 'Source\DelphiDoom.Tests.Endoom.Session.pas',
  DelphiDoom.Tests.Endoom.Screen in 'Source\DelphiDoom.Tests.Endoom.Screen.pas',
  DelphiDoom.Tests.Endoom.ColorQuantizer in 'Source\DelphiDoom.Tests.Endoom.ColorQuantizer.pas',
  DelphiDoom.Tests.Endoom.Drawing in 'Source\DelphiDoom.Tests.Endoom.Drawing.pas',
  DelphiDoom.Tests.Endoom.TextPaste in 'Source\DelphiDoom.Tests.Endoom.TextPaste.pas',
  DelphiDoom.Tests.Endoom.ScreenImage in 'Source\DelphiDoom.Tests.Endoom.ScreenImage.pas',
  DelphiDoom.Tests.Endoom.TextArtMethods in 'Source\DelphiDoom.Tests.Endoom.TextArtMethods.pas',
  DelphiDoom.Tests.Endoom.TextArtConverter in 'Source\DelphiDoom.Tests.Endoom.TextArtConverter.pas';

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
