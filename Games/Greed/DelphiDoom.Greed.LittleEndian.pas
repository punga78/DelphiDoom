{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - numbers of the data files (little endian)        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.LittleEndian;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Reads the 16 and 32 bit numbers of the files of the game byte by byte, whatever the order of the
  ///   machine, and refuses to go outside the buffer
  /// </summary>
  TGreedLittleEndian = class
  public
    /// <summary>The signed 16 bit number at AOffset (smallint)</summary>
    class function ReadSmallInt(const ABytes: TBytes; AOffset: Integer): SmallInt; static;
    /// <summary>The signed 32 bit number at AOffset (integer)</summary>
    class function ReadInt32(const ABytes: TBytes; AOffset: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Greed.Types;

{ TGreedLittleEndian }

class function TGreedLittleEndian.ReadSmallInt(const ABytes: TBytes; AOffset: Integer): SmallInt;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 2) then
    raise EGreedDataException.CreateFmt(SGreedReadPastEnd, [2, AOffset, Length(ABytes)]);
  Result := SmallInt(Word(ABytes[AOffset]) or (Word(ABytes[AOffset + 1]) shl 8));
end;

class function TGreedLittleEndian.ReadInt32(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 4) then
    raise EGreedDataException.CreateFmt(SGreedReadPastEnd, [4, AOffset, Length(ABytes)]);
  Result := Integer(Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8) or
    (Cardinal(ABytes[AOffset + 2]) shl 16) or (Cardinal(ABytes[AOffset + 3]) shl 24));
end;

end.
