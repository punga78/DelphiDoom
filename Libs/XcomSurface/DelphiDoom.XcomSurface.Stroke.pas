{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - lines with a width, for the drawings      }
{  that are finer than the game picture (issue 183)                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Stroke;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface;

type
  /// <summary>
  ///   Lines drawn with a square pen on an 8 bit surface. A line of the game picture (one pixel wide, between two
  ///   pixels) drawn on a surface AScale times larger goes between the same two points with a pen whose width
  ///   grows with the scale: its slanted parts are straight where the enlarged picture has steps
  /// </summary>
  TXcomStroke = class
  strict private
    class function Along(AFrom, ATo, AStep, ASteps: Integer): Integer; static;
  public
    /// <summary>The width of the pen of the finer drawings at a scale: half the scale, rounded up (1, 1, 2, 2, 3...)</summary>
    class function WidthOf(AScale: Integer): Integer; static;
    /// <summary>
    ///   A line between two pixels of the target with a pen AWidth x AWidth whose top left corner is on the point;
    ///   what falls outside the target is cut
    /// </summary>
    class procedure Line(ATarget: TXcomSurface; AX1, AY1, AX2, AY2, AWidth: Integer; AColor: Byte); static;
    /// <summary>
    ///   The line of the game picture from the pixel (AX1, AY1) to (AX2, AY2), on a target AScale times larger:
    ///   the pen is centered in the square of AScale x AScale pixels that each of the two pixels became
    /// </summary>
    class procedure ScaledLine(ATarget: TXcomSurface; AX1, AY1, AX2, AY2, AScale, AWidth: Integer;
      AColor: Byte); static;
  end;

implementation

class function TXcomStroke.WidthOf(AScale: Integer): Integer;
begin
  Result := (AScale + 1) div 2;
  if Result < 1 then
    Result := 1;
end;

class function TXcomStroke.Along(AFrom, ATo, AStep, ASteps: Integer): Integer;
var
  LNumerator: Integer;
begin
  // AFrom + (ATo - AFrom) * AStep / ASteps rounded to the nearest pixel, in whole numbers (div rounds towards
  // zero: a negative numerator is rounded down by hand)
  if ASteps = 0 then
    Exit(AFrom);
  LNumerator := 2 * (ATo - AFrom) * AStep + ASteps;
  if LNumerator >= 0 then
    Result := AFrom + LNumerator div (2 * ASteps)
  else
    Result := AFrom - (-LNumerator + 2 * ASteps - 1) div (2 * ASteps);
end;

class procedure TXcomStroke.Line(ATarget: TXcomSurface; AX1, AY1, AX2, AY2, AWidth: Integer; AColor: Byte);
var
  LSteps: Integer;
  LStep: Integer;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LFirstX: Integer;
  LLastX: Integer;
  LPixels: TBytes;
  LWidth: Integer;
  LHeight: Integer;
begin
  if (not Assigned(ATarget)) or (AWidth < 1) then
    Exit;
  LPixels := ATarget.Pixels;
  LWidth := ATarget.Width;
  LHeight := ATarget.Height;
  LSteps := Abs(AX2 - AX1);
  if Abs(AY2 - AY1) > LSteps then
    LSteps := Abs(AY2 - AY1);
  for LStep := 0 to LSteps do
  begin
    LX := Along(AX1, AX2, LStep, LSteps);
    LY := Along(AY1, AY2, LStep, LSteps);
    LFirstX := LX;
    if LFirstX < 0 then
      LFirstX := 0;
    LLastX := LX + AWidth - 1;
    if LLastX > LWidth - 1 then
      LLastX := LWidth - 1;
    if LFirstX > LLastX then
      Continue;
    for LRow := LY to LY + AWidth - 1 do
      if (LRow >= 0) and (LRow < LHeight) then
        FillChar(LPixels[LRow * LWidth + LFirstX], LLastX - LFirstX + 1, AColor);
  end;
end;

class procedure TXcomStroke.ScaledLine(ATarget: TXcomSurface; AX1, AY1, AX2, AY2, AScale, AWidth: Integer;
  AColor: Byte);
var
  LInset: Integer;
begin
  LInset := (AScale - AWidth) div 2;
  Line(ATarget, AX1 * AScale + LInset, AY1 * AScale + LInset, AX2 * AScale + LInset, AY2 * AScale + LInset, AWidth,
    AColor);
end;

end.
