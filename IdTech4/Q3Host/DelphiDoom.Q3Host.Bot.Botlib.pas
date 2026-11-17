{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the bot library of the game            }
{  (be_interface.c: Export_BotLibSetup ... Export_BotLibUpdateEntity)          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): be_interface.c. }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Botlib;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Facade.Intf,
  DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.World.AasWorld, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Move.Intf,
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Main.System, DelphiDoom.Aas.Entity.Types, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Bot.Intf, DelphiDoom.Q3Host.Bot.Aas, DelphiDoom.Q3Host.Bot.Bsp;

type
  /// <summary>
  ///   The botlib of a game: the library variables from the start, and between Setup and Shutdown the AAS system,
  ///   the systems of the bot AI and the world they share, made when the game sets the library up (after it set
  ///   the variables the setup reads: maxclients, maxentities, bot_developer ...). The AAS system is the only owner
  ///   of the entity table; no object keeps it, they ask the system. The router of a map is given to the bots when
  ///   the initialization of the AAS ends (a frame after the map was loaded, or several, if the reachabilities are
  ///   calculated)
  /// </summary>
  TQ3BotLibrary = class(TInterfacedObject, IQ3BotLibrary)
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FRandom: IBotRandom;
    FBsp: IAasBspWorld;
    FModels: IAasBspModels;
    FBspObject: TQ3BotBsp;
    // the machine holds the host, which holds this library: no reference back
    [weak] FMachine: IQvmMachine;
    FLibVars: IBotLibVarStore;
    FSystemRef: IInterface;
    FSystem: TAasSystem;
    FWorldRef: IInterface;
    FWorldFacade: IBotAasWorld;
    FWorld: TBotAasWorld;
    FAasRef: IQ3BotAas;
    FAas: TQ3BotAas;
    FAi: IBotAi;
    FSetup: Boolean;
    FMaxClients: Integer;
    FMaxEntities: Integer;
    FDeveloper: Boolean;
    FMapFile: IAasFile;
    FHasRouter: Boolean;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FAreas: IAasAreaQuery;
    FMovement: IAasMovement;
    function CheckSetup(const AName: string): Boolean;
    procedure RefreshMap;
    procedure RefreshRouter;
    procedure DropMap;
  public
    /// <summary>
    ///   The console prints for the library and the server runs the commands of the bots (botimport); the BSP gives
    ///   the traces and the models of the world; ARandom nil is the generator of the Microsoft runtime
    /// </summary>
    constructor Create(const AConsole: IQ3HostConsole; const AServer: IQ3HostBotServer; const AFiles: IBotFileSource;
      const ARandom: IBotRandom; const ABsp: TQ3BotBsp);
    procedure Attach(const AMachine: IQvmMachine);
    /// <summary>AAS_Time of the system in this library (0 before a Setup): the clock of the import</summary>
    function AasTime: Single;
    function IsSetup: Boolean;
    function Setup: Integer;
    function Shutdown: Integer;
    function LibVarSet(const AName, AValue: AnsiString): Integer;
    function LibVarGet(const AName: AnsiString; ASize: Integer): AnsiString;
    function StartFrame(ATime: Single): Integer;
    function LoadMap(const AMapName: AnsiString): Integer;
    function UpdateEntity(AEntity: Integer; const AState: PBotEntityState): Integer;
    function Ai: IBotAi;
    function Aas: IQ3BotAas;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.LibVars.Table, DelphiDoom.BotAi.Random.MsvcRand,
  DelphiDoom.BotAi.Facade.Factory, DelphiDoom.Aas.Entity.Table,
  DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Factory, DelphiDoom.Aas.Main.Intf, DelphiDoom.Aas.Main.Factory,
  DelphiDoom.Aas.Main.InitSteps, DelphiDoom.Aas.Move.Movement, DelphiDoom.Aas.Move.Settings,
  DelphiDoom.Q3Host.Bot.Import, DelphiDoom.Q3Host.Bot.EntitySource, DelphiDoom.Q3Host.Bot.NullRouter, DelphiDoom.Q3Host.Bot.World, DelphiDoom.Aas.Bsp.Entities,
  DelphiDoom.Q3Host.Types;

resourcestring
  SNotSetup = '%s: bot library used before being setup'#10;
  SInitialization = '------- BotLib Initialization -------'#10;
  SMapLoading = '------------ Map Loading ------------'#10;
  SMapLoaded = '-------------------------------------'#10;
  SInvalidEntity = '%s: invalid entity number %d, [0, %d]'#10;
  SNoAiYet = 'The bot library was used before it was set up';

constructor TQ3BotLibrary.Create(const AConsole: IQ3HostConsole; const AServer: IQ3HostBotServer;
  const AFiles: IBotFileSource; const ARandom: IBotRandom; const ABsp: TQ3BotBsp);
