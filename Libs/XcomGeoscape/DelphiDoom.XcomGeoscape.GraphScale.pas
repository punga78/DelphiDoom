{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - the vertical scale of the graphs of      }
{  GraphsState of OpenXcom                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.GraphScale;

interface

type
  /// <summary>
  ///   The scale that GraphsState picks for the highest and the lowest value shown: nine cells of Check units, with
  ///   zero on the baseline unless there are negative values, 126 pixels high
  /// </summary>
  TXcomGraphScale = record
  public
    const
      /// <summary>Pixels of the plotting area (127 high, the zero line at 175)</summary>
      HEIGHT_PIXELS = 126;
      /// <summary>The line of zero when the scale starts at zero</summary>
      BASELINE = 175;
      CELLS = 9;
  public
    LowerLimit: Integer;
    UpperLimit: Integer;
    /// <summary>Values to a pixel: (UpperLimit - LowerLimit) / 126</summary>
    Units: Double;
    /// <summary>
    ///   The scale of GraphsState::drawXxxLines: the cell grows (doubling) until the range fits in nine of them, then
    ///   the window slides down to include the lowest value
    /// </summary>
    /// <param name="AUpper">The highest value shown (never below zero)</param>
    /// <param name="ALower">The lowest value shown (never above zero)</param>
    /// <param name="AFirstCell">The first size of a cell: 10 (activity), 50 (income in thousands), 250 (finances)</param>
    class function Fit(AUpper, ALower, AFirstCell: Integer): TXcomGraphScale; static;
    /// <summary>
    ///   The y of a point: int y = 175 - (-lowerLimit / units) is truncated, then the value divided by the units
    ///   (truncated) is taken off; a value of Int64 is first divided as the C++ does (the caller passes it whole)
    /// </summary>
    function BaseY: Integer;
    function PointY(AValue: Int64): Integer;
    /// <summary>The label of cell AIndex (0..9) of the vertical axis: the increment is at least 10</summary>
    function AxisLabel(AIndex: Integer): Integer;
  end;

implementation

class function TXcomGraphScale.Fit(AUpper, ALower, AFirstCell: Integer): TXcomGraphScale;
var
  LRange: Double;
  LLow: Double;
  LCheck: Integer;
begin
  LRange := AUpper - ALower;
  LLow := ALower;
  LCheck := AFirstCell;
  while LRange > LCheck * CELLS do
    LCheck := LCheck * 2;
  Result.LowerLimit := 0;
  Result.UpperLimit := LCheck * CELLS;
  if LLow < 0 then
    while LLow < Result.LowerLimit do
    begin
      Dec(Result.LowerLimit, LCheck);
      Dec(Result.UpperLimit, LCheck);
    end;
  LRange := Result.UpperLimit - Result.LowerLimit;
  Result.Units := LRange / HEIGHT_PIXELS;
end;

function TXcomGraphScale.BaseY: Integer;
begin
  Result := Trunc(BASELINE - (-LowerLimit / Units));
end;

function TXcomGraphScale.PointY(AValue: Int64): Integer;
begin
  Result := BaseY - Trunc(AValue / Units);
end;

function TXcomGraphScale.AxisLabel(AIndex: Integer): Integer;
var
  LIncrement: Double;
begin
  LIncrement := (UpperLimit - LowerLimit) / CELLS;
  if LIncrement < 10 then
    LIncrement := 10;
  Result := Trunc(LowerLimit + AIndex * LIncrement);
end;

end.
