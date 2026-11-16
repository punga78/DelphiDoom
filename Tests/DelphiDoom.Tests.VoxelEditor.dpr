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
  DelphiDoom.VoxelEditor.Types in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Types.pas',
  DelphiDoom.VoxelEditor.Model in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Model.pas',
  DelphiDoom.VoxelEditor.Views in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Views.pas',
  DelphiDoom.VoxelEditor.Planes in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Planes.pas',
  DelphiDoom.VoxelEditor.Transforms in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Transforms.pas',
  DelphiDoom.VoxelEditor.Palettes in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Palettes.pas',
  DelphiDoom.VoxelEditor.Operations in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Operations.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Framework\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.VoxelEditor.Rotator in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Rotator.pas',
  DelphiDoom.VoxelEditor.Quantizer in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Quantizer.pas',
  DelphiDoom.Bytes.Types in '..\Framework\Bytes\DelphiDoom.Bytes.Types.pas',
  DelphiDoom.Bytes.Reader in '..\Framework\Bytes\DelphiDoom.Bytes.Reader.pas',
  DelphiDoom.VoxelEditor.ByteReader in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.ByteReader.pas',
  DelphiDoom.VoxelEditor.Format.SlabPalette in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Format.SlabPalette.pas',
  DelphiDoom.VoxelEditor.Format.Ddvox in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddvox.pas',
  DelphiDoom.VoxelEditor.Format.Kvx in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Format.Kvx.pas',
  DelphiDoom.VoxelEditor.Format.Vox in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Format.Vox.pas',
  DelphiDoom.VoxelEditor.Format.Ddmesh in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Format.Ddmesh.pas',
  DelphiDoom.VoxelEditor.MeshOptimizer in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.MeshOptimizer.pas',
  DelphiDoom.VoxelEditor.Painter in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Painter.pas',
  DelphiDoom.VoxelEditor.Intf in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Intf.pas',
  DelphiDoom.VoxelEditor.Presenter in '..\Strumenti\VoxelEditor\DelphiDoom.VoxelEditor.Presenter.pas',
  DelphiDoom.Tools.Factory in '..\Strumenti\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Tools.PathText in '..\Strumenti\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Tools.Intf in '..\Strumenti\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Tools.Types in '..\Strumenti\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.UndoHistory in '..\Strumenti\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in '..\Strumenti\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in '..\Strumenti\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in '..\Strumenti\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in '..\Strumenti\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Palette.GamePalettes in '..\Framework\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Palette.GamePaletteData in '..\Framework\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Palette.Types in '..\Framework\Palette\DelphiDoom.Palette.Types.pas',
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
