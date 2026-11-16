{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the vector shapes of the automap               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.Shapes;

interface

uses
  DelphiDoom.Automap.Types;

type
  /// <summary>Which family of games the arrow of the player is drawn for</summary>
  TAutomapShapeStyle = (assDoom, assRaven);

  /// <summary>
  ///   The line drawings of the automap (the player arrow, the cheat arrow, the triangles of the
  ///   things, the trace player and the key of Heretic and Hexen). They were the first 300 lines of
  ///   AM_Init. Cold: they are written once at start; the lines are then read by the drawing
  ///   routines of am_map from plain arrays, as before. Fixed point values in map units
  /// </summary>
  TAutomapShapes = class sealed
  strict private
    class procedure SetLine(var ALine: PAutomapLine; const AAX, AAY, ABX, ABY: Integer); static;
  public
    /// <summary>Lines of the player arrow: 7 for Doom and Strife, 10 for Heretic and Hexen</summary>
    class function PlayerArrowLineCount(const AStyle: TAutomapShapeStyle): Integer; static;
    class procedure FillPlayerArrowDoom(const ALines: PAutomapLine); static;
    class procedure FillPlayerArrowRaven(const ALines: PAutomapLine); static;
    /// <summary>Writes the lines of the player arrow of the style (the array must have PlayerArrowLineCount lines)</summary>
    class procedure FillPlayerArrow(const ALines: PAutomapLine;
      const AStyle: TAutomapShapeStyle); static;
    /// <summary>The 16 lines of the arrow of the player in cheating mode</summary>
    class procedure FillCheatPlayerArrow(const ALines: PAutomapLine); static;
    /// <summary>The 3 lines of the triangle of a thing</summary>
    class procedure FillTriangleGuy(const ALines: PAutomapLine); static;
    /// <summary>The 3 lines of the thin triangle of a thing</summary>
    class procedure FillThinTriangleGuy(const ALines: PAutomapLine); static;
    /// <summary>The 3 lines of the figure that follows the trace of the player</summary>
    class procedure FillTracePlayerGuy(const ALines: PAutomapLine); static;
    /// <summary>The 8 lines of the key of Heretic and Hexen</summary>
    class procedure FillKeySquare(const ALines: PAutomapLine); static;
  end;

implementation

{ TAutomapShapes }

class procedure TAutomapShapes.SetLine(var ALine: PAutomapLine; const AAX, AAY, ABX, ABY: Integer);
begin
  ALine.A.X := AAX;
  ALine.A.Y := AAY;
  ALine.B.X := ABX;
  ALine.B.Y := ABY;
  Inc(ALine);
end;

class function TAutomapShapes.PlayerArrowLineCount(const AStyle: TAutomapShapeStyle): Integer;
begin
  if AStyle = assRaven then
    Result := 10
  else
    Result := 7;
end;

class procedure TAutomapShapes.FillPlayerArrow(const ALines: PAutomapLine;
  const AStyle: TAutomapShapeStyle);
begin
  if AStyle = assRaven then
    FillPlayerArrowRaven(ALines)
  else
    FillPlayerArrowDoom(ALines);
end;
class procedure TAutomapShapes.FillPlayerArrowDoom(const ALines: PAutomapLine);
var
  LLine: PAutomapLine;
  LR: Integer;
begin
  LR := (8 * AUTOMAP_PLAYERRADIUS) div 7;
  LLine := ALines;
  SetLine(LLine, -LR + LR div 8, 0, LR, 0);
  SetLine(LLine, LR, 0, LR - LR div 2, LR div 4);
  SetLine(LLine, LR, 0, LR - LR div 2, -LR div 4);
  SetLine(LLine, -LR + LR div 8, 0, -LR - LR div 8, LR div 4);
  SetLine(LLine, -LR + LR div 8, 0, -LR - LR div 8, -LR div 4);
  SetLine(LLine, -LR + 3 * LR div 8, 0, -LR + LR div 8, LR div 4);
  SetLine(LLine, -LR + 3 * LR div 8, 0, -LR + LR div 8, -LR div 4);
end;
class procedure TAutomapShapes.FillPlayerArrowRaven(const ALines: PAutomapLine);
var
  LLine: PAutomapLine;
  LR: Integer;
begin
  LR := (8 * AUTOMAP_PLAYERRADIUS) div 7;
  LLine := ALines;
  SetLine(LLine, -LR + LR div 4, 0, 0, 0);
  SetLine(LLine, -LR + LR div 4, LR div 8, LR, 0);
  SetLine(LLine, -LR + LR div 4, -LR div 8, LR, 0);
  SetLine(LLine, -LR + LR div 4, -LR div 4, -LR + LR div 4, LR div 4);
  SetLine(LLine, -LR + LR div 8, -LR div 4, -LR + LR div 8, LR div 4);
  SetLine(LLine, -LR + LR div 8, -LR div 4, -LR + LR div 4, -LR div 4);
  SetLine(LLine, -LR + LR div 8, LR div 4, -LR + LR div 4, LR div 4);
  SetLine(LLine, -LR - LR div 4, LR div 8, -LR - LR div 4, -LR div 8);
  SetLine(LLine, -LR - LR div 4, LR div 8, -LR + LR div 8, LR div 8);
  SetLine(LLine, -LR - LR div 4, -LR div 8, -LR + LR div 8, -LR div 8);
end;
class procedure TAutomapShapes.FillCheatPlayerArrow(const ALines: PAutomapLine);
var
  LLine: PAutomapLine;
  LR: Integer;
begin
  LR := (8 * AUTOMAP_PLAYERRADIUS) div 7;
  LLine := ALines;
  SetLine(LLine, -LR + LR div 8, 0, LR, 0);
  SetLine(LLine, LR, 0, LR - LR div 2, LR div 6);
  SetLine(LLine, LR, 0, LR - LR div 2, -LR div 6);
  SetLine(LLine, -LR + LR div 8, 0, -LR - LR div 8, LR div 6);
  SetLine(LLine, -LR + LR div 8, 0, -LR - LR div 8, -LR div 6);
  SetLine(LLine, -LR + 3 * LR div 8, 0, -LR + LR div 8, LR div 6);
  SetLine(LLine, -LR + 3 * LR div 8, 0, -LR + LR div 8, -LR div 6);
  SetLine(LLine, -LR div 2, 0, -LR div 2, -LR div 6);
  SetLine(LLine, -LR div 2, -LR div 6, -LR div 2 + LR div 6, -LR div 6);
  SetLine(LLine, -LR div 2 + LR div 6, -LR div 6, -LR div 2 + LR div 6, LR div 4);
  SetLine(LLine, -LR div 6, 0, -LR div 6, -LR div 6);
  SetLine(LLine, -LR div 6, -LR div 6, 0, -LR div 6);
  SetLine(LLine, 0, -LR div 6, 0, LR div 4);
  SetLine(LLine, LR div 6, LR div 4, LR div 6, -LR div 7);
  SetLine(LLine, LR div 6, -LR div 7, LR div 6 + LR div 32, -LR div 7 - LR div 32);
  SetLine(LLine, LR div 6 + LR div 32, -LR div 7 - LR div 32, LR div 6 + LR div 10, -LR div 7);
end;
class procedure TAutomapShapes.FillTriangleGuy(const ALines: PAutomapLine);
var
  LLine: PAutomapLine;
begin
  LLine := ALines;
  SetLine(LLine, round(-0.867 * AUTOMAP_MAPUNIT), round(-0.5 * AUTOMAP_MAPUNIT), round(0.867 * AUTOMAP_MAPUNIT), round(-0.5 * AUTOMAP_MAPUNIT));
  SetLine(LLine, round(0.867 * AUTOMAP_MAPUNIT), round(-0.5 * AUTOMAP_MAPUNIT), 0, AUTOMAP_MAPUNIT);
  SetLine(LLine, 0, AUTOMAP_MAPUNIT, round(-0.867 * AUTOMAP_MAPUNIT), round(-0.5 * AUTOMAP_MAPUNIT));
end;
class procedure TAutomapShapes.FillThinTriangleGuy(const ALines: PAutomapLine);
var
  LLine: PAutomapLine;
begin
  LLine := ALines;
  SetLine(LLine, round(-0.5 * AUTOMAP_MAPUNIT), round(-0.7 * AUTOMAP_MAPUNIT), AUTOMAP_MAPUNIT, 0);
  SetLine(LLine, AUTOMAP_MAPUNIT, 0, round(-0.5 * AUTOMAP_MAPUNIT), round(0.7 * AUTOMAP_MAPUNIT));
  SetLine(LLine, round(-0.5 * AUTOMAP_MAPUNIT), round(0.7 * AUTOMAP_MAPUNIT), round(-0.5 * AUTOMAP_MAPUNIT), round(-0.7 * AUTOMAP_MAPUNIT));
end;
class procedure TAutomapShapes.FillTracePlayerGuy(const ALines: PAutomapLine);
var
  LLine: PAutomapLine;
begin
  LLine := ALines;
  SetLine(LLine, 0, round(-0.7 * AUTOMAP_MAPUNIT), round(0.7 * AUTOMAP_MAPUNIT), 0);
  SetLine(LLine, 0, round(0.7 * AUTOMAP_MAPUNIT), round(0.7 * AUTOMAP_MAPUNIT), 0);
  SetLine(LLine, 0, 0, round(0.7 * AUTOMAP_MAPUNIT), 0);
end;
class procedure TAutomapShapes.FillKeySquare(const ALines: PAutomapLine);
var
  LLine: PAutomapLine;
  LR: Integer;
begin
  LR := (8 * AUTOMAP_PLAYERRADIUS) div 7;
  LLine := ALines;
  SetLine(LLine, 0, 0, LR div 4, -LR div 2);
  SetLine(LLine, LR div 4, -LR div 2, LR div 2, -LR div 2);
  SetLine(LLine, LR div 2, -LR div 2, LR div 2, LR div 2);
  SetLine(LLine, LR div 2, LR div 2, LR div 4, LR div 2);
  SetLine(LLine, LR div 4, LR div 2, 0, 0);
  SetLine(LLine, 0, 0, -LR, 0);
  SetLine(LLine, -LR, 0, -LR, -LR div 2);
  SetLine(LLine, -3 * LR div 4, 0, -3 * LR div 4, -LR div 4);
end;

end.
