{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib core - the exceptions that replace common->Error          }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3), see README.md of Libs\IdLib.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later; the      }
{  parts derived from Doom 3 are GPL v3 with the additional terms of id.       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Core.Exceptions;

interface

uses
  System.SysUtils;

type
  /// <summary>Base class of the errors of the idLib ports (<c>common->Error</c> / <c>idLib::Error</c>)</summary>
  EIdLibException = class(Exception);

  /// <summary><c>common->FatalError</c>: the caller cannot go on (a programming error of the caller)</summary>
  EIdLibFatalException = class(EIdLibException);

  /// <summary>An error of the lexer: the message is "file F, line N: text" as the original printed it</summary>
  EIdLexerException = class(EIdLibException);

implementation

end.
