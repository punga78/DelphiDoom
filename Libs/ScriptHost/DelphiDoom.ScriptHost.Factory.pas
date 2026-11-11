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
  DelphiDoom.ScriptHost.Game.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.MobjInfo.Intf,
  DelphiDoom.ScriptHost.Players.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Intf,
  DelphiDoom.ScriptHost.Serializer.Intf,
  DelphiDoom.ScriptHost.System.Functions,
  DelphiDoom.ScriptHost.System.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.ScriptHost.Variables.Intf,
  DelphiDoom.ScriptHost.World.Intf;

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
    /// <summary>The vertex functions of PS_GAME</summary>
    class function CreateVertices(const AWorld: IScriptWorld): IScriptVertices; static;
    /// <summary>The side functions of PS_GAME</summary>
    class function CreateSides(const AWorld: IScriptWorld): IScriptSides; static;
    /// <summary>The line functions of PS_GAME (Hexen has no tag and no transparent lines)</summary>
    class function CreateLines(const AWorld: IScriptWorld; const AGame: TScriptGame): IScriptLines; static;
    /// <summary>The sector functions of PS_GAME (the offsets of the textures exist in Doom and Strife only)</summary>
    class function CreateSectors(const AWorld: IScriptWorld; const AGame: TScriptGame): IScriptSectors; static;
    /// <summary>The mobjinfo functions of PS_GAME (Strife has GetMobjInfoName2)</summary>
    class function CreateMobjInfo(const ASource: IScriptMobjInfoSource;
      const AGame: TScriptGame): IScriptMobjInfo; static;
    /// <summary>The player functions of PS_GAME (keys, artifacts, ammunition, mana and quests depend on the game)</summary>
    class function CreatePlayers(const ASource: IScriptPlayerSource;
      const AGame: TScriptGame): IScriptPlayers; static;
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
  DelphiDoom.ScriptHost.Game.Info,
  DelphiDoom.ScriptHost.Game.Textures,
  DelphiDoom.ScriptHost.Keys,
  DelphiDoom.ScriptHost.Registry,
  DelphiDoom.ScriptHost.SectorSpecials.Functions,
  DelphiDoom.ScriptHost.Serializer,
  DelphiDoom.ScriptHost.Variables,
  DelphiDoom.ScriptHost.World.Lines,
  DelphiDoom.ScriptHost.MobjInfo,
  DelphiDoom.ScriptHost.Players,
  DelphiDoom.ScriptHost.World.Sectors,
  DelphiDoom.ScriptHost.World.Sides,
  DelphiDoom.ScriptHost.World.Vertices;

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

class function TScriptHostFactory.CreateVertices(const AWorld: IScriptWorld): IScriptVertices;
begin
  Result := TScriptVertices.Create(AWorld);
end;

class function TScriptHostFactory.CreateSides(const AWorld: IScriptWorld): IScriptSides;
begin
  Result := TScriptSides.Create(AWorld);
end;

class function TScriptHostFactory.CreateLines(const AWorld: IScriptWorld;
  const AGame: TScriptGame): IScriptLines;
begin
  Result := TScriptLines.Create(AWorld, AGame);
end;

class function TScriptHostFactory.CreateSectors(const AWorld: IScriptWorld;
  const AGame: TScriptGame): IScriptSectors;
begin
  Result := TScriptSectors.Create(AWorld, AGame);
end;

class function TScriptHostFactory.CreateMobjInfo(const ASource: IScriptMobjInfoSource;
  const AGame: TScriptGame): IScriptMobjInfo;
begin
  Result := TScriptMobjInfo.Create(ASource, AGame);
end;

class function TScriptHostFactory.CreatePlayers(const ASource: IScriptPlayerSource;
  const AGame: TScriptGame): IScriptPlayers;
begin
  Result := TScriptPlayers.Create(ASource, AGame);
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
