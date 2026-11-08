{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the assembler replacements (DUnitX)               }
{                                                                              }
{  The old assembler (copied in Source\DelphiDoom.Tests.AsmParity.Oracles or, for    }
{  the MMX code, the 32 bit functions of d_delphi and r_mmx) against the       }
{  Pascal versions, on limit values and millions of pseudo random inputs.      }
{  The project is built for 32 bit: the assembler cannot run in 64 bit.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.AsmParity;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  d_delphi in '..\Common\d_delphi.pas',
  r_mmx in '..\Base\r_mmx.pas',
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.MemoryFill in '..\Libs\MathCore\DelphiDoom.MathCore.MemoryFill.pas',
  DelphiDoom.MathCore.PixelBatch in '..\Libs\MathCore\DelphiDoom.MathCore.PixelBatch.pas',
  DelphiDoom.Tests.AsmParity.Oracles in 'Source\DelphiDoom.Tests.AsmParity.Oracles.pas',
  DelphiDoom.Tests.AsmParity.Parity in 'Source\DelphiDoom.Tests.AsmParity.Parity.pas',
  DelphiDoom.Tests.AsmParity.FixedMath in 'Source\DelphiDoom.Tests.AsmParity.FixedMath.pas',
  DelphiDoom.Tests.AsmParity.MemoryFill in 'Source\DelphiDoom.Tests.AsmParity.MemoryFill.pas',
  DelphiDoom.Tests.AsmParity.PixelBatch in 'Source\DelphiDoom.Tests.AsmParity.PixelBatch.pas',
  DelphiDoom.Tests.AsmParity.Text in 'Source\DelphiDoom.Tests.AsmParity.Text.pas';

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
