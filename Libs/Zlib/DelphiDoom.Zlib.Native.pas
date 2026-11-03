{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - binding to the C code (zlib 1.2.8)                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Native;

// The zlib objects (ZLIB\z128_*.obj) are linked with the L directive: the
// folder ZLIB must be in the object path of the project. This unit has no
// dependency on the rest of the engine so that it can live inside a DLL.

interface

const
  Z_NO_FLUSH = 0;
  Z_SYNC_FLUSH = 2;
  Z_FINISH = 4;

  Z_OK = 0;
  Z_STREAM_END = 1;
  Z_NEED_DICT = 2;
  Z_STREAM_ERROR = -2;
  Z_DATA_ERROR = -3;
  Z_MEM_ERROR = -4;
  Z_BUF_ERROR = -5;

  ZLIB_VERSION_TEXT: PAnsiChar = '1.2.8';

type
  TZAlloc = function(AOpaque: Pointer; AItems, ASize: Integer): Pointer;
  TZFree = procedure(AOpaque, ABlock: Pointer);

  // Layout of z_stream: field names follow the C declaration
  TZStreamRec = packed record
    next_in: PByte;
    avail_in: Longint;
    total_in: Longint;

    next_out: PByte;
    avail_out: Longint;
    total_out: Longint;

    msg: PAnsiChar;
    state: Pointer;

    zalloc: TZAlloc;
    zfree: TZFree;
    opaque: Pointer;

    data_type: Integer;
    adler: Longint;
    reserved: Longint;
  end;

function deflateInit_(var strm: TZStreamRec; level: Integer; version: PAnsiChar;
  recsize: Integer): Integer;
function deflate(var strm: TZStreamRec; flush: Integer): Integer;
function deflateEnd(var strm: TZStreamRec): Integer;

function inflateInit2_(var strm: TZStreamRec; windowBits: Integer;
  version: PAnsiChar; recsize: Integer): Integer;
function inflate(var strm: TZStreamRec; flush: Integer): Integer;
function inflateEnd(var strm: TZStreamRec): Integer;

implementation

{$L z128_deflate}
{$L z128_inflate}
{$L z128_inftrees}
{$L z128_infback}
{$L z128_inffast}
{$L z128_trees}
{$L z128_compress}
{$L z128_adler32}
{$L z128_crc32}

// Error messages indexed by the C code (zError): pointers to ANSI text
const
  z_errmsg: array[0..9] of PAnsiChar = (
    'Need dictionary',      // Z_NEED_DICT      (2)
    'Stream end',           // Z_STREAM_END     (1)
    'OK',                   // Z_OK             (0)
    'File error',           // Z_ERRNO          (-1)
    'Stream error',         // Z_STREAM_ERROR   (-2)
    'Data error',           // Z_DATA_ERROR     (-3)
    'Insufficient memory',  // Z_MEM_ERROR      (-4)
    'Buffer error',         // Z_BUF_ERROR      (-5)
    'Incompatible version', // Z_VERSION_ERROR  (-6)
    ''
  );

// Functions of the C runtime that the objects import. The names must match the
// symbols of the objects, so they cannot follow the naming rules

function zcalloc(AOpaque: Pointer; AItems, ASize: Integer): Pointer;
begin
  GetMem(Result, AItems * ASize);
end;

procedure zcfree(AOpaque, ABlock: Pointer);
begin
  FreeMem(ABlock);
end;

procedure memcpy(ADest, ASource: Pointer; ACount: Integer); cdecl;
begin
  Move(ASource^, ADest^, ACount);
end;

function memset(P: Pointer; B: Byte; ACount: Integer): Pointer; cdecl;
begin
  FillChar(P^, ACount, B);
  Result := P;
end;

function deflateInit_(var strm: TZStreamRec; level: Integer; version: PAnsiChar;
  recsize: Integer): Integer; external;
function deflate(var strm: TZStreamRec; flush: Integer): Integer; external;
function deflateEnd(var strm: TZStreamRec): Integer; external;

function inflateInit2_(var strm: TZStreamRec; windowBits: Integer;
  version: PAnsiChar; recsize: Integer): Integer; external;
function inflate(var strm: TZStreamRec; flush: Integer): Integer; external;
function inflateEnd(var strm: TZStreamRec): Integer; external;

{$IFNDEF WIN64}
// 64 bit modulo helper imported by the objects (Int64 mod of the C code)
procedure _llmod;
asm
  jmp System.@_llmod;
end;
{$ENDIF}

end.