begin
  inherited Create;
  FImport := TQ3BotImport.Create(AConsole, AServer,
    function: Single
    begin
      Result := AasTime;
    end,
    function: IQvmMachine
    begin
      Result := FMachine;
    end);
  FFiles := AFiles;
  FRandom := ARandom;
  if not Assigned(FRandom) then
    FRandom := TBotMsvcRandom.Create;
  FBspObject := ABsp;
  FBsp := ABsp;
  FModels := ABsp;
  FLibVars := TBotLibVarTable.Create;
end;

procedure TQ3BotLibrary.Attach(const AMachine: IQvmMachine);
begin
  FMachine := AMachine;
  FBspObject.Attach(AMachine.Memory);
end;

function TQ3BotLibrary.AasTime: Single;
begin
  if Assigned(FSystem) then
    Result := FSystem.Time
  else
    Result := 0;
end;

function TQ3BotLibrary.IsSetup: Boolean;
begin
  Result := FSetup;
end;

// BotLibSetup( str ): the message of be_interface.c and False
function TQ3BotLibrary.CheckSetup(const AName: string): Boolean;
begin
  Result := FSetup;
  if not Result then
    FImport.Print(PRT_ERROR, AnsiString(Format(SNotSetup, [AName])));
end;

function TQ3BotLibrary.Setup: Integer;
var
  LEntities: IBotEntitySource;
begin
  FDeveloper := Trunc(FLibVars.GetValue('bot_developer')) <> 0;
  FImport.Print(PRT_MESSAGE, AnsiString(SInitialization));
  FMaxClients := Trunc(FLibVars.GetValueOrCreate('maxclients', '128'));
  FMaxEntities := Trunc(FLibVars.GetValueOrCreate('maxentities', '1024'));

  // AAS_Setup
  FSystem := TAasSystemFactory.CreateSystem(FImport, FFiles, FLibVars, FBsp, FModels, nil, nil, FDeveloper);
  FSystemRef := FSystem;
  Result := FSystem.Setup;
  if Result <> BLERR_NOERROR then
    Exit;
  FAas := TQ3BotAas.Create(FImport, FSystem, FBsp);
  FAasRef := FAas;
  LEntities := TQ3BotEntitySource.Create(
    function: TAasEntityTable
    begin
      if Assigned(FSystem) then
        Result := FSystem.Entities
      else
        Result := nil;
    end);
  FWorld := TBotAasWorld.Create(FBsp, FModels, LEntities);
  FWorldRef := FWorld;
  // EA_Setup and the systems that are made together with the actions
  FWorldFacade := TQ3BotWorld.Create(FWorld, TAasBspEntities.Create(FImport, ''));
  FAi := TBotAiFactory.CreateAi(FImport, FFiles, FLibVars, FRandom, FWorldFacade, FMaxClients, FDeveloper);
  Result := FAi.Weapons.Setup;
  if Result <> BLERR_NOERROR then
    Exit;
  Result := FAi.Goals.Setup;
  if Result <> BLERR_NOERROR then
    Exit;
  Result := FAi.Chat.Setup;
  if Result <> BLERR_NOERROR then
    Exit;
  Result := FAi.Moves.Setup;
  if Result <> BLERR_NOERROR then
    Exit;
  FSetup := True;
end;

function TQ3BotLibrary.Shutdown: Integer;
begin
  if not CheckSetup('BotLibShutdown') then
    Exit(Q3BOT_BLERR_LIBRARYNOTSETUP);
  FAi.Chat.Shutdown;
  FAi.Moves.Shutdown;
  FAi.Goals.Shutdown;
  FAi.Weapons.Shutdown;
  FAi.Weights.Shutdown;
  FAi.Characters.Shutdown;
  // AAS_Shutdown, and everything that was made at the setup goes
  FSystem.Shutdown;
  DropMap;
  FAi := nil;
  FWorld := nil;
  FWorldRef := nil;
  FAas := nil;
  FAasRef := nil;
  FSystem := nil;
  FSystemRef := nil;
  // LibVarDeAllocAll
  FLibVars := TBotLibVarTable.Create;
  FSetup := False;
  Result := BLERR_NOERROR;
end;

function TQ3BotLibrary.LibVarSet(const AName, AValue: AnsiString): Integer;
begin
  FLibVars.SetText(AName, AValue);
  Result := BLERR_NOERROR;
end;

function TQ3BotLibrary.LibVarGet(const AName: AnsiString; ASize: Integer): AnsiString;
begin
  // LibVarGetString does not create the variable; the text is cut to size - 1 characters
  Result := FLibVars.GetString(AName);
  if (ASize > 0) and (Length(Result) > ASize - 1) then
    Result := Copy(Result, 1, ASize - 1);
end;

