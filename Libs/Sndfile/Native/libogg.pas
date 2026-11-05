//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

unit libogg;

{$Z+}
{$H+}

// The functions of libogg that the C objects of libvorbis, libflac and libsndfile call, with
// the names and the calling convention of the C ones (cdecl, underscore in front). They are
// thin: the work is done by the classes of Libs\Ogg. This unit goes away with the last
// of those objects

interface

uses
  DelphiDoom.Ogg.Types;

//==============================================================================
// Pages
//==============================================================================
function _ogg_page_bos(og: POggPage): Integer; cdecl;
function _ogg_page_continued(og: POggPage): Integer; cdecl;
function _ogg_page_eos(og: POggPage): Integer; cdecl;
function _ogg_page_granulepos(og: POggPage): Int64; cdecl;
function _ogg_page_serialno(og: POggPage): Integer; cdecl;
procedure _ogg_page_checksum_set(og: POggPage); cdecl;

//==============================================================================
// Streams
//==============================================================================
function _ogg_stream_init(os: POggStreamState; serialno: Integer): Integer; cdecl;
function _ogg_stream_clear(os: POggStreamState): Integer; cdecl;
function _ogg_stream_reset(os: POggStreamState): Integer; cdecl;
function _ogg_stream_reset_serialno(os: POggStreamState; serialno: Integer): Integer; cdecl;
function _ogg_stream_pagein(os: POggStreamState; og: POggPage): Integer; cdecl;
function _ogg_stream_packetout(os: POggStreamState; op: POggPacket): Integer; cdecl;
function _ogg_stream_packetpeek(os: POggStreamState; op: POggPacket): Integer; cdecl;
function _ogg_stream_packetin(os: POggStreamState; op: POggPacket): Integer; cdecl;
function _ogg_stream_flush(os: POggStreamState; og: POggPage): Integer; cdecl;
function _ogg_stream_pageout(os: POggStreamState; og: POggPage): Integer; cdecl;

//==============================================================================
// Physical streams
//==============================================================================
function _ogg_sync_init(oy: POggSyncState): Integer; cdecl;
function _ogg_sync_clear(oy: POggSyncState): Integer; cdecl;
function _ogg_sync_reset(oy: POggSyncState): Integer; cdecl;
function _ogg_sync_buffer(oy: POggSyncState; size: Longint): PByte; cdecl;
function _ogg_sync_wrote(oy: POggSyncState; bytes: Longint): Integer; cdecl;
function _ogg_sync_pageseek(oy: POggSyncState; og: POggPage): Longint; cdecl;
function _ogg_sync_pageout(oy: POggSyncState; og: POggPage): Integer; cdecl;

//==============================================================================
// Bits
//==============================================================================
procedure _oggpack_writeinit(b: POggPackBuffer); cdecl;
procedure _oggpack_writetrunc(b: POggPackBuffer; bits: Longint); cdecl;
procedure _oggpack_write(b: POggPackBuffer; value: Cardinal; bits: Integer); cdecl;
procedure _oggpack_reset(b: POggPackBuffer); cdecl;
procedure _oggpack_writeclear(b: POggPackBuffer); cdecl;
procedure _oggpack_readinit(b: POggPackBuffer; buf: PByte; bytes: Integer); cdecl;
function _oggpack_look(b: POggPackBuffer; bits: Integer): Longint; cdecl;
procedure _oggpack_adv(b: POggPackBuffer; bits: Integer); cdecl;
function _oggpack_read(b: POggPackBuffer; bits: Integer): Longint; cdecl;
function _oggpack_bytes(b: POggPackBuffer): Longint; cdecl;
function _oggpack_get_buffer(b: POggPackBuffer): PByte; cdecl;

implementation

uses
  DelphiDoom.Ogg.BitPacker,
  DelphiDoom.Ogg.PageReader,
  DelphiDoom.Ogg.Stream,
  DelphiDoom.Ogg.Sync;

function _ogg_page_bos(og: POggPage): Integer;
begin
  Result := TOggPageReader.BeginningOfStream(og);
end;

function _ogg_page_continued(og: POggPage): Integer;
begin
  Result := TOggPageReader.Continued(og);
end;

function _ogg_page_eos(og: POggPage): Integer;
begin
  Result := TOggPageReader.EndOfStream(og);
end;

function _ogg_page_granulepos(og: POggPage): Int64;
begin
  Result := TOggPageReader.GranulePosition(og);
