{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the tokens of the language                                                    }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Tokens;

interface

const
  TK_NONE = 0;
  TK_EOF = 1;
  TK_IDENTIFIER = 2;  // VALUE: (char *) tk_Text
  TK_STRING = 3;  // VALUE: (char *) tk_Text
  TK_NUMBER = 4;  // VALUE: (int) tk_Num
  TK_LINESPECIAL = 5;  // VALUE: (int) tk_LineSpecial
  TK_PLUS = 6;  // '+'
  TK_MINUS = 7;  // '-'
  TK_ASTERISK = 8;  // '*'
  TK_SLASH = 9;  // '/'
  TK_PERCENT = 10;  // '%'
  TK_ASSIGN = 11;  // '='
  TK_ADDASSIGN = 12;  // '+='
  TK_SUBASSIGN = 13;  // '-='
  TK_MULASSIGN = 14;  // '*='
  TK_DIVASSIGN = 15;  // '/='
  TK_MODASSIGN = 16;  // '%='
  TK_INC = 17;  // '++'
  TK_DEC = 18;  // '--'
  TK_EQ = 19;  // '=='
  TK_NE = 20;  // '!='
  TK_LT = 21;  // '<'
  TK_GT = 22;  // '>'
  TK_LE = 23;  // '<='
  TK_GE = 24;  // '>='
  TK_LSHIFT = 25;  // '<<'
  TK_RSHIFT = 26;  // '>>'
  TK_ANDLOGICAL = 27;  // '&&'
  TK_ORLOGICAL = 28;  // '||'
  TK_ANDBITWISE = 29;  // '&'
  TK_ORBITWISE = 30;  // '|'
  TK_EORBITWISE = 31;  // '^'
  TK_TILDE = 32;  // '~'
  TK_LPAREN = 33;  // '('
  TK_RPAREN = 34;  // ')'
  TK_LBRACE = 35;  // '{'
  TK_RBRACE = 36;  // '}'
  TK_LBRACKET = 37;  // '['
  TK_RBRACKET = 38;  // ']'
  TK_COLON = 39;  // ':'
  TK_SEMICOLON = 40;  // ';'
  TK_COMMA = 41;  // ''
  TK_PERIOD = 42;  // '.'
  TK_NOT = 43;  // '!'
  TK_NUMBERSIGN = 44;  // '#'
  TK_CPPCOMMENT = 45;  // '//'
  TK_STARTCOMMENT = 46;  // '/*'
  TK_ENDCOMMENT = 47;  // '*/'
  TK_BREAK = 48;  // 'break'
  TK_CASE = 49;  // 'case'
  TK_CONST = 50;  // 'const'
  TK_CONTINUE = 51;  // 'continue'
  TK_DEFAULT = 52;  // 'default'
  TK_DEFINE = 53;  // 'define'
  TK_DO = 54;  // 'do'
  TK_ELSE = 55;  // 'else'
  TK_FOR = 56;  // 'for'
  TK_GOTO = 57;  // 'goto'
  TK_IF = 58;  // 'if'
  TK_INCLUDE = 59;  // 'include'
  TK_INT = 60;  // 'int'
  TK_OPEN = 61;  // 'open'
  TK_PRINT = 62;  // 'print'
  TK_PRINTBOLD = 63;  // 'printbold'
  TK_RESTART = 64;  // 'restart'
  TK_SCRIPT = 65;  // 'script'
  TK_SPECIAL = 66;  // 'special'
  TK_STR = 67;  // 'str'
  TK_SUSPEND = 68;  // 'suspend'
  TK_SWITCH = 69;  // 'switch'
  TK_TERMINATE = 70;  // 'terminate'
  TK_UNTIL = 71;  // 'until'
  TK_VOID = 72;  // 'void'
  TK_WHILE = 73;  // 'while'
  TK_WORLD = 74;  // 'world'

  // the class of a character, for the tokenizer
  CHR_EOF = 0;
  CHR_LETTER = 1;
  CHR_NUMBER = 2;
  CHR_QUOTE = 3;
  CHR_SPECIAL = 4;

implementation

end.
