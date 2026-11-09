{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the drawing tools of the text screen            }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Drawing;

interface

uses
  System.SysUtils, System.Types,
  DelphiDoom.Endoom.Types,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The tools of the editor on a screen: they paint the background (a cell is a pixel of a
  ///   picture of 80x25), or the foreground and the character for the frames. They are the
  ///   EditAction* procedures of the main window of ENDEDIT without the window: every tool takes
  ///   the cells it works on, and what falls outside of the screen is ignored
  /// </summary>
  TEndoomDrawing = class
  strict private
    class procedure PlotBackground(const AScreen: IEndoomScreen; AX, AY, AColor: Integer); static;
    class procedure PlotFrame(const AScreen: IEndoomScreen; AX, AY, AColor: Integer; ACode: Byte); static;
    class procedure Ellipse(const AScreen: IEndoomScreen; ACenterX, ACenterY, ARadiusX, ARadiusY: Integer;
      AFilled: Boolean; AColor: Integer); static;
  public
    /// <summary>
    ///   The cells that a drag from the first cell to the second one goes through (the line of
    ///   the old editor, which paints every one of them), the first cell included
    /// </summary>
    class function TraceCells(AX1, AY1, AX2, AY2: Integer): TArray<TPoint>; static;
    /// <summary>A line of background between two cells</summary>
    class procedure Line(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2, AColor: Integer); static;
    /// <summary>The outline of the rectangle between two corners, in background</summary>
    class procedure Rectangle(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2, AColor: Integer); static;
    class procedure FillRectangle(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2, AColor: Integer); static;
    /// <summary>
    ///   The outline of an ellipse (midpoint algorithm) whose center is the first cell and
    ///   which goes through the second one in the horizontal and in the vertical direction
    /// </summary>
    class procedure EllipseOutline(const AScreen: IEndoomScreen; ACenterX, ACenterY, AX, AY,
      AColor: Integer); static;
    class procedure EllipseFilled(const AScreen: IEndoomScreen; ACenterX, ACenterY, AX, AY,
      AColor: Integer); static;
    /// <summary>
    ///   Gives AColor to the background of the cell and of the cells that touch it (not on a
    ///   corner) with the same background, and so on: what a paint bucket does
    /// </summary>
    class procedure FloodFill(const AScreen: IEndoomScreen; AX, AY, AColor: Integer); static;
    /// <summary>
    ///   Draws the frame of a rectangle with characters of the DOS font: they have the foreground
    ///   AForeground, the background is left as it is
    /// </summary>
    class procedure CharacterFrame(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2: Integer;
      AStyle: TEndoomFrameStyle; AForeground: Integer); static;
  end;

implementation

type
  /// <summary>The characters of a frame: the corners, the horizontal and the vertical line</summary>
  TFrameCodes = record
    TopLeft: Byte;
    TopRight: Byte;
    BottomLeft: Byte;
    BottomRight: Byte;
    Horizontal: Byte;
    Vertical: Byte;
  end;

const
  FRAME_CODES: array[TEndoomFrameStyle] of TFrameCodes = (
    (TopLeft: $DA; TopRight: $BF; BottomLeft: $C0; BottomRight: $D9; Horizontal: $C4; Vertical: $B3),
    (TopLeft: $D5; TopRight: $B8; BottomLeft: $D4; BottomRight: $BE; Horizontal: $CD; Vertical: $B3),
    (TopLeft: $D6; TopRight: $B7; BottomLeft: $D3; BottomRight: $BD; Horizontal: $C4; Vertical: $BA),
    (TopLeft: $C9; TopRight: $BB; BottomLeft: $C8; BottomRight: $BC; Horizontal: $CD; Vertical: $BA),
    (TopLeft: $DB; TopRight: $DB; BottomLeft: $DB; BottomRight: $DB; Horizontal: $DB; Vertical: $DB)
  );

{ TEndoomDrawing }

class procedure TEndoomDrawing.PlotBackground(const AScreen: IEndoomScreen; AX, AY, AColor: Integer);
begin
  if (AX >= 0) and (AX < ENDOOM_COLUMNS) and (AY >= 0) and (AY < ENDOOM_ROWS) then
    AScreen.SetBackground(AX, AY, AColor);
end;

class procedure TEndoomDrawing.PlotFrame(const AScreen: IEndoomScreen; AX, AY, AColor: Integer;
  ACode: Byte);
begin
  if (AX >= 0) and (AX < ENDOOM_COLUMNS) and (AY >= 0) and (AY < ENDOOM_ROWS) then
  begin
    AScreen.SetForeground(AX, AY, AColor);
    AScreen.SetCharacter(AX, AY, ACode);
  end;
end;

class function TEndoomDrawing.TraceCells(AX1, AY1, AX2, AY2: Integer): TArray<TPoint>;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
  LAbsoluteX: Integer;
  LAbsoluteY: Integer;
  LStepX: Integer;
  LStepY: Integer;
  LCurrentX: Integer;
  LCurrentY: Integer;
  LError: Integer;
  LCount: Integer;

  procedure Add;
  begin
    if LCount >= Length(Result) then
      SetLength(Result, Length(Result) * 2 + 16);
    Result[LCount] := Point(LCurrentX, LCurrentY);
    Inc(LCount);
  end;

begin
  Result := nil;
  LCount := 0;
  LDeltaX := AX2 - AX1;
  LAbsoluteX := 2 * Abs(LDeltaX);
  if LDeltaX < 0 then
    LStepX := -1
  else
    LStepX := 1;
  LDeltaY := AY2 - AY1;
  LAbsoluteY := 2 * Abs(LDeltaY);
  if LDeltaY < 0 then
    LStepY := -1
  else
    LStepY := 1;
  LCurrentX := AX1;
  LCurrentY := AY1;
  if LAbsoluteX > LAbsoluteY then
  begin
    LError := LAbsoluteY - LAbsoluteX div 2;
    while True do
    begin
      Add;
      if LCurrentX = AX2 then
        Break;
      if LError >= 0 then
      begin
        LCurrentY := LCurrentY + LStepY;
        LError := LError - LAbsoluteX;
      end;
      LCurrentX := LCurrentX + LStepX;
      LError := LError + LAbsoluteY;
    end;
  end
  else
  begin
    LError := LAbsoluteX - LAbsoluteY div 2;
    while True do
    begin
      Add;
      if LCurrentY = AY2 then
        Break;
      if LError >= 0 then
      begin
        LCurrentX := LCurrentX + LStepX;
        LError := LError - LAbsoluteY;
      end;
      LCurrentY := LCurrentY + LStepY;
      LError := LError + LAbsoluteX;
    end;
  end;
  SetLength(Result, LCount);
end;

class procedure TEndoomDrawing.Line(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2, AColor: Integer);
var
  LCell: TPoint;
begin
  for LCell in TraceCells(AX1, AY1, AX2, AY2) do
    PlotBackground(AScreen, LCell.X, LCell.Y, AColor);
end;

class procedure TEndoomDrawing.Rectangle(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2, AColor: Integer);
var
  LRect: TEndoomRect;
  LIndex: Integer;
begin
  LRect := TEndoomRect.Between(AX1, AY1, AX2, AY2);
  for LIndex := LRect.Left to LRect.Right do
  begin
    PlotBackground(AScreen, LIndex, LRect.Top, AColor);
    PlotBackground(AScreen, LIndex, LRect.Bottom, AColor);
  end;
  for LIndex := LRect.Top + 1 to LRect.Bottom - 1 do
  begin
    PlotBackground(AScreen, LRect.Left, LIndex, AColor);
    PlotBackground(AScreen, LRect.Right, LIndex, AColor);
  end;
end;

class procedure TEndoomDrawing.FillRectangle(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2, AColor: Integer);
begin
  AScreen.FillBackground(TEndoomRect.Between(AX1, AY1, AX2, AY2), AColor);
end;

class procedure TEndoomDrawing.Ellipse(const AScreen: IEndoomScreen; ACenterX, ACenterY, ARadiusX,
  ARadiusY: Integer; AFilled: Boolean; AColor: Integer);
var
  LDeltaX: Double;
  LDeltaY: Double;
  LDecision1: Double;
  LDecision2: Double;
  LX: Integer;
  LY: Integer;

  procedure PlotRow(AOffsetX, AOffsetY: Integer);
  var
    LIndex: Integer;
  begin
    PlotBackground(AScreen, AOffsetX + ACenterX, AOffsetY + ACenterY, AColor);
    PlotBackground(AScreen, -AOffsetX + ACenterX, AOffsetY + ACenterY, AColor);
    PlotBackground(AScreen, AOffsetX + ACenterX, -AOffsetY + ACenterY, AColor);
    PlotBackground(AScreen, -AOffsetX + ACenterX, -AOffsetY + ACenterY, AColor);
    if AFilled then
      for LIndex := -AOffsetX + ACenterX + 1 to AOffsetX + ACenterX - 1 do
      begin
        PlotBackground(AScreen, LIndex, AOffsetY + ACenterY, AColor);
        PlotBackground(AScreen, LIndex, -AOffsetY + ACenterY, AColor);
      end;
  end;

begin
  LX := 0;
  LY := ARadiusY;
  // region 1: the slope is smaller than 1
  LDecision1 := (ARadiusY * ARadiusY) - (ARadiusX * ARadiusX * ARadiusY) + (0.25 * ARadiusX * ARadiusX);
  LDeltaX := 2 * ARadiusY * ARadiusY * LX;
  LDeltaY := 2 * ARadiusX * ARadiusX * LY;
  while LDeltaX < LDeltaY do
  begin
    PlotRow(LX, LY);
    if LDecision1 < 0 then
    begin
      Inc(LX);
      LDeltaX := LDeltaX + (2 * ARadiusY * ARadiusY);
      LDecision1 := LDecision1 + LDeltaX + (ARadiusY * ARadiusY);
    end
    else
    begin
      Inc(LX);
      Dec(LY);
      LDeltaX := LDeltaX + (2 * ARadiusY * ARadiusY);
      LDeltaY := LDeltaY - (2 * ARadiusX * ARadiusX);
      LDecision1 := LDecision1 + LDeltaX - LDeltaY + (ARadiusY * ARadiusY);
    end;
  end;
  // region 2: the slope is bigger than 1
  LDecision2 := ((ARadiusY * ARadiusY) * ((LX + 0.5) * (LX + 0.5))) +
    ((ARadiusX * ARadiusX) * ((LY - 1) * (LY - 1))) - (ARadiusX * ARadiusX * ARadiusY * ARadiusY);
  while LY >= 0 do
  begin
    PlotRow(LX, LY);
    if LDecision2 > 0 then
    begin
      Dec(LY);
      LDeltaY := LDeltaY - (2 * ARadiusX * ARadiusX);
      LDecision2 := LDecision2 + (ARadiusX * ARadiusX) - LDeltaY;
    end
    else
    begin
      Dec(LY);
      Inc(LX);
      LDeltaX := LDeltaX + (2 * ARadiusY * ARadiusY);
      LDeltaY := LDeltaY - (2 * ARadiusX * ARadiusX);
      LDecision2 := LDecision2 + LDeltaX - LDeltaY + (ARadiusX * ARadiusX);
    end;
  end;
end;

class procedure TEndoomDrawing.EllipseOutline(const AScreen: IEndoomScreen; ACenterX, ACenterY, AX, AY,
  AColor: Integer);
begin
  Ellipse(AScreen, ACenterX, ACenterY, Abs(ACenterX - AX), Abs(ACenterY - AY), False, AColor);
end;

class procedure TEndoomDrawing.EllipseFilled(const AScreen: IEndoomScreen; ACenterX, ACenterY, AX, AY,
  AColor: Integer);
begin
  Ellipse(AScreen, ACenterX, ACenterY, Abs(ACenterX - AX), Abs(ACenterY - AY), True, AColor);
end;

class procedure TEndoomDrawing.FloodFill(const AScreen: IEndoomScreen; AX, AY, AColor: Integer);
var
  LPending: TArray<TPoint>;
  LCount: Integer;
  LRover: Integer;
  LCell: TPoint;

  procedure Push(AOffsetX, AOffsetY: Integer);
  var
    LNextX: Integer;
    LNextY: Integer;
  begin
    LNextX := LCell.X + AOffsetX;
    LNextY := LCell.Y + AOffsetY;
    if (LNextX < 0) or (LNextX >= ENDOOM_COLUMNS) or (LNextY < 0) or (LNextY >= ENDOOM_ROWS) then
      Exit;
    if AScreen.GetBackground(LNextX, LNextY) <> LRover then
      Exit;
    if LCount >= Length(LPending) then
      SetLength(LPending, Length(LPending) * 2 + 16);
    LPending[LCount] := Point(LNextX, LNextY);
    Inc(LCount);
  end;

begin
  if (AX < 0) or (AX >= ENDOOM_COLUMNS) or (AY < 0) or (AY >= ENDOOM_ROWS) then
    Exit;
  LRover := AScreen.GetBackground(AX, AY);
  if LRover = AColor then
    Exit;
  // a list of cells to visit instead of the recursion of the old tool: the cells that
  // change are the same, the call stack of a big area does not grow
  LPending := nil;
  LCount := 0;
  LCell := Point(AX, AY);
  AScreen.SetBackground(AX, AY, AColor);
  Push(-1, 0);
  Push(1, 0);
  Push(0, -1);
  Push(0, 1);
  while LCount > 0 do
  begin
    Dec(LCount);
    LCell := LPending[LCount];
    // a cell may have been pushed twice before it was painted
    if AScreen.GetBackground(LCell.X, LCell.Y) <> LRover then
      Continue;
    AScreen.SetBackground(LCell.X, LCell.Y, AColor);
    Push(-1, 0);
    Push(1, 0);
    Push(0, -1);
    Push(0, 1);
  end;
end;

class procedure TEndoomDrawing.CharacterFrame(const AScreen: IEndoomScreen; AX1, AY1, AX2, AY2: Integer;
  AStyle: TEndoomFrameStyle; AForeground: Integer);
var
  LRect: TEndoomRect;
  LCodes: TFrameCodes;
  LIndex: Integer;
begin
  LRect := TEndoomRect.Between(AX1, AY1, AX2, AY2);
  LCodes := FRAME_CODES[AStyle];
  for LIndex := LRect.Left + 1 to LRect.Right - 1 do
  begin
    PlotFrame(AScreen, LIndex, LRect.Top, AForeground, LCodes.Horizontal);
    PlotFrame(AScreen, LIndex, LRect.Bottom, AForeground, LCodes.Horizontal);
  end;
  for LIndex := LRect.Top + 1 to LRect.Bottom - 1 do
  begin
    PlotFrame(AScreen, LRect.Left, LIndex, AForeground, LCodes.Vertical);
    PlotFrame(AScreen, LRect.Right, LIndex, AForeground, LCodes.Vertical);
  end;
  PlotFrame(AScreen, LRect.Left, LRect.Top, AForeground, LCodes.TopLeft);
  PlotFrame(AScreen, LRect.Right, LRect.Top, AForeground, LCodes.TopRight);
  PlotFrame(AScreen, LRect.Left, LRect.Bottom, AForeground, LCodes.BottomLeft);
  PlotFrame(AScreen, LRect.Right, LRect.Bottom, AForeground, LCodes.BottomRight);
end;

end.
