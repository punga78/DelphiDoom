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
  DelphiDoom.ScriptHost.Events.Intf,
  DelphiDoom.ScriptHost.Fixed.Functions,
  DelphiDoom.ScriptHost.Game.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Serializer.Intf,
  DelphiDoom.ScriptHost.System.Functions,
  DelphiDoom.ScriptHost.System.Intf,
  DelphiDoom.ScriptHost.Types,
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
    /// <summary>The game information functions of PS_GAME (_GAME, GameSkill, the earthquakes...)</summary>
    class function CreateGameInfo(const ASource: IScriptGameInfoSource;
      const AGame: TScriptGame): IScriptFunctionSection; static;
    /// <summary>The texture functions of PS_GAME</summary>
    class function CreateTextures(const ASource: IScriptTextureSource): IScriptFunctionSection; static;
    /// <summary>The keyboard functions of PS_GAME</summary>
    class function CreateKeys(const ASource: IScriptKeyboardSource;
      const AGame: TScriptGame): IScriptFunctionSection; static;
    /// <summary>The variables of the scripts (of a map or of the world), empty</summary>
    class function CreateVariables(const AFiles: IScriptVariablesFiles;
      const AFailure: IScriptVariablesFailure): IScriptVariables; static;
    /// <summary>The events of the script that the interpreter has loaded (not owned)</summary>
    class function CreateEvents(const AExec: TPSExec; const ALog: ILog): IScriptEvents; static;
    /// <summary>The saver of the global variables of the script of the interpreter (not owned)</summary>
    class function CreateSerializer(const AExec: TPSExec; const ALog: ILog): IScriptSerializer; static;
  end;

implementation

uses
  DelphiDoom.ScriptHost.Events,
  DelphiDoom.ScriptHost.Game.Info,
  DelphiDoom.ScriptHost.Game.Textures,
  DelphiDoom.ScriptHost.Keys,
  DelphiDoom.ScriptHost.Registry,
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

class function TScriptHostFactory.CreateGameInfo(const ASource: IScriptGameInfoSource;
  const AGame: TScriptGame): IScriptFunctionSection;
begin
  Result := TScriptGameInfo.Create(ASource, AGame);
end;

class function TScriptHostFactory.CreateTextures(
  const ASource: IScriptTextureSource): IScriptFunctionSection;
begin
  Result := TScriptTextures.Create(ASource);
end;

class function TScriptHostFactory.CreateKeys(const ASource: IScriptKeyboardSource;
  const AGame: TScriptGame): IScriptFunctionSection;
begin
  Result := TScriptKeys.Create(ASource, AGame);
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

end.
