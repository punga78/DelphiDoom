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
  DelphiDoom.Wad.Types in '..\Libs\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Name in '..\Libs\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Text in '..\Libs\Wad\DelphiDoom.Wad.Text.pas',
  DelphiDoom.Wad.FileBase in '..\Libs\Wad\DelphiDoom.Wad.FileBase.pas',
  DelphiDoom.Wad.Intf in '..\Libs\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Indicators in '..\Libs\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\Libs\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Libs\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Source.Zip in '..\Libs\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Wad.Fs.Types in '..\Libs\Wad\DelphiDoom.Wad.Fs.Types.pas',
  DelphiDoom.Wad.Fs.Intf in '..\Libs\Wad\DelphiDoom.Wad.Fs.Intf.pas',
  DelphiDoom.Wad.Fs.Write.Intf in '..\Libs\Wad\DelphiDoom.Wad.Fs.Write.Intf.pas',
  DelphiDoom.Wad.Fs.Paths in '..\Libs\Wad\DelphiDoom.Wad.Fs.Paths.pas',
  DelphiDoom.Wad.Fs.AddonParser in '..\Libs\Wad\DelphiDoom.Wad.Fs.AddonParser.pas',
  DelphiDoom.Wad.Fs.Disk in '..\Libs\Wad\DelphiDoom.Wad.Fs.Disk.pas',
  DelphiDoom.Wad.Fs.Pack in '..\Libs\Wad\DelphiDoom.Wad.Fs.Pack.pas',
  DelphiDoom.Wad.Fs.PackLoader in '..\Libs\Wad\DelphiDoom.Wad.Fs.PackLoader.pas',
  DelphiDoom.Wad.Fs.GameFile in '..\Libs\Wad\DelphiDoom.Wad.Fs.GameFile.pas',
  DelphiDoom.Wad.Fs.FileSystem in '..\Libs\Wad\DelphiDoom.Wad.Fs.FileSystem.pas',
  DelphiDoom.Wad.Fs.DiskWriter in '..\Libs\Wad\DelphiDoom.Wad.Fs.DiskWriter.pas',
  DelphiDoom.Wad.Fs.WriteFile in '..\Libs\Wad\DelphiDoom.Wad.Fs.WriteFile.pas',
  DelphiDoom.Wad.Fs.Writer in '..\Libs\Wad\DelphiDoom.Wad.Fs.Writer.pas',
  DelphiDoom.Wad.Fs.ModList.Intf in '..\Libs\Wad\DelphiDoom.Wad.Fs.ModList.Intf.pas',
  DelphiDoom.Wad.Fs.PureServer.Intf in '..\Libs\Wad\DelphiDoom.Wad.Fs.PureServer.Intf.pas',
  DelphiDoom.Wad.Fs.ModLister in '..\Libs\Wad\DelphiDoom.Wad.Fs.ModLister.pas',
  DelphiDoom.Wad.Fs.PackStatus in '..\Libs\Wad\DelphiDoom.Wad.Fs.PackStatus.pas',
  DelphiDoom.Wad.Fs.PureServer in '..\Libs\Wad\DelphiDoom.Wad.Fs.PureServer.pas',
  DelphiDoom.Wad.Fs.Factory in '..\Libs\Wad\DelphiDoom.Wad.Fs.Factory.pas',
  DelphiDoom.Console.CmdSystem.Types in '..\Libs\Console\DelphiDoom.Console.CmdSystem.Types.pas',
  DelphiDoom.Console.CmdSystem.Intf in '..\Libs\Console\DelphiDoom.Console.CmdSystem.Intf.pas',
  DelphiDoom.Console.CmdSystem.CommandList in '..\Libs\Console\DelphiDoom.Console.CmdSystem.CommandList.pas',
  DelphiDoom.Console.CmdSystem.Buffer in '..\Libs\Console\DelphiDoom.Console.CmdSystem.Buffer.pas',
  DelphiDoom.Console.CmdSystem.System in '..\Libs\Console\DelphiDoom.Console.CmdSystem.System.pas',
  DelphiDoom.Console.CmdSystem.Completions in '..\Libs\Console\DelphiDoom.Console.CmdSystem.Completions.pas',
  DelphiDoom.Decl.Types in '..\Libs\Decl\DelphiDoom.Decl.Types.pas',
  DelphiDoom.Decl.Source.Intf in '..\Libs\Decl\DelphiDoom.Decl.Source.Intf.pas',
  DelphiDoom.Decl.Statistics.Intf in '..\Libs\Decl\DelphiDoom.Decl.Statistics.Intf.pas',
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
  DelphiDoom.Decl.Particle.Types in '..\Libs\Decl\DelphiDoom.Decl.Particle.Types.pas',
  DelphiDoom.Decl.Particle.Intf in '..\Libs\Decl\DelphiDoom.Decl.Particle.Intf.pas',
  DelphiDoom.Decl.Particle.Generator in '..\Libs\Decl\DelphiDoom.Decl.Particle.Generator.pas',
  DelphiDoom.Decl.Particle.StageParser in '..\Libs\Decl\DelphiDoom.Decl.Particle.StageParser.pas',
  DelphiDoom.Decl.Particle.Writer in '..\Libs\Decl\DelphiDoom.Decl.Particle.Writer.pas',
  DelphiDoom.Decl.Particle in '..\Libs\Decl\DelphiDoom.Decl.Particle.pas',
  DelphiDoom.Decl.Particle.Registration in '..\Libs\Decl\DelphiDoom.Decl.Particle.Registration.pas',
  DelphiDoom.Decl.Fx.Types in '..\Libs\Decl\DelphiDoom.Decl.Fx.Types.pas',
  DelphiDoom.Decl.Fx.Intf in '..\Libs\Decl\DelphiDoom.Decl.Fx.Intf.pas',
  DelphiDoom.Decl.Fx.ActionParser in '..\Libs\Decl\DelphiDoom.Decl.Fx.ActionParser.pas',
  DelphiDoom.Decl.Fx in '..\Libs\Decl\DelphiDoom.Decl.Fx.pas',
  DelphiDoom.Decl.Fx.Registration in '..\Libs\Decl\DelphiDoom.Decl.Fx.Registration.pas',
  DelphiDoom.Decl.ArticulatedFigure.Types in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.Types.pas',
  DelphiDoom.Decl.ArticulatedFigure.Intf in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.Intf.pas',
  DelphiDoom.Decl.ArticulatedFigure.Contents in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.Contents.pas',
  DelphiDoom.Decl.ArticulatedFigure.VectorParser in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.VectorParser.pas',
  DelphiDoom.Decl.ArticulatedFigure.BodyParser in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.BodyParser.pas',
  DelphiDoom.Decl.ArticulatedFigure.ConstraintParser in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.ConstraintParser.pas',
  DelphiDoom.Decl.ArticulatedFigure.SettingsParser in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.SettingsParser.pas',
  DelphiDoom.Decl.ArticulatedFigure.Writer in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.Writer.pas',
  DelphiDoom.Decl.ArticulatedFigure.Finisher in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.Finisher.pas',
  DelphiDoom.Decl.ArticulatedFigure in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.pas',
  DelphiDoom.Decl.ArticulatedFigure.Registration in '..\Libs\Decl\DelphiDoom.Decl.ArticulatedFigure.Registration.pas',
  DelphiDoom.Decl.Sound.Types in '..\Libs\Decl\DelphiDoom.Decl.Sound.Types.pas',
  DelphiDoom.Decl.Sound.Intf in '..\Libs\Decl\DelphiDoom.Decl.Sound.Intf.pas',
  DelphiDoom.Decl.Sound.NameCatalog in '..\Libs\Decl\DelphiDoom.Decl.Sound.NameCatalog.pas',
  DelphiDoom.Decl.Sound.Parser in '..\Libs\Decl\DelphiDoom.Decl.Sound.Parser.pas',
  DelphiDoom.Decl.Sound in '..\Libs\Decl\DelphiDoom.Decl.Sound.pas',
  DelphiDoom.Decl.Sound.Registration in '..\Libs\Decl\DelphiDoom.Decl.Sound.Registration.pas',
  DelphiDoom.Decl.FileScanner.Intf in '..\Libs\Decl\DelphiDoom.Decl.FileScanner.Intf.pas',
  DelphiDoom.Decl.Q3Shader.Types in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Types.pas',
  DelphiDoom.Decl.Q3Shader.Intf in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Intf.pas',
  DelphiDoom.Decl.Q3Shader.Tokenizer in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Tokenizer.pas',
  DelphiDoom.Decl.Q3Shader.Context in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Context.pas',
  DelphiDoom.Decl.Q3Shader.Names in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Names.pas',
  DelphiDoom.Decl.Q3Shader.ValueParser in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.ValueParser.pas',
  DelphiDoom.Decl.Q3Shader.TexModParser in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.TexModParser.pas',
  DelphiDoom.Decl.Q3Shader.StageParser in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.StageParser.pas',
  DelphiDoom.Decl.Q3Shader.DeformParser in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.DeformParser.pas',
  DelphiDoom.Decl.Q3Shader.Parser in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Parser.pas',
  DelphiDoom.Decl.Q3Shader.Finisher in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Finisher.pas',
  DelphiDoom.Decl.Q3Shader.Compressor in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Compressor.pas',
  DelphiDoom.Decl.Q3Shader.FileScanner in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.FileScanner.pas',
  DelphiDoom.Decl.Q3Shader in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.pas',
  DelphiDoom.Decl.Q3Shader.DeclType in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.DeclType.pas',
  DelphiDoom.Decl.Q3Shader.Registration in '..\Libs\Decl\DelphiDoom.Decl.Q3Shader.Registration.pas',
  DelphiDoom.Decl.StandardTypes in '..\Libs\Decl\DelphiDoom.Decl.StandardTypes.pas',
  DelphiDoom.Decl.Source.GameFs in '..\Libs\Decl\DelphiDoom.Decl.Source.GameFs.pas',
  DelphiDoom.Decl.Console.Intf in '..\Libs\Decl\DelphiDoom.Decl.Console.Intf.pas',
  DelphiDoom.Decl.Console.TypeCommands in '..\Libs\Decl\DelphiDoom.Decl.Console.TypeCommands.pas',
  DelphiDoom.Decl.Console.Commands in '..\Libs\Decl\DelphiDoom.Decl.Console.Commands.pas',
  DelphiDoom.Decl.Factory in '..\Libs\Decl\DelphiDoom.Decl.Factory.pas',
  DelphiDoom.Tests.Scanner.IdFakes in 'Source\DelphiDoom.Tests.Scanner.IdFakes.pas',
  DelphiDoom.Tests.Decl.Support in 'Source\DelphiDoom.Tests.Decl.Support.pas',
  DelphiDoom.Tests.Decl.Source in 'Source\DelphiDoom.Tests.Decl.Source.pas',
  DelphiDoom.Tests.Decl.Manager in 'Source\DelphiDoom.Tests.Decl.Manager.pas',
  DelphiDoom.Tests.Decl.Types in 'Source\DelphiDoom.Tests.Decl.Types.pas',
  DelphiDoom.Tests.Decl.EntityDef in 'Source\DelphiDoom.Tests.Decl.EntityDef.pas',
  DelphiDoom.Tests.Decl.Pda in 'Source\DelphiDoom.Tests.Decl.Pda.pas',
  DelphiDoom.Tests.Decl.Golden in 'Source\DelphiDoom.Tests.Decl.Golden.pas',
  DelphiDoom.Tests.Decl.MaterialSupport in 'Source\DelphiDoom.Tests.Decl.MaterialSupport.pas',
  DelphiDoom.Tests.Decl.MaterialExpressions in 'Source\DelphiDoom.Tests.Decl.MaterialExpressions.pas',
  DelphiDoom.Tests.Decl.Material in 'Source\DelphiDoom.Tests.Decl.Material.pas',
  DelphiDoom.Tests.Decl.MaterialGolden in 'Source\DelphiDoom.Tests.Decl.MaterialGolden.pas',
  DelphiDoom.Tests.Decl.EffectsSupport in 'Source\DelphiDoom.Tests.Decl.EffectsSupport.pas',
  DelphiDoom.Tests.Decl.EffectsGolden in 'Source\DelphiDoom.Tests.Decl.EffectsGolden.pas',
  DelphiDoom.Tests.Decl.Effects in 'Source\DelphiDoom.Tests.Decl.Effects.pas',
  DelphiDoom.Tests.Decl.Q3Shader in 'Source\DelphiDoom.Tests.Decl.Q3Shader.pas',
  DelphiDoom.Tests.Decl.Q3ShaderGolden in 'Source\DelphiDoom.Tests.Decl.Q3ShaderGolden.pas',
  DelphiDoom.Tests.Decl.ArticulatedFigureSupport in 'Source\DelphiDoom.Tests.Decl.ArticulatedFigureSupport.pas',
  DelphiDoom.Tests.Decl.ArticulatedFigure in 'Source\DelphiDoom.Tests.Decl.ArticulatedFigure.pas',
  DelphiDoom.Tests.Decl.ArticulatedFigureGolden in 'Source\DelphiDoom.Tests.Decl.ArticulatedFigureGolden.pas',
  DelphiDoom.Tests.Decl.SoundSupport in 'Source\DelphiDoom.Tests.Decl.SoundSupport.pas',
  DelphiDoom.Tests.Decl.SoundGolden in 'Source\DelphiDoom.Tests.Decl.SoundGolden.pas',
  DelphiDoom.Tests.Decl.Sound in 'Source\DelphiDoom.Tests.Decl.Sound.pas',
  DelphiDoom.Tests.Wad.MemoryDisk in 'Source\DelphiDoom.Tests.Wad.MemoryDisk.pas',
  DelphiDoom.Tests.Wad.MemoryWriteDisk in 'Source\DelphiDoom.Tests.Wad.MemoryWriteDisk.pas',
  DelphiDoom.Tests.Decl.GameFileSource in 'Source\DelphiDoom.Tests.Decl.GameFileSource.pas',
  DelphiDoom.Tests.Decl.GameFsManager in 'Source\DelphiDoom.Tests.Decl.GameFsManager.pas',
  DelphiDoom.Tests.Decl.ConsoleCommands in 'Source\DelphiDoom.Tests.Decl.ConsoleCommands.pas',
  DelphiDoom.Tests.Decl.MaterialSave in 'Source\DelphiDoom.Tests.Decl.MaterialSave.pas';

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
