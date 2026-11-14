{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - the opcodes of the virtual machine    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script\             }
{  Script_Compiler.h, Script_Compiler.cpp (idCompiler::opcodes). Copyright     }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company.                     }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Opcodes;

interface

uses
  DelphiDoom.DoomScript.Types;

const
  OP_RETURN = 0;
  OP_UINC_F = 1;
  OP_UINCP_F = 2;
  OP_UDEC_F = 3;
  OP_UDECP_F = 4;
  OP_COMP_F = 5;
  OP_MUL_F = 6;
  OP_MUL_V = 7;
  OP_MUL_FV = 8;
  OP_MUL_VF = 9;
  OP_DIV_F = 10;
  OP_MOD_F = 11;
  OP_ADD_F = 12;
  OP_ADD_V = 13;
  OP_ADD_S = 14;
  OP_ADD_FS = 15;
  OP_ADD_SF = 16;
  OP_ADD_VS = 17;
  OP_ADD_SV = 18;
  OP_SUB_F = 19;
  OP_SUB_V = 20;
  OP_EQ_F = 21;
  OP_EQ_V = 22;
  OP_EQ_S = 23;
  OP_EQ_E = 24;
  OP_EQ_EO = 25;
  OP_EQ_OE = 26;
  OP_EQ_OO = 27;
  OP_NE_F = 28;
  OP_NE_V = 29;
  OP_NE_S = 30;
  OP_NE_E = 31;
  OP_NE_EO = 32;
  OP_NE_OE = 33;
  OP_NE_OO = 34;
  OP_LE = 35;
  OP_GE = 36;
  OP_LT = 37;
  OP_GT = 38;
  OP_INDIRECT_F = 39;
  OP_INDIRECT_V = 40;
  OP_INDIRECT_S = 41;
  OP_INDIRECT_ENT = 42;
  OP_INDIRECT_BOOL = 43;
  OP_INDIRECT_OBJ = 44;
  OP_ADDRESS = 45;
  OP_EVENTCALL = 46;
  OP_OBJECTCALL = 47;
  OP_SYSCALL = 48;
  OP_STORE_F = 49;
  OP_STORE_V = 50;
  OP_STORE_S = 51;
  OP_STORE_ENT = 52;
  OP_STORE_BOOL = 53;
  OP_STORE_OBJENT = 54;
  OP_STORE_OBJ = 55;
  OP_STORE_ENTOBJ = 56;
  OP_STORE_FTOS = 57;
  OP_STORE_BTOS = 58;
  OP_STORE_VTOS = 59;
  OP_STORE_FTOBOOL = 60;
  OP_STORE_BOOLTOF = 61;
  OP_STOREP_F = 62;
  OP_STOREP_V = 63;
  OP_STOREP_S = 64;
  OP_STOREP_ENT = 65;
  OP_STOREP_FLD = 66;
  OP_STOREP_BOOL = 67;
  OP_STOREP_OBJ = 68;
  OP_STOREP_OBJENT = 69;
  OP_STOREP_FTOS = 70;
  OP_STOREP_BTOS = 71;
  OP_STOREP_VTOS = 72;
  OP_STOREP_FTOBOOL = 73;
  OP_STOREP_BOOLTOF = 74;
  OP_UMUL_F = 75;
  OP_UMUL_V = 76;
  OP_UDIV_F = 77;
  OP_UDIV_V = 78;
  OP_UMOD_F = 79;
  OP_UADD_F = 80;
  OP_UADD_V = 81;
  OP_USUB_F = 82;
  OP_USUB_V = 83;
  OP_UAND_F = 84;
  OP_UOR_F = 85;
  OP_NOT_BOOL = 86;
  OP_NOT_F = 87;
  OP_NOT_V = 88;
  OP_NOT_S = 89;
  OP_NOT_ENT = 90;
  OP_NEG_F = 91;
  OP_NEG_V = 92;
  OP_INT_F = 93;
  OP_IF = 94;
  OP_IFNOT = 95;
  OP_CALL = 96;
  OP_THREAD = 97;
  OP_OBJTHREAD = 98;
  OP_PUSH_F = 99;
  OP_PUSH_V = 100;
  OP_PUSH_S = 101;
  OP_PUSH_ENT = 102;
  OP_PUSH_OBJ = 103;
  OP_PUSH_OBJENT = 104;
  OP_PUSH_FTOS = 105;
  OP_PUSH_BTOF = 106;
  OP_PUSH_FTOB = 107;
  OP_PUSH_VTOS = 108;
  OP_PUSH_BTOS = 109;
  OP_GOTO = 110;
  OP_AND = 111;
  OP_AND_BOOLF = 112;
  OP_AND_FBOOL = 113;
  OP_AND_BOOLBOOL = 114;
  OP_OR = 115;
  OP_OR_BOOLF = 116;
  OP_OR_FBOOL = 117;
  OP_OR_BOOLBOOL = 118;
  OP_BITAND = 119;
  OP_BITOR = 120;
  OP_BREAK = 121;
  OP_CONTINUE = 122;
  NUM_OPCODES = 123;

  // the priorities of the expression parser
  DS_FUNCTION_PRIORITY = 2;
  DS_INT_PRIORITY = 2;
  DS_NOT_PRIORITY = 5;
  DS_TILDE_PRIORITY = 5;
  DS_TOP_PRIORITY = 7;

