{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - keeps the coefficients of every block                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.CoefficientTarget;

interface

uses
  DelphiDoom.Jpeg.ComponentBuffers, DelphiDoom.Jpeg.EntropyDecoder,
  DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.McuTarget;

type
  /// <summary>
  ///   The blocks of a MCU are the blocks of the component in the memory of
  ///   the image (the coefficients of the whole image, which the scans of an
  ///   image in many scans fill one after the other)
  /// </summary>
  /// <remarks>
  ///   The consume_data of jdcoefct.c of libjpeg 6b
  /// </remarks>
  TJpegCoefficientTarget = class(TInterfacedObject, IJpegMcuTarget)
  private
    FFrame: TJpegFrame;
    FBuffers: TArray<TJpegComponentBuffers>;
  public
    constructor Create(AFrame: TJpegFrame; const ABuffers: TArray<TJpegComponentBuffers>);

    procedure BeginMcu(AMcuRow, AMcuColumn: Integer; var ABlocks: TJpegBlockPointers);
    procedure EndMcu(AMcuRow, AMcuColumn: Integer);
  end;

implementation

uses
  DelphiDoom.Jpeg.Types;

{ TJpegCoefficientTarget }

constructor TJpegCoefficientTarget.Create(AFrame: TJpegFrame;
  const ABuffers: TArray<TJpegComponentBuffers>);
begin
  inherited Create;
  FFrame := AFrame;
  FBuffers := ABuffers;
end;

procedure TJpegCoefficientTarget.BeginMcu(AMcuRow, AMcuColumn: Integer;
  var ABlocks: TJpegBlockPointers);
var
  LSlot: Integer;
  LComponent: PJpegComponentInfo;
  LBlock: Integer;
  LRow: Integer;
  LColumn: Integer;
begin
  LBlock := 0;
  for LSlot := 0 to FFrame.Scan^.ComponentCount - 1 do
  begin
    LComponent := FFrame.ScanComponent[LSlot];
    for LRow := 0 to LComponent^.McuHeight - 1 do
      for LColumn := 0 to LComponent^.McuWidth - 1 do
      begin
        ABlocks[LBlock] := FBuffers[LComponent^.Index].Block(
          AMcuRow * LComponent^.McuHeight + LRow,
          AMcuColumn * LComponent^.McuWidth + LColumn);
        Inc(LBlock);
      end;
  end;
end;

procedure TJpegCoefficientTarget.EndMcu(AMcuRow, AMcuColumn: Integer);
begin
  // The coefficients are where they have to be
end;

end.
