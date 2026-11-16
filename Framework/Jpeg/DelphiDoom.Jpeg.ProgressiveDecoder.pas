{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - decoder of progressive scans                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.ProgressiveDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.BitReader, DelphiDoom.Jpeg.EntropyDecoder,
  DelphiDoom.Jpeg.EntropyDecoderBase, DelphiDoom.Jpeg.Frame,
  DelphiDoom.Jpeg.HuffmanTable, DelphiDoom.Jpeg.MarkerReader,
  DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   Decodes the scans of a progressive image: the DC and the AC in bands,
  ///   first with some bits of each coefficient and then with the bits that
  ///   were left out
  /// </summary>
  /// <remarks>
  ///   Port of jdphuff.c of libjpeg 6b. It also keeps what is known of every
  ///   coefficient (CoefficientBit): how many low bits are still missing, or
  ///   -1 when no scan has given it yet; the smoothing of the blocks needs it
  /// </remarks>
  TJpegProgressiveDecoder = class(TJpegEntropyDecoderBase)
  private
    type
      TScanKind = (skDcFirst, skAcFirst, skDcRefine, skAcRefine);
  private
    FKind: TScanKind;
    FDcTables: array[0..3] of TJpegHuffmanTable;
    FAcTable: TJpegHuffmanTable;
    FEobRun: Integer;
    FCoefficientBits: array[0..JPEG_MAX_COMPONENTS - 1] of array[0..JPEG_DCT_SIZE2 - 1] of Integer;
    procedure FreeTables;
    procedure DecodeDcFirst(const ABlocks: TJpegBlockPointers);
    procedure DecodeAcFirst(const ABlocks: TJpegBlockPointers);
    procedure DecodeDcRefine(const ABlocks: TJpegBlockPointers);
    procedure DecodeAcRefine(const ABlocks: TJpegBlockPointers);
    function ReadExtended(ABits: Integer): Integer;
  protected
    procedure ResetState; override;
    procedure DecodeBlocks(const ABlocks: TJpegBlockPointers); override;
  public
    constructor Create(AFrame: TJpegFrame; AMarkers: TJpegMarkerReader;
      ABits: TJpegBitReader);
    destructor Destroy; override;

    procedure StartScan; override;

    /// <summary>
    ///   The number of bits of the coefficient (in zigzag order) of a
    ///   component that the scans did not send yet, or -1 if none did
    /// </summary>
    function CoefficientBit(AComponent, AIndex: Integer): Integer;
  end;

implementation

const
  EXTEND_TEST: array[0..15] of Integer = (
    $0000, $0001, $0002, $0004, $0008, $0010, $0020, $0040,
    $0080, $0100, $0200, $0400, $0800, $1000, $2000, $4000
  );

  EXTEND_OFFSET: array[0..15] of Integer = (
    0, -1, -3, -7, -15, -31, -63, -127, -255, -511, -1023, -2047, -4095, -8191,
    -16383, -32767
  );

{$Q-}
{$R-}

{ TJpegProgressiveDecoder }

constructor TJpegProgressiveDecoder.Create(AFrame: TJpegFrame;
  AMarkers: TJpegMarkerReader; ABits: TJpegBitReader);
var
  LComponent: Integer;
  LIndex: Integer;
begin
  inherited Create(AFrame, AMarkers, ABits);
  for LComponent := 0 to JPEG_MAX_COMPONENTS - 1 do
    for LIndex := 0 to JPEG_DCT_SIZE2 - 1 do
      FCoefficientBits[LComponent][LIndex] := -1;
end;

destructor TJpegProgressiveDecoder.Destroy;
begin
  FreeTables;
  inherited Destroy;
end;

procedure TJpegProgressiveDecoder.FreeTables;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FDcTables) do
    FreeAndNil(FDcTables[LIndex]);
  FreeAndNil(FAcTable);
end;

function TJpegProgressiveDecoder.CoefficientBit(AComponent, AIndex: Integer): Integer;
begin
  Result := FCoefficientBits[AComponent][AIndex];
end;

procedure TJpegProgressiveDecoder.ResetState;
begin
  inherited ResetState;
  FEobRun := 0;
end;

procedure TJpegProgressiveDecoder.StartScan;
var
  LScan: PJpegScanInfo;
  LIsDcBand: Boolean;
  LBad: Boolean;
  LSlot: Integer;
  LIndex: Integer;
  LComponent: PJpegComponentInfo;
