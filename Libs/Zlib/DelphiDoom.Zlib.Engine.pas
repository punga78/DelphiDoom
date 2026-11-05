{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - implementation of IZlib on top of the C code             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Engine;

interface

uses
  DelphiDoom.Zlib.Intf;

type
  /// <summary>
  ///   Stateless implementation of IZlib: every call uses its own z_stream, so
  ///   one instance can be used by several threads
  /// </summary>
  TZlibEngine = class(TInterfacedObject, IZlib)
  private
    class function WindowBitsOf(AFormat: TZlibFormat): Integer; static;
  public
    function GetVersion: PAnsiChar; stdcall;
    function CompressBound(ASourceSize: Cardinal): Cardinal; stdcall;
    function Compress(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      var ADestSize: Cardinal; ALevel: Integer): Integer; stdcall;
    function Uncompress(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      var ADestSize: Cardinal; AFormat: TZlibFormat): Integer; stdcall;
    function CreateInflater(AFormat: TZlibFormat;
      out AInflater: IZlibInflater): Integer; stdcall;
    function CreateDeflater(ALevel: Integer;
      out ADeflater: IZlibDeflater): Integer; stdcall;
  end;

implementation

uses
  System.ZLib, DelphiDoom.Zlib.Inflater, DelphiDoom.Zlib.Deflater;

const
  MAX_STREAM_SIZE = Cardinal(High(Longint));
  // What GetVersion answers: the code is the one of the RTL of Delphi
  ZLIB_LIBRARY_NAME: PAnsiChar = 'System.ZLib';

{ TZlibEngine }

class function TZlibEngine.WindowBitsOf(AFormat: TZlibFormat): Integer;
begin
  case AFormat of
    TZlibFormat.Zlib: Result := 15;
    TZlibFormat.Raw:  Result := -15;
    TZlibFormat.Gzip: Result := 15 + 16;
    TZlibFormat.Auto: Result := 15 + 32;
  else
    Result := 15;
  end;
end;

function TZlibEngine.GetVersion: PAnsiChar;
begin
  Result := ZLIB_LIBRARY_NAME;
end;

function TZlibEngine.CompressBound(ASourceSize: Cardinal): Cardinal;
begin
  // Same formula as compressBound() of zlib
  Result := ASourceSize + (ASourceSize shr 12) + (ASourceSize shr 14) +
    (ASourceSize shr 25) + 13;
end;

function TZlibEngine.Compress(ASource: Pointer; ASourceSize: Cardinal;
  ADest: Pointer; var ADestSize: Cardinal; ALevel: Integer): Integer;
var
  LStream: TZStreamRec;
begin
  if (ADest = nil) or ((ASource = nil) and (ASourceSize > 0)) then
    Exit(ZLIB_STREAM_ERROR);
  if (ASourceSize > MAX_STREAM_SIZE) or (ADestSize > MAX_STREAM_SIZE) then
    Exit(ZLIB_BUF_ERROR);

  FillChar(LStream, SizeOf(LStream), 0);
  Result := deflateInit_(LStream, ALevel, ZLIB_API_VERSION, SizeOf(LStream));
  if Result <> ZLIB_OK then
    Exit;

  try
    LStream.next_in := ASource;
    LStream.avail_in := Longint(ASourceSize);
    LStream.next_out := ADest;
    LStream.avail_out := Longint(ADestSize);

    Result := deflate(LStream, ZLIB_FINISH);
    if Result = ZLIB_STREAM_END then
    begin
      ADestSize := Cardinal(LStream.total_out);
      Result := ZLIB_OK;
    end
    else if Result = ZLIB_OK then
      // ZLIB_FINISH not completed: the destination buffer is too small
      Result := ZLIB_BUF_ERROR;
  finally
    deflateEnd(LStream);
  end;
end;

function TZlibEngine.Uncompress(ASource: Pointer; ASourceSize: Cardinal;
  ADest: Pointer; var ADestSize: Cardinal; AFormat: TZlibFormat): Integer;
var
  LStream: TZStreamRec;
  LNoOutput: Byte;
begin
  if ((ADest = nil) and (ADestSize > 0)) or
     ((ASource = nil) and (ASourceSize > 0)) then
    Exit(ZLIB_STREAM_ERROR);
  if (ASourceSize > MAX_STREAM_SIZE) or (ADestSize > MAX_STREAM_SIZE) then
    Exit(ZLIB_BUF_ERROR);

  FillChar(LStream, SizeOf(LStream), 0);
  Result := inflateInit2_(LStream, WindowBitsOf(AFormat), ZLIB_API_VERSION,
    SizeOf(LStream));
  if Result <> ZLIB_OK then
    Exit;

  try
    LStream.next_in := ASource;
    LStream.avail_in := Longint(ASourceSize);
    // zlib rejects a null output pointer even when no output is needed
    if ADest <> nil then
      LStream.next_out := ADest
    else
      LStream.next_out := @LNoOutput;
    LStream.avail_out := Longint(ADestSize);

    Result := inflate(LStream, ZLIB_FINISH);
    if Result = ZLIB_STREAM_END then
    begin
      ADestSize := Cardinal(LStream.total_out);
      Result := ZLIB_OK;
    end
    else if Result = ZLIB_NEED_DICT then
      Result := ZLIB_DATA_ERROR
    else if Result = ZLIB_OK then
      Result := ZLIB_BUF_ERROR;
  finally
    inflateEnd(LStream);
  end;
end;

function TZlibEngine.CreateInflater(AFormat: TZlibFormat;
  out AInflater: IZlibInflater): Integer;
var
  LInflater: TZlibInflater;
begin
  AInflater := nil;
  LInflater := TZlibInflater.Create;
  Result := LInflater.Start(WindowBitsOf(AFormat));
  if Result = ZLIB_OK then
    AInflater := LInflater
  else
    LInflater.Free;
end;

function TZlibEngine.CreateDeflater(ALevel: Integer;
  out ADeflater: IZlibDeflater): Integer;
var
  LDeflater: TZlibDeflater;
begin
  ADeflater := nil;
  LDeflater := TZlibDeflater.Create;
  Result := LDeflater.Start(ALevel);
  if Result = ZLIB_OK then
    ADeflater := LDeflater
  else
    LDeflater.Free;
end;

end.
