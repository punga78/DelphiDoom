{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the token source TIdDict parses from          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdParser.Intf;

interface

uses
  DelphiDoom.IdLib.Text.Token;

type
  /// <summary>
  ///   What a reader of key/value blocks (TIdDict.Parse) asks of the parser: tokens, expected
  ///   strings and the messages with the position. TIdParser implements it; a test can
  ///   give a fake. The implementations are not reference counted: the owner frees them.
  /// </summary>
  IIdTokenSource = interface
    ['{6B1C8E52-7D3A-4F0B-9C21-5A8E4D7F1B01}']
    function ReadToken(var AToken: TIdToken): Boolean;
    function ExpectTokenString(const AText: AnsiString): Boolean;
    /// <summary>idParser::Error: raises, or logs a warning when the flags say so</summary>
    procedure Error(const AText: string);
    procedure Warning(const AText: string);
  end;

implementation

end.
