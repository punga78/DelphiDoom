{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - shared types, limits and exceptions               }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of code/qcommon/vm_local.h and qfiles.h (Quake III Arena 1.32)         }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>VM_MAGIC: the files of Quake III Arena</summary>
  QVM_MAGIC = Integer($12721444);
  /// <summary>VM_MAGIC_VER2 of ioquake3: one more field in the header, the length of the jump table</summary>
  QVM_MAGIC_VER2 = Integer($12721445);
  /// <summary>STACK_SIZE: the top of the data image that is the program stack</summary>
  QVM_STACK_SIZE = $20000;
  /// <summary>MAX_STACK: the slots of the operand stack of one call</summary>
  QVM_OPERAND_STACK_SIZE = 256;
  /// <summary>VM_Call copies the command and nine arguments</summary>
  QVM_MAX_CALL_ARGUMENTS = 9;
  /// <summary>The integers a host sees of a system call: its number and fifteen arguments</summary>
  QVM_SYSTEM_CALL_ARGUMENTS = 16;
  /// <summary>The frame VM_CallInterpreted makes for the entry point</summary>
  QVM_ENTRY_FRAME = 48;
  /// <summary>MAX_VM</summary>
  QVM_MAX_MACHINES = 3;
  /// <summary>MAX_QPATH: a name keeps 63 characters</summary>
  QVM_MAX_NAME = 63;
  /// <summary>
  ///   Zero bytes after the data image, never written: what a 4 byte load at the last bytes and the arguments
  ///   of a system call made at the top of the stack read (the original reads what follows on the hunk)
  /// </summary>
  QVM_DATA_PADDING = 128;

type
  /// <summary>Every error of the library</summary>
  EQvmException = class(Exception);
  /// <summary>The file is not a QVM image, or is one that cannot be loaded</summary>
  EQvmFormatException = class(EQvmException);
  /// <summary>A program did something the machine does not allow; the machine can still be called</summary>
  EQvmExecutionException = class(EQvmException);
  /// <summary>The injected limit of instructions of one outer call was reached</summary>
  EQvmInstructionLimitException = class(EQvmExecutionException);

  /// <summary>vmHeader_t; with QVM_MAGIC_VER2 one more integer follows, the length of the jump table</summary>
  TQvmHeader = packed record
    Magic: Integer;
    InstructionCount: Integer;
    CodeOffset: Integer;
    CodeLength: Integer;
    DataOffset: Integer;
    DataLength: Integer;
    LitLength: Integer;
    BssLength: Integer;
  end;

  /// <summary>
  ///   What a host receives: [0] is the number of the system call, the others are the integers that follow it
  ///   on the program stack (the ones the call did not pass are whatever the frame holds)
  /// </summary>
  TQvmSystemCallArguments = array[0..QVM_SYSTEM_CALL_ARGUMENTS - 1] of Integer;
  PQvmSystemCallArguments = ^TQvmSystemCallArguments;

  /// <summary>What an image is allowed to ask for, and the switches of compatibility</summary>
  TQvmLimits = record
    /// <summary>The largest data image (a power of two); a file that needs more is refused</summary>
    MaxDataSize: Integer;
    /// <summary>Instructions of one outer call (nested calls included); 0 = no limit</summary>
    InstructionLimit: Int64;
    /// <summary>How many times the host may enter the machine from inside a system call</summary>
    MaxCallDepth: Integer;
    /// <summary>
    ///   OP_BCOM as the interpreter of Quake III 1.32 does it: the result goes to the slot below the top and
    ///   the top stays. False (the default): the complement replaces the top, as the compilers of Quake III
    ///   and ioquake3 do
    /// </summary>
    LegacyBitComplement: Boolean;
    /// <summary>64 MB of data, no limit of instructions, 64 nested calls</summary>
    class function Default: TQvmLimits; static;
  end;

  /// <summary>VM_VmInfo_f: one machine</summary>
  TQvmInfo = record
    Name: AnsiString;
    CodeLength: Integer;
    /// <summary>instructionPointersLength: four bytes for each instruction</summary>
    TableLength: Integer;
    /// <summary>dataMask + 1</summary>
    DataLength: Integer;
  end;

  /// <summary>VM_VmProfile_f: one line</summary>
  TQvmProfileEntry = record
    Name: AnsiString;
    Count: Int64;
    Percent: Integer;
  end;

  /// <summary>VM_VmProfile_f: the symbols from the least to the most executed, and the total</summary>
  TQvmProfile = record
    Entries: TArray<TQvmProfileEntry>;
    Total: Int64;
  end;

implementation

{ TQvmLimits }

class function TQvmLimits.Default: TQvmLimits;
begin
  Result.MaxDataSize := 1 shl 26;
  Result.InstructionLimit := 0;
  Result.MaxCallDepth := 64;
  Result.LegacyBitComplement := False;
end;

end.
