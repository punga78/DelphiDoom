{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the system calls all modules share      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_game.c,       }
{  cl_cgame.c, cl_ui.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is  }
{  derived from the Quake III Arena source code and is therefore available      }
{  under the GNU General Public License, version 2 or (at your option) any      }
{  later version.                                                               }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.CommonSyscalls;

// Overflow and range checks are off: the arguments are 32 bit words, as in the C.

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf;

type
  /// <summary>
  ///   Print, error, milliseconds, memset, memcpy, strncpy and the math functions (sin, cos, atan2, sqrt, floor,
  ///   ceil): the system calls that game, cgame and ui have, with different numbers, and that need nothing of the
  ///   engine but a console and a clock
  /// </summary>
  TQ3CommonSyscalls = class
  strict private
    class function RoundBits(ABits: Integer; AUp: Boolean): Integer; static;
  public
    /// <summary>
    ///   Registers them in the registry of the module AModule. G_ERROR, CG_ERROR and UI_ERROR raise
    ///   EQ3ModuleErrorException with the text (Com_Error( ERR_DROP )); memset and memcpy answer 0 and
    ///   strncpy the address of the destination (the C returns the host pointer, which no program can use).
    ///   Unlike the C, a range that is not inside the data of the program is an exception
    /// </summary>
    class procedure Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry; const AConsole: IQ3HostConsole;
      const ATime: IQ3HostTime); static;
  end;

implementation

uses
  System.Math, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Arguments, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

type
  TCommonNumbers = record
    Print, Error, Milliseconds, MemSet, MemCpy, StrNCpy, Sin, Cos, Atan2, Sqrt, Floor, Ceil: Integer;
  end;

const
  COMMON_NUMBERS: array[TQ3Module] of TCommonNumbers = (
    (Print: G_PRINT; Error: G_ERROR; Milliseconds: G_MILLISECONDS; MemSet: TRAP_MEMSET; MemCpy: TRAP_MEMCPY;
     StrNCpy: TRAP_STRNCPY; Sin: TRAP_SIN; Cos: TRAP_COS; Atan2: TRAP_ATAN2; Sqrt: TRAP_SQRT; Floor: TRAP_FLOOR;
     Ceil: TRAP_CEIL),
    (Print: CG_PRINT; Error: CG_ERROR; Milliseconds: CG_MILLISECONDS; MemSet: CG_MEMSET; MemCpy: CG_MEMCPY;
     StrNCpy: CG_STRNCPY; Sin: CG_SIN; Cos: CG_COS; Atan2: CG_ATAN2; Sqrt: CG_SQRT; Floor: CG_FLOOR;
     Ceil: CG_CEIL),
    (Print: UI_PRINT; Error: UI_ERROR; Milliseconds: UI_MILLISECONDS; MemSet: UI_MEMSET; MemCpy: UI_MEMCPY;
     StrNCpy: UI_STRNCPY; Sin: UI_SIN; Cos: UI_COS; Atan2: UI_ATAN2; Sqrt: UI_SQRT; Floor: UI_FLOOR;
     Ceil: UI_CEIL));
  CALL_NAMES: array[TQ3Module] of string = ('G_PRINT', 'CG_PRINT', 'UI_PRINT');

// floor and ceil of a float given as bits, in a float (the C does it in a double and converts back: the same
// value, a float is whole from 2^23)
class function TQ3CommonSyscalls.RoundBits(ABits: Integer; AUp: Boolean): Integer;
var
  LValue, LWhole: Single;
begin
  if (Cardinal(ABits) and $7FFFFFFF) >= $4B000000 then
    Exit(ABits);
  LValue := TQ3SyscallArguments.ToSingle(ABits);
  LWhole := Trunc(LValue);
  if AUp then
  begin
    if LWhole < LValue then
      LWhole := LWhole + 1;
  end
  else if LWhole > LValue then
    LWhole := LWhole - 1;
  Result := TQ3SyscallArguments.FromSingle(LWhole);
  // a zero keeps the sign of the value it came from (ceil( -0.5 ) is -0)
  if (Result = 0) and (ABits < 0) then
    Result := Integer($80000000);
end;

class procedure TQ3CommonSyscalls.Register(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry;
  const AConsole: IQ3HostConsole; const ATime: IQ3HostTime);
