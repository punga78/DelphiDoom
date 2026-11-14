{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - dumps of the parity     }
{  driver                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Parity.Dump;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs,
  DelphiDoom.DoomScript.Machine, DelphiDoom.Tests.DoomScript.Parity.Output,
  DelphiDoom.Tests.DoomScript.Parity.Game;

type
  /// <summary>
  ///   The dumps of the C++ harness (dumpProgram, dumpThreads, dumpEvents, dumpEntities, dumpReturn,
  ///   doSave, doRestore of Tools\Verifica\110\main.cpp) on the script machine of the library: the same
  ///   lines, in the same order.
  /// </summary>
  TDoomScriptParityDump = class
  strict private
    FGame: TDoomScriptParityGame;
    FMachine: TDoomScriptMachine;
    FOutput: TDoomScriptParityOutput;
    FLastSave: TBytes;
    function DefRef(const ADef: TDoomScriptVarDef): AnsiString;
    function DefValue(const ADef: TDoomScriptVarDef): AnsiString;
  public
    constructor Create(const AGame: TDoomScriptParityGame);
    function FuncIndex(const AFunction: TDoomScriptFunction): Integer;
    procedure Statements(const AFirst, ACount: Integer);
    procedure Globals;
    procedure ScriptProgram;
    procedure Threads(const AWithCalls: Boolean);
    procedure Stacks;
    procedure Events;
    procedure Entities;
    procedure ReturnValue;
    procedure Save;
    procedure Restore;
  end;

  /// <summary>An error of the driver itself ("harness: ..." in the goldens)</summary>
  EDoomScriptParityHarness = class(Exception);

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.EventQueue, DelphiDoom.DoomScript.Opcodes, DelphiDoom.DoomScript.ScriptProgram,
  DelphiDoom.DoomScript.ScriptObject, DelphiDoom.DoomScript.Interpreter, DelphiDoom.DoomScript.Thread,
  DelphiDoom.DoomScript.SaveStream, DelphiDoom.Tests.DoomScript.Parity.Entity;

type
  TOut = TDoomScriptParityOutput;

constructor TDoomScriptParityDump.Create(const AGame: TDoomScriptParityGame);
begin
  inherited Create;
  FGame := AGame;
  FMachine := AGame.Machine;
  FOutput := AGame.Output;
end;

function TDoomScriptParityDump.FuncIndex(const AFunction: TDoomScriptFunction): Integer;
begin
  if not Assigned(AFunction) then
    Exit(-1);
  Result := FMachine.ScriptProgram.GetFunctionIndex(AFunction);
  if Result < 0 then
    Result := -2;
end;

function TDoomScriptParityDump.DefRef(const ADef: TDoomScriptVarDef): AnsiString;
var
  LProgram: TDoomScriptProgram;
begin
  if not Assigned(ADef) then
    Exit('-');
  LProgram := FMachine.ScriptProgram;
  if (ADef.Num >= 0) and (ADef.Num < LProgram.NumDefs) and (LProgram.GetDefByIndex(ADef.Num) = ADef) then
    Exit(TOut.Num(ADef.Num));
  if Assigned(ADef.TypeDef) then
    Result := '@' + ADef.TypeDef.Name
  else
    Result := '@?';
end;

function TDoomScriptParityDump.DefValue(const ADef: TDoomScriptVarDef): AnsiString;
var
  LProgram: TDoomScriptProgram;
  LVector: TIdVec3;
begin
  LProgram := FMachine.ScriptProgram;
  if ADef.Initialized = diStackVariable then
    Exit('stack:' + TOut.Num(ADef.Value));
  case ADef.Kind of
    evFunction:
      Exit('func:' + TOut.Num(FuncIndex(ADef.FunctionPtr)));
    evJumpOffset:
      Exit('jump:' + TOut.Num(ADef.Value));
    evArgSize:
      Exit('args:' + TOut.Num(ADef.Value));
    evVirtualFunction:
      Exit('virt:' + TOut.Num(ADef.Value));
  end;
  if Assigned(ADef.Scope) and Assigned(ADef.Scope.TypeDef) and ADef.Scope.TypeDef.Inherits(LProgram.TypeObject) then
    Exit('ptr:' + TOut.Num(ADef.Value));
  if (ADef.Value < 0) or (ADef.Value > DS_MAX_GLOBALS) then
    Exit('?');
  Result := 'global:' + TOut.Num(ADef.Value);
  case ADef.Kind of
    evFloat:
      Result := Result + '=' + TOut.FloatBits(PSingle(LProgram.GlobalPtr(ADef.Value, 4))^);
    evVector:
      begin
        Move(LProgram.GlobalPtr(ADef.Value, 12)^, LVector, 12);
        Result := Result + '=' + TOut.Vec3(LVector);
      end;
    evString:
      Result := Result + '=' + TOut.Quoted(TDoomScriptMemory.ReadString(LProgram.GlobalPtr(ADef.Value,
        DS_MAX_STRING_LEN)));
    evEntity, evBoolean, evObject, evField, evPointer:
      Result := Result + '=' + TOut.Num(PInteger(LProgram.GlobalPtr(ADef.Value, 4))^);
  end;
end;

procedure TDoomScriptParityDump.Statements(const AFirst, ACount: Integer);
var
  LProgram: TDoomScriptProgram;
  LIndex: Integer;
  LStatement: PDoomScriptStatement;
begin
  LProgram := FMachine.ScriptProgram;
  LIndex := AFirst;
  while (LIndex < AFirst + ACount) and (LIndex < LProgram.NumStatements) do
  begin
    LStatement := LProgram.GetStatement(LIndex);
    FOutput.Line('STMT ' + TOut.Num(LIndex) + ' ' + DoomScriptOpcodes[LStatement.Op].OpName + ' a=' +
      DefRef(LStatement.A) + ' b=' + DefRef(LStatement.B) + ' c=' + DefRef(LStatement.C) + ' line=' +
      TOut.Num(LStatement.LineNumber) + ' file=' + TOut.Num(LStatement.FileNum));
    Inc(LIndex);
  end;
end;

procedure TDoomScriptParityDump.Globals;
var
  LProgram: TDoomScriptProgram;
  LOffset: Integer;
  LCount: Integer;
  LIndex: Integer;
  LZero: Boolean;
  LBase: PByte;
begin
  LProgram := FMachine.ScriptProgram;
  FOutput.Line('GLOBALS ' + TOut.Num(LProgram.NumVariables));
  LBase := LProgram.GlobalsBase;
  LOffset := 0;
  while LOffset < LProgram.NumVariables do
  begin
    LCount := LProgram.NumVariables - LOffset;
    if LCount > 32 then
      LCount := 32;
    LZero := True;
    for LIndex := 0 to LCount - 1 do
      if LBase[LOffset + LIndex] <> 0 then
        LZero := False;
    if not LZero then
      FOutput.Line('G ' + AnsiString(IntToHex(LOffset, 6)) + ' ' + TOut.Hex(LBase + LOffset, LCount));
    Inc(LOffset, 32);
  end;
end;

procedure TDoomScriptParityDump.ScriptProgram;
var
  LProgram: TDoomScriptProgram;
  LIndex: Integer;
  LInner: Integer;
  LText: AnsiString;
  LType: TDoomScriptTypeDef;
  LDef: TDoomScriptVarDef;
  LFunction: TDoomScriptFunction;
begin
  LProgram := FMachine.ScriptProgram;
  for LIndex := 0 to LProgram.NumFilenames - 1 do
    FOutput.Line('FILE ' + TOut.Num(LIndex) + ' ' + TOut.Esc(LProgram.GetFilename(LIndex)));
  for LIndex := 0 to LProgram.NumTypes - 1 do
  begin
    LType := LProgram.GetTypeByIndex(LIndex);
    LText := 'TYPE ' + TOut.Num(LIndex) + ' name=' + TOut.Quoted(LType.Name) + ' etype=' + TOut.Num(Ord(LType.Kind)) +
      ' size=' + TOut.Num(LType.Size) + ' aux=';
    if Assigned(LType.AuxType) then
      LText := LText + TOut.Esc(LType.AuxType.Name)
    else
      LText := LText + '-';
    LText := LText + ' def=' + DefRef(LType.Def) + ' parms=[';
    for LInner := 0 to LType.NumParameters - 1 do
    begin
      if LInner > 0 then
        LText := LText + ',';
      LText := LText + TOut.Esc(LType.GetParmType(LInner).Name) + ':' + TOut.Esc(LType.GetParmName(LInner));
    end;
    LText := LText + '] funcs=[';
    for LInner := 0 to LType.NumFunctions - 1 do
    begin
      if LInner > 0 then
        LText := LText + ',';
      LText := LText + TOut.Num(FuncIndex(LType.GetFunction(LInner)));
    end;
    FOutput.Line(LText + ']');
  end;
  for LIndex := 0 to LProgram.NumDefs - 1 do
  begin
    LDef := LProgram.GetDefByIndex(LIndex);
    FOutput.Line('DEF ' + TOut.Num(LDef.Num) + ' name=' + TOut.Quoted(LDef.Name) + ' type=' +
      TOut.Esc(LDef.TypeDef.Name) + '/' + TOut.Num(Ord(LDef.Kind)) + ' scope=' + DefRef(LDef.Scope) + ' init=' +
      TOut.Num(Ord(LDef.Initialized)) + ' users=' + TOut.Num(LDef.NumUsers) + ' value=' + DefValue(LDef));
  end;
  for LIndex := 0 to LProgram.NumFunctions - 1 do
  begin
    LFunction := LProgram.GetFunction(LIndex);
    LText := 'FUNC ' + TOut.Num(LIndex) + ' name=' + TOut.Quoted(LFunction.Name) + ' event=';
    if Assigned(LFunction.EventDef) then
      LText := LText + TOut.Esc(LFunction.EventDef.Name)
    else
      LText := LText + '-';
    LText := LText + ' def=' + DefRef(LFunction.Def) + ' first=' + TOut.Num(LFunction.FirstStatement) + ' num=' +
      TOut.Num(LFunction.NumStatements) + ' parmTotal=' + TOut.Num(LFunction.ParmTotal) + ' locals=' +
      TOut.Num(LFunction.Locals) + ' filenum=' + TOut.Num(LFunction.FileNum) + ' parmSize=[';
    for LInner := 0 to Length(LFunction.ParmSize) - 1 do
    begin
      if LInner > 0 then
        LText := LText + ',';
      LText := LText + TOut.Num(LFunction.ParmSize[LInner]);
    end;
    FOutput.Line(LText + ']');
  end;
  Statements(0, LProgram.NumStatements);
  FOutput.Line('TOP functions=' + TOut.Num(LProgram.TopFunctions) + ' statements=' + TOut.Num(LProgram.TopStatements) +
    ' types=' + TOut.Num(LProgram.TopTypes) + ' defs=' + TOut.Num(LProgram.TopDefs) + ' files=' +
    TOut.Num(LProgram.TopFiles));
  Globals;
  FOutput.Line('CHECKSUM ' + AnsiString(IntToHex(Cardinal(LProgram.CalculateChecksum), 8)));
end;

procedure TDoomScriptParityDump.Threads(const AWithCalls: Boolean);
var
  LIndex: Integer;
  LInner: Integer;
  LThread: TDoomScriptThread;
  LInterpreter: TDoomScriptInterpreter;
  LText: AnsiString;
  LWaiting: Integer;
  LPair: TIdKeyValue;
  LFrame: TDoomScriptCallFrame;
begin
  if AWithCalls then
  begin
    FOutput.Line('CURRENT ' + TOut.Num(TDoomScriptThread.CurrentThreadNum(FMachine.Context)));
    FOutput.Line('THREADINDEX ' + TOut.Num(FMachine.Context.ThreadIndex));
  end;
  for LIndex := 0 to FMachine.NumThreads - 1 do
  begin
    LThread := FMachine.ThreadAt(LIndex);
    LInterpreter := LThread.Interpreter;
    LWaiting := 0;
    if LThread.WaitingOnThread <> nil then
      LWaiting := LThread.WaitingOnThread.ThreadNum;
    LText := 'THREAD ' + TOut.Num(LThread.ThreadNum) + ' name=' + TOut.Quoted(LThread.GetThreadName) + ' dying=' +
      TOut.Num(Ord(LInterpreter.ThreadDying)) + ' done=' + TOut.Num(Ord(LInterpreter.DoneProcessing)) +
      ' waitingFor=' + TOut.Num(LThread.WaitingFor) + ' waitingUntil=' + TOut.Num(LThread.WaitingUntil) +
      ' waitingForThread=' + TOut.Num(LWaiting) + ' lastExec=' + TOut.Num(LThread.LastExecuteTime) + ' created=' +
      TOut.Num(LThread.CreationTime) + ' manual=' + TOut.Num(Ord(LThread.IsManualControl)) + ' depth=' +
      TOut.Num(LInterpreter.GetCallstackDepth) + ' used=' + TOut.Num(LInterpreter.LocalStackUsed) + ' base=' +
      TOut.Num(LInterpreter.LocalStackBase) + ' maxDepth=' + TOut.Num(LInterpreter.MaxStackDepth) + ' maxUsed=' +
      TOut.Num(LInterpreter.MaxLocalStackUsed) + ' ip=' + TOut.Num(LInterpreter.InstructionPointer) + ' func=' +
      TOut.Num(FuncIndex(LInterpreter.GetCurrentFunction)) + ' popParms=' + TOut.Num(LInterpreter.PopParmsPending) +
      ' multiFrame=';
    if Assigned(LInterpreter.MultiFrameEvent) then
      LText := LText + TOut.Esc(LInterpreter.MultiFrameEvent.Name)
    else
      LText := LText + '-';
    LText := LText + ' eventEntity=';
    if Assigned(LInterpreter.EventEntity) then
      LText := LText + TOut.Num(FMachine.Entities.NumberOf(LInterpreter.EventEntity))
    else
      LText := LText + '-';
    LText := LText + ' terminateOnExit=' + TOut.Num(Ord(LInterpreter.TerminateOnExit)) + ' debug=' +
      TOut.Num(Ord(LInterpreter.Debug)) + ' spawnArgs=[';
    for LInner := 0 to LThread.SpawnArgs.GetNumKeyVals - 1 do
      if LThread.SpawnArgs.TryGetKeyVal(LInner, LPair) then
      begin
        if LInner > 0 then
          LText := LText + ',';
        LText := LText + TOut.Esc(LPair.Key) + '=' + TOut.Esc(LPair.Value);
      end;
    FOutput.Line(LText + ']');
    if AWithCalls then
    begin
      LInner := 0;
      while (LInner < LInterpreter.GetCallstackDepth) and (LInner < DS_MAX_STACK_DEPTH) do
      begin
        LFrame := LInterpreter.GetCallFrame(LInner);
        FOutput.Line('CALL ' + TOut.Num(LInner) + ' s=' + TOut.Num(LFrame.Statement) + ' f=' +
          TOut.Num(FuncIndex(LFrame.Func)) + ' base=' + TOut.Num(LFrame.StackBase));
        Inc(LInner);
      end;
    end;
  end;
end;

procedure TDoomScriptParityDump.Stacks;
var
  LIndex: Integer;
  LThread: TDoomScriptThread;
begin
  for LIndex := 0 to FMachine.NumThreads - 1 do
  begin
    LThread := FMachine.ThreadAt(LIndex);
    FOutput.Line('STACK ' + TOut.Num(LThread.ThreadNum) + ' ' + TOut.Hex(LThread.Interpreter.LocalStackBytes));
  end;
end;

procedure TDoomScriptParityDump.Events;
var
  LIndex: Integer;
  LArg: Integer;
  LEvent: TDoomScriptQueuedEvent;
  LDef: TDoomScriptEventDef;
  LData: TBytes;
  LOffset: Integer;
  LObject: AnsiString;
  LText: AnsiString;
begin
  for LIndex := 0 to FMachine.Queue.Count - 1 do
  begin
    LEvent := FMachine.Queue.GetEvent(LIndex);
    LDef := LEvent.EventDef;
    if LEvent.Target is TDoomScriptThread then
      LObject := 'thread:' + TOut.Num(TDoomScriptThread(LEvent.Target).ThreadNum)
    else
      LObject := 'ent:' + TOut.Num(TDoomScriptParityEntity(LEvent.Target).EntityNumber);
    // the data block of the event of the original, rebuilt from the arguments
    SetLength(LData, 0);
    SetLength(LData, LDef.ArgSize);
    for LArg := 0 to LDef.GetNumArgs - 1 do
    begin
      LOffset := LDef.GetArgOffset(LArg);
      case LDef.ArgFormat[LArg + 1] of
        DS_EVENT_FLOAT:
          Move(LEvent.Args[LArg].FloatValue, LData[LOffset], 4);
        DS_EVENT_INTEGER:
          Move(LEvent.Args[LArg].IntValue, LData[LOffset], 4);
        DS_EVENT_VECTOR:
          Move(LEvent.Args[LArg].VectorValue, LData[LOffset], 12);
        DS_EVENT_STRING:
          begin
            LText := LEvent.Args[LArg].StringValue;
            if LText <> '' then
              Move(LText[1], LData[LOffset], Length(LText));
          end;
        DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
          Move(LEvent.EntityPtrs[LArg], LData[LOffset], 4);
      end;
    end;
    FOutput.Line('EVENT time=' + TOut.Num(LEvent.Time) + ' name=' + TOut.Esc(LDef.Name) + ' class=' +
      LEvent.TargetClass.Name + ' object=' + LObject + ' args=' + TOut.Hex(LData));
  end;
end;

procedure TDoomScriptParityDump.Entities;
var
  LIndex: Integer;
  LEntity: TDoomScriptParityEntity;
  LObject: TDoomScriptObject;
  LText: AnsiString;
begin
  for LIndex := 0 to DS_MAX_GENTITIES - 1 do
  begin
    LEntity := FGame.EntityAt(LIndex);
    if not Assigned(LEntity) then
      Continue;
    LObject := FGame.ScriptObjectOf(LEntity);
    LText := 'ENTITY ' + TOut.Num(LIndex) + ' class=' + LEntity.EventClass.Name + ' name=' + TOut.Quoted(LEntity.Name) +
      ' value=' + TOut.FloatBits(LEntity.Value) + ' origin=' + TOut.Vec3(LEntity.Origin) + ' owner=' +
      TOut.Num(LEntity.Owner) + ' object=';
    if LObject.HasObject then
      LText := LText + TOut.Esc(LObject.GetTypeName) + ' data=' + TOut.Hex(LObject.DataPtr(0, LObject.DataSize),
        LObject.DataSize)
    else
      LText := LText + '- data=';
    FOutput.Line(LText);
  end;
end;

procedure TDoomScriptParityDump.ReturnValue;
var
  LProgram: TDoomScriptProgram;
  LWords: PCardinal;
begin
  LProgram := FMachine.ScriptProgram;
  if not Assigned(LProgram.ReturnDef) then
  begin
    FOutput.Line('RETURN -');
    Exit;
  end;
  LWords := PCardinal(LProgram.GlobalPtr(LProgram.ReturnDef.Value, 12));
  FOutput.Line(AnsiString(Format('RETURN %.8X %.8X %.8X ', [PCardinal(PByte(LWords))^, PCardinal(PByte(LWords) + 4)^,
    PCardinal(PByte(LWords) + 8)^])) + TOut.Quoted(TDoomScriptMemory.ReadString(LProgram.GlobalPtr(
    LProgram.ReturnStringDef.Value, DS_MAX_STRING_LEN))));
end;

procedure TDoomScriptParityDump.Save;
var
  LStream: TBytesStream;
  LIndex: Integer;
  LStart: Integer;
  LStackAt: Integer;
  LUsed: Integer;
  LMark: Integer;
  LThread: TDoomScriptThread;
  LNoStack: TBytes;
  LEntity: TDoomScriptParityEntity;

  function Part(const AFrom, ACount: Integer): TBytes;
  begin
    Result := Copy(LStream.Bytes, AFrom, ACount);
  end;

begin
  LStream := TBytesStream.Create;
  try
    FMachine.ScriptProgram.Save(LStream);
    FOutput.Line('SAVE program ' + TOut.Hex(Part(0, LStream.Position)));
    TDoomScriptSaveStream.WriteInt(LStream, FMachine.NumThreads);
    for LIndex := 0 to FMachine.NumThreads - 1 do
    begin
      LThread := FMachine.ThreadAt(LIndex);
      LStart := LStream.Position;
      LThread.Save(LStream, FMachine.WriteObject);
      // the local stack is the block after threadNum, waitingForThread, waitingFor, waitingUntil (16 bytes),
      // callStackDepth (4), the call stack (12 bytes each), maxStackDepth (4) and localstackUsed (4)
      LStackAt := LStart + 16 + 4 + LThread.Interpreter.GetCallstackDepth * 12 + 4 + 4;
      LUsed := LThread.Interpreter.LocalStackUsed;
      LNoStack := Part(LStart, LStackAt - LStart) + Part(LStackAt + LUsed, LStream.Position - LStackAt - LUsed);
      FOutput.Line('SAVE thread ' + TOut.Num(LIndex) + ' ' + TOut.Hex(LNoStack));
      FOutput.Line('SAVE stack ' + TOut.Num(LIndex) + ' ' + TOut.Hex(Part(LStackAt, LUsed)));
    end;
    LMark := LStream.Position;
    FMachine.Queue.Save(LStream, FMachine.WriteObject);
    FOutput.Line('SAVE events ' + TOut.Hex(Part(LMark, LStream.Position - LMark)));
    LMark := LStream.Position;
    for LIndex := 0 to DS_MAX_GENTITIES - 1 do
    begin
      LEntity := FGame.EntityAt(LIndex);
      if Assigned(LEntity) then
      begin
        TDoomScriptSaveStream.WriteInt(LStream, LIndex);
        FGame.ScriptObjectOf(LEntity).Save(LStream);
      end;
    end;
    TDoomScriptSaveStream.WriteInt(LStream, -1);
    FOutput.Line('SAVE objects ' + TOut.Hex(Part(LMark, LStream.Position - LMark)));
    FLastSave := Part(0, LStream.Position);
  finally
    LStream.Free;
  end;
end;

procedure TDoomScriptParityDump.Restore;
var
  LStream: TBytesStream;
  LCount: Integer;
  LIndex: Integer;
  LOk: Boolean;
begin
  LStream := TBytesStream.Create(Copy(FLastSave));
  try
    FMachine.ScriptProgram.Restart;
    FMachine.Queue.Clear;
    LOk := FMachine.ScriptProgram.Restore(LStream);
    FOutput.Line('RESTORE program ' + TOut.Num(Ord(LOk)));
    LCount := TDoomScriptSaveStream.ReadInt(LStream);
    for LIndex := 0 to LCount - 1 do
      FMachine.CreateThread;
    for LIndex := 0 to LCount - 1 do
      FMachine.ThreadAt(LIndex).Restore(LStream, FMachine.ReadObject);
    FMachine.Queue.Restore(LStream, FMachine.ReadObject);
    while True do
    begin
      LIndex := TDoomScriptSaveStream.ReadInt(LStream);
      if LIndex < 0 then
        Break;
      if not Assigned(FGame.EntityAt(LIndex)) then
        raise EDoomScriptParityHarness.Create('harness: entity of the save is missing');
      FGame.ScriptObjectOf(FGame.EntityAt(LIndex)).Restore(LStream);
    end;
  finally
    LStream.Free;
  end;
end;

end.
