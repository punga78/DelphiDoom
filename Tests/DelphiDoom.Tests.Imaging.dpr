{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Imaging library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Imaging;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Imaging.ColorMath in '..\Libs\Imaging\DelphiDoom.Imaging.ColorMath.pas',
  DelphiDoom.Imaging.ColumnPainter in '..\Libs\Imaging\DelphiDoom.Imaging.ColumnPainter.pas',
  DelphiDoom.Imaging.ColumnRebuilder in '..\Libs\Imaging\DelphiDoom.Imaging.ColumnRebuilder.pas',
  DelphiDoom.Imaging.FixedColumn in '..\Libs\Imaging\DelphiDoom.Imaging.FixedColumn.pas',
  DelphiDoom.Imaging.PatchReader in '..\Libs\Imaging\DelphiDoom.Imaging.PatchReader.pas',
  DelphiDoom.Imaging.FlatReader in '..\Libs\Imaging\DelphiDoom.Imaging.FlatReader.pas',
  DelphiDoom.Imaging.FlatShrinker in '..\Libs\Imaging\DelphiDoom.Imaging.FlatShrinker.pas',
  DelphiDoom.Imaging.SpanGrower in '..\Libs\Imaging\DelphiDoom.Imaging.SpanGrower.pas',
  DelphiDoom.Imaging.ColumnExpander in '..\Libs\Imaging\DelphiDoom.Imaging.ColumnExpander.pas',
  DelphiDoom.Imaging.HiResTables in '..\Libs\Imaging\DelphiDoom.Imaging.HiResTables.pas',
  DelphiDoom.Imaging.MeltWipe in '..\Libs\Imaging\DelphiDoom.Imaging.MeltWipe.pas',
  DelphiDoom.Imaging.SineTable in '..\Libs\Imaging\DelphiDoom.Imaging.SineTable.pas',
  DelphiDoom.Imaging.WallScale in '..\Libs\Imaging\DelphiDoom.Imaging.WallScale.pas',
  DelphiDoom.Imaging.Factory in '..\Libs\Imaging\DelphiDoom.Imaging.Factory.pas',
  DelphiDoom.Tests.Imaging.Samples in 'Source\DelphiDoom.Tests.Imaging.Samples.pas',
  DelphiDoom.Tests.Imaging.Golden in 'Source\DelphiDoom.Tests.Imaging.Golden.pas',
  DelphiDoom.Tests.Imaging.Types in 'Source\DelphiDoom.Tests.Imaging.Types.pas',
  DelphiDoom.Tests.Imaging.ColorMath in 'Source\DelphiDoom.Tests.Imaging.ColorMath.pas',
  DelphiDoom.Tests.Imaging.ColumnPainter in 'Source\DelphiDoom.Tests.Imaging.ColumnPainter.pas',
  DelphiDoom.Tests.Imaging.ColumnRebuilder in 'Source\DelphiDoom.Tests.Imaging.ColumnRebuilder.pas',
  DelphiDoom.Tests.Imaging.FixedColumn in 'Source\DelphiDoom.Tests.Imaging.FixedColumn.pas',
  DelphiDoom.Tests.Imaging.PatchReader in 'Source\DelphiDoom.Tests.Imaging.PatchReader.pas',
  DelphiDoom.Tests.Imaging.FlatReader in 'Source\DelphiDoom.Tests.Imaging.FlatReader.pas',
  DelphiDoom.Tests.Imaging.FlatShrinker in 'Source\DelphiDoom.Tests.Imaging.FlatShrinker.pas',
  DelphiDoom.Tests.Imaging.SpanGrower in 'Source\DelphiDoom.Tests.Imaging.SpanGrower.pas',
  DelphiDoom.Tests.Imaging.ColumnExpander in 'Source\DelphiDoom.Tests.Imaging.ColumnExpander.pas',
  DelphiDoom.Tests.Imaging.HiResTables in 'Source\DelphiDoom.Tests.Imaging.HiResTables.pas',
  DelphiDoom.Tests.Imaging.MeltWipe in 'Source\DelphiDoom.Tests.Imaging.MeltWipe.pas',
  DelphiDoom.Tests.Imaging.SineTable in 'Source\DelphiDoom.Tests.Imaging.SineTable.pas',
  DelphiDoom.Tests.Imaging.WallScale in 'Source\DelphiDoom.Tests.Imaging.WallScale.pas',
  DelphiDoom.Tests.Imaging.Factory in 'Source\DelphiDoom.Tests.Imaging.Factory.pas';

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
