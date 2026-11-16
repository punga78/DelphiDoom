{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Quake III host library (the system calls of   }
{  qagame, cgame and ui, DUnitX)                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Q3Host;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.BotAi.Import.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.Models.Q3Player.TokenReader in '..\Framework\Models\DelphiDoom.Models.Q3Player.TokenReader.pas',
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask in '..\IdTech4\Decl\DelphiDoom.Decl.Q3Shader.Calc.FloatMask.pas',
  DelphiDoom.Wad.Types in '..\Framework\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Intf in '..\Framework\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Framework\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Name in '..\Framework\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Source.Zip in '..\Framework\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Qvm.Types in '..\IdTech4\Qvm\DelphiDoom.Qvm.Types.pas',
  DelphiDoom.Qvm.Opcodes in '..\IdTech4\Qvm\DelphiDoom.Qvm.Opcodes.pas',
  DelphiDoom.Qvm.Intf in '..\IdTech4\Qvm\DelphiDoom.Qvm.Intf.pas',
  DelphiDoom.Qvm.Image in '..\IdTech4\Qvm\DelphiDoom.Qvm.Image.pas',
  DelphiDoom.Qvm.Code in '..\IdTech4\Qvm\DelphiDoom.Qvm.Code.pas',
  DelphiDoom.Qvm.Memory in '..\IdTech4\Qvm\DelphiDoom.Qvm.Memory.pas',
  DelphiDoom.Qvm.Symbols in '..\IdTech4\Qvm\DelphiDoom.Qvm.Symbols.pas',
  DelphiDoom.Qvm.FloatMath in '..\IdTech4\Qvm\DelphiDoom.Qvm.FloatMath.pas',
  DelphiDoom.Qvm.Interpreter in '..\IdTech4\Qvm\DelphiDoom.Qvm.Interpreter.pas',
  DelphiDoom.Qvm.Machine in '..\IdTech4\Qvm\DelphiDoom.Qvm.Machine.pas',
  DelphiDoom.Qvm.Manager in '..\IdTech4\Qvm\DelphiDoom.Qvm.Manager.pas',
  DelphiDoom.Qvm.Factory in '..\IdTech4\Qvm\DelphiDoom.Qvm.Factory.pas',
  DelphiDoom.Q3Host.Types in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Types.pas',
  DelphiDoom.Q3Host.Opcodes in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Opcodes.pas',
  DelphiDoom.Q3Host.OpcodeTables in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.OpcodeTables.pas',
  DelphiDoom.Q3Host.OpcodeCatalog in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.OpcodeCatalog.pas',
  DelphiDoom.Q3Host.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Intf.pas',
  DelphiDoom.Q3Host.Arguments in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Arguments.pas',
  DelphiDoom.Q3Host.SyscallHost in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.SyscallHost.pas',
  DelphiDoom.Q3Host.CommonSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CommonSyscalls.pas',
  DelphiDoom.Q3Host.Factory in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Factory.pas',
  DelphiDoom.Tests.Shared.Fnv in 'Source\DelphiDoom.Tests.Shared.Fnv.pas',
  DelphiDoom.Tests.Shared.Files in 'Source\DelphiDoom.Tests.Shared.Files.pas',
  DelphiDoom.Tests.Shared.Golden in 'Source\DelphiDoom.Tests.Shared.Golden.pas',
  DelphiDoom.Tests.Shared.Skip in 'Source\DelphiDoom.Tests.Shared.Skip.pas',
  DelphiDoom.Tests.Qvm.Assembler in 'Source\DelphiDoom.Tests.Qvm.Assembler.pas',
  DelphiDoom.Tests.Qvm.Support in 'Source\DelphiDoom.Tests.Qvm.Support.pas',
  DelphiDoom.Tests.Qvm.Programs in 'Source\DelphiDoom.Tests.Qvm.Programs.pas',
  DelphiDoom.Tests.Q3Host.Support in 'Source\DelphiDoom.Tests.Q3Host.Support.pas',
  DelphiDoom.Tests.Q3Host.Catalog in 'Source\DelphiDoom.Tests.Q3Host.Catalog.pas',
  DelphiDoom.Tests.Q3Host.Math in 'Source\DelphiDoom.Tests.Q3Host.Math.pas',
  DelphiDoom.Tests.Q3Host.Host in 'Source\DelphiDoom.Tests.Q3Host.Host.pas',
  DelphiDoom.Tests.Q3Host.Init in 'Source\DelphiDoom.Tests.Q3Host.Init.pas';

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
