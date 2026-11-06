{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Dehacked library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Dehacked;

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
  DelphiDoom.Dehacked.Data.Doom in '..\Libs\Dehacked\DelphiDoom.Dehacked.Data.Doom.pas',
  DelphiDoom.Dehacked.Data.Heretic in '..\Libs\Dehacked\DelphiDoom.Dehacked.Data.Heretic.pas',
  DelphiDoom.Dehacked.Data.Hexen in '..\Libs\Dehacked\DelphiDoom.Dehacked.Data.Hexen.pas',
  DelphiDoom.Dehacked.Data.Strife in '..\Libs\Dehacked\DelphiDoom.Dehacked.Data.Strife.pas',
  DelphiDoom.Dehacked.Factory in '..\Libs\Dehacked\DelphiDoom.Dehacked.Factory.pas',
  DelphiDoom.Dehacked.FieldKinds in '..\Libs\Dehacked\DelphiDoom.Dehacked.FieldKinds.pas',
  DelphiDoom.Dehacked.FieldReader in '..\Libs\Dehacked\DelphiDoom.Dehacked.FieldReader.pas',
  DelphiDoom.Dehacked.FieldTable in '..\Libs\Dehacked\DelphiDoom.Dehacked.FieldTable.pas',
  DelphiDoom.Dehacked.FlagSet in '..\Libs\Dehacked\DelphiDoom.Dehacked.FlagSet.pas',
  DelphiDoom.Dehacked.FlagSets in '..\Libs\Dehacked\DelphiDoom.Dehacked.FlagSets.pas',
  DelphiDoom.Dehacked.GameData in '..\Libs\Dehacked\DelphiDoom.Dehacked.GameData.pas',
  DelphiDoom.Dehacked.Games in '..\Libs\Dehacked\DelphiDoom.Dehacked.Games.pas',
  DelphiDoom.Dehacked.Intf in '..\Libs\Dehacked\DelphiDoom.Dehacked.Intf.pas',
  DelphiDoom.Dehacked.LineSource in '..\Libs\Dehacked\DelphiDoom.Dehacked.LineSource.pas',
  DelphiDoom.Dehacked.Parser in '..\Libs\Dehacked\DelphiDoom.Dehacked.Parser.pas',
  DelphiDoom.Dehacked.Patch in '..\Libs\Dehacked\DelphiDoom.Dehacked.Patch.pas',
  DelphiDoom.Dehacked.Profile in '..\Libs\Dehacked\DelphiDoom.Dehacked.Profile.pas',
  DelphiDoom.Dehacked.Reader.Ammo in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Ammo.pas',
  DelphiDoom.Dehacked.Reader.Base in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Base.pas',
  DelphiDoom.Dehacked.Reader.Frame in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Frame.pas',
  DelphiDoom.Dehacked.Reader.Lines in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Lines.pas',
  DelphiDoom.Dehacked.Reader.Marker in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Marker.pas',
  DelphiDoom.Dehacked.Reader.Misc in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Misc.pas',
  DelphiDoom.Dehacked.Reader.Pars in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Pars.pas',
  DelphiDoom.Dehacked.Reader.Pointer in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Pointer.pas',
  DelphiDoom.Dehacked.Reader.Sound in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Sound.pas',
  DelphiDoom.Dehacked.Reader.Text in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Text.pas',
  DelphiDoom.Dehacked.Reader.Thing in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Thing.pas',
  DelphiDoom.Dehacked.Reader.Weapon in '..\Libs\Dehacked\DelphiDoom.Dehacked.Reader.Weapon.pas',
  DelphiDoom.Dehacked.Section in '..\Libs\Dehacked\DelphiDoom.Dehacked.Section.pas',
  DelphiDoom.Dehacked.Strings in '..\Libs\Dehacked\DelphiDoom.Dehacked.Strings.pas',
  DelphiDoom.Dehacked.Text in '..\Libs\Dehacked\DelphiDoom.Dehacked.Text.pas',
  DelphiDoom.Dehacked.Types in '..\Libs\Dehacked\DelphiDoom.Dehacked.Types.pas',
  DelphiDoom.Tests.Dehacked.DumpApplier in 'Source\DelphiDoom.Tests.Dehacked.DumpApplier.pas',
  DelphiDoom.Tests.Dehacked.Parity in 'Source\DelphiDoom.Tests.Dehacked.Parity.pas',
  DelphiDoom.Tests.Dehacked.Strings in 'Source\DelphiDoom.Tests.Dehacked.Strings.pas',
  DelphiDoom.Tests.Dehacked.LineSource in 'Source\DelphiDoom.Tests.Dehacked.LineSource.pas',
  DelphiDoom.Tests.Dehacked.Parser in 'Source\DelphiDoom.Tests.Dehacked.Parser.pas';

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
