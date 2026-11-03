{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - incremental compression                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Deflater;

interface

uses
  DelphiDoom.Zlib.Intf, DelphiDoom.Zlib.Native;

type
  /// <summary>
  ///   One zlib compression stream. Not thread safe: use one per thread
  /// </summary>
  TZlibDeflater = class(TInterfacedObject, IZlibDeflater)
  private
    FStream: TZStreamRec;
    FStarted: Boolean;
  public
    destructor Destroy; override;

    /// <summary>
    ///   Initializes the stream with the given compression level
    /// </summary>
    function Start(ALevel: Integer): Integer;

    function Deflate(var ABuffers: TZlibStreamBuffers; AFlush: Integer): Integer; stdcall;
  end;

implementation

{ TZlibDeflater }

destructor TZlibDeflater.Destroy;
begin
  if FStarted then
    deflateEnd(FStream);
  inherited;
end;

function TZlibDeflater.Start(ALevel: Integer): Integer;
begin
  FillChar(FStream, SizeOf(FStream), 0);
  Result := deflateInit_(FStream, ALevel, ZLIB_VERSION_TEXT, SizeOf(FStream));
  FStarted := Result = Z_OK;
end;

function TZlibDeflater.Deflate(var ABuffers: TZlibStreamBuffers;
  AFlush: Integer): Integer;
begin
  if not FStarted then
    Exit(Z_STREAM_ERROR);

  FStream.next_in := ABuffers.NextIn;
  FStream.avail_in := Longint(ABuffers.AvailIn);
  FStream.next_out := ABuffers.NextOut;
  FStream.avail_out := Longint(ABuffers.AvailOut);

  // Qualified: inside this class "deflate" would resolve to the method Deflate
  Result := DelphiDoom.Zlib.Native.deflate(FStream, AFlush);

  ABuffers.NextIn := FStream.next_in;
  ABuffers.AvailIn := Cardinal(FStream.avail_in);
  ABuffers.TotalIn := Cardinal(FStream.total_in);
  ABuffers.NextOut := FStream.next_out;
  ABuffers.AvailOut := Cardinal(FStream.avail_out);
  ABuffers.TotalOut := Cardinal(FStream.total_out);
end;

end.
