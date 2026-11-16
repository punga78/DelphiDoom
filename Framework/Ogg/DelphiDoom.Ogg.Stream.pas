{******************************************************************************}
{                                                                              }
{  DelphiDoom: Ogg - packets into pages and pages into packets                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libogg by the Xiph.Org Foundation (BSD licence)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ogg.Stream;

interface

uses
  DelphiDoom.Ogg.Types;

type
  /// <summary>
  ///   The framing of one logical stream. To encode, packets go in (PacketIn) and pages
  ///   come out (PageOut, Flush); to decode, pages go in (PageIn) and packets come
  ///   out (PacketOut). The pages and the packets that come out point inside the state:
  ///   they are good until the next call on the same state
  /// </summary>
  /// <remarks>
  ///   The functions answer as the C ones do, with a number: 0 is good for the Init
  ///   family and -1 is an error, while the page and packet functions return 1 when they
  ///   have given something, 0 when there is nothing yet (and -1 for a hole in the data)
  /// </remarks>
  TOggStream = class
  private
    class function ExpandBody(const AState: POggStreamState; const ANeeded: Longint): Integer; static;
    class function ExpandLacing(const AState: POggStreamState; const ANeeded: Longint): Integer; static;
    class function FlushPage(const AState: POggStreamState; const APage: POggPage; AForce: Integer;
      const AFill: Integer): Integer; static;
    class function TakePacket(const AState: POggStreamState; const APacket: POggPacket;
      const AAdvance: Boolean): Integer; static;
  public
    class function Init(const AState: POggStreamState; const ASerialNumber: Integer): Integer; static;
    /// <returns>0 for a state that can work, -1 for a state that was cleared after an error</returns>
    class function Check(const AState: POggStreamState): Integer; static;
    /// <summary>Gives back what the state holds; the state itself is not freed</summary>
    class function Clear(const AState: POggStreamState): Integer; static;
    /// <summary>Clears the state and frees it as well</summary>
    class function ClearAndFree(const AState: POggStreamState): Integer; static;

    /// <summary>Submits a packet made of several blocks</summary>
    class function IoVecIn(const AState: POggStreamState; const AVectors: POggIoVec; const ACount: Integer;
      const AEndOfStream: Longint; const AGranulePosition: Int64): Integer; static;
    class function PacketIn(const AState: POggStreamState; const APacket: POggPacket): Integer; static;

    /// <summary>A page, even a short one, if there is any data</summary>
    class function Flush(const AState: POggStreamState; const APage: POggPage): Integer; static;
    class function FlushFill(const AState: POggStreamState; const APage: POggPage;
      const AFill: Integer): Integer; static;
    /// <summary>A page, when enough data has gathered for a normal one</summary>
    class function PageOut(const AState: POggStreamState; const APage: POggPage): Integer; static;
    class function PageOutFill(const AState: POggStreamState; const APage: POggPage;
      const AFill: Integer): Integer; static;
    /// <returns>1 when the last page of the stream has been submitted</returns>
    class function EndOfStream(const AState: POggStreamState): Integer; static;

    class function PageIn(const AState: POggStreamState; const APage: POggPage): Integer; static;
    class function PacketOut(const AState: POggStreamState; const APacket: POggPacket): Integer; static;
    /// <summary>Like PacketOut, but the packet stays; APacket can be nil to ask if there is one</summary>
    class function PacketPeek(const AState: POggStreamState; const APacket: POggPacket): Integer; static;

    class function Reset(const AState: POggStreamState): Integer; static;
    class function ResetSerialNumber(const AState: POggStreamState; const ASerialNumber: Integer): Integer; static;

    /// <summary>Frees the data of a packet, which the caller owns, and clears the packet</summary>
    class procedure ClearPacket(const APacket: POggPacket); static;
  end;

implementation

uses
  DelphiDoom.Ogg.Memory,
  DelphiDoom.Ogg.PageReader;

const
  MAX_LONG = 2147483647;
  INITIAL_BODY_STORAGE = 16 * 1024;
  INITIAL_LACING_STORAGE = 1024;
  BODY_GROWTH = 1024;
  LACING_GROWTH = 32;
  FULL_SEGMENT = 255;
  MAX_SEGMENTS = 255;
  HEADER_SIZE = 27;
  NOMINAL_FILL = 4096;
  // Marks in the high bits of the values of the segment table
  LACING_FIRST = $100;
  LACING_LAST = $200;
  LACING_GAP = $400;
  FLAG_CONTINUED = $01;
  FLAG_BEGINNING = $02;
  FLAG_END = $04;
  HEADER_SERIAL = 14;
  HEADER_PAGE = 18;
  HEADER_GRANULE = 6;
  HEADER_CHECKSUM = 22;
  HEADER_SEGMENTS = 26;

{ TOggStream }

class function TOggStream.Init(const AState: POggStreamState; const ASerialNumber: Integer): Integer;
begin
  if not Assigned(AState) then
    Exit(-1);

  FillChar(AState^, SizeOf(AState^), 0);
  AState.BodyStorage := INITIAL_BODY_STORAGE;
  AState.LacingStorage := INITIAL_LACING_STORAGE;

  AState.BodyData := TOggMemory.Allocate(AState.BodyStorage * SizeOf(Byte));
  AState.LacingValues := TOggMemory.Allocate(AState.LacingStorage * SizeOf(Integer));
  AState.GranuleValues := TOggMemory.Allocate(AState.LacingStorage * SizeOf(Int64));

  if not Assigned(AState.BodyData) or not Assigned(AState.LacingValues) or
    not Assigned(AState.GranuleValues) then
  begin
    Clear(AState);
    Exit(-1);
  end;

  AState.SerialNumber := ASerialNumber;
  Result := 0;
end;

class function TOggStream.Check(const AState: POggStreamState): Integer;
begin
  if not Assigned(AState) or not Assigned(AState.BodyData) then
    Exit(-1);
  Result := 0;
end;

class function TOggStream.Clear(const AState: POggStreamState): Integer;
begin
  if Assigned(AState) then
  begin
    TOggMemory.Release(AState.BodyData);
    TOggMemory.Release(AState.LacingValues);
    TOggMemory.Release(AState.GranuleValues);
    FillChar(AState^, SizeOf(AState^), 0);
  end;
  Result := 0;
end;

class function TOggStream.ClearAndFree(const AState: POggStreamState): Integer;
begin
  if Assigned(AState) then
  begin
    Clear(AState);
    TOggMemory.Release(AState);
  end;
  Result := 0;
end;

class function TOggStream.ExpandBody(const AState: POggStreamState; const ANeeded: Longint): Integer;
var
  LStorage: Longint;
  LNew: Pointer;
begin
  if AState.BodyStorage - ANeeded <= AState.BodyFill then
  begin
    if AState.BodyStorage > MAX_LONG - ANeeded then
    begin
      Clear(AState);
      Exit(-1);
    end;
    LStorage := AState.BodyStorage + ANeeded;
    if LStorage < MAX_LONG - BODY_GROWTH then
      Inc(LStorage, BODY_GROWTH);
    LNew := TOggMemory.Reallocate(AState.BodyData, LStorage * SizeOf(Byte));
    if not Assigned(LNew) then
    begin
      Clear(AState);
      Exit(-1);
    end;
    AState.BodyStorage := LStorage;
    AState.BodyData := LNew;
  end;
  Result := 0;
end;

class function TOggStream.ExpandLacing(const AState: POggStreamState; const ANeeded: Longint): Integer;
var
  LStorage: Longint;
  LNew: Pointer;
begin
  if AState.LacingStorage - ANeeded <= AState.LacingFill then
  begin
    if AState.LacingStorage > MAX_LONG - ANeeded then
    begin
      Clear(AState);
      Exit(-1);
    end;
    LStorage := AState.LacingStorage + ANeeded;
    if LStorage < MAX_LONG - LACING_GROWTH then
      Inc(LStorage, LACING_GROWTH);
    LNew := TOggMemory.Reallocate(AState.LacingValues, LStorage * SizeOf(Integer));
    if not Assigned(LNew) then
    begin
      Clear(AState);
      Exit(-1);
    end;
    AState.LacingValues := LNew;
    LNew := TOggMemory.Reallocate(AState.GranuleValues, LStorage * SizeOf(Int64));
    if not Assigned(LNew) then
    begin
      Clear(AState);
      Exit(-1);
    end;
    AState.GranuleValues := LNew;
    AState.LacingStorage := LStorage;
  end;
  Result := 0;
end;

class function TOggStream.IoVecIn(const AState: POggStreamState; const AVectors: POggIoVec;
  const ACount: Integer; const AEndOfStream: Longint; const AGranulePosition: Int64): Integer;
var
  LBytes, LLacingCount: Longint;
  LIndex: Integer;
begin
  if Check(AState) <> 0 then
    Exit(-1);
  if not Assigned(AVectors) then
    Exit(0);

  LBytes := 0;
  for LIndex := 0 to ACount - 1 do
  begin
    if AVectors[LIndex].Length > MAX_LONG then
      Exit(-1);
    if LBytes > MAX_LONG - Longint(AVectors[LIndex].Length) then
      Exit(-1);
    Inc(LBytes, Longint(AVectors[LIndex].Length));
  end;
  LLacingCount := LBytes div FULL_SEGMENT + 1;

  if AState.BodyReturned <> 0 then
  begin
    // The data that was returned in the last call is dropped now
    Dec(AState.BodyFill, AState.BodyReturned);
    if AState.BodyFill <> 0 then
      Move((AState.BodyData + AState.BodyReturned)^, AState.BodyData^, AState.BodyFill);
    AState.BodyReturned := 0;
  end;

  if (ExpandBody(AState, LBytes) <> 0) or (ExpandLacing(AState, LLacingCount) <> 0) then
    Exit(-1);

  for LIndex := 0 to ACount - 1 do
  begin
    if AVectors[LIndex].Length > 0 then
      Move(PByte(AVectors[LIndex].Base)^, (AState.BodyData + AState.BodyFill)^, AVectors[LIndex].Length);
    Inc(AState.BodyFill, Longint(AVectors[LIndex].Length));
  end;

  // The lacing values of the packet: as many full segments as fit, then the rest
  for LIndex := 0 to LLacingCount - 2 do
  begin
    AState.LacingValues[AState.LacingFill + LIndex] := FULL_SEGMENT;
    AState.GranuleValues[AState.LacingFill + LIndex] := AState.GranulePosition;
  end;
  LIndex := LLacingCount - 1;
  AState.LacingValues[AState.LacingFill + LIndex] := LBytes mod FULL_SEGMENT;
  AState.GranulePosition := AGranulePosition;
  AState.GranuleValues[AState.LacingFill + LIndex] := AGranulePosition;

  // The first segment begins the packet
  AState.LacingValues[AState.LacingFill] := AState.LacingValues[AState.LacingFill] or LACING_FIRST;

  Inc(AState.LacingFill, LLacingCount);
  Inc(AState.PacketNumber);

  if AEndOfStream <> 0 then
    AState.EndOfStream := 1;

  Result := 0;
end;

class function TOggStream.PacketIn(const AState: POggStreamState; const APacket: POggPacket): Integer;
var
  LVector: TOggIoVec;
begin
  LVector.Base := APacket.Packet;
  LVector.Length := Cardinal(APacket.Bytes);
  Result := IoVecIn(AState, @LVector, 1, APacket.EndOfStream, APacket.GranulePosition);
end;

class function TOggStream.FlushPage(const AState: POggStreamState; const APage: POggPage;
  AForce: Integer; const AFill: Integer): Integer;
var
  LIndex, LValues, LMaxValues, LBytes: Integer;
  LAccumulated: Longint;
  LGranule: Int64;
  LPacketsDone, LPacketJustDone: Integer;
  LSerial, LPageNumber: Longint;
begin
  LValues := 0;
  if AState.LacingFill > MAX_SEGMENTS then
    LMaxValues := MAX_SEGMENTS
  else
    LMaxValues := AState.LacingFill;
  LBytes := 0;
  LAccumulated := 0;
  LGranule := -1;

  if Check(AState) <> 0 then
    Exit(0);
  if LMaxValues = 0 then
    Exit(0);

  // How many segments go into the page
  if AState.BeginningOfStream = 0 then
  begin
    // The first page has only the first packet, the initial header
    LGranule := 0;
    while LValues < LMaxValues do
    begin
      if (AState.LacingValues[LValues] and $FF) < FULL_SEGMENT then
      begin
        Inc(LValues);
        Break;
      end;
      Inc(LValues);
    end;
  end
  else
  begin
    // A page does not span packets without need, and it is not sent with less than
    // four packets unless it has grown enough
    LPacketsDone := 0;
    LPacketJustDone := 0;
    while LValues < LMaxValues do
    begin
      if (LAccumulated > AFill) and (LPacketJustDone >= 4) then
      begin
        AForce := 1;
        Break;
      end;
      Inc(LAccumulated, AState.LacingValues[LValues] and $FF);
      if (AState.LacingValues[LValues] and $FF) < FULL_SEGMENT then
      begin
        LGranule := AState.GranuleValues[LValues];
        Inc(LPacketsDone);
        LPacketJustDone := LPacketsDone;
      end
      else
        LPacketJustDone := 0;
      Inc(LValues);
    end;
    if LValues = MAX_SEGMENTS then
      AForce := 1;
  end;

  if AForce = 0 then
    Exit(0);

  // The header, in the working space of the state
  AState.Header[0] := Ord('O');
  AState.Header[1] := Ord('g');
  AState.Header[2] := Ord('g');
  AState.Header[3] := Ord('S');
  AState.Header[4] := 0;

  AState.Header[5] := 0;
  if (AState.LacingValues[0] and LACING_FIRST) = 0 then
    AState.Header[5] := AState.Header[5] or FLAG_CONTINUED;
  if AState.BeginningOfStream = 0 then
    AState.Header[5] := AState.Header[5] or FLAG_BEGINNING;
  if (AState.EndOfStream <> 0) and (AState.LacingFill = LValues) then
    AState.Header[5] := AState.Header[5] or FLAG_END;
  AState.BeginningOfStream := 1;

  for LIndex := HEADER_GRANULE to HEADER_GRANULE + 7 do
  begin
    AState.Header[LIndex] := Byte(LGranule and $FF);
    LGranule := LGranule shr 8;
  end;

  LSerial := AState.SerialNumber;
  for LIndex := HEADER_SERIAL to HEADER_SERIAL + 3 do
  begin
    AState.Header[LIndex] := Byte(LSerial and $FF);
    LSerial := LSerial shr 8;
  end;

  // After a reset the page number is -1: the first page is the number 0
  if AState.PageNumber = -1 then
    AState.PageNumber := 0;
  LPageNumber := AState.PageNumber;
  Inc(AState.PageNumber);
  for LIndex := HEADER_PAGE to HEADER_PAGE + 3 do
  begin
    AState.Header[LIndex] := Byte(LPageNumber and $FF);
    LPageNumber := LPageNumber shr 8;
  end;

  // The checksum is set later
  for LIndex := HEADER_CHECKSUM to HEADER_CHECKSUM + 3 do
    AState.Header[LIndex] := 0;

  AState.Header[HEADER_SEGMENTS] := Byte(LValues and $FF);
  for LIndex := 0 to LValues - 1 do
  begin
    AState.Header[LIndex + HEADER_SIZE] := Byte(AState.LacingValues[LIndex] and $FF);
    Inc(LBytes, AState.Header[LIndex + HEADER_SIZE]);
  end;

  APage.Header := @AState.Header[0];
  AState.HeaderFill := LValues + HEADER_SIZE;
  APage.HeaderLength := AState.HeaderFill;
  APage.Body := AState.BodyData + AState.BodyReturned;
  APage.BodyLength := LBytes;

  // What was put in the page is taken off the lacing data
  Dec(AState.LacingFill, LValues);
  Move((AState.LacingValues + LValues)^, AState.LacingValues^, AState.LacingFill * SizeOf(Integer));
  Move((AState.GranuleValues + LValues)^, AState.GranuleValues^, AState.LacingFill * SizeOf(Int64));
  Inc(AState.BodyReturned, LBytes);

  TOggPageReader.SetChecksum(APage);
  Result := 1;
end;

class function TOggStream.Flush(const AState: POggStreamState; const APage: POggPage): Integer;
begin
  Result := FlushPage(AState, APage, 1, NOMINAL_FILL);
end;

class function TOggStream.FlushFill(const AState: POggStreamState; const APage: POggPage;
  const AFill: Integer): Integer;
begin
  Result := FlushPage(AState, APage, 1, AFill);
end;

class function TOggStream.PageOut(const AState: POggStreamState; const APage: POggPage): Integer;
begin
  Result := PageOutFill(AState, APage, NOMINAL_FILL);
end;

class function TOggStream.PageOutFill(const AState: POggStreamState; const APage: POggPage;
  const AFill: Integer): Integer;
var
  LForce: Integer;
begin
  if Check(AState) <> 0 then
    Exit(0);

  LForce := 0;
  if ((AState.EndOfStream <> 0) and (AState.LacingFill <> 0)) or
    ((AState.LacingFill <> 0) and (AState.BeginningOfStream = 0)) then
    LForce := 1;

  Result := FlushPage(AState, APage, LForce, AFill);
end;

class function TOggStream.EndOfStream(const AState: POggStreamState): Integer;
begin
  if Check(AState) <> 0 then
    Exit(1);
  Result := AState.EndOfStream;
end;

class function TOggStream.PageIn(const AState: POggStreamState; const APage: POggPage): Integer;
var
  LHeader, LBody: PByte;
  LBodySize: Longint;
  LSegmentPointer, LSegments, LIndex, LValue, LSaved: Integer;
  LVersion, LContinued, LBeginning, LEnd: Integer;
  LGranule: Int64;
  LSerial: Integer;
  LPageNumber: Longint;
  LReturnedLacing, LReturnedBody: Longint;
begin
  LHeader := APage.Header;
  LBody := APage.Body;
  LBodySize := APage.BodyLength;
  LSegmentPointer := 0;

  LVersion := TOggPageReader.Version(APage);
  LContinued := TOggPageReader.Continued(APage);
  LBeginning := TOggPageReader.BeginningOfStream(APage);
  LEnd := TOggPageReader.EndOfStream(APage);
  LGranule := TOggPageReader.GranulePosition(APage);
  LSerial := TOggPageReader.SerialNumber(APage);
  LPageNumber := TOggPageReader.PageNumber(APage);
  LSegments := LHeader[HEADER_SEGMENTS];

  if Check(AState) <> 0 then
    Exit(-1);

  // The data that was returned is dropped
  LReturnedLacing := AState.LacingReturned;
  LReturnedBody := AState.BodyReturned;

  if LReturnedBody <> 0 then
  begin
    Dec(AState.BodyFill, LReturnedBody);
    if AState.BodyFill <> 0 then
      Move((AState.BodyData + LReturnedBody)^, AState.BodyData^, AState.BodyFill);
    AState.BodyReturned := 0;
  end;

  if LReturnedLacing <> 0 then
  begin
    if AState.LacingFill - LReturnedLacing <> 0 then
    begin
      Move((AState.LacingValues + LReturnedLacing)^, AState.LacingValues^,
        (AState.LacingFill - LReturnedLacing) * SizeOf(Integer));
      Move((AState.GranuleValues + LReturnedLacing)^, AState.GranuleValues^,
        (AState.LacingFill - LReturnedLacing) * SizeOf(Int64));
    end;
    Dec(AState.LacingFill, LReturnedLacing);
    Dec(AState.LacingPacket, LReturnedLacing);
    AState.LacingReturned := 0;
  end;

  if LSerial <> AState.SerialNumber then
    Exit(-1);
  if LVersion > 0 then
    Exit(-1);

  if ExpandLacing(AState, LSegments + 1) <> 0 then
    Exit(-1);

  // Is the page the next one?
  if LPageNumber <> AState.PageNumber then
  begin
    // The partial packet that was there is lost
    for LIndex := AState.LacingPacket to AState.LacingFill - 1 do
      Dec(AState.BodyFill, AState.LacingValues[LIndex] and $FF);
    AState.LacingFill := AState.LacingPacket;

    // A mark in the segment table tells about the gap
    if AState.PageNumber <> -1 then
    begin
      AState.LacingValues[AState.LacingFill] := LACING_GAP;
      Inc(AState.LacingFill);
      Inc(AState.LacingPacket);
    end;
  end;

  // A page that continues a packet may have to skip its first segments
  if LContinued <> 0 then
  begin
    if (AState.LacingFill < 1) or ((AState.LacingValues[AState.LacingFill - 1] and $FF) < FULL_SEGMENT) or
      (AState.LacingValues[AState.LacingFill - 1] = LACING_GAP) then
    begin
      LBeginning := 0;
      while LSegmentPointer < LSegments do
      begin
        LValue := LHeader[HEADER_SIZE + LSegmentPointer];
        Inc(LBody, LValue);
        Dec(LBodySize, LValue);
        if LValue < FULL_SEGMENT then
        begin
          Inc(LSegmentPointer);
          Break;
        end;
        Inc(LSegmentPointer);
      end;
    end;
  end;

  if LBodySize <> 0 then
  begin
    if ExpandBody(AState, LBodySize) <> 0 then
      Exit(-1);
    Move(LBody^, (AState.BodyData + AState.BodyFill)^, LBodySize);
    Inc(AState.BodyFill, LBodySize);
  end;

  LSaved := -1;
  while LSegmentPointer < LSegments do
  begin
    LValue := LHeader[HEADER_SIZE + LSegmentPointer];
    AState.LacingValues[AState.LacingFill] := LValue;
    AState.GranuleValues[AState.LacingFill] := -1;

    if LBeginning <> 0 then
    begin
      AState.LacingValues[AState.LacingFill] := AState.LacingValues[AState.LacingFill] or LACING_FIRST;
      LBeginning := 0;
    end;

    if LValue < FULL_SEGMENT then
      LSaved := AState.LacingFill;

    Inc(AState.LacingFill);
    Inc(LSegmentPointer);

    if LValue < FULL_SEGMENT then
      AState.LacingPacket := AState.LacingFill;
  end;

  // The granule position of the page belongs to the last packet that is complete
  if LSaved <> -1 then
    AState.GranuleValues[LSaved] := LGranule;

  if LEnd <> 0 then
  begin
    AState.EndOfStream := 1;
    if AState.LacingFill > 0 then
      AState.LacingValues[AState.LacingFill - 1] := AState.LacingValues[AState.LacingFill - 1] or LACING_LAST;
  end;

  AState.PageNumber := LPageNumber + 1;
  Result := 0;
end;

class function TOggStream.TakePacket(const AState: POggStreamState; const APacket: POggPacket;
  const AAdvance: Boolean): Integer;
var
  LPointer, LSize, LValue: Integer;
  LBytes: Longint;
  LEnd, LBeginning: Integer;
begin
  LPointer := AState.LacingReturned;

  if AState.LacingPacket <= LPointer then
    Exit(0);

  if (AState.LacingValues[LPointer] and LACING_GAP) <> 0 then
  begin
    // The codec has to know that there is a gap
    Inc(AState.LacingReturned);
    Inc(AState.PacketNumber);
    Exit(-1);
  end;

  // Only asking if a whole packet is there
  if not Assigned(APacket) and not AAdvance then
    Exit(1);

  // The whole packet: there are no holes and no partial packet here
  LSize := AState.LacingValues[LPointer] and $FF;
  LBytes := LSize;
  LEnd := AState.LacingValues[LPointer] and LACING_LAST;
  LBeginning := AState.LacingValues[LPointer] and LACING_FIRST;

  while LSize = FULL_SEGMENT do
  begin
    Inc(LPointer);
    LValue := AState.LacingValues[LPointer];
    LSize := LValue and $FF;
    if (LValue and LACING_LAST) <> 0 then
      LEnd := LACING_LAST;
    Inc(LBytes, LSize);
  end;

  if Assigned(APacket) then
  begin
    APacket.EndOfStream := LEnd;
    APacket.BeginningOfStream := LBeginning;
    APacket.Packet := AState.BodyData + AState.BodyReturned;
    APacket.PacketNumber := AState.PacketNumber;
    APacket.GranulePosition := AState.GranuleValues[LPointer];
    APacket.Bytes := LBytes;
  end;

  if AAdvance then
  begin
    Inc(AState.BodyReturned, LBytes);
    AState.LacingReturned := LPointer + 1;
    Inc(AState.PacketNumber);
  end;
  Result := 1;
end;

class function TOggStream.PacketOut(const AState: POggStreamState; const APacket: POggPacket): Integer;
begin
  if Check(AState) <> 0 then
    Exit(0);
  Result := TakePacket(AState, APacket, True);
end;

class function TOggStream.PacketPeek(const AState: POggStreamState; const APacket: POggPacket): Integer;
begin
  if Check(AState) <> 0 then
    Exit(0);
  Result := TakePacket(AState, APacket, False);
end;

class function TOggStream.Reset(const AState: POggStreamState): Integer;
begin
  if Check(AState) <> 0 then
    Exit(-1);

  AState.BodyFill := 0;
  AState.BodyReturned := 0;

  AState.LacingFill := 0;
  AState.LacingPacket := 0;
  AState.LacingReturned := 0;

  AState.HeaderFill := 0;

  AState.EndOfStream := 0;
  AState.BeginningOfStream := 0;
  AState.PageNumber := -1;
  AState.PacketNumber := 0;
  AState.GranulePosition := 0;
  Result := 0;
end;

class function TOggStream.ResetSerialNumber(const AState: POggStreamState;
  const ASerialNumber: Integer): Integer;
begin
  if Check(AState) <> 0 then
    Exit(-1);
  Reset(AState);
  AState.SerialNumber := ASerialNumber;
  Result := 0;
end;

class procedure TOggStream.ClearPacket(const APacket: POggPacket);
begin
  TOggMemory.Release(APacket.Packet);
  FillChar(APacket^, SizeOf(APacket^), 0);
end;

end.
