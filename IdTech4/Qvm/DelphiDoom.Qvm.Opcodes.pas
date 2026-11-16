{******************************************************************************}
{                                                                              }
{  DelphiDoom: QVM library - the instructions of the virtual machine           }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Port of opcode_t (code/qcommon/vm_local.h) and of opnames                   }
{  (vm_interpreted.c), Quake III Arena 1.32                                    }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Qvm.Opcodes;

interface

const
  OP_UNDEF = 0;
  OP_IGNORE = 1;
  OP_BREAK = 2;
  OP_ENTER = 3;
  OP_LEAVE = 4;
  OP_CALL = 5;
  OP_PUSH = 6;
  OP_POP = 7;
  OP_CONST = 8;
  OP_LOCAL = 9;
  OP_JUMP = 10;
  OP_EQ = 11;
  OP_NE = 12;
  OP_LTI = 13;
  OP_LEI = 14;
  OP_GTI = 15;
  OP_GEI = 16;
  OP_LTU = 17;
  OP_LEU = 18;
  OP_GTU = 19;
  OP_GEU = 20;
  OP_EQF = 21;
  OP_NEF = 22;
  OP_LTF = 23;
  OP_LEF = 24;
  OP_GTF = 25;
  OP_GEF = 26;
  OP_LOAD1 = 27;
  OP_LOAD2 = 28;
  OP_LOAD4 = 29;
  OP_STORE1 = 30;
  OP_STORE2 = 31;
  OP_STORE4 = 32;
  OP_ARG = 33;
  OP_BLOCK_COPY = 34;
  OP_SEX8 = 35;
  OP_SEX16 = 36;
  OP_NEGI = 37;
  OP_ADD = 38;
  OP_SUB = 39;
  OP_DIVI = 40;
  OP_DIVU = 41;
  OP_MODI = 42;
  OP_MODU = 43;
  OP_MULI = 44;
  OP_MULU = 45;
  OP_BAND = 46;
  OP_BOR = 47;
  OP_BXOR = 48;
  OP_BCOM = 49;
  OP_LSH = 50;
  OP_RSHI = 51;
  OP_RSHU = 52;
  OP_NEGF = 53;
  OP_ADDF = 54;
  OP_SUBF = 55;
  OP_DIVF = 56;
  OP_MULF = 57;
  OP_CVIF = 58;
  OP_CVFI = 59;
  /// <summary>The last instruction the machine knows</summary>
  OP_LAST = OP_CVFI;

type
  /// <summary>What the bytes of the code segment mean</summary>
  TQvmOpcodes = class
  public
    /// <summary>The bytes that follow the instruction in the file: 4 (a constant or a target), 1 (OP_ARG) or 0</summary>
    class function OperandSize(const AOpcode: Integer): Integer; static;
    /// <summary>The operand is the number of the instruction to jump to (the conditional branches)</summary>
    class function IsBranch(const AOpcode: Integer): Boolean; static; inline;
    /// <summary>opnames: 'OP_CONST'; empty for a byte that is not an instruction</summary>
    class function Name(const AOpcode: Integer): string; static;
  end;

implementation

const
  NAMES: array[0..OP_LAST] of string = (
    'OP_UNDEF', 'OP_IGNORE', 'OP_BREAK', 'OP_ENTER', 'OP_LEAVE', 'OP_CALL', 'OP_PUSH', 'OP_POP', 'OP_CONST',
    'OP_LOCAL', 'OP_JUMP', 'OP_EQ', 'OP_NE', 'OP_LTI', 'OP_LEI', 'OP_GTI', 'OP_GEI', 'OP_LTU', 'OP_LEU',
    'OP_GTU', 'OP_GEU', 'OP_EQF', 'OP_NEF', 'OP_LTF', 'OP_LEF', 'OP_GTF', 'OP_GEF', 'OP_LOAD1', 'OP_LOAD2',
    'OP_LOAD4', 'OP_STORE1', 'OP_STORE2', 'OP_STORE4', 'OP_ARG', 'OP_BLOCK_COPY', 'OP_SEX8', 'OP_SEX16',
    'OP_NEGI', 'OP_ADD', 'OP_SUB', 'OP_DIVI', 'OP_DIVU', 'OP_MODI', 'OP_MODU', 'OP_MULI', 'OP_MULU', 'OP_BAND',
    'OP_BOR', 'OP_BXOR', 'OP_BCOM', 'OP_LSH', 'OP_RSHI', 'OP_RSHU', 'OP_NEGF', 'OP_ADDF', 'OP_SUBF', 'OP_DIVF',
    'OP_MULF', 'OP_CVIF', 'OP_CVFI');

{ TQvmOpcodes }

class function TQvmOpcodes.OperandSize(const AOpcode: Integer): Integer;
begin
  // "these are the only opcodes that aren't a single byte"
  case AOpcode of
    OP_ENTER, OP_LEAVE, OP_CONST, OP_LOCAL, OP_EQ..OP_GEF, OP_BLOCK_COPY:
      Result := 4;
    OP_ARG:
      Result := 1;
  else
    Result := 0;
  end;
end;

class function TQvmOpcodes.IsBranch(const AOpcode: Integer): Boolean;
begin
  Result := (AOpcode >= OP_EQ) and (AOpcode <= OP_GEF);
end;

class function TQvmOpcodes.Name(const AOpcode: Integer): string;
begin
  if (AOpcode >= 0) and (AOpcode <= OP_LAST) then
    Result := NAMES[AOpcode]
  else
    Result := '';
end;

end.
