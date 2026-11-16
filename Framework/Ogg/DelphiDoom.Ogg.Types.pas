{******************************************************************************}
{                                                                              }
{  DelphiDoom: Ogg - the structures of the container, as the C code lays them  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libogg by the Xiph.Org Foundation (BSD licence)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ogg.Types;

interface

// The layout is that of the C structures, which libvorbis, libflac and libsndfile
// (still in C) read and write: 8 byte alignment, 32 bit pointers and longs
{$A8}

{$POINTERMATH ON}

type
  /// <summary>Lacing values of a stream: one for each segment of its table</summary>
  PLacingValues = ^Integer;
  /// <summary>Granule positions of a stream: one for each segment of its table</summary>
  PGranuleValues = ^Int64;

  /// <summary>A buffer where words of variable size are packed, or are read from (oggpack_buffer)</summary>
  POggPackBuffer = ^TOggPackBuffer;
  TOggPackBuffer = record
    EndByte: Longint;
    EndBit: Integer;
    Buffer: PByte;
    Ptr: PByte;
    Storage: Longint;
  end;

  /// <summary>One page of an Ogg stream: pointers to its header and to its body (ogg_page)</summary>
  POggPage = ^TOggPage;
  TOggPage = record
    Header: PByte;
    HeaderLength: Longint;
    Body: PByte;
    BodyLength: Longint;
  end;

  /// <summary>A block of bytes to submit as a part of a packet (ogg_iovec_t)</summary>
  POggIoVec = ^TOggIoVec;
  TOggIoVec = record
    Base: Pointer;
    Length: Cardinal;
  end;

  /// <summary>A raw packet of a codec (ogg_packet)</summary>
  POggPacket = ^TOggPacket;
  TOggPacket = record
    Packet: PByte;
    Bytes: Longint;
    BeginningOfStream: Longint;
    EndOfStream: Longint;
    GranulePosition: Int64;
    PacketNumber: Int64;
  end;

  /// <summary>The state of the encoding or decoding of a logical stream (ogg_stream_state)</summary>
  POggStreamState = ^TOggStreamState;
  TOggStreamState = record
    BodyData: PByte;
    BodyStorage: Longint;
    BodyFill: Longint;
    BodyReturned: Longint;
    LacingValues: PLacingValues;
    GranuleValues: PGranuleValues;
    LacingStorage: Longint;
    LacingFill: Longint;
    LacingPacket: Longint;
    LacingReturned: Longint;
    Header: array[0..281] of Byte;
    HeaderFill: Integer;
    EndOfStream: Integer;
    BeginningOfStream: Integer;
    SerialNumber: Longint;
    PageNumber: Longint;
    PacketNumber: Int64;
    GranulePosition: Int64;
  end;

  /// <summary>The state of the search of pages in a physical stream (ogg_sync_state)</summary>
  POggSyncState = ^TOggSyncState;
  TOggSyncState = record
    Data: PByte;
    Storage: Integer;
    Fill: Integer;
    Returned: Integer;
    Unsynced: Integer;
    HeaderBytes: Integer;
    BodyBytes: Integer;
  end;

implementation

end.
