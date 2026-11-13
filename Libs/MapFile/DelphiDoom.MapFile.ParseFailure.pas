{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the fatal error of the readers               }
{                                                                              }
{  Written for the port of MapFile.cpp (idlib): the original calls             }
{  <c>src.Error( ... )</c> and returns NULL.                                   }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.ParseFailure;

interface

uses
  DelphiDoom.IdLib.Text.Lexer;

type
  /// <summary>The way the readers report a text that is not valid</summary>
  TMapParseFailure = class
  public
    /// <summary>
    ///   Reports the error to the lexer (<c>src.Error</c>, which raises EIdLexerException with
    ///   "file F, line N: text" unless the lexer has LEXFL_NOFATALERRORS) and, if the lexer
    ///   returns, raises EMapFileException with the same text, so that a reader never goes on
    ///   with a half-read primitive (the original returns NULL)
    /// </summary>
    class procedure Fail(const ASource: TIdLexer; const AFormat: string; const AArgs: array of const); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Types;

{ TMapParseFailure }

class procedure TMapParseFailure.Fail(const ASource: TIdLexer; const AFormat: string; const AArgs: array of const);
begin
  ASource.Error(AFormat, AArgs);
  raise EMapFileException.Create(Format(AFormat, AArgs), ASource.LineNum);
end;

end.
