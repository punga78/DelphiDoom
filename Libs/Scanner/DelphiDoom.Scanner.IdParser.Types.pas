{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - constants of the idTech 4 parser              }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\Parser.h, Parser.cpp.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdParser.Types;

interface

const
  /// <summary>Builtin defines (BUILTIN_*)</summary>
  BUILTIN_LINE = 1;
  BUILTIN_FILE = 2;
  BUILTIN_DATE = 3;
  BUILTIN_TIME = 4;
  BUILTIN_STDC = 5;

  /// <summary>Kinds of conditional compilation indents (INDENT_*)</summary>
  INDENT_IF = $0001;
  INDENT_ELSE = $0002;
  INDENT_ELIF = $0004;
  INDENT_IFDEF = $0008;
  INDENT_IFNDEF = $0010;

  /// <summary>A define that cannot be redefined or undefined (builtin ones)</summary>
  DEFINE_FIXED = $0001;

  /// <summary>Token flag: the name is the define it belongs to (recursion is removed)</summary>
  TOKEN_FL_RECURSIVE_DEFINE = 1;

  /// <summary>The most parameters a macro call can have</summary>
  MAX_DEFINEPARMS = 128;
  /// <summary>The buckets of the table of defines (a power of two)</summary>
  DEFINEHASHSIZE = 2048;
  /// <summary>The limits of the #if evaluator (MAX_VALUES, MAX_OPERATORS)</summary>
  MAX_VALUES = 64;
  MAX_OPERATORS = 64;

implementation

end.
