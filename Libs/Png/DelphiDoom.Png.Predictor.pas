{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - Paeth predictor                                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Predictor;

interface

type
  /// <summary>
  ///   The predictor shared by the filter 4 of the encoder and of the decoder
  /// </summary>
  TPngPredictor = class sealed
  public
    /// <summary>
    ///   Paeth predictor: the one of ALeft, AAbove and AUpperLeft that is
    ///   closest to ALeft + AAbove - AUpperLeft (ties go to ALeft, then to
    ///   AAbove)
    /// </summary>
    class function Paeth(ALeft, AAbove, AUpperLeft: Integer): Integer; static;
  end;

implementation

{ TPngPredictor }

class function TPngPredictor.Paeth(ALeft, AAbove, AUpperLeft: Integer): Integer;
var
  LEstimate: Integer;
  LDistanceLeft: Integer;
  LDistanceAbove: Integer;
  LDistanceUpperLeft: Integer;
begin
  LEstimate := ALeft + AAbove - AUpperLeft;
  LDistanceLeft := Abs(LEstimate - ALeft);
  LDistanceAbove := Abs(LEstimate - AAbove);
  LDistanceUpperLeft := Abs(LEstimate - AUpperLeft);

  if (LDistanceLeft <= LDistanceAbove) and (LDistanceLeft <= LDistanceUpperLeft) then
    Result := ALeft
  else if LDistanceAbove <= LDistanceUpperLeft then
    Result := AAbove
  else
    Result := AUpperLeft;
end;

end.
