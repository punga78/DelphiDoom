{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - rectangles, subsets and the exception     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Base of the errors of the xcom surface library</summary>
  EXcomSurfaceException = class(Exception);

  /// <summary>
  ///   SDL_Rect of SDL 1.2: the position is signed 16 bit and the size unsigned 16 bit, so a negative size
  ///   given by the caller becomes a large one, as in the C++
  /// </summary>
  TXcomRect = record
    X: SmallInt;
    Y: SmallInt;
    W: Word;
    H: Word;
    class function Make(AX, AY, AW, AH: Integer): TXcomRect; static;
  end;

  PXcomRect = ^TXcomRect;

  /// <summary>GraphSubset of OpenXcom: a rectangle given as two half open ranges</summary>
  TXcomGraphSubset = record
    BegX: Integer;
    EndX: Integer;
    BegY: Integer;
    EndY: Integer;
    class function Make(ABegX, AEndX, ABegY, AEndY: Integer): TXcomGraphSubset; static;
    function Offset(AX, AY: Integer): TXcomGraphSubset;
    function SizeX: Integer;
    function SizeY: Integer;
    /// <summary>GraphSubset::intersection: an empty intersection keeps the start and ends there</summary>
    class function Intersection(const AFirst, ASecond: TXcomGraphSubset): TXcomGraphSubset; static;
  end;

const
  /// <summary>Number of colors of the palette of a surface</summary>
  XCOM_SURFACE_COLORS = 256;

implementation

{ TXcomRect }

class function TXcomRect.Make(AX, AY, AW, AH: Integer): TXcomRect;
begin
  Result.X := SmallInt(AX and $FFFF);
  Result.Y := SmallInt(AY and $FFFF);
  Result.W := Word(AW and $FFFF);
  Result.H := Word(AH and $FFFF);
end;

{ TXcomGraphSubset }

class function TXcomGraphSubset.Make(ABegX, AEndX, ABegY, AEndY: Integer): TXcomGraphSubset;
begin
  Result.BegX := ABegX;
  Result.EndX := AEndX;
  Result.BegY := ABegY;
  Result.EndY := AEndY;
end;

function TXcomGraphSubset.Offset(AX, AY: Integer): TXcomGraphSubset;
begin
  Result := Make(BegX + AX, EndX + AX, BegY + AY, EndY + AY);
end;

function TXcomGraphSubset.SizeX: Integer;
begin
  Result := EndX - BegX;
end;

function TXcomGraphSubset.SizeY: Integer;
begin
  Result := EndY - BegY;
end;

procedure IntersectRange(var ABeginA, AEndA: Integer; ABeginB, AEndB: Integer);
begin
  if (ABeginA >= AEndB) or (ABeginB >= AEndA) then
    AEndA := ABeginA
  else
  begin
    if ABeginB > ABeginA then
      ABeginA := ABeginB;
    if AEndB < AEndA then
      AEndA := AEndB;
  end;
end;

class function TXcomGraphSubset.Intersection(const AFirst, ASecond: TXcomGraphSubset): TXcomGraphSubset;
begin
  Result := AFirst;
  IntersectRange(Result.BegX, Result.EndX, ASecond.BegX, ASecond.EndX);
  IntersectRange(Result.BegY, Result.EndY, ASecond.BegY, ASecond.EndY);
end;

end.
