{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptSysEvents, the events of   }
{  the "sys" object                                                            }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Thread.cpp (the event definitions and the Event_* of idThread).      }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.SysEvents;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.ClassInfo,
  DelphiDoom.DoomScript.Context, DelphiDoom.DoomScript.Thread;

type
  /// <summary>
  ///   The events a script calls on <c>sys</c> (the events of idThread). All the definitions of the
  ///   original are created here, with the same names, formats and return types. The events that only
  ///   need the language, the threads, mathematics, strings and time are implemented by the library; the
  ///   others touch the game world and have no handler until the host adds one to the class of the
  ///   threads (<c>Context.ThreadClass.AddEvent</c>). A script that calls a
  ///   <c>sys</c> event without a handler does not compile ("is not callable as a 'sys' function").
  /// </summary>
  TDoomScriptSysEvents = class
  strict private
    FContext: TDoomScriptContext;
    procedure Add(const AEvent: TDoomScriptEventDef; const AHandler: TDoomScriptEventHandler);
    procedure RegisterThreadEvents;
    procedure RegisterMathEvents;
    procedure RegisterStringEvents;
    procedure RegisterWorldBoundEvents;
  public
    // script callable events, in the order of Script_Thread.cpp
    TerminateThread, Pause, Wait, WaitFrame, WaitFor, WaitForThread, Print, PrintLn, Say, AssertEvent, Trigger,
    SetCvar, GetCvar, Random, GetTime, KillThread, SetThreadName, GetEntity, Spawn, CopySpawnArgs, SetSpawnArg,
    SpawnString, SpawnFloat, SpawnVector, ClearPersistantArgs, SetPersistantArg, GetPersistantString,
    GetPersistantFloat, GetPersistantVector, AngToForward, AngToRight, AngToUp, Sine, Cosine, SquareRoot, Normalize,
    VecLength, VecDotProduct, VecCrossProduct, VecToAngles, OnSignal, ClearSignal, SetCamera, FirstPerson, Trace,
    TracePoint, GetTraceFraction, GetTraceEndPos, GetTraceNormal, GetTraceEntity, GetTraceJoint, GetTraceBody,
    FadeIn, FadeOut, FadeTo, StartMusic, ErrorEvent, WarningEvent, StrLen, StrLeft, StrRight, StrSkip, StrMid,
    StrToFloat, RadiusDamage, IsClient, IsMultiplayer, GetFrameTime, GetTicsPerSecond, DebugLine, DebugArrow,
    DebugCircle, DebugBounds, DrawText, InfluenceActive,
    // defined by idEntity and idClass in the original and used by idThread
    SetShaderParm, CacheSoundShader, SafeRemove, Activate: TDoomScriptEventDef;
    /// <summary>
    ///   Defines the events in the registry of the context, sets the three events the threads use
    ///   (execute, remove, set callback) in the context and adds the handlers of the library to the class
    ///   of the threads
    /// </summary>
    constructor Create(const AContext: TDoomScriptContext);
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.DoomScript.EventRegistry,
  DelphiDoom.DoomScript.EventTarget, DelphiDoom.DoomScript.Defs;

const
  SSignalRange = 'Signal out of range';
  SEntityNotFound = 'Entity not found';
  SFunctionNotFound = 'Function ''%s'' not found';
  SEntityNumberRange = 'Entity number in string out of range.';
  SThreadNotRunning = 'Thread %d not running';

constructor TDoomScriptSysEvents.Create(const AContext: TDoomScriptContext);
var
  LEvents: TDoomScriptEventRegistry;
