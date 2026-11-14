{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptInterpreter                }
{  (idInterpreter)                                                             }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Interpreter.h, Script_Interpreter.cpp. Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Interpreter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.EventRegistry, DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.EventTarget,
  DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.DoomScript.ScriptObject,
  DelphiDoom.DoomScript.Entities, DelphiDoom.DoomScript.SaveStream;

type
  TDoomScriptInterpreter = class;

  /// <summary>
  ///   What an interpreter asks the thread that owns it (the part of idThread the interpreter uses): its
  ///   name for the messages, the events of the <c>sys</c> object (it is their target) and the start of
  ///   a new thread for <c>thread f()</c>
  /// </summary>
  TDoomScriptThreadBase = class abstract(TDoomScriptEventTarget)
  public
    function GetThreadName: AnsiString; virtual; abstract;
    procedure SetThreadName(const AName: AnsiString); virtual; abstract;
    /// <summary>
    ///   Creates a thread that calls the function with the last <c>AArgs</c> bytes of the stack of the
    ///   source, starts it and returns its number
    /// </summary>
    function StartThread(const ASource: TDoomScriptInterpreter; const AFunction: TDoomScriptFunction;
      const AArgs: Integer): Integer; virtual; abstract;
  end;

  /// <summary>prstack_t: a frame of the call stack</summary>
  TDoomScriptCallFrame = record
    Statement: Integer;
    Func: TDoomScriptFunction;
    StackBase: Integer;
  end;


  /// <summary>
  ///   idInterpreter: runs the statements of a program for one thread, on its own call stack and local
  ///   stack. Every access to the memory (globals, local stack, object data, tables) is checked: what
  ///   was undefined in the original is an EDoomScriptMemoryError. A pointer to a field of an object is a
  ///   handle (entity and offset), never an address. The loop of <c>Execute</c> makes no virtual or
  ///   interface call for a statement, except for the events (calls to the host) and the messages.
  /// </summary>
  TDoomScriptInterpreter = class
  strict private
    FProgram: TDoomScriptProgram;
    FEntities: TDoomScriptEntityTable;
    FEvents: TDoomScriptEventRegistry;
    FHost: IDoomScriptHost;
    FLog: IIdLibLog;
    FThread: TDoomScriptThreadBase;
    FGlobals: PByte;
    FCallStack: array[0..DS_MAX_STACK_DEPTH - 1] of TDoomScriptCallFrame;
    FCallStackDepth: Integer;
    FMaxStackDepth: Integer;
    FLocalStack: array[0..DS_LOCALSTACK_SIZE - 1] of Byte;
    FLocalStackUsed: Integer;
    FLocalStackBase: Integer;
    FMaxLocalStackUsed: Integer;
    FCurrentFunction: TDoomScriptFunction;
    FInstructionPointer: Integer;
    FPopParms: Integer;
    FMultiFrameEvent: TDoomScriptEventDef;
    FEventEntity: TDoomScriptEventTarget;
    procedure MemoryError(const AOffset, ASize: Integer);
    procedure BadOperand;
    function VarPtr(const ADef: TDoomScriptVarDef; const ASize: Integer): PByte; inline;
    function StackPtr(const AOffset, ASize: Integer): PByte; inline;
    function FieldPtr(const AObject: TDoomScriptObject; const ADef: TDoomScriptVarDef; const ASize: Integer): PByte;
    function DerefPointer(const AHandle: Cardinal; const ASize: Integer): PByte;
    procedure PopParms(const ANumParms: Integer);
    procedure PushString(const AText: AnsiString);
    procedure Push(const AValue: Integer);
    function GetString(const ADef: TDoomScriptVarDef): AnsiString;
    procedure SetString(const ADef: TDoomScriptVarDef; const AText: AnsiString);
    procedure AppendString(const ADef: TDoomScriptVarDef; const AText: AnsiString);
    function GetScriptObject(const ADef: TDoomScriptVarDef): TDoomScriptObject;
    procedure NextInstruction(const APosition: Integer); inline;
    procedure LeaveFunction(const AReturnDef: TDoomScriptVarDef);
    function BuildEventArgs(const AFunction: TDoomScriptFunction; const AStart, AFirstPos, AArgSize: Integer;
      out AArgs: TDoomScriptEventArgs): Boolean;
    procedure CallEvent(const AFunction: TDoomScriptFunction; const AArgSize: Integer);
    procedure CallSysEvent(const AFunction: TDoomScriptFunction; const AArgSize: Integer);
    procedure Print(const AText: string);
    function ModuloOrError(const AValue, ADivisor: Single): Single;
    function RunStatements: Boolean;
    class function FormatG(const AValue: Single): AnsiString; static;
  public
    DoneProcessing: Boolean;
    ThreadDying: Boolean;
    TerminateOnExit: Boolean;
    Debug: Boolean;
    constructor Create(const AProgram: TDoomScriptProgram; const AEntities: TDoomScriptEntityTable;
      const AEvents: TDoomScriptEventRegistry; const AHost: IDoomScriptHost; const ALog: IIdLibLog;
      const AThread: TDoomScriptThreadBase);
    /// <summary>idInterpreter::Save; the references to the event entity and the thread go through the callback</summary>
    procedure Save(const AStream: TStream; const AWriteObject: TDoomScriptWriteObject);
    /// <summary>
    ///   idInterpreter::Restore. Values that would put the stacks outside their limits raise
    ///   EDoomScriptMemoryError; the two object references are read (and ignored for the thread, which
    ///   is the owner)
    /// </summary>
    procedure Restore(const AStream: TStream; const AReadObject: TDoomScriptReadObject);
    procedure StackTrace;
    function CurrentLine: Integer;
    function CurrentFile: AnsiString;
    /// <summary>Prints the stack trace and raises EDoomScriptError "file(line): Thread 'name': text"</summary>
    procedure Error(const AText: string);
    procedure Warning(const AText: string);
    procedure DisplayInfo;
    function BeginMultiFrameEvent(const AEntity: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef): Boolean;
    procedure EndMultiFrameEvent(const AEntity: TDoomScriptEventTarget; const AEvent: TDoomScriptEventDef);
    function MultiFrameEventInProgress: Boolean;
    /// <summary>Copies the arguments from the stack of the calling thread and enters the function</summary>
    procedure ThreadCall(const ASource: TDoomScriptInterpreter; const AFunction: TDoomScriptFunction;
      const AArgs: Integer);
    procedure EnterFunction(const AFunction: TDoomScriptFunction; const AClearStack: Boolean);
    /// <summary>Calls a method: pushes the entity (its handle) as <c>self</c></summary>
    procedure EnterObjectFunction(const AEntityNumber: Integer; const AFunction: TDoomScriptFunction;
      const AClearStack: Boolean);
    /// <summary>Runs until the thread pauses or ends; true when the thread is dying</summary>
    function Execute: Boolean;
    procedure Reset;
    /// <summary>
    ///   idInterpreter::GetRegisterValue (for a debugger). A field of an object gives false: the original
    ///   read the entity number as a pointer there
    /// </summary>
    function GetRegisterValue(const AName: AnsiString; out AValue: AnsiString; AScopeDepth: Integer): Boolean;
    function GetCallstackDepth: Integer;
    function GetCallFrame(const AIndex: Integer): TDoomScriptCallFrame;
    function GetCurrentFunction: TDoomScriptFunction;
    function GetThread: TDoomScriptThreadBase;
    /// <summary>The bytes of the local stack in use, for a state dump</summary>
    function LocalStackBytes: TBytes;
    property LocalStackUsed: Integer read FLocalStackUsed;
    property LocalStackBase: Integer read FLocalStackBase;
    property MaxStackDepth: Integer read FMaxStackDepth;
    property MaxLocalStackUsed: Integer read FMaxLocalStackUsed;
    property InstructionPointer: Integer read FInstructionPointer;
    property PopParmsPending: Integer read FPopParms;
    property MultiFrameEvent: TDoomScriptEventDef read FMultiFrameEvent;
    property EventEntity: TDoomScriptEventTarget read FEventEntity;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math, DelphiDoom.DoomScript.Opcodes;

type
  PIdVec3 = ^TIdVec3;

