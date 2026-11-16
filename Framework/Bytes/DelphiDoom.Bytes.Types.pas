{******************************************************************************}
{                                                                              }
{  DelphiDoom: bytes library - shared types (issue #229)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Games\XcomFormats\README.md for the license of the CAT entry                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Bytes.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>An entry of the index that starts a CAT file: where the entry is and how long it is</summary>
  TCatEntry = packed record
    Offset: Cardinal;
    Size: Cardinal;
  end;

  /// <summary>
  ///   Raised by the readers of this library when a read goes past the end of the bytes and the
  ///   reader has no exception of its own to raise
  /// </summary>
  EByteReaderException = class(Exception);

implementation

end.
