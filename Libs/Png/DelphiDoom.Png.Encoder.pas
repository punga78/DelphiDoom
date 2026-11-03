{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - encoder                                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Encoder;

// Writes a non-interlaced 8 bit image with a single IDAT chunk. The scanlines
// are filtered one at a time (each with the filter that looks best for it) and
// fed to the incremental interface of IZlib, which writes the compressed data
// straight into the buffer of the caller: the memory used besides it is a few
// scanlines, whatever the size of the image. Every failure is an
// EPngException: the engine turns it into a result code.

interface

{$POINTERMATH ON}

uses
  System.SysUtils, DelphiDoom.Zlib.Intf;

type
  /// <summary>
  ///   Encodes images into PNG files held in memory. Stateless: one instance
  ///   can serve several threads if the IZlib can
  /// </summary>
  TPngEncoder = class
  private
    FZlib: IZlib;

    class function IsValidImage(AWidth, AHeight, AFormat: Integer): Boolean; static;
    class function ClampLevel(ALevel: Integer): Integer; static;
    class procedure RaiseForZlib(ACode: Integer); static;
    function CreateDeflater(ALevel: Integer): IZlibDeflater;
    procedure Feed(const ADeflater: IZlibDeflater;
      var ABuffers: TZlibStreamBuffers; AData: PByte; ASize: Cardinal);
    procedure Finish(const ADeflater: IZlibDeflater;
      var ABuffers: TZlibStreamBuffers);
  public
    constructor Create(const AZlib: IZlib);

    /// <summary>
    ///   Upper bound of the size of the file for an image of that size; 0 if
    ///   the size or the format is not valid
    /// </summary>
    function Bound(AWidth, AHeight, AFormat: Integer): Cardinal;

    /// <summary>
    ///   Writes the file into ADest. ADestSize is the size of ADest on input
    ///   and the size of the file on output; it is not changed when the
    ///   buffer is too small. Raises DDPNG_ERR_INVALID_ARGUMENT or
    ///   DDPNG_ERR_BUFFER_TOO_SMALL
    /// </summary>
    procedure Encode(APixels: Pointer; AWidth, AHeight, AFormat, AStride,
      ALevel: Integer; ADest: Pointer; var ADestSize: Cardinal);
  end;

implementation

uses
  DelphiDoom.Png.Intf, DelphiDoom.Png.Header, DelphiDoom.Png.ByteOrder,
  DelphiDoom.Png.ChunkReader, DelphiDoom.Png.ChunkWriter,
  DelphiDoom.Png.Filter, DelphiDoom.Png.PixelPacker;

const
  PNG_SAMPLE_DEPTH = 8;

{ TPngEncoder }

constructor TPngEncoder.Create(const AZlib: IZlib);
begin
  inherited Create;
  if not Assigned(AZlib) then
    raise EArgumentNilException.Create('AZlib');
  FZlib := AZlib;
end;

class function TPngEncoder.IsValidImage(AWidth, AHeight,
  AFormat: Integer): Boolean;
begin
  Result := (AWidth >= 1) and (AWidth <= DDPNG_MAX_DIMENSION) and
    (AHeight >= 1) and (AHeight <= DDPNG_MAX_DIMENSION) and
    (Int64(AWidth) * AHeight <= DDPNG_MAX_PIXELS) and
    TPngPixelPacker.IsValidFormat(AFormat);
end;

class function TPngEncoder.ClampLevel(ALevel: Integer): Integer;
begin
  if ALevel < DDPNG_DEFAULT_LEVEL then
    Result := DDPNG_DEFAULT_LEVEL
  else if ALevel > DDPNG_MAX_LEVEL then
    Result := DDPNG_MAX_LEVEL
  else
    Result := ALevel;
end;

class procedure TPngEncoder.RaiseForZlib(ACode: Integer);
begin
  case ACode of
    ZLIB_BUF_ERROR:
      raise EPngException.CreateCode(DDPNG_ERR_BUFFER_TOO_SMALL);
    ZLIB_MEM_ERROR:
      raise EPngException.CreateCode(DDPNG_ERR_MEMORY);
  else
    raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
  end;
end;

function TPngEncoder.CreateDeflater(ALevel: Integer): IZlibDeflater;
var
  LCode: Integer;
begin
  Result := nil;
  LCode := FZlib.CreateDeflater(ALevel, Result);
  if LCode = ZLIB_MEM_ERROR then
    raise EPngException.CreateCode(DDPNG_ERR_MEMORY);
  if (LCode <> ZLIB_OK) or not Assigned(Result) then
    raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
end;

procedure TPngEncoder.Feed(const ADeflater: IZlibDeflater;
  var ABuffers: TZlibStreamBuffers; AData: PByte; ASize: Cardinal);
var
  LCode: Integer;
begin
  ABuffers.NextIn := AData;
  ABuffers.AvailIn := ASize;
  LCode := ADeflater.Deflate(ABuffers, ZLIB_NO_FLUSH);
  if LCode <> ZLIB_OK then
    RaiseForZlib(LCode);
  // The output buffer filled up before all the input was taken
  if ABuffers.AvailIn <> 0 then
    raise EPngException.CreateCode(DDPNG_ERR_BUFFER_TOO_SMALL);
end;

procedure TPngEncoder.Finish(const ADeflater: IZlibDeflater;
  var ABuffers: TZlibStreamBuffers);
var
  LCode: Integer;
  LNoInput: Byte;
begin
  ABuffers.NextIn := @LNoInput;
  ABuffers.AvailIn := 0;
  repeat
    LCode := ADeflater.Deflate(ABuffers, ZLIB_FINISH);
    if LCode = ZLIB_STREAM_END then
      Exit;
    if (LCode <> ZLIB_OK) and (LCode <> ZLIB_BUF_ERROR) then
      RaiseForZlib(LCode);
    // Not finished: either the output buffer is full or zlib wants to go on
    if ABuffers.AvailOut = 0 then
      raise EPngException.CreateCode(DDPNG_ERR_BUFFER_TOO_SMALL);
    if LCode = ZLIB_BUF_ERROR then
      raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
  until False;
end;

function TPngEncoder.Bound(AWidth, AHeight, AFormat: Integer): Cardinal;
var
  LUncompressed: Int64;
  LTotal: Int64;
begin
  Result := 0;
  if not IsValidImage(AWidth, AHeight, AFormat) then
    Exit;

  // Every scanline has a filter type byte in front
  LUncompressed := Int64(AHeight) *
    (Int64(AWidth) * TPngPixelPacker.ScanlineBytesPerPixel(AFormat) + 1);

  // Signature, IHDR, the IDAT chunk with the zlib stream, IEND
  LTotal := PNG_SIGNATURE_SIZE + (PNG_CHUNK_OVERHEAD + PNG_HEADER_SIZE) +
    PNG_CHUNK_OVERHEAD + Int64(FZlib.CompressBound(Cardinal(LUncompressed))) +
    PNG_CHUNK_OVERHEAD;
  if LTotal <= High(Cardinal) then
    Result := Cardinal(LTotal);
end;

procedure TPngEncoder.Encode(APixels: Pointer; AWidth, AHeight, AFormat,
  AStride, ALevel: Integer; ADest: Pointer; var ADestSize: Cardinal);
var
  LWriter: TPngChunkWriter;
  LHeaderData: array[0..PNG_HEADER_SIZE - 1] of Byte;
  LDeflater: IZlibDeflater;
  LBuffers: TZlibStreamBuffers;
  LData: PByte;
  LAvailable: Cardinal;
  LLevel: Integer;
  LSourceRowBytes: Integer;
  LRowBytes: Integer;
  LPixelBytes: Integer;
  LFilterCount: Integer;
  LFilter: Integer;
  LBestFilter: Integer;
  LScore: Cardinal;
  LBestScore: Cardinal;
  LRow: Integer;
  LSource: PByte;
  LCurrent: TBytes;
  LPrevious: TBytes;
  LBest: TBytes;
  LTrial: TBytes;
  LSwap: TBytes;
begin
  if (APixels = nil) or (ADest = nil) or
     not IsValidImage(AWidth, AHeight, AFormat) then
    raise EPngException.CreateCode(DDPNG_ERR_INVALID_ARGUMENT);

  LSourceRowBytes := AWidth * TPngPixelPacker.SourceBytesPerPixel(AFormat);
  if AStride = 0 then
    AStride := LSourceRowBytes;
  if Abs(AStride) < LSourceRowBytes then
    raise EPngException.CreateCode(DDPNG_ERR_INVALID_ARGUMENT);

  LLevel := ClampLevel(ALevel);
  LPixelBytes := TPngPixelPacker.ScanlineBytesPerPixel(AFormat);
  LRowBytes := AWidth * LPixelBytes;

  // Level 0 stores the data: trying five filters would be a waste
  if LLevel = 0 then
    LFilterCount := 1
  else
    LFilterCount := PNG_FILTER_COUNT;

  SetLength(LCurrent, LRowBytes);
  SetLength(LPrevious, LRowBytes);
  FillChar(PByte(LPrevious)^, LRowBytes, 0);
  SetLength(LBest, LRowBytes + 1);
  SetLength(LTrial, LRowBytes + 1);

  LWriter := TPngChunkWriter.Create(ADest, ADestSize);
  try
    LWriter.WriteSignature;

    TPngByteOrder.WriteCardinal(@LHeaderData[0], Cardinal(AWidth));
    TPngByteOrder.WriteCardinal(@LHeaderData[4], Cardinal(AHeight));
    LHeaderData[8] := PNG_SAMPLE_DEPTH;
    LHeaderData[9] := Byte(TPngPixelPacker.ColorTypeOf(AFormat));
    LHeaderData[10] := 0;  // compression method
    LHeaderData[11] := 0;  // filter method
    LHeaderData[12] := 0;  // no interlace
    LWriter.WriteChunk(PNG_CHUNK_IHDR, @LHeaderData[0], PNG_HEADER_SIZE);

    // The zlib stream goes straight into the IDAT chunk; the IEND chunk
    // that follows keeps its room
    LAvailable := LWriter.OpenChunk(PNG_CHUNK_IDAT, PNG_CHUNK_OVERHEAD, LData);
    // zlib counts the room in a signed 32 bit integer
    if LAvailable > Cardinal(High(Longint)) then
      LAvailable := Cardinal(High(Longint));

    LDeflater := CreateDeflater(LLevel);
    FillChar(LBuffers, SizeOf(LBuffers), 0);
    LBuffers.NextOut := LData;
    LBuffers.AvailOut := LAvailable;

    for LRow := 0 to AHeight - 1 do
    begin
      // The stride may be negative: compute the address in 64 bits
      LSource := PByte(NativeUInt(Int64(NativeUInt(APixels)) +
        Int64(LRow) * AStride));
      TPngPixelPacker.PackRow(AFormat, LSource, AWidth, PByte(LCurrent));

      LBestFilter := PNG_FILTER_NONE;
      LBestScore := High(Cardinal);
      for LFilter := 0 to LFilterCount - 1 do
      begin
        TPngFilter.Apply(LFilter, PByte(LCurrent), PByte(LPrevious),
          PByte(LTrial) + 1, LRowBytes, LPixelBytes);
        LScore := TPngFilter.Score(PByte(LTrial) + 1, LRowBytes);
        if LScore < LBestScore then
        begin
          LBestScore := LScore;
          LBestFilter := LFilter;
          LSwap := LBest;
          LBest := LTrial;
          LTrial := LSwap;
        end;
      end;
      LBest[0] := Byte(LBestFilter);

      Feed(LDeflater, LBuffers, PByte(LBest), Cardinal(LRowBytes + 1));

      LSwap := LPrevious;
      LPrevious := LCurrent;
      LCurrent := LSwap;
    end;

    Finish(LDeflater, LBuffers);
    LWriter.CloseChunk(LAvailable - LBuffers.AvailOut);
    LWriter.WriteChunk(PNG_CHUNK_IEND, nil, 0);

    ADestSize := LWriter.Position;
  finally
    LWriter.Free;
  end;
end;

end.
