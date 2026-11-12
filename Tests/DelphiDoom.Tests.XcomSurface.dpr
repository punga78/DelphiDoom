{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom surface library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomSurface;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Xcom.Types in '..\Libs\XcomFormats\DelphiDoom.Xcom.Types.pas',
  DelphiDoom.Xcom.Palette in '..\Libs\XcomFormats\DelphiDoom.Xcom.Palette.pas',
  DelphiDoom.Xcom.Image in '..\Libs\XcomFormats\DelphiDoom.Xcom.Image.pas',
  DelphiDoom.XcomSurface.Types in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Types.pas',
  DelphiDoom.XcomSurface.Sdl in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Sdl.pas',
  DelphiDoom.XcomSurface.Surface in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Surface.pas',
  DelphiDoom.XcomSurface.GfxFont in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.GfxFont.pas',
  DelphiDoom.XcomSurface.Gfx in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Gfx.pas',
  DelphiDoom.XcomSurface.Intf in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Intf.pas',
  DelphiDoom.XcomSurface.Shade in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Shade.pas',
  DelphiDoom.XcomSurface.Font in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Font.pas',
  DelphiDoom.XcomSurface.Factory in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Factory.pas',
  DelphiDoom.XcomSurface.Glyph.Types in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Glyph.Types.pas',
  DelphiDoom.XcomSurface.GlyphRasterizer.Intf in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.GlyphRasterizer.Intf.pas',
  DelphiDoom.XcomSurface.GlyphLevels in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.GlyphLevels.pas',
  DelphiDoom.XcomSurface.FontOverlay.Intf in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.FontOverlay.Intf.pas',
  DelphiDoom.XcomSurface.FontOverlayBuilder in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.FontOverlayBuilder.pas',
  DelphiDoom.XcomSurface.TtfFamilyName in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.TtfFamilyName.pas',
  DelphiDoom.Tests.XcomSurface.FakeRasterizer in 'Source\DelphiDoom.Tests.XcomSurface.FakeRasterizer.pas',
  DelphiDoom.Tests.XcomSurface.GlyphLevels in 'Source\DelphiDoom.Tests.XcomSurface.GlyphLevels.pas',
  DelphiDoom.Tests.XcomSurface.FontOverlayBuilder in 'Source\DelphiDoom.Tests.XcomSurface.FontOverlayBuilder.pas',
  DelphiDoom.Tests.XcomSurface.TtfFamilyName in 'Source\DelphiDoom.Tests.XcomSurface.TtfFamilyName.pas',
  DelphiDoom.Tests.XcomSurface.Script in 'Source\DelphiDoom.Tests.XcomSurface.Script.pas',
  DelphiDoom.Tests.XcomSurface.Golden in 'Source\DelphiDoom.Tests.XcomSurface.Golden.pas',
  DelphiDoom.Tests.XcomSurface.Gfx in 'Source\DelphiDoom.Tests.XcomSurface.Gfx.pas',
  DelphiDoom.Tests.XcomSurface.Surface in 'Source\DelphiDoom.Tests.XcomSurface.Surface.pas',
  DelphiDoom.XcomSurface.SurfaceSet in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.SurfaceSet.pas',
  DelphiDoom.XcomSurface.Enlarger in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Enlarger.pas',
  DelphiDoom.Tests.XcomSurface.Enlarger in 'Source\DelphiDoom.Tests.XcomSurface.Enlarger.pas',
  DelphiDoom.XcomSurface.Stroke in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.Stroke.pas',
  DelphiDoom.Tests.XcomSurface.Stroke in 'Source\DelphiDoom.Tests.XcomSurface.Stroke.pas',
  DelphiDoom.XcomSurface.BlendOverlay in '..\Libs\XcomSurface\DelphiDoom.XcomSurface.BlendOverlay.pas',
  DelphiDoom.Tests.XcomSurface.BlendOverlay in 'Source\DelphiDoom.Tests.XcomSurface.BlendOverlay.pas';

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
