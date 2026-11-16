{******************************************************************************}
{                                                                              }
{  DelphiDoom: bytes library - contract of a CAT archive (issue #229)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of the CAT archive               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Bytes.Archive.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Bytes.Types;

type
  /// <summary>A .CAT file: an index of entries, each with a name that starts it (CatFile)</summary>
  ICatArchive = interface
    ['{4C97E1D5-3A82-4B06-95F7-E0D18A6C2B39}']
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TCatEntry;
    /// <summary>
    ///   The bytes of an entry (CatFile::load). The entry starts with a name (a length byte of at most 56 and the
    ///   name): it is skipped, unless AKeepName. The size of the index is the size of what follows the name
    /// </summary>
    function Load(AIndex: Integer; AKeepName: Boolean = False): TBytes;
    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TCatEntry read GetEntry;
  end;

implementation

end.
