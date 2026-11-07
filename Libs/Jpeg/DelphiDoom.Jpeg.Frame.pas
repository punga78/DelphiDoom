{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - what the headers of the stream say                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Frame;

interface

uses
  DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   The state that the markers build: size of the image, components,
  ///   tables, restart interval, color markers and the parameters of the scan
  ///   that is being read. It also works out the geometry (blocks and MCUs)
  ///   that depends on them
  /// </summary>
  /// <remarks>
  ///   Port of the parts of jdinput.c and jdapimin.c of libjpeg 6b that hold
  ///   or compute the description of the image
  /// </remarks>
  TJpegFrame = class
  private
    FImageWidth: Integer;
    FImageHeight: Integer;
    FPrecision: Integer;
    FComponentCount: Integer;
    FComponents: TArray<TJpegComponentInfo>;
    FProgressive: Boolean;
    FArithmetic: Boolean;
    FSawJfif: Boolean;
    FSawAdobe: Boolean;
    FAdobeTransform: Integer;
    FRestartInterval: Integer;
    FColorSpace: TJpegColorSpace;
    FMaxHorizontal: Integer;
    FMaxVertical: Integer;
    FTotalMcuRows: Integer;
    FHasMultipleScans: Boolean;
    FQuantization: array[0..JPEG_QUANTIZATION_TABLES - 1] of TJpegQuantizationTable;
    FDcDefinitions: array[0..JPEG_HUFFMAN_TABLES - 1] of TJpegHuffmanDefinition;
    FAcDefinitions: array[0..JPEG_HUFFMAN_TABLES - 1] of TJpegHuffmanDefinition;
    FScan: TJpegScanInfo;
    function GetScan: PJpegScanInfo;
    function GetComponentByIndex(AIndex: Integer): PJpegComponentInfo;
    function GetScanComponent(ASlot: Integer): PJpegComponentInfo;
    function GetDcDefinition(ATable: Integer): PJpegHuffmanDefinition;
    function GetAcDefinition(ATable: Integer): PJpegHuffmanDefinition;
    function GetQuantization(ATable: Integer): PJpegQuantizationTable;
    class function DivideRoundUp(ADividend, ADivisor: Integer): Integer; static; inline;
  public
    /// <summary>
    ///   Marker of start of image: what the previous image said is forgotten
    ///   (the tables are not: a stream can use tables of the one before)
    /// </summary>
    procedure StartOfImage;

    /// <summary>
    ///   Keeps what the frame header says (SOFn)
    /// </summary>
    procedure SetFrameHeader(AWidth, AHeight, APrecision, AComponentCount: Integer;
      AProgressive, AArithmetic: Boolean);

    /// <summary>
    ///   Checks the frame header and works out the size in blocks of every
    ///   component; called when the first scan header is read
    /// </summary>
    /// <exception cref="EJpegDecodeException">
    ///   The image is too big, the precision is not 8 bits, there are too many
    ///   components or a sampling factor is out of range
    /// </exception>
    procedure PrepareGeometry;

    /// <summary>
    ///   Chooses the color space of the stream from the markers and the
    ///   components (default_decompress_parms)
    /// </summary>
    procedure ChooseColorSpace;

    /// <summary>
    ///   Works out the MCU of the scan that is being read
    /// </summary>
    /// <exception cref="EJpegDecodeException">A MCU has more than 10 blocks</exception>
    procedure PrepareScan;

    /// <summary>
    ///   The components of the scan that start now keep the quantization table
    ///   that is defined at this moment
    /// </summary>
    /// <exception cref="EJpegDecodeException">The table is not defined</exception>
    procedure LatchQuantizationTables;

    property ImageWidth: Integer read FImageWidth;
    property ImageHeight: Integer read FImageHeight;
    property Precision: Integer read FPrecision;
    property ComponentCount: Integer read FComponentCount;
    property IsProgressive: Boolean read FProgressive;
    property IsArithmetic: Boolean read FArithmetic;
    property SawJfif: Boolean read FSawJfif write FSawJfif;
    property SawAdobe: Boolean read FSawAdobe write FSawAdobe;
    property AdobeTransform: Integer read FAdobeTransform write FAdobeTransform;
    property RestartInterval: Integer read FRestartInterval write FRestartInterval;
    property ColorSpace: TJpegColorSpace read FColorSpace;
    property MaxHorizontal: Integer read FMaxHorizontal;
    property MaxVertical: Integer read FMaxVertical;

    /// <summary>
    ///   Rows of MCUs of a scan with all the components
    /// </summary>
    property TotalMcuRows: Integer read FTotalMcuRows;

    /// <summary>
    ///   True when the image is in more than one scan or in a progressive
    ///   scan, so that all the coefficients are needed before the first pixel
    /// </summary>
    property HasMultipleScans: Boolean read FHasMultipleScans;

    /// <summary>The scan that is being read</summary>
    property Scan: PJpegScanInfo read GetScan;

    property ComponentByIndex[AIndex: Integer]: PJpegComponentInfo read GetComponentByIndex;
    property ScanComponent[ASlot: Integer]: PJpegComponentInfo read GetScanComponent;
    property DcDefinition[ATable: Integer]: PJpegHuffmanDefinition read GetDcDefinition;
    property AcDefinition[ATable: Integer]: PJpegHuffmanDefinition read GetAcDefinition;
    property Quantization[ATable: Integer]: PJpegQuantizationTable read GetQuantization;
  end;

implementation

{ TJpegFrame }

class function TJpegFrame.DivideRoundUp(ADividend, ADivisor: Integer): Integer;
begin
  Result := (ADividend + ADivisor - 1) div ADivisor;
end;

function TJpegFrame.GetScan: PJpegScanInfo;
begin
  Result := @FScan;
end;

function TJpegFrame.GetComponentByIndex(AIndex: Integer): PJpegComponentInfo;
begin
  Result := @FComponents[AIndex];
end;

function TJpegFrame.GetScanComponent(ASlot: Integer): PJpegComponentInfo;
begin
  Result := @FComponents[FScan.Components[ASlot]];
end;

function TJpegFrame.GetDcDefinition(ATable: Integer): PJpegHuffmanDefinition;
begin
  Result := @FDcDefinitions[ATable];
end;

function TJpegFrame.GetAcDefinition(ATable: Integer): PJpegHuffmanDefinition;
begin
  Result := @FAcDefinitions[ATable];
end;

function TJpegFrame.GetQuantization(ATable: Integer): PJpegQuantizationTable;
begin
  Result := @FQuantization[ATable];
end;

procedure TJpegFrame.StartOfImage;
begin
  FRestartInterval := 0;
  FColorSpace := jcsUnknown;
  FSawJfif := False;
  FSawAdobe := False;
  FAdobeTransform := 0;
end;

procedure TJpegFrame.SetFrameHeader(AWidth, AHeight, APrecision,
  AComponentCount: Integer; AProgressive, AArithmetic: Boolean);
var
  LIndex: Integer;
begin
  FImageWidth := AWidth;
  FImageHeight := AHeight;
  FPrecision := APrecision;
  FComponentCount := AComponentCount;
  FProgressive := AProgressive;
  FArithmetic := AArithmetic;
  FComponents := nil;
  SetLength(FComponents, AComponentCount);
  for LIndex := 0 to AComponentCount - 1 do
  begin
    FComponents[LIndex] := Default(TJpegComponentInfo);
    FComponents[LIndex].Index := LIndex;
  end;
end;

procedure TJpegFrame.PrepareGeometry;
var
  LIndex: Integer;
  LComponent: PJpegComponentInfo;
begin
  if (FImageHeight > JPEG_MAX_IMAGE_DIMENSION) or
     (FImageWidth > JPEG_MAX_IMAGE_DIMENSION) then
    EJpegDecodeException.Fail(jdeImageTooBig);
  if FPrecision <> JPEG_SAMPLE_PRECISION then
    EJpegDecodeException.Fail(jdeBadPrecision);
  if FComponentCount > JPEG_MAX_COMPONENTS then
    EJpegDecodeException.Fail(jdeBadComponentCount);

  FMaxHorizontal := 1;
  FMaxVertical := 1;
  for LIndex := 0 to FComponentCount - 1 do
  begin
    LComponent := @FComponents[LIndex];
    if (LComponent^.Horizontal <= 0) or
       (LComponent^.Horizontal > JPEG_MAX_SAMPLING_FACTOR) or
       (LComponent^.Vertical <= 0) or
       (LComponent^.Vertical > JPEG_MAX_SAMPLING_FACTOR) then
      EJpegDecodeException.Fail(jdeBadSampling);
    if FMaxHorizontal < LComponent^.Horizontal then
      FMaxHorizontal := LComponent^.Horizontal;
    if FMaxVertical < LComponent^.Vertical then
      FMaxVertical := LComponent^.Vertical;
  end;

  for LIndex := 0 to FComponentCount - 1 do
  begin
    LComponent := @FComponents[LIndex];
    LComponent^.WidthInBlocks := DivideRoundUp(FImageWidth * LComponent^.Horizontal,
      FMaxHorizontal * JPEG_DCT_SIZE);
    LComponent^.HeightInBlocks := DivideRoundUp(FImageHeight * LComponent^.Vertical,
      FMaxVertical * JPEG_DCT_SIZE);
    LComponent^.DownsampledWidth := DivideRoundUp(FImageWidth * LComponent^.Horizontal,
      FMaxHorizontal);
    LComponent^.DownsampledHeight := DivideRoundUp(FImageHeight * LComponent^.Vertical,
      FMaxVertical);
    LComponent^.HasQuantization := False;
  end;

  FTotalMcuRows := DivideRoundUp(FImageHeight, FMaxVertical * JPEG_DCT_SIZE);

  FHasMultipleScans := (FScan.ComponentCount < FComponentCount) or FProgressive;
end;

procedure TJpegFrame.ChooseColorSpace;
var
  LFirst: Integer;
  LSecond: Integer;
  LThird: Integer;
begin
  case FComponentCount of
    1:
      FColorSpace := jcsGrayscale;
    3:
      if FSawJfif then
        FColorSpace := jcsYCbCr
      else if FSawAdobe then
      begin
        case FAdobeTransform of
          0: FColorSpace := jcsRgb;
        else
          // 1 is YCbCr; any other code is a mistake that is read as YCbCr
          FColorSpace := jcsYCbCr;
        end;
      end
      else
      begin
        // No marker: the identifiers of the components tell
        LFirst := FComponents[0].Id;
        LSecond := FComponents[1].Id;
        LThird := FComponents[2].Id;
        if (LFirst = 82) and (LSecond = 71) and (LThird = 66) then
          FColorSpace := jcsRgb
        else
          FColorSpace := jcsYCbCr;
      end;
    4:
      if FSawAdobe then
      begin
        case FAdobeTransform of
          0: FColorSpace := jcsCmyk;
        else
          // 2 is YCCK; any other code is a mistake that is read as YCCK
          FColorSpace := jcsYcck;
        end;
      end
      else
        FColorSpace := jcsCmyk;
  else
    FColorSpace := jcsUnknown;
  end;
end;

procedure TJpegFrame.PrepareScan;
var
  LSlot: Integer;
  LComponent: PJpegComponentInfo;
  LRemaining: Integer;
  LRest: Integer;
begin
  if FScan.ComponentCount = 1 then
  begin
    // One component: the MCU is one block and the scan goes over the blocks
    // of the component only
    LComponent := GetScanComponent(0);
    FScan.McusPerRow := LComponent^.WidthInBlocks;
    FScan.McuRowsInScan := LComponent^.HeightInBlocks;
    LComponent^.McuWidth := 1;
    LComponent^.McuHeight := 1;
    LComponent^.McuBlocks := 1;
    LComponent^.LastColumnWidth := 1;
    LRest := LComponent^.HeightInBlocks mod LComponent^.Vertical;
    if LRest = 0 then
      LRest := LComponent^.Vertical;
    LComponent^.LastRowHeight := LRest;
    FScan.BlocksInMcu := 1;
    FScan.McuMembership[0] := 0;
  end
  else
  begin
    FScan.McusPerRow := DivideRoundUp(FImageWidth, FMaxHorizontal * JPEG_DCT_SIZE);
    FScan.McuRowsInScan := DivideRoundUp(FImageHeight, FMaxVertical * JPEG_DCT_SIZE);
    FScan.BlocksInMcu := 0;
    for LSlot := 0 to FScan.ComponentCount - 1 do
    begin
      LComponent := GetScanComponent(LSlot);
      LComponent^.McuWidth := LComponent^.Horizontal;
      LComponent^.McuHeight := LComponent^.Vertical;
      LComponent^.McuBlocks := LComponent^.McuWidth * LComponent^.McuHeight;

      LRest := LComponent^.WidthInBlocks mod LComponent^.McuWidth;
      if LRest = 0 then
        LRest := LComponent^.McuWidth;
      LComponent^.LastColumnWidth := LRest;
      LRest := LComponent^.HeightInBlocks mod LComponent^.McuHeight;
      if LRest = 0 then
        LRest := LComponent^.McuHeight;
      LComponent^.LastRowHeight := LRest;

      LRemaining := LComponent^.McuBlocks;
      if FScan.BlocksInMcu + LRemaining > JPEG_MAX_BLOCKS_IN_MCU then
        EJpegDecodeException.Fail(jdeBadMcuSize);
      while LRemaining > 0 do
      begin
        Dec(LRemaining);
        FScan.McuMembership[FScan.BlocksInMcu] := LSlot;
        Inc(FScan.BlocksInMcu);
      end;
    end;
  end;
end;

procedure TJpegFrame.LatchQuantizationTables;
var
  LSlot: Integer;
  LComponent: PJpegComponentInfo;
  LNumber: Integer;
  LIndex: Integer;
begin
  for LSlot := 0 to FScan.ComponentCount - 1 do
  begin
    LComponent := GetScanComponent(LSlot);
    if LComponent^.HasQuantization then
      Continue;
    LNumber := LComponent^.QuantizationNumber;
    if (LNumber < 0) or (LNumber >= JPEG_QUANTIZATION_TABLES) or
       not FQuantization[LNumber].Defined then
      EJpegDecodeException.Fail(jdeMissingQuantizationTable);
    for LIndex := 0 to JPEG_DCT_SIZE2 - 1 do
      LComponent^.Quantization[LIndex] := FQuantization[LNumber].Values[LIndex];
    LComponent^.HasQuantization := True;
  end;
end;

end.
