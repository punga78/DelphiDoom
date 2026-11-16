{******************************************************************************}
{                                                                              }
{  DelphiDoom: zlib - the class the engine uses in place of the library        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zlib.Client;

interface

uses
  System.SysUtils, DelphiDoom.Zlib.Intf;

const
  // Largest buffer Uncompress grows to when the size of the data is unknown
  ZLIB_CLIENT_MAX_UNCOMPRESSED_SIZE = 256 * 1024 * 1024;

type
  /// <summary>
  ///   Stands for the zlib library in the rest of the engine: works with
  ///   TBytes and raises EZlibException instead of returning error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IZlib, so it works the same with the DLL (see
  ///   TZlibLoader) and with an engine linked in the executable, or with a
  ///   fake in the tests
  /// </remarks>
  TZlibClient = class
  private
    FZlib: IZlib;
    class procedure Check(ACode: Integer); static;
  public
    constructor Create(const AZlib: IZlib);

    function Version: string;

    function Compress(const ASource: TBytes;
      ALevel: Integer = ZLIB_DEFAULT_LEVEL): TBytes; overload;
    function Compress(ASource: Pointer; ASourceSize: Cardinal;
      ALevel: Integer = ZLIB_DEFAULT_LEVEL): TBytes; overload;

    /// <summary>
    ///   Decompresses data whose original size is known
    /// </summary>
    function Uncompress(const ASource: TBytes; AExpectedSize: Cardinal;
      AFormat: TZlibFormat = TZlibFormat.Zlib): TBytes; overload;
    function Uncompress(ASource: Pointer; ASourceSize, AExpectedSize: Cardinal;
      AFormat: TZlibFormat = TZlibFormat.Zlib): TBytes; overload;

    /// <summary>
    ///   Decompresses data of unknown size, growing the buffer up to
    ///   ZLIB_CLIENT_MAX_UNCOMPRESSED_SIZE
    /// </summary>
    function Uncompress(const ASource: TBytes;
      AFormat: TZlibFormat = TZlibFormat.Zlib): TBytes; overload;
    function Uncompress(ASource: Pointer; ASourceSize: Cardinal;
      AFormat: TZlibFormat = TZlibFormat.Zlib): TBytes; overload;

    /// <summary>
    ///   Streams for data that does not fit in one buffer. Raise
    ///   EZlibException if the stream cannot be started
    /// </summary>
    function CreateInflater(AFormat: TZlibFormat = TZlibFormat.Zlib): IZlibInflater;
    function CreateDeflater(ALevel: Integer = ZLIB_DEFAULT_LEVEL): IZlibDeflater;
  end;

implementation

{ TZlibClient }

constructor TZlibClient.Create(const AZlib: IZlib);
begin
  inherited Create;
  if not Assigned(AZlib) then
    raise EArgumentNilException.Create('AZlib');
  FZlib := AZlib;
end;

class procedure TZlibClient.Check(ACode: Integer);
begin
  if ACode <> ZLIB_OK then
    raise EZlibException.CreateCode(ACode);
end;

function TZlibClient.Version: string;
begin
  Result := string(AnsiString(FZlib.GetVersion));
end;

function TZlibClient.Compress(const ASource: TBytes; ALevel: Integer): TBytes;
begin
  Result := Compress(Pointer(ASource), Length(ASource), ALevel);
end;

function TZlibClient.Compress(ASource: Pointer; ASourceSize: Cardinal;
  ALevel: Integer): TBytes;
var
  LSize: Cardinal;
begin
  LSize := FZlib.CompressBound(ASourceSize);
  SetLength(Result, LSize);
  Check(FZlib.Compress(ASource, ASourceSize, Pointer(Result), LSize, ALevel));
  SetLength(Result, LSize);
end;

function TZlibClient.Uncompress(const ASource: TBytes; AExpectedSize: Cardinal;
  AFormat: TZlibFormat): TBytes;
begin
  Result := Uncompress(Pointer(ASource), Length(ASource), AExpectedSize, AFormat);
end;

function TZlibClient.Uncompress(ASource: Pointer; ASourceSize,
  AExpectedSize: Cardinal; AFormat: TZlibFormat): TBytes;
var
  LSize: Cardinal;
begin
  LSize := AExpectedSize;
  SetLength(Result, LSize);
  Check(FZlib.Uncompress(ASource, ASourceSize, Pointer(Result), LSize, AFormat));
  SetLength(Result, LSize);
end;

function TZlibClient.Uncompress(const ASource: TBytes;
  AFormat: TZlibFormat): TBytes;
begin
  Result := Uncompress(Pointer(ASource), Length(ASource), AFormat);
end;

function TZlibClient.Uncompress(ASource: Pointer; ASourceSize: Cardinal;
  AFormat: TZlibFormat): TBytes;
var
  LCapacity: Cardinal;
  LSize: Cardinal;
  LCode: Integer;
begin
  LCapacity := ASourceSize * 4;
  if LCapacity < 4096 then
    LCapacity := 4096;

  repeat
    SetLength(Result, LCapacity);
    LSize := LCapacity;
    LCode := FZlib.Uncompress(ASource, ASourceSize,
      Pointer(Result), LSize, AFormat);
    if LCode = ZLIB_OK then
    begin
      SetLength(Result, LSize);
      Exit;
    end;
    // Only a full buffer is worth another attempt with a larger one
    if (LCode <> ZLIB_BUF_ERROR) or
       (LCapacity >= ZLIB_CLIENT_MAX_UNCOMPRESSED_SIZE) then
      raise EZlibException.CreateCode(LCode);
    LCapacity := LCapacity * 2;
  until False;
end;

function TZlibClient.CreateInflater(AFormat: TZlibFormat): IZlibInflater;
begin
  Check(FZlib.CreateInflater(AFormat, Result));
end;

function TZlibClient.CreateDeflater(ALevel: Integer): IZlibDeflater;
begin
  Check(FZlib.CreateDeflater(ALevel, Result));
end;

end.
