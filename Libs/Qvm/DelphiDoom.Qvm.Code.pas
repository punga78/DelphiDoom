{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the code prepared for the interpreter             }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of VM_PrepareInterpreter (code/qcommon/vm_interpreted.c), Quake III    }
{  Arena 1.32                                                                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Code;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Types;

const
  /// <summary>
  ///   What fills the code image after the last instruction: not an instruction, so that a program that
  ///   runs off its end is stopped (the original goes on into the hunk)
  /// </summary>
  QVM_CODE_SENTINEL = Integer($7FFFFFFF);

type
  /// <summary>
  ///   The code segment as the interpreter wants it, laid out as the original does: an integer for every
  ///   byte of the file, the instruction at the offset of its byte and its operand in the next slot, so
  ///   that a program counter is the same number the original saves on the program stack. The operand of a
  ///   conditional branch is already the offset of its target.
  ///   Checked here once, so that the interpreter does not have to: every byte is a known instruction,
  ///   every instruction lies inside the segment, every branch goes to an existing instruction
  /// </summary>
  TQvmCode = class
  strict private
    FCodeLength: Integer;
    FInstructionCount: Integer;
    FImage: TArray<Integer>;
    FInstructionPointers: TArray<Integer>;
    FInstructionStart: TArray<Byte>;
    procedure Prepare(const ACode: TBytes; const AName: string);
  public
    /// <summary>Raises EQvmFormatException when the code breaks one of the rules above</summary>
    constructor Create(const ACode: TBytes; AInstructionCount: Integer; const AName: string);
    /// <summary>A program counter where an instruction starts (what a return address must be)</summary>
    function IsInstructionStart(AProgramCounter: Integer): Boolean; inline;
    property CodeLength: Integer read FCodeLength;
    property InstructionCount: Integer read FInstructionCount;
    /// <summary>CodeLength slots and some sentinels</summary>
    property Image: TArray<Integer> read FImage;
    /// <summary>vm->instructionPointers: the offset of every instruction</summary>
    property InstructionPointers: TArray<Integer> read FInstructionPointers;
    /// <summary>1 at the offsets where an instruction starts, CodeLength bytes</summary>
    property InstructionStart: TArray<Byte> read FInstructionStart;
  end;

implementation

uses
  DelphiDoom.Qvm.Opcodes;

const
  SENTINELS = 8;
  // the message of the original
  SPastCode = 'VM_PrepareInterpreter: pc > header->codeLength';
  SBadInstruction = '%s: byte %d at offset %d is not an instruction (Bad VM instruction)';
  SBadTarget = '%s: the branch at offset %d jumps to instruction %d of %d';

{ TQvmCode }

constructor TQvmCode.Create(const ACode: TBytes; AInstructionCount: Integer; const AName: string);
begin
  inherited Create;
  FCodeLength := Length(ACode);
  FInstructionCount := AInstructionCount;
  Prepare(ACode, AName);
end;

function TQvmCode.IsInstructionStart(AProgramCounter: Integer): Boolean;
begin
  Result := (Cardinal(AProgramCounter) < Cardinal(FCodeLength)) and (FInstructionStart[AProgramCounter] <> 0);
end;

procedure TQvmCode.Prepare(const ACode: TBytes; const AName: string);
var
  LInstruction, LProgramCounter, LOpcode, LOperandSize, LTarget, LIndex: Integer;
begin
  SetLength(FImage, FCodeLength + SENTINELS);
  SetLength(FInstructionPointers, FInstructionCount);
  SetLength(FInstructionStart, FCodeLength);

  // we don't need to translate the instructions, but we still need
  // to find each instructions starting point for jumps
  LProgramCounter := 0;
  for LInstruction := 0 to FInstructionCount - 1 do
  begin
    if LProgramCounter >= FCodeLength then
      raise EQvmFormatException.Create(SPastCode);
    FInstructionPointers[LInstruction] := LProgramCounter;
    FInstructionStart[LProgramCounter] := 1;
    LOpcode := ACode[LProgramCounter];
    if LOpcode > OP_LAST then
      raise EQvmFormatException.CreateFmt(SBadInstruction, [AName, LOpcode, LProgramCounter]);
    FImage[LProgramCounter] := LOpcode;
    Inc(LProgramCounter);

    LOperandSize := TQvmOpcodes.OperandSize(LOpcode);
    if LProgramCounter + LOperandSize > FCodeLength then
      raise EQvmFormatException.Create(SPastCode);
    if LOperandSize = 4 then
      FImage[LProgramCounter] := Integer(Cardinal(ACode[LProgramCounter]) or
        (Cardinal(ACode[LProgramCounter + 1]) shl 8) or (Cardinal(ACode[LProgramCounter + 2]) shl 16) or
        (Cardinal(ACode[LProgramCounter + 3]) shl 24))
    else if LOperandSize = 1 then
      FImage[LProgramCounter] := ACode[LProgramCounter];
    Inc(LProgramCounter, LOperandSize);
  end;
  for LIndex := LProgramCounter to High(FImage) do
    FImage[LIndex] := QVM_CODE_SENTINEL;

  // the targets of the branches become offsets; the original does not look at where they go
  for LInstruction := 0 to FInstructionCount - 1 do
  begin
    LProgramCounter := FInstructionPointers[LInstruction];
    if TQvmOpcodes.IsBranch(FImage[LProgramCounter]) then
    begin
      LTarget := FImage[LProgramCounter + 1];
      if Cardinal(LTarget) >= Cardinal(FInstructionCount) then
        raise EQvmFormatException.CreateFmt(SBadTarget, [AName, LProgramCounter, LTarget, FInstructionCount]);
      FImage[LProgramCounter + 1] := FInstructionPointers[LTarget];
    end;
  end;
end;

end.