begin
  LScan := FFrame.Scan;
  LIsDcBand := LScan^.SpectralStart = 0;

  // The parameters of the scan must be what the standard allows
  LBad := False;
  if LIsDcBand then
  begin
    if LScan^.SpectralEnd <> 0 then
      LBad := True;
  end
  else
  begin
    if (LScan^.SpectralStart > LScan^.SpectralEnd) or
       (LScan^.SpectralEnd >= JPEG_DCT_SIZE2) then
      LBad := True;
    // The AC coefficients are sent one component at a time
    if LScan^.ComponentCount <> 1 then
      LBad := True;
  end;
  if LScan^.ApproximationHigh <> 0 then
    if LScan^.ApproximationLow <> LScan^.ApproximationHigh - 1 then
      LBad := True;
  if LScan^.ApproximationLow > 13 then
    LBad := True;
  if LBad then
    EJpegDecodeException.Fail(jdeBadProgression);

  // What is known of the coefficients after this scan. A scan that does not
  // follow the one before it in the progression is not an error: it is used
  for LSlot := 0 to LScan^.ComponentCount - 1 do
    for LIndex := LScan^.SpectralStart to LScan^.SpectralEnd do
      FCoefficientBits[FFrame.ScanComponent[LSlot]^.Index][LIndex] :=
        LScan^.ApproximationLow;

  if LScan^.ApproximationHigh = 0 then
  begin
    if LIsDcBand then
      FKind := skDcFirst
    else
      FKind := skAcFirst;
  end
  else
  begin
    if LIsDcBand then
      FKind := skDcRefine
    else
      FKind := skAcRefine;
  end;

  FreeTables;
  for LSlot := 0 to LScan^.ComponentCount - 1 do
  begin
    LComponent := FFrame.ScanComponent[LSlot];
    if LIsDcBand then
    begin
      // The bits that refine the DC are not coded
      if LScan^.ApproximationHigh = 0 then
        FDcTables[LSlot] := BuildTable(LComponent^.DcTableNumber, True);
    end
    else
    begin
      FreeAndNil(FAcTable);
      FAcTable := BuildTable(LComponent^.AcTableNumber, False);
    end;
  end;

  StartCommon;
  FEobRun := 0;
end;

procedure TJpegProgressiveDecoder.DecodeBlocks(const ABlocks: TJpegBlockPointers);
begin
  case FKind of
    skDcFirst:
      DecodeDcFirst(ABlocks);
    skAcFirst:
      DecodeAcFirst(ABlocks);
    skDcRefine:
      DecodeDcRefine(ABlocks);
    skAcRefine:
      DecodeAcRefine(ABlocks);
  end;
end;

function TJpegProgressiveDecoder.ReadExtended(ABits: Integer): Integer;
begin
  // A number of ABits bits whose first bit is 0 is negative
  Result := FBits.ReadBits(ABits);
  if Result < EXTEND_TEST[ABits] then
    Result := Result + EXTEND_OFFSET[ABits];
end;

procedure TJpegProgressiveDecoder.DecodeDcFirst(const ABlocks: TJpegBlockPointers);
var
  LBlock: Integer;
  LSlot: Integer;
  LBits: Integer;
  LValue: Integer;
  LShift: Integer;
begin
  if FBits.InsufficientData then
    Exit;

  LShift := FFrame.Scan^.ApproximationLow;
  for LBlock := 0 to FFrame.Scan^.BlocksInMcu - 1 do
  begin
    LSlot := FFrame.Scan^.McuMembership[LBlock];
    LBits := FBits.DecodeSymbol(FDcTables[LSlot]);
    if LBits <> 0 then
      LValue := ReadExtended(LBits)
    else
      LValue := 0;
    Inc(LValue, FLastDc[LSlot]);
    FLastDc[LSlot] := LValue;
    ABlocks[LBlock]^[0] := LValue shl LShift;
  end;
end;

procedure TJpegProgressiveDecoder.DecodeAcFirst(const ABlocks: TJpegBlockPointers);
var
  LScan: PJpegScanInfo;
  LEobRun: Integer;
  LIndex: Integer;
  LValue: Integer;
  LRun: Integer;
  LBits: Integer;
  LBlock: PJpegBlock;