begin
  inherited Create;
  FContext := AContext;
  LEvents := AContext.Events;
  AContext.EvExecute := LEvents.Define('<execute>');
  AContext.EvSetCallback := LEvents.Define('<script_setcallback>');
  TerminateThread := LEvents.Define('terminate', 'd');
  Pause := LEvents.Define('pause');
  Wait := LEvents.Define('wait', 'f');
  WaitFrame := LEvents.Define('waitFrame');
  WaitFor := LEvents.Define('waitFor', 'e');
  WaitForThread := LEvents.Define('waitForThread', 'd');
  Print := LEvents.Define('print', 's');
  PrintLn := LEvents.Define('println', 's');
  Say := LEvents.Define('say', 's');
  AssertEvent := LEvents.Define('assert', 'f');
  Trigger := LEvents.Define('trigger', 'e');
  SetCvar := LEvents.Define('setcvar', 'ss');
  GetCvar := LEvents.Define('getcvar', 's', 's');
  Random := LEvents.Define('random', 'f', 'f');
  GetTime := LEvents.Define('getTime', '', 'f');
  KillThread := LEvents.Define('killthread', 's');
  SetThreadName := LEvents.Define('threadname', 's');
  GetEntity := LEvents.Define('getEntity', 's', 'e');
  Spawn := LEvents.Define('spawn', 's', 'e');
  CopySpawnArgs := LEvents.Define('copySpawnArgs', 'e');
  SetSpawnArg := LEvents.Define('setSpawnArg', 'ss');
  SpawnString := LEvents.Define('SpawnString', 'ss', 's');
  SpawnFloat := LEvents.Define('SpawnFloat', 'sf', 'f');
  SpawnVector := LEvents.Define('SpawnVector', 'sv', 'v');
  ClearPersistantArgs := LEvents.Define('clearPersistantArgs');
  SetPersistantArg := LEvents.Define('setPersistantArg', 'ss');
  GetPersistantString := LEvents.Define('getPersistantString', 's', 's');
  GetPersistantFloat := LEvents.Define('getPersistantFloat', 's', 'f');
  GetPersistantVector := LEvents.Define('getPersistantVector', 's', 'v');
  AngToForward := LEvents.Define('angToForward', 'v', 'v');
  AngToRight := LEvents.Define('angToRight', 'v', 'v');
  AngToUp := LEvents.Define('angToUp', 'v', 'v');
  Sine := LEvents.Define('sin', 'f', 'f');
  Cosine := LEvents.Define('cos', 'f', 'f');
  SquareRoot := LEvents.Define('sqrt', 'f', 'f');
  Normalize := LEvents.Define('vecNormalize', 'v', 'v');
  VecLength := LEvents.Define('vecLength', 'v', 'f');
  VecDotProduct := LEvents.Define('DotProduct', 'vv', 'f');
  VecCrossProduct := LEvents.Define('CrossProduct', 'vv', 'v');
  VecToAngles := LEvents.Define('VecToAngles', 'v', 'v');
  OnSignal := LEvents.Define('onSignal', 'des');
  ClearSignal := LEvents.Define('clearSignalThread', 'de');
  SetCamera := LEvents.Define('setCamera', 'e');
  FirstPerson := LEvents.Define('firstPerson');
  Trace := LEvents.Define('trace', 'vvvvde', 'f');
  TracePoint := LEvents.Define('tracePoint', 'vvde', 'f');
  GetTraceFraction := LEvents.Define('getTraceFraction', '', 'f');
  GetTraceEndPos := LEvents.Define('getTraceEndPos', '', 'v');
  GetTraceNormal := LEvents.Define('getTraceNormal', '', 'v');
  GetTraceEntity := LEvents.Define('getTraceEntity', '', 'e');
  GetTraceJoint := LEvents.Define('getTraceJoint', '', 's');
  GetTraceBody := LEvents.Define('getTraceBody', '', 's');
  FadeIn := LEvents.Define('fadeIn', 'vf');
  FadeOut := LEvents.Define('fadeOut', 'vf');
  FadeTo := LEvents.Define('fadeTo', 'vff');
  StartMusic := LEvents.Define('music', 's');
  ErrorEvent := LEvents.Define('error', 's');
  WarningEvent := LEvents.Define('warning', 's');
  StrLen := LEvents.Define('strLength', 's', 'd');
  StrLeft := LEvents.Define('strLeft', 'sd', 's');
  StrRight := LEvents.Define('strRight', 'sd', 's');
  StrSkip := LEvents.Define('strSkip', 'sd', 's');
  StrMid := LEvents.Define('strMid', 'sdd', 's');
  StrToFloat := LEvents.Define('strToFloat', 's', 'f');
  RadiusDamage := LEvents.Define('radiusDamage', 'vEEEsf');
  IsClient := LEvents.Define('isClient', '', 'f');
  IsMultiplayer := LEvents.Define('isMultiplayer', '', 'f');
  GetFrameTime := LEvents.Define('getFrameTime', '', 'f');
  GetTicsPerSecond := LEvents.Define('getTicsPerSecond', '', 'f');
  DebugLine := LEvents.Define('debugLine', 'vvvf');
  DebugArrow := LEvents.Define('debugArrow', 'vvvdf');
  DebugCircle := LEvents.Define('debugCircle', 'vvvfdf');
  DebugBounds := LEvents.Define('debugBounds', 'vvvf');
  DrawText := LEvents.Define('drawText', 'svfvdf');
  InfluenceActive := LEvents.Define('influenceActive', '', 'd');
  SetShaderParm := LEvents.Define('setShaderParm', 'df');
  CacheSoundShader := LEvents.Define('cacheSoundShader', 's');
  AContext.EvRemove := LEvents.Define('<immediateremove>');
  SafeRemove := LEvents.Define('remove');
  Activate := LEvents.Define('activate', 'e');
  RegisterThreadEvents;
  RegisterMathEvents;
  RegisterStringEvents;
  RegisterWorldBoundEvents;
