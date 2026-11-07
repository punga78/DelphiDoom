{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - smooth upsampling to twice the width and height          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.FancyUpsamplerH2V2;

interface

uses
  DelphiDoom.Jpeg.RowUpsampler;

type
  /// <summary>
  ///   Doubles width and height with a triangle filter: each new sample is
  ///   9/16 of the nearest sample, 3/16 of each of the two neighbours that
  ///   are nearest in one direction and 1/16 of the corner (h2v2_fancy_upsample).
  ///   A row of the result needs the row of the component and the one above
  ///   it (first row of the pair) or below it (second)
  /// </summary>
  TJpegFancyUpsamplerH2V2 = class(TInterfacedObject, IJpegRowUpsampler)
  private
    FInputWidth: Integer;
  public
    /// <param name="AInputWidth">The number of samples of the row; more than 2</param>
    constructor Create(AInputWidth: Integer);

    procedure UpsampleRow(ARow, ANeighbour, AOutput: PByte);
  end;

implementation

{$POINTERMATH ON}

{ TJpegFancyUpsamplerH2V2 }

constructor TJpegFancyUpsamplerH2V2.Create(AInputWidth: Integer);
begin
  inherited Create;
  FInputWidth := AInputWidth;
end;

procedure TJpegFancyUpsamplerH2V2.UpsampleRow(ARow, ANeighbour, AOutput: PByte);
var
  LIndex: Integer;
  LLast: Integer;
  LThis: Integer;
  LPrevious: Integer;
  LNext: Integer;
begin
  // The sum of a column is 3 times the sample of the row plus the sample of
  // the neighbour row
  LThis := ARow[0] * 3 + ANeighbour[0];
  LNext := ARow[1] * 3 + ANeighbour[1];

  // The first sample is not filtered across
  AOutput[0] := Byte((LThis * 4 + 8) shr 4);
  AOutput[1] := Byte((LThis * 3 + LNext + 7) shr 4);
  LPrevious := LThis;
  LThis := LNext;

  for LIndex := 2 to FInputWidth - 1 do
  begin
    LNext := ARow[LIndex] * 3 + ANeighbour[LIndex];
    AOutput[(LIndex - 1) * 2] := Byte((LThis * 3 + LPrevious + 8) shr 4);
    AOutput[(LIndex - 1) * 2 + 1] := Byte((LThis * 3 + LNext + 7) shr 4);
    LPrevious := LThis;
    LThis := LNext;
  end;

  // Nor is the last one
  LLast := FInputWidth - 1;
  AOutput[LLast * 2] := Byte((LThis * 3 + LPrevious + 8) shr 4);
  AOutput[LLast * 2 + 1] := Byte((LThis * 4 + 7) shr 4);
end;

end.
