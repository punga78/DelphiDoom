{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - what every section of an .aas file has       }
{                                                                              }
{  Written for this library from the Parse functions of idAASFileLocal         }
{  (AASFile.cpp), Doom 3 GPL Source Code.                                      }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Parse;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Text.Lexer;

type
  /// <summary>
  ///   The text of a section is "NAME COUNT {" then one line per element, which starts with the
  ///   number of the element (read and ignored), then "}". The numbers in the parentheses are
  ///   those of the original: values that do not fit the narrow type of a field wrap
  /// </summary>
  TAasParse = class
  public
    /// <summary>Reads the count and the opening brace; the count must be in 0..MAX_AAS_ELEMENTS</summary>
    class function BeginSection(const ALexer: TIdLexer; const AWhat: string): Integer; static;
    /// <summary>Reads the number that starts an element and, if <c>AOpen</c>, the opening parenthesis</summary>
    class procedure BeginElement(const ALexer: TIdLexer; const AOpen: Boolean = True); static;
    class procedure EndElement(const ALexer: TIdLexer); static;
    class procedure EndSection(const ALexer: TIdLexer); static;
  end;

implementation

uses
  DelphiDoom.MapFile.Aas.Types;

resourcestring
  SBadCount = 'bad number of %s';

{ TAasParse }

class function TAasParse.BeginSection(const ALexer: TIdLexer; const AWhat: string): Integer;
begin
  Result := ALexer.ParseInt;
  if (Result < 0) or (Result > MAX_AAS_ELEMENTS) then
    ALexer.Error(SBadCount, [AWhat]);
  ALexer.ExpectTokenString('{');
end;

class procedure TAasParse.BeginElement(const ALexer: TIdLexer; const AOpen: Boolean);
begin
  ALexer.ParseInt;
  if AOpen then
    ALexer.ExpectTokenString('(');
end;

class procedure TAasParse.EndElement(const ALexer: TIdLexer);
begin
  ALexer.ExpectTokenString(')');
end;

class procedure TAasParse.EndSection(const ALexer: TIdLexer);
begin
  ALexer.ExpectTokenString('}');
end;

end.
