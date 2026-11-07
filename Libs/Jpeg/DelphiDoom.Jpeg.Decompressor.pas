{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - decodes a stream into pixels                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.Decompressor;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.BitReader, DelphiDoom.Jpeg.ByteSource,
  DelphiDoom.Jpeg.ComponentBuffers, DelphiDoom.Jpeg.EntropyDecoder,
  DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.InverseDct, DelphiDoom.Jpeg.MarkerReader,
  DelphiDoom.Jpeg.McuTarget, DelphiDoom.Jpeg.ProgressiveDecoder;

type
  /// <summary>
  ///   Reads the headers of a JPEG stream and decodes the image: scans,
  ///   inverse DCT, widening of the components, conversion of the colors
  /// </summary>
  /// <remarks>
  ///   The control that libjpeg 6b spreads over the master, the input
  ///   controller, the coefficient controller and the main controller (jdmaster.c,
  ///   jdinput.c, jdcoefct.c, jdmainct.c, jdapimin.c, jdapistd.c) for the
  ///   settings that the engine uses: the whole image at its own size, 8 bit
  ///   samples, accurate inverse DCT, smooth upsampling, smoothing of the
  ///   blocks, gray or RGB output. libjpeg decodes a strip of the image at a
  ///   time and keeps a few strips of rows; here the planes of the components
  ///   hold the whole image and the rows are made at the end. The result is
  ///   the same, and so are the errors and the order in which they are found
  /// </remarks>
  TJpegDecompressor = class
  private
    FSource: TJpegByteSource;
    FFrame: TJpegFrame;
    FMarkers: TJpegMarkerReader;
    FBits: TJpegBitReader;
    FEntropy: IJpegEntropyDecoder;
    FProgressive: TJpegProgressiveDecoder;
    FBuffers: TArray<TJpegComponentBuffers>;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetOutputComponents: Integer;
    class function RoundUp(AValue, AMultiple: Integer): Integer; static; inline;
    procedure StartInputPass;
    procedure DecodeScan(const ATarget: IJpegMcuTarget);
    procedure DecodeAllScans(const ATarget: IJpegMcuTarget);
    procedure TransformCoefficients(const AInverseDct: IJpegInverseDct);
    procedure FreeBuffers;
  public
    /// <summary>
    ///   The stream is the ASize bytes at AData, which must stay where they
    ///   are while the decompressor is used
    /// </summary>
    constructor Create(AData: Pointer; ASize: Integer);
    destructor Destroy; override;

    /// <summary>
    ///   Reads the headers up to the first scan: the size and the color
    ///   space of the image
    /// </summary>
    /// <exception cref="EJpegDecodeException">The stream has no image or is not supported</exception>
    procedure ReadHeader;

    /// <summary>
    ///   Decodes the image into AOutput, a row after the other at AStride
    ///   bytes (Width * OutputComponents bytes are written in each). ReadHeader
    ///   comes first
    /// </summary>
    /// <exception cref="EJpegDecodeException">
    ///   The stream is wrong, cut, or has something that cannot be decoded
    /// </exception>
    procedure Decompress(AOutput: PByte; AStride: Integer);

    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;

    /// <summary>
    ///   Bytes of a pixel of the output: 1 for gray, 3 (blue, green, red) for
    ///   the others
    /// </summary>
    property OutputComponents: Integer read GetOutputComponents;
  end;

implementation

uses
  DelphiDoom.Jpeg.BlockSmoother, DelphiDoom.Jpeg.CoefficientTarget,
  DelphiDoom.Jpeg.ColorConverter, DelphiDoom.Jpeg.ColorConverterFactory,
  DelphiDoom.Jpeg.RowRenderer, DelphiDoom.Jpeg.SampleTarget,
  DelphiDoom.Jpeg.SequentialDecoder, DelphiDoom.Jpeg.SlowInverseDct,
  DelphiDoom.Jpeg.Types;

{$POINTERMATH ON}

{ TJpegDecompressor }

constructor TJpegDecompressor.Create(AData: Pointer; ASize: Integer);
begin
  inherited Create;
  FSource := TJpegByteSource.Create(AData, ASize);
  FFrame := TJpegFrame.Create;
  FMarkers := TJpegMarkerReader.Create(FSource, FFrame);
  FBits := TJpegBitReader.Create(FSource, FMarkers);
end;

destructor TJpegDecompressor.Destroy;
begin
  FEntropy := nil;
  FreeBuffers;
  FBits.Free;
  FMarkers.Free;
  FFrame.Free;
  FSource.Free;
  inherited Destroy;
end;

procedure TJpegDecompressor.FreeBuffers;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FBuffers) do
    FBuffers[LIndex].Free;
  FBuffers := nil;
end;

class function TJpegDecompressor.RoundUp(AValue, AMultiple: Integer): Integer;
begin
  Result := (AValue + AMultiple - 1) div AMultiple * AMultiple;
end;

function TJpegDecompressor.GetWidth: Integer;
begin
  Result := FFrame.ImageWidth;
end;

function TJpegDecompressor.GetHeight: Integer;
begin
  Result := FFrame.ImageHeight;
end;

function TJpegDecompressor.GetOutputComponents: Integer;
begin
  Result := TJpegColorConverterFactory.OutputComponentsOf(FFrame);
end;

procedure TJpegDecompressor.ReadHeader;
begin
  case FMarkers.ReadMarkers of
    jmsStartOfScan:
      begin
        FFrame.PrepareGeometry;
        FFrame.ChooseColorSpace;
      end;
    jmsEndOfImage:
      // No scan: a frame that is not followed by one, or no frame at all
      if FMarkers.SawFrame then
        EJpegDecodeException.Fail(jdeFrameWithoutScan)
      else
        EJpegDecodeException.Fail(jdeNoImage);
  end;
