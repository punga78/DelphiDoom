{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - smooth upsampling to twice the width                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.FancyUpsamplerH2V1;

interface

uses
  DelphiDoom.Jpeg.RowUpsampler;

type
  /// <summary>
  ///   Doubles the width with a triangle filter: each new sample is 3/4 of
  ///   the nearest sample of the row and 1/4 of the next nearest (h2v1_fancy_upsample)
  /// </summary>
  TJpegFancyUpsamplerH2V1 = class(TInterfacedObject, IJpegRowUpsampler)
  private
    FInputWidth: Integer;
  public
    /// <param name="AInputWidth">The number of samples of the row; more than 2</param>
    constructor Create(AInputWidth: Integer);

    procedure UpsampleRow(ARow, ANeighbour, AOutput: PByte);
  end;

implementation

{$POINTERMATH ON}

{ TJpegFancyUpsamplerH2V1 }

constructor TJpegFancyUpsamplerH2V1.Create(AInputWidth: Integer);
begin
  inherited Create;
  FInputWidth := AInputWidth;
end;

procedure TJpegFancyUpsamplerH2V1.UpsampleRow(ARow, ANeighbour, AOutput: PByte);
var
  LIndex: Integer;
  LValue: Integer;
  LLast: Integer;
begin
  // The first sample is not filtered
  LValue := ARow[0];
  AOutput[0] := Byte(LValue);
  AOutput[1] := Byte((LValue * 3 + ARow[1] + 2) shr 2);

  for LIndex := 1 to FInputWidth - 2 do
  begin
    LValue := ARow[LIndex] * 3;
    AOutput[LIndex * 2] := Byte((LValue + ARow[LIndex - 1] + 1) shr 2);
    AOutput[LIndex * 2 + 1] := Byte((LValue + ARow[LIndex + 1] + 2) shr 2);
  end;

  // Nor is the last one
  LLast := FInputWidth - 1;
  LValue := ARow[LLast];
  AOutput[LLast * 2] := Byte((LValue * 3 + ARow[LLast - 1] + 1) shr 2);
  AOutput[LLast * 2 + 1] := Byte(LValue);
end;

end.
