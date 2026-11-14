{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiWindowPainter, the drawing of a window        }
{                                                                              }
{  Port of idWindow::Redraw, Draw, DrawBackground, DrawBorderAndCaption,       }
{  SetupTransforms and DebugDraw (ui\Window.cpp) and of idSimpleWindow::       }
{  Redraw (ui\SimpleWindow.cpp) of Doom 3 (id Software, GPL v3). Everything    }
{  is drawn through TGuiDrawContext.                                           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Painter;

interface

uses
  DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Window;

type
  /// <summary>The drawing of a window and of its draw windows (simple windows included)</summary>
  TGuiWindowPainter = class
  public
    /// <summary>idWindow::Redraw</summary>
    class procedure Redraw(const AWindow: TGuiWindow; const AX, AY: Single); static;
    /// <summary>idSimpleWindow::Redraw: a window without scripts or children is drawn without clipping rectangle or size</summary>
    class procedure RedrawSimple(const AWindow: TGuiWindow; const AX, AY: Single); static;
    /// <summary>idWindow::Draw: the text, with its shadow, and the coordinates when gui_edit is on</summary>
    class procedure DrawText(const AWindow: TGuiWindow); static;
    /// <summary>idWindow::DrawBackground</summary>
    class procedure DrawBackground(const AWindow: TGuiWindow; const ARect: TGuiRectangle); static;
    /// <summary>The text of printf("%0.<c>ADecimals</c>f"): the exact value of the float rounded half to even</summary>
    class function FormatFixed(const AValue: Double; const ADecimals: Integer): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Gui.Context, DelphiDoom.Gui.DrawContext,
  DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.Window.Types;

const
  // static char buff[16384] of idWindow::DebugDraw
  DEBUG_BUFFER_SIZE = 16384;

class function TGuiWindowPainter.FormatFixed(const AValue: Double; const ADecimals: Integer): string;
var
  LBits: UInt64;
  LExponent, LShift, LIndex: Integer;
  LMantissa, LScaled, LQuotient, LRemainder, LHalf, LPower: UInt64;
  LNegative: Boolean;
  LDigits: string;
begin
  // the exact value of the double (a binary fraction), scaled by 10^decimals, rounded half to even as printf does
  Move(AValue, LBits, SizeOf(LBits));
  LNegative := (LBits shr 63) <> 0;
  LExponent := Integer((LBits shr 52) and $7FF);
  LMantissa := LBits and $000FFFFFFFFFFFFF;
  LPower := 1;
  for LIndex := 1 to ADecimals do
    LPower := LPower * 10;
  if (LExponent = $7FF) or (LExponent > 1075) then
    Exit(Format('%.*f', [ADecimals, AValue], TFormatSettings.Invariant));
  if LExponent = 0 then
    LExponent := 1
  else
    LMantissa := LMantissa or (UInt64(1) shl 52);
  LShift := 1075 - LExponent;
  if LShift <= 0 then
    LScaled := (LMantissa shl (-LShift)) * LPower
  else
    LScaled := LMantissa * LPower;
  if LShift <= 0 then
    LQuotient := LScaled
  else if LShift >= 64 then
    LQuotient := 0
  else
  begin
    LQuotient := LScaled shr LShift;
    LRemainder := LScaled and ((UInt64(1) shl LShift) - 1);
    LHalf := UInt64(1) shl (LShift - 1);
    if (LRemainder > LHalf) or ((LRemainder = LHalf) and ((LQuotient and 1) = 1)) then
      Inc(LQuotient);
  end;
  LDigits := UIntToStr(LQuotient);
  if ADecimals > 0 then
  begin
    while Length(LDigits) <= ADecimals do
      LDigits := '0' + LDigits;
    LDigits := Copy(LDigits, 1, Length(LDigits) - ADecimals) + '.' + Copy(LDigits, Length(LDigits) - ADecimals + 1, ADecimals);
  end;
  if LNegative and (LQuotient <> 0) then
    LDigits := '-' + LDigits
  else if LNegative then
    LDigits := '-' + LDigits;
  Result := LDigits;
end;
function SkipShaders(const AContext: TGuiContext): Integer;
begin
  if Assigned(AContext.Cvars) then
    Result := AContext.Cvars.GetInteger('r_skipGuiShaders')
  else
    Result := 0;
end;

function CvarBool(const AContext: TGuiContext; const AName: AnsiString): Boolean;
begin
  Result := Assigned(AContext.Cvars) and AContext.Cvars.GetBool(AName);
end;

function CvarInteger(const AContext: TGuiContext; const AName: AnsiString): Integer;
begin
  if Assigned(AContext.Cvars) then
    Result := AContext.Cvars.GetInteger(AName)
  else
    Result := 0;
end;

// idMat3 *= idMat3 with every step a float
procedure MultiplyMat3(var AMat: TIdMat3; const AOther: TIdMat3);
var
  LResult: TIdMat3;
  LRow, LColumn: Integer;
  LA, LB, LC: Single;
begin
  for LRow := 0 to 2 do
    for LColumn := 0 to 2 do
    begin
      LA := AMat.Rows[LRow].X * AOther.Rows[0].Items[LColumn];
      LB := AMat.Rows[LRow].Y * AOther.Rows[1].Items[LColumn];
      LC := AMat.Rows[LRow].Z * AOther.Rows[2].Items[LColumn];
      LA := LA + LB;
      LResult.Rows[LRow].Items[LColumn] := LA + LC;
    end;
  AMat := LResult;
end;

// idRotation::ToMat3 for an axis of (0, 0, 1)
function RotationMat3(const AAngle: Single): TIdMat3;
var
  LFactor, LHalf, LSin, LCos, LX, LY, LZ, LW, LX2, LY2, LZ2, LXX, LXY, LXZ, LYY, LYZ, LZZ, LWX, LWY, LWZ, LSum: Single;
begin
  LFactor := Single(Pi);
  LFactor := LFactor / 180.0;
  LFactor := LFactor * 0.5;
  LHalf := AAngle * LFactor;
  LSin := TIdMath.Sin(LHalf);
  LCos := TIdMath.Cos(LHalf);
  LX := 0.0 * LSin;
  LY := 0.0 * LSin;
  LZ := 1.0 * LSin;
  LW := LCos;
  LX2 := LX + LX;
  LY2 := LY + LY;
  LZ2 := LZ + LZ;
  LXX := LX * LX2;
  LXY := LX * LY2;
  LXZ := LX * LZ2;
  LYY := LY * LY2;
  LYZ := LY * LZ2;
  LZZ := LZ * LZ2;
  LWX := LW * LX2;
  LWY := LW * LY2;
  LWZ := LW * LZ2;
  LSum := LYY + LZZ;
  Result.Rows[0].X := 1.0 - LSum;
  Result.Rows[0].Y := LXY - LWZ;
  Result.Rows[0].Z := LXZ + LWY;
  Result.Rows[1].X := LXY + LWZ;
  LSum := LXX + LZZ;
  Result.Rows[1].Y := 1.0 - LSum;
  Result.Rows[1].Z := LYZ - LWX;
  Result.Rows[2].X := LXZ - LWY;
  Result.Rows[2].Y := LYZ + LWX;
  LSum := LXX + LYY;
  Result.Rows[2].Z := 1.0 - LSum;
end;

procedure SetupTransforms(const AWindow: TGuiWindow; const ADc: TGuiDrawContext; const AX, AY: Single);
var
  LTrans, LShear: TIdMat3;
  LOrigin: TIdVec3;
begin
  LTrans := TIdMat3.Identity;
  LOrigin.X := AWindow.Origin.X + AX;
  LOrigin.Y := AWindow.Origin.Y + AY;
  LOrigin.Z := 0.0;
  if AWindow.Rotate.Value <> 0.0 then
    LTrans := RotationMat3(AWindow.Rotate.Value);
  if (AWindow.Shear.X <> 0.0) or (AWindow.Shear.Y <> 0.0) then
  begin
    LShear := TIdMat3.Identity;
    LShear.Rows[0].Y := AWindow.Shear.X;
    LShear.Rows[1].X := AWindow.Shear.Y;
    MultiplyMat3(LTrans, LShear);
  end;
  if not LTrans.IsIdentity then
    ADc.SetTransformInfo(LOrigin, LTrans);
end;

procedure DrawShadowedText(const AWindow: TGuiWindow; const ADc: TGuiDrawContext);
var
  LShadow: TGuiRectangle;
  LWrap: Boolean;
begin
  LWrap := (AWindow.Flags and WIN_NOWRAP) = 0;
  if AWindow.TextShadow <> 0 then
  begin
    LShadow := AWindow.TextRect;
    LShadow.X := LShadow.X + AWindow.TextShadow;
    LShadow.Y := LShadow.Y + AWindow.TextShadow;
    ADc.DrawText(TIdStrings.RemoveColors(AWindow.Text.AsText), AWindow.TextScale.Value, AWindow.TextAlign,
      ADc.ColorBlack, LShadow, LWrap, -1);
  end;
  ADc.DrawText(AWindow.Text.AsText, AWindow.TextScale.Value, AWindow.TextAlign, AWindow.ForeColor.Value,
    AWindow.TextRect, LWrap, -1);
end;

class procedure TGuiWindowPainter.DrawText(const AWindow: TGuiWindow);
var
  LDc: TGuiDrawContext;
  LRect: TGuiRectangle;
  LRectangle: TGuiRectangle;
  LSum: Single;
begin
  LDc := AWindow.Context.DrawContext;
  if AWindow.Text.Length = 0 then
    Exit;
  DrawShadowedText(AWindow, LDc);
  if CvarBool(AWindow.Context, 'gui_edit') then
  begin
    LRect := AWindow.Rect.Value;
    LDc.EnableClipping(False);
    LRectangle := TGuiRectangle.Create(LRect.X, LRect.Y - 15, 100, 20);
    LDc.DrawText(AnsiString(Format('x: %d  y: %d', [TIdMath.Ftoi(LRect.X), TIdMath.Ftoi(LRect.Y)])), 0.25, 0,
      LDc.ColorWhite, LRectangle, False);
    LSum := LRect.W + LRect.H;
    LSum := LSum + 5;
    LRectangle := TGuiRectangle.Create(LRect.X + LRect.W, LSum, 100, 20);
    LDc.DrawText(AnsiString(Format('w: %d  h: %d', [TIdMath.Ftoi(LRect.W), TIdMath.Ftoi(LRect.H)])), 0.25, 0,
      LDc.ColorWhite, LRectangle, False);
    LDc.EnableClipping(True);
  end;
end;

class procedure TGuiWindowPainter.DrawBackground(const AWindow: TGuiWindow; const ARect: TGuiRectangle);
var
  LDc: TGuiDrawContext;
  LBackground: IGuiMaterial;
  LScaleX, LScaleY: Single;
begin
  LDc := AWindow.Context.DrawContext;
  if AWindow.BackColor.Value.W <> 0.0 then
    LDc.DrawFilledRect(ARect.X, ARect.Y, ARect.W, ARect.H, AWindow.BackColor.Value);
  LBackground := AWindow.GetBackground;
  if Assigned(LBackground) and (AWindow.MatColor.Value.W <> 0.0) then
  begin
    if (AWindow.Flags and WIN_NATURALMAT) <> 0 then
    begin
      LScaleX := ARect.W / LBackground.GetImageWidth;
      LScaleY := ARect.H / LBackground.GetImageHeight;
    end
    else
    begin
      LScaleX := AWindow.MatScaleX;
      LScaleY := AWindow.MatScaleY;
    end;
    LDc.DrawMaterial(ARect.X, ARect.Y, ARect.W, ARect.H, LBackground, AWindow.MatColor.Value, LScaleX, LScaleY);
  end;
end;

procedure DrawBorder(const AWindow: TGuiWindow; const ADc: TGuiDrawContext; const ARect: TGuiRectangle);
begin
  if ((AWindow.Flags and WIN_BORDER) <> 0) and (AWindow.BorderSize <> 0.0) and
    (AWindow.BorderColor.Value.W <> 0.0) then
    ADc.DrawRect(ARect.X, ARect.Y, ARect.W, ARect.H, AWindow.BorderSize, AWindow.BorderColor.Value);
end;

// idWindow::DebugDraw
procedure DebugDraw(const AWindow: TGuiWindow; const ADc: TGuiDrawContext);
var
  LContext: TGuiContext;
  LRect, LDrawRect, LClientRect: TGuiRectangle;
begin
  LContext := AWindow.Context;
  ADc.EnableClipping(False);
  LDrawRect := AWindow.DrawRect;
  if CvarInteger(LContext, 'gui_debug') = 1 then
    ADc.DrawRect(LDrawRect.X, LDrawRect.Y, LDrawRect.W, LDrawRect.H, 1, ADc.ColorRed)
  else if CvarInteger(LContext, 'gui_debug') = 2 then
  begin
    LRect := AWindow.Rect.Value;
    LClientRect := AWindow.ClientRect;
    // the buffer is static in the original and only the first line resets it
    if AWindow.Text.AsText <> '' then
      LContext.DebugBuffer := AWindow.Text.AsText + #10;
    LContext.DebugBuffer := LContext.DebugBuffer +
      AnsiString(Format('Rect: %s, %s, %s, %s'#10, [TGuiWindowPainter.FormatFixed(LRect.X, 1),
      TGuiWindowPainter.FormatFixed(LRect.Y, 1), TGuiWindowPainter.FormatFixed(LRect.W, 1),
      TGuiWindowPainter.FormatFixed(LRect.H, 1)]));
    LContext.DebugBuffer := LContext.DebugBuffer +
      AnsiString(Format('Draw Rect: %s, %s, %s, %s'#10, [TGuiWindowPainter.FormatFixed(LDrawRect.X, 1),
      TGuiWindowPainter.FormatFixed(LDrawRect.Y, 1), TGuiWindowPainter.FormatFixed(LDrawRect.W, 1),
      TGuiWindowPainter.FormatFixed(LDrawRect.H, 1)]));
    LContext.DebugBuffer := LContext.DebugBuffer +
      AnsiString(Format('Client Rect: %s, %s, %s, %s'#10, [TGuiWindowPainter.FormatFixed(LClientRect.X, 1),
      TGuiWindowPainter.FormatFixed(LClientRect.Y, 1), TGuiWindowPainter.FormatFixed(LClientRect.W, 1),
      TGuiWindowPainter.FormatFixed(LClientRect.H, 1)]));
    LContext.DebugBuffer := LContext.DebugBuffer +
      AnsiString(Format('Cursor: %s : %s'#10, [TGuiWindowPainter.FormatFixed(LContext.CursorX, 1),
      TGuiWindowPainter.FormatFixed(LContext.CursorY, 1)]));
    if Length(LContext.DebugBuffer) >= DEBUG_BUFFER_SIZE then
      raise EGuiDrawException.Create('the debug text of the windows does not fit its buffer of 16384 characters');
    ADc.DrawText(LContext.DebugBuffer, AWindow.TextScale.Value, AWindow.TextAlign, AWindow.ForeColor.Value,
      AWindow.TextRect, True);
  end;
  ADc.EnableClipping(True);
