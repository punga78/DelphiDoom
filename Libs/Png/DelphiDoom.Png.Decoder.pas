{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - decoder                                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Decoder;

// The image is decompressed one scanline at a time through the incremental
// interface of IZlib, so the memory used besides the destination is two
// scanlines, whatever the size of the image. Every failure is an
// EPngException: the engine turns it into a result code.

interface

{$POINTERMATH ON}

uses
  System.SysUtils, DelphiDoom.Zlib.Intf, DelphiDoom.Png.Intf,
  DelphiDoom.Png.Metadata, DelphiDoom.Png.ChunkReader;

type
  /// <summary>
  ///   Decodes PNG files held in memory. Stateless: one instance can serve
  ///   several threads if the IZlib can
  /// </summary>
  TPngDecoder = class
  private
    type
      TTarget = (Bgra, Indices);
  private
    FZlib: IZlib;

    procedure ReadBeforeImage(AReader: TPngChunkReader;
      AMetadata: TPngMetadata; out AFirstImageChunk: TPngChunk);
    procedure ReadAfterImage(AReader: TPngChunkReader; AMetadata: TPngMetadata);
    function CreateInflater: IZlibInflater;
    procedure Decode(ASource: Pointer; ASourceSize: Cardinal; ATarget: TTarget;
      ADest: Pointer; ADestSize: Cardinal; APalette: Pointer);
  public
    constructor Create(const AZlib: IZlib);

    /// <summary>
    ///   Header and ancillary chunks of a file. Only the signature and the
    ///   header must be valid
    /// </summary>
    function ReadInfo(ASource: Pointer; ASourceSize: Cardinal): TPngInfo;

    /// <summary>
    ///   Decodes to Width * Height BGRA pixels. Raises
    ///   DDPNG_ERR_BUFFER_TOO_SMALL if ADest is smaller than that
    /// </summary>
    procedure DecodeBgra(ASource: Pointer; ASourceSize: Cardinal;
      ADest: Pointer; ADestSize: Cardinal);

    /// <summary>
    ///   Decodes a palette image to Width * Height indices; APalette receives
    ///   DDPNG_PALETTE_BYTES bytes
    /// </summary>
    procedure DecodeIndexed(ASource: Pointer; ASourceSize: Cardinal;
      APixels: Pointer; APixelsSize: Cardinal; APalette: Pointer);
  end;

implementation

uses
  DelphiDoom.Png.Header, DelphiDoom.Png.Adam7, DelphiDoom.Png.Unfilter,
  DelphiDoom.Png.PixelConverter, DelphiDoom.Png.IdatStream;

{ TPngDecoder }

constructor TPngDecoder.Create(const AZlib: IZlib);
begin
  inherited Create;
  if not Assigned(AZlib) then
    raise EArgumentNilException.Create('AZlib');
  FZlib := AZlib;
end;

procedure TPngDecoder.ReadBeforeImage(AReader: TPngChunkReader;
  AMetadata: TPngMetadata; out AFirstImageChunk: TPngChunk);
var
  LChunk: TPngChunk;
begin
  AReader.ReadSignature;
  AMetadata.AcceptHeader(AReader.Next(True));

  repeat
    LChunk := AReader.Next(True);
    case LChunk.ChunkType of
      PNG_CHUNK_IDAT:
        begin
          AFirstImageChunk := LChunk;
          Exit;
        end;
      PNG_CHUNK_IEND:
        // The end of the file with no image data
        raise EPngException.CreateCode(DDPNG_ERR_DATA);
      PNG_CHUNK_IHDR:
        raise EPngException.CreateCode(DDPNG_ERR_DATA);
    else
      AMetadata.Accept(LChunk, True);
    end;
  until False;
end;

procedure TPngDecoder.ReadAfterImage(AReader: TPngChunkReader;
  AMetadata: TPngMetadata);
var
  LChunk: TPngChunk;
begin
  // The file must end with IEND: a file that stops before it is truncated
  repeat
    LChunk := AReader.Next(True);
    case LChunk.ChunkType of
      PNG_CHUNK_IEND:
        Exit;
      PNG_CHUNK_IHDR:
        raise EPngException.CreateCode(DDPNG_ERR_DATA);
      PNG_CHUNK_IDAT:
        ;
    else
      AMetadata.Accept(LChunk, False);
    end;
  until False;
end;

function TPngDecoder.CreateInflater: IZlibInflater;
var
  LCode: Integer;
begin
  Result := nil;
  LCode := FZlib.CreateInflater(TZlibFormat.Zlib, Result);
  if LCode = ZLIB_MEM_ERROR then
    raise EPngException.CreateCode(DDPNG_ERR_MEMORY);
  if (LCode <> ZLIB_OK) or not Assigned(Result) then
    raise EPngException.CreateCode(DDPNG_ERR_INTERNAL);
end;

function TPngDecoder.ReadInfo(ASource: Pointer; ASourceSize: Cardinal): TPngInfo;
var
  LReader: TPngChunkReader;
  LMetadata: TPngMetadata;
  LChunk: TPngChunk;
begin
  LReader := TPngChunkReader.Create(ASource, ASourceSize);
  LMetadata := TPngMetadata.Create;
  try
    LReader.ReadSignature;
    LMetadata.AcceptHeader(LReader.Next(True));

    // From here the header is known to be good: whatever is wrong later in
    // the file is for Decode to report, so the chunks are read as far as
    // they go and the walk stops at the first problem
    try
      while not LReader.AtEnd do
      begin
        LChunk := LReader.Next(False);
        case LChunk.ChunkType of
          PNG_CHUNK_IEND:
            Break;
          PNG_CHUNK_IDAT, PNG_CHUNK_IHDR:
            ;
        else
          LMetadata.Accept(LChunk, True);
        end;
      end;
    except
      on EPngException do
        ;
    end;

    Result := LMetadata.BuildInfo;
  finally
    LMetadata.Free;
    LReader.Free;
  end;
end;

procedure TPngDecoder.Decode(ASource: Pointer; ASourceSize: Cardinal;
  ATarget: TTarget; ADest: Pointer; ADestSize: Cardinal; APalette: Pointer);
var
  LReader: TPngChunkReader;
  LMetadata: TPngMetadata;
  LConverter: TPngPixelConverter;
  LStream: TPngIdatStream;
  LFirstImageChunk: TPngChunk;
  LHeader: TPngHeader;
  LPass: TPngPass;
  LPassIndex: Integer;
  LRow: Integer;
  LY: Integer;
  LRowBytes: Integer;
  LStride: Integer;
  LOutputBytes: Integer;
  LRequired: Int64;
  LLine: TBytes;
  LPrevious: TBytes;
  LSwap: TBytes;
  LRowDest: PByte;
begin
  LReader := TPngChunkReader.Create(ASource, ASourceSize);
  LMetadata := TPngMetadata.Create;
  LConverter := nil;
  LStream := nil;
  try
    ReadBeforeImage(LReader, LMetadata, LFirstImageChunk);
    LMetadata.Resolve;
    LHeader := LMetadata.Header;

    if ATarget = TTarget.Indices then
    begin
      if LHeader.ColorType <> DDPNG_COLOR_PALETTE then
        raise EPngException.CreateCode(DDPNG_ERR_UNSUPPORTED);
      LOutputBytes := 1;
    end
    else
      LOutputBytes := 4;

    LRequired := Int64(LHeader.Width) * LHeader.Height * LOutputBytes;
    if Int64(ADestSize) < LRequired then
      raise EPngException.CreateCode(DDPNG_ERR_BUFFER_TOO_SMALL);

    LConverter := TPngPixelConverter.Create(LMetadata);
    LStream := TPngIdatStream.Create(LReader, CreateInflater, LFirstImageChunk);

    // Two scanlines, each with its filter type byte in front. The widest
    // scanline of an interlaced image is the one of the last pass
    LStride := LHeader.FilterStride;
    SetLength(LLine, LHeader.RowBytes(LHeader.Width) + 1);
    SetLength(LPrevious, Length(LLine));

    for LPassIndex := 0 to TPngAdam7.PassCount(LHeader.Interlaced) - 1 do
    begin
      LPass := TPngAdam7.GetPass(LHeader.Interlaced, LPassIndex, LHeader.Width,
        LHeader.Height);
      // A pass with no pixels has no scanlines in the stream
      if (LPass.Width = 0) or (LPass.Height = 0) then
        Continue;

      LRowBytes := LHeader.RowBytes(LPass.Width);
      // The first row of a pass has nothing above it
      FillChar(PByte(LPrevious)^, LRowBytes + 1, 0);

      for LRow := 0 to LPass.Height - 1 do
      begin
        LStream.Read(PByte(LLine), Cardinal(LRowBytes + 1));
        TPngUnfilter.Apply(LLine[0], PByte(LLine) + 1, PByte(LPrevious) + 1,
          LRowBytes, LStride);

        LY := LPass.RowStart + LRow * LPass.RowStep;
        LRowDest := PByte(ADest) +
          (LY * LHeader.Width + LPass.ColumnStart) * LOutputBytes;
        if ATarget = TTarget.Indices then
          LConverter.ToIndices(PByte(LLine) + 1, LPass.Width, LRowDest,
            LPass.ColumnStep)
        else
          LConverter.ToBgra(PByte(LLine) + 1, LPass.Width, LRowDest,
            LPass.ColumnStep * LOutputBytes);

        // The row just reconstructed is the one above the next
        LSwap := LPrevious;
        LPrevious := LLine;
        LLine := LSwap;
      end;
    end;

    LStream.Finish;
    ReadAfterImage(LReader, LMetadata);

    if ATarget = TTarget.Indices then
      LMetadata.CopyPaletteTo(APalette);
  finally
    LStream.Free;
    LConverter.Free;
    LMetadata.Free;
    LReader.Free;
  end;
end;

procedure TPngDecoder.DecodeBgra(ASource: Pointer; ASourceSize: Cardinal;
  ADest: Pointer; ADestSize: Cardinal);
begin
  Decode(ASource, ASourceSize, TTarget.Bgra, ADest, ADestSize, nil);
end;

procedure TPngDecoder.DecodeIndexed(ASource: Pointer; ASourceSize: Cardinal;
  APixels: Pointer; APixelsSize: Cardinal; APalette: Pointer);
begin
  Decode(ASource, ASourceSize, TTarget.Indices, APixels, APixelsSize, APalette);
end;

end.
