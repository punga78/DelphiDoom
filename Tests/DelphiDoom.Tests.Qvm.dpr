{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the QVM library (virtual machine of Quake III,    }
{  DUnitX)                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Qvm;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.BotAi.Import.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.Models.Q3Player.TokenReader in '..\Libs\Models\DelphiDoom.Models.Q3Player.TokenReader.pas',
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Calc.FloatMask.pas',
  DelphiDoom.Wad.Types in '..\Libs\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Intf in '..\Libs\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Libs\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Name in '..\Libs\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Source.Zip in '..\Libs\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Qvm.Types in '..\Libs\Qvm\DelphiDoom.Qvm.Types.pas',
  DelphiDoom.Qvm.Opcodes in '..\Libs\Qvm\DelphiDoom.Qvm.Opcodes.pas',
  DelphiDoom.Qvm.Intf in '..\Libs\Qvm\DelphiDoom.Qvm.Intf.pas',
  DelphiDoom.Qvm.Image in '..\Libs\Qvm\DelphiDoom.Qvm.Image.pas',
  DelphiDoom.Qvm.Code in '..\Libs\Qvm\DelphiDoom.Qvm.Code.pas',
  DelphiDoom.Qvm.Memory in '..\Libs\Qvm\DelphiDoom.Qvm.Memory.pas',
  DelphiDoom.Qvm.Symbols in '..\Libs\Qvm\DelphiDoom.Qvm.Symbols.pas',
  DelphiDoom.Qvm.FloatMath in '..\Libs\Qvm\DelphiDoom.Qvm.FloatMath.pas',
  DelphiDoom.Qvm.Interpreter in '..\Libs\Qvm\DelphiDoom.Qvm.Interpreter.pas',
  DelphiDoom.Qvm.Machine in '..\Libs\Qvm\DelphiDoom.Qvm.Machine.pas',
  DelphiDoom.Qvm.Manager in '..\Libs\Qvm\DelphiDoom.Qvm.Manager.pas',
  DelphiDoom.Qvm.Factory in '..\Libs\Qvm\DelphiDoom.Qvm.Factory.pas',
  DelphiDoom.Tests.Shared.Fnv in 'Source\DelphiDoom.Tests.Shared.Fnv.pas',
  DelphiDoom.Tests.Shared.Files in 'Source\DelphiDoom.Tests.Shared.Files.pas',
  DelphiDoom.Tests.Shared.Golden in 'Source\DelphiDoom.Tests.Shared.Golden.pas',
  DelphiDoom.Tests.Shared.Skip in 'Source\DelphiDoom.Tests.Shared.Skip.pas',
  DelphiDoom.Tests.Qvm.Assembler in 'Source\DelphiDoom.Tests.Qvm.Assembler.pas',
  DelphiDoom.Tests.Qvm.Support in 'Source\DelphiDoom.Tests.Qvm.Support.pas',
  DelphiDoom.Tests.Qvm.Programs in 'Source\DelphiDoom.Tests.Qvm.Programs.pas',
  DelphiDoom.Tests.Qvm.Parity in 'Source\DelphiDoom.Tests.Qvm.Parity.pas',
  DelphiDoom.Tests.Qvm.Image in 'Source\DelphiDoom.Tests.Qvm.Image.pas',
  DelphiDoom.Tests.Qvm.Code in 'Source\DelphiDoom.Tests.Qvm.Code.pas',
  DelphiDoom.Tests.Qvm.Memory in 'Source\DelphiDoom.Tests.Qvm.Memory.pas',
  DelphiDoom.Tests.Qvm.Symbols in 'Source\DelphiDoom.Tests.Qvm.Symbols.pas',
  DelphiDoom.Tests.Qvm.Machine in 'Source\DelphiDoom.Tests.Qvm.Machine.pas',
  DelphiDoom.Tests.Qvm.Manager in 'Source\DelphiDoom.Tests.Qvm.Manager.pas',
  DelphiDoom.Tests.Qvm.Fuzz in 'Source\DelphiDoom.Tests.Qvm.Fuzz.pas',
  DelphiDoom.Tests.Qvm.OpenArena in 'Source\DelphiDoom.Tests.Qvm.OpenArena.pas',
  DelphiDoom.Tests.Qvm.Performance in 'Source\DelphiDoom.Tests.Qvm.Performance.pas';

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
