{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - types and constants of the script parser of   }
{  Quake III Arena (l_script.h, l_precomp.h)                                   }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib.     }
{  Copyright (C) 1999-2005 Id Software, Inc. Licensed under the GNU General    }
{  Public License, version 2 or later.                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.Types;

interface

uses
  DelphiDoom.MathCore.SoftExtended;

const
  /// <summary>MAX_TOKEN: the longest token</summary>
  Q3_MAX_TOKEN = 1024;

  // script flags
  SCFL_NOERRORS = $0001;
  SCFL_NOWARNINGS = $0002;
  SCFL_NOSTRINGWHITESPACES = $0004;
  SCFL_NOSTRINGESCAPECHARS = $0008;
  SCFL_PRIMITIVE = $0010;
  SCFL_NOBINARYNUMBERS = $0020;
  SCFL_NONUMBERVALUES = $0040;

  // token types
  TT_STRING = 1;
  TT_LITERAL = 2;
  TT_NUMBER = 3;
  TT_NAME = 4;
  TT_PUNCTUATION = 5;

  // number sub types
  TT_DECIMAL = $0008;
  TT_HEX = $0100;
  TT_OCTAL = $0200;
  TT_BINARY = $0400;
  TT_FLOAT = $0800;
  TT_INTEGER = $1000;
  TT_LONG = $2000;
  TT_UNSIGNED = $4000;

  // punctuation sub types
  P_RSHIFT_ASSIGN = 1;
  P_LSHIFT_ASSIGN = 2;
  P_PARMS = 3;
  P_PRECOMPMERGE = 4;
  P_LOGIC_AND = 5;
  P_LOGIC_OR = 6;
  P_LOGIC_GEQ = 7;
  P_LOGIC_LEQ = 8;
  P_LOGIC_EQ = 9;
  P_LOGIC_UNEQ = 10;
  P_MUL_ASSIGN = 11;
  P_DIV_ASSIGN = 12;
  P_MOD_ASSIGN = 13;
  P_ADD_ASSIGN = 14;
  P_SUB_ASSIGN = 15;
  P_INC = 16;
  P_DEC = 17;
  P_BIN_AND_ASSIGN = 18;
  P_BIN_OR_ASSIGN = 19;
  P_BIN_XOR_ASSIGN = 20;
  P_RSHIFT = 21;
  P_LSHIFT = 22;
  P_POINTERREF = 23;
  P_CPP1 = 24;
  P_CPP2 = 25;
  P_MUL = 26;
  P_DIV = 27;
  P_MOD = 28;
  P_ADD = 29;
  P_SUB = 30;
  P_ASSIGN = 31;
  P_BIN_AND = 32;
  P_BIN_OR = 33;
  P_BIN_XOR = 34;
  P_BIN_NOT = 35;
  P_LOGIC_NOT = 36;
  P_LOGIC_GREATER = 37;
  P_LOGIC_LESS = 38;
  P_REF = 39;
  P_COMMA = 40;
  P_SEMICOLON = 41;
  P_COLON = 42;
  P_QUESTIONMARK = 43;
  P_PARENTHESESOPEN = 44;
  P_PARENTHESESCLOSE = 45;
  P_BRACEOPEN = 46;
  P_BRACECLOSE = 47;
  P_SQBRACKETOPEN = 48;
  P_SQBRACKETCLOSE = 49;
  P_BACKSLASH = 50;
  P_PRECOMP = 51;
  P_DOLLAR = 52;

  // print levels of botimport.Print
  Q3_PRT_MESSAGE = 1;
  Q3_PRT_WARNING = 2;
  Q3_PRT_ERROR = 3;

  // define flags and builtins
  DEFINE_FIXED = $0001;
  BUILTIN_LINE = 1;
  BUILTIN_FILE = 2;
  BUILTIN_DATE = 3;
  BUILTIN_TIME = 4;
  BUILTIN_STDC = 5;

  // indents (conditional compilation)
  INDENT_IF = $0001;
  INDENT_ELSE = $0002;
  INDENT_ELIF = $0004;
  INDENT_IFDEF = $0008;
  INDENT_IFNDEF = $0010;

type
  /// <summary>punctuation_t: the text of a punctuation and its number</summary>
  TQ3Punctuation = record
    Text: AnsiString;
    Number: Integer;
  end;

  TQ3PunctuationArray = array of TQ3Punctuation;

  /// <summary>
  ///   token_t. The text stops at the first zero byte as the C string does (the length that a string token
  ///   keeps in Subtype still counts the zero). The whitespace pointers of the C are offsets in the script
  ///   (0 is NULL: they are only ever subtracted)
  /// </summary>
  TQ3Token = record
    Text: AnsiString;
    TokenType: Integer;
    Subtype: Integer;
    /// <summary>unsigned long (32 bit on Windows)</summary>
    IntValue: Cardinal;
    /// <summary>long double: the 80 bit x87, in software, so that Win32 and Win64 give the same bits</summary>
    FloatValue: TSoftExtended;
    WhitespaceOffset: Integer;
    EndWhitespaceOffset: Integer;
    Line: Integer;
    LinesCrossed: Integer;
  end;

  /// <summary>pc_token_t: what the engine gets from PC_ReadTokenHandle (float, not long double)</summary>
  TQ3PcToken = record
    TokenType: Integer;
    Subtype: Integer;
    IntValue: Integer;
    FloatValue: Single;
    Text: AnsiString;
  end;

  /// <summary>The time that __DATE__ and __TIME__ expand to (the C reads the clock of the machine)</summary>
  TQ3NowProvider = reference to function: TDateTime;

implementation

end.
