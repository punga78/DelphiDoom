{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the numbers that every section of .proc has  }
{                                                                              }
{  Written for this library from the loops of RenderWorld_load.cpp.            }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Parse;

interface

uses
  DelphiDoom.IdLib.Text.Lexer;

type
  /// <summary>
  ///   The reading that the sections of a .proc file have in common: a count that must not be
  ///   negative (nor absurd) and a run of integer indexes
  /// </summary>
  TProcParse = class
  public
    /// <summary>
    ///   Reads an integer. A negative value, or one above MAX_PROC_ELEMENTS, is an error of the
    ///   lexer with the message given (the original only checks that it is not negative)
    /// </summary>
    class function ReadCount(const ALexer: TIdLexer; const AMessage: string): Integer; static;
    /// <summary>Reads <c>ACount</c> integers</summary>
    class function ReadIndexes(const ALexer: TIdLexer; const ACount: Integer): TArray<Integer>; static;
  end;

implementation

uses
  DelphiDoom.MapFile.Proc.Types;

{ TProcParse }

class function TProcParse.ReadCount(const ALexer: TIdLexer; const AMessage: string): Integer;
begin
  Result := ALexer.ParseInt;
  if (Result < 0) or (Result > MAX_PROC_ELEMENTS) then
    ALexer.Error('%s', [AMessage]);
end;

class function TProcParse.ReadIndexes(const ALexer: TIdLexer; const ACount: Integer): TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := ALexer.ParseInt;
end;

end.
