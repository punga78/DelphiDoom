{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: reader of big endian data    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_lwo.cpp   }
{  (getU1..getS0, sgetU1..sgetS0, from the LightWave 6.5 SDK lwio.c).          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore            }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.ByteReader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Bytes.Reader;

type
  /// <summary>
  ///   A cursor on a block of bytes with the readers of the IFF formats (big endian). Reading
  ///   past the end raises EStaticModelException with the offset. It replaces idFile and the
  ///   "flen" error counter of the original. The cursor is the common TByteReader of Libs\Bytes;
  ///   this class adds the names of the original readers (getU1, getU2, ...) and the strings, and
  ///   gives it the exception of this library
  /// </summary>
  TStaticByteReader = class(TByteReader)
  protected
    procedure RaiseOverrun(ACount: Integer); override;
  public
    function ReadU1: Byte;
    function ReadU2: Word;
    function ReadU4: Cardinal;
    function ReadF4: Single;
    /// <summary>getVX: an index of 2 bytes, or 4 bytes after $FF; Size gets the bytes read</summary>
    function ReadVX(out ASize: Integer): Integer;
    /// <summary>
    ///   getS0: a string that ends with a zero byte, padded to an even size; an empty string is
    ///   two bytes. Size gets the bytes read.
    /// </summary>
    function ReadS0(out ASize: Integer): AnsiString;
    /// <summary>The little endian readers of the MD3 format (the engine reads them with LittleLong, LittleShort, LittleFloat)</summary>
    function ReadLeInt16: SmallInt;
    function ReadLeInt32: Integer;
    function ReadLeSingle: Single;
    /// <summary>A string in a field of ACount bytes (char name[64]): up to the first zero byte or the end of the field</summary>
    function ReadFixedString(const ACount: Integer): AnsiString;
    /// <summary>The bytes of a block</summary>
    function ReadBytes(const ACount: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Models.Static.Types;

{ TStaticByteReader }

procedure TStaticByteReader.RaiseOverrun(ACount: Integer);
begin
  if ACount < 0 then
    raise EStaticModelException.CreateAtOffset(Format(SStaticNegativeSize, [ACount, Position]), Position);
  raise EStaticModelException.CreateAtOffset(Format(SStaticTruncated, [ACount, Position, Size]), Position);
end;

function TStaticByteReader.ReadU1: Byte;
begin
  Result := ReadByte;
end;

function TStaticByteReader.ReadU2: Word;
begin
  Result := ReadWordBE;
end;

function TStaticByteReader.ReadU4: Cardinal;
begin
  Result := ReadCardinalBE;
end;

function TStaticByteReader.ReadF4: Single;
var
  LBits: Cardinal;
begin
  LBits := ReadU4;
  Result := PSingle(@LBits)^;
  // FLOAT_IS_DENORMAL: the exponent is zero and the mantissa is not
  if ((LBits and $7F800000) = 0) and ((LBits and $007FFFFF) <> 0) then
    Result := 0.0;
end;

function TStaticByteReader.ReadVX(out ASize: Integer): Integer;
var
  LFirst: Byte;
begin
  LFirst := ReadU1;
  if LFirst <> $FF then
  begin
    Result := (Integer(LFirst) shl 8) or ReadU1;
    ASize := 2;
  end
  else
  begin
    Result := Integer(ReadU1) shl 16;
    Result := Result or (Integer(ReadU1) shl 8);
    Result := Result or ReadU1;
    ASize := 4;
  end;
end;

function TStaticByteReader.ReadS0(out ASize: Integer): AnsiString;
var
  LStart, LEnd, LLength: Integer;
begin
  LStart := Position;
  LEnd := LStart;
  while True do
  begin
    if LEnd >= Size then
      raise EStaticModelException.CreateAtOffset(Format(SStaticTruncated, [1, LEnd, Size]), LEnd);
    if Data[LEnd] = 0 then
      Break;
    Inc(LEnd);
  end;
  LLength := LEnd - LStart;
  if LLength = 0 then
  begin
    Skip(2);
    ASize := 2;
    Exit('');
  end;
  // the string with its zero is padded to an even number of bytes
  ASize := LLength + 1 + ((LLength + 1) and 1);
  Need(ASize);
  SetString(Result, PAnsiChar(@Data[LStart]), LLength);
  Skip(ASize);
end;

function TStaticByteReader.ReadLeInt16: SmallInt;
begin
  Result := ReadSmallInt;
end;

function TStaticByteReader.ReadLeInt32: Integer;
begin
  Result := ReadInteger;
end;

function TStaticByteReader.ReadLeSingle: Single;
var
  LBits: Integer;
begin
  LBits := ReadLeInt32;
  Result := PSingle(@LBits)^;
end;

function TStaticByteReader.ReadFixedString(const ACount: Integer): AnsiString;
var
  LLength: Integer;
begin
  Need(ACount);
  LLength := 0;
  while (LLength < ACount) and (Data[Position + LLength] <> 0) do
    Inc(LLength);
  SetString(Result, PAnsiChar(@Data[Position]), LLength);
  Skip(ACount);
end;

function TStaticByteReader.ReadBytes(const ACount: Integer): TBytes;
begin
  Result := ReadBlock(ACount);
end;

end.
