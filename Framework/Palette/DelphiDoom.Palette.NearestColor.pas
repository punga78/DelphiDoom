{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the nearest color on a table of the engine    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.NearestColor;

interface

type
  /// <summary>
  ///   V_FindAproxColorIndex and V_FindAproxColorIndexExcluding, on a table of colors that stays where
  ///   the engine keeps it (no copy, no interface call: the engine asks for it once for each pixel of an
  ///   image that it converts). The distance is the squared euclidean one; the low byte is called "red"
  ///   for both colors, so the order of the channels does not matter
  /// </summary>
  TNearestColor = class sealed
  public
    /// <summary>
    ///   The first index AStart..AFinish with the least distance from AColor; an exact match stops the
    ///   search; AStart if the range is empty. The range is not checked (as in the original): the table
    ///   must have AFinish + 1 colors
    /// </summary>
    class function Find(const APalette: PCardinal; AColor: Cardinal; AStart, AFinish: Integer): Integer;
      overload; static;
    /// <summary>The same, without looking at the index AExclude</summary>
    class function Find(const APalette: PCardinal; AColor: Cardinal; AStart, AFinish,
      AExclude: Integer): Integer; overload; static;
  end;

implementation

{$POINTERMATH ON}

{ TNearestColor }

class function TNearestColor.Find(const APalette: PCardinal; AColor: Cardinal; AStart,
  AFinish: Integer): Integer;
begin
  // no index can be Low(Integer): nothing is excluded
  Result := Find(APalette, AColor, AStart, AFinish, Low(Integer));
end;

class function TNearestColor.Find(const APalette: PCardinal; AColor: Cardinal; AStart, AFinish,
  AExclude: Integer): Integer;
var
  LIndex: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LDeltaRed: Integer;
  LDeltaGreen: Integer;
  LDeltaBlue: Integer;
  LColor: Cardinal;
  LDistance: Cardinal;
  LMinimum: Cardinal;
begin
  LRed := AColor and $FF;
  LGreen := (AColor shr 8) and $FF;
  LBlue := (AColor shr 16) and $FF;
  Result := AStart;
  LMinimum := Cardinal($FFFFFFFF);
  for LIndex := AStart to AFinish do
  begin
    if LIndex = AExclude then
      Continue;
    LColor := APalette[LIndex];
    LDeltaRed := LRed - Integer(LColor and $FF);
    LDeltaGreen := LGreen - Integer((LColor shr 8) and $FF);
    LDeltaBlue := LBlue - Integer((LColor shr 16) and $FF);
    LDistance := Cardinal(LDeltaRed * LDeltaRed + LDeltaGreen * LDeltaGreen + LDeltaBlue * LDeltaBlue);
    if LDistance < LMinimum then
    begin
      Result := LIndex;
      if LDistance = 0 then
        Exit;
      LMinimum := LDistance;
    end;
  end;
end;

end.
