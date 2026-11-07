{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the clipping of the lines                     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.LineClipper;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Automap.Types;

type
  /// <summary>
  ///   Automap clipping of lines (the old AM_clipMline). Based on the Cohen-Sutherland algorithm
  ///   but with a slightly faster reject: a line outside the window of the map is rejected before
  ///   it is moved to the frame buffer.
  /// </summary>
  /// <remarks>
  ///   The products of the clipping wrap around at 32 bits as they did, so the unit turns
  ///   overflow and range checks off.
  /// </remarks>
  TAutomapLineClipper = class
  strict private
    class function OutCode(const AWindow: TAutomapWindow; const AX, AY: Integer): Integer; static;
  public
    /// <summary>
    ///   Moves a line of the map to the frame buffer and cuts it to the frame. False when no part
    ///   of the line is inside; AFrameLine is then not meaningful
    /// </summary>
    class function Clip(const AWindow: TAutomapWindow; const AMapLine: TAutomapLine;
      var AFrameLine: TAutomapFrameLine): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Automap.Transform;

const
  OUTCODE_LEFT = 1;
  OUTCODE_RIGHT = 2;
  OUTCODE_BOTTOM = 4;
  OUTCODE_TOP = 8;

{ TAutomapLineClipper }

class function TAutomapLineClipper.OutCode(const AWindow: TAutomapWindow;
  const AX, AY: Integer): Integer;
begin
  Result := 0;
  if AY < 0 then
    Result := Result or OUTCODE_TOP
  else if AY >= AWindow.FrameHeight then
    Result := Result or OUTCODE_BOTTOM;
  if AX < 0 then
    Result := Result or OUTCODE_LEFT
  else if AX >= AWindow.FrameWidth then
    Result := Result or OUTCODE_RIGHT;
end;

class function TAutomapLineClipper.Clip(const AWindow: TAutomapWindow;
  const AMapLine: TAutomapLine; var AFrameLine: TAutomapFrameLine): Boolean;
var
  LOutCode1: Integer;
  LOutCode2: Integer;
  LOutside: Integer;
  LCut: TAutomapFramePoint;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  Result := False;

  // do trivial rejects and outcodes
  if AMapLine.A.Y > AWindow.MapY2 then
    LOutCode1 := OUTCODE_TOP
  else if AMapLine.A.Y < AWindow.MapY then
    LOutCode1 := OUTCODE_BOTTOM
  else
    LOutCode1 := 0;

  if AMapLine.B.Y > AWindow.MapY2 then
    LOutCode2 := OUTCODE_TOP
  else if AMapLine.B.Y < AWindow.MapY then
    LOutCode2 := OUTCODE_BOTTOM
  else
    LOutCode2 := 0;

  if (LOutCode1 and LOutCode2) <> 0 then
    Exit; // trivially outside

  if AMapLine.A.X < AWindow.MapX then
    LOutCode1 := LOutCode1 or OUTCODE_LEFT
  else if AMapLine.A.X > AWindow.MapX2 then
    LOutCode1 := LOutCode1 or OUTCODE_RIGHT;

  if AMapLine.B.X < AWindow.MapX then
    LOutCode2 := LOutCode2 or OUTCODE_LEFT
  else if AMapLine.B.X > AWindow.MapX2 then
    LOutCode2 := LOutCode2 or OUTCODE_RIGHT;

  if (LOutCode1 and LOutCode2) <> 0 then
    Exit; // trivially outside

  // transform to frame-buffer coordinates
  AFrameLine.A.X := TAutomapTransform.MapToFrameX(AWindow, AMapLine.A.X);
  AFrameLine.A.Y := TAutomapTransform.MapToFrameY(AWindow, AMapLine.A.Y);
  AFrameLine.B.X := TAutomapTransform.MapToFrameX(AWindow, AMapLine.B.X);
  AFrameLine.B.Y := TAutomapTransform.MapToFrameY(AWindow, AMapLine.B.Y);

  LOutCode1 := OutCode(AWindow, AFrameLine.A.X, AFrameLine.A.Y);
  LOutCode2 := OutCode(AWindow, AFrameLine.B.X, AFrameLine.B.Y);

  if (LOutCode1 and LOutCode2) <> 0 then
    Exit; // trivially outside

  LCut.X := 0;
  LCut.Y := 0;
  while (LOutCode1 or LOutCode2) <> 0 do
  begin
    // may be partially inside box: find an outside point
    if LOutCode1 <> 0 then
      LOutside := LOutCode1
    else
      LOutside := LOutCode2;

    // clip to each side
    if (LOutside and OUTCODE_TOP) <> 0 then
    begin
      LDeltaY := AFrameLine.A.Y - AFrameLine.B.Y;
      LDeltaX := AFrameLine.B.X - AFrameLine.A.X;
      LCut.X := AFrameLine.A.X + (LDeltaX * AFrameLine.A.Y) div LDeltaY;
      LCut.Y := 0;
    end
    else if (LOutside and OUTCODE_BOTTOM) <> 0 then
    begin
      LDeltaY := AFrameLine.A.Y - AFrameLine.B.Y;
      LDeltaX := AFrameLine.B.X - AFrameLine.A.X;
      LCut.X := AFrameLine.A.X + (LDeltaX * (AFrameLine.A.Y - AWindow.FrameHeight)) div LDeltaY;
      LCut.Y := AWindow.FrameHeight - 1;
    end
    else if (LOutside and OUTCODE_RIGHT) <> 0 then
    begin
      LDeltaY := AFrameLine.B.Y - AFrameLine.A.Y;
      LDeltaX := AFrameLine.B.X - AFrameLine.A.X;
      LCut.Y := AFrameLine.A.Y + (LDeltaY * (AWindow.FrameWidth - 1 - AFrameLine.A.X)) div LDeltaX;
      LCut.X := AWindow.FrameWidth - 1;
    end
    else if (LOutside and OUTCODE_LEFT) <> 0 then
    begin
      LDeltaY := AFrameLine.B.Y - AFrameLine.A.Y;
      LDeltaX := AFrameLine.B.X - AFrameLine.A.X;
      LCut.Y := AFrameLine.A.Y + (LDeltaY * (-AFrameLine.A.X)) div LDeltaX;
      LCut.X := 0;
    end;

    if LOutside = LOutCode1 then
    begin
      AFrameLine.A := LCut;
      LOutCode1 := OutCode(AWindow, AFrameLine.A.X, AFrameLine.A.Y);
    end
    else
    begin
      AFrameLine.B := LCut;
      LOutCode2 := OutCode(AWindow, AFrameLine.B.X, AFrameLine.B.Y);
    end;

    if (LOutCode1 and LOutCode2) <> 0 then
      Exit; // trivially outside
  end;

  Result := True;
end;

end.
