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
  System.SysUtils;

type
  /// <summary>
  ///   A cursor on a block of bytes with the readers of the IFF formats (big endian). Reading
  ///   past the end raises EStaticModelException with the offset. It replaces idFile and the
  ///   "flen" error counter of the original.
  /// </summary>
  TStaticByteReader = class
  strict private
    FData: TBytes;
    FPosition: Integer;
    procedure Need(const ACount: Integer);
  public
    constructor Create(const AData: TBytes);
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
    procedure Skip(const ACount: Integer);
    function Size: Integer;
    function Remaining: Integer;
    property Position: Integer read FPosition write FPosition;
  end;

implementation

uses
  DelphiDoom.Models.Static.Types;

{ TStaticByteReader }

constructor TStaticByteReader.Create(const AData: TBytes);
begin
  inherited Create;
  FData := AData;
end;

procedure TStaticByteReader.Need(const ACount: Integer);
begin
  if ACount < 0 then
    raise EStaticModelException.CreateAtOffset(Format(SStaticNegativeSize, [ACount, FPosition]), FPosition);
  if (FPosition < 0) or (FPosition + ACount > Length(FData)) or (FPosition + ACount < FPosition) then
    raise EStaticModelException.CreateAtOffset(Format(SStaticTruncated, [ACount, FPosition, Length(FData)]),
      FPosition);
end;

function TStaticByteReader.ReadU1: Byte;
begin
  Need(1);
  Result := FData[FPosition];
  Inc(FPosition);
end;

function TStaticByteReader.ReadU2: Word;
begin
  Need(2);
  Result := (Word(FData[FPosition]) shl 8) or FData[FPosition + 1];
  Inc(FPosition, 2);
end;

function TStaticByteReader.ReadU4: Cardinal;
begin
  Need(4);
  Result := (Cardinal(FData[FPosition]) shl 24) or (Cardinal(FData[FPosition + 1]) shl 16) or
    (Cardinal(FData[FPosition + 2]) shl 8) or FData[FPosition + 3];
  Inc(FPosition, 4);
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
  LStart := FPosition;
  LEnd := LStart;
  while True do
  begin
    if LEnd >= Length(FData) then
      raise EStaticModelException.CreateAtOffset(Format(SStaticTruncated, [1, LEnd, Length(FData)]), LEnd);
    if FData[LEnd] = 0 then
      Break;
    Inc(LEnd);
  end;
  LLength := LEnd - LStart;
  if LLength = 0 then
  begin
    Need(2);
    Inc(FPosition, 2);
    ASize := 2;
    Exit('');
  end;
  // the string with its zero is padded to an even number of bytes
  ASize := LLength + 1 + ((LLength + 1) and 1);
  Need(ASize);
  SetString(Result, PAnsiChar(@FData[LStart]), LLength);
  Inc(FPosition, ASize);
end;

function TStaticByteReader.ReadLeInt16: SmallInt;
begin
  Need(2);
  Result := SmallInt(Word(FData[FPosition]) or (Word(FData[FPosition + 1]) shl 8));
  Inc(FPosition, 2);
end;

function TStaticByteReader.ReadLeInt32: Integer;
begin
  Need(4);
  Result := Integer(Cardinal(FData[FPosition]) or (Cardinal(FData[FPosition + 1]) shl 8) or
    (Cardinal(FData[FPosition + 2]) shl 16) or (Cardinal(FData[FPosition + 3]) shl 24));
  Inc(FPosition, 4);
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
  while (LLength < ACount) and (FData[FPosition + LLength] <> 0) do
    Inc(LLength);
  SetString(Result, PAnsiChar(@FData[FPosition]), LLength);
  Inc(FPosition, ACount);
end;

function TStaticByteReader.ReadBytes(const ACount: Integer): TBytes;
begin
  Need(ACount);
  SetLength(Result, ACount);
  if ACount > 0 then
    Move(FData[FPosition], Result[0], ACount);
  Inc(FPosition, ACount);
end;

procedure TStaticByteReader.Skip(const ACount: Integer);
begin
  Need(ACount);
  Inc(FPosition, ACount);
end;

function TStaticByteReader.Size: Integer;
begin
  Result := Length(FData);
end;

function TStaticByteReader.Remaining: Integer;
begin
  Result := Length(FData) - FPosition;
end;

end.
