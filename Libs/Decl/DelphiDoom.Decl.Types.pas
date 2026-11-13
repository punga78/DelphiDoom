{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - types, constants and the exception        }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclManager.h. Copyright (C) 1999-2011 id Software LLC, a         }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Types;

const
  // declType_t. The number of a type is open: a library registers its own (the first free number is DECL_FIRST_FREE)
  DECL_TABLE = 0;
  DECL_MATERIAL = 1;
  DECL_SKIN = 2;
  DECL_SOUND = 3;
  DECL_ENTITYDEF = 4;
  DECL_MODELDEF = 5;
  DECL_FX = 6;
  DECL_PARTICLE = 7;
  DECL_AF = 8;
  DECL_PDA = 9;
  DECL_VIDEO = 10;
  DECL_AUDIO = 11;
  DECL_EMAIL = 12;
  DECL_MODELEXPORT = 13;
  DECL_MAPDEF = 14;
  DECL_FIRST_FREE = 15;
  /// <summary>The number of types the manager can hold, and the "no type" value of a file without a default type</summary>
  DECL_MAX_TYPES = 32;

  /// <summary>DECL_LEXER_FLAGS: the lexer flags every declaration is read with</summary>
  DECL_LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS or LEXFL_ALLOWPATHNAMES or
    LEXFL_ALLOWMULTICHARLITERALS or LEXFL_ALLOWBACKSLASHSTRINGCONCAT or LEXFL_NOFATALERRORS;

  /// <summary>The flags the PDA, e-mail, video and audio declarations are read with (no NOSTRINGESCAPECHARS)</summary>
  DECL_PDA_LEXER_FLAGS = LEXFL_NOSTRINGCONCAT or LEXFL_ALLOWPATHNAMES or LEXFL_ALLOWMULTICHARLITERALS or
    LEXFL_ALLOWBACKSLASHSTRINGCONCAT or LEXFL_NOFATALERRORS;

type
  /// <summary>declState_t</summary>
  TDeclState = (
    /// <summary>The text is known, it has not been parsed (or it was purged)</summary>
    dsUnparsed,
    /// <summary>A parse failed or there is no text: the default definition of the type is loaded</summary>
    dsDefaulted,
    dsParsed);

  /// <summary>What <c>ListType</c> shows: the decls referenced now, ever, or all of them (listDeclStrings)</summary>
  TDeclListMode = (dlmCurrent, dlmEver, dlmAll);

  /// <summary>
  ///   The errors of the declaration manager: <c>common->Error</c> and <c>FatalError</c> of the original
  ///   (a bad type number, a decl file that cannot be read, a runaway default definition)
  /// </summary>
  EDeclException = class(EIdLibException);

implementation

end.