procedure TQ3BotLibrary.DropMap;
begin
  FMapFile := nil;
  FSampler := nil;
  FTracer := nil;
  FAreas := nil;
  FMovement := nil;
  FHasRouter := False;
  if Assigned(FWorld) then
    FWorld.ClearMap;
  if Assigned(FAas) then
    FAas.ClearMap;
end;

// the parts of the map that AAS_LoadMap made: the file is the one thing the system and the bots share
procedure TQ3BotLibrary.RefreshMap;
var
  LFile: IAasFile;
  LBoxAreas: IAasBoxAreas;
begin
  if not Assigned(FSystem.Map) then
  begin
    DropMap;
    Exit;
  end;
  LFile := FSystem.Map.AasFile;
  if LFile = FMapFile then
    Exit;
  FMapFile := LFile;
  FHasRouter := False;
  FSampler := TAasFactory.CreateSampler(LFile, FImport, True);
  FTracer := TAasFactory.CreateTracer(LFile, FImport);
  FAreas := TAasFactory.CreateAreaQuery(LFile, FImport);
  LBoxAreas := TAasFactory.CreateBoxAreas(LFile, FImport);
  FMovement := TAasMovement.Create(LFile, FSampler, FTracer, TAasFactory.CreateFaceTester(LFile, FImport), FBsp,
    FImport, TAasMoveSettingsReader.Read(FLibVars));
  FAas.SetMap(FSampler, FTracer, LBoxAreas, FAreas, FMovement);
  FAas.SetRouter(nil);
  FWorld.SetMap(FAreas, FSampler, FTracer, TQ3BotNullRouter.Create, FMovement, FSystem.BestReachable,
    FSystem.BspEntities);
  FWorld.SetTime(FSystem.Time);
end;

// the router the initialization makes, as soon as there is one: the same object for the bots and the exports
procedure TQ3BotLibrary.RefreshRouter;
var
  LRouter: IAasRouter;
  LSteps: IAasInitSteps;
begin
  if FHasRouter or not Assigned(FSystem.Map) or not FSystem.Initialized then
    Exit;
  LSteps := FSystem.Map.Steps;
  if not ((LSteps as TObject) is TAasInitSteps) then
    Exit;
  LRouter := (LSteps as TAasInitSteps).Router;
  if not Assigned(LRouter) then
    Exit;
  FHasRouter := True;
  FAas.SetRouter(LRouter);
  FWorld.SetMap(FAreas, FSampler, FTracer, LRouter, FMovement, FSystem.BestReachable, FSystem.BspEntities);
end;

function TQ3BotLibrary.StartFrame(ATime: Single): Integer;
begin
  if not CheckSetup('BotStartFrame') then
    Exit(Q3BOT_BLERR_LIBRARYNOTSETUP);
  Result := FSystem.StartFrame(ATime);
  FWorld.SetTime(ATime);
  RefreshRouter;
end;

function TQ3BotLibrary.LoadMap(const AMapName: AnsiString): Integer;
begin
  if not CheckSetup('BotLoadMap') then
    Exit(Q3BOT_BLERR_LIBRARYNOTSETUP);
  FImport.Print(PRT_MESSAGE, AnsiString(SMapLoading));
  // startup AAS for the current map, model and sound index
  Result := FSystem.LoadMap(AMapName);
  FMapFile := nil;
  RefreshMap;
  if Result <> BLERR_NOERROR then
    Exit;
  // the items in the level, the types of the brush models
  FAi.Goals.InitLevelItems;
  FAi.Moves.SetBrushModelTypes;
  FImport.Print(PRT_MESSAGE, AnsiString(SMapLoaded));
end;

function TQ3BotLibrary.UpdateEntity(AEntity: Integer; const AState: PBotEntityState): Integer;
begin
  if not CheckSetup('BotUpdateEntity') then
    Exit(Q3BOT_BLERR_LIBRARYNOTSETUP);
  // ValidEntityNumber: the last number of the table is accepted by the C (num > max) and the AAS then writes past it
  if (AEntity < 0) or (AEntity > FMaxEntities) then
  begin
    FImport.Print(PRT_ERROR, AnsiString(Format(SInvalidEntity, ['BotUpdateEntity', AEntity, FMaxEntities])));
    Exit(Q3BOT_BLERR_INVALIDENTITYNUMBER);
  end;
  Result := FSystem.Entities.UpdateEntity(AEntity, AState);
end;

function TQ3BotLibrary.Ai: IBotAi;
begin
  if not Assigned(FAi) then
    raise EQ3HostException.Create(SNoAiYet);
  Result := FAi;
end;

function TQ3BotLibrary.Aas: IQ3BotAas;
begin
  if not Assigned(FAasRef) then
    raise EQ3HostException.Create(SNoAiYet);
  Result := FAasRef;
end;

end.
