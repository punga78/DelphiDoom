{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the lines of the map on the frame buffer      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.LineRasterizer;

interface

uses
  DelphiDoom.Automap.Types;

type
  /// <summary>
  ///   Where the lines go: the buffer of the software renderer (one byte or four bytes for
  ///   each pixel, Width pixels for each row) and, when the map is drawn over the view, the
  ///   window of the view
  /// </summary>
  TAutomapRasterTarget = record
    Pixels: Pointer;
    Width: Integer;
    /// <summary>True for the overlay: a pixel is drawn only strictly inside the window</summary>
    Clipped: Boolean;
    /// <summary>Drawn if ClipLeft &lt; x &lt; ClipRight and ClipTop &lt; y &lt; ClipBottom</summary>
    ClipLeft: Integer;
    ClipTop: Integer;
    ClipRight: Integer;
    ClipBottom: Integer;
  end;

  /// <summary>
  ///   The Bresenham of AM_drawFline of am_map.pas ("Classic Bresenham w/ whatever
  ///   optimizations needed for speed"). The line is already inside the frame (the clipper of
  ///   the view does it). Hot path: no state, static methods, the depth of the buffer is
  ///   chosen by the caller once for each line and nothing virtual is called for a pixel
  /// </summary>
  TAutomapLineRasterizer = class sealed
  strict private
    class function Hidden(const ATarget: TAutomapRasterTarget; AX, AY: Integer): Boolean;
      static; inline;
  public
    /// <summary>The line with a color of the palette, on a buffer of bytes</summary>
    class procedure Draw8(const ATarget: TAutomapRasterTarget; const ALine: TAutomapFrameLine;
      AColor: Byte); static;
    /// <summary>The line with a color, on a buffer of 32 bit pixels</summary>
    class procedure Draw32(const ATarget: TAutomapRasterTarget; const ALine: TAutomapFrameLine;
      AColor: Cardinal); static;
  end;

implementation

{$POINTERMATH ON}

{ TAutomapLineRasterizer }

class function TAutomapLineRasterizer.Hidden(const ATarget: TAutomapRasterTarget; AX,
  AY: Integer): Boolean;
begin
  Result := ATarget.Clipped and ((AY <= ATarget.ClipTop) or (AY >= ATarget.ClipBottom) or
    (AX <= ATarget.ClipLeft) or (AX >= ATarget.ClipRight));
end;

class procedure TAutomapLineRasterizer.Draw8(const ATarget: TAutomapRasterTarget;
  const ALine: TAutomapFrameLine; AColor: Byte);
var
  LX, LY: Integer;
  LDeltaX, LDeltaY: Integer;
  LStepX, LStepY: Integer;
  LAbsX, LAbsY: Integer;
  LError: Integer;
  LPixels: PByte;
begin
  LPixels := ATarget.Pixels;

  LDeltaX := ALine.B.X - ALine.A.X;
  LAbsX := 2 * Abs(LDeltaX);
  if LDeltaX < 0 then
    LStepX := -1
  else
    LStepX := 1;

  LDeltaY := ALine.B.Y - ALine.A.Y;
  LAbsY := 2 * Abs(LDeltaY);
  if LDeltaY < 0 then
    LStepY := -1
  else
    LStepY := 1;

  LX := ALine.A.X;
  LY := ALine.A.Y;

  if LAbsX > LAbsY then
  begin
    LError := LAbsY - LAbsX div 2;
    while True do
    begin
      if not Hidden(ATarget, LX, LY) then
        LPixels[LY * ATarget.Width + LX] := AColor;
      if LX = ALine.B.X then
        Exit;
      if LError >= 0 then
      begin
        LY := LY + LStepY;
        LError := LError - LAbsX;
      end;
      LX := LX + LStepX;
      LError := LError + LAbsY;
    end;
  end
  else
  begin
    LError := LAbsX - LAbsY div 2;
    while True do
    begin
      if not Hidden(ATarget, LX, LY) then
        LPixels[LY * ATarget.Width + LX] := AColor;
      if LY = ALine.B.Y then
        Exit;
      if LError >= 0 then
      begin
        LX := LX + LStepX;
        LError := LError - LAbsY;
      end;
      LY := LY + LStepY;
      LError := LError + LAbsX;
    end;
  end;
end;

class procedure TAutomapLineRasterizer.Draw32(const ATarget: TAutomapRasterTarget;
  const ALine: TAutomapFrameLine; AColor: Cardinal);
var
  LX, LY: Integer;
  LDeltaX, LDeltaY: Integer;
  LStepX, LStepY: Integer;
  LAbsX, LAbsY: Integer;
  LError: Integer;
  LPixels: PCardinal;
begin
  LPixels := ATarget.Pixels;

  LDeltaX := ALine.B.X - ALine.A.X;
  LAbsX := 2 * Abs(LDeltaX);
  if LDeltaX < 0 then
    LStepX := -1
  else
    LStepX := 1;

  LDeltaY := ALine.B.Y - ALine.A.Y;
  LAbsY := 2 * Abs(LDeltaY);
  if LDeltaY < 0 then
    LStepY := -1
  else
    LStepY := 1;

  LX := ALine.A.X;
  LY := ALine.A.Y;

  if LAbsX > LAbsY then
  begin
    LError := LAbsY - LAbsX div 2;
    while True do
    begin
      if not Hidden(ATarget, LX, LY) then
        LPixels[LY * ATarget.Width + LX] := AColor;
      if LX = ALine.B.X then
        Exit;
      if LError >= 0 then
      begin
        LY := LY + LStepY;
        LError := LError - LAbsX;
      end;
      LX := LX + LStepX;
      LError := LError + LAbsY;
    end;
  end
  else
  begin
    LError := LAbsX - LAbsY div 2;
    while True do
    begin
      if not Hidden(ATarget, LX, LY) then
        LPixels[LY * ATarget.Width + LX] := AColor;
      if LY = ALine.B.Y then
        Exit;
      if LError >= 0 then
      begin
        LX := LX + LStepX;
        LError := LError - LAbsY;
      end;
      LY := LY + LStepY;
      LError := LError + LAbsX;
    end;
  end;
end;

end.