end;

function _ogg_page_serialno(og: POggPage): Integer;
begin
  Result := TOggPageReader.SerialNumber(og);
end;

procedure _ogg_page_checksum_set(og: POggPage);
begin
  TOggPageReader.SetChecksum(og);
end;

function _ogg_stream_init(os: POggStreamState; serialno: Integer): Integer;
begin
  Result := TOggStream.Init(os, serialno);
end;

function _ogg_stream_clear(os: POggStreamState): Integer;
begin
  Result := TOggStream.Clear(os);
end;

function _ogg_stream_reset(os: POggStreamState): Integer;
begin
  Result := TOggStream.Reset(os);
end;

function _ogg_stream_reset_serialno(os: POggStreamState; serialno: Integer): Integer;
begin
  Result := TOggStream.ResetSerialNumber(os, serialno);
end;

function _ogg_stream_pagein(os: POggStreamState; og: POggPage): Integer;
begin
  Result := TOggStream.PageIn(os, og);
end;

function _ogg_stream_packetout(os: POggStreamState; op: POggPacket): Integer;
begin
  Result := TOggStream.PacketOut(os, op);
end;

function _ogg_stream_packetpeek(os: POggStreamState; op: POggPacket): Integer;
begin
  Result := TOggStream.PacketPeek(os, op);
end;

function _ogg_stream_packetin(os: POggStreamState; op: POggPacket): Integer;
begin
  Result := TOggStream.PacketIn(os, op);
end;

function _ogg_stream_flush(os: POggStreamState; og: POggPage): Integer;
begin
  Result := TOggStream.Flush(os, og);
end;

function _ogg_stream_pageout(os: POggStreamState; og: POggPage): Integer;
begin
  Result := TOggStream.PageOut(os, og);
end;

function _ogg_sync_init(oy: POggSyncState): Integer;
begin
  Result := TOggSync.Init(oy);
end;

function _ogg_sync_clear(oy: POggSyncState): Integer;
begin
  Result := TOggSync.Clear(oy);
end;

function _ogg_sync_reset(oy: POggSyncState): Integer;
begin
  Result := TOggSync.Reset(oy);
end;

function _ogg_sync_buffer(oy: POggSyncState; size: Longint): PByte;
begin
  Result := TOggSync.Buffer(oy, size);
end;

function _ogg_sync_wrote(oy: POggSyncState; bytes: Longint): Integer;
begin
  Result := TOggSync.Wrote(oy, bytes);
end;

function _ogg_sync_pageseek(oy: POggSyncState; og: POggPage): Longint;
begin
  Result := TOggSync.PageSeek(oy, og);
end;

function _ogg_sync_pageout(oy: POggSyncState; og: POggPage): Integer;
begin
  Result := TOggSync.PageOut(oy, og);
end;

procedure _oggpack_writeinit(b: POggPackBuffer);
begin
  TOggBitPacker.WriteInit(b);
end;

procedure _oggpack_writetrunc(b: POggPackBuffer; bits: Longint);
begin
  TOggBitPacker.WriteTruncate(b, bits);
end;

procedure _oggpack_write(b: POggPackBuffer; value: Cardinal; bits: Integer);
begin
  TOggBitPacker.Write(b, value, bits);
end;

procedure _oggpack_reset(b: POggPackBuffer);
begin
  TOggBitPacker.Reset(b);
end;

procedure _oggpack_writeclear(b: POggPackBuffer);
begin
  TOggBitPacker.WriteClear(b);
end;

procedure _oggpack_readinit(b: POggPackBuffer; buf: PByte; bytes: Integer);
begin
  TOggBitPacker.ReadInit(b, buf, bytes);
end;

function _oggpack_look(b: POggPackBuffer; bits: Integer): Longint;
begin
  Result := TOggBitPacker.Look(b, bits);
end;

procedure _oggpack_adv(b: POggPackBuffer; bits: Integer);
begin
  TOggBitPacker.Advance(b, bits);
end;

function _oggpack_read(b: POggPackBuffer; bits: Integer): Longint;
begin
  Result := TOggBitPacker.Read(b, bits);
end;

function _oggpack_bytes(b: POggPackBuffer): Longint;
begin
  Result := TOggBitPacker.Bytes(b);
end;

function _oggpack_get_buffer(b: POggPackBuffer): PByte;
begin
  Result := TOggBitPacker.GetBuffer(b);
end;

end.
