{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the declaration manager (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Decl;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Scanner.IdCNumbers in '..\Libs\Scanner\DelphiDoom.Scanner.IdCNumbers.pas',
  DelphiDoom.Scanner.IdParser.Types in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Types.pas',
  DelphiDoom.Scanner.IdParser.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Intf.pas',
  DelphiDoom.Scanner.IdDict in '..\Libs\Scanner\DelphiDoom.Scanner.IdDict.pas',
  DelphiDoom.Decl.Types in '..\Libs\Decl\DelphiDoom.Decl.Types.pas',
  DelphiDoom.Decl.Source.Intf in '..\Libs\Decl\DelphiDoom.Decl.Source.Intf.pas',
  DelphiDoom.Decl.Source.Memory in '..\Libs\Decl\DelphiDoom.Decl.Source.Memory.pas',
  DelphiDoom.Decl.Intf in '..\Libs\Decl\DelphiDoom.Decl.Intf.pas',
  DelphiDoom.Decl.Base in '..\Libs\Decl\DelphiDoom.Decl.Base.pas',
  DelphiDoom.Decl.TypeInfo in '..\Libs\Decl\DelphiDoom.Decl.TypeInfo.pas',
  DelphiDoom.Decl.Entry in '..\Libs\Decl\DelphiDoom.Decl.Entry.pas',
  DelphiDoom.Decl.Manager in '..\Libs\Decl\DelphiDoom.Decl.Manager.pas',
  DelphiDoom.Decl.Table in '..\Libs\Decl\DelphiDoom.Decl.Table.pas',
  DelphiDoom.Decl.Skin in '..\Libs\Decl\DelphiDoom.Decl.Skin.pas',
  DelphiDoom.Decl.EntityDef in '..\Libs\Decl\DelphiDoom.Decl.EntityDef.pas',
  DelphiDoom.Decl.Pda in '..\Libs\Decl\DelphiDoom.Decl.Pda.pas',
  DelphiDoom.Decl.Email in '..\Libs\Decl\DelphiDoom.Decl.Email.pas',
  DelphiDoom.Decl.Video in '..\Libs\Decl\DelphiDoom.Decl.Video.pas',
  DelphiDoom.Decl.Audio in '..\Libs\Decl\DelphiDoom.Decl.Audio.pas',
  DelphiDoom.Decl.StandardTypes in '..\Libs\Decl\DelphiDoom.Decl.StandardTypes.pas',
  DelphiDoom.Decl.Factory in '..\Libs\Decl\DelphiDoom.Decl.Factory.pas',
  DelphiDoom.Tests.Scanner.IdFakes in 'Source\DelphiDoom.Tests.Scanner.IdFakes.pas',
  DelphiDoom.Tests.Decl.Support in 'Source\DelphiDoom.Tests.Decl.Support.pas',
  DelphiDoom.Tests.Decl.Source in 'Source\DelphiDoom.Tests.Decl.Source.pas',
  DelphiDoom.Tests.Decl.Manager in 'Source\DelphiDoom.Tests.Decl.Manager.pas',
  DelphiDoom.Tests.Decl.Types in 'Source\DelphiDoom.Tests.Decl.Types.pas',
  DelphiDoom.Tests.Decl.EntityDef in 'Source\DelphiDoom.Tests.Decl.EntityDef.pas',
  DelphiDoom.Tests.Decl.Pda in 'Source\DelphiDoom.Tests.Decl.Pda.pas';

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
