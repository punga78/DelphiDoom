{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the contracts                                     }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of the VM_* API of code/qcommon/qcommon.h (Quake III Arena 1.32)       }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types;

type
  /// <summary>
  ///   The data image of a machine as a host may touch it. An address is the 32 bit integer of the program:
  ///   it is masked as the original does (VM_ArgPtr) and then, unlike the original, the whole range asked
  ///   for must lie inside the image: EQvmExecutionException otherwise. Nothing here can reach the memory
  ///   of the host
  /// </summary>
  IQvmMemory = interface
    ['{6B1E0D42-93A7-4C58-B2F1-7E05A9C4D310}']
    /// <summary>dataMask + 1: a power of two</summary>
    function GetSize: Integer;
    function GetMask: Integer;
    /// <summary>
    ///   VM_ArgPtr: nil for the address 0, otherwise the host pointer of the masked address, valid for
    ///   ALength bytes
    /// </summary>
    function ArgPtr(AAddress: Integer; ALength: NativeInt): Pointer;
    /// <summary>As ArgPtr, but the address 0 is an address like the others</summary>
    function Range(AAddress: Integer; ALength: NativeInt): Pointer;
    function ReadByte(AAddress: Integer): Byte;
    procedure WriteByte(AAddress: Integer; AValue: Byte);
    function ReadInt32(AAddress: Integer): Integer;
    procedure WriteInt32(AAddress: Integer; AValue: Integer);
    /// <summary>The bytes up to the first zero; raises if there is none before the end of the image</summary>
    function ReadString(AAddress: Integer): AnsiString;
    /// <summary>
    ///   Q_strncpyz: at most ABufferSize - 1 bytes of the text, then zeroes up to the end of the buffer (it
    ///   is a strncpy), which must be all inside the image. Nothing is written when ABufferSize is below 1
    /// </summary>
    procedure WriteString(AAddress: Integer; const AText: AnsiString; ABufferSize: Integer);
    function ReadBytes(AAddress: Integer; ALength: NativeInt): TBytes;
    procedure WriteBytes(AAddress: Integer; const ABytes: TBytes);
    /// <summary>memset</summary>
    procedure Fill(AAddress: Integer; AValue: Byte; ALength: NativeInt);
    /// <summary>memmove inside the image</summary>
    procedure Copy(ADestination, ASource: Integer; ALength: NativeInt);
    property Size: Integer read GetSize;
    property Mask: Integer read GetMask;
  end;

  /// <summary>The symbols of a .map file (VM_LoadSymbols) and the profile counted on them</summary>
  IQvmSymbols = interface
    ['{C24F7A19-5E60-4B83-9D3C-18A6F0B7E245}']
    function GetCount: Integer;
    /// <summary>
    ///   Reads the text of a .map file: only the symbols of the code segment are kept. Returns how many;
    ///   the symbols that were there are forgotten
    /// </summary>
    function Load(const AText: AnsiString): Integer;
    /// <summary>VM_ValueToSymbol of a program counter: 'name', 'name+offset' or 'NO SYMBOLS'</summary>
    function ValueToSymbol(AValue: Integer): AnsiString;
    /// <summary>VM_SymbolToValue: 0 when there is no such symbol</summary>
    function SymbolToValue(const AName: AnsiString): Integer;
    /// <summary>
    ///   VM_VmProfile_f as data: the instructions counted on every symbol while the machine was profiling,
    ///   from the least executed, then the counts go back to zero
    /// </summary>
    function TakeProfile: TQvmProfile;
    property Count: Integer read GetCount;
  end;

  IQvmMachine = interface;

  /// <summary>
  ///   The other side of the system calls: a call to a negative address is the call number -1 - address.
  ///   The host reads and writes the memory of the program only through AMachine.Memory, and may call
  ///   AMachine.Call again from here (the machine is re-entrant). An exception raised here ends the call
  ///   of the machine and goes to its caller (the Com_Error of the original)
  /// </summary>
  IQvmHost = interface
    ['{0E8D53B6-A471-4F2C-8B95-D36C1E7F0A28}']
    function SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
  end;

  /// <summary>One loaded image (vm_t): its code, its data and its program stack</summary>
  IQvmMachine = interface
    ['{F3A96C05-2B7D-4E14-A8C6-5D0B9E3F7142}']
    function GetName: AnsiString;
    function GetMemory: IQvmMemory;
    function GetSymbols: IQvmSymbols;
    function GetInfo: TQvmInfo;
    function GetInstructionCount: Integer;
    function GetJumpTargets: TArray<Integer>;
    function GetProgramStack: Integer;
    function GetStackBottom: Integer;
    function GetCallDepth: Integer;
    function GetInstructionsExecuted: Int64;
    function GetSystemCallCount: Int64;
    function GetBreakCount: Integer;
    function GetProfiling: Boolean;
    procedure SetProfiling(AValue: Boolean);
    /// <summary>
    ///   VM_Call: runs the entry point (vmMain) with the command and at most nine arguments and returns its
    ///   value. Raises EQvmExecutionException when the program breaks a rule of the machine, and whatever
    ///   the host raises; after an exception the machine is as it was before the call, except for what the
    ///   program wrote in its memory
    /// </summary>
    function Call(ACommand: Integer; const AArguments: array of Integer): Integer;
    /// <summary>
    ///   VM_Restart: the data image is cleared and loaded again from the bytes of the file; code, symbols
    ///   and program stack stay. The file must ask for the same amount of data
    /// </summary>
    procedure Restart(const AFileData: TBytes);
    /// <summary>VM_StackTrace: the symbols of the frames from a program counter and a program stack, at most 32</summary>
    function StackTrace(AProgramCounter, AProgramStack: Integer): TArray<AnsiString>;
    property Name: AnsiString read GetName;
    property Memory: IQvmMemory read GetMemory;
    property Symbols: IQvmSymbols read GetSymbols;
    /// <summary>VM_VmInfo_f</summary>
    property Info: TQvmInfo read GetInfo;
    property InstructionCount: Integer read GetInstructionCount;
    /// <summary>The jump table of a QVM_MAGIC_VER2 file (instruction numbers); empty otherwise</summary>
    property JumpTargets: TArray<Integer> read GetJumpTargets;
    /// <summary>vm->programStack: where the next call will make its frame</summary>
    property ProgramStack: Integer read GetProgramStack;
    property StackBottom: Integer read GetStackBottom;
    /// <summary>How many calls are running now (0 outside Call)</summary>
    property CallDepth: Integer read GetCallDepth;
    property InstructionsExecuted: Int64 read GetInstructionsExecuted;
    property SystemCallCount: Int64 read GetSystemCallCount;
    /// <summary>vm->breakCount: the OP_BREAK executed</summary>
    property BreakCount: Integer read GetBreakCount;
    /// <summary>Counts the instructions on the symbols (the DEBUG_VM build of the original)</summary>
    property Profiling: Boolean read GetProfiling write SetProfiling;
  end;

  /// <summary>
  ///   The table of the machines (vmTable, MAX_VM): a module is loaded once by name from 'vm/name.qvm'
  /// </summary>
  IQvmManager = interface
    ['{8D57B2E4-06C9-41AF-B3E8-92F4A1D6C057}']
    function GetCount: Integer;
    /// <summary>
    ///   VM_Create: the machine of the module, loaded now if it is not in the table. nil when the file is
    ///   not there (as the original); raises EQvmFormatException for a bad file, EQvmException when the
    ///   table is full or the arguments are empty
    /// </summary>
    function Load(const AModule: AnsiString; const AHost: IQvmHost): IQvmMachine;
    /// <summary>The machine of a module that is in the table, or nil</summary>
    function Find(const AModule: AnsiString): IQvmMachine;
    /// <summary>VM_Restart: reads the file again; raises when it is not there any more</summary>
    procedure Restart(const AMachine: IQvmMachine);
    /// <summary>VM_Free</summary>
    procedure Unload(const AMachine: IQvmMachine);
    /// <summary>VM_Clear</summary>
    procedure Clear;
    /// <summary>VM_VmInfo_f as data</summary>
    function Info: TArray<TQvmInfo>;
    property Count: Integer read GetCount;
  end;

implementation

end.
