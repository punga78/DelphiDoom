{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - constants and types of the decoder                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Types;

interface

uses
  System.SysUtils;

const
  // The block of the DCT is 8x8 samples
  JPEG_DCT_SIZE = 8;
  JPEG_DCT_SIZE2 = 64;

  // Limits of the format and of the decoder
  JPEG_MAX_COMPONENTS = 10;
  JPEG_MAX_COMPONENTS_IN_SCAN = 4;
  JPEG_MAX_BLOCKS_IN_MCU = 10;
  JPEG_MAX_SAMPLING_FACTOR = 4;
  JPEG_QUANTIZATION_TABLES = 4;
  JPEG_HUFFMAN_TABLES = 4;

  // A tad under 64K, to keep the sizes away from overflows
  JPEG_MAX_IMAGE_DIMENSION = 65500;

  // The only precision of the samples that is decoded
  JPEG_SAMPLE_PRECISION = 8;

  // Where the coefficient number k (in zigzag order) goes in a block. The
  // extra entries are for the streams that run past the end of a block: they
  // all point to the last coefficient
  JPEG_NATURAL_ORDER: array[0..JPEG_DCT_SIZE2 + 15] of Integer = (
    0, 1, 8, 16, 9, 2, 3, 10,
    17, 24, 32, 25, 18, 11, 4, 5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6, 7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63,
    63, 63, 63, 63, 63, 63, 63, 63,
    63, 63, 63, 63, 63, 63, 63, 63
  );

type
  /// <summary>
  ///   The 64 coefficients of a block of the DCT, in natural order
  /// </summary>
  TJpegBlock = array[0..JPEG_DCT_SIZE2 - 1] of Integer;
  PJpegBlock = ^TJpegBlock;

  /// <summary>
  ///   A quantization table of a stream, in natural order
  /// </summary>
  TJpegQuantizationTable = record
    Defined: Boolean;
    Values: array[0..JPEG_DCT_SIZE2 - 1] of Word;
  end;

  /// <summary>
  ///   A Huffman table as a marker defines it: how many codes there are of
  ///   each length (Bits[1]..Bits[16]) and the symbols in order of length
  /// </summary>
  TJpegHuffmanDefinition = record
    Defined: Boolean;
    Bits: array[0..16] of Byte;
    Values: array[0..255] of Byte;
  end;

  /// <summary>
  ///   A component of the frame, with what the decoder computes about it
  /// </summary>
  TJpegComponentInfo = record
    Id: Integer;
    Index: Integer;
    Horizontal: Integer;
    Vertical: Integer;
    QuantizationNumber: Integer;
    // The tables of the scan that is being read
    DcTableNumber: Integer;
    AcTableNumber: Integer;
    // Size in blocks (the blocks that complete a MCU do not count) and in
    // samples
    WidthInBlocks: Integer;
    HeightInBlocks: Integer;
    DownsampledWidth: Integer;
    DownsampledHeight: Integer;
    // The shape of its part of a MCU in the scan that is being read
    McuWidth: Integer;
    McuHeight: Integer;
    McuBlocks: Integer;
    LastColumnWidth: Integer;
    LastRowHeight: Integer;
    // The quantization table as it was when the first scan of the component
    // started: a later table with the same number does not change it
    HasQuantization: Boolean;
    Quantization: array[0..JPEG_DCT_SIZE2 - 1] of Integer;
  end;
  PJpegComponentInfo = ^TJpegComponentInfo;

  /// <summary>
  ///   The scan that is being read: its components (as indexes in the frame),
  ///   the progressive parameters and the shape of its MCUs
  /// </summary>
  TJpegScanInfo = record
    ComponentCount: Integer;
    Components: array[0..JPEG_MAX_COMPONENTS_IN_SCAN - 1] of Integer;
    SpectralStart: Integer;
    SpectralEnd: Integer;
    ApproximationHigh: Integer;
    ApproximationLow: Integer;
    McusPerRow: Integer;
    McuRowsInScan: Integer;
    BlocksInMcu: Integer;
    // The component (as a position in Components) that owns each block of a MCU
    McuMembership: array[0..JPEG_MAX_BLOCKS_IN_MCU - 1] of Integer;
  end;

  PJpegScanInfo = ^TJpegScanInfo;
  PJpegHuffmanDefinition = ^TJpegHuffmanDefinition;
  PJpegQuantizationTable = ^TJpegQuantizationTable;

  /// <summary>
  ///   The color spaces that a stream can be in
  /// </summary>
  TJpegColorSpace = (jcsUnknown, jcsGrayscale, jcsRgb, jcsYCbCr, jcsCmyk,
    jcsYcck);

  /// <summary>
  ///   The things that can be wrong in a stream or that the decoder cannot do
  /// </summary>
  TJpegDecodeError = (
    jdeNotJpeg,
    jdeDuplicateStartOfImage,
    jdeDuplicateFrame,
    jdeScanBeforeFrame,
    jdeFrameWithoutScan,
    jdeNoImage,
    jdeEmptyImage,
    jdeBadLength,
    jdeBadComponentId,
    jdeBadHuffmanTableIndex,
    jdeBadQuantizationTableIndex,
    jdeBadHuffmanTable,
    jdeUnknownMarker,
    jdeUnsupportedFrame,
    jdeImageTooBig,
    jdeBadPrecision,
    jdeBadComponentCount,
    jdeBadSampling,
    jdeBadMcuSize,
    jdeMissingQuantizationTable,
    jdeMissingHuffmanTable,
    jdeBadProgression,
    jdeArithmeticCoding,
    jdeColorConversion,
    jdeFractionalSampling,
    jdeTruncated
  );

  /// <summary>
  ///   Raised by the decoder for a stream that it cannot decode; it never
  ///   leaves the unit that calls the decoder (TJpegDecoder)
  /// </summary>
  EJpegDecodeException = class(Exception)
  private
    FError: TJpegDecodeError;
  public
    constructor Create(AError: TJpegDecodeError);

    /// <summary>
    ///   The DDJPEG_ERR_ code that stands for an error of the decoder
    /// </summary>
    class function ResultCodeOf(AError: TJpegDecodeError): Integer; static;

    /// <summary>
    ///   Raises the exception of the error
    /// </summary>
    class procedure Fail(AError: TJpegDecodeError); static;

    property Error: TJpegDecodeError read FError;
  end;

implementation

uses
  DelphiDoom.Jpeg.Intf;

const
  ERROR_TEXTS: array[TJpegDecodeError] of string = (
    'Not a JPEG file: it does not start with the marker of the start of image',
    'Two markers of start of image',
    'Two frame headers',
    'A scan comes before the frame header',
    'The frame header is not followed by a scan',
    'The stream has no image',
    'The image is empty',
    'A marker segment has a wrong length',
    'A scan has a component that the frame does not have',
    'Wrong index of a Huffman table',
    'Wrong index of a quantization table',
    'A Huffman table is not valid',
    'Unknown marker',
    'This kind of JPEG is not supported (lossless, hierarchical, arithmetic)',
    'The image is too big',
    'The precision of the samples is not 8 bits',
    'Too many components',
    'Wrong sampling factors',
    'Too many blocks in a MCU',
    'A component has no quantization table',
    'A component has no Huffman table',
    'Wrong parameters of a progressive scan',
    'Arithmetic coding is not supported',
    'The color space cannot be converted',
    'The sampling factors are not a whole multiple of each other',
    'The stream ends before the image is complete'
  );

{ EJpegDecodeException }

constructor EJpegDecodeException.Create(AError: TJpegDecodeError);
begin
  inherited Create(ERROR_TEXTS[AError]);
  FError := AError;
end;

class function EJpegDecodeException.ResultCodeOf(AError: TJpegDecodeError): Integer;
begin
  case AError of
    jdeTruncated:
      Result := DDJPEG_ERR_TRUNCATED;
    jdeUnsupportedFrame, jdeImageTooBig, jdeBadPrecision, jdeBadProgression,
    jdeArithmeticCoding, jdeColorConversion:
      Result := DDJPEG_ERR_UNSUPPORTED;
  else
    Result := DDJPEG_ERR_DATA;
  end;
end;

class procedure EJpegDecodeException.Fail(AError: TJpegDecodeError);
begin
  raise EJpegDecodeException.Create(AError);
end;

end.
