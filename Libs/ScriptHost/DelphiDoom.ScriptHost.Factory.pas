{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the factory: the composition root                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Factory;

interface

uses
  ps_runtime,
  DelphiDoom.Logging.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.ScriptHost.CallbackGroup,
  DelphiDoom.ScriptHost.Dll.Intf,
  DelphiDoom.ScriptHost.Events.Intf,
  DelphiDoom.ScriptHost.Fixed.Functions,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Intf,
  DelphiDoom.ScriptHost.Serializer.Intf,
  DelphiDoom.ScriptHost.System.Functions,
  DelphiDoom.ScriptHost.System.Intf,
  DelphiDoom.ScriptHost.Variables.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the script host</summary>
  TScriptHostFactory = class
  public
    /// <summary>A registry with no units</summary>
    class function CreateRegistry: IScriptFunctionRegistry; static;
    /// <summary>The unit SYSTEM of the scripts: for the registry ask it for an IScriptFunctionGroup</summary>
    class function CreateSystemFunctions(const ARoutines: TScriptSystemRoutines;
      const AOutput: IScriptSystemOutput; const AEnvironment: IScriptSystemEnvironment;
      const AConsole: IScriptSystemConsole; const ARandom: IGameRandom): IScriptSystemFunctions; static;
    /// <summary>The unit PS_FIXED of the scripts</summary>
    class function CreateFixedGroup(const ARoutines: TScriptFixedRoutines): IScriptFunctionGroup; static;
    /// <summary>A unit of script whose functions a procedure writes</summary>
    class function CreateCallbackGroup(const AUnitName: string;
      const ADescribe: TScriptDescribeProcedure): IScriptFunctionGroup; static;
    /// <summary>The variables of the scripts (of a map or of the world), empty</summary>
    class function CreateVariables(const AFiles: IScriptVariablesFiles;
      const AFailure: IScriptVariablesFailure): IScriptVariables; static;
    /// <summary>The events of the script that the interpreter has loaded (not owned)</summary>
    class function CreateEvents(const AExec: TPSExec; const ALog: ILog): IScriptEvents; static;
    /// <summary>The saver of the global variables of the script of the interpreter (not owned)</summary>
    class function CreateSerializer(const AExec: TPSExec; const ALog: ILog): IScriptSerializer; static;
    /// <summary>The classes of the specials of the sectors (doors, ceilings, floors, ...) on one gateway</summary>
    class function CreateSectorSpecialFunctions(
      const ASpecials: IScriptSectorSpecials): IScriptSectorSpecialFunctions; static;
    /// <summary>The loader of the DLLs of the PAK files</summary>
    class function CreateDllLoader(const ASource: IScriptDllSource; const ALibrary: IScriptDllLibrary;
      const ALog: ILog): IScriptDllLoader; static;
    /// <summary>LoadLibrary and FreeLibrary of Windows</summary>
    class function CreateWindowsDllLibrary: IScriptDllLibrary; static;
  end;

implementation

uses
  DelphiDoom.ScriptHost.Dll.Loader,
  DelphiDoom.ScriptHost.Dll.WindowsLibrary,
  DelphiDoom.ScriptHost.Events,
  DelphiDoom.ScriptHost.Registry,
  DelphiDoom.ScriptHost.SectorSpecials.Functions,
  DelphiDoom.ScriptHost.Serializer,
  DelphiDoom.ScriptHost.Variables;

{ TScriptHostFactory }

class function TScriptHostFactory.CreateRegistry: IScriptFunctionRegistry;
begin
  Result := TScriptFunctionRegistry.Create;
end;

class function TScriptHostFactory.CreateSystemFunctions(const ARoutines: TScriptSystemRoutines;
  const AOutput: IScriptSystemOutput; const AEnvironment: IScriptSystemEnvironment;
  const AConsole: IScriptSystemConsole; const ARandom: IGameRandom): IScriptSystemFunctions;
begin
  Result := TScriptSystemFunctions.Create(ARoutines, AOutput, AEnvironment, AConsole, ARandom);
end;

class function TScriptHostFactory.CreateFixedGroup(
  const ARoutines: TScriptFixedRoutines): IScriptFunctionGroup;
begin
  Result := TScriptFixedFunctions.Create(ARoutines);
end;

class function TScriptHostFactory.CreateCallbackGroup(const AUnitName: string;
  const ADescribe: TScriptDescribeProcedure): IScriptFunctionGroup;
begin
  Result := TScriptCallbackGroup.Create(AUnitName, ADescribe);
end;

class function TScriptHostFactory.CreateVariables(const AFiles: IScriptVariablesFiles;
  const AFailure: IScriptVariablesFailure): IScriptVariables;
begin
  Result := TScriptVariables.Create(AFiles, AFailure);
end;

class function TScriptHostFactory.CreateEvents(const AExec: TPSExec; const ALog: ILog): IScriptEvents;
begin
  Result := TScriptEvents.Create(AExec, ALog);
end;

class function TScriptHostFactory.CreateSerializer(const AExec: TPSExec;
  const ALog: ILog): IScriptSerializer;
begin
  Result := TScriptSerializer.Create(AExec, ALog);
end;

class function TScriptHostFactory.CreateSectorSpecialFunctions(
  const ASpecials: IScriptSectorSpecials): IScriptSectorSpecialFunctions;
begin
  Result := TScriptSectorSpecialFunctions.Create(ASpecials);
end;

class function TScriptHostFactory.CreateDllLoader(const ASource: IScriptDllSource;
  const ALibrary: IScriptDllLibrary; const ALog: ILog): IScriptDllLoader;
begin
  Result := TScriptDllLoader.Create(ASource, ALibrary, ALog);
end;

class function TScriptHostFactory.CreateWindowsDllLibrary: IScriptDllLibrary;
begin
  Result := TScriptDllWindowsLibrary.Create;
end;

end.
