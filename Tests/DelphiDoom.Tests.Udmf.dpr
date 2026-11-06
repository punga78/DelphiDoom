{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the UDMF library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Udmf;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Libs\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Libs\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Libs\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Udmf.Types in '..\Libs\Udmf\DelphiDoom.Udmf.Types.pas',
  DelphiDoom.Udmf.BinaryWriter in '..\Libs\Udmf\DelphiDoom.Udmf.BinaryWriter.pas',
  DelphiDoom.Udmf.Intf in '..\Libs\Udmf\DelphiDoom.Udmf.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Libs\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.Udmf.Text in '..\Libs\Udmf\DelphiDoom.Udmf.Text.pas',
  DelphiDoom.Udmf.Preprocessor in '..\Libs\Udmf\DelphiDoom.Udmf.Preprocessor.pas',
  DelphiDoom.Udmf.ValueReader in '..\Libs\Udmf\DelphiDoom.Udmf.ValueReader.pas',
  DelphiDoom.Udmf.ThingFormat.Base in '..\Libs\Udmf\DelphiDoom.Udmf.ThingFormat.Base.pas',
  DelphiDoom.Udmf.ThingFormat.Vanilla in '..\Libs\Udmf\DelphiDoom.Udmf.ThingFormat.Vanilla.pas',
  DelphiDoom.Udmf.ThingFormat.Hexen in '..\Libs\Udmf\DelphiDoom.Udmf.ThingFormat.Hexen.pas',
  DelphiDoom.Udmf.LineFormat.Base in '..\Libs\Udmf\DelphiDoom.Udmf.LineFormat.Base.pas',
  DelphiDoom.Udmf.LineFormat.Vanilla in '..\Libs\Udmf\DelphiDoom.Udmf.LineFormat.Vanilla.pas',
  DelphiDoom.Udmf.LineFormat.Hexen in '..\Libs\Udmf\DelphiDoom.Udmf.LineFormat.Hexen.pas',
  DelphiDoom.Udmf.SideFormat in '..\Libs\Udmf\DelphiDoom.Udmf.SideFormat.pas',
  DelphiDoom.Udmf.VertexFormat in '..\Libs\Udmf\DelphiDoom.Udmf.VertexFormat.pas',
  DelphiDoom.Udmf.SectorFormat in '..\Libs\Udmf\DelphiDoom.Udmf.SectorFormat.pas',
  DelphiDoom.Udmf.Profile in '..\Libs\Udmf\DelphiDoom.Udmf.Profile.pas',
  DelphiDoom.Udmf.Games in '..\Libs\Udmf\DelphiDoom.Udmf.Games.pas',
  DelphiDoom.Udmf.Map in '..\Libs\Udmf\DelphiDoom.Udmf.Map.pas',
  DelphiDoom.Udmf.Parser in '..\Libs\Udmf\DelphiDoom.Udmf.Parser.pas',
  DelphiDoom.Udmf.ConvertedMap in '..\Libs\Udmf\DelphiDoom.Udmf.ConvertedMap.pas',
  DelphiDoom.Udmf.Converter in '..\Libs\Udmf\DelphiDoom.Udmf.Converter.pas',
  DelphiDoom.Udmf.Factory in '..\Libs\Udmf\DelphiDoom.Udmf.Factory.pas',
  DelphiDoom.Tests.Udmf.Sounds in 'Source\DelphiDoom.Tests.Udmf.Sounds.pas',
  DelphiDoom.Tests.Udmf.Parity in 'Source\DelphiDoom.Tests.Udmf.Parity.pas',
  DelphiDoom.Tests.Udmf.Behavior in 'Source\DelphiDoom.Tests.Udmf.Behavior.pas';

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
