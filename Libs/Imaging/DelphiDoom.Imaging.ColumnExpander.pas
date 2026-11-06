{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - interpolates a column to a multiple of it     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ColumnExpander;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   R_ExpandColumn (r_grow.pas): the 128 pixels of a column become 128 * factor, each one
  ///   blended with the next (the column wraps), in the same buffer
  /// </summary>
  /// <remarks>
  ///   The expansion is done in place from the end to the start, as the old code did, and for
  ///   a factor of 2 the pixels that it writes first are the ones that it reads later; the
  ///   result is the one of the old code, not the "clean" one. A buffer of 129 * factor
  ///   pixels is needed because the loop writes the 129th group
  /// </remarks>
  TImagingColumnExpander = class(TInterfacedObject, IImagingColumnExpander)
  public
    procedure Expand(var ABuffer: TImagingPixels; AFactor: Integer);
  end;

implementation

uses
  DelphiDoom.Imaging.ColorMath;

{ TImagingColumnExpander }

procedure TImagingColumnExpander.Expand(var ABuffer: TImagingPixels; AFactor: Integer);
var
  LIndex: Integer;
  LStep: Integer;
begin
  if AFactor < 1 then
    raise EImagingException.Create(SImagingBadFactor);
  if Length(ABuffer) < 129 * AFactor then
    raise EImagingException.Create(SImagingBufferTooSmall);

  for LIndex := 128 downto 0 do
    for LStep := 0 to AFactor - 1 do
      ABuffer[LIndex * AFactor + LStep] := TImagingColorMath.Average(ABuffer[LIndex and 127],
        ABuffer[(LIndex + 1) and 127], LStep * IMAGING_FRACUNIT div AFactor);
end;

end.
