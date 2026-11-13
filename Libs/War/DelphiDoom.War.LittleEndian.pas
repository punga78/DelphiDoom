{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - little endian numbers                             }
{                                                                              }
{  Port of war1 (acoto87/war1), wfile_readU16LE and wfile_readU32LE of         }
{  war_file.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see            }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.LittleEndian;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Reads the 16 and 32 bit numbers of DATA.WAR byte by byte, whatever the order of the machine, and
  ///   refuses to go outside the buffer (the original used memcpy on a pointer)
  /// </summary>
  TWarLittleEndian = class
  public
    /// <summary>The unsigned 16 bit number at AOffset</summary>
    class function ReadWord(const ABytes: TBytes; AOffset: Integer): Word; static;
    /// <summary>The unsigned 32 bit number at AOffset</summary>
    class function ReadCardinal(const ABytes: TBytes; AOffset: Integer): Cardinal; static;
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarLittleEndian }

class function TWarLittleEndian.ReadWord(const ABytes: TBytes; AOffset: Integer): Word;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 2) then
    raise EWarException.CreateFmt(SWarReadPastEnd, [2, AOffset, Length(ABytes)]);
  Result := Word(ABytes[AOffset]) or (Word(ABytes[AOffset + 1]) shl 8);
end;

class function TWarLittleEndian.ReadCardinal(const ABytes: TBytes; AOffset: Integer): Cardinal;
begin
  if (AOffset < 0) or (AOffset > Length(ABytes) - 4) then
    raise EWarException.CreateFmt(SWarReadPastEnd, [4, AOffset, Length(ABytes)]);
  Result := Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8) or
    (Cardinal(ABytes[AOffset + 2]) shl 16) or (Cardinal(ABytes[AOffset + 3]) shl 24);
end;

end.
