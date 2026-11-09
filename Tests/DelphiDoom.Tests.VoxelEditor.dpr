{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the VoxelEditor library (DUnitX)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.VoxelEditor;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Types.pas',
  DelphiDoom.VoxelEditor.Model in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Model.pas',
  DelphiDoom.VoxelEditor.Views in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Views.pas',
  DelphiDoom.VoxelEditor.Planes in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Planes.pas',
  DelphiDoom.VoxelEditor.Transforms in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Transforms.pas',
  DelphiDoom.VoxelEditor.Palettes in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Palettes.pas',
  DelphiDoom.VoxelEditor.Operations in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Operations.pas',
  DelphiDoom.VoxelEditor.Rotator in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Rotator.pas',
  DelphiDoom.VoxelEditor.Quantizer in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Quantizer.pas',
  DelphiDoom.VoxelEditor.ByteReader in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.ByteReader.pas',
  DelphiDoom.VoxelEditor.Format.SlabPalette in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.SlabPalette.pas',
  DelphiDoom.VoxelEditor.Format.Ddvox in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddvox.pas',
  DelphiDoom.VoxelEditor.Format.Kvx in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Kvx.pas',
  DelphiDoom.VoxelEditor.Format.Vox in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Vox.pas',
  DelphiDoom.VoxelEditor.Format.Ddmesh in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddmesh.pas',
  DelphiDoom.VoxelEditor.MeshOptimizer in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.MeshOptimizer.pas',
  DelphiDoom.VoxelEditor.Painter in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Painter.pas',
  DelphiDoom.VoxelEditor.Intf in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Intf.pas',
  DelphiDoom.VoxelEditor.Presenter in '..\Libs\VoxelEditor\DelphiDoom.VoxelEditor.Presenter.pas',
  DelphiDoom.Tools.Factory in '..\Libs\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Tools.PathText in '..\Libs\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Tools.Intf in '..\Libs\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Tools.Types in '..\Libs\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.UndoHistory in '..\Libs\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in '..\Libs\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in '..\Libs\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in '..\Libs\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in '..\Libs\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Palette.GamePalettes in '..\Libs\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Palette.GamePaletteData in '..\Libs\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Palette.Types in '..\Libs\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Tests.ToolsCore.Fakes in 'Source\DelphiDoom.Tests.ToolsCore.Fakes.pas',
  DelphiDoom.Tests.VoxelEditor.Scenarios in 'Source\DelphiDoom.Tests.VoxelEditor.Scenarios.pas',
  DelphiDoom.Tests.VoxelEditor.Fakes in 'Source\DelphiDoom.Tests.VoxelEditor.Fakes.pas',
  DelphiDoom.Tests.VoxelEditor.Presenter in 'Source\DelphiDoom.Tests.VoxelEditor.Presenter.pas',
  DelphiDoom.Tests.VoxelEditor.Model in 'Source\DelphiDoom.Tests.VoxelEditor.Model.pas',
  DelphiDoom.Tests.VoxelEditor.Views in 'Source\DelphiDoom.Tests.VoxelEditor.Views.pas',
  DelphiDoom.Tests.VoxelEditor.Planes in 'Source\DelphiDoom.Tests.VoxelEditor.Planes.pas',
  DelphiDoom.Tests.VoxelEditor.Transforms in 'Source\DelphiDoom.Tests.VoxelEditor.Transforms.pas',
  DelphiDoom.Tests.VoxelEditor.Operations in 'Source\DelphiDoom.Tests.VoxelEditor.Operations.pas',
  DelphiDoom.Tests.VoxelEditor.Rotator in 'Source\DelphiDoom.Tests.VoxelEditor.Rotator.pas',
  DelphiDoom.Tests.VoxelEditor.Quantizer in 'Source\DelphiDoom.Tests.VoxelEditor.Quantizer.pas',
  DelphiDoom.Tests.VoxelEditor.Palettes in 'Source\DelphiDoom.Tests.VoxelEditor.Palettes.pas',
  DelphiDoom.Tests.VoxelEditor.Ddvox in 'Source\DelphiDoom.Tests.VoxelEditor.Ddvox.pas',
  DelphiDoom.Tests.VoxelEditor.Kvx in 'Source\DelphiDoom.Tests.VoxelEditor.Kvx.pas',
  DelphiDoom.Tests.VoxelEditor.Vox in 'Source\DelphiDoom.Tests.VoxelEditor.Vox.pas',
  DelphiDoom.Tests.VoxelEditor.Ddmesh in 'Source\DelphiDoom.Tests.VoxelEditor.Ddmesh.pas',
  DelphiDoom.Tests.VoxelEditor.MeshOptimizer in 'Source\DelphiDoom.Tests.VoxelEditor.MeshOptimizer.pas',
  DelphiDoom.Tests.VoxelEditor.ByteReader in 'Source\DelphiDoom.Tests.VoxelEditor.ByteReader.pas',
  DelphiDoom.Tests.VoxelEditor.Painter in 'Source\DelphiDoom.Tests.VoxelEditor.Painter.pas',
  DelphiDoom.Tests.VoxelEditor.Parity in 'Source\DelphiDoom.Tests.VoxelEditor.Parity.pas';

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
