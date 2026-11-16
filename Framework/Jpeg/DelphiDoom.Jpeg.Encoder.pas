{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - baseline encoder                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Encoder;

// The decoder of the library is a port of the decompressor of libjpeg 6b (see
// TJpegDecompressor); there is no compressor, so this unit writes the other
// direction, which the engine does not use: a JFIF baseline
// stream with the standard Huffman tables of the JPEG specification (annex K)
// and the quantization tables scaled by quality as libjpeg does. Colors are
// converted to YCbCr and are not subsampled (4:4:4), which keeps the pixels
// close to the original at the cost of a larger stream than libjpeg's 4:2:0.

interface

uses
  DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   The 64 samples of one component of an 8x8 block, in natural order
  /// </summary>
  TJpegSampleBlock = array[0..63] of Double;

  /// <summary>
  ///   The 8x8 samples of every component of one block
  /// </summary>
  TJpegBlockSamples = array[0..2] of TJpegSampleBlock;

  /// <summary>
  ///   The quantized coefficients of an 8x8 block, in natural order
  /// </summary>
  TJpegQuantizedBlock = array[0..63] of Integer;

  /// <summary>
  ///   Huffman code and length of every symbol that can be written
  /// </summary>
  TJpegHuffmanTable = record
    Codes: array[0..255] of Integer;
    Sizes: array[0..255] of Integer;
  end;

  /// <summary>
  ///   Encodes one image. Create it, call Encode once, free it
  /// </summary>
  TJpegEncoder = class
  private
    FPixels: Pointer;
    FWidth: Integer;
    FHeight: Integer;
    FComponents: Integer;
    FQuantization: array[0..1, 0..63] of Integer;
    FDcTables: array[0..1] of TJpegHuffmanTable;
    FAcTables: array[0..1] of TJpegHuffmanTable;
    FBasis: array[0..7, 0..7] of Double;
    FDest: Pointer;
    FCapacity: Cardinal;
    FWritten: Cardinal;
    FOverflow: Boolean;
    FBitBuffer: Integer;
    FBitCount: Integer;
    FLastDc: array[0..2] of Integer;

    procedure PrepareQuantization(AQuality: Integer);
    procedure PrepareBasis;
    procedure BuildHuffmanTable(const ABits, AValues: array of Byte;
      var ATable: TJpegHuffmanTable);

    function PixelAt(AOffset: NativeInt): Integer;
    class function TableOfComponent(AComponent: Integer): Integer; static;
    class function CategoryOf(AValue: Integer): Integer; static;

    procedure WriteByte(AValue: Integer);
    procedure WriteWord(AValue: Integer);
    procedure WriteMarker(AMarker: Integer);
    procedure WriteBits(ACode, ASize: Integer);
    procedure WriteMagnitude(AValue, ACategory: Integer);
    procedure FlushBits;

    procedure WriteHuffmanTable(AClass, AIdentifier: Integer;
      const ABits, AValues: array of Byte);
    procedure WriteHeaders;
    procedure LoadBlock(AX, AY: Integer; var ASamples: TJpegBlockSamples);
    procedure TransformBlock(const ASamples: TJpegSampleBlock; ATable: Integer;
      var AQuantized: TJpegQuantizedBlock);
    procedure EncodeBlock(AComponent: Integer;
      const AQuantized: TJpegQuantizedBlock);
    procedure EncodeScan;
  public
    /// <summary>
    ///   APixels holds AWidth * AHeight * AComponents bytes laid out as
    ///   described in TJpegInfo. The arguments must pass IsValidFormat
    /// </summary>
    constructor Create(APixels: Pointer; AWidth, AHeight, AComponents,
      AQuality: Integer);

    /// <summary>
    ///   Writes the stream into ADest. ADestSize is the size of ADest on input
    ///   and the size of the stream on output
    /// </summary>
    /// <returns>
    ///   DDJPEG_OK or DDJPEG_ERR_BUFFER_TOO_SMALL (ADestSize is not changed)
    /// </returns>
    function Encode(ADest: Pointer; var ADestSize: Cardinal): Integer;

    /// <summary>
    ///   True if the size and the number of components can be encoded
    /// </summary>
    class function IsValidFormat(AWidth, AHeight,
      AComponents: Integer): Boolean; static;

    /// <summary>
    ///   Upper bound of the size of the stream; 0 if the format is not valid
    ///   or the bound does not fit in 32 bits
    /// </summary>
    class function Bound(AWidth, AHeight, AComponents: Integer): Cardinal; static;
  end;

implementation

uses
  System.SysUtils;

const
  // Worst case of the stream apart from the entropy coded data: SOI, JFIF,
  // two quantization tables, frame header, four Huffman tables, scan header,
  // EOI
  HEADER_BOUND = 1024;

  // Worst case of one block of one component: 20 bits for the DC, 63 AC
  // coefficients of up to 26 bits (16 of code and 10 of magnitude), doubled
  // for the zero byte that follows every $FF
  BLOCK_BOUND = 416;

  ZIGZAG: array[0..63] of Byte = (
    0, 1, 8, 16, 9, 2, 3, 10,
    17, 24, 32, 25, 18, 11, 4, 5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6, 7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63
  );

  // Quantization tables of the specification (annex K) at quality 50
  LUMINANCE_QUANTIZATION: array[0..63] of Byte = (
    16, 11, 10, 16, 24, 40, 51, 61,
    12, 12, 14, 19, 26, 58, 60, 55,
    14, 13, 16, 24, 40, 57, 69, 56,
    14, 17, 22, 29, 51, 87, 80, 62,
    18, 22, 37, 56, 68, 109, 103, 77,
    24, 35, 55, 64, 81, 104, 113, 92,
    49, 64, 78, 87, 103, 121, 120, 101,
    72, 92, 95, 98, 112, 100, 103, 99
  );

  CHROMINANCE_QUANTIZATION: array[0..63] of Byte = (
    17, 18, 24, 47, 99, 99, 99, 99,
    18, 21, 26, 66, 99, 99, 99, 99,
    24, 26, 56, 99, 99, 99, 99, 99,
    47, 66, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99
  );

  // Standard Huffman tables (annex K): number of codes of each length from 1
  // to 16 bits, then the symbols in order of increasing code length
  DC_LUMINANCE_BITS: array[0..15] of Byte = (
    0, 1, 5, 1, 1, 1, 1, 1,
    1, 0, 0, 0, 0, 0, 0, 0
  );

  DC_CHROMINANCE_BITS: array[0..15] of Byte = (
    0, 3, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 0, 0, 0, 0, 0
  );

  DC_VALUES: array[0..11] of Byte = (
    0, 1, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11
  );

  AC_LUMINANCE_BITS: array[0..15] of Byte = (
    0, 2, 1, 3, 3, 2, 4, 3,
    5, 5, 4, 4, 0, 0, 1, 125
  );

  AC_LUMINANCE_VALUES: array[0..161] of Byte = (
    $01, $02, $03, $00, $04, $11, $05, $12, $21, $31, $41, $06, $13, $51, $61, $07,
    $22, $71, $14, $32, $81, $91, $A1, $08, $23, $42, $B1, $C1, $15, $52, $D1, $F0,
    $24, $33, $62, $72, $82, $09, $0A, $16, $17, $18, $19, $1A, $25, $26, $27, $28,
    $29, $2A, $34, $35, $36, $37, $38, $39, $3A, $43, $44, $45, $46, $47, $48, $49,
    $4A, $53, $54, $55, $56, $57, $58, $59, $5A, $63, $64, $65, $66, $67, $68, $69,
    $6A, $73, $74, $75, $76, $77, $78, $79, $7A, $83, $84, $85, $86, $87, $88, $89,
    $8A, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $A2, $A3, $A4, $A5, $A6, $A7,
    $A8, $A9, $AA, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $C2, $C3, $C4, $C5,
    $C6, $C7, $C8, $C9, $CA, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $E1, $E2,
    $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8,
    $F9, $FA
  );

  AC_CHROMINANCE_BITS: array[0..15] of Byte = (
    0, 2, 1, 2, 4, 4, 3, 4,
    7, 5, 4, 4, 0, 1, 2, 119
  );

  AC_CHROMINANCE_VALUES: array[0..161] of Byte = (
    $00, $01, $02, $03, $11, $04, $05, $21, $31, $06, $12, $41, $51, $07, $61, $71,
    $13, $22, $32, $81, $08, $14, $42, $91, $A1, $B1, $C1, $09, $23, $33, $52, $F0,
    $15, $62, $72, $D1, $0A, $16, $24, $34, $E1, $25, $F1, $17, $18, $19, $1A, $26,
    $27, $28, $29, $2A, $35, $36, $37, $38, $39, $3A, $43, $44, $45, $46, $47, $48,
    $49, $4A, $53, $54, $55, $56, $57, $58, $59, $5A, $63, $64, $65, $66, $67, $68,
    $69, $6A, $73, $74, $75, $76, $77, $78, $79, $7A, $82, $83, $84, $85, $86, $87,
    $88, $89, $8A, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $A2, $A3, $A4, $A5,
    $A6, $A7, $A8, $A9, $AA, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $C2, $C3,
    $C4, $C5, $C6, $C7, $C8, $C9, $CA, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA,
    $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $F2, $F3, $F4, $F5, $F6, $F7, $F8,
    $F9, $FA
  );

  // Symbols of the AC tables with a special meaning
  SYMBOL_END_OF_BLOCK = $00;
  SYMBOL_ZERO_RUN_16 = $F0;

  // Marker codes (they follow a $FF byte)
  MARKER_SOI = $D8;
  MARKER_EOI = $D9;
  MARKER_APP0 = $E0;
  MARKER_DQT = $DB;
  MARKER_SOF0 = $C0;
  MARKER_DHT = $C4;
  MARKER_SOS = $DA;

{ TJpegEncoder }

constructor TJpegEncoder.Create(APixels: Pointer; AWidth, AHeight, AComponents,
  AQuality: Integer);
begin
  inherited Create;
  if not Assigned(APixels) then
    raise EArgumentNilException.Create('APixels');
  if not IsValidFormat(AWidth, AHeight, AComponents) then
    raise EArgumentOutOfRangeException.Create('The image format is not valid');

  FPixels := APixels;
  FWidth := AWidth;
  FHeight := AHeight;
  FComponents := AComponents;

  PrepareQuantization(AQuality);
  PrepareBasis;
  BuildHuffmanTable(DC_LUMINANCE_BITS, DC_VALUES, FDcTables[0]);
  BuildHuffmanTable(DC_CHROMINANCE_BITS, DC_VALUES, FDcTables[1]);
  BuildHuffmanTable(AC_LUMINANCE_BITS, AC_LUMINANCE_VALUES, FAcTables[0]);
  BuildHuffmanTable(AC_CHROMINANCE_BITS, AC_CHROMINANCE_VALUES, FAcTables[1]);
end;

class function TJpegEncoder.IsValidFormat(AWidth, AHeight,
  AComponents: Integer): Boolean;
begin
  Result := (AWidth >= 1) and (AWidth <= DDJPEG_MAX_DIMENSION) and
    (AHeight >= 1) and (AHeight <= DDJPEG_MAX_DIMENSION) and
    ((AComponents = 1) or (AComponents = 3));
end;

class function TJpegEncoder.Bound(AWidth, AHeight, AComponents: Integer): Cardinal;
var
  LBlocks: Int64;
  LTotal: Int64;
begin
  Result := 0;
  if not IsValidFormat(AWidth, AHeight, AComponents) then
    Exit;

  LBlocks := Int64((AWidth + 7) div 8) * Int64((AHeight + 7) div 8);
  LTotal := HEADER_BOUND + LBlocks * AComponents * BLOCK_BOUND;
  if LTotal <= Int64(High(Cardinal)) then
    Result := Cardinal(LTotal);
end;

class function TJpegEncoder.TableOfComponent(AComponent: Integer): Integer;
begin
  // Luminance tables for the first component, chrominance for the others
  if AComponent = 0 then
    Result := 0
  else
    Result := 1;
end;

class function TJpegEncoder.CategoryOf(AValue: Integer): Integer;
var
  LMagnitude: Integer;
begin
  // Number of bits needed by the absolute value
  LMagnitude := Abs(AValue);
  Result := 0;
  while LMagnitude <> 0 do
  begin
    Inc(Result);
    LMagnitude := LMagnitude shr 1;
  end;
end;

procedure TJpegEncoder.PrepareQuantization(AQuality: Integer);
var
  LScale: Integer;
  LIndex: Integer;

  function Scaled(ABase: Integer): Integer;
  begin
    Result := (ABase * LScale + 50) div 100;
    if Result < 1 then
      Result := 1
    else if Result > 255 then
      Result := 255;
  end;

begin
  if AQuality < DDJPEG_MIN_QUALITY then
    AQuality := DDJPEG_MIN_QUALITY
  else if AQuality > DDJPEG_MAX_QUALITY then
    AQuality := DDJPEG_MAX_QUALITY;

  // Same scaling as jpeg_quality_scaling of libjpeg
  if AQuality < 50 then
    LScale := 5000 div AQuality
  else
    LScale := 200 - AQuality * 2;

  for LIndex := 0 to 63 do
  begin
    FQuantization[0, LIndex] := Scaled(LUMINANCE_QUANTIZATION[LIndex]);
    FQuantization[1, LIndex] := Scaled(CHROMINANCE_QUANTIZATION[LIndex]);
  end;
end;

procedure TJpegEncoder.PrepareBasis;
var
  LFrequency: Integer;
  LPosition: Integer;
  LScale: Double;
begin
  // FBasis[u, x] = C(u) / 2 * cos((2x + 1) u pi / 16), with C(0) = 1 / sqrt(2)
  for LFrequency := 0 to 7 do
  begin
    if LFrequency = 0 then
      LScale := Sqrt(0.5)
    else
      LScale := 1.0;
    for LPosition := 0 to 7 do
      FBasis[LFrequency, LPosition] := LScale / 2 *
        Cos((2 * LPosition + 1) * LFrequency * Pi / 16);
  end;
end;

procedure TJpegEncoder.BuildHuffmanTable(const ABits, AValues: array of Byte;
  var ATable: TJpegHuffmanTable);
var
  LLength: Integer;
  LCount: Integer;
  LCode: Integer;
  LValueIndex: Integer;
begin
  FillChar(ATable, SizeOf(ATable), 0);

  // Canonical codes of annex C: consecutive within a length, doubled when the
  // length grows
  LCode := 0;
  LValueIndex := 0;
  for LLength := 1 to 16 do
  begin
    for LCount := 1 to ABits[LLength - 1] do
    begin
      ATable.Codes[AValues[LValueIndex]] := LCode;
      ATable.Sizes[AValues[LValueIndex]] := LLength;
      Inc(LValueIndex);
      Inc(LCode);
    end;
    LCode := LCode shl 1;
  end;
end;

function TJpegEncoder.PixelAt(AOffset: NativeInt): Integer;
begin
  Result := PByte(NativeUInt(FPixels) + NativeUInt(AOffset))^;
end;

procedure TJpegEncoder.WriteByte(AValue: Integer);
begin
  // Past the end of the buffer nothing is written: the caller is told at the
  // end of the encoding
  if FWritten < FCapacity then
  begin
    PByte(NativeUInt(FDest) + NativeUInt(FWritten))^ := Byte(AValue and $FF);
    Inc(FWritten);
  end
  else
    FOverflow := True;
end;

procedure TJpegEncoder.WriteWord(AValue: Integer);
begin
  WriteByte(AValue shr 8);
  WriteByte(AValue and $FF);
end;

procedure TJpegEncoder.WriteMarker(AMarker: Integer);
begin
  WriteByte($FF);
  WriteByte(AMarker);
end;

procedure TJpegEncoder.WriteBits(ACode, ASize: Integer);
var
  LByte: Integer;
begin
  if ASize = 0 then
    Exit;

  FBitBuffer := (FBitBuffer shl ASize) or (ACode and ((1 shl ASize) - 1));
  Inc(FBitCount, ASize);
  while FBitCount >= 8 do
  begin
    LByte := (FBitBuffer shr (FBitCount - 8)) and $FF;
    WriteByte(LByte);
    // A $FF inside the entropy coded data is followed by a zero byte so that
    // it is not taken for a marker
    if LByte = $FF then
      WriteByte(0);
    Dec(FBitCount, 8);
  end;
  FBitBuffer := FBitBuffer and ((1 shl FBitCount) - 1);
end;

procedure TJpegEncoder.WriteMagnitude(AValue, ACategory: Integer);
begin
  if ACategory = 0 then
    Exit;

  // A negative value is written as the low bits of its one's complement
  if AValue < 0 then
    WriteBits(AValue - 1, ACategory)
  else
    WriteBits(AValue, ACategory);
end;

procedure TJpegEncoder.FlushBits;
begin
  // The last byte is completed with 1 bits
  if FBitCount > 0 then
    WriteBits((1 shl (8 - FBitCount)) - 1, 8 - FBitCount);
end;

procedure TJpegEncoder.WriteHuffmanTable(AClass, AIdentifier: Integer;
  const ABits, AValues: array of Byte);
var
  LIndex: Integer;
begin
  WriteMarker(MARKER_DHT);
  WriteWord(2 + 1 + Length(ABits) + Length(AValues));
  WriteByte((AClass shl 4) or AIdentifier);
  for LIndex := 0 to High(ABits) do
    WriteByte(ABits[LIndex]);
  for LIndex := 0 to High(AValues) do
    WriteByte(AValues[LIndex]);
end;

procedure TJpegEncoder.WriteHeaders;
var
  LTables: Integer;
  LTable: Integer;
  LIndex: Integer;
  LComponent: Integer;
begin
  WriteMarker(MARKER_SOI);

  // JFIF header: version 1.1, no units, 1:1 aspect ratio, no thumbnail
  WriteMarker(MARKER_APP0);
  WriteWord(16);
  WriteByte(Ord('J'));
  WriteByte(Ord('F'));
  WriteByte(Ord('I'));
  WriteByte(Ord('F'));
  WriteByte(0);
  WriteByte(1);
  WriteByte(1);
  WriteByte(0);
  WriteWord(1);
  WriteWord(1);
  WriteByte(0);
  WriteByte(0);

  // Quantization tables in zigzag order
  if FComponents = 1 then
    LTables := 1
  else
    LTables := 2;
  WriteMarker(MARKER_DQT);
  WriteWord(2 + LTables * 65);
  for LTable := 0 to LTables - 1 do
  begin
    WriteByte(LTable);
    for LIndex := 0 to 63 do
      WriteByte(FQuantization[LTable, ZIGZAG[LIndex]]);
  end;

  // Baseline frame: 8 bit samples, no subsampling
  WriteMarker(MARKER_SOF0);
  WriteWord(8 + 3 * FComponents);
  WriteByte(8);
  WriteWord(FHeight);
  WriteWord(FWidth);
  WriteByte(FComponents);
  for LComponent := 0 to FComponents - 1 do
  begin
    WriteByte(LComponent + 1);
    WriteByte($11);
    WriteByte(TableOfComponent(LComponent));
  end;

  WriteHuffmanTable(0, 0, DC_LUMINANCE_BITS, DC_VALUES);
  WriteHuffmanTable(1, 0, AC_LUMINANCE_BITS, AC_LUMINANCE_VALUES);
  if FComponents = 3 then
  begin
    WriteHuffmanTable(0, 1, DC_CHROMINANCE_BITS, DC_VALUES);
    WriteHuffmanTable(1, 1, AC_CHROMINANCE_BITS, AC_CHROMINANCE_VALUES);
  end;

  // One interleaved scan with all the components
  WriteMarker(MARKER_SOS);
  WriteWord(6 + 2 * FComponents);
  WriteByte(FComponents);
  for LComponent := 0 to FComponents - 1 do
  begin
    WriteByte(LComponent + 1);
    // DC and AC table selectors are the same number
    WriteByte(TableOfComponent(LComponent) * $11);
  end;
  WriteByte(0);
  WriteByte(63);
  WriteByte(0);
end;

procedure TJpegEncoder.LoadBlock(AX, AY: Integer; var ASamples: TJpegBlockSamples);
var
  LRow: Integer;
  LColumn: Integer;
  LSourceX: Integer;
  LSourceY: Integer;
  LOffset: NativeInt;
  LIndex: Integer;
  LBlue: Integer;
  LGreen: Integer;
  LRed: Integer;
begin
  for LRow := 0 to 7 do
  begin
    // Blocks that stick out of the image repeat its last row and column
    LSourceY := AY + LRow;
    if LSourceY >= FHeight then
      LSourceY := FHeight - 1;

    for LColumn := 0 to 7 do
    begin
      LSourceX := AX + LColumn;
      if LSourceX >= FWidth then
        LSourceX := FWidth - 1;

      LOffset := (NativeInt(LSourceY) * FWidth + LSourceX) * FComponents;
      LIndex := LRow * 8 + LColumn;
      if FComponents = 1 then
        ASamples[0][LIndex] := PixelAt(LOffset) - 128.0
      else
      begin
        // Pixels are B, G, R. Chrominance has no level shift: its zero is the
        // 128 of the JFIF color conversion, minus the 128 of the shift
        LBlue := PixelAt(LOffset);
        LGreen := PixelAt(LOffset + 1);
        LRed := PixelAt(LOffset + 2);
        ASamples[0][LIndex] := 0.299 * LRed + 0.587 * LGreen + 0.114 * LBlue - 128.0;
        ASamples[1][LIndex] := -0.168736 * LRed - 0.331264 * LGreen + 0.5 * LBlue;
        ASamples[2][LIndex] := 0.5 * LRed - 0.418688 * LGreen - 0.081312 * LBlue;
      end;
    end;
  end;
end;

procedure TJpegEncoder.TransformBlock(const ASamples: TJpegSampleBlock;
  ATable: Integer; var AQuantized: TJpegQuantizedBlock);
var
  LTemporary: TJpegSampleBlock;
  LRow: Integer;
  LColumn: Integer;
  LStep: Integer;
  LSum: Double;
begin
  // Separable DCT: first along the rows...
  for LRow := 0 to 7 do
    for LColumn := 0 to 7 do
    begin
      LSum := 0;
      for LStep := 0 to 7 do
        LSum := LSum + ASamples[LRow * 8 + LStep] * FBasis[LColumn, LStep];
      LTemporary[LRow * 8 + LColumn] := LSum;
    end;

  // ...then along the columns, quantizing each coefficient
  for LRow := 0 to 7 do
    for LColumn := 0 to 7 do
    begin
      LSum := 0;
      for LStep := 0 to 7 do
        LSum := LSum + FBasis[LRow, LStep] * LTemporary[LStep * 8 + LColumn];
      AQuantized[LRow * 8 + LColumn] :=
        Integer(Round(LSum / FQuantization[ATable, LRow * 8 + LColumn]));
    end;
end;

procedure TJpegEncoder.EncodeBlock(AComponent: Integer;
  const AQuantized: TJpegQuantizedBlock);
var
  LTable: Integer;
  LDifference: Integer;
  LCategory: Integer;
  LRun: Integer;
  LIndex: Integer;
  LCoefficient: Integer;
  LSymbol: Integer;
begin
  LTable := TableOfComponent(AComponent);

  // DC: difference from the previous block of the same component
  LDifference := AQuantized[0] - FLastDc[AComponent];
  FLastDc[AComponent] := AQuantized[0];
  LCategory := CategoryOf(LDifference);
  WriteBits(FDcTables[LTable].Codes[LCategory], FDcTables[LTable].Sizes[LCategory]);
  WriteMagnitude(LDifference, LCategory);

  // AC: (run of zeros, size) symbol followed by the magnitude, in zigzag order
  LRun := 0;
  for LIndex := 1 to 63 do
  begin
    LCoefficient := AQuantized[ZIGZAG[LIndex]];
    if LCoefficient = 0 then
      Inc(LRun)
    else
    begin
      while LRun > 15 do
      begin
        WriteBits(FAcTables[LTable].Codes[SYMBOL_ZERO_RUN_16],
          FAcTables[LTable].Sizes[SYMBOL_ZERO_RUN_16]);
        Dec(LRun, 16);
      end;
      LCategory := CategoryOf(LCoefficient);
      LSymbol := (LRun shl 4) or LCategory;
      WriteBits(FAcTables[LTable].Codes[LSymbol], FAcTables[LTable].Sizes[LSymbol]);
      WriteMagnitude(LCoefficient, LCategory);
      LRun := 0;
    end;
  end;

  // Trailing zeros are replaced by the end of block
  if LRun > 0 then
    WriteBits(FAcTables[LTable].Codes[SYMBOL_END_OF_BLOCK],
      FAcTables[LTable].Sizes[SYMBOL_END_OF_BLOCK]);
end;

procedure TJpegEncoder.EncodeScan;
var
  LBlockX: Integer;
  LBlockY: Integer;
  LComponent: Integer;
  LSamples: TJpegBlockSamples;
  LQuantized: TJpegQuantizedBlock;
begin
  for LBlockY := 0 to (FHeight + 7) div 8 - 1 do
    for LBlockX := 0 to (FWidth + 7) div 8 - 1 do
    begin
      // The output buffer is full: the result is already known
      if FOverflow then
        Exit;

      LoadBlock(LBlockX * 8, LBlockY * 8, LSamples);
      for LComponent := 0 to FComponents - 1 do
      begin
        TransformBlock(LSamples[LComponent], TableOfComponent(LComponent), LQuantized);
        EncodeBlock(LComponent, LQuantized);
      end;
    end;
end;

function TJpegEncoder.Encode(ADest: Pointer; var ADestSize: Cardinal): Integer;
begin
  FDest := ADest;
  FCapacity := ADestSize;
  FWritten := 0;
  FOverflow := False;
  FBitBuffer := 0;
  FBitCount := 0;
  FillChar(FLastDc, SizeOf(FLastDc), 0);

  WriteHeaders;
  EncodeScan;
  FlushBits;
  WriteMarker(MARKER_EOI);

  if FOverflow then
    Result := DDJPEG_ERR_BUFFER_TOO_SMALL
  else
  begin
    ADestSize := FWritten;
    Result := DDJPEG_OK;
  end;
end;

end.