type
  /// <summary>
  ///   opcode_t: the operator text the compiler looks for, the name the disassembler prints, the priority
  ///   and the kinds of the three operands (the def_* of the original, here the kind of the built-in def)
  /// </summary>
  TDoomScriptOpcode = record
    Name: AnsiString;
    OpName: AnsiString;
    Priority: Integer;
    RightAssociative: Boolean;
    TypeA: TDoomScriptEType;
    TypeB: TDoomScriptEType;
    TypeC: TDoomScriptEType;
  end;

const
  /// <summary>
  ///   idCompiler::opcodes, entry by entry as in the original, oddities included (NOT_S takes a vector,
  ///   two entries are called STORE_OBJENT, DIV_F prints as DIV and INDIRECT_ENT as INDIRECT_E)
  /// </summary>
  DoomScriptOpcodes: array[0..NUM_OPCODES - 1] of TDoomScriptOpcode = (
    (Name: '<RETURN>'; OpName: 'RETURN'; Priority: -1; RightAssociative: False; TypeA: evVoid; TypeB: evVoid; TypeC: evVoid),
    (Name: '++'; OpName: 'UINC_F'; Priority: 1; RightAssociative: True; TypeA: evFloat; TypeB: evVoid; TypeC: evVoid),
    (Name: '++'; OpName: 'UINCP_F'; Priority: 1; RightAssociative: True; TypeA: evObject; TypeB: evField; TypeC: evFloat),
    (Name: '--'; OpName: 'UDEC_F'; Priority: 1; RightAssociative: True; TypeA: evFloat; TypeB: evVoid; TypeC: evVoid),
    (Name: '--'; OpName: 'UDECP_F'; Priority: 1; RightAssociative: True; TypeA: evObject; TypeB: evField; TypeC: evFloat),
    (Name: '~'; OpName: 'COMP_F'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evVoid; TypeC: evFloat),
    (Name: '*'; OpName: 'MUL_F'; Priority: 3; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '*'; OpName: 'MUL_V'; Priority: 3; RightAssociative: False; TypeA: evVector; TypeB: evVector; TypeC: evFloat),
    (Name: '*'; OpName: 'MUL_FV'; Priority: 3; RightAssociative: False; TypeA: evFloat; TypeB: evVector; TypeC: evVector),
    (Name: '*'; OpName: 'MUL_VF'; Priority: 3; RightAssociative: False; TypeA: evVector; TypeB: evFloat; TypeC: evVector),
    (Name: '/'; OpName: 'DIV'; Priority: 3; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '%'; OpName: 'MOD_F'; Priority: 3; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '+'; OpName: 'ADD_F'; Priority: 4; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '+'; OpName: 'ADD_V'; Priority: 4; RightAssociative: False; TypeA: evVector; TypeB: evVector; TypeC: evVector),
    (Name: '+'; OpName: 'ADD_S'; Priority: 4; RightAssociative: False; TypeA: evString; TypeB: evString; TypeC: evString),
    (Name: '+'; OpName: 'ADD_FS'; Priority: 4; RightAssociative: False; TypeA: evFloat; TypeB: evString; TypeC: evString),
    (Name: '+'; OpName: 'ADD_SF'; Priority: 4; RightAssociative: False; TypeA: evString; TypeB: evFloat; TypeC: evString),
    (Name: '+'; OpName: 'ADD_VS'; Priority: 4; RightAssociative: False; TypeA: evVector; TypeB: evString; TypeC: evString),
    (Name: '+'; OpName: 'ADD_SV'; Priority: 4; RightAssociative: False; TypeA: evString; TypeB: evVector; TypeC: evString),
    (Name: '-'; OpName: 'SUB_F'; Priority: 4; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '-'; OpName: 'SUB_V'; Priority: 4; RightAssociative: False; TypeA: evVector; TypeB: evVector; TypeC: evVector),
    (Name: '=='; OpName: 'EQ_F'; Priority: 5; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '=='; OpName: 'EQ_V'; Priority: 5; RightAssociative: False; TypeA: evVector; TypeB: evVector; TypeC: evFloat),
    (Name: '=='; OpName: 'EQ_S'; Priority: 5; RightAssociative: False; TypeA: evString; TypeB: evString; TypeC: evFloat),
    (Name: '=='; OpName: 'EQ_E'; Priority: 5; RightAssociative: False; TypeA: evEntity; TypeB: evEntity; TypeC: evFloat),
    (Name: '=='; OpName: 'EQ_EO'; Priority: 5; RightAssociative: False; TypeA: evEntity; TypeB: evObject; TypeC: evFloat),
    (Name: '=='; OpName: 'EQ_OE'; Priority: 5; RightAssociative: False; TypeA: evObject; TypeB: evEntity; TypeC: evFloat),
    (Name: '=='; OpName: 'EQ_OO'; Priority: 5; RightAssociative: False; TypeA: evObject; TypeB: evObject; TypeC: evFloat),
    (Name: '!='; OpName: 'NE_F'; Priority: 5; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '!='; OpName: 'NE_V'; Priority: 5; RightAssociative: False; TypeA: evVector; TypeB: evVector; TypeC: evFloat),
    (Name: '!='; OpName: 'NE_S'; Priority: 5; RightAssociative: False; TypeA: evString; TypeB: evString; TypeC: evFloat),
    (Name: '!='; OpName: 'NE_E'; Priority: 5; RightAssociative: False; TypeA: evEntity; TypeB: evEntity; TypeC: evFloat),
    (Name: '!='; OpName: 'NE_EO'; Priority: 5; RightAssociative: False; TypeA: evEntity; TypeB: evObject; TypeC: evFloat),
    (Name: '!='; OpName: 'NE_OE'; Priority: 5; RightAssociative: False; TypeA: evObject; TypeB: evEntity; TypeC: evFloat),
    (Name: '!='; OpName: 'NE_OO'; Priority: 5; RightAssociative: False; TypeA: evObject; TypeB: evObject; TypeC: evFloat),
    (Name: '<='; OpName: 'LE'; Priority: 5; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '>='; OpName: 'GE'; Priority: 5; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '<'; OpName: 'LT'; Priority: 5; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '>'; OpName: 'GT'; Priority: 5; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '.'; OpName: 'INDIRECT_F'; Priority: 1; RightAssociative: False; TypeA: evObject; TypeB: evField; TypeC: evFloat),
    (Name: '.'; OpName: 'INDIRECT_V'; Priority: 1; RightAssociative: False; TypeA: evObject; TypeB: evField; TypeC: evVector),
    (Name: '.'; OpName: 'INDIRECT_S'; Priority: 1; RightAssociative: False; TypeA: evObject; TypeB: evField; TypeC: evString),
    (Name: '.'; OpName: 'INDIRECT_E'; Priority: 1; RightAssociative: False; TypeA: evObject; TypeB: evField; TypeC: evEntity),
    (Name: '.'; OpName: 'INDIRECT_BOOL'; Priority: 1; RightAssociative: False; TypeA: evObject; TypeB: evField; TypeC: evBoolean),
    (Name: '.'; OpName: 'INDIRECT_OBJ'; Priority: 1; RightAssociative: False; TypeA: evObject; TypeB: evField; TypeC: evObject),
    (Name: '.'; OpName: 'ADDRESS'; Priority: 1; RightAssociative: False; TypeA: evEntity; TypeB: evField; TypeC: evPointer),
    (Name: '.'; OpName: 'EVENTCALL'; Priority: 2; RightAssociative: False; TypeA: evEntity; TypeB: evFunction; TypeC: evVoid),
    (Name: '.'; OpName: 'OBJECTCALL'; Priority: 2; RightAssociative: False; TypeA: evObject; TypeB: evFunction; TypeC: evVoid),
    (Name: '.'; OpName: 'SYSCALL'; Priority: 2; RightAssociative: False; TypeA: evVoid; TypeB: evFunction; TypeC: evVoid),
    (Name: '='; OpName: 'STORE_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '='; OpName: 'STORE_V'; Priority: 6; RightAssociative: True; TypeA: evVector; TypeB: evVector; TypeC: evVector),
    (Name: '='; OpName: 'STORE_S'; Priority: 6; RightAssociative: True; TypeA: evString; TypeB: evString; TypeC: evString),
    (Name: '='; OpName: 'STORE_ENT'; Priority: 6; RightAssociative: True; TypeA: evEntity; TypeB: evEntity; TypeC: evEntity),
    (Name: '='; OpName: 'STORE_BOOL'; Priority: 6; RightAssociative: True; TypeA: evBoolean; TypeB: evBoolean; TypeC: evBoolean),
    (Name: '='; OpName: 'STORE_OBJENT'; Priority: 6; RightAssociative: True; TypeA: evObject; TypeB: evEntity; TypeC: evObject),
    (Name: '='; OpName: 'STORE_OBJ'; Priority: 6; RightAssociative: True; TypeA: evObject; TypeB: evObject; TypeC: evObject),
    (Name: '='; OpName: 'STORE_OBJENT'; Priority: 6; RightAssociative: True; TypeA: evEntity; TypeB: evObject; TypeC: evObject),
    (Name: '='; OpName: 'STORE_FTOS'; Priority: 6; RightAssociative: True; TypeA: evString; TypeB: evFloat; TypeC: evString),
    (Name: '='; OpName: 'STORE_BTOS'; Priority: 6; RightAssociative: True; TypeA: evString; TypeB: evBoolean; TypeC: evString),
    (Name: '='; OpName: 'STORE_VTOS'; Priority: 6; RightAssociative: True; TypeA: evString; TypeB: evVector; TypeC: evString),
    (Name: '='; OpName: 'STORE_FTOBOOL'; Priority: 6; RightAssociative: True; TypeA: evBoolean; TypeB: evFloat; TypeC: evBoolean),
    (Name: '='; OpName: 'STORE_BOOLTOF'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evBoolean; TypeC: evFloat),
    (Name: '='; OpName: 'STOREP_F'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evFloat; TypeC: evFloat),
    (Name: '='; OpName: 'STOREP_V'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evVector; TypeC: evVector),
    (Name: '='; OpName: 'STOREP_S'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evString; TypeC: evString),
    (Name: '='; OpName: 'STOREP_ENT'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evEntity; TypeC: evEntity),
    (Name: '='; OpName: 'STOREP_FLD'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evField; TypeC: evField),
    (Name: '='; OpName: 'STOREP_BOOL'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evBoolean; TypeC: evBoolean),
    (Name: '='; OpName: 'STOREP_OBJ'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evObject; TypeC: evObject),
    (Name: '='; OpName: 'STOREP_OBJENT'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evObject; TypeC: evObject),
    (Name: '<=>'; OpName: 'STOREP_FTOS'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evFloat; TypeC: evString),
    (Name: '<=>'; OpName: 'STOREP_BTOS'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evBoolean; TypeC: evString),
    (Name: '<=>'; OpName: 'STOREP_VTOS'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evVector; TypeC: evString),
    (Name: '<=>'; OpName: 'STOREP_FTOBOOL'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evFloat; TypeC: evBoolean),
    (Name: '<=>'; OpName: 'STOREP_BOOLTOF'; Priority: 6; RightAssociative: True; TypeA: evPointer; TypeB: evBoolean; TypeC: evFloat),
    (Name: '*='; OpName: 'UMUL_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '*='; OpName: 'UMUL_V'; Priority: 6; RightAssociative: True; TypeA: evVector; TypeB: evFloat; TypeC: evVoid),
    (Name: '/='; OpName: 'UDIV_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '/='; OpName: 'UDIV_V'; Priority: 6; RightAssociative: True; TypeA: evVector; TypeB: evFloat; TypeC: evVoid),
    (Name: '%='; OpName: 'UMOD_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '+='; OpName: 'UADD_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '+='; OpName: 'UADD_V'; Priority: 6; RightAssociative: True; TypeA: evVector; TypeB: evVector; TypeC: evVoid),
    (Name: '-='; OpName: 'USUB_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '-='; OpName: 'USUB_V'; Priority: 6; RightAssociative: True; TypeA: evVector; TypeB: evVector; TypeC: evVoid),
    (Name: '&='; OpName: 'UAND_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '|='; OpName: 'UOR_F'; Priority: 6; RightAssociative: True; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '!'; OpName: 'NOT_BOOL'; Priority: -1; RightAssociative: False; TypeA: evBoolean; TypeB: evVoid; TypeC: evFloat),
    (Name: '!'; OpName: 'NOT_F'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evVoid; TypeC: evFloat),
    (Name: '!'; OpName: 'NOT_V'; Priority: -1; RightAssociative: False; TypeA: evVector; TypeB: evVoid; TypeC: evFloat),
    (Name: '!'; OpName: 'NOT_S'; Priority: -1; RightAssociative: False; TypeA: evVector; TypeB: evVoid; TypeC: evFloat),
    (Name: '!'; OpName: 'NOT_ENT'; Priority: -1; RightAssociative: False; TypeA: evEntity; TypeB: evVoid; TypeC: evFloat),
    (Name: '<NEG_F>'; OpName: 'NEG_F'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evVoid; TypeC: evFloat),
    (Name: '<NEG_V>'; OpName: 'NEG_V'; Priority: -1; RightAssociative: False; TypeA: evVector; TypeB: evVoid; TypeC: evVector),
    (Name: 'int'; OpName: 'INT_F'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evVoid; TypeC: evFloat),
    (Name: '<IF>'; OpName: 'IF'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evJumpOffset; TypeC: evVoid),
    (Name: '<IFNOT>'; OpName: 'IFNOT'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evJumpOffset; TypeC: evVoid),
    (Name: '<CALL>'; OpName: 'CALL'; Priority: -1; RightAssociative: False; TypeA: evFunction; TypeB: evArgSize; TypeC: evVoid),
    (Name: '<THREAD>'; OpName: 'THREAD'; Priority: -1; RightAssociative: False; TypeA: evFunction; TypeB: evArgSize; TypeC: evVoid),
    (Name: '<THREAD>'; OpName: 'OBJTHREAD'; Priority: -1; RightAssociative: False; TypeA: evFunction; TypeB: evArgSize; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_F'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_V'; Priority: -1; RightAssociative: False; TypeA: evVector; TypeB: evVector; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_S'; Priority: -1; RightAssociative: False; TypeA: evString; TypeB: evString; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_ENT'; Priority: -1; RightAssociative: False; TypeA: evEntity; TypeB: evEntity; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_OBJ'; Priority: -1; RightAssociative: False; TypeA: evObject; TypeB: evObject; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_OBJENT'; Priority: -1; RightAssociative: False; TypeA: evEntity; TypeB: evObject; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_FTOS'; Priority: -1; RightAssociative: False; TypeA: evString; TypeB: evFloat; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_BTOF'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evBoolean; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_FTOB'; Priority: -1; RightAssociative: False; TypeA: evBoolean; TypeB: evFloat; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_VTOS'; Priority: -1; RightAssociative: False; TypeA: evString; TypeB: evVector; TypeC: evVoid),
    (Name: '<PUSH>'; OpName: 'PUSH_BTOS'; Priority: -1; RightAssociative: False; TypeA: evString; TypeB: evBoolean; TypeC: evVoid),
    (Name: '<GOTO>'; OpName: 'GOTO'; Priority: -1; RightAssociative: False; TypeA: evJumpOffset; TypeB: evVoid; TypeC: evVoid),
    (Name: '&&'; OpName: 'AND'; Priority: 7; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '&&'; OpName: 'AND_BOOLF'; Priority: 7; RightAssociative: False; TypeA: evBoolean; TypeB: evFloat; TypeC: evFloat),
    (Name: '&&'; OpName: 'AND_FBOOL'; Priority: 7; RightAssociative: False; TypeA: evFloat; TypeB: evBoolean; TypeC: evFloat),
    (Name: '&&'; OpName: 'AND_BOOLBOOL'; Priority: 7; RightAssociative: False; TypeA: evBoolean; TypeB: evBoolean; TypeC: evFloat),
    (Name: '||'; OpName: 'OR'; Priority: 7; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '||'; OpName: 'OR_BOOLF'; Priority: 7; RightAssociative: False; TypeA: evBoolean; TypeB: evFloat; TypeC: evFloat),
    (Name: '||'; OpName: 'OR_FBOOL'; Priority: 7; RightAssociative: False; TypeA: evFloat; TypeB: evBoolean; TypeC: evFloat),
    (Name: '||'; OpName: 'OR_BOOLBOOL'; Priority: 7; RightAssociative: False; TypeA: evBoolean; TypeB: evBoolean; TypeC: evFloat),
    (Name: '&'; OpName: 'BITAND'; Priority: 3; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '|'; OpName: 'BITOR'; Priority: 3; RightAssociative: False; TypeA: evFloat; TypeB: evFloat; TypeC: evFloat),
    (Name: '<BREAK>'; OpName: 'BREAK'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evVoid; TypeC: evVoid),
    (Name: '<CONTINUE>'; OpName: 'CONTINUE'; Priority: -1; RightAssociative: False; TypeA: evFloat; TypeB: evVoid; TypeC: evVoid)
  );

implementation

end.
