{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - one virtual machine                               }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of vm_t, of the second half of VM_Create, of VM_Restart, VM_Call       }
{  (code/qcommon/vm.c) and of VM_StackTrace (vm_interpreted.c), Quake III      }
{  Arena 1.32                                                                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Machine;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Image, DelphiDoom.Qvm.Code,
  DelphiDoom.Qvm.Memory, DelphiDoom.Qvm.Symbols, DelphiDoom.Qvm.Interpreter;

type
  /// <summary>
  ///   A loaded module: it owns the prepared code, the data image, the symbols and the interpreter, and is
  ///   what the host sees (the machine, its memory and its symbols are the same object). Two machines
  ///   share nothing
  /// </summary>
  TQvmMachine = class(TInterfacedObject, IQvmMachine, IQvmMemory, IQvmSymbols)
  strict private
    FName: AnsiString;
    FLimits: TQvmLimits;
    FJumpTargets: TArray<Integer>;
    FCode: TQvmCode;
    FMemory: TQvmMemory;
    FSymbols: TQvmSymbols;
    FInterpreter: TQvmInterpreter;
  public
    /// <summary>Raises EQvmFormatException for a file that cannot be loaded, EQvmException without a host</summary>
    constructor Create(const AName: AnsiString; const AFileData: TBytes; const AHost: IQvmHost;
      const ALimits: TQvmLimits);
    destructor Destroy; override;
    // IQvmMachine
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
    function Call(ACommand: Integer; const AArguments: array of Integer): Integer;
    procedure Restart(const AFileData: TBytes);
    function StackTrace(AProgramCounter, AProgramStack: Integer): TArray<AnsiString>;
    // IQvmMemory
    function GetSize: Integer;
    function GetMask: Integer;
    function ArgPtr(AAddress: Integer; ALength: NativeInt): Pointer;
    function Range(AAddress: Integer; ALength: NativeInt): Pointer;
    function ReadByte(AAddress: Integer): Byte;
    procedure WriteByte(AAddress: Integer; AValue: Byte);
    function ReadInt32(AAddress: Integer): Integer;
    procedure WriteInt32(AAddress: Integer; AValue: Integer);
    function ReadString(AAddress: Integer): AnsiString;
    procedure WriteString(AAddress: Integer; const AText: AnsiString; ABufferSize: Integer);
    function ReadBytes(AAddress: Integer; ALength: NativeInt): TBytes;
    procedure WriteBytes(AAddress: Integer; const ABytes: TBytes);
    procedure Fill(AAddress: Integer; AValue: Byte; ALength: NativeInt);
    procedure Copy(ADestination, ASource: Integer; ALength: NativeInt);
    // IQvmSymbols
    function GetCount: Integer;
    function Load(const AText: AnsiString): Integer;
    function ValueToSymbol(AValue: Integer): AnsiString;
    function SymbolToValue(const AName: AnsiString): Integer;
    function TakeProfile: TQvmProfile;
  end;

implementation

const
  SNoHost = 'VM_Create: bad parms';
  STraceDepth = 32;

{ TQvmMachine }

constructor TQvmMachine.Create(const AName: AnsiString; const AFileData: TBytes; const AHost: IQvmHost;
  const ALimits: TQvmLimits);
var
  LImage: TQvmImage;
begin
  inherited Create;
  if (AName = '') or not Assigned(AHost) then
    raise EQvmException.Create(SNoHost);
  FName := System.Copy(AName, 1, QVM_MAX_NAME);
  FLimits := ALimits;
  LImage := TQvmImage.Create(AFileData, ALimits, string(FName));
  try
    FJumpTargets := LImage.JumpTargets;
    FCode := TQvmCode.Create(LImage.Code, LImage.InstructionCount, string(FName));
    FMemory := TQvmMemory.Create(LImage);
  finally
    LImage.Free;
  end;
  FSymbols := TQvmSymbols.Create(FCode.InstructionPointers);
  FInterpreter := TQvmInterpreter.Create(FCode, FMemory, FSymbols, AHost, Self, ALimits);
end;

destructor TQvmMachine.Destroy;
begin
  FInterpreter.Free;
  FSymbols.Free;
  FMemory.Free;
  FCode.Free;
  inherited Destroy;
end;

function TQvmMachine.GetName: AnsiString;
begin
  Result := FName;
end;

function TQvmMachine.GetMemory: IQvmMemory;
begin
  Result := Self;
end;

function TQvmMachine.GetSymbols: IQvmSymbols;
begin
  Result := Self;
end;

function TQvmMachine.GetInfo: TQvmInfo;
begin
  Result.Name := FName;
  Result.CodeLength := FCode.CodeLength;
  Result.TableLength := FCode.InstructionCount * SizeOf(Integer);
  Result.DataLength := FMemory.Size;
end;

function TQvmMachine.GetInstructionCount: Integer;
begin
  Result := FCode.InstructionCount;
end;

function TQvmMachine.GetJumpTargets: TArray<Integer>;
begin
  Result := FJumpTargets;
end;

function TQvmMachine.GetProgramStack: Integer;
begin
  Result := FInterpreter.ProgramStack;
end;

function TQvmMachine.GetStackBottom: Integer;
begin
  Result := FInterpreter.StackBottom;
end;

function TQvmMachine.GetCallDepth: Integer;
begin
  Result := FInterpreter.CallDepth;
end;

function TQvmMachine.GetInstructionsExecuted: Int64;
begin
  Result := FInterpreter.InstructionsExecuted;
end;

function TQvmMachine.GetSystemCallCount: Int64;
begin
  Result := FInterpreter.SystemCallCount;
end;

function TQvmMachine.GetBreakCount: Integer;
begin
  Result := FInterpreter.BreakCount;
end;

function TQvmMachine.GetProfiling: Boolean;
begin
  Result := FInterpreter.Profiling;
end;

procedure TQvmMachine.SetProfiling(AValue: Boolean);
begin
  FInterpreter.Profiling := AValue;
end;

function TQvmMachine.Call(ACommand: Integer; const AArguments: array of Integer): Integer;
begin
  Result := FInterpreter.Call(ACommand, AArguments);
end;

procedure TQvmMachine.Restart(const AFileData: TBytes);
var
  LImage: TQvmImage;
begin
  LImage := TQvmImage.Create(AFileData, FLimits, string(FName));
  try
    FMemory.Load(LImage);
  finally
    LImage.Free;
  end;
end;

function TQvmMachine.StackTrace(AProgramCounter, AProgramStack: Integer): TArray<AnsiString>;
var
  LProgramCounter, LProgramStack: Integer;
begin
  Result := nil;
  LProgramCounter := AProgramCounter;
  LProgramStack := AProgramStack;
  repeat
    Result := Result + [FSymbols.ValueToSymbol(LProgramCounter)];
    // the frame keeps where the caller's frame is (only the debug build of the original writes it) and
    // that one the address it returns to; the reads are checked here
    LProgramStack := FMemory.ReadInt32(LProgramStack + 4);
    LProgramCounter := FMemory.ReadInt32(LProgramStack);
  until (LProgramCounter = -1) or (Length(Result) >= STraceDepth);
end;

function TQvmMachine.GetSize: Integer;
begin
  Result := FMemory.Size;
end;

function TQvmMachine.GetMask: Integer;
begin
  Result := FMemory.Mask;
end;

function TQvmMachine.ArgPtr(AAddress: Integer; ALength: NativeInt): Pointer;
begin
  Result := FMemory.ArgPtr(AAddress, ALength);
end;

function TQvmMachine.Range(AAddress: Integer; ALength: NativeInt): Pointer;
begin
  Result := FMemory.Range(AAddress, ALength);
end;

function TQvmMachine.ReadByte(AAddress: Integer): Byte;
begin
  Result := FMemory.ReadByte(AAddress);
end;

procedure TQvmMachine.WriteByte(AAddress: Integer; AValue: Byte);
begin
  FMemory.WriteByte(AAddress, AValue);
end;

function TQvmMachine.ReadInt32(AAddress: Integer): Integer;
begin
  Result := FMemory.ReadInt32(AAddress);
end;

procedure TQvmMachine.WriteInt32(AAddress: Integer; AValue: Integer);
begin
  FMemory.WriteInt32(AAddress, AValue);
end;

function TQvmMachine.ReadString(AAddress: Integer): AnsiString;
begin
  Result := FMemory.ReadString(AAddress);
end;

procedure TQvmMachine.WriteString(AAddress: Integer; const AText: AnsiString; ABufferSize: Integer);
begin
  FMemory.WriteString(AAddress, AText, ABufferSize);
end;

function TQvmMachine.ReadBytes(AAddress: Integer; ALength: NativeInt): TBytes;
begin
  Result := FMemory.ReadBytes(AAddress, ALength);
end;

procedure TQvmMachine.WriteBytes(AAddress: Integer; const ABytes: TBytes);
begin
  FMemory.WriteBytes(AAddress, ABytes);
end;

procedure TQvmMachine.Fill(AAddress: Integer; AValue: Byte; ALength: NativeInt);
begin
  FMemory.Fill(AAddress, AValue, ALength);
end;

procedure TQvmMachine.Copy(ADestination, ASource: Integer; ALength: NativeInt);
begin
  FMemory.Copy(ADestination, ASource, ALength);
end;

function TQvmMachine.GetCount: Integer;
begin
  Result := FSymbols.Count;
end;

function TQvmMachine.Load(const AText: AnsiString): Integer;
begin
  Result := FSymbols.Load(AText);
end;

function TQvmMachine.ValueToSymbol(AValue: Integer): AnsiString;
begin
  Result := FSymbols.ValueToSymbol(AValue);
end;

function TQvmMachine.SymbolToValue(const AName: AnsiString): Integer;
begin
  Result := FSymbols.SymbolToValue(AName);
end;

function TQvmMachine.TakeProfile: TQvmProfile;
begin
  Result := FSymbols.TakeProfile;
end;

end.
