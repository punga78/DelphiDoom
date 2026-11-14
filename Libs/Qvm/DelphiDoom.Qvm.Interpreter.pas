{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the interpreter                                   }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of VM_CallInterpreted (code/qcommon/vm_interpreted.c), Quake III       }
{  Arena 1.32                                                                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Interpreter;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Code, DelphiDoom.Qvm.Memory,
  DelphiDoom.Qvm.Symbols;

type
  /// <summary>What a program can do wrong while it runs</summary>
  TQvmFault = (OperandStackOverflow, OperandStackUnderflow, ProgramStack, ArgumentOutOfRange, BadCallTarget,
    BadJumpTarget, BadReturnAddress, DivisionByZero, DivisionOverflow, BlockCopyNotAligned,
    BlockCopyOutOfRange, BadInstruction, UnbalancedStack);

  /// <summary>
  ///   Runs the code of a machine on its data image. The program is not trusted: nothing it does can read
  ///   or write outside the image or run anything but its own instructions.
  ///   - Loads and stores are masked as in the original (a wild address wraps into the image).
  ///   - The program stack pointer is checked whenever it changes (OP_ENTER, OP_LEAVE and the entry frame):
  ///     above the stack bottom, inside the image, a multiple of four. The original checks only in its
  ///     debug build and uses the pointer without a mask.
  ///   - The operand stack has 256 slots and is checked at every push and pop.
  ///   - A call, a jump and a return address must be an existing instruction.
  ///   - Division by zero and the minimum integer divided by -1, which stop the processor in the original,
  ///     are EQvmExecutionException; shifts use the low five bits of the count, as x86 does.
  ///   The loop has no virtual or interface call for an instruction: only a system call goes to the host
  /// </summary>
  TQvmInterpreter = class
  strict private
    FCode: TQvmCode;
    FMemory: TQvmMemory;
    FSymbols: TQvmSymbols;
    FHost: IQvmHost;
    // the machine that owns this object, not counted: it is what the host receives
    FMachine: Pointer;
    FLimits: TQvmLimits;
    FProgramStack: Integer;
    FStackBottom: Integer;
    FStackLow: Integer;
    FStackSpan: Cardinal;
    FDepth: Integer;
    FRemaining: Int64;
    FExecuted: Int64;
    FSystemCalls: Int64;
    FBreakCount: Integer;
    FProfiling: Boolean;
    FProfileIndex: Integer;
    FProfileMark: Int64;
    function TakeChunk: Integer;
    procedure ReturnChunk(ABudget: Integer);
    procedure ProfileSwitch(ABudget, AIndex: Integer);
    procedure Fail(AFault: TQvmFault; ABudget: Integer; AValue: Integer = 0);
    function SystemCall(AArguments: PQvmSystemCallArguments): Integer;
    function Run(ACommand: Integer; const AArguments: array of Integer): Integer;
  public
    /// <param name="AMachine">The machine the host is told about; it must outlive this object</param>
    constructor Create(ACode: TQvmCode; AMemory: TQvmMemory; ASymbols: TQvmSymbols; const AHost: IQvmHost;
      const AMachine: IQvmMachine; const ALimits: TQvmLimits);
    /// <summary>VM_Call on an interpreted module: see IQvmMachine.Call</summary>
    function Call(ACommand: Integer; const AArguments: array of Integer): Integer;
    /// <summary>vm->programStack</summary>
    property ProgramStack: Integer read FProgramStack;
    /// <summary>vm->stackBottom: the image size less QVM_STACK_SIZE (negative for a small image)</summary>
    property StackBottom: Integer read FStackBottom;
    property CallDepth: Integer read FDepth;
    property InstructionsExecuted: Int64 read FExecuted;
    property SystemCallCount: Int64 read FSystemCalls;
    property BreakCount: Integer read FBreakCount;
    property Profiling: Boolean read FProfiling write FProfiling;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes, DelphiDoom.Qvm.FloatMath, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

{$POINTERMATH ON}
// the integers of the program wrap as the int of C does
{$Q-}
{$R-}
// a float operation is rounded to a float at once, at 64 bit too
{$EXCESSPRECISION OFF}

const
  BUDGET_CHUNK = 1 shl 30;
  // the messages of the original, where it has one
  SOperandStackOverflow = 'VM opStack overflow';
  SOperandStackUnderflow = 'VM opStack underflow';
  SStackOverflow = 'VM stack overflow';
  SStackMisaligned = 'VM program stack misaligned';
  SStackOutOfRange = 'VM program stack out of range: %d';
  SArgumentOutOfRange = 'VM OP_ARG outside the data image: %d';
  SBadCallTarget = 'VM call to instruction %d, which does not exist';
  SBadJumpTarget = 'VM jump to instruction %d, which does not exist';
  SBadReturnAddress = 'VM return to %d, which is not an instruction';
  SDivisionByZero = 'VM division by zero';
  SDivisionOverflow = 'VM division overflow';
  SBlockCopyNotAligned = 'OP_BLOCK_COPY not dword aligned';
  SBlockCopyOutOfRange = 'OP_BLOCK_COPY out of range';
  SBadInstruction = 'VM pc out of range';
  SUnbalancedStack = 'Interpreter error: opStack = %d';
  SInstructionLimit = 'VM instruction limit reached (%d)';
  STooManyArguments = 'VM_Call with %d arguments (at most %d)';
  STooDeep = 'VM entered %d times from its own system calls';

{ TQvmInterpreter }

constructor TQvmInterpreter.Create(ACode: TQvmCode; AMemory: TQvmMemory; ASymbols: TQvmSymbols;
  const AHost: IQvmHost; const AMachine: IQvmMachine; const ALimits: TQvmLimits);
var
  LHigh: Integer;
begin
  inherited Create;
  FCode := ACode;
  FMemory := AMemory;
  FSymbols := ASymbols;
  FHost := AHost;
  FMachine := Pointer(AMachine);
  FLimits := ALimits;
  // the stack is implicitly at the end of the image
  FProgramStack := FMemory.Size;
  FStackBottom := FProgramStack - QVM_STACK_SIZE;
  // a program stack pointer is good from above the bottom up to where a return address and the number
  // of a system call still fit
  FStackLow := FStackBottom + 1;
  if FStackLow < 0 then
    FStackLow := 0;
  LHigh := FMemory.Size - 2 * SizeOf(Integer);
  if LHigh >= FStackLow then
    FStackSpan := Cardinal(LHigh - FStackLow)
  else
  begin
    // an image too small to hold a frame: no multiple of four passes the test
    FStackLow := 1;
    FStackSpan := 0;
  end;
  FProfileIndex := -1;
end;

function TQvmInterpreter.TakeChunk: Integer;
begin
  if FRemaining <= 0 then
    raise EQvmInstructionLimitException.CreateFmt(SInstructionLimit, [FLimits.InstructionLimit]);
  if FRemaining > BUDGET_CHUNK then
    Result := BUDGET_CHUNK
  else
    Result := Integer(FRemaining);
  Dec(FRemaining, Result);
  Inc(FExecuted, Result);
end;

procedure TQvmInterpreter.ReturnChunk(ABudget: Integer);
begin
  Inc(FRemaining, ABudget);
  Dec(FExecuted, ABudget);
end;

procedure TQvmInterpreter.ProfileSwitch(ABudget, AIndex: Integer);
var
  LNow: Int64;
begin
  LNow := FExecuted - ABudget;
  FSymbols.AddCount(FProfileIndex, LNow - FProfileMark);
  FProfileMark := LNow;
  FProfileIndex := AIndex;
end;

procedure TQvmInterpreter.Fail(AFault: TQvmFault; ABudget, AValue: Integer);
begin
  ReturnChunk(ABudget);
  case AFault of
    TQvmFault.OperandStackOverflow:
      raise EQvmExecutionException.Create(SOperandStackOverflow);
    TQvmFault.OperandStackUnderflow:
      raise EQvmExecutionException.Create(SOperandStackUnderflow);
    TQvmFault.ProgramStack:
      if (AValue and 3) <> 0 then
        raise EQvmExecutionException.Create(SStackMisaligned)
      else if (AValue <= FStackBottom) or (AValue < 0) then
        raise EQvmExecutionException.Create(SStackOverflow)
      else
        raise EQvmExecutionException.CreateFmt(SStackOutOfRange, [AValue]);
    TQvmFault.ArgumentOutOfRange:
      raise EQvmExecutionException.CreateFmt(SArgumentOutOfRange, [AValue]);
    TQvmFault.BadCallTarget:
      raise EQvmExecutionException.CreateFmt(SBadCallTarget, [AValue]);
    TQvmFault.BadJumpTarget:
      raise EQvmExecutionException.CreateFmt(SBadJumpTarget, [AValue]);
    TQvmFault.BadReturnAddress:
      raise EQvmExecutionException.CreateFmt(SBadReturnAddress, [AValue]);
    TQvmFault.DivisionByZero:
      raise EQvmExecutionException.Create(SDivisionByZero);
    TQvmFault.DivisionOverflow:
      raise EQvmExecutionException.Create(SDivisionOverflow);
    TQvmFault.BlockCopyNotAligned:
      raise EQvmExecutionException.Create(SBlockCopyNotAligned);
    TQvmFault.BlockCopyOutOfRange:
      raise EQvmExecutionException.Create(SBlockCopyOutOfRange);
    TQvmFault.BadInstruction:
      raise EQvmExecutionException.Create(SBadInstruction);
  else
    raise EQvmExecutionException.CreateFmt(SUnbalancedStack, [AValue]);
  end;
end;

function TQvmInterpreter.SystemCall(AArguments: PQvmSystemCallArguments): Integer;
begin
  Inc(FSystemCalls);
  Result := FHost.SystemCall(IQvmMachine(FMachine), AArguments^);
end;

function TQvmInterpreter.Call(ACommand: Integer; const AArguments: array of Integer): Integer;
var
  LStackOnEntry: Integer;
  LFloatMask: IInterface;
begin
  if Length(AArguments) > QVM_MAX_CALL_ARGUMENTS then
    raise EQvmException.CreateFmt(STooManyArguments, [Length(AArguments), QVM_MAX_CALL_ARGUMENTS]);
  if FDepth >= FLimits.MaxCallDepth then
    raise EQvmExecutionException.CreateFmt(STooDeep, [FDepth]);
  if FDepth = 0 then
  begin
    if FLimits.InstructionLimit > 0 then
      FRemaining := FLimits.InstructionLimit
    else
      FRemaining := High(Int64);
    FProfileMark := FExecuted;
    FProfileIndex := -1;
  end;
  // a division by zero or an overflow of the floats of the program gives an infinite or a NaN, as in C
  LFloatMask := TQ3FloatMask.Enter;
  // we might be called recursively, so this might not be the very top
  LStackOnEntry := FProgramStack;
  Inc(FDepth);
  try
    Result := Run(ACommand, AArguments);
  finally
    Dec(FDepth);
    FProgramStack := LStackOnEntry;
  end;
end;

function TQvmInterpreter.Run(ACommand: Integer; const AArguments: array of Integer): Integer;
var
  LStack: array[0..QVM_OPERAND_STACK_SIZE - 1] of Integer;
  LCode: PInteger;
  LPointers: PInteger;
  LImage: PByte;
  LProgramCounter: NativeInt;
  LOperandTop: NativeInt;
  LProgramStack: Integer;
  LMask: Integer;
  LBudget: Integer;
  LFirst: Integer;
  LSecond: Integer;
  LIndex: Integer;
  LInstructionCount: Cardinal;
  LSavedProfile: Integer;
  LProfiling: Boolean;
begin
  LImage := FMemory.Base;
  LMask := FMemory.Mask;
  LCode := PInteger(FCode.Image);
  LPointers := PInteger(FCode.InstructionPointers);
  LInstructionCount := Cardinal(FCode.InstructionCount);
  LBudget := 0;
  LProfiling := FProfiling;
  LSavedProfile := FProfileIndex;
  if LProfiling then
    ProfileSwitch(0, FSymbols.FunctionIndex(0));

  // set up the stack frame
  LProgramStack := FProgramStack - QVM_ENTRY_FRAME;
  if (Cardinal(LProgramStack - FStackLow) > FStackSpan) or ((LProgramStack and 3) <> 0) then
    Fail(TQvmFault.ProgramStack, 0, LProgramStack);
  for LIndex := 0 to QVM_MAX_CALL_ARGUMENTS - 1 do
    if LIndex < Length(AArguments) then
      PInteger(LImage + LProgramStack + 12 + 4 * LIndex)^ := AArguments[LIndex]
    else
      PInteger(LImage + LProgramStack + 12 + 4 * LIndex)^ := 0;
  PInteger(LImage + LProgramStack + 8)^ := ACommand;
  // return stack
  PInteger(LImage + LProgramStack + 4)^ := 0;
  // will terminate the loop on return
  PInteger(LImage + LProgramStack)^ := -1;

  // the original leaves its operand stack as the C stack happens to be; slot 0 is the free spot below
  // the first value
  FillChar(LStack, SizeOf(LStack), 0);
  LOperandTop := 0;
  LProgramCounter := 0;

  // main interpreter loop, will exit when a LEAVE instruction
  // grabs the -1 program counter
  while True do
  begin
    Dec(LBudget);
    if LBudget < 0 then
      LBudget := TakeChunk - 1;
    LIndex := LCode[LProgramCounter];
    Inc(LProgramCounter);
    case LIndex of
      OP_UNDEF, OP_IGNORE:
        ;
      OP_BREAK:
        Inc(FBreakCount);
      OP_CONST:
        begin
          Inc(LOperandTop);
          if LOperandTop >= QVM_OPERAND_STACK_SIZE then
            Fail(TQvmFault.OperandStackOverflow, LBudget);
          LStack[LOperandTop] := LCode[LProgramCounter];
          Inc(LProgramCounter, 4);
        end;
      OP_LOCAL:
        begin
          Inc(LOperandTop);
          if LOperandTop >= QVM_OPERAND_STACK_SIZE then
            Fail(TQvmFault.OperandStackOverflow, LBudget);
          LStack[LOperandTop] := LCode[LProgramCounter] + LProgramStack;
          Inc(LProgramCounter, 4);
        end;
      OP_LOAD4:
        LStack[LOperandTop] := PInteger(LImage + (LStack[LOperandTop] and LMask))^;
      OP_LOAD2:
        LStack[LOperandTop] := PWord(LImage + (LStack[LOperandTop] and LMask))^;
      OP_LOAD1:
        LStack[LOperandTop] := PByte(LImage + (LStack[LOperandTop] and LMask))^;
      OP_STORE4:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          PInteger(LImage + (LStack[LOperandTop + 1] and (LMask and not 3)))^ := LStack[LOperandTop + 2];
        end;
      OP_STORE2:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          PWord(LImage + (LStack[LOperandTop + 1] and (LMask and not 1)))^ := Word(LStack[LOperandTop + 2]);
        end;
      OP_STORE1:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          PByte(LImage + (LStack[LOperandTop + 1] and LMask))^ := Byte(LStack[LOperandTop + 2]);
        end;
      OP_ARG:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          // single byte offset from programStack; the original does not mask it
          LFirst := LCode[LProgramCounter] + LProgramStack;
          if Cardinal(LFirst) > Cardinal(LMask - 3) then
            Fail(TQvmFault.ArgumentOutOfRange, LBudget, LFirst);
          PInteger(LImage + LFirst)^ := LStack[LOperandTop + 1];
          Inc(LProgramCounter);
        end;
      OP_BLOCK_COPY:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          case FMemory.BlockCopy(LStack[LOperandTop + 1], LStack[LOperandTop + 2], LCode[LProgramCounter]) of
            TQvmBlockCopyResult.NotAligned:
              Fail(TQvmFault.BlockCopyNotAligned, LBudget);
            TQvmBlockCopyResult.OutOfRange:
              Fail(TQvmFault.BlockCopyOutOfRange, LBudget);
          end;
          Inc(LProgramCounter, 4);
        end;
      OP_CALL:
        begin
          // save current program counter
          PInteger(LImage + LProgramStack)^ := Integer(LProgramCounter);
          // jump to the location on the stack
          LFirst := LStack[LOperandTop];
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if LFirst < 0 then
          begin
            // system call: save the stack to allow recursive VM entry
            FProgramStack := LProgramStack - 4;
            PInteger(LImage + LProgramStack + 4)^ := -1 - LFirst;
            ReturnChunk(LBudget);
            LBudget := 0;
            LSecond := SystemCall(PQvmSystemCallArguments(LImage + LProgramStack + 4));
            // save return value; the program goes on after the call (the original reads the address back
            // from the image, where the host could have changed it)
            Inc(LOperandTop);
            LStack[LOperandTop] := LSecond;
          end
          else
          begin
            if Cardinal(LFirst) >= LInstructionCount then
              Fail(TQvmFault.BadCallTarget, LBudget, LFirst);
            LProgramCounter := LPointers[LFirst];
          end;
        end;
      // push and pop are only needed for discarded or bad function return values
      OP_PUSH:
        begin
          Inc(LOperandTop);
          if LOperandTop >= QVM_OPERAND_STACK_SIZE then
            Fail(TQvmFault.OperandStackOverflow, LBudget);
        end;
      OP_POP:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
        end;
      OP_ENTER:
        begin
          if LProfiling then
            ProfileSwitch(LBudget, FSymbols.FunctionIndex(Integer(LProgramCounter)));
          // get size of stack frame
          LProgramStack := LProgramStack - LCode[LProgramCounter];
          Inc(LProgramCounter, 4);
          if (Cardinal(LProgramStack - FStackLow) > FStackSpan) or ((LProgramStack and 3) <> 0) then
            Fail(TQvmFault.ProgramStack, LBudget, LProgramStack);
        end;
      OP_LEAVE:
        begin
          // remove our stack frame
          LProgramStack := LProgramStack + LCode[LProgramCounter];
          if (Cardinal(LProgramStack - FStackLow) > FStackSpan) or ((LProgramStack and 3) <> 0) then
            Fail(TQvmFault.ProgramStack, LBudget, LProgramStack);
          // grab the saved program counter
          LProgramCounter := PInteger(LImage + LProgramStack)^;
          if LProfiling then
            ProfileSwitch(LBudget, FSymbols.FunctionIndex(Integer(LProgramCounter)));
          // check for leaving the VM
          if LProgramCounter = -1 then
            Break;
          if not FCode.IsInstructionStart(Integer(LProgramCounter)) then
            Fail(TQvmFault.BadReturnAddress, LBudget, Integer(LProgramCounter));
        end;
      OP_JUMP:
        begin
          LFirst := LStack[LOperandTop];
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if Cardinal(LFirst) >= LInstructionCount then
            Fail(TQvmFault.BadJumpTarget, LBudget, LFirst);
          LProgramCounter := LPointers[LFirst];
        end;
      OP_EQ:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if LStack[LOperandTop + 1] = LStack[LOperandTop + 2] then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_NE:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if LStack[LOperandTop + 1] <> LStack[LOperandTop + 2] then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_LTI:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if LStack[LOperandTop + 1] < LStack[LOperandTop + 2] then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_LEI:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if LStack[LOperandTop + 1] <= LStack[LOperandTop + 2] then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_GTI:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if LStack[LOperandTop + 1] > LStack[LOperandTop + 2] then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_GEI:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if LStack[LOperandTop + 1] >= LStack[LOperandTop + 2] then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_LTU:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if Cardinal(LStack[LOperandTop + 1]) < Cardinal(LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_LEU:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if Cardinal(LStack[LOperandTop + 1]) <= Cardinal(LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_GTU:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if Cardinal(LStack[LOperandTop + 1]) > Cardinal(LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_GEU:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if Cardinal(LStack[LOperandTop + 1]) >= Cardinal(LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_EQF:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.Equal(LStack[LOperandTop + 1], LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_NEF:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if not TQvmFloatMath.Equal(LStack[LOperandTop + 1], LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_LTF:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.Less(LStack[LOperandTop + 1], LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_LEF:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.LessOrEqual(LStack[LOperandTop + 1], LStack[LOperandTop + 2]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_GTF:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.Less(LStack[LOperandTop + 2], LStack[LOperandTop + 1]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_GEF:
        begin
          Dec(LOperandTop, 2);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.LessOrEqual(LStack[LOperandTop + 2], LStack[LOperandTop + 1]) then
            LProgramCounter := LCode[LProgramCounter]
          else
            Inc(LProgramCounter, 4);
        end;
      OP_SEX8:
        LStack[LOperandTop] := ShortInt(LStack[LOperandTop]);
      OP_SEX16:
        LStack[LOperandTop] := SmallInt(LStack[LOperandTop]);
      OP_NEGI:
        LStack[LOperandTop] := -LStack[LOperandTop];
      OP_ADD:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := LStack[LOperandTop] + LStack[LOperandTop + 1];
        end;
      OP_SUB:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := LStack[LOperandTop] - LStack[LOperandTop + 1];
        end;
      OP_DIVI, OP_MODI:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LFirst := LStack[LOperandTop];
          LSecond := LStack[LOperandTop + 1];
          // the idiv of x86 stops the program in both cases
          if LSecond = 0 then
            Fail(TQvmFault.DivisionByZero, LBudget);
          if (LSecond = -1) and (LFirst = Low(Integer)) then
            Fail(TQvmFault.DivisionOverflow, LBudget);
          if LIndex = OP_DIVI then
            LStack[LOperandTop] := LFirst div LSecond
          else
            LStack[LOperandTop] := LFirst mod LSecond;
        end;
      OP_DIVU, OP_MODU:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LSecond := LStack[LOperandTop + 1];
          if LSecond = 0 then
            Fail(TQvmFault.DivisionByZero, LBudget);
          if LIndex = OP_DIVU then
            LStack[LOperandTop] := Integer(Cardinal(LStack[LOperandTop]) div Cardinal(LSecond))
          else
            LStack[LOperandTop] := Integer(Cardinal(LStack[LOperandTop]) mod Cardinal(LSecond));
        end;
      OP_MULI, OP_MULU:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := LStack[LOperandTop] * LStack[LOperandTop + 1];
        end;
      OP_BAND:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := LStack[LOperandTop] and LStack[LOperandTop + 1];
        end;
      OP_BOR:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := LStack[LOperandTop] or LStack[LOperandTop + 1];
        end;
      OP_BXOR:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := LStack[LOperandTop] xor LStack[LOperandTop + 1];
        end;
      OP_BCOM:
        if FLimits.LegacyBitComplement then
        begin
          // opStack[-1] = ~r0 with the top left where it is: the defect of the interpreter of 1.32
          if LOperandTop < 1 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop - 1] := not LStack[LOperandTop];
        end
        else
          LStack[LOperandTop] := not LStack[LOperandTop];
      OP_LSH:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := LStack[LOperandTop] shl (LStack[LOperandTop + 1] and 31);
        end;
      OP_RSHI:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          // shr is a logical shift: the arithmetic one of a negative number is the complement of the
          // logical shift of its complement
          LFirst := LStack[LOperandTop];
          LSecond := LStack[LOperandTop + 1] and 31;
          if LFirst < 0 then
            LStack[LOperandTop] := not ((not LFirst) shr LSecond)
          else
            LStack[LOperandTop] := LFirst shr LSecond;
        end;
      OP_RSHU:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          LStack[LOperandTop] := Integer(Cardinal(LStack[LOperandTop]) shr (LStack[LOperandTop + 1] and 31));
        end;
      OP_NEGF:
        LStack[LOperandTop] := LStack[LOperandTop] xor Integer($80000000);
      OP_ADDF:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.IsSpecial(LStack[LOperandTop]) or TQvmFloatMath.IsSpecial(LStack[LOperandTop + 1]) then
            LStack[LOperandTop] := TQvmFloatMath.Special(OP_ADDF, LStack[LOperandTop], LStack[LOperandTop + 1])
          else
            PSingle(@LStack[LOperandTop])^ := PSingle(@LStack[LOperandTop])^ + PSingle(@LStack[LOperandTop + 1])^;
        end;
      OP_SUBF:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.IsSpecial(LStack[LOperandTop]) or TQvmFloatMath.IsSpecial(LStack[LOperandTop + 1]) then
            LStack[LOperandTop] := TQvmFloatMath.Special(OP_SUBF, LStack[LOperandTop], LStack[LOperandTop + 1])
          else
            PSingle(@LStack[LOperandTop])^ := PSingle(@LStack[LOperandTop])^ - PSingle(@LStack[LOperandTop + 1])^;
        end;
      OP_DIVF:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.IsSpecial(LStack[LOperandTop]) or TQvmFloatMath.IsSpecial(LStack[LOperandTop + 1]) then
            LStack[LOperandTop] := TQvmFloatMath.Special(OP_DIVF, LStack[LOperandTop], LStack[LOperandTop + 1])
          else
            PSingle(@LStack[LOperandTop])^ := PSingle(@LStack[LOperandTop])^ / PSingle(@LStack[LOperandTop + 1])^;
        end;
      OP_MULF:
        begin
          Dec(LOperandTop);
          if LOperandTop < 0 then
            Fail(TQvmFault.OperandStackUnderflow, LBudget);
          if TQvmFloatMath.IsSpecial(LStack[LOperandTop]) or TQvmFloatMath.IsSpecial(LStack[LOperandTop + 1]) then
            LStack[LOperandTop] := TQvmFloatMath.Special(OP_MULF, LStack[LOperandTop], LStack[LOperandTop + 1])
          else
            PSingle(@LStack[LOperandTop])^ := PSingle(@LStack[LOperandTop])^ * PSingle(@LStack[LOperandTop + 1])^;
        end;
      OP_CVIF:
        PSingle(@LStack[LOperandTop])^ := LStack[LOperandTop];
      OP_CVFI:
        LStack[LOperandTop] := TQvmFloatMath.ToInteger(LStack[LOperandTop]);
    else
      // the sentinel after the last instruction
      Fail(TQvmFault.BadInstruction, LBudget);
    end;
  end;

  if LProfiling then
    ProfileSwitch(LBudget, LSavedProfile);
  ReturnChunk(LBudget);
  if LOperandTop <> 1 then
    Fail(TQvmFault.UnbalancedStack, 0, Integer(LOperandTop));
  // return the result
  Result := LStack[1];
end;

end.
