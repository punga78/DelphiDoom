{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib text - token types, lexer flags and punctuation ids       }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Token.h, Lexer.h and     }
{  the table default_punctuations of Lexer.cpp. Copyright (C) 1999-2011 id     }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Text.Types;

interface

const
  // token types
  TT_STRING = 1;
  TT_LITERAL = 2;
  TT_NUMBER = 3;
  TT_NAME = 4;
  TT_PUNCTUATION = 5;

  // number sub types
  TT_INTEGER = $00001;
  TT_DECIMAL = $00002;
  TT_HEX = $00004;
  TT_OCTAL = $00008;
  TT_BINARY = $00010;
  TT_LONG = $00020;
  TT_UNSIGNED = $00040;
  TT_FLOAT = $00080;
  TT_SINGLE_PRECISION = $00100;
  TT_DOUBLE_PRECISION = $00200;
  TT_EXTENDED_PRECISION = $00400;
  TT_INFINITE = $00800;
  TT_INDEFINITE = $01000;
  TT_NAN = $02000;
  TT_IPADDRESS = $04000;
  TT_IPPORT = $08000;
  TT_VALUESVALID = $10000;

  // lexer flags (lexerFlags_t)
  LEXFL_NOERRORS = 1 shl 0;
  LEXFL_NOWARNINGS = 1 shl 1;
  LEXFL_NOFATALERRORS = 1 shl 2;
  LEXFL_NOSTRINGCONCAT = 1 shl 3;
  LEXFL_NOSTRINGESCAPECHARS = 1 shl 4;
  LEXFL_NODOLLARPRECOMPILE = 1 shl 5;
  LEXFL_NOBASEINCLUDES = 1 shl 6;
  LEXFL_ALLOWPATHNAMES = 1 shl 7;
  LEXFL_ALLOWNUMBERNAMES = 1 shl 8;
  LEXFL_ALLOWIPADDRESSES = 1 shl 9;
  LEXFL_ALLOWFLOATEXCEPTIONS = 1 shl 10;
  LEXFL_ALLOWMULTICHARLITERALS = 1 shl 11;
  LEXFL_ALLOWBACKSLASHSTRINGCONCAT = 1 shl 12;
  LEXFL_ONLYSTRINGS = 1 shl 13;

  // punctuation ids
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

type
  /// <summary>punctuation_t: the characters of a punctuation and its id</summary>
  TIdPunctuation = record
    Text: AnsiString;
    Id: Integer;
  end;

  TIdPunctuationList = TArray<TIdPunctuation>;

  /// <summary>The punctuation set of the C/C++ lexer (default_punctuations), longer ones first</summary>
  TIdPunctuations = class
  public
    class function Default: TIdPunctuationList; static;
  end;

implementation

const
  DEFAULT_TEXTS: array[0..51] of AnsiString = (
    '>>=', '<<=', '...', '##', '&&', '||', '>=', '<=', '==', '!=', '*=', '/=', '%=', '+=', '-=', '++', '--',
    '&=', '|=', '^=', '>>', '<<', '->', '::', '.*', '*', '/', '%', '+', '-', '=', '&', '|', '^', '~', '!', '>',
    '<', '.', ',', ';', ':', '?', '(', ')', '{', '}', '[', ']', '\', '#', '$');
  DEFAULT_IDS: array[0..51] of Integer = (
    P_RSHIFT_ASSIGN, P_LSHIFT_ASSIGN, P_PARMS, P_PRECOMPMERGE, P_LOGIC_AND, P_LOGIC_OR, P_LOGIC_GEQ,
    P_LOGIC_LEQ, P_LOGIC_EQ, P_LOGIC_UNEQ, P_MUL_ASSIGN, P_DIV_ASSIGN, P_MOD_ASSIGN, P_ADD_ASSIGN,
    P_SUB_ASSIGN, P_INC, P_DEC, P_BIN_AND_ASSIGN, P_BIN_OR_ASSIGN, P_BIN_XOR_ASSIGN, P_RSHIFT, P_LSHIFT,
    P_POINTERREF, P_CPP1, P_CPP2, P_MUL, P_DIV, P_MOD, P_ADD, P_SUB, P_ASSIGN, P_BIN_AND, P_BIN_OR,
    P_BIN_XOR, P_BIN_NOT, P_LOGIC_NOT, P_LOGIC_GREATER, P_LOGIC_LESS, P_REF, P_COMMA, P_SEMICOLON, P_COLON,
    P_QUESTIONMARK, P_PARENTHESESOPEN, P_PARENTHESESCLOSE, P_BRACEOPEN, P_BRACECLOSE, P_SQBRACKETOPEN,
    P_SQBRACKETCLOSE, P_BACKSLASH, P_PRECOMP, P_DOLLAR);

{ TIdPunctuations }

class function TIdPunctuations.Default: TIdPunctuationList;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(DEFAULT_TEXTS));
  for LIndex := 0 to High(DEFAULT_TEXTS) do
  begin
    Result[LIndex].Text := DEFAULT_TEXTS[LIndex];
    Result[LIndex].Id := DEFAULT_IDS[LIndex];
  end;
end;

end.
