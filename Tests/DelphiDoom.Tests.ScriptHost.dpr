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
  d_delphi in '..\Libs\Script\Shim\d_delphi.pas',
  ps_defs in '..\Libs\PascalScript\ps_defs.pas',
  ps_keywords in '..\Libs\PascalScript\ps_keywords.pas',
  ps_utils in '..\Libs\PascalScript\ps_utils.pas',
  ps_compiler in '..\Libs\PascalScript\ps_compiler.pas',
  uPSPreProcessor in '..\Libs\PascalScript\uPSPreProcessor.pas',
  ps_runtime in '..\Libs\PascalScript\ps_runtime.pas',
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Libs\MathCore\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Log in '..\Libs\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Recorder in '..\Libs\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Factory in '..\Libs\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.ScriptHost.Types in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Types.pas',
  DelphiDoom.ScriptHost.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Intf.pas',
  DelphiDoom.ScriptHost.FunctionList in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.FunctionList.pas',
  DelphiDoom.ScriptHost.Registry in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Registry.pas',
  DelphiDoom.ScriptHost.CallbackGroup in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.CallbackGroup.pas',
  DelphiDoom.ScriptHost.System.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.System.Intf.pas',
  DelphiDoom.ScriptHost.System.Functions in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.System.Functions.pas',
  DelphiDoom.ScriptHost.Fixed.Functions in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Fixed.Functions.pas',
  DelphiDoom.ScriptHost.Variables.Types in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.Types.pas',
  DelphiDoom.ScriptHost.Variables.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.Intf.pas',
  DelphiDoom.ScriptHost.Variables.HashTable in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.HashTable.pas',
  DelphiDoom.ScriptHost.Variables.HashList in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.HashList.pas',
  DelphiDoom.ScriptHost.Variables in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.pas',
  DelphiDoom.ScriptHost.Events.Table in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Events.Table.pas',
  DelphiDoom.ScriptHost.Events.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Events.Intf.pas',
  DelphiDoom.ScriptHost.Events in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Events.pas',
  DelphiDoom.ScriptHost.Serializer.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Serializer.Intf.pas',
  DelphiDoom.ScriptHost.Serializer in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Serializer.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Types in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Types.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Intf.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Base in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Base.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Doors in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Doors.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Ceilings in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Ceilings.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Floors in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Floors.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Lights in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Lights.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Plats in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Plats.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Pillars in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Pillars.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Polyobjects in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Polyobjects.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf.pas',
  DelphiDoom.ScriptHost.SectorSpecials.Functions in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.SectorSpecials.Functions.pas',
  DelphiDoom.ScriptHost.Dll.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Dll.Intf.pas',
  DelphiDoom.ScriptHost.Dll.Loader in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Dll.Loader.pas',
  DelphiDoom.ScriptHost.Dll.WindowsLibrary in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Dll.WindowsLibrary.pas',
  DelphiDoom.ScriptHost.Game.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Game.Intf.pas',
  DelphiDoom.ScriptHost.Games in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Games.pas',
  DelphiDoom.ScriptHost.Game.Info in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Game.Info.pas',
  DelphiDoom.ScriptHost.Game.Textures in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Game.Textures.pas',
  DelphiDoom.ScriptHost.World.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.World.Intf.pas',
  DelphiDoom.ScriptHost.World.Vertices in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.World.Vertices.pas',
  DelphiDoom.ScriptHost.World.Sides in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.World.Sides.pas',
  DelphiDoom.ScriptHost.World.Lines in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.World.Lines.pas',
  DelphiDoom.ScriptHost.World.Sectors in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.World.Sectors.pas',
  DelphiDoom.ScriptHost.Keys.Table in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Keys.Table.pas',
  DelphiDoom.ScriptHost.Keys in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Keys.pas',
  DelphiDoom.ScriptHost.Factory in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Factory.pas',
  DelphiDoom.Tests.ScriptHost.OldSectorSpecials in 'Source\DelphiDoom.Tests.ScriptHost.OldSectorSpecials.pas',
  DelphiDoom.Tests.ScriptHost.SectorSpecials in 'Source\DelphiDoom.Tests.ScriptHost.SectorSpecials.pas',
  DelphiDoom.Tests.ScriptHost.DllLoader in 'Source\DelphiDoom.Tests.ScriptHost.DllLoader.pas',
  DelphiDoom.Tests.ScriptHost.Fakes in 'Source\DelphiDoom.Tests.ScriptHost.Fakes.pas',
  DelphiDoom.Tests.ScriptHost.Interpreter in 'Source\DelphiDoom.Tests.ScriptHost.Interpreter.pas',
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
  DelphiDoom.Tests.ScriptHost.Sectors in 'Source\DelphiDoom.Tests.ScriptHost.Sectors.pas';

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