end;

procedure DrawCursor(const AWindow: TGuiWindow; const ADc: TGuiDrawContext);
var
  LContext: TGuiContext;
  LDesktop: TGuiWindow;
begin
  LContext := AWindow.Context;
  LDesktop := AWindow;
  if (LDesktop.Flags and WIN_MENUGUI) <> 0 then
    ADc.DrawCursor(LContext.CursorX, LContext.CursorY, 32.0)
  else
    ADc.DrawCursor(LContext.CursorX, LContext.CursorY, 64.0);
end;

class procedure TGuiWindowPainter.Redraw(const AWindow: TGuiWindow; const AX, AY: Single);
var
  LContext: TGuiContext;
  LDc: TGuiDrawContext;
  LTime, LSkip, LIndex: Integer;
  LOldOrigin: TIdVec3;
  LOldMat: TIdMat3;
  LChildX, LChildY: Single;
  LDraw: TGuiDrawWindow;
  LElapsed: Double;
begin
  LContext := AWindow.Context;
  LDc := LContext.DrawContext;
  LSkip := SkipShaders(LContext);
  if (LSkip = 1) or (not Assigned(LDc)) then
    Exit;
  LTime := LContext.Time;
  if ((AWindow.Flags and WIN_DESKTOP) <> 0) and (LSkip <> 3) then
    AWindow.RunTimeEvents(LTime);
  if LSkip = 2 then
    Exit;
  if (AWindow.Flags and WIN_SHOWTIME) <> 0 then
  begin
    // the quotient is passed to printf as a double: the reference computes it with the x87 in extended precision
    LElapsed := (LTime - AWindow.TimeLine) / 1000.0;
    LDc.DrawText(AnsiString(' ' + FormatFixed(LElapsed, 1) + ' seconds'#10) + LContext.StateDict.GetString('name'),
      0.35, 0, LDc.ColorWhite, TGuiRectangle.Create(100, 0, 80, 80), False);
  end;
  if (AWindow.Flags and WIN_SHOWCOORDS) <> 0 then
  begin
    LDc.EnableClipping(False);
    LDc.DrawText(AnsiString(Format('x: %d y: %d  cursorx: %d cursory: %d', [TIdMath.Ftoi(AWindow.Rect.Value.X),
      TIdMath.Ftoi(AWindow.Rect.Value.Y), TIdMath.Ftoi(LContext.CursorX), TIdMath.Ftoi(LContext.CursorY)])), 0.25, 0,
      LDc.ColorWhite, TGuiRectangle.Create(0, 0, 100, 20), False);
    LDc.EnableClipping(True);
  end;
  if not AWindow.Visible.Value then
    Exit;
  AWindow.CalcClientRect(0, 0);
  LDc.SetFont(AWindow.FontNum);
  LDc.SetSize(AWindow.ForceAspectWidth, AWindow.ForceAspectHeight);
  AWindow.OffsetRects(AX, AY);
  AWindow.ActualX := AWindow.DrawRect.X;
  AWindow.ActualY := AWindow.DrawRect.Y;
  LDc.GetTransformInfo(LOldOrigin, LOldMat);
  SetupTransforms(AWindow, LDc, AX, AY);
  AWindow.DrawBackground(AWindow.DrawRect);
  DrawBorder(AWindow, LDc, AWindow.DrawRect);
  if (AWindow.Flags and WIN_NOCLIP) = 0 then
    LDc.PushClipRect(AWindow.ClientRect);
  if LSkip < 5 then
    AWindow.Draw(LTime, AX, AY);
  if CvarInteger(LContext, 'gui_debug') <> 0 then
    DebugDraw(AWindow, LDc);
  LChildX := AWindow.ClientRect.X + AWindow.XOffset;
  LChildY := AWindow.ClientRect.Y + AWindow.YOffset;
  for LIndex := 0 to AWindow.DrawWindowCount - 1 do
  begin
    LDraw := AWindow.DrawWindows[LIndex];
    if LDraw.IsSimple then
      RedrawSimple(LDraw.Window, LChildX, LChildY)
    else
      LDraw.Window.Redraw(LChildX, LChildY);
  end;
  // put the transforms back to what they were before the children were processed
  LDc.SetTransformInfo(LOldOrigin, LOldMat);
  if (AWindow.Flags and WIN_NOCLIP) = 0 then
    LDc.PopClipRect;
  if CvarBool(LContext, 'gui_edit') or (((AWindow.Flags and WIN_DESKTOP) <> 0) and
    ((AWindow.Flags and WIN_NOCURSOR) = 0) and (not AWindow.HideCursor.Value) and
    (LContext.Active or ((AWindow.Flags and WIN_MENUGUI) <> 0))) then
  begin
    LDc.SetTransformInfo(TIdVec3.Create(0, 0, 0), TIdMat3.Identity);
    DrawCursor(AWindow, LDc);
  end;
  if (CvarInteger(LContext, 'gui_debug') <> 0) and ((AWindow.Flags and WIN_DESKTOP) <> 0) then
  begin
    LDc.EnableClipping(False);
    LDc.DrawText(AnsiString('x: ' + FormatFixed(LContext.CursorX, 0) + ' y: ' + FormatFixed(LContext.CursorY, 0)), 0.25,
      0, LDc.ColorWhite, TGuiRectangle.Create(0, 0, 100, 20), False);
    LDc.DrawText(LContext.SourceFile, 0.25, 0, LDc.ColorWhite, TGuiRectangle.Create(0, 20, 300, 20), False);
    LDc.EnableClipping(True);
  end;
  AWindow.OffsetRects(-AX, -AY);
end;

class procedure TGuiWindowPainter.RedrawSimple(const AWindow: TGuiWindow; const AX, AY: Single);
var
  LContext: TGuiContext;
  LDc: TGuiDrawContext;
  LBackground: IGuiMaterial;
  LScaleX, LScaleY: Single;
  LRect: TGuiRectangle;
begin
  LContext := AWindow.Context;
  LDc := LContext.DrawContext;
  if not AWindow.Visible.Value then
    Exit;
  AWindow.CalcClientRect(0, 0);
  LDc.SetFont(AWindow.FontNum);
  AWindow.OffsetRects(AX, AY);
  SetupTransforms(AWindow, LDc, AX, AY);
  if (AWindow.Flags and WIN_NOCLIP) <> 0 then
    LDc.EnableClipping(False);
  LRect := AWindow.DrawRect;
  // idSimpleWindow::DrawBackground: any positive alpha
  if AWindow.BackColor.Value.W > 0.0 then
    LDc.DrawFilledRect(LRect.X, LRect.Y, LRect.W, LRect.H, AWindow.BackColor.Value);
  LBackground := AWindow.GetBackground;
  if Assigned(LBackground) and (AWindow.MatColor.Value.W > 0.0) then
  begin
    if (AWindow.Flags and WIN_NATURALMAT) <> 0 then
    begin
      LScaleX := LRect.W / LBackground.GetImageWidth;
      LScaleY := LRect.H / LBackground.GetImageHeight;
    end
    else
    begin
      LScaleX := AWindow.MatScaleX;
      LScaleY := AWindow.MatScaleY;
    end;
    LDc.DrawMaterial(LRect.X, LRect.Y, LRect.W, LRect.H, LBackground, AWindow.MatColor.Value, LScaleX, LScaleY);
  end;
  // idSimpleWindow::DrawBorderAndCaption: no test of the alpha of the border
  if ((AWindow.Flags and WIN_BORDER) <> 0) and (AWindow.BorderSize <> 0.0) then
    LDc.DrawRect(LRect.X, LRect.Y, LRect.W, LRect.H, AWindow.BorderSize, AWindow.BorderColor.Value);
  DrawShadowedText(AWindow, LDc);
  LDc.SetTransformInfo(TIdVec3.Create(0, 0, 0), TIdMat3.Identity);
  if (AWindow.Flags and WIN_NOCLIP) <> 0 then
    LDc.EnableClipping(True);
  AWindow.OffsetRects(-AX, -AY);
end;

end.
