{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - IDeclFileScanner, the syntax of a file    }
{                                                                              }
{  Written from the description of the problem (issue #119): the manager       }
{  finds the declarations of a file with the lexer of Doom 3 (a type word,     }
{  a name and a braced text); a type with another syntax (the Quake III        }
{  shaders: a name and a braced text, read by COM_ParseExt) supplies its own   }
{  scanner.                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.FileScanner.Intf;

interface

uses
  DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>One declaration found in a file: what <c>TDeclFile</c> needs to register it</summary>
  TDeclScannedBlock = record
    /// <summary>The type of the declaration (a scanner of one type gives its own number)</summary>
    TypeId: Integer;
    /// <summary>The name, as the lookups will use it</summary>
    Name: AnsiString;
    /// <summary>Offset in the file of the first character of the text (0 based); comments above the declaration belong to it</summary>
    Offset: Integer;
    /// <summary>Length of the text in bytes</summary>
    Length: Integer;
    /// <summary>The line (1 based) where the text starts</summary>
    Line: Integer;
  end;

  /// <summary>
  ///   The syntax of the files of a declaration type. A type that implements it on its <c>IDeclType</c> is
  ///   asked to find the declarations of the files whose default type it is (the files of a folder registered
  ///   with <c>RegisterDeclFolder</c>); the Doom 3 types do not implement it and are read with the lexer of
  ///   idLib and <c>DECL_LEXER_FLAGS</c>, as before. This is the strategy per type that the lexer flags,
  ///   fixed for every type, could not be: the text of one declaration is parsed by the type itself, with
  ///   the lexer it likes (<c>TDecl.OpenLexer</c> takes the flags; a type may not use it at all).
  /// </summary>
  IDeclFileScanner = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0010}']
    /// <summary>
    ///   Finds every declaration of a file. Problems are warnings to <c>ALog</c> (may be nil), never exceptions.
    ///   <c>ANumLines</c> is the number of lines of the file.
    /// </summary>
    function ScanFile(const AText, AFileName: AnsiString; const ADefaultType: Integer; const ALog: IIdLibLog;
      out ANumLines: Integer): TArray<TDeclScannedBlock>;
  end;

implementation

end.
