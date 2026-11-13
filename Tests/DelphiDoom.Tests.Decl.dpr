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
  DelphiDoom.Decl.Material.Types in '..\Libs\Decl\DelphiDoom.Decl.Material.Types.pas',
  DelphiDoom.Decl.Material.Intf in '..\Libs\Decl\DelphiDoom.Decl.Material.Intf.pas',
  DelphiDoom.Decl.Material.Registers in '..\Libs\Decl\DelphiDoom.Decl.Material.Registers.pas',
  DelphiDoom.Decl.Material.ExpressionParser in '..\Libs\Decl\DelphiDoom.Decl.Material.ExpressionParser.pas',
  DelphiDoom.Decl.Material.Evaluator in '..\Libs\Decl\DelphiDoom.Decl.Material.Evaluator.pas',
  DelphiDoom.Decl.Material.SurfaceParms in '..\Libs\Decl\DelphiDoom.Decl.Material.SurfaceParms.pas',
  DelphiDoom.Decl.Material.BlendModes in '..\Libs\Decl\DelphiDoom.Decl.Material.BlendModes.pas',
  DelphiDoom.Decl.Material.StageParser in '..\Libs\Decl\DelphiDoom.Decl.Material.StageParser.pas',
  DelphiDoom.Decl.Material.Data in '..\Libs\Decl\DelphiDoom.Decl.Material.Data.pas',
  DelphiDoom.Decl.Material.Parser in '..\Libs\Decl\DelphiDoom.Decl.Material.Parser.pas',
  DelphiDoom.Decl.Material.ImageNames in '..\Libs\Decl\DelphiDoom.Decl.Material.ImageNames.pas',
  delphidoom.decl.material.imagenamer in '..\libs\decl\delphidoom.decl.material.imagenamer.pas',
  DelphiDoom.Decl.Material in '..\Libs\Decl\DelphiDoom.Decl.Material.pas',
  DelphiDoom.Decl.StandardTypes in '..\Libs\Decl\DelphiDoom.Decl.StandardTypes.pas',
  DelphiDoom.Decl.Factory in '..\Libs\Decl\DelphiDoom.Decl.Factory.pas',
  DelphiDoom.Tests.Scanner.IdFakes in 'Source\DelphiDoom.Tests.Scanner.IdFakes.pas',
  DelphiDoom.Tests.Decl.Support in 'Source\DelphiDoom.Tests.Decl.Support.pas',
  DelphiDoom.Tests.Decl.Source in 'Source\DelphiDoom.Tests.Decl.Source.pas',
  DelphiDoom.Tests.Decl.Manager in 'Source\DelphiDoom.Tests.Decl.Manager.pas',
  DelphiDoom.Tests.Decl.Types in 'Source\DelphiDoom.Tests.Decl.Types.pas',
  DelphiDoom.Tests.Decl.EntityDef in 'Source\DelphiDoom.Tests.Decl.EntityDef.pas',
  DelphiDoom.Tests.Decl.Pda in 'Source\DelphiDoom.Tests.Decl.Pda.pas',
  DelphiDoom.Tests.Decl.Golden in 'Source\DelphiDoom.Tests.Decl.Golden.pas',
  DelphiDoom.Tests.Decl.MaterialGolden in 'Source\DelphiDoom.Tests.Decl.MaterialGolden.pas';

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
