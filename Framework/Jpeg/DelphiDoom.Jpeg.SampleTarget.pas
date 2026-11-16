{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - turns each MCU into samples as soon as it is decoded     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.SampleTarget;

interface

uses
  DelphiDoom.Jpeg.ComponentBuffers, DelphiDoom.Jpeg.EntropyDecoder,
  DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.InverseDct, DelphiDoom.Jpeg.McuTarget,
  DelphiDoom.Jpeg.Types;

type
  /// <summary>
  ///   The blocks of a MCU are in a buffer of the size of one MCU that is
  ///   cleared before each MCU; when the MCU is decoded its blocks go through
  ///   the inverse DCT into the plane of their component. The blocks that
  ///   complete a MCU but are not part of the image are decoded and dropped
  /// </summary>
  /// <remarks>
  ///   The decompress_onepass of jdcoefct.c of libjpeg 6b
  /// </remarks>
  TJpegSampleTarget = class(TInterfacedObject, IJpegMcuTarget)
  private
    FFrame: TJpegFrame;
    FBuffers: TArray<TJpegComponentBuffers>;
    FInverseDct: IJpegInverseDct;
    FMcu: array[0..JPEG_MAX_BLOCKS_IN_MCU - 1] of TJpegBlock;
  public
    constructor Create(AFrame: TJpegFrame; const ABuffers: TArray<TJpegComponentBuffers>;
      const AInverseDct: IJpegInverseDct);

    procedure BeginMcu(AMcuRow, AMcuColumn: Integer; var ABlocks: TJpegBlockPointers);
    procedure EndMcu(AMcuRow, AMcuColumn: Integer);
  end;

implementation

{$POINTERMATH ON}

{ TJpegSampleTarget }

constructor TJpegSampleTarget.Create(AFrame: TJpegFrame;
  const ABuffers: TArray<TJpegComponentBuffers>; const AInverseDct: IJpegInverseDct);
begin
  inherited Create;
  FFrame := AFrame;
  FBuffers := ABuffers;
  FInverseDct := AInverseDct;
end;

procedure TJpegSampleTarget.BeginMcu(AMcuRow, AMcuColumn: Integer;
  var ABlocks: TJpegBlockPointers);
var
  LBlock: Integer;
begin
  FillChar(FMcu, FFrame.Scan^.BlocksInMcu * SizeOf(TJpegBlock), 0);
  for LBlock := 0 to FFrame.Scan^.BlocksInMcu - 1 do
    ABlocks[LBlock] := @FMcu[LBlock];
end;

procedure TJpegSampleTarget.EndMcu(AMcuRow, AMcuColumn: Integer);
var
  LSlot: Integer;
  LComponent: PJpegComponentInfo;
  LBuffers: TJpegComponentBuffers;
  LBlock: Integer;
  LRow: Integer;
  LColumn: Integer;
  LBlockRow: Integer;
  LBlockColumn: Integer;
begin
  LBlock := 0;
  for LSlot := 0 to FFrame.Scan^.ComponentCount - 1 do
  begin
    LComponent := FFrame.ScanComponent[LSlot];
    LBuffers := FBuffers[LComponent^.Index];
    for LRow := 0 to LComponent^.McuHeight - 1 do
      for LColumn := 0 to LComponent^.McuWidth - 1 do
      begin
        LBlockRow := AMcuRow * LComponent^.McuHeight + LRow;
        LBlockColumn := AMcuColumn * LComponent^.McuWidth + LColumn;
        // Only the blocks that are inside the image have samples
        if (LBlockRow < LComponent^.HeightInBlocks) and
           (LBlockColumn < LComponent^.WidthInBlocks) then
          FInverseDct.Transform(FMcu[LBlock], LComponent^.Quantization,
            LBuffers.PlaneRow(LBlockRow * JPEG_DCT_SIZE) + LBlockColumn * JPEG_DCT_SIZE,
            LBuffers.PlaneStride);
        Inc(LBlock);
      end;
  end;
end;

end.
