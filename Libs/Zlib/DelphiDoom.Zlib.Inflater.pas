{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - incremental decompression                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Inflater;

interface

uses
  System.ZLib, DelphiDoom.Zlib.Intf;

type
  /// <summary>
  ///   One zlib decompression stream. Not thread safe: use one per thread
  /// </summary>
  TZlibInflater = class(TInterfacedObject, IZlibInflater)
  private
    FStream: TZStreamRec;
    FStarted: Boolean;
  public
    destructor Destroy; override;

    /// <summary>
    ///   Initializes the stream; AWindowBits as in inflateInit2
    /// </summary>
    function Start(AWindowBits: Integer): Integer;

    function Inflate(var ABuffers: TZlibStreamBuffers; AFlush: Integer): Integer; stdcall;
  end;

implementation

{ TZlibInflater }

destructor TZlibInflater.Destroy;
begin
  if FStarted then
    inflateEnd(FStream);
  inherited;
end;

function TZlibInflater.Start(AWindowBits: Integer): Integer;
begin
  FillChar(FStream, SizeOf(FStream), 0);
  Result := inflateInit2_(FStream, AWindowBits, ZLIB_API_VERSION, SizeOf(FStream));
  FStarted := Result = ZLIB_OK;
end;

function TZlibInflater.Inflate(var ABuffers: TZlibStreamBuffers;
  AFlush: Integer): Integer;
begin
  if not FStarted then
    Exit(ZLIB_STREAM_ERROR);

  FStream.next_in := ABuffers.NextIn;
  FStream.avail_in := Longint(ABuffers.AvailIn);
  FStream.next_out := ABuffers.NextOut;
  FStream.avail_out := Longint(ABuffers.AvailOut);

  // Qualified: inside this class "inflate" would resolve to the method Inflate
  Result := System.ZLib.inflate(FStream, AFlush);

  ABuffers.NextIn := FStream.next_in;
  ABuffers.AvailIn := Cardinal(FStream.avail_in);
  ABuffers.TotalIn := Cardinal(FStream.total_in);
  ABuffers.NextOut := FStream.next_out;
  ABuffers.AvailOut := Cardinal(FStream.avail_out);
  ABuffers.TotalOut := Cardinal(FStream.total_out);

  if Result = ZLIB_NEED_DICT then
    Result := ZLIB_DATA_ERROR;
end;

end.
