{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - applies the filters to the scanlines                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Filter;

interface

{$POINTERMATH ON}

const
  // Filter types of the PNG specification
  PNG_FILTER_NONE = 0;
  PNG_FILTER_SUB = 1;
  PNG_FILTER_UP = 2;
  PNG_FILTER_AVERAGE = 3;
  PNG_FILTER_PAETH = 4;
  PNG_FILTER_COUNT = 5;

type
  /// <summary>
  ///   Filters a scanline for the encoder (the opposite of TPngUnfilter)
  /// </summary>
  TPngFilter = class sealed
  public
    /// <summary>
    ///   Writes into ADest the ACount bytes of ARow filtered with AFilter.
    ///   APrevious is the row above (all zeros for the first one) and AStride
    ///   the size of a pixel in bytes
    /// </summary>
    class procedure Apply(AFilter: Integer; ARow, APrevious, ADest: PByte;
      ACount, AStride: Integer); static;

    /// <summary>
    ///   The usual measure of how well a filtered row will compress: the sum
    ///   of the bytes taken as signed values, in absolute value. The lower
    ///   the better
    /// </summary>
    class function Score(AFiltered: PByte; ACount: Integer): Cardinal; static;
  end;

implementation

uses
  DelphiDoom.Png.Predictor;

{ TPngFilter }

class procedure TPngFilter.Apply(AFilter: Integer; ARow, APrevious,
  ADest: PByte; ACount, AStride: Integer);
var
  LIndex: Integer;
  LLeft: Integer;
  LUpperLeft: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    if LIndex >= AStride then
    begin
      LLeft := ARow[LIndex - AStride];
      LUpperLeft := APrevious[LIndex - AStride];
    end
    else
    begin
      LLeft := 0;
      LUpperLeft := 0;
    end;

    case AFilter of
      PNG_FILTER_SUB:
        ADest[LIndex] := Byte(ARow[LIndex] - LLeft);
      PNG_FILTER_UP:
        ADest[LIndex] := Byte(ARow[LIndex] - APrevious[LIndex]);
      PNG_FILTER_AVERAGE:
        ADest[LIndex] := Byte(ARow[LIndex] - ((LLeft + APrevious[LIndex]) shr 1));
      PNG_FILTER_PAETH:
        ADest[LIndex] := Byte(ARow[LIndex] -
          TPngPredictor.Paeth(LLeft, APrevious[LIndex], LUpperLeft));
    else
      ADest[LIndex] := ARow[LIndex];
    end;
  end;
end;

class function TPngFilter.Score(AFiltered: PByte; ACount: Integer): Cardinal;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to ACount - 1 do
    if AFiltered[LIndex] < 128 then
      Inc(Result, AFiltered[LIndex])
    else
      Inc(Result, 256 - AFiltered[LIndex]);
end;

end.
