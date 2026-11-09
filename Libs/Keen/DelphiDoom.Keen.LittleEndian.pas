{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - numbers of the data files (little endian)         }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LittleEndian;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Reads the 16 and 32 bit numbers of the DOS files byte by byte, whatever the order of the machine,
  ///   and refuses to go outside the buffer
  /// </summary>
  TKeenLittleEndian = class
  public
    /// <summary>The unsigned 16 bit number at AOffset (unsigned of the C code)</summary>
    class function ReadWord(const ABytes: TBytes; AOffset: Integer): Word; static;
    /// <summary>The signed 16 bit number at AOffset (int of the C code)</summary>
    class function ReadSmallInt(const ABytes: TBytes; AOffset: Integer): SmallInt; static;
    /// <summary>The signed 32 bit number at AOffset (long of the C code)</summary>
    class function ReadInt32(const ABytes: TBytes; AOffset: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Keen.Types;

{ TKeenLittleEndian }

class function TKeenLittleEndian.ReadWord(const ABytes: TBytes; AOffset: Integer): Word;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 2) then
    raise EKeenDataException.CreateFmt(SKeenReadPastEnd, [2, AOffset, Length(ABytes)]);
  Result := Word(ABytes[AOffset]) or (Word(ABytes[AOffset + 1]) shl 8);
end;

class function TKeenLittleEndian.ReadSmallInt(const ABytes: TBytes; AOffset: Integer): SmallInt;
begin
  Result := SmallInt(ReadWord(ABytes, AOffset));
end;

class function TKeenLittleEndian.ReadInt32(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 4) then
    raise EKeenDataException.CreateFmt(SKeenReadPastEnd, [4, AOffset, Length(ABytes)]);
  Result := Integer(Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8) or
    (Cardinal(ABytes[AOffset + 2]) shl 16) or (Cardinal(ABytes[AOffset + 3]) shl 24));
end;

end.