begin
  if FBits.InsufficientData then
    Exit;

  LScan := FFrame.Scan;
  LEobRun := FEobRun;
  if LEobRun > 0 then
    // The block is in a run of blocks without AC coefficients in this band
    Dec(LEobRun)
  else
  begin
    LBlock := ABlocks[0];
    LIndex := LScan^.SpectralStart;
    while LIndex <= LScan^.SpectralEnd do
    begin
      LValue := FBits.DecodeSymbol(FAcTable);
      LRun := LValue shr 4;
      LBits := LValue and 15;
      if LBits <> 0 then
      begin
        Inc(LIndex, LRun);
        LValue := ReadExtended(LBits);
        LBlock^[JPEG_NATURAL_ORDER[LIndex]] := LValue shl LScan^.ApproximationLow;
      end
      else
      begin
        if LRun = 15 then
          // Sixteen zeros
          Inc(LIndex, 15)
        else
        begin
          // The end of a run of blocks: this one and the next ones
          LEobRun := 1 shl LRun;
          if LRun <> 0 then
            Inc(LEobRun, FBits.ReadBits(LRun));
          Dec(LEobRun);
          Break;
        end;
      end;
      Inc(LIndex);
    end;
  end;
  FEobRun := LEobRun;
end;

procedure TJpegProgressiveDecoder.DecodeDcRefine(const ABlocks: TJpegBlockPointers);
var
  LBlock: Integer;
  LBit: Integer;
begin
  // One bit for each block: the next bit of the DC. This does not stop at a
  // marker: it takes the zeros that the bit reader gives
  LBit := 1 shl FFrame.Scan^.ApproximationLow;
  for LBlock := 0 to FFrame.Scan^.BlocksInMcu - 1 do
    if FBits.ReadBits(1) <> 0 then
      ABlocks[LBlock]^[0] := ABlocks[LBlock]^[0] or LBit;
end;

procedure TJpegProgressiveDecoder.DecodeAcRefine(const ABlocks: TJpegBlockPointers);
var
  LScan: PJpegScanInfo;
  LBlock: PJpegBlock;
  LBit: Integer;
  LNegativeBit: Integer;
  LIndex: Integer;
  LValue: Integer;
  LRun: Integer;
  LBits: Integer;
  LEobRun: Integer;
  LCoefficient: PInteger;
begin
  if FBits.InsufficientData then
    Exit;

  LScan := FFrame.Scan;
  LBit := 1 shl LScan^.ApproximationLow;
  LNegativeBit := -1 shl LScan^.ApproximationLow;
  LBlock := ABlocks[0];
  LEobRun := FEobRun;
  LIndex := LScan^.SpectralStart;

  if LEobRun = 0 then
  begin
    while LIndex <= LScan^.SpectralEnd do
    begin
      LValue := FBits.DecodeSymbol(FAcTable);
      LRun := LValue shr 4;
      LBits := LValue and 15;
      if LBits <> 0 then
      begin
        // A coefficient that was zero becomes +1 or -1 (at this bit)
        if FBits.ReadBits(1) <> 0 then
          LValue := LBit
        else
          LValue := LNegativeBit;
      end
      else
      begin
        LValue := 0;
        if LRun <> 15 then
        begin
          // The end of a run of blocks
          LEobRun := 1 shl LRun;
          if LRun <> 0 then
            Inc(LEobRun, FBits.ReadBits(LRun));
          Break;
        end;
      end;

      // Skips the zero coefficients that the run counts; each coefficient that
      // is not zero on the way gets a bit of correction
      repeat
        LCoefficient := @LBlock^[JPEG_NATURAL_ORDER[LIndex]];
        if LCoefficient^ <> 0 then
        begin
          if FBits.ReadBits(1) <> 0 then
            if (LCoefficient^ and LBit) = 0 then
            begin
              if LCoefficient^ >= 0 then
                Inc(LCoefficient^, LBit)
              else
                Inc(LCoefficient^, LNegativeBit);
            end;
        end
        else
        begin
          Dec(LRun);
          if LRun < 0 then
            Break;
        end;
        Inc(LIndex);
      until LIndex > LScan^.SpectralEnd;

      if LValue <> 0 then
        LBlock^[JPEG_NATURAL_ORDER[LIndex]] := LValue;
      Inc(LIndex);
    end;
  end;

  if LEobRun > 0 then
  begin
    // The rest of the band: only the bits of correction
    while LIndex <= LScan^.SpectralEnd do
    begin
      LCoefficient := @LBlock^[JPEG_NATURAL_ORDER[LIndex]];
      if LCoefficient^ <> 0 then
      begin
        if FBits.ReadBits(1) <> 0 then
          if (LCoefficient^ and LBit) = 0 then
          begin
            if LCoefficient^ >= 0 then
              Inc(LCoefficient^, LBit)
            else
              Inc(LCoefficient^, LNegativeBit);
          end;
      end;
      Inc(LIndex);
    end;
    Dec(LEobRun);
  end;

  FEobRun := LEobRun;
end;

end.
