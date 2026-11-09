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
  DelphiDoom.Tests.XcomSurface.Script in 'Source\DelphiDoom.Tests.XcomSurface.Script.pas',
  DelphiDoom.Tests.XcomSurface.Golden in 'Source\DelphiDoom.Tests.XcomSurface.Golden.pas',
  DelphiDoom.Tests.XcomSurface.Gfx in 'Source\DelphiDoom.Tests.XcomSurface.Gfx.pas',
  DelphiDoom.Tests.XcomSurface.Surface in 'Source\DelphiDoom.Tests.XcomSurface.Surface.pas';

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
