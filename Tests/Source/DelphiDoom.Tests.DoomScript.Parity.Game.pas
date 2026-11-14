{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - fake game of the        }
{  parity driver                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Parity.Game;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Random, DelphiDoom.Scanner.IdDict,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.ScriptObject,
  DelphiDoom.DoomScript.Thread, DelphiDoom.DoomScript.Machine, DelphiDoom.Tests.DoomScript.Parity.Output,
  DelphiDoom.Tests.DoomScript.Parity.FileSystem, DelphiDoom.Tests.DoomScript.Parity.Entity;

const
  PARITY_MAX_CLIENTS = 32;
  PARITY_ENTITYNUM_WORLD = DS_MAX_GENTITIES - 2;
  PARITY_SIG_TRIGGER = 2;
  PARITY_SIG_REMOVE = 3;

type
  /// <summary>
  ///   The fake game of the C++ harness (gameLocal and the stubs of Tools\Verifica\110\main.cpp) around
  ///   the script machine of the library: host and world of the machine, fake entities with their events,
  ///   the world events of the threads. Every stub writes the same "HOST ..." line as the C++ one. Not
  ///   reference counted: the scenario owns it.
  /// </summary>
  TDoomScriptParityGame = class(TNoRefCountObject, IDoomScriptHost, IDoomScriptWorld)
  strict private
    FOutput: TDoomScriptParityOutput;
    FMachine: TDoomScriptMachine;
    FRandom: TIdRandom;
    FCVars: TDictionary<string, AnsiString>;
    FEntities: array[0..DS_MAX_GENTITIES - 1] of TDoomScriptParityEntity;
    FPersistentLevelInfo: TIdDict;
    FGlobalShaderParms: array[0..DS_MAX_GLOBAL_SHADER_PARMS - 1] of Single;
    FEntityClass: TDoomScriptClassInfo;
    FMoverClass: TDoomScriptClassInfo;
    FCameraClass: TDoomScriptClassInfo;
    FPlayerClass: TDoomScriptClassInfo;
    FAFEntityClass: TDoomScriptClassInfo;
    FEvGetName, FEvSetName, FEvSetValue, FEvGetValue, FEvSetOrigin, FEvGetOrigin, FEvSetOwner, FEvGetOwner, FEvBind,
    FEvSetKey, FEvGetKey, FEvAddInts, FEvMix, FEvHostPing, FEvMoveTo, FEvMoveDone, FEvIsMoving,
    FEvSlowTurn: TDoomScriptEventDef;
    // the trace of the threads (idThread::trace): zero until the first trace
    FTraceFraction: Single;
    FTraceEndPos: TIdVec3;
    FTraceNormal: TIdVec3;
    FTraceEntityNum: Integer;
    FTraceId: Integer;
    procedure DeclareClasses;
    procedure Head(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: AnsiString = '');
    procedure FillTrace(const AStart, AEnd: TIdVec3);
    procedure Fade(const AColor: TIdVec3; const AAlpha, ATime: Single);
    function CVarInteger(const AName: string): Integer;
    // the events of idEntity
    procedure EntActivate(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntSetShaderParm(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntCacheSoundShader(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntGetName(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntSetName(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntSetValue(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntGetValue(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntSetOrigin(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntGetOrigin(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntSetOwner(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntGetOwner(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntBind(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntSetKey(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntGetKey(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntAddInts(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntMix(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntHostPing(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntSafeRemove(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure EntRemove(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    // the events of idMover
    procedure MoverMoveTo(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure MoverMoveDone(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure MoverIsMoving(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure MoverSetCallback(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure MoverSlowTurn(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    // the world events of idThread (Script_Thread.cpp), on the stubs of the harness
    procedure SysSay(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysTrigger(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysSetCvar(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetCvar(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysClearPersistantArgs(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysSetPersistantArg(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetPersistantString(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetPersistantFloat(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetPersistantVector(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysSetCamera(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysFirstPerson(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysTrace(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysTracePoint(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetTraceFraction(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetTraceEndPos(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetTraceNormal(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetTraceEntity(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetTraceJoint(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysGetTraceBody(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysFadeIn(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysFadeOut(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysFadeTo(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysSetShaderParm(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysStartMusic(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysRadiusDamage(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysIsClient(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysIsMultiplayer(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysCacheSoundShader(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysDebugLine(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysDebugArrow(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysDebugCircle(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysDebugBounds(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysDrawText(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
    procedure SysInfluenceActive(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs);
  public
    // gameLocal
    Time: Integer;
    Msec: Integer;
    RealClientTime: Integer;
    FrameNum: Integer;
    IsClient: Boolean;
    IsMultiplayer: Boolean;
    /// <summary>The entity number of the last idPlayer spawned, -1 = none</summary>
    LocalPlayer: Integer;
    // what the next traces of the fake clip answer (command "settrace")
    ClipFraction: Single;
    ClipEntity: Integer;
    ClipId: Integer;
    constructor Create(const AOutput: TDoomScriptParityOutput; const AFileSystem: TDoomScriptParityFileSystem);
    destructor Destroy; override;
    // IDoomScriptHost
    function GetTime: Integer;
    function GetFrameMsec: Integer;
    function GetRealClientTime: Integer;
    function RandomFloat: Single;
    function RelativePathToOSPath(const APath: AnsiString): AnsiString;
    function OSPathToRelativePath(const APath: AnsiString): AnsiString;
    function DebugScript: Boolean;
    function Developer: Boolean;
    function Disassemble: Boolean;
    procedure DebugPrintf(const AText: string);
    // IDoomScriptWorld
    function FindEntity(const AName: AnsiString): Integer;
    function SpawnEntity(const ASpawnArgs: TIdDict): Integer;
    procedure CopyEntitySpawnArgs(const AEntityNumber: Integer; const ATarget: TIdDict);
    procedure SetSignal(const AEntityNumber, ASignal, AThreadNum: Integer; const AFunctionName: AnsiString);
    procedure ClearSignalThread(const AEntityNumber, ASignal, AThreadNum: Integer);

    /// <summary>The command "setcvar": no HOST line</summary>
    procedure SetCVar(const AName: string; const AValue: AnsiString);
    /// <summary>makeEntity of the harness; nil if the class is unknown or is not an entity class</summary>
    function MakeEntity(const ANumber: Integer; const AClassName, AName: AnsiString;
      const AArgs: TIdDict): TDoomScriptParityEntity;
    /// <summary>The destructor of an entity of the harness ("HOST free")</summary>
    procedure RemoveEntity(const AEntity: TDoomScriptParityEntity);
    function EntityAt(const ANumber: Integer): TDoomScriptParityEntity;
    function ScriptObjectOf(const AEntity: TDoomScriptParityEntity): TDoomScriptObject;
    /// <summary>idEntity::ConstructScriptObject of the harness</summary>
    procedure ConstructScriptObject(const AEntity: TDoomScriptParityEntity);
    /// <summary>idEntity::Signal of the harness</summary>
    procedure Signal(const AEntity: TDoomScriptParityEntity; const ASignal: Integer);
    property Machine: TDoomScriptMachine read FMachine;
    property Output: TDoomScriptParityOutput read FOutput;
  end;

implementation

uses
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.DoomScript.Factory, DelphiDoom.DoomScript.Context,
  DelphiDoom.DoomScript.SysEvents;

type
  TOut = TDoomScriptParityOutput;

function Ent(const ATarget: TObject): TDoomScriptParityEntity; inline;
begin
  Result := TDoomScriptParityEntity(ATarget);
end;

{ TDoomScriptParityGame }

constructor TDoomScriptParityGame.Create(const AOutput: TDoomScriptParityOutput;
  const AFileSystem: TDoomScriptParityFileSystem);
begin
  inherited Create;
  FOutput := AOutput;
  FRandom := TIdRandom.Create(0);
  FCVars := TDictionary<string, AnsiString>.Create;
  FCVars.Add('g_disasm', '0');
  FCVars.Add('g_debugscript', '0');
  FCVars.Add('g_debugtriggers', '0');
  FCVars.Add('developer', '0');
  FPersistentLevelInfo := TIdDict.Create;
  Msec := 16;
  LocalPlayer := -1;
  ClipFraction := 1.0;
  ClipEntity := DS_ENTITYNUM_NONE;
  FMachine := TDoomScriptFactory.CreateMachine(Self, Self, AOutput, AFileSystem);
  DeclareClasses;
end;

destructor TDoomScriptParityGame.Destroy;
var
  LIndex: Integer;
begin
  // the machine first: its threads and its queue refer to the entities
  FMachine.Free;
  for LIndex := 0 to DS_MAX_GENTITIES - 1 do
    FEntities[LIndex].Free;
  FPersistentLevelInfo.Free;
  FCVars.Free;
  inherited;
end;

procedure TDoomScriptParityGame.DeclareClasses;
var
  LSys: TDoomScriptSysEvents;
  LThreads: TDoomScriptClassInfo;
  LContext: TDoomScriptContext;
begin
  LSys := FMachine.SysEvents;
  LContext := FMachine.Context;
  FEvGetName := FMachine.Events.Define('getName', '', 's');
  FEvSetName := FMachine.Events.Define('setName', 's');
  FEvSetValue := FMachine.Events.Define('setValue', 'f');
  FEvGetValue := FMachine.Events.Define('getValue', '', 'f');
  FEvSetOrigin := FMachine.Events.Define('setOrigin', 'v');
  FEvGetOrigin := FMachine.Events.Define('getOrigin', '', 'v');
  FEvSetOwner := FMachine.Events.Define('setOwner', 'E');
  FEvGetOwner := FMachine.Events.Define('getOwner', '', 'e');
  FEvBind := FMachine.Events.Define('bind', 'e');
  FEvSetKey := FMachine.Events.Define('setKey', 'ss');
  FEvGetKey := FMachine.Events.Define('getKey', 's', 's');
  FEvAddInts := FMachine.Events.Define('addInts', 'dd', 'd');
  FEvMix := FMachine.Events.Define('mix', 'fdvsE', 'f');
  FEvHostPing := FMachine.Events.Define('<hostping>', 'd');
  FEvMoveTo := FMachine.Events.Define('moveTo', 'vf');
  FEvMoveDone := FMachine.Events.Define('<movedone>');
  FEvIsMoving := FMachine.Events.Define('isMoving', '', 'f');
  FEvSlowTurn := FMachine.Events.Define('slowTurn', 'f');
  // three events that no class answers
  FMachine.Events.Define('traceArg', 't');
  FMachine.Events.Define('traceRet', '', 't');
  FMachine.Events.Define('spare', 'f');

  FEntityClass := FMachine.Classes.Declare('idEntity', 'idClass');
  FEntityClass.AddEvent(LSys.Activate, EntActivate);
  FEntityClass.AddEvent(LSys.SetShaderParm, EntSetShaderParm);
  FEntityClass.AddEvent(LSys.CacheSoundShader, EntCacheSoundShader);
  FEntityClass.AddEvent(FEvGetName, EntGetName);
  FEntityClass.AddEvent(FEvSetName, EntSetName);
  FEntityClass.AddEvent(FEvSetValue, EntSetValue);
  FEntityClass.AddEvent(FEvGetValue, EntGetValue);
  FEntityClass.AddEvent(FEvSetOrigin, EntSetOrigin);
  FEntityClass.AddEvent(FEvGetOrigin, EntGetOrigin);
  FEntityClass.AddEvent(FEvSetOwner, EntSetOwner);
  FEntityClass.AddEvent(FEvGetOwner, EntGetOwner);
  FEntityClass.AddEvent(FEvBind, EntBind);
  FEntityClass.AddEvent(FEvSetKey, EntSetKey);
  FEntityClass.AddEvent(FEvGetKey, EntGetKey);
  FEntityClass.AddEvent(FEvAddInts, EntAddInts);
  FEntityClass.AddEvent(FEvMix, EntMix);
  FEntityClass.AddEvent(FEvHostPing, EntHostPing);
  // idClass::Event_SafeRemove and idClass::Event_Remove
  FEntityClass.AddEvent(LSys.SafeRemove, EntSafeRemove);
  FEntityClass.AddEvent(LContext.EvRemove, EntRemove);

  FMoverClass := FMachine.Classes.Declare('idMover', 'idEntity');
  FMoverClass.AddEvent(FEvMoveTo, MoverMoveTo);
  FMoverClass.AddEvent(FEvMoveDone, MoverMoveDone);
  FMoverClass.AddEvent(FEvIsMoving, MoverIsMoving);
  FMoverClass.AddEvent(LContext.EvSetCallback, MoverSetCallback);
  FMoverClass.AddEvent(FEvSlowTurn, MoverSlowTurn);
  FCameraClass := FMachine.Classes.Declare('idCamera', 'idEntity');
  FPlayerClass := FMachine.Classes.Declare('idPlayer', 'idEntity');
  FAFEntityClass := FMachine.Classes.Declare('idAFEntity_Base', 'idEntity');

  LThreads := LContext.ThreadClass;
  LThreads.AddEvent(LSys.Say, SysSay);
  LThreads.AddEvent(LSys.Trigger, SysTrigger);
  LThreads.AddEvent(LSys.SetCvar, SysSetCvar);
  LThreads.AddEvent(LSys.GetCvar, SysGetCvar);
  LThreads.AddEvent(LSys.ClearPersistantArgs, SysClearPersistantArgs);
  LThreads.AddEvent(LSys.SetPersistantArg, SysSetPersistantArg);
  LThreads.AddEvent(LSys.GetPersistantString, SysGetPersistantString);
  LThreads.AddEvent(LSys.GetPersistantFloat, SysGetPersistantFloat);
  LThreads.AddEvent(LSys.GetPersistantVector, SysGetPersistantVector);
  LThreads.AddEvent(LSys.SetCamera, SysSetCamera);
  LThreads.AddEvent(LSys.FirstPerson, SysFirstPerson);
  LThreads.AddEvent(LSys.Trace, SysTrace);
  LThreads.AddEvent(LSys.TracePoint, SysTracePoint);
  LThreads.AddEvent(LSys.GetTraceFraction, SysGetTraceFraction);
  LThreads.AddEvent(LSys.GetTraceEndPos, SysGetTraceEndPos);
  LThreads.AddEvent(LSys.GetTraceNormal, SysGetTraceNormal);
  LThreads.AddEvent(LSys.GetTraceEntity, SysGetTraceEntity);
  LThreads.AddEvent(LSys.GetTraceJoint, SysGetTraceJoint);
  LThreads.AddEvent(LSys.GetTraceBody, SysGetTraceBody);
  LThreads.AddEvent(LSys.FadeIn, SysFadeIn);
  LThreads.AddEvent(LSys.FadeOut, SysFadeOut);
  LThreads.AddEvent(LSys.FadeTo, SysFadeTo);
  LThreads.AddEvent(LSys.SetShaderParm, SysSetShaderParm);
  LThreads.AddEvent(LSys.StartMusic, SysStartMusic);
  LThreads.AddEvent(LSys.RadiusDamage, SysRadiusDamage);
  LThreads.AddEvent(LSys.IsClient, SysIsClient);
  LThreads.AddEvent(LSys.IsMultiplayer, SysIsMultiplayer);
  LThreads.AddEvent(LSys.CacheSoundShader, SysCacheSoundShader);
  LThreads.AddEvent(LSys.DebugLine, SysDebugLine);
  LThreads.AddEvent(LSys.DebugArrow, SysDebugArrow);
  LThreads.AddEvent(LSys.DebugCircle, SysDebugCircle);
  LThreads.AddEvent(LSys.DebugBounds, SysDebugBounds);
  LThreads.AddEvent(LSys.DrawText, SysDrawText);
  LThreads.AddEvent(LSys.InfluenceActive, SysInfluenceActive);
end;

{ host }

function TDoomScriptParityGame.GetTime: Integer;
begin
  Result := Time;
end;

function TDoomScriptParityGame.GetFrameMsec: Integer;
begin
  Result := Msec;
end;

function TDoomScriptParityGame.GetRealClientTime: Integer;
begin
  Result := RealClientTime;
end;

function TDoomScriptParityGame.RandomFloat: Single;
begin
  Result := FRandom.RandomFloat;
end;

function TDoomScriptParityGame.RelativePathToOSPath(const APath: AnsiString): AnsiString;
begin
  Result := TDoomScriptParityFileSystem.BASE_PATH + APath;
end;

function TDoomScriptParityGame.OSPathToRelativePath(const APath: AnsiString): AnsiString;
begin
  if TDoomScriptParityFileSystem.IsOsPath(APath) then
    Result := Copy(APath, Length(TDoomScriptParityFileSystem.BASE_PATH) + 1, MaxInt)
  else
    Result := '';
end;

function TDoomScriptParityGame.CVarInteger(const AName: string): Integer;
var
  LValue: AnsiString;
begin
  if FCVars.TryGetValue(LowerCase(AName), LValue) then
    Result := TIdCNumbers.Atoi(LValue)
  else
    Result := 0;
end;

function TDoomScriptParityGame.DebugScript: Boolean;
begin
  Result := CVarInteger('g_debugScript') <> 0;
end;

function TDoomScriptParityGame.Developer: Boolean;
begin
  Result := CVarInteger('developer') <> 0;
end;

function TDoomScriptParityGame.Disassemble: Boolean;
begin
  Result := CVarInteger('g_disasm') <> 0;
end;

procedure TDoomScriptParityGame.DebugPrintf(const AText: string);
begin
  // the DPrintf of the harness always prints
  FOutput.DebugPrintf(AText);
end;

procedure TDoomScriptParityGame.SetCVar(const AName: string; const AValue: AnsiString);
begin
  FCVars.AddOrSetValue(LowerCase(AName), AValue);
end;

{ world }

function TDoomScriptParityGame.EntityAt(const ANumber: Integer): TDoomScriptParityEntity;
begin
  if (ANumber >= 0) and (ANumber < DS_MAX_GENTITIES) then
    Result := FEntities[ANumber]
  else
    Result := nil;
end;

function TDoomScriptParityGame.ScriptObjectOf(const AEntity: TDoomScriptParityEntity): TDoomScriptObject;
begin
  Result := FMachine.Entities.ObjectOf(AEntity.EntityNumber);
end;

function TDoomScriptParityGame.FindEntity(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  FOutput.Line('HOST FindEntity ' + TOut.Quoted(AName));
  for LIndex := 0 to DS_MAX_GENTITIES - 1 do
    if Assigned(FEntities[LIndex]) and SameText(string(FEntities[LIndex].Name), string(AName)) then
      Exit(LIndex);
  Result := -1;
end;

function TDoomScriptParityGame.MakeEntity(const ANumber: Integer; const AClassName, AName: AnsiString;
  const AArgs: TIdDict): TDoomScriptParityEntity;
var
  LClass: TDoomScriptClassInfo;
begin
  LClass := FMachine.Classes.GetClass(AClassName);
  if (not Assigned(LClass)) or not LClass.IsType(FEntityClass) then
    Exit(nil);
  Result := TDoomScriptParityEntity.Create(LClass, ANumber, AName);
  Result.SpawnArgs.Assign(AArgs);
  FEntities[ANumber] := Result;
  FMachine.Entities.Add(ANumber, Result, AName);
  if LClass = FPlayerClass then
    LocalPlayer := ANumber;
  FMachine.ScriptProgram.SetEntity(AName, ANumber);
end;

function TDoomScriptParityGame.SpawnEntity(const ASpawnArgs: TIdDict): Integer;
var
  LText: AnsiString;
  LIndex: Integer;
  LPair: TIdKeyValue;
  LClassName: AnsiString;
  LName: AnsiString;
  LObjectType: AnsiString;
  LEntity: TDoomScriptParityEntity;
begin
  LText := 'HOST SpawnEntityDef';
  for LIndex := 0 to ASpawnArgs.GetNumKeyVals - 1 do
    if ASpawnArgs.TryGetKeyVal(LIndex, LPair) then
      LText := LText + ' ' + TOut.Esc(LPair.Key) + '=' + TOut.Esc(LPair.Value);
  FOutput.Line(LText);
  LClassName := ASpawnArgs.GetString('classname');
  Result := PARITY_MAX_CLIENTS;
  while (Result < PARITY_ENTITYNUM_WORLD) and Assigned(FEntities[Result]) do
    Inc(Result);
  LName := ASpawnArgs.GetString('name', LClassName + '_' + TOut.Num(Result));
  LEntity := MakeEntity(Result, LClassName, LName, ASpawnArgs);
  if not Assigned(LEntity) then
  begin
    FOutput.Line('HOST spawned null');
    Exit(-1);
  end;
  FOutput.Line('HOST spawned ent:' + TOut.Num(Result) + ' class=' + LClassName + ' name=' + TOut.Quoted(LName));
  LObjectType := ASpawnArgs.GetString('scriptobject');
  if (LObjectType <> '') and ScriptObjectOf(LEntity).SetType(LObjectType) then
    ConstructScriptObject(LEntity);
end;

procedure TDoomScriptParityGame.CopyEntitySpawnArgs(const AEntityNumber: Integer; const ATarget: TIdDict);
begin
  // the original crashes on a NULL entity
  if Assigned(EntityAt(AEntityNumber)) then
    ATarget.Copy(FEntities[AEntityNumber].SpawnArgs);
end;

procedure TDoomScriptParityGame.SetSignal(const AEntityNumber, ASignal, AThreadNum: Integer;
  const AFunctionName: AnsiString);
var
  LSignal: TDoomScriptParitySignal;
  LEntity: TDoomScriptParityEntity;
  LIndex: Integer;
begin
  LEntity := FEntities[AEntityNumber];
  LSignal.ThreadNum := AThreadNum;
  LSignal.Func := FMachine.ScriptProgram.FindFunction(AFunctionName);
  FOutput.Line('HOST SetSignal ' + TOut.Num(AEntityNumber) + ' ' + TOut.Num(ASignal) + ' ' + TOut.Num(AThreadNum) +
    ' ' + TOut.Num(FMachine.ScriptProgram.GetFunctionIndex(LSignal.Func)));
  for LIndex := 0 to LEntity.Signals[ASignal].Count - 1 do
    if (LEntity.Signals[ASignal][LIndex].ThreadNum = AThreadNum) and
      (LEntity.Signals[ASignal][LIndex].Func = LSignal.Func) then
      Exit;
  LEntity.Signals[ASignal].Add(LSignal);
end;

procedure TDoomScriptParityGame.ClearSignalThread(const AEntityNumber, ASignal, AThreadNum: Integer);
var
  LEntity: TDoomScriptParityEntity;
  LIndex: Integer;
begin
  LEntity := FEntities[AEntityNumber];
  FOutput.Line('HOST ClearSignalThread ' + TOut.Num(AEntityNumber) + ' ' + TOut.Num(ASignal) + ' ' +
    TOut.Num(AThreadNum));
  for LIndex := LEntity.Signals[ASignal].Count - 1 downto 0 do
    if LEntity.Signals[ASignal][LIndex].ThreadNum = AThreadNum then
      LEntity.Signals[ASignal].Delete(LIndex);
end;

procedure TDoomScriptParityGame.Signal(const AEntity: TDoomScriptParityEntity; const ASignal: Integer);
var
  LSignals: TArray<TDoomScriptParitySignal>;
  LIndex: Integer;
  LThread: TDoomScriptThread;
begin
  FOutput.Line('HOST Signal ' + TOut.Num(AEntity.EntityNumber) + ' ' + TOut.Num(ASignal));
  LSignals := AEntity.Signals[ASignal].ToArray;
  AEntity.Signals[ASignal].Clear;
  for LIndex := 0 to Length(LSignals) - 1 do
  begin
    LThread := FMachine.GetThread(LSignals[LIndex].ThreadNum);
    if Assigned(LThread) then
    begin
      LThread.CallFunction(LSignals[LIndex].Func, True);
      LThread.Execute;
    end;
  end;
end;

procedure TDoomScriptParityGame.ConstructScriptObject(const AEntity: TDoomScriptParityEntity);
var
  LObject: TDoomScriptObject;
  LConstructor: TDoomScriptFunction;
  LThread: TDoomScriptThread;
begin
  LObject := ScriptObjectOf(AEntity);
  LObject.ClearObject;
  LConstructor := LObject.GetConstructor;
  if Assigned(LConstructor) then
  begin
    LThread := FMachine.CreateThread;
    LThread.SetThreadName(AEntity.Name);
    LThread.CallFunction(AEntity.EntityNumber, LConstructor, True);
    LThread.DelayedStart(0);
  end;
  LObject.ClearObject;
end;

procedure TDoomScriptParityGame.RemoveEntity(const AEntity: TDoomScriptParityEntity);
var
  LObject: TDoomScriptObject;
  LDestructor: TDoomScriptFunction;
  LThread: TDoomScriptThread;
  LNumber: Integer;
begin
  LNumber := AEntity.EntityNumber;
  FOutput.Line('HOST free ' + TOut.Num(LNumber));
  try
    // idEntity::DeconstructScriptObject of the harness
    LObject := ScriptObjectOf(AEntity);
    LDestructor := LObject.GetDestructor;
    if Assigned(LDestructor) then
    begin
      LThread := FMachine.CreateThread;
      try
        LThread.SetThreadName(AEntity.Name);
        LThread.CallFunction(LNumber, LDestructor, True);
        LThread.Execute;
      finally
        LThread.Free;
      end;
    end;
    LObject.FreeObject;
    Signal(AEntity, PARITY_SIG_REMOVE);
  finally
    if LocalPlayer = LNumber then
      LocalPlayer := -1;
    if FEntities[LNumber] = AEntity then
    begin
      FEntities[LNumber] := nil;
      FMachine.ScriptProgram.SetEntity(AEntity.Name, -1);
    end;
    // idClass::~idClass
    FMachine.Queue.CancelEvents(AEntity);
    FMachine.Entities.Remove(LNumber);
    AEntity.Free;
  end;
end;

{ entity events }

procedure TDoomScriptParityGame.Head(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: AnsiString);
var
  LText: AnsiString;
begin
  LText := 'HOST event ' + TOut.Num(Ent(ATarget).EntityNumber) + ' ' + AEvent.Name;
  if AArgs <> '' then
    LText := LText + ' ' + AArgs;
  FOutput.Line(LText);
end;

procedure TDoomScriptParityGame.EntActivate(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LName: AnsiString;
begin
  // idClass::ProcessEventArgPtr with g_debugTriggers
  if CVarInteger('g_debugTriggers') <> 0 then
  begin
    if Assigned(EntityAt(AArgs[0].IntValue)) then
      LName := FEntities[AArgs[0].IntValue].Name
    else
      LName := 'NULL';
    FOutput.Printf(Format('%d: ''%s'' activated by ''%s'''#10, [FrameNum, string(Ent(ATarget).Name), string(LName)]));
  end;
  Head(ATarget, AEvent, TOut.EntityRef(AArgs[0].IntValue));
end;

procedure TDoomScriptParityGame.EntSetShaderParm(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.Num(AArgs[0].IntValue) + ' ' + TOut.FloatBits(AArgs[1].FloatValue));
end;

procedure TDoomScriptParityGame.EntCacheSoundShader(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.Quoted(AArgs[0].StringValue));
end;

procedure TDoomScriptParityGame.EntGetName(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent);
  FMachine.ScriptProgram.ReturnString(Ent(ATarget).Name);
end;

procedure TDoomScriptParityGame.EntSetName(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  LEntity := Ent(ATarget);
  Head(ATarget, AEvent, TOut.Quoted(AArgs[0].StringValue));
  FMachine.ScriptProgram.SetEntity(LEntity.Name, -1);
  LEntity.Name := AArgs[0].StringValue;
  FMachine.Entities.Rename(LEntity.EntityNumber, LEntity.Name);
  FMachine.ScriptProgram.SetEntity(LEntity.Name, LEntity.EntityNumber);
end;

procedure TDoomScriptParityGame.EntSetValue(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.FloatBits(AArgs[0].FloatValue));
  Ent(ATarget).Value := AArgs[0].FloatValue;
end;

procedure TDoomScriptParityGame.EntGetValue(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent);
  FMachine.ScriptProgram.ReturnFloat(Ent(ATarget).Value);
end;

procedure TDoomScriptParityGame.EntSetOrigin(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.Vec3(AArgs[0].VectorValue));
  Ent(ATarget).Origin := AArgs[0].VectorValue;
end;

procedure TDoomScriptParityGame.EntGetOrigin(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent);
  FMachine.ScriptProgram.ReturnVector(Ent(ATarget).Origin);
end;

procedure TDoomScriptParityGame.EntSetOwner(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.EntityRef(AArgs[0].IntValue));
  if AArgs[0].IntValue >= 0 then
    Ent(ATarget).Owner := AArgs[0].IntValue + 1
  else
    Ent(ATarget).Owner := 0;
end;

procedure TDoomScriptParityGame.EntGetOwner(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LOwner: Integer;
begin
  Head(ATarget, AEvent);
  LOwner := Ent(ATarget).Owner - 1;
  if not Assigned(EntityAt(LOwner)) then
    LOwner := -1;
  FMachine.ScriptProgram.ReturnEntity(LOwner);
end;

procedure TDoomScriptParityGame.EntBind(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.EntityRef(AArgs[0].IntValue));
end;

procedure TDoomScriptParityGame.EntSetKey(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.Quoted(AArgs[0].StringValue) + ' ' + TOut.Quoted(AArgs[1].StringValue));
  Ent(ATarget).SpawnArgs.SetValue(AArgs[0].StringValue, AArgs[1].StringValue);
end;

procedure TDoomScriptParityGame.EntGetKey(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.Quoted(AArgs[0].StringValue));
  FMachine.ScriptProgram.ReturnString(Ent(ATarget).SpawnArgs.GetString(AArgs[0].StringValue, ''));
end;

procedure TDoomScriptParityGame.EntAddInts(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent, TOut.Num(AArgs[0].IntValue) + ' ' + TOut.Num(AArgs[1].IntValue));
  FMachine.ScriptProgram.ReturnFloat(AArgs[0].IntValue + AArgs[1].IntValue);
end;

procedure TDoomScriptParityGame.EntMix(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LResult: Single;
begin
  Head(ATarget, AEvent, TOut.FloatBits(AArgs[0].FloatValue) + ' ' + TOut.Num(AArgs[1].IntValue) + ' ' +
    TOut.Vec3(AArgs[2].VectorValue) + ' ' + TOut.Quoted(AArgs[3].StringValue) + ' ' +
    TOut.EntityRef(AArgs[4].IntValue));
  LResult := AArgs[0].FloatValue + AArgs[1].IntValue;
  FMachine.ScriptProgram.ReturnFloat(LResult);
end;

procedure TDoomScriptParityGame.EntHostPing(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  if AArgs[0].IntValue < 0 then
  begin
    FMachine.Queue.PostEventMS(Ent(ATarget), FEvHostPing, 0, [TDoomScriptConvert.IntArg(AArgs[0].IntValue)]);
    Exit;
  end;
  Head(ATarget, AEvent, TOut.Num(AArgs[0].IntValue));
end;

procedure TDoomScriptParityGame.EntSafeRemove(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FMachine.Queue.PostEventMS(Ent(ATarget), FMachine.Context.EvRemove, 0);
end;

procedure TDoomScriptParityGame.EntRemove(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  RemoveEntity(Ent(ATarget));
end;

{ mover events }

procedure TDoomScriptParityGame.MoverMoveTo(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  LEntity := Ent(ATarget);
  Head(ATarget, AEvent, TOut.Vec3(AArgs[0].VectorValue) + ' ' + TOut.FloatBits(AArgs[1].FloatValue));
  LEntity.Dest := AArgs[0].VectorValue;
  LEntity.Moving := True;
  LEntity.MoveThread := 0;
  FMachine.Queue.PostEventSec(LEntity, FEvMoveDone, AArgs[1].FloatValue, []);
end;

procedure TDoomScriptParityGame.MoverMoveDone(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  LEntity := Ent(ATarget);
  Head(ATarget, AEvent);
  LEntity.Moving := False;
  LEntity.Origin := LEntity.Dest;
  if LEntity.MoveThread <> 0 then
  begin
    TDoomScriptThread.ObjectMoveDone(FMachine.Context, LEntity.MoveThread, LEntity.EntityNumber);
    LEntity.MoveThread := 0;
  end;
end;

procedure TDoomScriptParityGame.MoverIsMoving(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Head(ATarget, AEvent);
  if Ent(ATarget).Moving then
    FMachine.ScriptProgram.ReturnFloat(1.0)
  else
    FMachine.ScriptProgram.ReturnFloat(0.0);
end;

procedure TDoomScriptParityGame.MoverSetCallback(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  LEntity := Ent(ATarget);
  Head(ATarget, AEvent);
  if LEntity.Moving and (LEntity.MoveThread = 0) then
  begin
    LEntity.MoveThread := TDoomScriptThread.CurrentThreadNum(FMachine.Context);
    FMachine.ScriptProgram.ReturnFloat(1.0);
  end
  else
    FMachine.ScriptProgram.ReturnFloat(0.0);
end;

procedure TDoomScriptParityGame.MoverSlowTurn(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  LEntity := Ent(ATarget);
  Head(ATarget, AEvent, TOut.FloatBits(AArgs[0].FloatValue));
  if TDoomScriptThread.BeginMultiFrameEvent(FMachine.Context, LEntity, FEvSlowTurn) then
  begin
    LEntity.TurnLeft := TDoomScriptConvert.FloatToInt(AArgs[0].FloatValue);
    FOutput.Line('HOST slowTurn begin ' + TOut.Num(LEntity.TurnLeft));
  end;
  Dec(LEntity.TurnLeft);
  FOutput.Line('HOST slowTurn tick ' + TOut.Num(LEntity.TurnLeft));
  if LEntity.TurnLeft <= 0 then
  begin
    TDoomScriptThread.EndMultiFrameEvent(FMachine.Context, LEntity, FEvSlowTurn);
    FOutput.Line('HOST slowTurn end');
  end;
end;

{ world events of the threads }

procedure TDoomScriptParityGame.SysSay(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST BufferCommandText ' + TOut.Quoted('say "' + AArgs[0].StringValue + '"'));
end;

procedure TDoomScriptParityGame.SysTrigger(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
  LArgs: TDoomScriptEventArgs;
begin
  LEntity := EntityAt(AArgs[0].IntValue);
  if not Assigned(LEntity) then
    Exit;
  Signal(LEntity, PARITY_SIG_TRIGGER);
  LArgs := Default(TDoomScriptEventArgs);
  LArgs[0] := TDoomScriptConvert.EntityArg(LocalPlayer);
  LEntity.ProcessEvent(FMachine.SysEvents.Activate, LArgs);
  FOutput.Line('HOST TriggerGuis ' + TOut.Num(LEntity.EntityNumber));
end;

procedure TDoomScriptParityGame.SysSetCvar(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST SetCVarString ' + TOut.Quoted(AArgs[0].StringValue) + ' ' + TOut.Quoted(AArgs[1].StringValue));
  SetCVar(string(AArgs[0].StringValue), AArgs[1].StringValue);
end;

procedure TDoomScriptParityGame.SysGetCvar(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LValue: AnsiString;
begin
  FOutput.Line('HOST GetCVarString ' + TOut.Quoted(AArgs[0].StringValue));
  if not FCVars.TryGetValue(LowerCase(string(AArgs[0].StringValue)), LValue) then
    LValue := '';
  FMachine.ScriptProgram.ReturnString(LValue);
end;

procedure TDoomScriptParityGame.SysClearPersistantArgs(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FPersistentLevelInfo.Clear;
end;

procedure TDoomScriptParityGame.SysSetPersistantArg(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FPersistentLevelInfo.SetValue(AArgs[0].StringValue, AArgs[1].StringValue);
end;

procedure TDoomScriptParityGame.SysGetPersistantString(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LResult: AnsiString;
begin
  FPersistentLevelInfo.GetString(AArgs[0].StringValue, '', LResult);
  FMachine.ScriptProgram.ReturnString(LResult);
end;

procedure TDoomScriptParityGame.SysGetPersistantFloat(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LResult: Single;
begin
  FPersistentLevelInfo.GetFloat(AArgs[0].StringValue, '0', LResult);
  FMachine.ScriptProgram.ReturnFloat(LResult);
end;

procedure TDoomScriptParityGame.SysGetPersistantVector(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LResult: TIdVec3;
begin
  FPersistentLevelInfo.GetVector(AArgs[0].StringValue, '0 0 0', LResult);
  FMachine.ScriptProgram.ReturnVector(LResult);
end;

procedure TDoomScriptParityGame.SysSetCamera(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  LEntity := EntityAt(AArgs[0].IntValue);
  if not Assigned(LEntity) then
    TDoomScriptThread(ATarget).Error('Entity not found');
  if not LEntity.EventClass.IsType(FCameraClass) then
    TDoomScriptThread(ATarget).Error('Entity is not a camera');
  FOutput.Line('HOST SetCamera ' + TOut.EntityRef(LEntity.EntityNumber));
end;

procedure TDoomScriptParityGame.SysFirstPerson(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST SetCamera null');
end;

procedure TDoomScriptParityGame.FillTrace(const AStart, AEnd: TIdVec3);
var
  LDelta: TIdVec3;
begin
  FTraceFraction := ClipFraction;
  LDelta := AEnd - AStart;
  LDelta := LDelta * ClipFraction;
  FTraceEndPos := AStart + LDelta;
  FTraceNormal := TIdVec3.Create(0, 0, 1);
  FTraceEntityNum := ClipEntity;
  FTraceId := ClipId;
end;

procedure TDoomScriptParityGame.SysTrace(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LZero: TIdVec3;
begin
  LZero := TIdVec3.Create(0, 0, 0);
  if (AArgs[2].VectorValue = LZero) and (AArgs[3].VectorValue = LZero) then
    FOutput.Line('HOST TracePoint ' + TOut.Vec3(AArgs[0].VectorValue) + ' ' + TOut.Vec3(AArgs[1].VectorValue) + ' ' +
      TOut.Num(AArgs[4].IntValue) + ' ' + TOut.EntityRef(AArgs[5].IntValue))
  else
    FOutput.Line('HOST TraceBounds ' + TOut.Vec3(AArgs[0].VectorValue) + ' ' + TOut.Vec3(AArgs[1].VectorValue) + ' ' +
      TOut.Vec3(AArgs[2].VectorValue) + ' ' + TOut.Vec3(AArgs[3].VectorValue) + ' ' + TOut.Num(AArgs[4].IntValue) +
      ' ' + TOut.EntityRef(AArgs[5].IntValue));
  FillTrace(AArgs[0].VectorValue, AArgs[1].VectorValue);
  FMachine.ScriptProgram.ReturnFloat(FTraceFraction);
end;

procedure TDoomScriptParityGame.SysTracePoint(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST TracePoint ' + TOut.Vec3(AArgs[0].VectorValue) + ' ' + TOut.Vec3(AArgs[1].VectorValue) + ' ' +
    TOut.Num(AArgs[2].IntValue) + ' ' + TOut.EntityRef(AArgs[3].IntValue));
  FillTrace(AArgs[0].VectorValue, AArgs[1].VectorValue);
  FMachine.ScriptProgram.ReturnFloat(FTraceFraction);
end;

procedure TDoomScriptParityGame.SysGetTraceFraction(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FMachine.ScriptProgram.ReturnFloat(FTraceFraction);
end;

procedure TDoomScriptParityGame.SysGetTraceEndPos(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FMachine.ScriptProgram.ReturnVector(FTraceEndPos);
end;

procedure TDoomScriptParityGame.SysGetTraceNormal(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  if FTraceFraction < 1.0 then
    FMachine.ScriptProgram.ReturnVector(FTraceNormal)
  else
    FMachine.ScriptProgram.ReturnVector(TIdVec3.Create(0, 0, 0));
end;

procedure TDoomScriptParityGame.SysGetTraceEntity(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  if (FTraceFraction < 1.0) and Assigned(EntityAt(FTraceEntityNum)) then
    FMachine.ScriptProgram.ReturnEntity(FTraceEntityNum)
  else
    FMachine.ScriptProgram.ReturnEntity(-1);
end;

procedure TDoomScriptParityGame.SysGetTraceJoint(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  if (FTraceFraction < 1.0) and (FTraceId < 0) then
  begin
    LEntity := EntityAt(FTraceEntityNum);
    if Assigned(LEntity) and LEntity.EventClass.IsType(FAFEntityClass) then
    begin
      // CLIPMODEL_ID_TO_JOINT_HANDLE
      FMachine.ScriptProgram.ReturnString('joint' + TOut.Num(-1 - FTraceId));
      Exit;
    end;
  end;
  FMachine.ScriptProgram.ReturnString('');
end;

procedure TDoomScriptParityGame.SysGetTraceBody(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
var
  LEntity: TDoomScriptParityEntity;
begin
  if (FTraceFraction < 1.0) and (FTraceId < 0) then
  begin
    LEntity := EntityAt(FTraceEntityNum);
    if Assigned(LEntity) and LEntity.EventClass.IsType(FAFEntityClass) then
    begin
      FMachine.ScriptProgram.ReturnString('body' + TOut.Num(FTraceId));
      Exit;
    end;
  end;
  FMachine.ScriptProgram.ReturnString('');
end;

procedure TDoomScriptParityGame.Fade(const AColor: TIdVec3; const AAlpha, ATime: Single);
begin
  if LocalPlayer >= 0 then
    FOutput.Line('HOST Fade ' + TOut.Vec4(AColor, AAlpha) + ' ' + TOut.Num(TDoomScriptConvert.SecToMs(ATime)));
end;

procedure TDoomScriptParityGame.SysFadeIn(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Fade(AArgs[0].VectorValue, 0.0, AArgs[1].FloatValue);
end;

procedure TDoomScriptParityGame.SysFadeOut(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Fade(AArgs[0].VectorValue, 1.0, AArgs[1].FloatValue);
end;

procedure TDoomScriptParityGame.SysFadeTo(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  Fade(AArgs[0].VectorValue, AArgs[1].FloatValue, AArgs[2].FloatValue);
end;

procedure TDoomScriptParityGame.SysSetShaderParm(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  if (AArgs[0].IntValue < 0) or (AArgs[0].IntValue >= DS_MAX_GLOBAL_SHADER_PARMS) then
    TDoomScriptThread(ATarget).Error(Format('shader parm index (%d) out of range', [AArgs[0].IntValue]));
  FGlobalShaderParms[AArgs[0].IntValue] := AArgs[1].FloatValue;
end;

procedure TDoomScriptParityGame.SysStartMusic(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST PlayShaderDirectly ' + TOut.Quoted(AArgs[0].StringValue));
end;

procedure TDoomScriptParityGame.SysRadiusDamage(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST RadiusDamage ' + TOut.Vec3(AArgs[0].VectorValue) + ' ' + TOut.EntityRef(AArgs[1].IntValue) + ' ' +
    TOut.EntityRef(AArgs[2].IntValue) + ' ' + TOut.EntityRef(AArgs[3].IntValue) + ' ' +
    TOut.EntityRef(AArgs[3].IntValue) + ' ' + TOut.Quoted(AArgs[4].StringValue) + ' ' +
    TOut.FloatBits(AArgs[5].FloatValue));
end;

procedure TDoomScriptParityGame.SysIsClient(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FMachine.ScriptProgram.ReturnFloat(Ord(IsClient));
end;

procedure TDoomScriptParityGame.SysIsMultiplayer(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FMachine.ScriptProgram.ReturnFloat(Ord(IsMultiplayer));
end;

procedure TDoomScriptParityGame.SysCacheSoundShader(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST FindSound ' + TOut.Quoted(AArgs[0].StringValue));
end;

procedure TDoomScriptParityGame.SysDebugLine(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST DebugLine ' + TOut.Vec4(AArgs[0].VectorValue, 0.0) + ' ' + TOut.Vec3(AArgs[1].VectorValue) + ' ' +
    TOut.Vec3(AArgs[2].VectorValue) + ' ' + TOut.Num(TDoomScriptConvert.SecToMs(AArgs[3].FloatValue)));
end;

procedure TDoomScriptParityGame.SysDebugArrow(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST DebugArrow ' + TOut.Vec4(AArgs[0].VectorValue, 0.0) + ' ' + TOut.Vec3(AArgs[1].VectorValue) +
    ' ' + TOut.Vec3(AArgs[2].VectorValue) + ' ' + TOut.Num(AArgs[3].IntValue) + ' ' +
    TOut.Num(TDoomScriptConvert.SecToMs(AArgs[4].FloatValue)));
end;

procedure TDoomScriptParityGame.SysDebugCircle(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST DebugCircle ' + TOut.Vec4(AArgs[0].VectorValue, 0.0) + ' ' + TOut.Vec3(AArgs[1].VectorValue) +
    ' ' + TOut.Vec3(AArgs[2].VectorValue) + ' ' + TOut.FloatBits(AArgs[3].FloatValue) + ' ' +
    TOut.Num(AArgs[4].IntValue) + ' ' + TOut.Num(TDoomScriptConvert.SecToMs(AArgs[5].FloatValue)));
end;

procedure TDoomScriptParityGame.SysDebugBounds(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  FOutput.Line('HOST DebugBounds ' + TOut.Vec4(AArgs[0].VectorValue, 0.0) + ' ' + TOut.Vec3(AArgs[1].VectorValue) +
    ' ' + TOut.Vec3(AArgs[2].VectorValue) + ' ' + TOut.Vec3(TIdVec3.Create(0, 0, 0)) + ' ' +
    TOut.Num(TDoomScriptConvert.SecToMs(AArgs[3].FloatValue)));
end;

procedure TDoomScriptParityGame.SysDrawText(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  // the original reads the view angles of the local player: without a player it crashes
  FOutput.Line('HOST DrawText ' + TOut.Quoted(AArgs[0].StringValue) + ' ' + TOut.Vec3(AArgs[1].VectorValue) + ' ' +
    TOut.FloatBits(AArgs[2].FloatValue) + ' ' + TOut.Vec4(AArgs[3].VectorValue, 0.0) + ' ' +
    TOut.Num(AArgs[4].IntValue) + ' ' + TOut.Num(TDoomScriptConvert.SecToMs(AArgs[5].FloatValue)));
end;

procedure TDoomScriptParityGame.SysInfluenceActive(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs);
begin
  if (LocalPlayer >= 0) and (FEntities[LocalPlayer].InfluenceLevel <> 0) then
    FMachine.ScriptProgram.ReturnFloat(1.0)
  else
    FMachine.ScriptProgram.ReturnFloat(0.0);
end;

end.
