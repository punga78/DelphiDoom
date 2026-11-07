{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - decoder of sequential (baseline) scans                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.SequentialDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Jpeg.BitReader, DelphiDoom.Jpeg.EntropyDecoder,
  DelphiDoom.Jpeg.EntropyDecoderBase, DelphiDoom.Jpeg.Frame,
  DelphiDoom.Jpeg.HuffmanTable, DelphiDoom.Jpeg.MarkerReader;

type
  /// <summary>
  ///   Decodes a scan whose blocks are written whole, one after the other:
  ///   the difference of the DC and the run lengths of the AC (Huffman coding)
  /// </summary>
  /// <remarks>
  ///   Port of decode_mcu of jdhuff.c of libjpeg 6b. All the components are
  ///   decoded to their full size (the decoder does not scale the image), so
  ///   no AC coefficient is skipped
  /// </remarks>
  TJpegSequentialDecoder = class(TJpegEntropyDecoderBase)
  private
    FDcTables: array[0..3] of TJpegHuffmanTable;
    FAcTables: array[0..3] of TJpegHuffmanTable;
    procedure FreeTables;
  protected
    procedure DecodeBlocks(const ABlocks: TJpegBlockPointers); override;
  public
    destructor Destroy; override;

    procedure StartScan; override;
  end;

implementation

uses
  DelphiDoom.Jpeg.Types;

const
  // The value of a number of s bits that starts with 0 is negative
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

{ TJpegSequentialDecoder }

destructor TJpegSequentialDecoder.Destroy;
begin
  FreeTables;
  inherited Destroy;
end;

procedure TJpegSequentialDecoder.FreeTables;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FDcTables) do
  begin
    FreeAndNil(FDcTables[LIndex]);
    FreeAndNil(FAcTables[LIndex]);
  end;
end;

procedure TJpegSequentialDecoder.StartScan;
var
  LSlot: Integer;
  LComponent: PJpegComponentInfo;
begin
  FreeTables;
  // The parameters of a progressive scan in a sequential stream are not
  // read: there is nothing to do with them
  for LSlot := 0 to FFrame.Scan^.ComponentCount - 1 do
  begin
    LComponent := FFrame.ScanComponent[LSlot];
    FDcTables[LSlot] := BuildTable(LComponent^.DcTableNumber, True);
    FAcTables[LSlot] := BuildTable(LComponent^.AcTableNumber, False);
  end;
  StartCommon;
end;

procedure TJpegSequentialDecoder.DecodeBlocks(const ABlocks: TJpegBlockPointers);
var
  LBlock: Integer;
  LSlot: Integer;
  LBits: Integer;
  LValue: Integer;
  LRun: Integer;
  LIndex: Integer;
  LCoefficients: PJpegBlock;
  LAcTable: TJpegHuffmanTable;
begin
  if FBits.InsufficientData then
    Exit;

  for LBlock := 0 to FFrame.Scan^.BlocksInMcu - 1 do
  begin
    LCoefficients := ABlocks[LBlock];
    LSlot := FFrame.Scan^.McuMembership[LBlock];

    // DC: the size of the difference, then the difference
    LBits := FBits.DecodeSymbol(FDcTables[LSlot]);
    if LBits <> 0 then
    begin
      LValue := FBits.ReadBits(LBits);
      if LValue < EXTEND_TEST[LBits] then
        LValue := LValue + EXTEND_OFFSET[LBits];
    end
    else
      LValue := 0;
    Inc(LValue, FLastDc[LSlot]);
    FLastDc[LSlot] := LValue;
    LCoefficients^[0] := LValue;

    // AC: runs of zeros followed by a coefficient, until the end of block
    LAcTable := FAcTables[LSlot];
    LIndex := 1;
    while LIndex < JPEG_DCT_SIZE2 do
    begin
      LValue := FBits.DecodeSymbol(LAcTable);
      LRun := LValue shr 4;
      LBits := LValue and 15;
      if LBits <> 0 then
      begin
        Inc(LIndex, LRun);
        LValue := FBits.ReadBits(LBits);
        if LValue < EXTEND_TEST[LBits] then
          LValue := LValue + EXTEND_OFFSET[LBits];
        LCoefficients^[JPEG_NATURAL_ORDER[LIndex]] := LValue;
      end
      else
      begin
        // 15 0: sixteen zeros; anything else: end of block
        if LRun <> 15 then
          Break;
        Inc(LIndex, 15);
      end;
      Inc(LIndex);
    end;
  end;
end;

end.