var
  LNumbers: TCommonNumbers;
  LPrint: TQ3SyscallHandler;
begin
  LNumbers := COMMON_NUMBERS[AModule];

  LPrint := function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      AConsole.Print(TQ3SyscallArguments.Text(AMachine, AArguments[1], CALL_NAMES[AModule]));
      Result := 0;
    end;
  ARegistry.Register(LNumbers.Print, LPrint);

  ARegistry.Register(LNumbers.Error,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      raise EQ3ModuleErrorException.Create(string(TQ3SyscallArguments.Text(AMachine, AArguments[1], 'ERROR')));
    end);

  ARegistry.Register(LNumbers.Milliseconds,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      Result := ATime.Milliseconds;
    end);

  ARegistry.Register(LNumbers.MemSet,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      FillChar(TQ3SyscallArguments.Buffer(AMachine, AArguments[1], AArguments[3])^, AArguments[3],
        Byte(AArguments[2]));
      Result := 0;
    end);

  ARegistry.Register(LNumbers.MemCpy,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    var
      LTarget, LSource: PByte;
    begin
      LTarget := TQ3SyscallArguments.Buffer(AMachine, AArguments[1], AArguments[3]);
      LSource := TQ3SyscallArguments.Buffer(AMachine, AArguments[2], AArguments[3]);
      Move(LSource^, LTarget^, AArguments[3]);
      Result := 0;
    end);

  ARegistry.Register(LNumbers.StrNCpy,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    var
      LTarget: PByte;
      LIndex: Integer;
      LByte: Byte;
      LEnded: Boolean;
    begin
      LTarget := TQ3SyscallArguments.Buffer(AMachine, AArguments[1], AArguments[3]);
      LEnded := False;
      // strncpy: the bytes of the source up to its zero, then zeroes up to the count
      for LIndex := 0 to AArguments[3] - 1 do
      begin
        LByte := 0;
        if not LEnded then
          LByte := AMachine.Memory.ReadByte(AArguments[2] + LIndex);
        if LByte = 0 then
          LEnded := True;
        LTarget[LIndex] := LByte;
      end;
      Result := AArguments[1];
    end);

  // the math: a float widened to a double, the function of the C library, the result narrowed to a float
  ARegistry.Register(LNumbers.Sin,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    var
      LMask: IInterface;
    begin
      LMask := TQ3FloatMask.Enter;
      // sin( -0 ) is -0 (the RTL of Win64 loses the sign)
      if (Cardinal(AArguments[1]) and $7FFFFFFF) = 0 then
        Exit(AArguments[1]);
      Result := TQ3SyscallArguments.FromSingle(Single(System.Sin(Double(TQ3SyscallArguments.ToSingle(AArguments[1])))));
    end);
  ARegistry.Register(LNumbers.Cos,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    var
      LMask: IInterface;
    begin
      LMask := TQ3FloatMask.Enter;
      Result := TQ3SyscallArguments.FromSingle(Single(System.Cos(Double(TQ3SyscallArguments.ToSingle(AArguments[1])))));
    end);
  ARegistry.Register(LNumbers.Atan2,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    var
      LMask: IInterface;
    begin
      LMask := TQ3FloatMask.Enter;
      Result := TQ3SyscallArguments.FromSingle(Single(ArcTan2(Double(TQ3SyscallArguments.ToSingle(AArguments[1])),
        Double(TQ3SyscallArguments.ToSingle(AArguments[2])))));
    end);
  ARegistry.Register(LNumbers.Sqrt,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    var
      LMask: IInterface;
      LValue: Double;
    begin
      LMask := TQ3FloatMask.Enter;
      LValue := Double(TQ3SyscallArguments.ToSingle(AArguments[1]));
      // the square root of a negative is a NaN, with the sign the processor gives it (the C library: -nan)
      if LValue < 0 then
        Exit(Integer($FFC00000));
      Result := TQ3SyscallArguments.FromSingle(Single(System.Sqrt(LValue)));
    end);
  ARegistry.Register(LNumbers.Floor,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      Result := RoundBits(AArguments[1], False);
    end);
  ARegistry.Register(LNumbers.Ceil,
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      Result := RoundBits(AArguments[1], True);
    end);
end;

end.
