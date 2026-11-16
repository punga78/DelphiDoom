{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the script host library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.ScriptHost;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  ps_defs in '..\Framework\PascalScript\ps_defs.pas',
  ps_keywords in '..\Framework\PascalScript\ps_keywords.pas',
  ps_utils in '..\Framework\PascalScript\ps_utils.pas',
  ps_compiler in '..\Framework\PascalScript\ps_compiler.pas',
  uPSPreProcessor in '..\Framework\PascalScript\uPSPreProcessor.pas',
  ps_runtime in '..\Framework\PascalScript\ps_runtime.pas',
  DelphiDoom.MathCore.Types in '..\Framework\GameMath\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Framework\GameMath\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Log in '..\Framework\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Recorder in '..\Framework\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Factory in '..\Framework\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.ScriptHost.Types in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Types.pas',
  DelphiDoom.ScriptHost.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Intf.pas',
  DelphiDoom.ScriptHost.FunctionList in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.FunctionList.pas',
  DelphiDoom.ScriptHost.Registry in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Registry.pas',
  DelphiDoom.ScriptHost.CallbackGroup in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.CallbackGroup.pas',
  DelphiDoom.ScriptHost.Defines in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Defines.pas',
  DelphiDoom.ScriptHost.Source.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Source.Intf.pas',
  DelphiDoom.ScriptHost.Services.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Services.Intf.pas',
  DelphiDoom.ScriptHost.Services in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Services.pas',
  DelphiDoom.ScriptHost.Classes.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Classes.Intf.pas',
  DelphiDoom.ScriptHost.Classes.Descriptor in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Classes.Descriptor.pas',
  DelphiDoom.ScriptHost.Classes.Catalog in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Classes.Catalog.pas',
  DelphiDoom.ScriptHost.Constants.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Constants.Intf.pas',
  DelphiDoom.ScriptHost.Constants.Basic in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Constants.Basic.pas',
  DelphiDoom.ScriptHost.Constants.Chain in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Constants.Chain.pas',
  DelphiDoom.ScriptHost.Constants.Compiler in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Constants.Compiler.pas',
  DelphiDoom.ScriptHost.Constants.Generalized in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Constants.Generalized.pas',
  DelphiDoom.ScriptHost.System.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.System.Intf.pas',
  DelphiDoom.ScriptHost.System.Functions in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.System.Functions.pas',
  DelphiDoom.ScriptHost.Fixed.Functions in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Fixed.Functions.pas',
  DelphiDoom.ScriptHost.Variables.Types in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Variables.Types.pas',
  DelphiDoom.ScriptHost.Variables.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Variables.Intf.pas',
  DelphiDoom.ScriptHost.Variables.HashTable in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Variables.HashTable.pas',
  DelphiDoom.ScriptHost.Variables.HashList in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Variables.HashList.pas',
  DelphiDoom.ScriptHost.Variables in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Variables.pas',
  DelphiDoom.ScriptHost.Events.Table in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Events.Table.pas',
  DelphiDoom.ScriptHost.Events.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Events.Intf.pas',
  DelphiDoom.ScriptHost.Events in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Events.pas',
  DelphiDoom.ScriptHost.Serializer.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Serializer.Intf.pas',
  DelphiDoom.ScriptHost.Serializer in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Serializer.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Types in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Types.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Intf.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Base in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Base.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Doors in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Doors.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Ceilings in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Ceilings.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Floors in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Floors.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Lights in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Lights.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Plats in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Plats.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Pillars in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Pillars.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Polyobjects in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Polyobjects.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Functions in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Functions.pas',
  DelphiDoom.ScriptHost.Dll.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Dll.Intf.pas',
  DelphiDoom.ScriptHost.Dll.Loader in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Dll.Loader.pas',
  DelphiDoom.ScriptHost.Dll.WindowsLibrary in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Dll.WindowsLibrary.pas',
  DelphiDoom.ScriptHost.Game.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Game.Intf.pas',
  DelphiDoom.ScriptHost.Games in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Games.pas',
  DelphiDoom.ScriptHost.Game.Info in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Game.Info.pas',
  DelphiDoom.ScriptHost.Game.Textures in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Game.Textures.pas',
  DelphiDoom.ScriptHost.World.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.World.Intf.pas',
  DelphiDoom.ScriptHost.World.Vertices in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.World.Vertices.pas',
  DelphiDoom.ScriptHost.World.Sides in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.World.Sides.pas',
  DelphiDoom.ScriptHost.World.Lines in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.World.Lines.pas',
  DelphiDoom.ScriptHost.World.Sectors in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.World.Sectors.pas',
  DelphiDoom.ScriptHost.Overlay.Types in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Overlay.Types.pas',
  DelphiDoom.ScriptHost.Overlay.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Overlay.Intf.pas',
  DelphiDoom.ScriptHost.Overlay.NullCanvas in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Overlay.NullCanvas.pas',
  DelphiDoom.ScriptHost.Overlay.Drawer in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Overlay.Drawer.pas',
  DelphiDoom.ScriptHost.Overlay.Functions in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Overlay.Functions.pas',
  DelphiDoom.ScriptHost.MobjInfo.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.MobjInfo.Intf.pas',
  DelphiDoom.ScriptHost.MobjInfo.Table in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.MobjInfo.Table.pas',
  DelphiDoom.ScriptHost.MobjInfo in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.MobjInfo.pas',
  DelphiDoom.ScriptHost.Players.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Players.Intf.pas',
  DelphiDoom.ScriptHost.Players in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Players.pas',
  DelphiDoom.ScriptHost.Actors.KeyList in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Actors.KeyList.pas',
  DelphiDoom.ScriptHost.Actors.Intf in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Actors.Intf.pas',
  DelphiDoom.ScriptHost.Actors in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Actors.pas',
  DelphiDoom.ScriptHost.Keys.Table in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Keys.Table.pas',
  DelphiDoom.ScriptHost.Keys in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Keys.pas',
  DelphiDoom.ScriptHost.Factory in '..\Framework\ScriptHost\DelphiDoom.ScriptHost.Factory.pas',
  DelphiDoom.Tests.ScriptHost.OldSectorSpecials in 'Source\DelphiDoom.Tests.ScriptHost.OldSectorSpecials.pas',
  DelphiDoom.Tests.ScriptHost.SectorSpecials in 'Source\DelphiDoom.Tests.ScriptHost.SectorSpecials.pas',
  DelphiDoom.Tests.ScriptHost.DllLoader in 'Source\DelphiDoom.Tests.ScriptHost.DllLoader.pas',
  DelphiDoom.Tests.ScriptHost.Fakes in 'Source\DelphiDoom.Tests.ScriptHost.Fakes.pas',
  DelphiDoom.Tests.ScriptHost.Defines in 'Source\DelphiDoom.Tests.ScriptHost.Defines.pas',
  DelphiDoom.Tests.ScriptHost.Services in 'Source\DelphiDoom.Tests.ScriptHost.Services.pas',
  DelphiDoom.Tests.ScriptHost.ConstantFakes in 'Source\DelphiDoom.Tests.ScriptHost.ConstantFakes.pas',
  DelphiDoom.Tests.ScriptHost.ConstantsBasic in 'Source\DelphiDoom.Tests.ScriptHost.ConstantsBasic.pas',
  DelphiDoom.Tests.ScriptHost.ConstantsGeneralized in 'Source\DelphiDoom.Tests.ScriptHost.ConstantsGeneralized.pas',
  DelphiDoom.Tests.ScriptHost.ConstantChain in 'Source\DelphiDoom.Tests.ScriptHost.ConstantChain.pas',
  DelphiDoom.Tests.ScriptHost.ConstantsCompiler in 'Source\DelphiDoom.Tests.ScriptHost.ConstantsCompiler.pas',
  DelphiDoom.Tests.ScriptHost.ClassCatalog in 'Source\DelphiDoom.Tests.ScriptHost.ClassCatalog.pas',
  DelphiDoom.Tests.ScriptHost.Interpreter in 'Source\DelphiDoom.Tests.ScriptHost.Interpreter.pas',
  DelphiDoom.Tests.ScriptHost.CompiledExtended in 'Source\DelphiDoom.Tests.ScriptHost.CompiledExtended.pas',
  DelphiDoom.Tests.ScriptHost.VariablesFakes in 'Source\DelphiDoom.Tests.ScriptHost.VariablesFakes.pas',
  DelphiDoom.Tests.ScriptHost.Variables in 'Source\DelphiDoom.Tests.ScriptHost.Variables.pas',
  DelphiDoom.Tests.ScriptHost.VariablesHash in 'Source\DelphiDoom.Tests.ScriptHost.VariablesHash.pas',
  DelphiDoom.Tests.ScriptHost.Events in 'Source\DelphiDoom.Tests.ScriptHost.Events.pas',
  DelphiDoom.Tests.ScriptHost.Serializer in 'Source\DelphiDoom.Tests.ScriptHost.Serializer.pas',
  DelphiDoom.Tests.ScriptHost.Registry in 'Source\DelphiDoom.Tests.ScriptHost.Registry.pas',
  DelphiDoom.Tests.ScriptHost.FunctionList in 'Source\DelphiDoom.Tests.ScriptHost.FunctionList.pas',
  DelphiDoom.Tests.ScriptHost.CallbackGroup in 'Source\DelphiDoom.Tests.ScriptHost.CallbackGroup.pas',
  DelphiDoom.Tests.ScriptHost.SystemFunctions in 'Source\DelphiDoom.Tests.ScriptHost.SystemFunctions.pas',
  DelphiDoom.Tests.ScriptHost.FixedFunctions in 'Source\DelphiDoom.Tests.ScriptHost.FixedFunctions.pas',
  DelphiDoom.Tests.ScriptHost.GameSections in 'Source\DelphiDoom.Tests.ScriptHost.GameSections.pas',
  DelphiDoom.Tests.ScriptHost.World in 'Source\DelphiDoom.Tests.ScriptHost.World.pas',
  DelphiDoom.Tests.ScriptHost.Sectors in 'Source\DelphiDoom.Tests.ScriptHost.Sectors.pas',
  DelphiDoom.Tests.ScriptHost.MobjInfo in 'Source\DelphiDoom.Tests.ScriptHost.MobjInfo.pas',
  DelphiDoom.Tests.ScriptHost.Players in 'Source\DelphiDoom.Tests.ScriptHost.Players.pas',
  DelphiDoom.Tests.ScriptHost.Actors in 'Source\DelphiDoom.Tests.ScriptHost.Actors.pas',
  DelphiDoom.Tests.ScriptHost.OverlayFakes in 'Source\DelphiDoom.Tests.ScriptHost.OverlayFakes.pas',
  DelphiDoom.Tests.ScriptHost.OverlayDrawer in 'Source\DelphiDoom.Tests.ScriptHost.OverlayDrawer.pas',
  DelphiDoom.Tests.ScriptHost.OverlayFunctions in 'Source\DelphiDoom.Tests.ScriptHost.OverlayFunctions.pas',
  DelphiDoom.Tests.ScriptHost.OverlayNullCanvas in 'Source\DelphiDoom.Tests.ScriptHost.OverlayNullCanvas.pas';

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