end;

procedure TDoomScriptSysEvents.Add(const AEvent: TDoomScriptEventDef; const AHandler: TDoomScriptEventHandler);
begin
  FContext.ThreadClass.AddEvent(AEvent, AHandler);
end;

procedure TDoomScriptSysEvents.RegisterThreadEvents;
var
  LContext: TDoomScriptContext;
begin
  LContext := FContext;
  Add(LContext.EvExecute,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).Execute;
    end);
  // idClass::Event_Remove: delete this
  Add(LContext.EvRemove,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      ATarget.Free;
    end);
  // idClass::Event_SafeRemove: forces the remove to be done at a safe time
  Add(SafeRemove,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LContext.Queue.PostEventMS(TDoomScriptThread(ATarget), LContext.EvRemove, 0);
    end);
  Add(TerminateThread,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread.KillThread(LContext, AArgs[0].IntValue);
    end);
  Add(Pause,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).Pause;
    end);
  Add(Wait,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).WaitSec(AArgs[0].FloatValue);
    end);
  Add(WaitFrame,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).WaitFrame;
    end);
  Add(WaitFor,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LEntity: TDoomScriptEventTarget;
    begin
      LEntity := LContext.Entities.TargetOf(AArgs[0].IntValue);
      if Assigned(LEntity) and LEntity.RespondsTo(LContext.EvSetCallback) then
      begin
        LEntity.ProcessEvent(LContext.EvSetCallback);
        if LContext.ScriptProgram.GetReturnedInteger <> 0 then
          TDoomScriptThread(ATarget).WaitForEntity(AArgs[0].IntValue);
      end;
    end);
  Add(WaitForThread,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThread: TDoomScriptThread;
    begin
      LThread := TDoomScriptThread.GetThread(LContext, AArgs[0].IntValue);
      if not Assigned(LThread) then
      begin
        if LContext.Host.DebugScript then
          // just print a warning and continue executing
          TDoomScriptThread(ATarget).Warning(Format(SThreadNotRunning, [AArgs[0].IntValue]));
      end
      else
        TDoomScriptThread(ATarget).WaitForThread(LThread);
    end);
  Add(Print,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LContext.Print(string(AArgs[0].StringValue));
    end);
  Add(PrintLn,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LContext.Print(string(AArgs[0].StringValue) + #10);
    end);
  // assert( value ) of a release build: nothing
  Add(AssertEvent,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
    end);
  Add(Random,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: Single;
    begin
      LResult := LContext.Host.RandomFloat;
      LResult := AArgs[0].FloatValue * LResult;
      LContext.ScriptProgram.ReturnFloat(LResult);
    end);
  Add(GetTime,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: Single;
    begin
      LResult := LContext.Host.GetRealClientTime * ID_MS2SEC;
      LContext.ScriptProgram.ReturnFloat(LResult);
    end);
  Add(KillThread,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread.KillThread(LContext, AArgs[0].StringValue);
    end);
  Add(SetThreadName,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).SetThreadName(AArgs[0].StringValue);
    end);
  Add(ErrorEvent,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).Error(string(AArgs[0].StringValue));
    end);
  Add(WarningEvent,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).Warning(string(AArgs[0].StringValue));
    end);
  Add(GetFrameTime,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: Single;
    begin
      LResult := LContext.Host.GetFrameMsec * ID_MS2SEC;
      LContext.ScriptProgram.ReturnFloat(LResult);
    end);
  Add(GetTicsPerSecond,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LContext.ScriptProgram.ReturnFloat(DS_USERCMD_HZ);
    end);
  Add(SetSpawnArg,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TDoomScriptThread(ATarget).SpawnArgs.SetValue(AArgs[0].StringValue, AArgs[1].StringValue);
    end);
  Add(SpawnString,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: AnsiString;
    begin
      TDoomScriptThread(ATarget).SpawnArgs.GetString(AArgs[0].StringValue, AArgs[1].StringValue, LResult);
      LContext.ScriptProgram.ReturnString(LResult);
    end);
  Add(SpawnFloat,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: Single;
    begin
      TDoomScriptThread(ATarget).SpawnArgs.GetFloat(AArgs[0].StringValue,
        TIdStrings.FloatToPlainText(AArgs[1].FloatValue), LResult);
      LContext.ScriptProgram.ReturnFloat(LResult);
    end);
  Add(SpawnVector,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: TIdVec3;
      LDefault: AnsiString;
    begin
      LDefault := TIdStrings.FloatToPlainText(AArgs[1].VectorValue.X) + ' ' +
        TIdStrings.FloatToPlainText(AArgs[1].VectorValue.Y) + ' ' +
        TIdStrings.FloatToPlainText(AArgs[1].VectorValue.Z);
      TDoomScriptThread(ATarget).SpawnArgs.GetVector(AArgs[0].StringValue, LDefault, LResult);
      LContext.ScriptProgram.ReturnVector(LResult);
    end);
