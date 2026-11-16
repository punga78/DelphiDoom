{******************************************************************************}
{                                                                              }
{  DelphiDoom: Ogg - what the header of a page says                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libogg by the Xiph.Org Foundation (BSD licence)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ogg.PageReader;

interface

uses
  DelphiDoom.Ogg.Types;

type
  /// <summary>
  ///   Reads the fields of the header of a page and sets its checksum
  /// </summary>
  TOggPageReader = class
  public
    class function Version(const APage: POggPage): Integer; static;
    /// <returns>1 when the first packet of the page began on the page before, 0 if not</returns>
    class function Continued(const APage: POggPage): Integer; static;
    /// <returns>2 for the first page of a logical stream, 0 if not (the value of the flag bit)</returns>
    class function BeginningOfStream(const APage: POggPage): Integer; static;
    /// <returns>4 for the last page of a logical stream, 0 if not (the value of the flag bit)</returns>
    class function EndOfStream(const APage: POggPage): Integer; static;
    class function GranulePosition(const APage: POggPage): Int64; static;
    class function SerialNumber(const APage: POggPage): Integer; static;
    class function PageNumber(const APage: POggPage): Longint; static;
    /// <summary>
    ///   The packets that end on the page, counting the first one even if it began on
    ///   the page before
    /// </summary>
    class function Packets(const APage: POggPage): Integer; static;
    /// <summary>Computes the checksum over the header and the body and writes it in the header</summary>
    class procedure SetChecksum(const APage: POggPage); static;
  end;

implementation

uses
  DelphiDoom.Ogg.Crc;

const
  OFFSET_VERSION = 4;
  OFFSET_FLAGS = 5;
  OFFSET_GRANULE = 6;
  OFFSET_SERIAL = 14;
  OFFSET_PAGE = 18;
  OFFSET_CHECKSUM = 22;
  OFFSET_SEGMENTS = 26;
  OFFSET_SEGMENT_TABLE = 27;
  FLAG_CONTINUED = $01;
  FLAG_BEGINNING = $02;
  FLAG_END = $04;
  FULL_SEGMENT = 255;

{ TOggPageReader }

class function TOggPageReader.Version(const APage: POggPage): Integer;
begin
  Result := APage.Header[OFFSET_VERSION];
end;

class function TOggPageReader.Continued(const APage: POggPage): Integer;
begin
  Result := APage.Header[OFFSET_FLAGS] and FLAG_CONTINUED;
end;

class function TOggPageReader.BeginningOfStream(const APage: POggPage): Integer;
begin
  Result := APage.Header[OFFSET_FLAGS] and FLAG_BEGINNING;
end;

class function TOggPageReader.EndOfStream(const APage: POggPage): Integer;
begin
  Result := APage.Header[OFFSET_FLAGS] and FLAG_END;
end;

class function TOggPageReader.GranulePosition(const APage: POggPage): Int64;
var
  LIndex: Integer;
  LValue: UInt64;
begin
  // Eight bytes, the last one the most significant
  LValue := 0;
  for LIndex := OFFSET_GRANULE + 7 downto OFFSET_GRANULE do
    LValue := (LValue shl 8) or APage.Header[LIndex];
  Result := Int64(LValue);
end;

class function TOggPageReader.SerialNumber(const APage: POggPage): Integer;
begin
  Result := Integer(Cardinal(APage.Header[OFFSET_SERIAL]) or
    (Cardinal(APage.Header[OFFSET_SERIAL + 1]) shl 8) or
    (Cardinal(APage.Header[OFFSET_SERIAL + 2]) shl 16) or
    (Cardinal(APage.Header[OFFSET_SERIAL + 3]) shl 24));
end;

class function TOggPageReader.PageNumber(const APage: POggPage): Longint;
begin
  Result := Longint(Cardinal(APage.Header[OFFSET_PAGE]) or
    (Cardinal(APage.Header[OFFSET_PAGE + 1]) shl 8) or
    (Cardinal(APage.Header[OFFSET_PAGE + 2]) shl 16) or
    (Cardinal(APage.Header[OFFSET_PAGE + 3]) shl 24));
end;

class function TOggPageReader.Packets(const APage: POggPage): Integer;
var
  LIndex, LSegments: Integer;
begin
  Result := 0;
  LSegments := APage.Header[OFFSET_SEGMENTS];
  for LIndex := 0 to LSegments - 1 do
  begin
    if APage.Header[OFFSET_SEGMENT_TABLE + LIndex] < FULL_SEGMENT then
      Inc(Result);
  end;
end;

class procedure TOggPageReader.SetChecksum(const APage: POggPage);
var
  LCrc: Cardinal;
  LIndex: Integer;
begin
  if not Assigned(APage) then
    Exit;

  // The field has to be zero while the checksum is computed
  for LIndex := 0 to 3 do
    APage.Header[OFFSET_CHECKSUM + LIndex] := 0;

  LCrc := TOggCrc.Update(0, APage.Header, APage.HeaderLength);
  LCrc := TOggCrc.Update(LCrc, APage.Body, APage.BodyLength);

  for LIndex := 0 to 3 do
    APage.Header[OFFSET_CHECKSUM + LIndex] := Byte(LCrc shr (8 * LIndex));
end;

end.