end;

procedure TJpegDecompressor.StartInputPass;
begin
  FFrame.PrepareScan;
  FFrame.LatchQuantizationTables;
  FEntropy.StartScan;
end;

procedure TJpegDecompressor.DecodeScan(const ATarget: IJpegMcuTarget);
var
  LScan: PJpegScanInfo;
  LRow: Integer;
  LColumn: Integer;
  LBlocks: TJpegBlockPointers;
begin
  LScan := FFrame.Scan;
  for LRow := 0 to LScan^.McuRowsInScan - 1 do
    for LColumn := 0 to LScan^.McusPerRow - 1 do
    begin
      ATarget.BeginMcu(LRow, LColumn, LBlocks);
      FEntropy.DecodeMcu(LBlocks);
      ATarget.EndMcu(LRow, LColumn);
    end;
end;

procedure TJpegDecompressor.DecodeAllScans(const ATarget: IJpegMcuTarget);
begin
  // The scan that was started, then the ones that follow until the end of
  // the image
  DecodeScan(ATarget);
  while FMarkers.ReadMarkers = jmsStartOfScan do
  begin
    StartInputPass;
    DecodeScan(ATarget);
  end;
end;

procedure TJpegDecompressor.TransformCoefficients(const AInverseDct: IJpegInverseDct);
var
  LSmoother: TJpegBlockSmoother;
  LIndex: Integer;
  LComponent: PJpegComponentInfo;
  LRow: Integer;
  LColumn: Integer;
  LWorkspace: TJpegBlock;
  LPlane: PByte;
begin
  // Only a progressive image can be smoothed
  LSmoother := nil;
  if FFrame.IsProgressive then
    LSmoother := TJpegBlockSmoother.TryCreate(FFrame, FProgressive);
  try
    for LIndex := 0 to FFrame.ComponentCount - 1 do
    begin
      LComponent := FFrame.ComponentByIndex[LIndex];
      for LRow := 0 to LComponent^.HeightInBlocks - 1 do
        for LColumn := 0 to LComponent^.WidthInBlocks - 1 do
        begin
          LPlane := FBuffers[LIndex].PlaneRow(LRow * JPEG_DCT_SIZE) + LColumn * JPEG_DCT_SIZE;
          if Assigned(LSmoother) then
          begin
            LSmoother.SmoothBlock(LIndex, LComponent, FBuffers[LIndex], LRow, LColumn,
              LWorkspace);
            AInverseDct.Transform(LWorkspace, LComponent^.Quantization, LPlane,
              FBuffers[LIndex].PlaneStride);
          end
          else
            AInverseDct.Transform(FBuffers[LIndex].Block(LRow, LColumn)^,
              LComponent^.Quantization, LPlane, FBuffers[LIndex].PlaneStride);
        end;
    end;
  finally
    LSmoother.Free;
  end;
end;

procedure TJpegDecompressor.Decompress(AOutput: PByte; AStride: Integer);
var
  LConverter: IJpegColorConverter;
  LRenderer: TJpegRowRenderer;
  LInverseDct: IJpegInverseDct;
  LComponent: PJpegComponentInfo;
  LIndex: Integer;
  LRow: Integer;
  LMultipleScans: Boolean;
begin
  // The choices that can fail, in the order that libjpeg makes them: the
  // conversion of the colors, the upsampling, the coding
  LConverter := TJpegColorConverterFactory.Select(FFrame);

  FreeBuffers;
  SetLength(FBuffers, FFrame.ComponentCount);
  for LIndex := 0 to FFrame.ComponentCount - 1 do
  begin
    LComponent := FFrame.ComponentByIndex[LIndex];
    FBuffers[LIndex] := TJpegComponentBuffers.Create(LComponent^.WidthInBlocks,
      LComponent^.HeightInBlocks);
  end;

  LRenderer := TJpegRowRenderer.Create(FFrame, FBuffers, LConverter);
  try
    LInverseDct := TJpegSlowInverseDct.Create;

    if FFrame.IsArithmetic then
      EJpegDecodeException.Fail(jdeArithmeticCoding);
    if FFrame.IsProgressive then
    begin
      FProgressive := TJpegProgressiveDecoder.Create(FFrame, FMarkers, FBits);
      FEntropy := FProgressive;
    end
    else
      FEntropy := TJpegSequentialDecoder.Create(FFrame, FMarkers, FBits);

    // Memory: the planes, and the coefficients when the image is in more
    // than one scan (they are needed all together)
    LMultipleScans := FFrame.HasMultipleScans;
    for LIndex := 0 to FFrame.ComponentCount - 1 do
    begin
      LComponent := FFrame.ComponentByIndex[LIndex];
      FBuffers[LIndex].AllocatePlane;
      if LMultipleScans then
        FBuffers[LIndex].AllocateCoefficients(
          RoundUp(LComponent^.WidthInBlocks, LComponent^.Horizontal),
          RoundUp(LComponent^.HeightInBlocks, LComponent^.Vertical))
      else
        // A component that the scan does not have (a scan can name a
        // component twice) is mid-gray, as the zero blocks of an image in
        // many scans are
        FBuffers[LIndex].FillPlane(128);
    end;

    StartInputPass;
    if LMultipleScans then
    begin
      DecodeAllScans(TJpegCoefficientTarget.Create(FFrame, FBuffers));
      TransformCoefficients(LInverseDct);
    end
    else
      DecodeScan(TJpegSampleTarget.Create(FFrame, FBuffers, LInverseDct));

    for LRow := 0 to FFrame.ImageHeight - 1 do
      LRenderer.RenderRow(LRow, AOutput + LRow * AStride);
  finally
    LRenderer.Free;
  end;
end;

end.