end;

procedure TDoomScriptSysEvents.RegisterMathEvents;
var
  LContext: TDoomScriptContext;
begin
  LContext := FContext;
  Add(AngToForward,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LContext.ScriptProgram.ReturnVector(TIdAngles.Create(AArgs[0].VectorValue.X, AArgs[0].VectorValue.Y,
        AArgs[0].VectorValue.Z).ToForward);
    end);
  Add(AngToRight,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LForward, LRight, LUp: TIdVec3;
    begin
      TIdAngles.Create(AArgs[0].VectorValue.X, AArgs[0].VectorValue.Y, AArgs[0].VectorValue.Z).ToVectors(LForward,
        LRight, LUp);
      LContext.ScriptProgram.ReturnVector(LRight);
    end);
  Add(AngToUp,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LForward, LRight, LUp: TIdVec3;
    begin
      TIdAngles.Create(AArgs[0].VectorValue.X, AArgs[0].VectorValue.Y, AArgs[0].VectorValue.Z).ToVectors(LForward,
        LRight, LUp);
      LContext.ScriptProgram.ReturnVector(LUp);
    end);
  Add(Sine,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LAngle: Single;
    begin
      LAngle := AArgs[0].FloatValue * ID_DEG2RAD;
      LContext.ScriptProgram.ReturnFloat(TIdMath.Sin(LAngle));
    end);
  Add(Cosine,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LAngle: Single;
    begin
      LAngle := AArgs[0].FloatValue * ID_DEG2RAD;
      LContext.ScriptProgram.ReturnFloat(TIdMath.Cos(LAngle));
    end);
  Add(SquareRoot,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LContext.ScriptProgram.ReturnFloat(TIdMath.Sqrt(AArgs[0].FloatValue));
    end);
  Add(Normalize,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LVector: TIdVec3;
    begin
      LVector := AArgs[0].VectorValue;
      LVector.Normalize;
      LContext.ScriptProgram.ReturnVector(LVector);
    end);
  Add(VecLength,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LVector: TIdVec3;
    begin
      LVector := AArgs[0].VectorValue;
      LContext.ScriptProgram.ReturnFloat(LVector.Length);
    end);
  Add(VecDotProduct,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: Single;
    begin
      LResult := AArgs[0].VectorValue * AArgs[1].VectorValue;
      LContext.ScriptProgram.ReturnFloat(LResult);
    end);
  Add(VecCrossProduct,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LVector: TIdVec3;
    begin
      LVector := AArgs[0].VectorValue;
      LContext.ScriptProgram.ReturnVector(LVector.Cross(AArgs[1].VectorValue));
    end);
  Add(VecToAngles,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LVector: TIdVec3;
      LPitch, LYaw, LRoll: Single;
    begin
      LVector := AArgs[0].VectorValue;
      LVector.ToAngles(LPitch, LYaw, LRoll);
      LContext.ScriptProgram.ReturnVector(TIdVec3.Create(LPitch, LYaw, LRoll));
    end);
end;

procedure TDoomScriptSysEvents.RegisterStringEvents;
var
  LContext: TDoomScriptContext;
