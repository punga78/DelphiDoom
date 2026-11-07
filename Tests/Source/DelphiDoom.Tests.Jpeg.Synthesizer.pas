{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the JPEG decoder - writer of test streams              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Synthesizer;

// Builds JPEG streams from random DCT coefficients: any sampling, restart
// interval, color marker, sequential or progressive scan script. The pixels
// of the image do not matter (the coefficients are written straight into the
// entropy coded data), so the streams are small and reach every path of a
// decoder, also the ones that real encoders hardly use. Everything is a pure
// function of the specification: the same specification always gives the same
// bytes.

interface

uses
  System.SysUtils, DelphiDoom.Tests.Jpeg.Random;

type
  /// <summary>
  ///   The markers that tell how to read the colors
  /// </summary>
  TJpegColorMarker = (jcmNone, jcmJfif, jcmAdobeTransform0, jcmAdobeTransform1,
    jcmAdobeTransform2);

  /// <summary>
  ///   The kind of the frame header
  /// </summary>
  TJpegFrameKind = (jfkBaseline, jfkExtended, jfkProgressive);

  /// <summary>
  ///   One scan: the components (indexes in the frame) and the progressive
  ///   parameters (they are written as they are also in a sequential stream)
  /// </summary>
  TJpegScanSpec = record
    Components: TArray<Integer>;
    SpectralStart: Integer;
    SpectralEnd: Integer;
    ApproximationHigh: Integer;
    ApproximationLow: Integer;
    class function Make(const AComponents: array of Integer; ASpectralStart,
      ASpectralEnd, AApproximationHigh, AApproximationLow: Integer): TJpegScanSpec; static;
  end;

  /// <summary>
  ///   What to write
  /// </summary>
  TJpegSpec = record
    Width: Integer;
    Height: Integer;
    ComponentCount: Integer;
    Horizontal: array[0..3] of Integer;
    Vertical: array[0..3] of Integer;
    ComponentIds: array[0..3] of Integer;
    Marker: TJpegColorMarker;
    FrameKind: TJpegFrameKind;
    // MCUs between two restart markers, 0 for none
    RestartInterval: Integer;
    // Huffman tables of the encoder instead of the ones of annex K
    CustomTables: Boolean;
    // 16 bit quantization tables
    WideQuantization: Boolean;
    // Percent of the table of annex K
    QuantizationScale: Integer;
    // Chance in percent that the first AC coefficient is not zero
    Density: Integer;
    Seed: Cardinal;
    // Empty: one scan with all the components
    Scans: TArray<TJpegScanSpec>;
    // Comments, markers that nobody reads, fill bytes, tables in many segments
    ExtraMarkers: Boolean;
    class function Make(AWidth, AHeight, AComponentCount: Integer;
      ASeed: Cardinal): TJpegSpec; static;
    procedure SetSampling(AComponent, AHorizontal, AVertical: Integer);
  end;

  /// <summary>
  ///   Writes a JPEG stream from a specification
  /// </summary>
  TJpegSynthesizer = class
  private
    type
      TJpegCodeTable = record
        Codes: array[0..255] of Integer;
        Sizes: array[0..255] of Integer;
        Bits: array[1..16] of Byte;
        Values: TBytes;
      end;
  private
    FSpec: TJpegSpec;
    FRandom: TJpegRandom;
    FOutput: TBytes;
    FLength: Integer;
    FBitBuffer: Cardinal;
    FBitCount: Integer;
    FMaxHorizontal: Integer;
    FMaxVertical: Integer;
    FPaddedColumns: array[0..3] of Integer;
    FPaddedRows: array[0..3] of Integer;
    FRealColumns: array[0..3] of Integer;
    FRealRows: array[0..3] of Integer;
    FBlocks: array[0..3] of TArray<Integer>;
    FQuantization: array[0..1] of array[0..63] of Integer;
    FDcTables: array[0..1] of TJpegCodeTable;
    FAcTables: array[0..1] of TJpegCodeTable;
    FLastDc: array[0..3] of Integer;
    FEobRun: Integer;
    FPendingBits: TBytes;
    FPendingCount: Integer;
    FRestartNumber: Integer;
    FAcTable: Integer;

    constructor Create(const ASpec: TJpegSpec);
    function Run: TBytes;

    procedure WriteByte(AValue: Integer);
    procedure WriteWord(AValue: Integer);
    procedure WriteMarker(AMarker: Integer);
    procedure WriteBits(AValue, ACount: Integer);
    procedure FlushBits;
    procedure WriteTable(const ATable: TJpegCodeTable; AClass, AIdentifier: Integer);

    procedure PrepareGeometry;
    procedure PrepareBlocks;
    procedure PrepareQuantization;
    procedure PrepareTables;
    procedure FillTable(var ATable: TJpegCodeTable; const ABits: array of Byte;
      const AValues: TBytes);
    procedure FillCustomTables;
    function TableOf(AComponent: Integer): Integer;

    procedure WriteHeaders;
    procedure WriteScan(const AScan: TJpegScanSpec);
    procedure WriteScanHeader(const AScan: TJpegScanSpec);

    procedure EmitSymbol(const ATable: TJpegCodeTable; ASymbol: Integer);
    procedure EmitEobRun;
    procedure StartScanState;
    procedure EndScanState;
    procedure Restart;
    procedure EncodeBlock(const AScan: TJpegScanSpec; ASlot, AComponent: Integer;
      ABlockIndex: Integer);
    procedure EncodeSequential(ASlot, AComponent, ABlockIndex: Integer);
    procedure EncodeDcFirst(ASlot, AComponent, ABlockIndex, AShift: Integer);
    procedure EncodeDcRefine(AComponent, ABlockIndex, AShift: Integer);
    procedure EncodeAcFirst(AComponent, ABlockIndex, AStart, AEnd, AShift: Integer);
    procedure EncodeAcRefine(AComponent, ABlockIndex, AStart, AEnd, AShift: Integer);
    class function Category(AValue: Integer): Integer; static;
  public
    class function Build(const ASpec: TJpegSpec): TBytes; static;

    /// <summary>
    ///   The scans of the script of libjpeg for progressive files (spectral
    ///   selection and successive approximation) for a frame of 1 or 3
    ///   components
    /// </summary>
    class function StandardProgression(AComponentCount: Integer): TArray<TJpegScanSpec>; static;

    /// <summary>
    ///   Progressive scans with spectral selection only
    /// </summary>
    class function SpectralProgression(AComponentCount: Integer): TArray<TJpegScanSpec>; static;
  end;

implementation

{$Q-}
{$R-}

const
  NATURAL_ORDER: array[0..63] of Integer = (
    0, 1, 8, 16, 9, 2, 3, 10,
    17, 24, 32, 25, 18, 11, 4, 5,
    12, 19, 26, 33, 40, 48, 41, 34,
    27, 20, 13, 6, 7, 14, 21, 28,
    35, 42, 49, 56, 57, 50, 43, 36,
    29, 22, 15, 23, 30, 37, 44, 51,
    58, 59, 52, 45, 38, 31, 39, 46,
    53, 60, 61, 54, 47, 55, 62, 63
  );

  LUMINANCE_QUANTIZATION: array[0..63] of Integer = (
    16, 11, 10, 16, 24, 40, 51, 61,
    12, 12, 14, 19, 26, 58, 60, 55,
    14, 13, 16, 24, 40, 57, 69, 56,
    14, 17, 22, 29, 51, 87, 80, 62,
    18, 22, 37, 56, 68, 109, 103, 77,
    24, 35, 55, 64, 81, 104, 113, 92,
    49, 64, 78, 87, 103, 121, 120, 101,
    72, 92, 95, 98, 112, 100, 103, 99
  );

  CHROMINANCE_QUANTIZATION: array[0..63] of Integer = (
    17, 18, 24, 47, 99, 99, 99, 99,
    18, 21, 26, 66, 99, 99, 99, 99,
    24, 26, 56, 99, 99, 99, 99, 99,
    47, 66, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99,
    99, 99, 99, 99, 99, 99, 99, 99
  );

  // Tables of annex K
  STD_DC_LUMINANCE_BITS: array[0..15] of Byte = (0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0);
  STD_DC_CHROMINANCE_BITS: array[0..15] of Byte = (0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0);
  STD_DC_VALUES: array[0..11] of Byte = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);

  STD_AC_LUMINANCE_BITS: array[0..15] of Byte = (0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 125);
  STD_AC_LUMINANCE_VALUES: array[0..161] of Byte = (
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

  STD_AC_CHROMINANCE_BITS: array[0..15] of Byte = (0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 119);
  STD_AC_CHROMINANCE_VALUES: array[0..161] of Byte = (
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

  // Custom tables: 255 symbols (all but $FF) with codes of 2 to 12 bits, and
  // 16 DC symbols with codes of 2 to 9 bits
  CUSTOM_AC_BITS: array[0..15] of Byte = (0, 1, 1, 1, 2, 4, 8, 16, 32, 64, 64, 62, 0, 0, 0, 0);
  CUSTOM_DC_BITS: array[0..15] of Byte = (0, 1, 3, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0);

  MARKER_SOI = $D8;
  MARKER_EOI = $D9;
  MARKER_APP0 = $E0;
  MARKER_APP3 = $E3;
  MARKER_APP14 = $EE;
  MARKER_COM = $FE;
  MARKER_DQT = $DB;
  MARKER_DHT = $C4;
  MARKER_DRI = $DD;
  MARKER_SOS = $DA;
  MARKER_RST0 = $D0;

  // The number of correction bits that can wait for an end of block run
  MAX_PENDING_BITS = 1000;

{ TJpegScanSpec }

class function TJpegScanSpec.Make(const AComponents: array of Integer;
  ASpectralStart, ASpectralEnd, AApproximationHigh,
  AApproximationLow: Integer): TJpegScanSpec;
var
  LIndex: Integer;
begin
  SetLength(Result.Components, Length(AComponents));
  for LIndex := 0 to High(AComponents) do
    Result.Components[LIndex] := AComponents[LIndex];
  Result.SpectralStart := ASpectralStart;
  Result.SpectralEnd := ASpectralEnd;
  Result.ApproximationHigh := AApproximationHigh;
  Result.ApproximationLow := AApproximationLow;
end;

{ TJpegSpec }

class function TJpegSpec.Make(AWidth, AHeight, AComponentCount: Integer;
  ASeed: Cardinal): TJpegSpec;
var
  LIndex: Integer;
begin
  Result := Default(TJpegSpec);
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.ComponentCount := AComponentCount;
  for LIndex := 0 to 3 do
  begin
    Result.Horizontal[LIndex] := 1;
    Result.Vertical[LIndex] := 1;
    Result.ComponentIds[LIndex] := LIndex + 1;
  end;
  if AComponentCount = 3 then
    Result.Marker := jcmJfif;
  Result.FrameKind := jfkBaseline;
  Result.QuantizationScale := 100;
  Result.Density := 60;
  Result.Seed := ASeed;
end;

procedure TJpegSpec.SetSampling(AComponent, AHorizontal, AVertical: Integer);
begin
  Horizontal[AComponent] := AHorizontal;
  Vertical[AComponent] := AVertical;
end;

{ TJpegSynthesizer }

class function TJpegSynthesizer.Build(const ASpec: TJpegSpec): TBytes;
var
  LSynthesizer: TJpegSynthesizer;
begin
  LSynthesizer := TJpegSynthesizer.Create(ASpec);
  try
    Result := LSynthesizer.Run;
  finally
    LSynthesizer.Free;
  end;
end;

class function TJpegSynthesizer.StandardProgression(
  AComponentCount: Integer): TArray<TJpegScanSpec>;
begin
  if AComponentCount = 1 then
  begin
    SetLength(Result, 6);
    Result[0] := TJpegScanSpec.Make([0], 0, 0, 0, 1);
    Result[1] := TJpegScanSpec.Make([0], 1, 5, 0, 2);
    Result[2] := TJpegScanSpec.Make([0], 6, 63, 0, 2);
    Result[3] := TJpegScanSpec.Make([0], 1, 63, 2, 1);
    Result[4] := TJpegScanSpec.Make([0], 0, 0, 1, 0);
    Result[5] := TJpegScanSpec.Make([0], 1, 63, 1, 0);
  end
  else
  begin
    SetLength(Result, 10);
    Result[0] := TJpegScanSpec.Make([0, 1, 2], 0, 0, 0, 1);
    Result[1] := TJpegScanSpec.Make([0], 1, 5, 0, 2);
    Result[2] := TJpegScanSpec.Make([2], 1, 63, 0, 1);
    Result[3] := TJpegScanSpec.Make([1], 1, 63, 0, 1);
    Result[4] := TJpegScanSpec.Make([0], 6, 63, 0, 2);
    Result[5] := TJpegScanSpec.Make([0], 1, 63, 2, 1);
    Result[6] := TJpegScanSpec.Make([0, 1, 2], 0, 0, 1, 0);
    Result[7] := TJpegScanSpec.Make([2], 1, 63, 1, 0);
    Result[8] := TJpegScanSpec.Make([1], 1, 63, 1, 0);
    Result[9] := TJpegScanSpec.Make([0], 1, 63, 1, 0);
  end;
end;

class function TJpegSynthesizer.SpectralProgression(
  AComponentCount: Integer): TArray<TJpegScanSpec>;
var
  LIndex: Integer;
begin
  if AComponentCount = 1 then
  begin
    SetLength(Result, 3);
    Result[0] := TJpegScanSpec.Make([0], 0, 0, 0, 0);
    Result[1] := TJpegScanSpec.Make([0], 1, 9, 0, 0);
    Result[2] := TJpegScanSpec.Make([0], 10, 63, 0, 0);
  end
  else
  begin
    SetLength(Result, 1 + AComponentCount * 2);
    Result[0] := TJpegScanSpec.Make([0, 1, 2], 0, 0, 0, 0);
    for LIndex := 0 to AComponentCount - 1 do
    begin
      Result[1 + LIndex * 2] := TJpegScanSpec.Make([LIndex], 1, 9, 0, 0);
      Result[2 + LIndex * 2] := TJpegScanSpec.Make([LIndex], 10, 63, 0, 0);
    end;
  end;
end;

constructor TJpegSynthesizer.Create(const ASpec: TJpegSpec);
begin
  inherited Create;
  FSpec := ASpec;
  FRandom := TJpegRandom.Create(ASpec.Seed);
  SetLength(FOutput, 4096);
  SetLength(FPendingBits, MAX_PENDING_BITS + 64);
end;

procedure TJpegSynthesizer.WriteByte(AValue: Integer);
begin
  if FLength >= Length(FOutput) then
    SetLength(FOutput, Length(FOutput) * 2);
  FOutput[FLength] := Byte(AValue and $FF);
  Inc(FLength);
end;

procedure TJpegSynthesizer.WriteWord(AValue: Integer);
begin
  WriteByte(AValue shr 8);
  WriteByte(AValue and $FF);
end;

procedure TJpegSynthesizer.WriteMarker(AMarker: Integer);
begin
  // A marker may be preceded by fill bytes
  if FSpec.ExtraMarkers and FRandom.Chance(20) then
    WriteByte($FF);
  WriteByte($FF);
  WriteByte(AMarker);
end;

procedure TJpegSynthesizer.WriteBits(AValue, ACount: Integer);
var
  LByte: Integer;
begin
  if ACount = 0 then
    Exit;
  FBitBuffer := (FBitBuffer shl ACount) or (Cardinal(AValue) and ((Cardinal(1) shl ACount) - 1));
  Inc(FBitCount, ACount);
  while FBitCount >= 8 do
  begin
    LByte := Integer((FBitBuffer shr (FBitCount - 8)) and $FF);
    WriteByte(LByte);
    if LByte = $FF then
      WriteByte(0);
    Dec(FBitCount, 8);
  end;
  FBitBuffer := FBitBuffer and ((Cardinal(1) shl FBitCount) - 1);
end;

procedure TJpegSynthesizer.FlushBits;
begin
  if FBitCount > 0 then
    WriteBits((1 shl (8 - FBitCount)) - 1, 8 - FBitCount);
end;

procedure TJpegSynthesizer.WriteTable(const ATable: TJpegCodeTable; AClass,
  AIdentifier: Integer);
var
  LIndex: Integer;
begin
  WriteMarker(MARKER_DHT);
  WriteWord(2 + 1 + 16 + Length(ATable.Values));
  WriteByte((AClass shl 4) or AIdentifier);
  for LIndex := 1 to 16 do
    WriteByte(ATable.Bits[LIndex]);
  for LIndex := 0 to High(ATable.Values) do
    WriteByte(ATable.Values[LIndex]);
end;

procedure TJpegSynthesizer.PrepareGeometry;
var
  LIndex: Integer;
  LMcuColumns: Integer;
  LMcuRows: Integer;
begin
  FMaxHorizontal := 1;
  FMaxVertical := 1;
  for LIndex := 0 to FSpec.ComponentCount - 1 do
  begin
    if FSpec.Horizontal[LIndex] > FMaxHorizontal then
      FMaxHorizontal := FSpec.Horizontal[LIndex];
    if FSpec.Vertical[LIndex] > FMaxVertical then
      FMaxVertical := FSpec.Vertical[LIndex];
  end;

  LMcuColumns := (FSpec.Width + FMaxHorizontal * 8 - 1) div (FMaxHorizontal * 8);
  LMcuRows := (FSpec.Height + FMaxVertical * 8 - 1) div (FMaxVertical * 8);
  for LIndex := 0 to FSpec.ComponentCount - 1 do
  begin
    FRealColumns[LIndex] := (FSpec.Width * FSpec.Horizontal[LIndex] +
      FMaxHorizontal * 8 - 1) div (FMaxHorizontal * 8);
    FRealRows[LIndex] := (FSpec.Height * FSpec.Vertical[LIndex] +
      FMaxVertical * 8 - 1) div (FMaxVertical * 8);
    FPaddedColumns[LIndex] := LMcuColumns * FSpec.Horizontal[LIndex];
    FPaddedRows[LIndex] := LMcuRows * FSpec.Vertical[LIndex];
  end;
end;

procedure TJpegSynthesizer.PrepareBlocks;
var
  LComponent: Integer;
  LBlock: Integer;
  LBase: Integer;
  LCoefficient: Integer;
  LPosition: Integer;
  LDc: Integer;
  LChance: Integer;
  LValue: Integer;
begin
  for LComponent := 0 to FSpec.ComponentCount - 1 do
  begin
    SetLength(FBlocks[LComponent], FPaddedColumns[LComponent] * FPaddedRows[LComponent] * 64);
    LDc := FRandom.Between(-500, 500);
    for LBlock := 0 to FPaddedColumns[LComponent] * FPaddedRows[LComponent] - 1 do
    begin
      LBase := LBlock * 64;
      LDc := LDc + FRandom.Between(-200, 200);
      if LDc > 1000 then
        LDc := 1000
      else if LDc < -1000 then
        LDc := -1000;
      FBlocks[LComponent][LBase] := LDc;

      for LCoefficient := 1 to 63 do
      begin
        LChance := FSpec.Density - LCoefficient;
        if LChance < 2 then
          LChance := 2;
        if not FRandom.Chance(LChance) then
          Continue;

        if FRandom.Chance(85) then
          LValue := FRandom.Between(1, 3)
        else if FRandom.Chance(70) then
          LValue := FRandom.Between(4, 40)
        else
          LValue := FRandom.Between(41, 1000);
        if FRandom.Chance(50) then
          LValue := -LValue;

        LPosition := NATURAL_ORDER[LCoefficient];
        FBlocks[LComponent][LBase + LPosition] := LValue;
      end;
    end;
  end;
end;

procedure TJpegSynthesizer.PrepareQuantization;
var
  LIndex: Integer;
  LValue: Integer;
  LLimit: Integer;
begin
  if FSpec.WideQuantization then
    LLimit := 2000
  else
    LLimit := 255;
  for LIndex := 0 to 63 do
  begin
    LValue := LUMINANCE_QUANTIZATION[LIndex] * FSpec.QuantizationScale div 100;
    if LValue < 1 then
      LValue := 1;
    if LValue > LLimit then
      LValue := LLimit;
    FQuantization[0][LIndex] := LValue;

    LValue := CHROMINANCE_QUANTIZATION[LIndex] * FSpec.QuantizationScale div 100;
    if FSpec.WideQuantization then
      LValue := LValue * 5;
    if LValue < 1 then
      LValue := 1;
    if LValue > LLimit then
      LValue := LLimit;
    FQuantization[1][LIndex] := LValue;
  end;
end;

procedure TJpegSynthesizer.FillTable(var ATable: TJpegCodeTable;
  const ABits: array of Byte; const AValues: TBytes);
var
  LLength: Integer;
  LCount: Integer;
  LCode: Integer;
  LIndex: Integer;
begin
  FillChar(ATable.Codes, SizeOf(ATable.Codes), 0);
  FillChar(ATable.Sizes, SizeOf(ATable.Sizes), 0);
  for LLength := 1 to 16 do
    ATable.Bits[LLength] := ABits[LLength - 1];
  ATable.Values := Copy(AValues);

  LCode := 0;
  LIndex := 0;
  for LLength := 1 to 16 do
  begin
    for LCount := 1 to ATable.Bits[LLength] do
    begin
      ATable.Codes[ATable.Values[LIndex]] := LCode;
      ATable.Sizes[ATable.Values[LIndex]] := LLength;
      Inc(LIndex);
      Inc(LCode);
    end;
    LCode := LCode shl 1;
  end;
end;

procedure TJpegSynthesizer.FillCustomTables;
var
  LSymbols: TBytes;
  LReversed: TBytes;
  LIndex: Integer;
  LOther: Integer;
  LKeyA: Integer;
  LKeyB: Integer;
  LTemp: Byte;
  LDc: TBytes;
  LDcReversed: TBytes;
begin
  // The symbols in order of use: runs and sizes that are small come first
  SetLength(LSymbols, 255);
  for LIndex := 0 to 254 do
    LSymbols[LIndex] := Byte(LIndex);
  for LIndex := 1 to 254 do
  begin
    LTemp := LSymbols[LIndex];
    LKeyA := (LTemp shr 4) + (LTemp and 15) * 2;
    LOther := LIndex - 1;
    while LOther >= 0 do
    begin
      LKeyB := (LSymbols[LOther] shr 4) + (LSymbols[LOther] and 15) * 2;
      if LKeyB <= LKeyA then
        Break;
      LSymbols[LOther + 1] := LSymbols[LOther];
      Dec(LOther);
    end;
    LSymbols[LOther + 1] := LTemp;
  end;

  SetLength(LReversed, 255);
  for LIndex := 0 to 254 do
    LReversed[LIndex] := LSymbols[254 - LIndex];

  SetLength(LDc, 16);
  SetLength(LDcReversed, 16);
  for LIndex := 0 to 15 do
  begin
    LDc[LIndex] := Byte(LIndex);
    LDcReversed[LIndex] := Byte(15 - LIndex);
  end;

  FillTable(FAcTables[0], CUSTOM_AC_BITS, LSymbols);
  FillTable(FAcTables[1], CUSTOM_AC_BITS, LReversed);
  FillTable(FDcTables[0], CUSTOM_DC_BITS, LDc);
  FillTable(FDcTables[1], CUSTOM_DC_BITS, LDcReversed);
end;

procedure TJpegSynthesizer.PrepareTables;
var
  LValues: TBytes;
begin
  if FSpec.CustomTables or (FSpec.FrameKind = jfkProgressive) then
  begin
    FillCustomTables;
    Exit;
  end;

  SetLength(LValues, Length(STD_DC_VALUES));
  Move(STD_DC_VALUES, LValues[0], Length(LValues));
  FillTable(FDcTables[0], STD_DC_LUMINANCE_BITS, LValues);
  FillTable(FDcTables[1], STD_DC_CHROMINANCE_BITS, LValues);

  SetLength(LValues, Length(STD_AC_LUMINANCE_VALUES));
  Move(STD_AC_LUMINANCE_VALUES, LValues[0], Length(LValues));
  FillTable(FAcTables[0], STD_AC_LUMINANCE_BITS, LValues);
  SetLength(LValues, Length(STD_AC_CHROMINANCE_VALUES));
  Move(STD_AC_CHROMINANCE_VALUES, LValues[0], Length(LValues));
  FillTable(FAcTables[1], STD_AC_CHROMINANCE_BITS, LValues);
end;

function TJpegSynthesizer.TableOf(AComponent: Integer): Integer;
begin
  if AComponent = 0 then
    Result := 0
  else
    Result := 1;
end;

procedure TJpegSynthesizer.WriteHeaders;
var
  LIndex: Integer;
  LPrecision: Integer;
  LSegments: Boolean;
  LTable: Integer;
begin
  WriteByte($FF);
  WriteByte(MARKER_SOI);

  case FSpec.Marker of
    jcmJfif:
      begin
        WriteMarker(MARKER_APP0);
        WriteWord(16);
        WriteByte(Ord('J'));
        WriteByte(Ord('F'));
        WriteByte(Ord('I'));
        WriteByte(Ord('F'));
        WriteByte(0);
        WriteByte(1);
        WriteByte(FRandom.Between(0, 2));
        WriteByte(0);
        WriteWord(1);
        WriteWord(1);
        WriteByte(0);
        WriteByte(0);
      end;
    jcmAdobeTransform0, jcmAdobeTransform1, jcmAdobeTransform2:
      begin
        WriteMarker(MARKER_APP14);
        WriteWord(14);
        WriteByte(Ord('A'));
        WriteByte(Ord('d'));
        WriteByte(Ord('o'));
        WriteByte(Ord('b'));
        WriteByte(Ord('e'));
        WriteWord(100);
        WriteWord(0);
        WriteWord(0);
        WriteByte(Ord(FSpec.Marker) - Ord(jcmAdobeTransform0));
      end;
  end;

  if FSpec.ExtraMarkers then
  begin
    WriteMarker(MARKER_COM);
    WriteWord(2 + 5);
    for LIndex := 1 to 5 do
      WriteByte(Ord('a') + LIndex);
    WriteMarker(MARKER_APP3);
    WriteWord(2 + 20);
    for LIndex := 1 to 20 do
      WriteByte(FRandom.Between(0, 255));
    // An APP0 that is not JFIF
    WriteMarker(MARKER_APP0);
    WriteWord(2 + 6);
    WriteByte(Ord('J'));
    WriteByte(Ord('F'));
    WriteByte(Ord('X'));
    WriteByte(Ord('X'));
    WriteByte(0);
    WriteByte($10);
  end;

  LSegments := FSpec.ExtraMarkers and FRandom.Chance(50);
  if FSpec.WideQuantization then
    LPrecision := 1
  else
    LPrecision := 0;
  if (FSpec.ComponentCount = 1) or LSegments then
  begin
    for LTable := 0 to 1 do
    begin
      if (LTable = 1) and (FSpec.ComponentCount = 1) then
        Break;
      WriteMarker(MARKER_DQT);
      WriteWord(2 + 1 + 64 * (1 + LPrecision));
      WriteByte((LPrecision shl 4) or LTable);
      for LIndex := 0 to 63 do
        if LPrecision = 1 then
          WriteWord(FQuantization[LTable][NATURAL_ORDER[LIndex]])
        else
          WriteByte(FQuantization[LTable][NATURAL_ORDER[LIndex]]);
    end;
  end
  else
  begin
    WriteMarker(MARKER_DQT);
    WriteWord(2 + 2 * (1 + 64 * (1 + LPrecision)));
    for LTable := 0 to 1 do
    begin
      WriteByte((LPrecision shl 4) or LTable);
      for LIndex := 0 to 63 do
        if LPrecision = 1 then
          WriteWord(FQuantization[LTable][NATURAL_ORDER[LIndex]])
        else
          WriteByte(FQuantization[LTable][NATURAL_ORDER[LIndex]]);
    end;
  end;

  case FSpec.FrameKind of
    jfkBaseline:
      WriteMarker($C0);
    jfkExtended:
      WriteMarker($C1);
    jfkProgressive:
      WriteMarker($C2);
  end;
  WriteWord(8 + 3 * FSpec.ComponentCount);
  WriteByte(8);
  WriteWord(FSpec.Height);
  WriteWord(FSpec.Width);
  WriteByte(FSpec.ComponentCount);
  for LIndex := 0 to FSpec.ComponentCount - 1 do
  begin
    WriteByte(FSpec.ComponentIds[LIndex]);
    WriteByte((FSpec.Horizontal[LIndex] shl 4) or FSpec.Vertical[LIndex]);
    WriteByte(TableOf(LIndex));
  end;

  WriteTable(FDcTables[0], 0, 0);
  WriteTable(FAcTables[0], 1, 0);
  WriteTable(FDcTables[1], 0, 1);
  WriteTable(FAcTables[1], 1, 1);

  if FSpec.RestartInterval > 0 then
  begin
    WriteMarker(MARKER_DRI);
    WriteWord(4);
    WriteWord(FSpec.RestartInterval);
  end;
end;

procedure TJpegSynthesizer.WriteScanHeader(const AScan: TJpegScanSpec);
var
  LIndex: Integer;
  LComponent: Integer;
begin
  WriteMarker(MARKER_SOS);
  WriteWord(6 + 2 * Length(AScan.Components));
  WriteByte(Length(AScan.Components));
  for LIndex := 0 to High(AScan.Components) do
  begin
    LComponent := AScan.Components[LIndex];
    WriteByte(FSpec.ComponentIds[LComponent]);
    WriteByte(TableOf(LComponent) * $11);
  end;
  WriteByte(AScan.SpectralStart);
  WriteByte(AScan.SpectralEnd);
  WriteByte((AScan.ApproximationHigh shl 4) or AScan.ApproximationLow);
end;

class function TJpegSynthesizer.Category(AValue: Integer): Integer;
begin
  AValue := Abs(AValue);
  Result := 0;
  while AValue <> 0 do
  begin
    Inc(Result);
    AValue := AValue shr 1;
  end;
end;

procedure TJpegSynthesizer.EmitSymbol(const ATable: TJpegCodeTable; ASymbol: Integer);
begin
  if ATable.Sizes[ASymbol] = 0 then
    raise Exception.CreateFmt('The symbol %d is not in the table', [ASymbol]);
  WriteBits(ATable.Codes[ASymbol], ATable.Sizes[ASymbol]);
end;

procedure TJpegSynthesizer.EmitEobRun;
var
  LCount: Integer;
  LRun: Integer;
  LIndex: Integer;
begin
  if FEobRun > 0 then
  begin
    LRun := FEobRun;
    LCount := 0;
    LRun := LRun shr 1;
    while LRun <> 0 do
    begin
      Inc(LCount);
      LRun := LRun shr 1;
    end;
    EmitSymbol(FAcTables[FAcTable], LCount shl 4);
    if LCount > 0 then
      WriteBits(FEobRun, LCount);
    FEobRun := 0;
  end;
  for LIndex := 0 to FPendingCount - 1 do
    WriteBits(FPendingBits[LIndex], 1);
  FPendingCount := 0;
end;

procedure TJpegSynthesizer.StartScanState;
begin
  FillChar(FLastDc, SizeOf(FLastDc), 0);
  FEobRun := 0;
  FPendingCount := 0;
  FBitBuffer := 0;
  FBitCount := 0;
  FRestartNumber := 0;
end;

procedure TJpegSynthesizer.EndScanState;
begin
  EmitEobRun;
  FlushBits;
end;

procedure TJpegSynthesizer.Restart;
begin
  EmitEobRun;
  FlushBits;
  WriteByte($FF);
  WriteByte(MARKER_RST0 + FRestartNumber);
  FRestartNumber := (FRestartNumber + 1) and 7;
  FillChar(FLastDc, SizeOf(FLastDc), 0);
end;

procedure TJpegSynthesizer.EncodeSequential(ASlot, AComponent,
  ABlockIndex: Integer);
var
  LBase: Integer;
  LTable: Integer;
  LDifference: Integer;
  LCategory: Integer;
  LRun: Integer;
  LIndex: Integer;
  LValue: Integer;
begin
  LBase := ABlockIndex * 64;
  LTable := TableOf(AComponent);

  LDifference := FBlocks[AComponent][LBase] - FLastDc[ASlot];
  FLastDc[ASlot] := FBlocks[AComponent][LBase];
  LCategory := Category(LDifference);
  EmitSymbol(FDcTables[LTable], LCategory);
  if LCategory > 0 then
  begin
    if LDifference < 0 then
      WriteBits(LDifference - 1, LCategory)
    else
      WriteBits(LDifference, LCategory);
  end;

  LRun := 0;
  for LIndex := 1 to 63 do
  begin
    LValue := FBlocks[AComponent][LBase + NATURAL_ORDER[LIndex]];
    if LValue = 0 then
    begin
      Inc(LRun);
      Continue;
    end;
    while LRun > 15 do
    begin
      EmitSymbol(FAcTables[LTable], $F0);
      Dec(LRun, 16);
    end;
    LCategory := Category(LValue);
    EmitSymbol(FAcTables[LTable], (LRun shl 4) or LCategory);
    if LValue < 0 then
      WriteBits(LValue - 1, LCategory)
    else
      WriteBits(LValue, LCategory);
    LRun := 0;
  end;
  if LRun > 0 then
    EmitSymbol(FAcTables[LTable], 0);
end;

procedure TJpegSynthesizer.EncodeDcFirst(ASlot, AComponent, ABlockIndex,
  AShift: Integer);
var
  LValue: Integer;
  LDifference: Integer;
  LCategory: Integer;
  LTable: Integer;
begin
  LTable := TableOf(AComponent);
  // Arithmetic shift: the point transform of a negative value rounds down
  LValue := FBlocks[AComponent][ABlockIndex * 64];
  if AShift > 0 then
    LValue := LValue div (1 shl AShift) - Ord((LValue < 0) and ((LValue mod (1 shl AShift)) <> 0));
  LDifference := LValue - FLastDc[ASlot];
  FLastDc[ASlot] := LValue;
  LCategory := Category(LDifference);
  EmitSymbol(FDcTables[LTable], LCategory);
  if LCategory > 0 then
  begin
    if LDifference < 0 then
      WriteBits(LDifference - 1, LCategory)
    else
      WriteBits(LDifference, LCategory);
  end;
end;

procedure TJpegSynthesizer.EncodeDcRefine(AComponent, ABlockIndex,
  AShift: Integer);
var
  LValue: Integer;
begin
  LValue := FBlocks[AComponent][ABlockIndex * 64];
  // The bit AShift of the two's complement
  WriteBits((LValue shr AShift) and 1, 1);
end;

procedure TJpegSynthesizer.EncodeAcFirst(AComponent, ABlockIndex, AStart,
  AEnd, AShift: Integer);
var
  LBase: Integer;
  LRun: Integer;
  LIndex: Integer;
  LValue: Integer;
  LMagnitude: Integer;
  LBits: Integer;
  LCategory: Integer;
  LTable: Integer;
begin
  LBase := ABlockIndex * 64;
  LTable := TableOf(AComponent);
  LRun := 0;
  for LIndex := AStart to AEnd do
  begin
    LValue := FBlocks[AComponent][LBase + NATURAL_ORDER[LIndex]];
    if LValue = 0 then
    begin
      Inc(LRun);
      Continue;
    end;
    if LValue < 0 then
    begin
      LMagnitude := (-LValue) shr AShift;
      LBits := not LMagnitude;
    end
    else
    begin
      LMagnitude := LValue shr AShift;
      LBits := LMagnitude;
    end;
    if LMagnitude = 0 then
    begin
      Inc(LRun);
      Continue;
    end;

    if FEobRun > 0 then
      EmitEobRun;
    while LRun > 15 do
    begin
      EmitSymbol(FAcTables[LTable], $F0);
      Dec(LRun, 16);
    end;
    LCategory := Category(LMagnitude);
    EmitSymbol(FAcTables[LTable], (LRun shl 4) or LCategory);
    WriteBits(LBits, LCategory);
    LRun := 0;
  end;

  if LRun > 0 then
  begin
    Inc(FEobRun);
    if FEobRun = $7FFF then
      EmitEobRun;
  end;
end;

procedure TJpegSynthesizer.EncodeAcRefine(AComponent, ABlockIndex, AStart,
  AEnd, AShift: Integer);
var
  LBase: Integer;
  LTable: Integer;
  LValues: array[0..63] of Integer;
  LIndex: Integer;
  LValue: Integer;
  LEnd: Integer;
  LRun: Integer;
  LBlockBits: TBytes;
  LBlockCount: Integer;
  LBit: Integer;
  LNext: Integer;
begin
  LBase := ABlockIndex * 64;
  LTable := TableOf(AComponent);

  // The absolute values after the point transform and the last coefficient that
  // becomes not zero in this scan
  LEnd := 0;
  for LIndex := AStart to AEnd do
  begin
    LValue := Abs(FBlocks[AComponent][LBase + NATURAL_ORDER[LIndex]]) shr AShift;
    LValues[LIndex] := LValue;
    if LValue = 1 then
      LEnd := LIndex;
  end;

  SetLength(LBlockBits, 64);
  LBlockCount := 0;
  LRun := 0;
  for LIndex := AStart to AEnd do
  begin
    LValue := LValues[LIndex];
    if LValue = 0 then
    begin
      Inc(LRun);
      Continue;
    end;

    // Zero runs of 16 are not written when the end of block takes them
    while (LRun > 15) and (LIndex <= LEnd) do
    begin
      EmitEobRun;
      EmitSymbol(FAcTables[LTable], $F0);
      Dec(LRun, 16);
      for LBit := 0 to LBlockCount - 1 do
        WriteBits(LBlockBits[LBit], 1);
      LBlockCount := 0;
    end;

    // A coefficient that was not zero only needs a bit
    if LValue > 1 then
    begin
      LBlockBits[LBlockCount] := Byte(LValue and 1);
      Inc(LBlockCount);
      Continue;
    end;

    EmitEobRun;
    EmitSymbol(FAcTables[LTable], (LRun shl 4) + 1);
    if FBlocks[AComponent][LBase + NATURAL_ORDER[LIndex]] < 0 then
      WriteBits(0, 1)
    else
      WriteBits(1, 1);
    for LBit := 0 to LBlockCount - 1 do
      WriteBits(LBlockBits[LBit], 1);
    LBlockCount := 0;
    LRun := 0;
  end;

  if (LRun > 0) or (LBlockCount > 0) then
  begin
    Inc(FEobRun);
    for LNext := 0 to LBlockCount - 1 do
    begin
      FPendingBits[FPendingCount] := LBlockBits[LNext];
      Inc(FPendingCount);
    end;
    if (FEobRun = $7FFF) or (FPendingCount > MAX_PENDING_BITS - 64 + 1) then
      EmitEobRun;
  end;
end;

procedure TJpegSynthesizer.EncodeBlock(const AScan: TJpegScanSpec; ASlot,
  AComponent, ABlockIndex: Integer);
begin
  if FSpec.FrameKind <> jfkProgressive then
    EncodeSequential(ASlot, AComponent, ABlockIndex)
  else if AScan.SpectralStart = 0 then
  begin
    if AScan.ApproximationHigh = 0 then
      EncodeDcFirst(ASlot, AComponent, ABlockIndex, AScan.ApproximationLow)
    else
      EncodeDcRefine(AComponent, ABlockIndex, AScan.ApproximationLow);
  end
  else if AScan.ApproximationHigh = 0 then
    EncodeAcFirst(AComponent, ABlockIndex, AScan.SpectralStart,
      AScan.SpectralEnd, AScan.ApproximationLow)
  else
    EncodeAcRefine(AComponent, ABlockIndex, AScan.SpectralStart,
      AScan.SpectralEnd, AScan.ApproximationLow);
end;

procedure TJpegSynthesizer.WriteScan(const AScan: TJpegScanSpec);
var
  LMcuColumns: Integer;
  LMcuRows: Integer;
  LMcu: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSlot: Integer;
  LComponent: Integer;
  LBlockRow: Integer;
  LBlockColumn: Integer;
  LPaddedColumns: Integer;
begin
  WriteScanHeader(AScan);
  FAcTable := TableOf(AScan.Components[0]);
  StartScanState;
  LMcu := 0;

  if Length(AScan.Components) = 1 then
  begin
    // One block per MCU, only the blocks that are inside the image
    LComponent := AScan.Components[0];
    for LRow := 0 to FRealRows[LComponent] - 1 do
      for LColumn := 0 to FRealColumns[LComponent] - 1 do
      begin
        if (FSpec.RestartInterval > 0) and (LMcu > 0) and
           (LMcu mod FSpec.RestartInterval = 0) then
          Restart;
        EncodeBlock(AScan, 0, LComponent, LRow * FPaddedColumns[LComponent] + LColumn);
        Inc(LMcu);
      end;
  end
  else
  begin
    LMcuColumns := (FSpec.Width + FMaxHorizontal * 8 - 1) div (FMaxHorizontal * 8);
    LMcuRows := (FSpec.Height + FMaxVertical * 8 - 1) div (FMaxVertical * 8);
    for LRow := 0 to LMcuRows - 1 do
      for LColumn := 0 to LMcuColumns - 1 do
      begin
        if (FSpec.RestartInterval > 0) and (LMcu > 0) and
           (LMcu mod FSpec.RestartInterval = 0) then
          Restart;
        for LSlot := 0 to High(AScan.Components) do
        begin
          LComponent := AScan.Components[LSlot];
          LPaddedColumns := FPaddedColumns[LComponent];
          for LBlockRow := 0 to FSpec.Vertical[LComponent] - 1 do
            for LBlockColumn := 0 to FSpec.Horizontal[LComponent] - 1 do
              EncodeBlock(AScan, LSlot, LComponent,
                (LRow * FSpec.Vertical[LComponent] + LBlockRow) * LPaddedColumns +
                LColumn * FSpec.Horizontal[LComponent] + LBlockColumn);
        end;
        Inc(LMcu);
      end;
  end;

  EndScanState;
end;

function TJpegSynthesizer.Run: TBytes;
var
  LScan: Integer;
  LAll: TJpegScanSpec;
  LIndex: Integer;
begin
  PrepareGeometry;
  PrepareBlocks;
  PrepareQuantization;
  PrepareTables;

  WriteHeaders;
  if Length(FSpec.Scans) = 0 then
  begin
    SetLength(LAll.Components, FSpec.ComponentCount);
    for LIndex := 0 to FSpec.ComponentCount - 1 do
      LAll.Components[LIndex] := LIndex;
    LAll.SpectralStart := 0;
    LAll.SpectralEnd := 63;
    LAll.ApproximationHigh := 0;
    LAll.ApproximationLow := 0;
    WriteScan(LAll);
  end
  else
    for LScan := 0 to High(FSpec.Scans) do
    begin
      // The tables may be sent again between the scans
      if FSpec.ExtraMarkers and (LScan > 0) and FRandom.Chance(40) then
        WriteTable(FAcTables[1], 1, 1);
      WriteScan(FSpec.Scans[LScan]);
    end;

  WriteByte($FF);
  WriteByte(MARKER_EOI);
  SetLength(FOutput, FLength);
  Result := FOutput;
end;

end.