const
  POINTER_FLAG = Cardinal($80000000);
  POINTER_OFFSET_BITS = 18;
  POINTER_OFFSET_MASK = (1 shl POINTER_OFFSET_BITS) - 1;

  SMemoryError = 'idInterpreter: access to %d bytes at %d is outside the memory of the script';
  SBadOperand = 'idInterpreter: statement %d has no operand where one is needed';
  SBadPointer = 'idInterpreter: invalid pointer %x';
  SStalePointer = 'idInterpreter: pointer to a field of an object that no longer exists';
  SBadStatement = 'idInterpreter: instruction pointer %d is outside the program';
  SBadParmSize = 'idInterpreter: the event ''%s'' has more arguments than the function declares';
  SRestoreState = 'idInterpreter::Restore: invalid state (%s = %d)';

constructor TDoomScriptInterpreter.Create(const AProgram: TDoomScriptProgram; const AEntities: TDoomScriptEntityTable;
  const AEvents: TDoomScriptEventRegistry; const AHost: IDoomScriptHost; const ALog: IIdLibLog;
  const AThread: TDoomScriptThreadBase);
begin
  inherited Create;
  FProgram := AProgram;
  FEntities := AEntities;
  FEvents := AEvents;
  FHost := AHost;
  FLog := ALog;
  FThread := AThread;
  FGlobals := AProgram.GlobalsBase;
  TerminateOnExit := True;
  Debug := False;
  Reset;
end;

procedure TDoomScriptInterpreter.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Printf(AText);
end;

procedure TDoomScriptInterpreter.MemoryError(const AOffset, ASize: Integer);
begin
  raise EDoomScriptMemoryError.CreateFmt(SMemoryError, [ASize, AOffset]);
end;

procedure TDoomScriptInterpreter.BadOperand;
begin
  raise EDoomScriptMemoryError.CreateFmt(SBadOperand, [FInstructionPointer]);
end;

function TDoomScriptInterpreter.VarPtr(const ADef: TDoomScriptVarDef; const ASize: Integer): PByte;
var
  LOffset: Integer;
begin
  if ADef = nil then
    BadOperand;
  if ADef.Initialized = diStackVariable then
  begin
    LOffset := FLocalStackBase + ADef.Value;
    if (LOffset < 0) or (LOffset > DS_LOCALSTACK_SIZE - ASize) then
      MemoryError(LOffset, ASize);
    Result := @FLocalStack[LOffset];
  end
  else
  begin
    LOffset := ADef.Value;
    if (LOffset < 0) or (LOffset > DS_MAX_GLOBALS - ASize) then
      MemoryError(LOffset, ASize);
    Result := FGlobals + LOffset;
  end;
end;

function TDoomScriptInterpreter.StackPtr(const AOffset, ASize: Integer): PByte;
begin
  if (AOffset < 0) or (AOffset > DS_LOCALSTACK_SIZE - ASize) then
    MemoryError(AOffset, ASize);
  Result := @FLocalStack[AOffset];
end;

function TDoomScriptInterpreter.FieldPtr(const AObject: TDoomScriptObject; const ADef: TDoomScriptVarDef;
  const ASize: Integer): PByte;
begin
  if ADef = nil then
    BadOperand;
  Result := AObject.DataPtr(ADef.Value, ASize);
end;

function TDoomScriptInterpreter.DerefPointer(const AHandle: Cardinal; const ASize: Integer): PByte;
var
  LObject: TDoomScriptObject;
begin
  if (AHandle and POINTER_FLAG) = 0 then
    raise EDoomScriptMemoryError.CreateFmt(SBadPointer, [AHandle]);
  LObject := FEntities.GetScriptObject(Integer((AHandle and not POINTER_FLAG) shr POINTER_OFFSET_BITS) + 1);
  if not Assigned(LObject) then
    raise EDoomScriptMemoryError.Create(SStalePointer);
  Result := LObject.DataPtr(Integer(AHandle and POINTER_OFFSET_MASK), ASize);
end;

function TDoomScriptInterpreter.GetScriptObject(const ADef: TDoomScriptVarDef): TDoomScriptObject;
begin
  Result := FEntities.GetScriptObject(PInteger(VarPtr(ADef, 4))^);
end;

