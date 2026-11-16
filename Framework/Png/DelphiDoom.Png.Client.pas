{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - the class the engine uses in place of the library         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Client;

interface

uses
  System.SysUtils, DelphiDoom.Png.Intf;

type
  /// <summary>
  ///   A decoded image: Pixels holds Height rows of Width pixels of 4 bytes
  ///   (B, G, R, A), from top to bottom, without padding
  /// </summary>
  TPngImage = record
    Info: TPngInfo;
    Pixels: TBytes;
  end;

  /// <summary>
  ///   A decoded palette image: Pixels holds Height rows of Width palette
  ///   indices (one byte each) and Palette the 256 entries of the palette as
  ///   4 bytes (B, G, R, A), DDPNG_PALETTE_BYTES bytes
  /// </summary>
  TPngIndexedImage = record
    Info: TPngInfo;
    Pixels: TBytes;
    Palette: TBytes;
  end;

  /// <summary>
  ///   Stands for the PNG library in the rest of the engine: works with
  ///   TBytes and raises EPngException instead of returning error codes
  /// </summary>
  /// <remarks>
  ///   Depends only on IPng, so it works the same with the DLL (see
  ///   TPngLoader) and with an engine linked in the executable, or with a
  ///   fake in the tests
  /// </remarks>
  TPngClient = class
  private
    FPng: IPng;
    class procedure Check(ACode: Integer); static;
    class function SizeOfPixels(const AInfo: TPngInfo;
      ABytesPerPixel: Integer): Integer; static;
  public
    constructor Create(const APng: IPng);

    function Version: string;

    /// <summary>
    ///   Size and format of a PNG file, without decoding it
    /// </summary>
    function GetInfo(const ASource: TBytes): TPngInfo; overload;
    function GetInfo(ASource: Pointer; ASourceSize: Cardinal): TPngInfo; overload;

    /// <summary>
    ///   Decodes any PNG file to BGRA pixels
    /// </summary>
    function Decode(const ASource: TBytes): TPngImage; overload;
    function Decode(ASource: Pointer; ASourceSize: Cardinal): TPngImage; overload;

    /// <summary>
    ///   Decodes a palette image to indices and palette. Raises
    ///   EPngException with DDPNG_ERR_UNSUPPORTED for another color type
    /// </summary>
    function DecodeIndexed(const ASource: TBytes): TPngIndexedImage; overload;
    function DecodeIndexed(ASource: Pointer;
      ASourceSize: Cardinal): TPngIndexedImage; overload;

    /// <summary>
    ///   Encodes AWidth * AHeight pixels of the given layout (DDPNG_FORMAT_*)
    ///   into a PNG file. AStride: see IPng.Encode, 0 for rows without padding
    /// </summary>
    function Encode(const APixels: TBytes; AWidth, AHeight: Integer;
      AFormat: Integer = DDPNG_FORMAT_BGRA; ALevel: Integer = DDPNG_DEFAULT_LEVEL;
      AStride: Integer = 0): TBytes; overload;
    function Encode(APixels: Pointer; AWidth, AHeight: Integer;
      AFormat: Integer = DDPNG_FORMAT_BGRA; ALevel: Integer = DDPNG_DEFAULT_LEVEL;
      AStride: Integer = 0): TBytes; overload;
  end;

implementation

{ TPngClient }

constructor TPngClient.Create(const APng: IPng);
begin
  inherited Create;
  if not Assigned(APng) then
    raise EArgumentNilException.Create('APng');
  FPng := APng;
end;

class procedure TPngClient.Check(ACode: Integer);
begin
  if ACode <> DDPNG_OK then
    raise EPngException.CreateCode(ACode);
end;

class function TPngClient.SizeOfPixels(const AInfo: TPngInfo;
  ABytesPerPixel: Integer): Integer;
var
  LSize: Int64;
begin
  LSize := Int64(AInfo.Width) * AInfo.Height * ABytesPerPixel;
  if LSize > High(Integer) then
    raise EPngException.CreateCode(DDPNG_ERR_TOO_LARGE);
  Result := Integer(LSize);
end;

function TPngClient.Version: string;
begin
  Result := string(AnsiString(FPng.GetVersion));
end;

function TPngClient.GetInfo(const ASource: TBytes): TPngInfo;
begin
  Result := GetInfo(Pointer(ASource), Length(ASource));
end;

function TPngClient.GetInfo(ASource: Pointer; ASourceSize: Cardinal): TPngInfo;
begin
  Check(FPng.GetInfo(ASource, ASourceSize, Result));
end;

function TPngClient.Decode(const ASource: TBytes): TPngImage;
begin
  Result := Decode(Pointer(ASource), Length(ASource));
end;

function TPngClient.Decode(ASource: Pointer; ASourceSize: Cardinal): TPngImage;
var
  LInfo: TPngInfo;
  LSize: Integer;
begin
  LInfo := GetInfo(ASource, ASourceSize);
  LSize := SizeOfPixels(LInfo, 4);

  Result.Pixels := nil;
  SetLength(Result.Pixels, LSize);
  Check(FPng.Decode(ASource, ASourceSize, Pointer(Result.Pixels),
    Cardinal(LSize), Result.Info));
end;

function TPngClient.DecodeIndexed(const ASource: TBytes): TPngIndexedImage;
begin
  Result := DecodeIndexed(Pointer(ASource), Length(ASource));
end;

function TPngClient.DecodeIndexed(ASource: Pointer;
  ASourceSize: Cardinal): TPngIndexedImage;
var
  LInfo: TPngInfo;
  LSize: Integer;
begin
  LInfo := GetInfo(ASource, ASourceSize);
  LSize := SizeOfPixels(LInfo, 1);

  Result.Pixels := nil;
  Result.Palette := nil;
  SetLength(Result.Pixels, LSize);
  SetLength(Result.Palette, DDPNG_PALETTE_BYTES);
  Check(FPng.DecodeIndexed(ASource, ASourceSize, Pointer(Result.Pixels),
    Cardinal(LSize), Pointer(Result.Palette), Result.Info));
end;

function TPngClient.Encode(const APixels: TBytes; AWidth, AHeight, AFormat,
  ALevel, AStride: Integer): TBytes;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  // The pixels the image needs: the last row does not need its padding
  case AFormat of
    DDPNG_FORMAT_BGRA, DDPNG_FORMAT_BGRX: LRowBytes := Int64(AWidth) * 4;
    DDPNG_FORMAT_BGR:                      LRowBytes := Int64(AWidth) * 3;
  else
    LRowBytes := AWidth;
  end;
  LStride := Abs(AStride);
  if LStride = 0 then
    LStride := LRowBytes;
  if (AWidth < 1) or (AHeight < 1) or
     (Int64(Length(APixels)) < LStride * (AHeight - 1) + LRowBytes) then
    raise EPngException.CreateCode(DDPNG_ERR_INVALID_ARGUMENT);

  // A negative stride reads the rows upwards from the pointer: start from
  // the last row of the array
  if AStride < 0 then
    Result := Encode(Pointer(NativeUInt(Pointer(APixels)) +
      NativeUInt(LStride * (AHeight - 1))), AWidth, AHeight, AFormat, ALevel,
      AStride)
  else
    Result := Encode(Pointer(APixels), AWidth, AHeight, AFormat, ALevel,
      AStride);
end;

function TPngClient.Encode(APixels: Pointer; AWidth, AHeight, AFormat,
  ALevel, AStride: Integer): TBytes;
var
  LBound: Cardinal;
  LSize: Cardinal;
begin
  LBound := FPng.EncodeBound(AWidth, AHeight, AFormat);
  if LBound = 0 then
    raise EPngException.CreateCode(DDPNG_ERR_INVALID_ARGUMENT);
  if LBound > Cardinal(High(Integer)) then
    raise EPngException.CreateCode(DDPNG_ERR_TOO_LARGE);

  // The bound is a worst case that holds for any content: the memory is only
  // reserved, and given back when the actual size is known
  Result := nil;
  SetLength(Result, Integer(LBound));
  LSize := LBound;
  Check(FPng.Encode(APixels, AWidth, AHeight, AFormat, AStride, ALevel,
    Pointer(Result), LSize));
  SetLength(Result, Integer(LSize));
end;

end.
