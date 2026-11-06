{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the codes of the errors                                                       }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.ErrorCodes;

interface

const
  ERR_NONE = 0;
  ERR_NO_SYMBOL_MEM = 10;
  ERR_IDENTIFIER_TOO_LONG = 11;
  ERR_STRING_TOO_LONG = 12;
  ERR_FILE_NAME_TOO_LONG = 13;
  ERR_MISSING_LPAREN = 14;
  ERR_MISSING_RPAREN = 15;
  ERR_MISSING_SEMICOLON = 16;
  ERR_MISSING_SCRIPT_NUMBER = 17;
  ERR_ALLOC_PCODE_BUFFER = 18;
  ERR_PCODE_BUFFER_OVERFLOW = 19;
  ERR_TOO_MANY_SCRIPTS = 20;
  ERR_SAVE_OBJECT_FAILED = 21;
  ERR_MISSING_LPAREN_SCR = 22;
  ERR_INVALID_IDENTIFIER = 23;
  ERR_REDEFINED_IDENTIFIER = 24;
  ERR_MISSING_COMMA = 25;
  ERR_BAD_VAR_TYPE = 26;
  ERR_TOO_MANY_SCRIPT_ARGS = 27;
  ERR_MISSING_LBRACE_SCR = 28;
  ERR_MISSING_RBRACE_SCR = 29;
  ERR_TOO_MANY_MAP_VARS = 30;
  ERR_MISSING_WVAR_INDEX = 31;
  ERR_BAD_WVAR_INDEX = 32;
  ERR_MISSING_WVAR_COLON = 33;
  ERR_MISSING_SPEC_VAL = 34;
  ERR_MISSING_SPEC_COLON = 35;
  ERR_MISSING_SPEC_ARGC = 36;
  ERR_CANT_READ_FILE = 37;
  ERR_CANT_OPEN_FILE = 38;
  ERR_CANT_OPEN_DBGFILE = 39;
  ERR_INVALID_DIRECTIVE = 40;
  ERR_BAD_DEFINE = 41;
  ERR_INCL_NESTING_TOO_DEEP = 42;
  ERR_STRING_LIT_NOT_FOUND = 43;
  ERR_TOO_MANY_SCRIPT_VARS = 44;
  ERR_INVALID_DECLARATOR = 45;
  ERR_BAD_LSPEC_ARG_COUNT = 46;
  ERR_BAD_ARG_COUNT = 47;
  ERR_UNKNOWN_IDENTIFIER = 48;
  ERR_MISSING_COLON = 49;
  ERR_BAD_EXPR = 50;
  ERR_BAD_CONST_EXPR = 51;
  ERR_NO_DIRECT_VER = 52;
  ERR_ILLEGAL_EXPR_IDENT = 53;
  ERR_EXPR_FUNC_NO_RET_VAL = 54;
  ERR_MISSING_ASSIGN_OP = 55;
  ERR_INCDEC_OP_ON_NON_VAR = 56;
  ERR_MISSING_RBRACE = 57;
  ERR_INVALID_STATEMENT = 58;
  ERR_BAD_DO_STATEMENT = 59;
  ERR_BAD_SCRIPT_DECL = 60;
  ERR_CASE_OVERFLOW = 61;
  ERR_BREAK_OVERFLOW = 62;
  ERR_CONTINUE_OVERFLOW = 63;
  ERR_STATEMENT_OVERFLOW = 64;
  ERR_MISPLACED_BREAK = 65;
  ERR_MISPLACED_CONTINUE = 66;
  ERR_CASE_NOT_IN_SWITCH = 67;
  ERR_DEFAULT_NOT_IN_SWITCH = 68;
  ERR_MULTIPLE_DEFAULT = 69;
  ERR_EXPR_STACK_OVERFLOW = 70;
  ERR_EXPR_STACK_EMPTY = 71;
  ERR_UNKNOWN_CONST_EXPR_PCD = 72;
  ERR_BAD_RADIX_CONSTANT = 73;
  ERR_BAD_ASSIGNMENT = 74;
  ERR_OUT_OF_MEMORY = 75;
  ERR_TOO_MANY_STRINGS = 76;
  ERR_UNKNOWN_PRTYPE = 77;
  ERR_BAD_CHARACTER = 78;
  ERR_ALLOC_SCRIPT_BUFFER = 79;
  /// <summary>A statement that the compiler does not implement (new in this library: the old one looped forever)</summary>
  ERR_STATEMENT_NOT_IMPLEMENTED = 80;

implementation

end.