procedure TDoomScriptInterpreter.PopParms(const ANumParms: Integer);
begin
  // pop our parms off the stack
  if (FLocalStackUsed < ANumParms) or (ANumParms < 0) then
    Error('locals stack underflow'#10);
  Dec(FLocalStackUsed, ANumParms);
end;

procedure TDoomScriptInterpreter.Push(const AValue: Integer);
begin
  if FLocalStackUsed + 4 > DS_LOCALSTACK_SIZE then
    Error('Push: locals stack overflow'#10);
  PInteger(@FLocalStack[FLocalStackUsed])^ := AValue;
  Inc(FLocalStackUsed, 4);
end;

procedure TDoomScriptInterpreter.PushString(const AText: AnsiString);
begin
  if FLocalStackUsed + DS_MAX_STRING_LEN > DS_LOCALSTACK_SIZE then
    Error('PushString: locals stack overflow'#10);
  TDoomScriptMemory.CopyString(@FLocalStack[FLocalStackUsed], AText);
  Inc(FLocalStackUsed, DS_MAX_STRING_LEN);
end;

function TDoomScriptInterpreter.GetString(const ADef: TDoomScriptVarDef): AnsiString;
begin
  Result := TDoomScriptMemory.ReadString(VarPtr(ADef, DS_MAX_STRING_LEN));
end;

procedure TDoomScriptInterpreter.SetString(const ADef: TDoomScriptVarDef; const AText: AnsiString);
begin
  TDoomScriptMemory.CopyString(VarPtr(ADef, DS_MAX_STRING_LEN), AText);
end;

procedure TDoomScriptInterpreter.AppendString(const ADef: TDoomScriptVarDef; const AText: AnsiString);
begin
  TDoomScriptMemory.AppendString(VarPtr(ADef, DS_MAX_STRING_LEN), AText);
end;

procedure TDoomScriptInterpreter.NextInstruction(const APosition: Integer);
begin
  // the instruction pointer is incremented before a statement runs: compensate for that here
  FInstructionPointer := APosition - 1;
end;

procedure TDoomScriptInterpreter.Reset;
begin
  FCallStackDepth := 0;
  FLocalStackUsed := 0;
  FLocalStackBase := 0;
  FMaxLocalStackUsed := 0;
  FMaxStackDepth := 0;
  FPopParms := 0;
  FMultiFrameEvent := nil;
  FEventEntity := nil;
  FCurrentFunction := nil;
  NextInstruction(0);
  ThreadDying := False;
  DoneProcessing := True;
end;

procedure TDoomScriptInterpreter.Save(const AStream: TStream; const AWriteObject: TDoomScriptWriteObject);
var
  LIndex: Integer;
begin
  TDoomScriptSaveStream.WriteInt(AStream, FCallStackDepth);
  for LIndex := 0 to FCallStackDepth - 1 do
  begin
    TDoomScriptSaveStream.WriteInt(AStream, FCallStack[LIndex].Statement);
    TDoomScriptSaveStream.WriteInt(AStream, FProgram.GetFunctionIndex(FCallStack[LIndex].Func));
    TDoomScriptSaveStream.WriteInt(AStream, FCallStack[LIndex].StackBase);
  end;
  TDoomScriptSaveStream.WriteInt(AStream, FMaxStackDepth);
  TDoomScriptSaveStream.WriteInt(AStream, FLocalStackUsed);
  TDoomScriptSaveStream.WriteBytes(AStream, @FLocalStack[0], FLocalStackUsed);
  TDoomScriptSaveStream.WriteInt(AStream, FLocalStackBase);
  TDoomScriptSaveStream.WriteInt(AStream, FMaxLocalStackUsed);
  TDoomScriptSaveStream.WriteInt(AStream, FProgram.GetFunctionIndex(FCurrentFunction));
  TDoomScriptSaveStream.WriteInt(AStream, FInstructionPointer);
  TDoomScriptSaveStream.WriteInt(AStream, FPopParms);
  if Assigned(FMultiFrameEvent) then
    TDoomScriptSaveStream.WriteString(AStream, FMultiFrameEvent.Name)
  else
    TDoomScriptSaveStream.WriteString(AStream, '');
  AWriteObject(AStream, FEventEntity);
  AWriteObject(AStream, FThread);
  TDoomScriptSaveStream.WriteBool(AStream, DoneProcessing);
  TDoomScriptSaveStream.WriteBool(AStream, ThreadDying);
  TDoomScriptSaveStream.WriteBool(AStream, TerminateOnExit);
  TDoomScriptSaveStream.WriteBool(AStream, Debug);
end;

procedure TDoomScriptInterpreter.Restore(const AStream: TStream; const AReadObject: TDoomScriptReadObject);
var
  LIndex: Integer;
  LFuncIndex: Integer;
  LName: AnsiString;
  LObject: TObject;

  procedure Check(const AValid: Boolean; const AWhat: string; const AValue: Integer);
  begin
    if not AValid then
      raise EDoomScriptMemoryError.CreateFmt(SRestoreState, [AWhat, AValue]);
  end;

  function ReadFunction: TDoomScriptFunction;
  begin
    LFuncIndex := TDoomScriptSaveStream.ReadInt(AStream);
    if LFuncIndex >= 0 then
      Result := FProgram.GetFunction(LFuncIndex)
    else
      Result := nil;
  end;

begin
  FCallStackDepth := TDoomScriptSaveStream.ReadInt(AStream);
  if (FCallStackDepth < 0) or (FCallStackDepth > DS_MAX_STACK_DEPTH) then
  begin
    LIndex := FCallStackDepth;
    FCallStackDepth := 0;
    Check(False, 'callStackDepth', LIndex);
  end;
  for LIndex := 0 to FCallStackDepth - 1 do
  begin
    FCallStack[LIndex].Statement := TDoomScriptSaveStream.ReadInt(AStream);
    FCallStack[LIndex].Func := ReadFunction;
    FCallStack[LIndex].StackBase := TDoomScriptSaveStream.ReadInt(AStream);
    Check((FCallStack[LIndex].StackBase >= 0) and (FCallStack[LIndex].StackBase <= DS_LOCALSTACK_SIZE), 'stackbase',
      FCallStack[LIndex].StackBase);
  end;
  FMaxStackDepth := TDoomScriptSaveStream.ReadInt(AStream);
  LIndex := TDoomScriptSaveStream.ReadInt(AStream);
  Check((LIndex >= 0) and (LIndex <= DS_LOCALSTACK_SIZE), 'localstackUsed', LIndex);
  FLocalStackUsed := LIndex;
  TDoomScriptSaveStream.ReadBytes(AStream, @FLocalStack[0], FLocalStackUsed);
  LIndex := TDoomScriptSaveStream.ReadInt(AStream);
  Check((LIndex >= 0) and (LIndex <= DS_LOCALSTACK_SIZE), 'localstackBase', LIndex);
  FLocalStackBase := LIndex;
  FMaxLocalStackUsed := TDoomScriptSaveStream.ReadInt(AStream);
  FCurrentFunction := ReadFunction;
  FInstructionPointer := TDoomScriptSaveStream.ReadInt(AStream);
  LIndex := TDoomScriptSaveStream.ReadInt(AStream);
  Check((LIndex >= 0) and (LIndex <= FLocalStackUsed), 'popParms', LIndex);
  FPopParms := LIndex;
  LName := TDoomScriptSaveStream.ReadString(AStream);
  if LName <> '' then
    FMultiFrameEvent := FEvents.FindEvent(LName);
  LObject := AReadObject(AStream);
  if LObject is TDoomScriptEventTarget then
    FEventEntity := TDoomScriptEventTarget(LObject)
  else
    FEventEntity := nil;
  // the thread: the interpreter already belongs to the thread that restores it
  AReadObject(AStream);
  DoneProcessing := TDoomScriptSaveStream.ReadBool(AStream);
  ThreadDying := TDoomScriptSaveStream.ReadBool(AStream);
  TerminateOnExit := TDoomScriptSaveStream.ReadBool(AStream);
  Debug := TDoomScriptSaveStream.ReadBool(AStream);
end;

class function TDoomScriptInterpreter.FormatG(const AValue: Single): AnsiString;
var
  LText: string;
  LExponent: Integer;
  LPosE: Integer;
  LMantissa: string;
  LSettings: TFormatSettings;

  function StripZeros(const AText: string): string;
  begin
    Result := AText;
    if Pos('.', Result) > 0 then
    begin
      while Result[Length(Result)] = '0' do
        SetLength(Result, Length(Result) - 1);
      if Result[Length(Result)] = '.' then
        SetLength(Result, Length(Result) - 1);
    end;
  end;

begin
  if IsNan(AValue) then
    Exit('nan');
  if IsInfinite(AValue) then
  begin
    if AValue < 0 then
      Exit('-inf');
    Exit('inf');
  end;
  if AValue = 0 then
    Exit('0');
  LSettings := TFormatSettings.Invariant;
  // "%g": six significant digits, exponent form outside 1e-5 .. 1e6
  LText := FloatToStrF(AValue, ffExponent, 6, 2, LSettings);
  LPosE := Pos('E', LText);
  LMantissa := Copy(LText, 1, LPosE - 1);
  LExponent := StrToInt(Copy(LText, LPosE + 1, MaxInt));
  if (LExponent < -4) or (LExponent >= 6) then
  begin
    LText := StripZeros(LMantissa) + 'e';
    if LExponent < 0 then
      LText := LText + '-'
    else
      LText := LText + '+';
    Result := AnsiString(LText + Format('%.2d', [Abs(LExponent)]));
  end
  else
    Result := AnsiString(StripZeros(FloatToStrF(AValue, ffFixed, 18, 5 - LExponent, LSettings)));
end;

function TDoomScriptInterpreter.GetRegisterValue(const AName: AnsiString; out AValue: AnsiString;
  AScopeDepth: Integer): Boolean;
var
  LDef: TDoomScriptVarDef;
  LScope: TDoomScriptVarDef;
  LFunc: TDoomScriptFunction;
  LFuncObject: AnsiString;
  LFuncName: AnsiString;
  LPos: Integer;
  LVector: PIdVec3;
begin
  AValue := '';
  if AScopeDepth = -1 then
    AScopeDepth := FCallStackDepth;
  if AScopeDepth = FCallStackDepth then
    LFunc := FCurrentFunction
  else if (AScopeDepth >= 0) and (AScopeDepth < DS_MAX_STACK_DEPTH) then
    LFunc := FCallStack[AScopeDepth].Func
  else
    LFunc := nil;
  if not Assigned(LFunc) then
    Exit(False);
  LFuncObject := LFunc.Name;
  LPos := Pos(AnsiString('::'), LFuncObject);
  if LPos > 0 then
  begin
    LFuncName := Copy(LFuncObject, LPos + 2, MaxInt);
    SetLength(LFuncObject, LPos - 1);
    LScope := FProgram.GetDef(nil, LFuncObject, FProgram.DefNamespace);
  end
  else
  begin
    LFuncName := LFuncObject;
    LScope := FProgram.DefNamespace;
  end;
  // get the function from the object
  LDef := FProgram.GetDef(nil, LFuncName, LScope);
  if not Assigned(LDef) then
    Exit(False);
  // get the variable itself and check various namespaces
  LDef := FProgram.GetDef(nil, AName, LDef);
  if not Assigned(LDef) then
  begin
    if LScope = FProgram.DefNamespace then
      Exit(False);
    LDef := FProgram.GetDef(nil, AName, LScope);
    if not Assigned(LDef) then
    begin
      LDef := FProgram.GetDef(nil, AName, FProgram.DefNamespace);
      if not Assigned(LDef) then
        Exit(False);
    end;
  end;
  Result := True;
  case LDef.Kind of
    evFloat:
      AValue := FormatG(PSingle(VarPtr(LDef, 4))^);
    evVector:
      begin
        LVector := PIdVec3(VarPtr(LDef, 12));
        AValue := FormatG(LVector.X) + ',' + FormatG(LVector.Y) + ',' + FormatG(LVector.Z);
      end;
    evBoolean:
      AValue := AnsiString(IntToStr(PInteger(VarPtr(LDef, 4))^));
    evString:
      AValue := '"' + GetString(LDef) + '"';
  else
    // a field: the original took the entity number on the stack for a pointer to the object
    Result := False;
  end;
end;

function TDoomScriptInterpreter.GetCallstackDepth: Integer;
begin
  Result := FCallStackDepth;
end;

function TDoomScriptInterpreter.GetCallFrame(const AIndex: Integer): TDoomScriptCallFrame;
begin
  if (AIndex < 0) or (AIndex >= DS_MAX_STACK_DEPTH) then
    MemoryError(AIndex, 0);
  Result := FCallStack[AIndex];
end;

function TDoomScriptInterpreter.GetCurrentFunction: TDoomScriptFunction;
begin
  Result := FCurrentFunction;
end;

function TDoomScriptInterpreter.GetThread: TDoomScriptThreadBase;
begin
  Result := FThread;
end;

function TDoomScriptInterpreter.LocalStackBytes: TBytes;
begin
  SetLength(Result, FLocalStackUsed);
  if FLocalStackUsed > 0 then
    Move(FLocalStack[0], Result[0], FLocalStackUsed);
end;

function TDoomScriptInterpreter.CurrentLine: Integer;
begin
  if (FInstructionPointer < 0) or (FInstructionPointer >= FProgram.NumStatements) then
    Exit(0);
  Result := FProgram.GetLineNumberForStatement(FInstructionPointer);
end;

function TDoomScriptInterpreter.CurrentFile: AnsiString;
begin
  if (FInstructionPointer < 0) or (FInstructionPointer >= FProgram.NumStatements) then
    Exit('');
  Result := FProgram.GetFilenameForStatement(FInstructionPointer);
end;

procedure TDoomScriptInterpreter.StackTrace;
var
  LIndex: Integer;
  LTop: Integer;

  procedure PrintFunction(const AFunction: TDoomScriptFunction);
  begin
    if (not Assigned(AFunction)) or (AFunction.FileNum >= FProgram.NumFilenames) then
      Print('<NO FUNCTION>'#10)
    else
      Print(Format('%12s : %s'#10, [string(FProgram.GetFilename(AFunction.FileNum)), string(AFunction.Name)]));
  end;

begin
  if FCallStackDepth = 0 then
  begin
    Print('<NO STACK>'#10);
    Exit;
  end;
  LTop := FCallStackDepth;
  if LTop >= DS_MAX_STACK_DEPTH then
    LTop := DS_MAX_STACK_DEPTH - 1;
  PrintFunction(FCurrentFunction);
  // as in the original, the entry at the top is one past the frames in use: what an earlier call left
  for LIndex := LTop downto 0 do
    PrintFunction(FCallStack[LIndex].Func);
end;

procedure TDoomScriptInterpreter.Error(const AText: string);
begin
  StackTrace;
  if (FInstructionPointer >= 0) and (FInstructionPointer < FProgram.NumStatements) then
    raise EDoomScriptError.CreateFmt('%s(%d): Thread ''%s'': %s'#10,
      [string(FProgram.GetFilenameForStatement(FInstructionPointer)),
      FProgram.GetLineNumberForStatement(FInstructionPointer), string(FThread.GetThreadName), AText]);
  raise EDoomScriptError.CreateFmt('Thread ''%s'': %s'#10, [string(FThread.GetThreadName), AText]);
end;

procedure TDoomScriptInterpreter.Warning(const AText: string);
begin
  if not Assigned(FLog) then
    Exit;
  if (FInstructionPointer >= 0) and (FInstructionPointer < FProgram.NumStatements) then
    FLog.Warning(Format('%s(%d): Thread ''%s'': %s', [string(FProgram.GetFilenameForStatement(FInstructionPointer)),
      FProgram.GetLineNumberForStatement(FInstructionPointer), string(FThread.GetThreadName), AText]))
  else
    FLog.Warning(Format('Thread ''%s'' : %s', [string(FThread.GetThreadName), AText]));
end;

procedure TDoomScriptInterpreter.DisplayInfo;
var
  LIndex: Integer;

  procedure PrintFunction(const AFunction: TDoomScriptFunction);
  begin
    if (not Assigned(AFunction)) or (AFunction.FileNum >= FProgram.NumFilenames) then
      Print('<NO FUNCTION>'#10)
    else
      Print(Format('%12s : %s'#10, [string(FProgram.GetFilename(AFunction.FileNum)), string(AFunction.Name)]));
  end;

begin
  Print(Format(' Stack depth: %d bytes, %d max'#10, [FLocalStackUsed, FMaxLocalStackUsed]));
  Print(Format('  Call depth: %d, %d max'#10, [FCallStackDepth, FMaxStackDepth]));
  Print('  Call Stack: ');
  if FCallStackDepth = 0 then
    Print('<NO STACK>'#10)
  else
  begin
    PrintFunction(FCurrentFunction);
    for LIndex := FCallStackDepth downto 1 do
    begin
      Print('              ');
      // the original read one entry past the array when the stack was full
      if LIndex >= DS_MAX_STACK_DEPTH then
        PrintFunction(nil)
      else
        PrintFunction(FCallStack[LIndex].Func);
    end;
  end;
end;

procedure TDoomScriptInterpreter.ThreadCall(const ASource: TDoomScriptInterpreter; const AFunction: TDoomScriptFunction;
  const AArgs: Integer);
begin
  Reset;
  if (AArgs < 0) or (AArgs > ASource.FLocalStackUsed) then
    MemoryError(ASource.FLocalStackUsed - AArgs, AArgs);
  if AArgs > 0 then
    Move(ASource.FLocalStack[ASource.FLocalStackUsed - AArgs], FLocalStack[0], AArgs);
  FLocalStackUsed := AArgs;
  FLocalStackBase := 0;
  FMaxLocalStackUsed := FLocalStackUsed;
  EnterFunction(AFunction, False);
  FThread.SetThreadName(FCurrentFunction.Name);
end;

procedure TDoomScriptInterpreter.EnterObjectFunction(const AEntityNumber: Integer; const AFunction: TDoomScriptFunction;
  const AClearStack: Boolean);
begin
  if AClearStack then
    Reset;
  if FPopParms <> 0 then
  begin
    PopParms(FPopParms);
    FPopParms := 0;
  end;
  Push(AEntityNumber + 1);
  EnterFunction(AFunction, False);
end;

procedure TDoomScriptInterpreter.EnterFunction(const AFunction: TDoomScriptFunction; const AClearStack: Boolean);
var
  LLocals: Integer;
  LSuffix: string;
begin
  if AClearStack then
    Reset;
  if FPopParms <> 0 then
  begin
    PopParms(FPopParms);
    FPopParms := 0;
  end;
  if FCallStackDepth >= DS_MAX_STACK_DEPTH then
    Error('call stack overflow');
  // point to the next instruction to execute
  FCallStack[FCallStackDepth].Statement := FInstructionPointer + 1;
  FCallStack[FCallStackDepth].Func := FCurrentFunction;
  FCallStack[FCallStackDepth].StackBase := FLocalStackBase;
  Inc(FCallStackDepth);
  if FCallStackDepth > FMaxStackDepth then
    FMaxStackDepth := FCallStackDepth;
  if not Assigned(AFunction) then
    Error('NULL function');
  if Debug then
  begin
    if AClearStack then
      LSuffix := ' clear stack'
    else
      LSuffix := '';
    if Assigned(FCurrentFunction) then
      Print(Format('%d: call ''%s'' from ''%s''(line %d)%s'#10, [FHost.GetTime, string(AFunction.Name),
        string(FCurrentFunction.Name), FProgram.GetStatement(FInstructionPointer).LineNumber, LSuffix]))
    else
      Print(Format('%d: call ''%s''%s'#10, [FHost.GetTime, string(AFunction.Name), LSuffix]));
  end;
  FCurrentFunction := AFunction;
  NextInstruction(AFunction.FirstStatement);
  // allocate space on the stack for locals; parms are already on stack
  LLocals := AFunction.Locals - AFunction.ParmTotal;
  if (LLocals < 0) or (FLocalStackUsed + LLocals > DS_LOCALSTACK_SIZE) then
    Error('EnterFuncton: locals stack overflow'#10);
  // initialize local stack variables to zero
  if LLocals > 0 then
    FillChar(FLocalStack[FLocalStackUsed], LLocals, 0);
  Inc(FLocalStackUsed, LLocals);
  FLocalStackBase := FLocalStackUsed - AFunction.Locals;
  if FLocalStackUsed > FMaxLocalStackUsed then
    FMaxLocalStackUsed := FLocalStackUsed;
end;

procedure TDoomScriptInterpreter.LeaveFunction(const AReturnDef: TDoomScriptVarDef);
var
  LFrame: ^TDoomScriptCallFrame;
  LVector: TIdVec3;
  LLine: PDoomScriptStatement;
begin
  if FCallStackDepth <= 0 then
    Error('prog stack underflow');
  // return value
  if Assigned(AReturnDef) then
    case AReturnDef.Kind of
      evString:
        FProgram.ReturnString(GetString(AReturnDef));
      evVector:
        begin
          Move(VarPtr(AReturnDef, 12)^, LVector, 12);
          FProgram.ReturnVector(LVector);
        end;
    else
      FProgram.ReturnInteger(PInteger(VarPtr(AReturnDef, 4))^);
    end;
  // remove locals from the stack
  PopParms(FCurrentFunction.Locals);
  if Debug then
  begin
    LLine := FProgram.GetStatement(FInstructionPointer);
    Print(Format('%d: %s(%d): exit %s', [FHost.GetTime, string(FProgram.GetFilename(LLine.FileNum)),
      LLine.LineNumber, string(FCurrentFunction.Name)]));
    if (FCallStackDepth > 1) and Assigned(FCallStack[FCallStackDepth - 1].Func) then
      Print(Format(' return to %s(line %d)'#10, [string(FCallStack[FCallStackDepth - 1].Func.Name),
        FProgram.GetStatement(FCallStack[FCallStackDepth - 1].Statement).LineNumber]))
    else
      Print(' done'#10);
  end;
  // up stack
  Dec(FCallStackDepth);
  LFrame := @FCallStack[FCallStackDepth];
  FCurrentFunction := LFrame.Func;
  FLocalStackBase := LFrame.StackBase;
  NextInstruction(LFrame.Statement);
  if FCallStackDepth = 0 then
  begin
    // all done
    DoneProcessing := True;
    ThreadDying := True;
    FCurrentFunction := nil;
  end;
end;

function TDoomScriptInterpreter.BuildEventArgs(const AFunction: TDoomScriptFunction; const AStart, AFirstPos,
  AArgSize: Integer; out AArgs: TDoomScriptEventArgs): Boolean;
var
  LIndex: Integer;
  LParm: Integer;
  LPos: Integer;
  LFormat: AnsiString;
  LKind: AnsiChar;
  LEvent: TDoomScriptEventDef;
  LEntity: Integer;
begin
  Result := True;
  AArgs := Default(TDoomScriptEventArgs);
  LEvent := AFunction.EventDef;
  LFormat := LEvent.ArgFormat;
  LIndex := 0;
  LParm := 0;
  LPos := AFirstPos;
  while (LPos < AArgSize) or (LIndex < Length(LFormat)) do
  begin
    if LIndex < Length(LFormat) then
      LKind := LFormat[LIndex + 1]
    else
      LKind := #0;
    if LKind <> #0 then
      AArgs[LIndex].Kind := LKind;
    case LKind of
      DS_EVENT_INTEGER:
        AArgs[LIndex].IntValue := TDoomScriptConvert.FloatToInt(PSingle(StackPtr(AStart + LPos, 4))^);
      DS_EVENT_FLOAT:
        AArgs[LIndex].FloatValue := PSingle(StackPtr(AStart + LPos, 4))^;
      DS_EVENT_VECTOR:
        Move(StackPtr(AStart + LPos, 12)^, AArgs[LIndex].VectorValue, 12);
      DS_EVENT_STRING:
        AArgs[LIndex].StringValue := TDoomScriptMemory.ReadString(StackPtr(AStart + LPos, DS_MAX_STRING_LEN));
      DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
        begin
          LEntity := PInteger(StackPtr(AStart + LPos, 4))^;
          if Assigned(FEntities.GetEntity(LEntity)) then
            AArgs[LIndex].IntValue := LEntity - 1
          else
          begin
            AArgs[LIndex].IntValue := -1;
            if LKind = DS_EVENT_ENTITY then
            begin
              Warning(Format('Entity not found for event ''%s''. Terminating thread.', [string(LEvent.Name)]));
              ThreadDying := True;
              PopParms(AArgSize);
              Exit(False);
            end;
          end;
        end;
      DS_EVENT_TRACE:
        Error(Format('trace type not supported from script for ''%s'' event.', [string(LEvent.Name)]));
    else
      Error(Format('Invalid arg format string for ''%s'' event.', [string(LEvent.Name)]));
    end;
    if LParm >= Length(AFunction.ParmSize) then
      raise EDoomScriptMemoryError.CreateFmt(SBadParmSize, [string(LEvent.Name)]);
    Inc(LPos, AFunction.ParmSize[LParm]);
    Inc(LParm);
    Inc(LIndex);
  end;
end;

procedure TDoomScriptInterpreter.CallEvent(const AFunction: TDoomScriptFunction; const AArgSize: Integer);
var
  LStart: Integer;
  LArgs: TDoomScriptEventArgs;
  LEvent: TDoomScriptEventDef;
  LEntity: Integer;
begin
  if (not Assigned(AFunction)) or not Assigned(AFunction.EventDef) then
    Error('NULL function');
  LEvent := AFunction.EventDef;
  LStart := FLocalStackUsed - AArgSize;
  LEntity := PInteger(StackPtr(LStart, 4))^;
  FEventEntity := FEntities.GetEntity(LEntity);
  if (not Assigned(FEventEntity)) or not FEventEntity.RespondsTo(LEvent) then
  begin
    if Assigned(FEventEntity) and FHost.Developer then
      // give a warning in developer mode
      Warning(Format('Function ''%s'' not supported on entity ''%s''', [string(LEvent.Name),
        string(FEntities.NameOf(LEntity - 1))]));
    // always return a safe value when an object doesn't exist
    case LEvent.ReturnType of
      DS_EVENT_INTEGER:
        FProgram.ReturnInteger(0);
      DS_EVENT_FLOAT:
        FProgram.ReturnFloat(0);
      DS_EVENT_VECTOR:
        FProgram.ReturnVector(TIdVec3.Create(0, 0, 0));
      DS_EVENT_STRING:
        FProgram.ReturnString('');
      DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
        FProgram.ReturnEntity(-1);
    end;
    PopParms(AArgSize);
    FEventEntity := nil;
    Exit;
  end;
  if not BuildEventArgs(AFunction, LStart, 4, AArgSize, LArgs) then
    Exit;
  FPopParms := AArgSize;
  FEventEntity.ProcessEvent(LEvent, LArgs);
  if not Assigned(FMultiFrameEvent) then
  begin
    if FPopParms <> 0 then
      PopParms(FPopParms);
    FEventEntity := nil;
  end
  else
    DoneProcessing := True;
  FPopParms := 0;
end;

function TDoomScriptInterpreter.BeginMultiFrameEvent(const AEntity: TDoomScriptEventTarget;
  const AEvent: TDoomScriptEventDef): Boolean;
begin
  if FEventEntity <> AEntity then
    Error('idInterpreter::BeginMultiFrameEvent called with wrong entity');
  if Assigned(FMultiFrameEvent) then
  begin
    if FMultiFrameEvent <> AEvent then
      Error('idInterpreter::BeginMultiFrameEvent called with wrong event');
    Exit(False);
  end;
  FMultiFrameEvent := AEvent;
  Result := True;
end;

procedure TDoomScriptInterpreter.EndMultiFrameEvent(const AEntity: TDoomScriptEventTarget;
  const AEvent: TDoomScriptEventDef);
begin
  if FMultiFrameEvent <> AEvent then
    Error('idInterpreter::EndMultiFrameEvent called with wrong event');
  FMultiFrameEvent := nil;
end;

function TDoomScriptInterpreter.MultiFrameEventInProgress: Boolean;
begin
  Result := Assigned(FMultiFrameEvent);
end;

procedure TDoomScriptInterpreter.CallSysEvent(const AFunction: TDoomScriptFunction; const AArgSize: Integer);
var
  LArgs: TDoomScriptEventArgs;
begin
  if (not Assigned(AFunction)) or not Assigned(AFunction.EventDef) then
    Error('NULL function');
  if not BuildEventArgs(AFunction, FLocalStackUsed - AArgSize, 0, AArgSize, LArgs) then
    Exit;
  FPopParms := AArgSize;
  FThread.ProcessEvent(AFunction.EventDef, LArgs);
  if FPopParms <> 0 then
    PopParms(FPopParms);
  FPopParms := 0;
end;

function TDoomScriptInterpreter.ModuloOrError(const AValue, ADivisor: Single): Single;
var
  LA: Integer;
  LB: Integer;
begin
  LA := TDoomScriptConvert.FloatToInt(AValue);
  LB := TDoomScriptConvert.FloatToInt(ADivisor);
  // a divisor between -1 and 1 is not zero as a float but is as an integer: a crash in the original
  if LB = 0 then
    Error('Divide by zero');
  if LB = -1 then
    Result := 0
  else
    Result := LA mod LB;
end;

function TDoomScriptInterpreter.RunStatements: Boolean;
var
  LA: PByte;
  LB: PByte;
  LC: PByte;
  LP: PByte;
  LStatement: PDoomScriptStatement;
  LStatements: PDoomScriptStatement;
  LRunaway: Integer;
  LObject: TDoomScriptObject;
  LFunction: TDoomScriptFunction;
  LFloat: Single;
  LHandle: Cardinal;
  LEntity: Integer;
  LVecA: PIdVec3;
  LVecB: PIdVec3;
  LVector: TIdVec3;

  function Bool(const AValue: Boolean): Single; inline;
  begin
    if AValue then
      Result := 1.0
    else
      Result := 0.0;
  end;

  function ToInt(const AValue: PByte): Integer; inline;
  begin
    Result := TDoomScriptConvert.FloatToInt(PSingle(AValue)^);
  end;

  // the comparisons of C on the bits of the floats: a NaN is not zero, and is never equal, less or greater
  function NonZero(const AValue: PByte): Boolean; inline;
  begin
    Result := (PCardinal(AValue)^ and $7FFFFFFF) <> 0;
  end;

  function FEq(const AFirst, ASecond: PByte): Boolean; inline;
  begin
    Result := TDoomScriptConvert.FloatEq(PSingle(AFirst)^, PSingle(ASecond)^);
  end;

  function FLt(const AFirst, ASecond: PByte): Boolean; inline;
  begin
    Result := TDoomScriptConvert.FloatLt(PSingle(AFirst)^, PSingle(ASecond)^);
  end;

  function FLe(const AFirst, ASecond: PByte): Boolean; inline;
  begin
    Result := TDoomScriptConvert.FloatLe(PSingle(AFirst)^, PSingle(ASecond)^);
  end;

  function VecEq(const AFirst, ASecond: PByte): Boolean;
  begin
    Result := FEq(AFirst, ASecond) and FEq(AFirst + 4, ASecond + 4) and FEq(AFirst + 8, ASecond + 8);
  end;

begin
  if ThreadDying or not Assigned(FCurrentFunction) then
    Exit(True);
  if Assigned(FMultiFrameEvent) then
    // move to previous instruction and call it again
    Dec(FInstructionPointer);
  LRunaway := DS_RUNAWAY_LIMIT;
  DoneProcessing := False;
  LStatements := FProgram.StatementsBase;
  while (not DoneProcessing) and not ThreadDying do
  begin
    Inc(FInstructionPointer);
    Dec(LRunaway);
    if LRunaway = 0 then
      Error('runaway loop error');
    // next statement
    if Cardinal(FInstructionPointer) >= Cardinal(FProgram.NumStatements) then
      raise EDoomScriptMemoryError.CreateFmt(SBadStatement, [FInstructionPointer]);
    LStatement := LStatements;
    Inc(LStatement, FInstructionPointer);
    case LStatement.Op of
      OP_RETURN:
        LeaveFunction(LStatement.A);
      OP_THREAD:
        begin
          if (LStatement.A = nil) or (LStatement.B = nil) then
            BadOperand;
          // return the thread number to the script
          LFloat := FThread.StartThread(Self, LStatement.A.FunctionPtr, LStatement.B.Value);
          FProgram.ReturnFloat(LFloat);
          PopParms(LStatement.B.Value);
        end;
      OP_OBJTHREAD:
        begin
          if (LStatement.B = nil) or (LStatement.C = nil) then
            BadOperand;
          LObject := GetScriptObject(LStatement.A);
          if Assigned(LObject) then
          begin
            LFunction := LObject.GetTypeDef.GetFunction(LStatement.B.Value);
            LFloat := FThread.StartThread(Self, LFunction, LFunction.ParmTotal);
            FProgram.ReturnFloat(LFloat);
          end
          else
            // return a null thread to the script
            FProgram.ReturnFloat(0.0);
          PopParms(LStatement.C.Value);
        end;
      OP_CALL:
        begin
          if LStatement.A = nil then
            BadOperand;
          EnterFunction(LStatement.A.FunctionPtr, False);
        end;
      OP_EVENTCALL:
        begin
          if (LStatement.A = nil) or (LStatement.B = nil) then
            BadOperand;
          CallEvent(LStatement.A.FunctionPtr, LStatement.B.Value);
        end;
      OP_OBJECTCALL:
        begin
          if (LStatement.B = nil) or (LStatement.C = nil) then
            BadOperand;
          LObject := GetScriptObject(LStatement.A);
          if Assigned(LObject) then
            EnterFunction(LObject.GetTypeDef.GetFunction(LStatement.B.Value), False)
          else
          begin
            // return a 'safe' value
            FProgram.ReturnVector(TIdVec3.Create(0, 0, 0));
            FProgram.ReturnString('');
            PopParms(LStatement.C.Value);
          end;
        end;
      OP_SYSCALL:
        begin
          if (LStatement.A = nil) or (LStatement.B = nil) then
            BadOperand;
          CallSysEvent(LStatement.A.FunctionPtr, LStatement.B.Value);
        end;
      OP_IFNOT:
        begin
          if LStatement.B = nil then
            BadOperand;
          if PInteger(VarPtr(LStatement.A, 4))^ = 0 then
            NextInstruction(FInstructionPointer + LStatement.B.Value);
        end;
      OP_IF:
        begin
          if LStatement.B = nil then
            BadOperand;
          if PInteger(VarPtr(LStatement.A, 4))^ <> 0 then
            NextInstruction(FInstructionPointer + LStatement.B.Value);
        end;
      OP_GOTO:
        begin
          if LStatement.A = nil then
            BadOperand;
          NextInstruction(FInstructionPointer + LStatement.A.Value);
        end;
      OP_ADD_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := PSingle(LA)^ + PSingle(LB)^;
        end;
      OP_ADD_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          LVector := LVecA^ + LVecB^;
          PIdVec3(VarPtr(LStatement.C, 12))^ := LVector;
        end;
      OP_ADD_S:
        begin
          SetString(LStatement.C, GetString(LStatement.A));
          AppendString(LStatement.C, GetString(LStatement.B));
        end;
      OP_ADD_FS:
        begin
          SetString(LStatement.C, TDoomScriptConvert.FloatToString(PSingle(VarPtr(LStatement.A, 4))^));
          AppendString(LStatement.C, GetString(LStatement.B));
        end;
      OP_ADD_SF:
        begin
          LB := VarPtr(LStatement.B, 4);
          SetString(LStatement.C, GetString(LStatement.A));
          AppendString(LStatement.C, TDoomScriptConvert.FloatToString(PSingle(LB)^));
        end;
      OP_ADD_VS:
        begin
          SetString(LStatement.C, PIdVec3(VarPtr(LStatement.A, 12)).ToString);
          AppendString(LStatement.C, GetString(LStatement.B));
        end;
      OP_ADD_SV:
        begin
          LB := VarPtr(LStatement.B, 12);
          SetString(LStatement.C, GetString(LStatement.A));
          AppendString(LStatement.C, PIdVec3(LB).ToString);
        end;
      OP_SUB_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := PSingle(LA)^ - PSingle(LB)^;
        end;
      OP_SUB_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          LVector := LVecA^ - LVecB^;
          PIdVec3(VarPtr(LStatement.C, 12))^ := LVector;
        end;
      OP_MUL_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := PSingle(LA)^ * PSingle(LB)^;
        end;
      OP_MUL_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          LFloat := LVecA^ * LVecB^;
          PSingle(VarPtr(LStatement.C, 4))^ := LFloat;
        end;
      OP_MUL_FV:
        begin
          LA := VarPtr(LStatement.A, 4);
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          LVector := PSingle(LA)^ * LVecB^;
          PIdVec3(VarPtr(LStatement.C, 12))^ := LVector;
        end;
      OP_MUL_VF:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LB := VarPtr(LStatement.B, 4);
          LVector := LVecA^ * PSingle(LB)^;
          PIdVec3(VarPtr(LStatement.C, 12))^ := LVector;
        end;
      OP_DIV_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          LC := VarPtr(LStatement.C, 4);
          if not NonZero(LB) then
          begin
            Warning('Divide by zero');
            PSingle(LC)^ := ID_INFINITY;
          end
          else
            PSingle(LC)^ := PSingle(LA)^ / PSingle(LB)^;
        end;
      OP_MOD_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          LC := VarPtr(LStatement.C, 4);
          if not NonZero(LB) then
          begin
            Warning('Divide by zero');
            PSingle(LC)^ := PSingle(LA)^;
          end
          else
            PSingle(LC)^ := ModuloOrError(PSingle(LA)^, PSingle(LB)^);
        end;
      OP_BITAND:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := ToInt(LA) and ToInt(LB);
        end;
      OP_BITOR:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := ToInt(LA) or ToInt(LB);
        end;
      OP_GE:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(FLe(LB, LA));
        end;
      OP_LE:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(FLe(LA, LB));
        end;
      OP_GT:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(FLt(LB, LA));
        end;
      OP_LT:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(FLt(LA, LB));
        end;
      OP_AND:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(NonZero(LA) and NonZero(LB));
        end;
      OP_AND_BOOLF:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool((PInteger(LA)^ <> 0) and NonZero(LB));
        end;
      OP_AND_FBOOL:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(NonZero(LA) and (PInteger(LB)^ <> 0));
        end;
      OP_AND_BOOLBOOL:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool((PInteger(LA)^ <> 0) and (PInteger(LB)^ <> 0));
        end;
      OP_OR:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(NonZero(LA) or NonZero(LB));
        end;
      OP_OR_BOOLF:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool((PInteger(LA)^ <> 0) or NonZero(LB));
        end;
      OP_OR_FBOOL:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(NonZero(LA) or (PInteger(LB)^ <> 0));
        end;
      OP_OR_BOOLBOOL:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool((PInteger(LA)^ <> 0) or (PInteger(LB)^ <> 0));
        end;
      OP_NOT_BOOL:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(PInteger(LA)^ = 0);
        end;
      OP_NOT_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(not NonZero(LA));
        end;
      OP_NOT_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(not (NonZero(PByte(LVecA)) or NonZero(PByte(LVecA) + 4) or NonZero(PByte(LVecA) + 8)));
        end;
      OP_NOT_S:
        begin
          LC := VarPtr(LStatement.C, 4);
          PSingle(LC)^ := Bool(VarPtr(LStatement.A, DS_MAX_STRING_LEN)^ = 0);
        end;
      OP_NOT_ENT:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(FEntities.GetEntity(PInteger(LA)^) = nil);
        end;
      OP_NEG_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := -PSingle(LA)^;
        end;
      OP_NEG_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVector := -LVecA^;
          PIdVec3(VarPtr(LStatement.C, 12))^ := LVector;
        end;
      OP_INT_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := ToInt(LA);
        end;
      OP_EQ_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(FEq(LA, LB));
        end;
      OP_EQ_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(VecEq(PByte(LVecA), PByte(LVecB)));
        end;
      OP_EQ_S:
        begin
          LC := VarPtr(LStatement.C, 4);
          PSingle(LC)^ := Bool(GetString(LStatement.A) = GetString(LStatement.B));
        end;
      OP_EQ_E, OP_EQ_EO, OP_EQ_OE, OP_EQ_OO:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(PInteger(LA)^ = PInteger(LB)^);
        end;
      OP_NE_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(not FEq(LA, LB));
        end;
      OP_NE_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(not VecEq(PByte(LVecA), PByte(LVecB)));
        end;
      OP_NE_S:
        begin
          LC := VarPtr(LStatement.C, 4);
          PSingle(LC)^ := Bool(GetString(LStatement.A) <> GetString(LStatement.B));
        end;
      OP_NE_E, OP_NE_EO, OP_NE_OE, OP_NE_OO:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := Bool(PInteger(LA)^ <> PInteger(LB)^);
        end;
      OP_UADD_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(LB)^ := PSingle(LB)^ + PSingle(LA)^;
        end;
      OP_UADD_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          LVector := LVecB^ + LVecA^;
          LVecB^ := LVector;
        end;
      OP_USUB_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(LB)^ := PSingle(LB)^ - PSingle(LA)^;
        end;
      OP_USUB_V:
        begin
          LVecA := PIdVec3(VarPtr(LStatement.A, 12));
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          LVector := LVecB^ - LVecA^;
          LVecB^ := LVector;
        end;
      OP_UMUL_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(LB)^ := PSingle(LB)^ * PSingle(LA)^;
        end;
      OP_UMUL_V:
        begin
          LA := VarPtr(LStatement.A, 4);
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          LVector := LVecB^ * PSingle(LA)^;
          LVecB^ := LVector;
        end;
      OP_UDIV_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          if not NonZero(LA) then
          begin
            Warning('Divide by zero');
            PSingle(LB)^ := ID_INFINITY;
          end
          else
            PSingle(LB)^ := PSingle(LB)^ / PSingle(LA)^;
        end;
      OP_UDIV_V:
        begin
          LA := VarPtr(LStatement.A, 4);
          LVecB := PIdVec3(VarPtr(LStatement.B, 12));
          if not NonZero(LA) then
          begin
            Warning('Divide by zero');
            LVecB.SetValues(ID_INFINITY, ID_INFINITY, ID_INFINITY);
          end
          else
          begin
            LVector := LVecB^ / PSingle(LA)^;
            LVecB^ := LVector;
          end;
        end;
      OP_UMOD_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          if not NonZero(LA) then
          begin
            Warning('Divide by zero');
            // as in the original: the variable takes the divisor, not its old value
            PSingle(LB)^ := PSingle(LA)^;
          end
          else
            PSingle(LB)^ := ModuloOrError(PSingle(LB)^, PSingle(LA)^);
        end;
      OP_UOR_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(LB)^ := ToInt(LB) or ToInt(LA);
        end;
      OP_UAND_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          PSingle(LB)^ := ToInt(LB) and ToInt(LA);
        end;
      OP_UINC_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(LA)^ := PSingle(LA)^ + 1.0;
        end;
      OP_UINCP_F:
        begin
          LObject := GetScriptObject(LStatement.A);
          if Assigned(LObject) then
          begin
            LP := FieldPtr(LObject, LStatement.B, 4);
            PSingle(LP)^ := PSingle(LP)^ + 1.0;
          end;
        end;
      OP_UDEC_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(LA)^ := PSingle(LA)^ - 1.0;
        end;
      OP_UDECP_F:
        begin
          LObject := GetScriptObject(LStatement.A);
          if Assigned(LObject) then
          begin
            LP := FieldPtr(LObject, LStatement.B, 4);
            PSingle(LP)^ := PSingle(LP)^ - 1.0;
          end;
        end;
      OP_COMP_F:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(VarPtr(LStatement.C, 4))^ := not ToInt(LA);
        end;
      OP_STORE_F, OP_STORE_ENT, OP_STORE_BOOL, OP_STORE_OBJ, OP_STORE_ENTOBJ:
        begin
          LA := VarPtr(LStatement.A, 4);
          PInteger(VarPtr(LStatement.B, 4))^ := PInteger(LA)^;
        end;
      OP_STORE_OBJENT:
        begin
          LA := VarPtr(LStatement.A, 4);
          LB := VarPtr(LStatement.B, 4);
          LObject := FEntities.GetScriptObject(PInteger(LA)^);
          if (not Assigned(LObject)) or not LObject.GetTypeDef.Inherits(LStatement.B.TypeDef) then
            PInteger(LB)^ := 0
          else
            PInteger(LB)^ := PInteger(LA)^;
        end;
      OP_STORE_S:
        SetString(LStatement.B, GetString(LStatement.A));
      OP_STORE_V:
        begin
          LA := VarPtr(LStatement.A, 12);
          Move(LA^, VarPtr(LStatement.B, 12)^, 12);
        end;
      OP_STORE_FTOS:
        SetString(LStatement.B, TDoomScriptConvert.FloatToString(PSingle(VarPtr(LStatement.A, 4))^));
      OP_STORE_BTOS:
        if PInteger(VarPtr(LStatement.A, 4))^ <> 0 then
          SetString(LStatement.B, 'true')
        else
          SetString(LStatement.B, 'false');
      OP_STORE_VTOS:
        SetString(LStatement.B, PIdVec3(VarPtr(LStatement.A, 12)).ToString);
      OP_STORE_FTOBOOL:
        begin
          LA := VarPtr(LStatement.A, 4);
          PInteger(VarPtr(LStatement.B, 4))^ := Ord(NonZero(LA));
        end;
      OP_STORE_BOOLTOF:
        begin
          LA := VarPtr(LStatement.A, 4);
          PSingle(VarPtr(LStatement.B, 4))^ := PInteger(LA)^;
        end;
      OP_STOREP_F, OP_STOREP_ENT, OP_STOREP_FLD, OP_STOREP_BOOL, OP_STOREP_OBJ:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
          begin
            LP := DerefPointer(LHandle, 4);
            PInteger(LP)^ := PInteger(VarPtr(LStatement.A, 4))^;
          end;
        end;
      OP_STOREP_S:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
            TDoomScriptMemory.CopyString(DerefPointer(LHandle, DS_MAX_STRING_LEN), GetString(LStatement.A));
        end;
      OP_STOREP_V:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
          begin
            LP := DerefPointer(LHandle, 12);
            Move(VarPtr(LStatement.A, 12)^, LP^, 12);
          end;
        end;
      OP_STOREP_FTOS:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
            TDoomScriptMemory.CopyString(DerefPointer(LHandle, DS_MAX_STRING_LEN),
              TDoomScriptConvert.FloatToString(PSingle(VarPtr(LStatement.A, 4))^));
        end;
      OP_STOREP_BTOS:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
          begin
            LP := DerefPointer(LHandle, DS_MAX_STRING_LEN);
            // as in the original, the boolean is read as a float here
            if NonZero(VarPtr(LStatement.A, 4)) then
              TDoomScriptMemory.CopyString(LP, 'true')
            else
              TDoomScriptMemory.CopyString(LP, 'false');
          end;
        end;
      OP_STOREP_VTOS:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
            TDoomScriptMemory.CopyString(DerefPointer(LHandle, DS_MAX_STRING_LEN),
              PIdVec3(VarPtr(LStatement.A, 12)).ToString);
        end;
      OP_STOREP_FTOBOOL:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
          begin
            LP := DerefPointer(LHandle, 4);
            PInteger(LP)^ := Ord(NonZero(VarPtr(LStatement.A, 4)));
          end;
        end;
      OP_STOREP_BOOLTOF:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
          begin
            LP := DerefPointer(LHandle, 4);
            PSingle(LP)^ := PInteger(VarPtr(LStatement.A, 4))^;
          end;
        end;
      OP_STOREP_OBJENT:
        begin
          LHandle := PCardinal(VarPtr(LStatement.B, 4))^;
          if LHandle <> 0 then
          begin
            LP := DerefPointer(LHandle, 4);
            LA := VarPtr(LStatement.A, 4);
            LObject := FEntities.GetScriptObject(PInteger(LA)^);
            if LStatement.C = nil then
              BadOperand;
            // the real type of the field is in c: the type of b is a temporary of the compiler
            if (not Assigned(LObject)) or not LObject.GetTypeDef.Inherits(LStatement.C.TypeDef) then
              PInteger(LP)^ := 0
            else
              PInteger(LP)^ := PInteger(LA)^;
          end;
        end;
      OP_ADDRESS:
        begin
          LA := VarPtr(LStatement.A, 4);
          LC := VarPtr(LStatement.C, 4);
          LEntity := PInteger(LA)^;
          LObject := FEntities.GetScriptObject(LEntity);
          if Assigned(LObject) then
          begin
            if LStatement.B = nil then
              BadOperand;
            // checks the offset now, then keeps the entity and the offset as the pointer
            LObject.DataPtr(LStatement.B.Value, 0);
            PCardinal(LC)^ := POINTER_FLAG or (Cardinal(LEntity - 1) shl POINTER_OFFSET_BITS) or
              Cardinal(LStatement.B.Value);
          end
          else
            PCardinal(LC)^ := 0;
        end;
      OP_INDIRECT_F, OP_INDIRECT_ENT, OP_INDIRECT_BOOL, OP_INDIRECT_OBJ:
        begin
          LC := VarPtr(LStatement.C, 4);
          LObject := GetScriptObject(LStatement.A);
          if Assigned(LObject) then
            PInteger(LC)^ := PInteger(FieldPtr(LObject, LStatement.B, 4))^
          else
            PInteger(LC)^ := 0;
        end;
      OP_INDIRECT_S:
        begin
          LObject := GetScriptObject(LStatement.A);
          if Assigned(LObject) then
            SetString(LStatement.C, TDoomScriptMemory.ReadString(FieldPtr(LObject, LStatement.B, DS_MAX_STRING_LEN)))
          else
            SetString(LStatement.C, '');
        end;
      OP_INDIRECT_V:
        begin
          LC := VarPtr(LStatement.C, 12);
          LObject := GetScriptObject(LStatement.A);
          if Assigned(LObject) then
            Move(FieldPtr(LObject, LStatement.B, 12)^, LC^, 12)
          else
            FillChar(LC^, 12, 0);
        end;
      OP_PUSH_F, OP_PUSH_ENT, OP_PUSH_OBJ, OP_PUSH_OBJENT:
        Push(PInteger(VarPtr(LStatement.A, 4))^);
      OP_PUSH_FTOS:
        PushString(TDoomScriptConvert.FloatToString(PSingle(VarPtr(LStatement.A, 4))^));
      OP_PUSH_BTOF:
        begin
          LFloat := PInteger(VarPtr(LStatement.A, 4))^;
          Push(PInteger(@LFloat)^);
        end;
      OP_PUSH_FTOB:
        if NonZero(VarPtr(LStatement.A, 4)) then
          Push(1)
        else
          Push(0);
      OP_PUSH_VTOS:
        PushString(PIdVec3(VarPtr(LStatement.A, 12)).ToString);
      OP_PUSH_BTOS:
        if PInteger(VarPtr(LStatement.A, 4))^ <> 0 then
          PushString('true')
        else
          PushString('false');
      OP_PUSH_S:
        PushString(GetString(LStatement.A));
      OP_PUSH_V:
        begin
          LA := VarPtr(LStatement.A, 12);
          Push(PInteger(LA)^);
          Push(PInteger(LA + 4)^);
          Push(PInteger(LA + 8)^);
        end;
    else
      Error(Format('Bad opcode %d', [LStatement.Op]));
    end;
  end;
  Result := ThreadDying;
end;

function TDoomScriptInterpreter.Execute: Boolean;
var
  LSavedMask: TArithmeticExceptionMask;
begin
  // the arithmetic of a script gives infinities and NaN as in C, never a floating point exception
  LSavedMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    Result := RunStatements;
  finally
    SetExceptionMask(LSavedMask);
  end;
end;

end.