begin
  LContext := FContext;
  Add(StrLen,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      // true integers aren't supported in the compiler, so int values are stored as floats
      LContext.ScriptProgram.ReturnFloat(Length(AArgs[0].StringValue));
    end);
  Add(StrLeft,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      if AArgs[1].IntValue < 0 then
        LContext.ScriptProgram.ReturnString('')
      else
        LContext.ScriptProgram.ReturnString(Copy(AArgs[0].StringValue, 1, AArgs[1].IntValue));
    end);
  Add(StrRight,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LLength: Integer;
    begin
      LLength := Length(AArgs[0].StringValue);
      if AArgs[1].IntValue < 0 then
        LContext.ScriptProgram.ReturnString('')
      else if LLength < AArgs[1].IntValue then
        LContext.ScriptProgram.ReturnString(AArgs[0].StringValue)
      else
        LContext.ScriptProgram.ReturnString(Copy(AArgs[0].StringValue, LLength - AArgs[1].IntValue + 1, MaxInt));
    end);
  Add(StrSkip,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      if AArgs[1].IntValue < 0 then
        LContext.ScriptProgram.ReturnString(AArgs[0].StringValue)
      else if Length(AArgs[0].StringValue) < AArgs[1].IntValue then
        LContext.ScriptProgram.ReturnString('')
      else
        LContext.ScriptProgram.ReturnString(Copy(AArgs[0].StringValue, AArgs[1].IntValue + 1, MaxInt));
    end);
  Add(StrMid,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LStart: Integer;
      LNum: Integer;
      LLength: Integer;
    begin
      LStart := AArgs[1].IntValue;
      LNum := AArgs[2].IntValue;
      if LNum < 0 then
      begin
        LContext.ScriptProgram.ReturnString('');
        Exit;
      end;
      if LStart < 0 then
        LStart := 0;
      LLength := Length(AArgs[0].StringValue);
      if LStart > LLength then
        LStart := LLength;
      // the sum wraps for a huge count, as the integers of the original do
      if (LStart + LNum > LLength) or (LStart + LNum < LStart) then
        LNum := LLength - LStart;
      LContext.ScriptProgram.ReturnString(Copy(AArgs[0].StringValue, LStart + 1, LNum));
    end);
  Add(StrToFloat,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LResult: Single;
    begin
      LResult := TIdCNumbers.Atof(AArgs[0].StringValue);
      LContext.ScriptProgram.ReturnFloat(LResult);
    end);
end;

procedure TDoomScriptSysEvents.RegisterWorldBoundEvents;
var
  LContext: TDoomScriptContext;
begin
  LContext := FContext;
  // without a world these events stay without a handler, like the other world events
  if not Assigned(LContext.World) then
    Exit;
  Add(GetEntity,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LName: AnsiString;
      LNumber: Integer;
    begin
      LName := AArgs[0].StringValue;
      if (LName <> '') and (LName[1] = '*') then
      begin
        LNumber := TIdCNumbers.Atoi(Copy(LName, 2, MaxInt));
        if (LNumber < 0) or (LNumber >= DS_MAX_GENTITIES) then
          TDoomScriptThread(ATarget).Error(SEntityNumberRange);
        if LContext.Entities.Exists(LNumber) then
          LContext.ScriptProgram.ReturnEntity(LNumber)
        else
          LContext.ScriptProgram.ReturnEntity(-1);
      end
      else
        LContext.ScriptProgram.ReturnEntity(LContext.World.FindEntity(LName));
    end);
  Add(Spawn,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThread: TDoomScriptThread;
    begin
      LThread := TDoomScriptThread(ATarget);
      LThread.SpawnArgs.SetValue('classname', AArgs[0].StringValue);
      LContext.ScriptProgram.ReturnEntity(LContext.World.SpawnEntity(LThread.SpawnArgs));
      LThread.SpawnArgs.Clear;
    end);
  Add(CopySpawnArgs,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      LContext.World.CopyEntitySpawnArgs(AArgs[0].IntValue, TDoomScriptThread(ATarget).SpawnArgs);
    end);
  Add(OnSignal,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThread: TDoomScriptThread;
      LFunction: TDoomScriptFunction;
    begin
      LThread := TDoomScriptThread(ATarget);
      if AArgs[1].IntValue < 0 then
        LThread.Error(SEntityNotFound);
      if (AArgs[0].IntValue < 0) or (AArgs[0].IntValue >= DS_NUM_SIGNALS) then
        LThread.Error(SSignalRange);
      LFunction := LContext.ScriptProgram.FindFunction(AArgs[2].StringValue);
      if not Assigned(LFunction) then
        LThread.Error(Format(SFunctionNotFound, [string(AArgs[2].StringValue)]));
      LContext.World.SetSignal(AArgs[1].IntValue, AArgs[0].IntValue, LThread.ThreadNum, AArgs[2].StringValue);
    end);
  Add(ClearSignal,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThread: TDoomScriptThread;
    begin
      LThread := TDoomScriptThread(ATarget);
      if AArgs[1].IntValue < 0 then
        LThread.Error(SEntityNotFound);
      if (AArgs[0].IntValue < 0) or (AArgs[0].IntValue >= DS_NUM_SIGNALS) then
        LThread.Error(SSignalRange);
      LContext.World.ClearSignalThread(AArgs[1].IntValue, AArgs[0].IntValue, LThread.ThreadNum);
    end);
end;

end.
