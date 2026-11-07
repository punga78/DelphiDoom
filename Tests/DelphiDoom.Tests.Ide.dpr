{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the ide library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Ide;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Types in '..\Libs\Ide\DelphiDoom.Ide.Types.pas',
  DelphiDoom.Ide.Messages in '..\Libs\Ide\DelphiDoom.Ide.Messages.pas',
  DelphiDoom.Ide.Intf in '..\Libs\Ide\DelphiDoom.Ide.Intf.pas',
  DelphiDoom.Ide.Text in '..\Libs\Ide\DelphiDoom.Ide.Text.pas',
  DelphiDoom.Ide.ItemKinds in '..\Libs\Ide\DelphiDoom.Ide.ItemKinds.pas',
  DelphiDoom.Ide.Games in '..\Libs\Ide\DelphiDoom.Ide.Games.pas',
  DelphiDoom.Ide.ProjectFormat in '..\Libs\Ide\DelphiDoom.Ide.ProjectFormat.pas',
  DelphiDoom.Ide.UncountedObject in '..\Libs\Ide\DelphiDoom.Ide.UncountedObject.pas',
  DelphiDoom.Ide.UndoHistory in '..\Libs\Ide\DelphiDoom.Ide.UndoHistory.pas',
  DelphiDoom.Ide.Document in '..\Libs\Ide\DelphiDoom.Ide.Document.pas',
  DelphiDoom.Ide.ProjectItem in '..\Libs\Ide\DelphiDoom.Ide.ProjectItem.pas',
  DelphiDoom.Ide.Project in '..\Libs\Ide\DelphiDoom.Ide.Project.pas',
  DelphiDoom.Ide.Pk3Builder in '..\Libs\Ide\DelphiDoom.Ide.Pk3Builder.pas',
  DelphiDoom.Ide.CompilerMessages in '..\Libs\Ide\DelphiDoom.Ide.CompilerMessages.pas',
  DelphiDoom.Ide.PCodeFile in '..\Libs\Ide\DelphiDoom.Ide.PCodeFile.pas',
  DelphiDoom.Ide.CompileCommand in '..\Libs\Ide\DelphiDoom.Ide.CompileCommand.pas',
  DelphiDoom.Ide.Csv in '..\Libs\Ide\DelphiDoom.Ide.Csv.pas',
  DelphiDoom.Ide.Outline in '..\Libs\Ide\DelphiDoom.Ide.Outline.pas',
  DelphiDoom.Ide.RowSorter in '..\Libs\Ide\DelphiDoom.Ide.RowSorter.pas',
  DelphiDoom.Ide.LibraryTable in '..\Libs\Ide\DelphiDoom.Ide.LibraryTable.pas',
  DelphiDoom.Ide.NameValueTable in '..\Libs\Ide\DelphiDoom.Ide.NameValueTable.pas',
  DelphiDoom.Ide.ActorDefFunctionTable in '..\Libs\Ide\DelphiDoom.Ide.ActorDefFunctionTable.pas',
  DelphiDoom.Ide.UnitFunctionTable in '..\Libs\Ide\DelphiDoom.Ide.UnitFunctionTable.pas',
  DelphiDoom.Ide.FieldFormatter in '..\Libs\Ide\DelphiDoom.Ide.FieldFormatter.pas',
  DelphiDoom.Ide.StateTables in '..\Libs\Ide\DelphiDoom.Ide.StateTables.pas',
  DelphiDoom.Ide.StateCatalog in '..\Libs\Ide\DelphiDoom.Ide.StateCatalog.pas',
  DelphiDoom.Ide.MobjinfoCatalog in '..\Libs\Ide\DelphiDoom.Ide.MobjinfoCatalog.pas',
  DelphiDoom.Ide.ClassCatalog in '..\Libs\Ide\DelphiDoom.Ide.ClassCatalog.pas',
  DelphiDoom.Ide.SpriteCatalog in '..\Libs\Ide\DelphiDoom.Ide.SpriteCatalog.pas',
  DelphiDoom.Ide.ExampleStore in '..\Libs\Ide\DelphiDoom.Ide.ExampleStore.pas',
  DelphiDoom.Ide.ParameterHints in '..\Libs\Ide\DelphiDoom.Ide.ParameterHints.pas',
  DelphiDoom.Ide.SearchHistory in '..\Libs\Ide\DelphiDoom.Ide.SearchHistory.pas',
  DelphiDoom.Ide.SearchSettings in '..\Libs\Ide\DelphiDoom.Ide.SearchSettings.pas',
  DelphiDoom.Ide.SearchPlan in '..\Libs\Ide\DelphiDoom.Ide.SearchPlan.pas',
  DelphiDoom.Ide.MessageLog in '..\Libs\Ide\DelphiDoom.Ide.MessageLog.pas',
  DelphiDoom.Ide.ProjectOutline in '..\Libs\Ide\DelphiDoom.Ide.ProjectOutline.pas',
  DelphiDoom.Ide.EventSnippets in '..\Libs\Ide\DelphiDoom.Ide.EventSnippets.pas',
  DelphiDoom.Ide.Views.Intf in '..\Libs\Ide\DelphiDoom.Ide.Views.Intf.pas',
  DelphiDoom.Ide.MainPresenter in '..\Libs\Ide\DelphiDoom.Ide.MainPresenter.pas',
  DelphiDoom.Ide.ScriptEditorPresenter in '..\Libs\Ide\DelphiDoom.Ide.ScriptEditorPresenter.pas',
  DelphiDoom.Tests.Ide.TestData in 'Source\DelphiDoom.Tests.Ide.TestData.pas',
  DelphiDoom.Tests.Ide.FakeFileSystem in 'Source\DelphiDoom.Tests.Ide.FakeFileSystem.pas',
  DelphiDoom.Tests.Ide.FakeLog in 'Source\DelphiDoom.Tests.Ide.FakeLog.pas',
  DelphiDoom.Tests.Ide.FakeClock in 'Source\DelphiDoom.Tests.Ide.FakeClock.pas',
  DelphiDoom.Tests.Ide.FakeScriptCompiler in 'Source\DelphiDoom.Tests.Ide.FakeScriptCompiler.pas',
  DelphiDoom.Tests.Ide.FakeArchive in 'Source\DelphiDoom.Tests.Ide.FakeArchive.pas',
  DelphiDoom.Tests.Ide.ProjectDump in 'Source\DelphiDoom.Tests.Ide.ProjectDump.pas',
  DelphiDoom.Tests.Ide.CompilerGolden in 'Source\DelphiDoom.Tests.Ide.CompilerGolden.pas',
  DelphiDoom.Tests.Ide.FakeGameLibrary in 'Source\DelphiDoom.Tests.Ide.FakeGameLibrary.pas',
  DelphiDoom.Tests.Ide.LibraryDump in 'Source\DelphiDoom.Tests.Ide.LibraryDump.pas',
  DelphiDoom.Tests.Ide.LibraryParity in 'Source\DelphiDoom.Tests.Ide.LibraryParity.pas',
  DelphiDoom.Tests.Ide.Csv in 'Source\DelphiDoom.Tests.Ide.Csv.pas',
  DelphiDoom.Tests.Ide.FieldFormatter in 'Source\DelphiDoom.Tests.Ide.FieldFormatter.pas',
  DelphiDoom.Tests.Ide.LibraryTables in 'Source\DelphiDoom.Tests.Ide.LibraryTables.pas',
  DelphiDoom.Tests.Ide.Catalogs in 'Source\DelphiDoom.Tests.Ide.Catalogs.pas',
  DelphiDoom.Tests.Ide.ExampleStore in 'Source\DelphiDoom.Tests.Ide.ExampleStore.pas',
  DelphiDoom.Tests.Ide.ParameterHints in 'Source\DelphiDoom.Tests.Ide.ParameterHints.pas',
  DelphiDoom.Tests.Ide.Search in 'Source\DelphiDoom.Tests.Ide.Search.pas',
  DelphiDoom.Tests.Ide.RowSorter in 'Source\DelphiDoom.Tests.Ide.RowSorter.pas',
  DelphiDoom.Tests.Ide.FakeUi in 'Source\DelphiDoom.Tests.Ide.FakeUi.pas',
  DelphiDoom.Tests.Ide.MainPresenter in 'Source\DelphiDoom.Tests.Ide.MainPresenter.pas',
  DelphiDoom.Tests.Ide.ScriptEditorPresenter in 'Source\DelphiDoom.Tests.Ide.ScriptEditorPresenter.pas',
  DelphiDoom.Tests.Ide.SmallModels in 'Source\DelphiDoom.Tests.Ide.SmallModels.pas',
  DelphiDoom.Tests.Ide.Text in 'Source\DelphiDoom.Tests.Ide.Text.pas',
  DelphiDoom.Tests.Ide.ItemKinds in 'Source\DelphiDoom.Tests.Ide.ItemKinds.pas',
  DelphiDoom.Tests.Ide.ProjectFormat in 'Source\DelphiDoom.Tests.Ide.ProjectFormat.pas',
  DelphiDoom.Tests.Ide.UndoHistory in 'Source\DelphiDoom.Tests.Ide.UndoHistory.pas',
  DelphiDoom.Tests.Ide.Document in 'Source\DelphiDoom.Tests.Ide.Document.pas',
  DelphiDoom.Tests.Ide.Project in 'Source\DelphiDoom.Tests.Ide.Project.pas',
  DelphiDoom.Tests.Ide.Pk3Builder in 'Source\DelphiDoom.Tests.Ide.Pk3Builder.pas',
  DelphiDoom.Tests.Ide.CompilerMessages in 'Source\DelphiDoom.Tests.Ide.CompilerMessages.pas',
  DelphiDoom.Tests.Ide.CompileCommand in 'Source\DelphiDoom.Tests.Ide.CompileCommand.pas';

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
