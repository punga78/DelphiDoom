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
  System.SysUtils,
  ps_compiler,
  ps_runtime,
  DelphiDoom.Logging.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.ScriptHost.Actors.Intf,
  DelphiDoom.ScriptHost.CallbackGroup,
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.ScriptHost.Dll.Intf,
  DelphiDoom.ScriptHost.Services.Intf,
  DelphiDoom.ScriptHost.Source.Intf,
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
    /// <summary>A catalog of the classes that scripts see, with no classes yet, for a game</summary>
    class function CreateClassCatalog(const AGame: TScriptGame): IScriptClassCatalog; static;
    /// <summary>The services of the compiler and the interpreter of the scripts (see IScriptHostServices)</summary>
    class function CreateServices(const ARegistry: IScriptFunctionRegistry;
      const AClasses: IScriptClassCatalog; const AConstants: IScriptConstantProvider;
      const ASources: IScriptSourceProvider; const AGameName: string; const AGame: TScriptGame;
      const ADefines: TFunc<TArray<string>>): IScriptHostServices; static;
    /// <summary>The defines of the preprocessor of the scripts for a game (see TScriptDefines)</summary>
    class function CreateDefines(const AGameName: string; const AGame: TScriptGame; const ADebug,
      ADevParm, AOpenGL: Boolean): TArray<string>; static;
    /// <summary>
    ///   The constants of the unit SYSTEM: the basic ones, the four parts that the engine gives
    ///   (mobjs, game, world, groups) and the generalized linedef types between the last two, in
    ///   the order of the old PS_ScriptOnUses
    /// </summary>
    class function CreateConstants(const AMobjs, AGame, AWorld, AGroups: IScriptConstantProvider): IScriptConstantProvider; static;
    /// <summary>The table of constants that writes in a compiler of scripts</summary>
    class function CreateCompilerConstants(const ACompiler: TPSPascalCompiler): IScriptConstantTable; static;
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
    /// <summary>The actor functions of PS_GAME (the mobjs only through the source; Strife has GetActorName2)</summary>
    class function CreateActors(const ASource: IScriptActorSource; const AContext: IScriptActorContext;
      const APlayers: IScriptPlayers; const AGame: TScriptGame): IScriptActors; static;
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
  DelphiDoom.ScriptHost.Actors,
  DelphiDoom.ScriptHost.Classes.Catalog,
  DelphiDoom.ScriptHost.Constants.Basic,
  DelphiDoom.ScriptHost.Constants.Chain,
  DelphiDoom.ScriptHost.Constants.Compiler,
  DelphiDoom.ScriptHost.Constants.Generalized,
  DelphiDoom.ScriptHost.Defines,
  DelphiDoom.ScriptHost.Services,
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

class function TScriptHostFactory.CreateServices(const ARegistry: IScriptFunctionRegistry;
  const AClasses: IScriptClassCatalog; const AConstants: IScriptConstantProvider;
  const ASources: IScriptSourceProvider; const AGameName: string; const AGame: TScriptGame;
  const ADefines: TFunc<TArray<string>>): IScriptHostServices;
begin
  Result := TScriptHostServices.Create(ARegistry, AClasses, AConstants, ASources, AGameName, AGame,
    ADefines);
end;

class function TScriptHostFactory.CreateDefines(const AGameName: string; const AGame: TScriptGame;
  const ADebug, ADevParm, AOpenGL: Boolean): TArray<string>;
begin
  Result := TScriptDefines.ForGame(AGameName, AGame, ADebug, ADevParm, AOpenGL);
end;

class function TScriptHostFactory.CreateClassCatalog(const AGame: TScriptGame): IScriptClassCatalog;
begin
  Result := TScriptClassCatalog.Create(AGame);
end;

class function TScriptHostFactory.CreateConstants(const AMobjs, AGame, AWorld,
  AGroups: IScriptConstantProvider): IScriptConstantProvider;
begin
  Result := TScriptConstantChain.Create([TScriptBasicConstants.Create, AMobjs, AGame, AWorld,
    TScriptGeneralizedConstants.Create, AGroups]);
end;

class function TScriptHostFactory.CreateCompilerConstants(
  const ACompiler: TPSPascalCompiler): IScriptConstantTable;
begin
  Result := TScriptCompilerConstants.Create(ACompiler);
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

class function TScriptHostFactory.CreateActors(const ASource: IScriptActorSource;
  const AContext: IScriptActorContext; const APlayers: IScriptPlayers;
  const AGame: TScriptGame): IScriptActors;
begin
  Result := TScriptActors.Create(ASource, AContext, APlayers, AGame);
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
