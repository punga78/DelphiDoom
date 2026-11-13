{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the info and script tables (DUnitX)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.InfoTables;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  d_delphi in '..\Common\d_delphi.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.TokenEntry in '..\Libs\Scanner\DelphiDoom.Scanner.TokenEntry.pas',
  DelphiDoom.Scanner.ConstTable in '..\Libs\Scanner\DelphiDoom.Scanner.ConstTable.pas',
  DelphiDoom.Scanner.Numbers in '..\Libs\Scanner\DelphiDoom.Scanner.Numbers.pas',
  DelphiDoom.Scanner.Text in '..\Libs\Scanner\DelphiDoom.Scanner.Text.pas',
  DelphiDoom.Scanner.ContextEvaluator.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.ContextEvaluator.Intf.pas',
  DelphiDoom.ActorDef.ParamText in '..\Libs\ActorDef\DelphiDoom.ActorDef.ParamText.pas',
  DelphiDoom.ActorDef.ParamList.Intf in '..\Libs\ActorDef\DelphiDoom.ActorDef.ParamList.Intf.pas',
  DelphiDoom.ActorDef.ParamList in '..\Libs\ActorDef\DelphiDoom.ActorDef.ParamList.pas',
  DelphiDoom.ActorDef.ParamString in '..\Libs\ActorDef\DelphiDoom.ActorDef.ParamString.pas',
  DelphiDoom.Info.Types in '..\Libs\Info\DelphiDoom.Info.Types.pas',
  DelphiDoom.Info.Intf in '..\Libs\Info\DelphiDoom.Info.Intf.pas',
  DelphiDoom.Info.Range in '..\Libs\Info\DelphiDoom.Info.Range.pas',
  DelphiDoom.Info.SpriteNames in '..\Libs\Info\DelphiDoom.Info.SpriteNames.pas',
  DelphiDoom.Info.MobjAliases in '..\Libs\Info\DelphiDoom.Info.MobjAliases.pas',
  DelphiDoom.Info.MobjLookup in '..\Libs\Info\DelphiDoom.Info.MobjLookup.pas',
  DelphiDoom.Info.DoomedNumbers in '..\Libs\Info\DelphiDoom.Info.DoomedNumbers.pas',
  DelphiDoom.Info.StateWalker in '..\Libs\Info\DelphiDoom.Info.StateWalker.pas',
  DelphiDoom.Info.SpriteStates in '..\Libs\Info\DelphiDoom.Info.SpriteStates.pas',
  DelphiDoom.Info.GroupNames in '..\Libs\Info\DelphiDoom.Info.GroupNames.pas',
  DelphiDoom.Info.RandomMonsters in '..\Libs\Info\DelphiDoom.Info.RandomMonsters.pas',
  DelphiDoom.Info.StateNames in '..\Libs\Info\DelphiDoom.Info.StateNames.pas',
  DelphiDoom.Dehacked.Strings in '..\Libs\Dehacked\DelphiDoom.Dehacked.Strings.pas',
  DelphiDoom.Dehacked.Text in '..\Libs\Dehacked\DelphiDoom.Dehacked.Text.pas',
  DelphiDoom.Dehacked.TokenName in '..\Libs\Dehacked\DelphiDoom.Dehacked.TokenName.pas',
  DelphiDoom.Dehacked.FileNames in '..\Libs\Dehacked\DelphiDoom.Dehacked.FileNames.pas',
  DelphiDoom.TableExport.Saver.Intf in '..\Libs\TableExport\DelphiDoom.TableExport.Saver.Intf.pas',
  DelphiDoom.TableExport.Saver in '..\Libs\TableExport\DelphiDoom.TableExport.Saver.pas',
  DelphiDoom.Tests.InfoTables.Fakes in 'Source\DelphiDoom.Tests.InfoTables.Fakes.pas',
  DelphiDoom.Tests.InfoTables.LegacyTokens in 'Source\DelphiDoom.Tests.InfoTables.LegacyTokens.pas',
  DelphiDoom.Tests.InfoTables.LegacyParams in 'Source\DelphiDoom.Tests.InfoTables.LegacyParams.pas',
  DelphiDoom.Tests.InfoTables.LegacyInfo in 'Source\DelphiDoom.Tests.InfoTables.LegacyInfo.pas',
  DelphiDoom.Tests.InfoTables.Tables in 'Source\DelphiDoom.Tests.InfoTables.Tables.pas',
  DelphiDoom.Tests.InfoTables.LegacyDeh in 'Source\DelphiDoom.Tests.InfoTables.LegacyDeh.pas',
  DelphiDoom.Tests.Info.Parity in 'Source\DelphiDoom.Tests.Info.Parity.pas',
  DelphiDoom.Tests.Info.Units in 'Source\DelphiDoom.Tests.Info.Units.pas',
  DelphiDoom.Tests.Dehacked.BaseText in 'Source\DelphiDoom.Tests.Dehacked.BaseText.pas',
  DelphiDoom.Tests.TableExport.Saver in 'Source\DelphiDoom.Tests.TableExport.Saver.pas',
  DelphiDoom.Tests.ActorDef.ParamText in 'Source\DelphiDoom.Tests.ActorDef.ParamText.pas',
  DelphiDoom.Tests.ActorDef.ParamList in 'Source\DelphiDoom.Tests.ActorDef.ParamList.pas',
  DelphiDoom.Tests.ActorDef.ParamString in 'Source\DelphiDoom.Tests.ActorDef.ParamString.pas',
  DelphiDoom.Tests.Scanner.TokenEntry in 'Source\DelphiDoom.Tests.Scanner.TokenEntry.pas',
  DelphiDoom.Tests.Scanner.ConstTable in 'Source\DelphiDoom.Tests.Scanner.ConstTable.pas';

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
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;
end.
