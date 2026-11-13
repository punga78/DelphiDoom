{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the interfaces of the bit messages                }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\BitMsg.h.          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.BitMessage.Intf;

interface

uses
  DelphiDoom.Scanner.IdDict;

type
  /// <summary>
  ///   The writing side of a bit message, as far as idBitMsgDelta needs it: raw bits, strings, byte
  ///   blocks, dictionaries and the three counters. A negative number of bits writes a signed value.
  /// </summary>
  IBitMessageWriter = interface
    ['{5D1A6B0E-3F4C-4A57-9C21-7E0B8D6F2A11}']
    procedure WriteBits(AValue, ANumBits: Integer);
    procedure WriteString(const AText: AnsiString; AMaxLength: Integer = -1; AMake7Bit: Boolean = True);
    procedure WriteData(AData: PByte; ALength: Integer);
    /// <summary>False if nothing differs from the base (the dictionary is written anyway)</summary>
    function WriteDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
    procedure WriteDeltaByteCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaShortCounter(AOldValue, ANewValue: Integer);
    procedure WriteDeltaLongCounter(AOldValue, ANewValue: Integer);
  end;

  /// <summary>The reading side of a bit message (see <c>IBitMessageWriter</c>); -1 from ReadBits means "past the end"</summary>
  IBitMessageReader = interface
    ['{5D1A6B0E-3F4C-4A57-9C21-7E0B8D6F2A12}']
    function ReadBits(ANumBits: Integer): Integer;
    /// <summary>
    ///   Reads a string: the text is cut at ABufferSize - 1 characters but the whole string is consumed;
    ///   a '%' becomes '.'
    /// </summary>
    function ReadString(ABufferSize: Integer = 1024): AnsiString;
    /// <summary>Copies the data (AData may be nil to skip); returns the number of bytes consumed</summary>
    function ReadData(AData: PByte; ALength: Integer): Integer;
    function ReadDeltaDict(const ADict: TIdDict; const ABase: TIdDict): Boolean;
    function ReadDeltaByteCounter(AOldValue: Integer): Integer;
    function ReadDeltaShortCounter(AOldValue: Integer): Integer;
    function ReadDeltaLongCounter(AOldValue: Integer): Integer;
  end;

implementation

end.
