{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the floating point of the slopes of the      }
{  32 bit renderer                                                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The expressions are those of r_slopes.pas                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.SlopesX87;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The floating point expressions of r_slopes.pas (sloped floors and ceilings, sloped walls) with the result
  ///   of the 32 bit code (x87 FPU: every intermediate value has 64 bits of mantissa, every assignment to a
  ///   Double or a Single rounds), computed with TSoftExtended. The 64 bit renderer calls these where the 32 bit
  ///   one has the expression
  /// </summary>
  /// <remarks>
  ///   Always the exact way (TSoftExtended, some hundreds of nanoseconds per operation): the slopes are computed
  ///   once per point of a subsector, once per row of a span list and once per wall, never per pixel. The
  ///   divisions by FRACUNIT and WORLDUNIT (powers of two) are exact in a Double and are left to the caller.
  ///   Each function names the expression it replaces
  /// </remarks>
  TRendererSlopesX87 = class
  public
    /// <summary>
    ///   R_SlopesCalcSSPoint of r_slopes.pas: the world point (AWorldX, AWorldY, AWorldZ) on the screen
    /// </summary>
    class procedure ProjectPoint(AWorldX, AWorldY, AWorldZ, AViewX, AViewY, AViewZ, AProjection, AProjectionY,
      ACenterX, ACenterY: Integer; const AViewSine, AViewCosine: Double; out AScreenX, AScreenY, AScreenZ: Double);
      static;
    /// <summary>
    ///   (ANumerator) / (ADenominator + AScreenY * FRACUNIT) * AProjectionY of the world depth of a point, where
    ///   ADenominator is the integer -centeryfrac - FRACUNIT div 2
    /// </summary>
    class function WorldDepth(ANumerator, ADenominator: Integer; const AScreenY: Double;
      AProjectionY: Integer): Double; static;
    /// <summary>(AFirst - ASecond) / (AThird - AFourth) of the steps of an edge of a slope</summary>
    class function EdgeStep(const AFirst, ASecond, AThird, AFourth: Double): Double; static;
    /// <summary>AStart + AStep * (ARow - AScreenY) of the start of an edge on its first row</summary>
    class function EdgeStart(const AStart, AStep: Double; ARow: Integer; const AScreenY: Double): Double; static;
    /// <summary>
    ///   Theta := (1.0 / ATPos - 1.0 / AZ1) / (1.0 / AZ2 - 1.0 / AZ1) of the interpolation along an edge
    /// </summary>
    class function Theta(const ATPos, AZ1, AZ2: Double): Double; static;
    /// <summary>1.0 - ATheta stored in a Double (rTheta)</summary>
    class function ThetaComplement(const ATheta: Double): Double; static;
    /// <summary>Round(ARTheta * AWorldZ1 + ATheta * AWorldZ2): the world depth of a point of an edge</summary>
    class function RoundInterpolated(const ARTheta, ATheta, AWorldZ1, AWorldZ2: Double): Integer; static;
    /// <summary>
    ///   1.0 / AValue stored in a Single (inv_zleft and inv_zright of the spans of a slope): the quotient has 64
    ///   bits of mantissa before it is rounded to the 24 of a Single
    /// </summary>
    class function SingleReciprocal(const AValue: Single): Single; static;
    /// <summary>Round(AColumn * AStep) with the step of a line stored in a Single: the slope of a wall</summary>
    class function RoundColumnStep(AColumn: Integer; const AStep: Single): Integer; static;
    /// <summary>
    ///   AOrigin - AScale * AHeight stored in a Double: topfrac_dbl, bottomfrac_dbl, pixhigh_dbl, pixlow_dbl with
    ///   AOrigin = centeryfrac / WORLDUNIT, AScale = scale / FRACUNIT and AHeight = height / WORLDUNIT
    /// </summary>
    class function WallEdge(const AOrigin, AScale, AHeight: Double): Double; static;
    /// <summary>
    ///   -AScaleStep * AHeight1 + AScale * AHeightDifference / ACount stored in a Double: the *step_dbl of a
    ///   sloped wall (AScaleStep = rw_scalestep_dbl / FRACUNIT, AScale = rw_scale_dbl / FRACUNIT, the heights
    ///   divided by WORLDUNIT, ACount = rw_stopx - rw_x)
    /// </summary>
    class function WallEdgeStep(const AScaleStep, AHeight1, AScale, AHeightDifference: Double;
      ACount: Integer): Double; static;
  end;

implementation

uses
  DelphiDoom.MathCore.SoftExtended;

{ TRendererSlopesX87 }

// an infinity or a NaN (what a division by zero leaves in a Double) is not a number for a TSoftExtended
function IsFinite(const AValue: Double): Boolean;
begin
  Result := ((PUInt64(@AValue)^ shr 52) and $7FF) <> $7FF;
end;

class procedure TRendererSlopesX87.ProjectPoint(AWorldX, AWorldY, AWorldZ, AViewX, AViewY, AViewZ, AProjection,
  AProjectionY, ACenterX, ACenterY: Integer; const AViewSine, AViewCosine: Double;
  out AScreenX, AScreenY, AScreenZ: Double);
var
  LRelativeX, LRelativeY, LRelativeZ: Double;
  LDepth, LCosine, LSine, LTX, LXScale, LYScale: Double;
  LDenominator: TSoftExtended;
begin
  // an integer divided by 65536 is exact in a Double
  LRelativeX := (AWorldX - AViewX) / 65536;
  LRelativeY := (AWorldY - AViewY) / 65536;
  LRelativeZ := (AWorldZ - AViewZ) / 65536;
  LCosine := AViewCosine;
  LSine := AViewSine;

  LDenominator := TSoftExtended.FromDouble(LRelativeX) * TSoftExtended.FromDouble(LCosine) +
    TSoftExtended.FromDouble(LRelativeY) * TSoftExtended.FromDouble(LSine);
  if LDenominator.IsZero then
  begin
    // a point on the line of the view plane: the division by zero (an infinity, with the exceptions of the
    // arithmetic masked as the games do) is not something a TSoftExtended can hold; the result is the native one
    LDepth := 1.0 / (LRelativeX * LCosine + LRelativeY * LSine);
    AScreenZ := AProjection * LDepth;
    LXScale := AScreenZ / 65536;
    LTX := LRelativeX * LSine - LRelativeY * LCosine;
    AScreenX := ACenterX + LTX * LXScale;
    LYScale := AProjectionY / 65536 * LDepth;
    AScreenY := ACenterY - LRelativeZ * LYScale;
    Exit;
  end;
  LDepth := (TSoftExtended.FromInt64(1) / LDenominator).ToDouble;

  AScreenZ := (TSoftExtended.FromInt64(AProjection) * TSoftExtended.FromDouble(LDepth)).ToDouble;
  LXScale := AScreenZ / 65536;

  LTX := (TSoftExtended.FromDouble(LRelativeX) * TSoftExtended.FromDouble(LSine) -
    TSoftExtended.FromDouble(LRelativeY) * TSoftExtended.FromDouble(LCosine)).ToDouble;

  AScreenX := (TSoftExtended.FromInt64(ACenterX) +
    TSoftExtended.FromDouble(LTX) * TSoftExtended.FromDouble(LXScale)).ToDouble;

  // projectiony / FRACUNIT is an exact quotient, then a product with the depth rounded to a Double
  LYScale := (TSoftExtended.FromDouble(AProjectionY / 65536) * TSoftExtended.FromDouble(LDepth)).ToDouble;
  AScreenY := (TSoftExtended.FromInt64(ACenterY) -
    TSoftExtended.FromDouble(LRelativeZ) * TSoftExtended.FromDouble(LYScale)).ToDouble;
end;

class function TRendererSlopesX87.WorldDepth(ANumerator, ADenominator: Integer; const AScreenY: Double;
  AProjectionY: Integer): Double;
var
  LDenominator: TSoftExtended;
begin
  if not IsFinite(AScreenY) then
  begin
    Result := ANumerator / (ADenominator + AScreenY * 65536) * AProjectionY;
    Exit;
  end;
  LDenominator := TSoftExtended.FromInt64(ADenominator) +
    TSoftExtended.FromDouble(AScreenY) * TSoftExtended.FromInt64(65536);
  if LDenominator.IsZero then
    // a division by zero: the arithmetic of the processor, not a TSoftExtended
    Result := ANumerator / (ADenominator + AScreenY * 65536) * AProjectionY
  else
    Result := (TSoftExtended.FromInt64(ANumerator) / LDenominator * TSoftExtended.FromInt64(AProjectionY)).ToDouble;
end;

class function TRendererSlopesX87.EdgeStep(const AFirst, ASecond, AThird, AFourth: Double): Double;
var
  LDenominator: TSoftExtended;
begin
  if not (IsFinite(AFirst) and IsFinite(ASecond) and IsFinite(AThird) and IsFinite(AFourth)) then
  begin
    Result := (AFirst - ASecond) / (AThird - AFourth);
    Exit;
  end;
  LDenominator := TSoftExtended.FromDouble(AThird) - TSoftExtended.FromDouble(AFourth);
  if LDenominator.IsZero then
    // a division by zero: the arithmetic of the processor, not a TSoftExtended
    Result := (AFirst - ASecond) / (AThird - AFourth)
  else
    Result := ((TSoftExtended.FromDouble(AFirst) - TSoftExtended.FromDouble(ASecond)) / LDenominator).ToDouble;
end;

class function TRendererSlopesX87.EdgeStart(const AStart, AStep: Double; ARow: Integer;
  const AScreenY: Double): Double;
begin
  if not (IsFinite(AStart) and IsFinite(AStep) and IsFinite(AScreenY)) then
    Result := AStart + AStep * (ARow - AScreenY)
  else
    Result := (TSoftExtended.FromDouble(AStart) + TSoftExtended.FromDouble(AStep) *
      (TSoftExtended.FromInt64(ARow) - TSoftExtended.FromDouble(AScreenY))).ToDouble;
end;

class function TRendererSlopesX87.Theta(const ATPos, AZ1, AZ2: Double): Double;
var
  LOne: TSoftExtended;
  LInverse1, LDenominator: TSoftExtended;
begin
  if (ATPos = 0) or (AZ1 = 0) or (AZ2 = 0) or not (IsFinite(ATPos) and IsFinite(AZ1) and IsFinite(AZ2)) then
  begin
    // a division by zero: the arithmetic of the processor, not a TSoftExtended
    Result := (1.0 / ATPos - 1.0 / AZ1) / (1.0 / AZ2 - 1.0 / AZ1);
    Exit;
  end;
  LOne := TSoftExtended.FromInt64(1);
  LInverse1 := LOne / TSoftExtended.FromDouble(AZ1);
  LDenominator := LOne / TSoftExtended.FromDouble(AZ2) - LInverse1;
  if LDenominator.IsZero then
    Result := (1.0 / ATPos - 1.0 / AZ1) / (1.0 / AZ2 - 1.0 / AZ1)
  else
    Result := ((LOne / TSoftExtended.FromDouble(ATPos) - LInverse1) / LDenominator).ToDouble;
end;

class function TRendererSlopesX87.ThetaComplement(const ATheta: Double): Double;
begin
  if not IsFinite(ATheta) then
    Result := 1.0 - ATheta
  else
    Result := (TSoftExtended.FromInt64(1) - TSoftExtended.FromDouble(ATheta)).ToDouble;
end;

class function TRendererSlopesX87.RoundInterpolated(const ARTheta, ATheta, AWorldZ1, AWorldZ2: Double): Integer;
begin
  if not (IsFinite(ARTheta) and IsFinite(ATheta) and IsFinite(AWorldZ1) and IsFinite(AWorldZ2)) then
    Result := Round(ARTheta * AWorldZ1 + ATheta * AWorldZ2)
  else
    Result := Integer((TSoftExtended.FromDouble(ARTheta) * TSoftExtended.FromDouble(AWorldZ1) +
      TSoftExtended.FromDouble(ATheta) * TSoftExtended.FromDouble(AWorldZ2)).Round);
end;

class function TRendererSlopesX87.SingleReciprocal(const AValue: Single): Single;
begin
  if AValue = 0 then
    // a division by zero: the arithmetic of the processor, not a TSoftExtended
    Result := 1.0 / AValue
  else
    Result := (TSoftExtended.FromInt64(1) / TSoftExtended.FromDouble(AValue)).ToSingle;
end;

class function TRendererSlopesX87.RoundColumnStep(AColumn: Integer; const AStep: Single): Integer;
begin
  Result := Integer((TSoftExtended.FromInt64(AColumn) * TSoftExtended.FromDouble(AStep)).Round);
end;

class function TRendererSlopesX87.WallEdge(const AOrigin, AScale, AHeight: Double): Double;
begin
  Result := (TSoftExtended.FromDouble(AOrigin) -
    TSoftExtended.FromDouble(AScale) * TSoftExtended.FromDouble(AHeight)).ToDouble;
end;

class function TRendererSlopesX87.WallEdgeStep(const AScaleStep, AHeight1, AScale, AHeightDifference: Double;
  ACount: Integer): Double;
begin
  if ACount = 0 then
  begin
    // a division by zero: the arithmetic of the processor, not a TSoftExtended
    Result := -AScaleStep * AHeight1 + AScale * AHeightDifference / ACount;
    Exit;
  end;
  Result := (-TSoftExtended.FromDouble(AScaleStep) * TSoftExtended.FromDouble(AHeight1) +
    TSoftExtended.FromDouble(AScale) * TSoftExtended.FromDouble(AHeightDifference) /
      TSoftExtended.FromInt64(ACount)).ToDouble;
end;

end.
