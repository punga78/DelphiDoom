{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the floating point of the 32 bit renderer    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The expressions are those of r_main.pas, r_plane.pas and r_scale.pas        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.X87;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.SoftExtended, DelphiDoom.MathCore.SoftArcTan, DelphiDoom.MathCore.X87Double;

type
  /// <summary>
  ///   The floating point expressions of the software renderer with the result of the 32 bit code (x87 FPU:
  ///   every intermediate value has 64 bits of mantissa, the sine is the one of the processor), computed
  ///   without the FPU. The 64 bit renderer calls these where the 32 bit one has the expression, so that both
  ///   draw the same pixels; the 32 bit renderer keeps its own code
  /// </summary>
  /// <remarks>
  ///   Static functions, no state besides a table of sines already computed (one per thread). The sine is
  ///   TSoftExtended.Sin: equal to the one of the processor except, rarely, for the last of the 64 bits
  /// </remarks>
  TRendererX87 = class
  strict private
    class function AngleToRadians: TSoftExtended; static;
  public
    /// <summary>Sin(AAngle * ANGLE_T_TO_RAD) with 64 bits of mantissa (ANGLE_T_TO_RAD of tables.pas)</summary>
    class function AngleSine(AAngle: Cardinal): TSoftExtended; static;
    /// <summary>
    ///   Sin(AAngle * ANGLE_T_TO_RAD) stored in a Single: ds_sine and ds_viewsine of a flat with a texture
    ///   angle (the angle may be negative: "-ds_angle" of an unsigned angle is a negative number of 64 bits)
    /// </summary>
    class function AngleSineSingle(AAngle: Int64): Single; static;
    /// <summary>Cos(AAngle * ANGLE_T_TO_RAD) stored in a Single: ds_cosine and ds_viewcosine</summary>
    class function AngleCosineSingle(AAngle: Int64): Single; static;
    /// <summary>
    ///   Round(Sin(AAngle * ANGLE_T_TO_RAD) * ADistance), or the cosine: the corners of the view frustum of the
    ///   slopes (r_slopes.pas)
    /// </summary>
    class function RoundAngleProduct(AAngle: Cardinal; ADistance: Integer; ACosine: Boolean): Integer; static;
    /// <summary>The same with Trunc instead of Round (the clipper of the 3D floors, r_3dfloors.pas)</summary>
    class function TruncAngleProduct(AAngle: Cardinal; ADistance: Integer; ACosine: Boolean): Integer; static;
    /// <summary>dviewsin of R_SetupFrame: Sin(AViewAngle / $FFFFFFFF * 2 * pi)</summary>
    class function ViewSine(AViewAngle: Cardinal): Double; static;
    /// <summary>dviewcos of R_SetupFrame: Cos(AViewAngle / $FFFFFFFF * 2 * pi)</summary>
    class function ViewCosine(AViewAngle: Cardinal): Double; static;
    /// <summary>relative_aspect of R_InitAspect: AWidth / AHeight / (4 / 3), the biggest mode of the monitor</summary>
    class function MonitorAspect(AWidth, AHeight: Integer): Double; static;
    /// <summary>AAspect / (4 / 3) of R_GetRelativeAspect (a forced aspect)</summary>
    class function AspectOverFourThirds(const AAspect: Double): Double; static;
    /// <summary>planerelativeaspect: 320 / 200 * AScreenHeight / AScreenWidth * AMonitorAspect</summary>
    class function PlaneRelativeAspect(AScreenHeight, AScreenWidth: Integer;
      const AMonitorAspect: Double): Double; static;
    /// <summary>
    ///   The steps of a span of R_MapPlane: slope := (APlaneHeight / ARows) * AAspect (a Double),
    ///   AXStep := Round(ASine * slope), AYStep := Round(ACosine * slope). Always the exact way
    /// </summary>
    class procedure PlaneStepsExact(APlaneHeight, ARows: Integer; const AAspect, ASine, ACosine: Double;
      out AXStep, AYStep: Integer); static;
    /// <summary>The same; the native result is used when it is certainly the one of the FPU</summary>
    class procedure PlaneSteps(APlaneHeight, ARows: Integer; const AAspect, ASine, ACosine: Double;
      out AXStep, AYStep: Integer); static; inline;
    /// <summary>
    ///   R_ScaleFromGlobalAngle_DBL: num := AProjectionY * Sin(AAngleB * ANGLE_T_TO_RAD),
    ///   den := ADistance * Sin(AAngleA * ANGLE_T_TO_RAD), (num / den) * FRACUNIT kept in 256..AMaxScale
    /// </summary>
    class function ScaleFromAngles(AProjectionY, ADistance: Integer; AAngleA, AAngleB: Cardinal;
      AMaxScale: Integer): Double; static;
    /// <summary>
    ///   squaredist of R_MarkDLights: dx := AX - ALightX (a Single), the same for y and z,
    ///   dx * dx + dy * dy + dz * dz stored in a Single
    /// </summary>
    class function LightSquareDistance(const AX, AY, AZ, ALightX, ALightY, ALightZ: Single): Single; static;
    /// <summary>w of R_DrawVisLight: 2 * ARadius * AWidthFactor / ADefaultWidthFactor stored in a Single</summary>
    class function LightWidth(const ARadius: Single; AWidthFactor, ADefaultWidthFactor: Integer): Single; static;
    /// <summary>
    ///   distance of the per pixel slope spans (r_slopes): Round(1.0 / (ARTheta * AInverseLeft + ATheta *
    ///   AInverseRight)), the two inverses are Single. Always the exact way; 0 when the sum is 0 (the FPU gives
    ///   the integer indefinite, whose low 32 bits are 0)
    /// </summary>
    class function SlopeInverseDistanceExact(ARTheta, ATheta: Integer; const AInverseLeft, AInverseRight: Single): Integer;
      static;
    /// <summary>The same; the native result is used when it is certainly the one of the FPU</summary>
    class function SlopeInverseDistance(ARTheta, ATheta: Integer; const AInverseLeft, AInverseRight: Single): Integer;
      static;
    /// <summary>
    ///   fov of R_InitTextureMapping: Round(ArcTan(AAspect) * AFineAngles / D_PI) with the D_PI of tables.pas.
    ///   The arc tangent is TSoftArcTan: the same integer as the FPU unless the value is within 1e-18 of a half
    /// </summary>
    class function FieldOfView(const AAspect: Double; AFineAngles: Integer): Integer; static;
    /// <summary>
    ///   The angle of a column of a voxel: Round(ArcTan2(AY, AX) * (ANG180 / D_PI)) (r_voxels.pas)
    /// </summary>
    class function VoxelColumnAngle(AY, AX: Integer): Int64; static;
    /// <summary>
    ///   The turn of a spinning voxel: Round(((ALevelTime + ATicFraction / FRACUNIT) / ATicRate * ASpin) *
    ///   (ANGLE_MAX / 360)); with AWithFraction false the paused game one, without the fraction of the tic
    /// </summary>
    class function VoxelSpinAngle(ALevelTime, ATicFraction, ATicRate: Integer; ASpin: Int64;
      AWithFraction: Boolean): Int64; static;
    /// <summary>
    ///   distf of R_AdjustTeleportZoom, a Single: Sqr(ATeleportTics / FRACUNIT) / (AZoom / FRACUNIT); the
    ///   distance is Round(distf * FRACUNIT), computed by TeleportDistance
    /// </summary>
    class function TeleportDistance(ATeleportTics, AZoom: Integer): Integer; static;
    /// <summary>
    ///   GetOffset of gl_setup.pas: Round(Sqrt(a * a + b * b) * FRACUNIT) with a and b Singles of the two
    ///   differences over FRACUNIT (the length of a wall of the OpenGL renderer)
    /// </summary>
    class function WallOffset(ADeltaX, ADeltaY: Integer): Integer; static;
    /// <summary>
    ///   R_PointToScreenBufferEx of r_utils.pas: the world point, as its distances from the view (ADeltaX, ADeltaY,
    ///   ADeltaZ), on the screen. Every intermediate value is stored in a Single, as in the old code. Gives False,
    ///   leaving the outputs alone, when the point is at the plane of the view or a value is out of the range of a
    ///   Single: the caller then uses its own code (the FPU would give an infinity)
    /// </summary>
    class function ScreenPoint(ADeltaX, ADeltaY, ADeltaZ, AViewCosine, AViewSine, AProjection, AProjectionY,
      ACenterX, ACenterY, AViewWidth, AViewHeight: Integer; out AX, AY: Integer; out AInside: Boolean): Boolean;
      static;
  end;

implementation

const
  // 2 * 3.141592657 / $100000000 as the 32 bit compiler folds it (D_PI of tables.pas is not Pi)
  ANGLE_TO_RADIANS_MANTISSA = UInt64($C90FDAA5CACCB9CF);
  ANGLE_TO_RADIANS_EXPONENT = -93;
  // Pi of the System unit as an Extended
  PI_MANTISSA = UInt64($C90FDAA22168C235);
  PI_EXPONENT = -62;
  FRACTION_UNIT = 65536;
  MIN_SCALE = 256;
  SINE_CACHE_BITS = 11;
  SINE_CACHE_SIZE = 1 shl SINE_CACHE_BITS;

// The sines already computed, one table per thread (no lock, nothing shared): a slot holds the last angle
// that fell on it
threadvar
  SineCacheAngles: array[0..SINE_CACHE_SIZE - 1] of Cardinal;
  SineCacheValues: array[0..SINE_CACHE_SIZE - 1] of TSoftExtended;
  SineCacheUsed: array[0..SINE_CACHE_SIZE - 1] of Boolean;

{ TRendererX87 }

class function TRendererX87.AngleToRadians: TSoftExtended;
begin
  Result := TSoftExtended.FromMantissa(ANGLE_TO_RADIANS_MANTISSA, ANGLE_TO_RADIANS_EXPONENT);
end;

class function TRendererX87.AngleSine(AAngle: Cardinal): TSoftExtended;
var
  LSlot: Integer;
begin
  // the angle of a column of the screen comes back at every frame: its sine is kept
  LSlot := Integer((AAngle * Cardinal(2654435761)) shr (32 - SINE_CACHE_BITS));
  if SineCacheUsed[LSlot] and (SineCacheAngles[LSlot] = AAngle) then
    Exit(SineCacheValues[LSlot]);
  Result := TSoftExtended.Sin(TSoftExtended.FromInt64(AAngle) * AngleToRadians);
  SineCacheAngles[LSlot] := AAngle;
  SineCacheValues[LSlot] := Result;
  SineCacheUsed[LSlot] := True;
end;

class function TRendererX87.AngleSineSingle(AAngle: Int64): Single;
begin
  Result := TSoftExtended.Sin(TSoftExtended.FromInt64(AAngle) * AngleToRadians).ToSingle;
end;

class function TRendererX87.AngleCosineSingle(AAngle: Int64): Single;
begin
  Result := TSoftExtended.Cos(TSoftExtended.FromInt64(AAngle) * AngleToRadians).ToSingle;
end;

class function TRendererX87.RoundAngleProduct(AAngle: Cardinal; ADistance: Integer; ACosine: Boolean): Integer;
var
  LArgument: TSoftExtended;
begin
  LArgument := TSoftExtended.FromInt64(AAngle) * AngleToRadians;
  if ACosine then
    Result := Integer((TSoftExtended.Cos(LArgument) * TSoftExtended.FromInt64(ADistance)).Round)
  else
    Result := Integer((TSoftExtended.Sin(LArgument) * TSoftExtended.FromInt64(ADistance)).Round);
end;

class function TRendererX87.TruncAngleProduct(AAngle: Cardinal; ADistance: Integer; ACosine: Boolean): Integer;
var
  LArgument: TSoftExtended;
begin
  LArgument := TSoftExtended.FromInt64(AAngle) * AngleToRadians;
  if ACosine then
    Result := Integer((TSoftExtended.Cos(LArgument) * TSoftExtended.FromInt64(ADistance)).Truncate)
  else
    Result := Integer((TSoftExtended.Sin(LArgument) * TSoftExtended.FromInt64(ADistance)).Truncate);
end;

class function TRendererX87.ViewSine(AViewAngle: Cardinal): Double;
begin
  Result := TSoftExtended.Sin(TSoftExtended.FromInt64(AViewAngle) / TSoftExtended.FromInt64($FFFFFFFF) *
    TSoftExtended.FromInt64(2) * TSoftExtended.FromMantissa(PI_MANTISSA, PI_EXPONENT)).ToDouble;
end;

class function TRendererX87.ViewCosine(AViewAngle: Cardinal): Double;
begin
  Result := TSoftExtended.Cos(TSoftExtended.FromInt64(AViewAngle) / TSoftExtended.FromInt64($FFFFFFFF) *
    TSoftExtended.FromInt64(2) * TSoftExtended.FromMantissa(PI_MANTISSA, PI_EXPONENT)).ToDouble;
end;

class function TRendererX87.MonitorAspect(AWidth, AHeight: Integer): Double;
begin
  // 4 / 3 is folded by the 32 bit compiler in an Extended
  Result := (TSoftExtended.FromInt64(AWidth) / TSoftExtended.FromInt64(AHeight) /
    TSoftExtended.FromRatio(4, 3)).ToDouble;
end;

class function TRendererX87.AspectOverFourThirds(const AAspect: Double): Double;
begin
  Result := (TSoftExtended.FromDouble(AAspect) / TSoftExtended.FromRatio(4, 3)).ToDouble;
end;

class function TRendererX87.PlaneRelativeAspect(AScreenHeight, AScreenWidth: Integer;
  const AMonitorAspect: Double): Double;
begin
  Result := (TSoftExtended.FromRatio(320, 200) * TSoftExtended.FromInt64(AScreenHeight) /
    TSoftExtended.FromInt64(AScreenWidth) * TSoftExtended.FromDouble(AMonitorAspect)).ToDouble;
end;

class procedure TRendererX87.PlaneStepsExact(APlaneHeight, ARows: Integer; const AAspect, ASine, ACosine: Double;
  out AXStep, AYStep: Integer);
var
  LSlope: Double;
begin
  LSlope := (TSoftExtended.FromInt64(APlaneHeight) / TSoftExtended.FromInt64(ARows) *
    TSoftExtended.FromDouble(AAspect)).ToDouble;
  AXStep := TX87Double.RoundProductExact(ASine, LSlope);
  AYStep := TX87Double.RoundProductExact(ACosine, LSlope);
end;

class procedure TRendererX87.PlaneSteps(APlaneHeight, ARows: Integer; const AAspect, ASine, ACosine: Double;
  out AXStep, AYStep: Integer);
{$IF SizeOf(Extended) > SizeOf(Double)}
var
  LSlope: Double;
begin
  LSlope := (APlaneHeight / ARows) * AAspect;
  AXStep := Integer(Round(ASine * LSlope));
  AYStep := Integer(Round(ACosine * LSlope));
end;
{$ELSE}
var
  LSlope: Double;
  LX: Double;
  LY: Double;
begin
  LSlope := (APlaneHeight / ARows) * AAspect;
  LX := ASine * LSlope;
  LY := ACosine * LSlope;
  if TX87Double.CanRound(LX, Abs(LX)) and TX87Double.CanRound(LY, Abs(LY)) then
  begin
    AXStep := Round(LX);
    AYStep := Round(LY);
  end
  else
    PlaneStepsExact(APlaneHeight, ARows, AAspect, ASine, ACosine, AXStep, AYStep);
end;
{$IFEND}

class function TRendererX87.ScaleFromAngles(AProjectionY, ADistance: Integer; AAngleA, AAngleB: Cardinal;
  AMaxScale: Integer): Double;
var
  LNumerator: Double;
  LDenominator: Double;
begin
  LNumerator := (TSoftExtended.FromInt64(AProjectionY) * AngleSine(AAngleB)).ToDouble;
  LDenominator := (TSoftExtended.FromInt64(ADistance) * AngleSine(AAngleA)).ToDouble;
  if LDenominator = 0 then
  begin
    if LNumerator < 0 then
      Result := MIN_SCALE
    else
      Result := AMaxScale;
  end
  else
  begin
    Result := (TSoftExtended.FromDouble(LNumerator) / TSoftExtended.FromDouble(LDenominator) *
      TSoftExtended.FromInt64(FRACTION_UNIT)).ToDouble;
    if Result < MIN_SCALE then
      Result := MIN_SCALE
    else if Result > AMaxScale then
      Result := AMaxScale;
  end;
end;

class function TRendererX87.LightSquareDistance(const AX, AY, AZ, ALightX, ALightY, ALightZ: Single): Single;
var
  LX, LY, LZ: TSoftExtended;
begin
  // each difference is stored in a Single before it is squared
  LX := TSoftExtended.FromDouble((TSoftExtended.FromDouble(AX) - TSoftExtended.FromDouble(ALightX)).ToSingle);
  LY := TSoftExtended.FromDouble((TSoftExtended.FromDouble(AY) - TSoftExtended.FromDouble(ALightY)).ToSingle);
  LZ := TSoftExtended.FromDouble((TSoftExtended.FromDouble(AZ) - TSoftExtended.FromDouble(ALightZ)).ToSingle);
  Result := (LX * LX + LY * LY + LZ * LZ).ToSingle;
end;

class function TRendererX87.LightWidth(const ARadius: Single; AWidthFactor, ADefaultWidthFactor: Integer): Single;
begin
  Result := (TSoftExtended.FromInt64(2) * TSoftExtended.FromDouble(ARadius) * TSoftExtended.FromInt64(AWidthFactor) /
    TSoftExtended.FromInt64(ADefaultWidthFactor)).ToSingle;
end;

class function TRendererX87.SlopeInverseDistanceExact(ARTheta, ATheta: Integer;
  const AInverseLeft, AInverseRight: Single): Integer;
var
  LSum: TSoftExtended;
begin
  // the products have at most 34 bits: they are exact; the sum is rounded to the 64 bits of the FPU
  LSum := TSoftExtended.FromInt64(ARTheta) * TSoftExtended.FromDouble(AInverseLeft) +
    TSoftExtended.FromInt64(ATheta) * TSoftExtended.FromDouble(AInverseRight);
  if LSum.IsZero then
    Exit(0);
  Result := Integer((TSoftExtended.FromInt64(1) / LSum).Round);
end;

class function TRendererX87.SlopeInverseDistance(ARTheta, ATheta: Integer;
  const AInverseLeft, AInverseRight: Single): Integer;
{$IF SizeOf(Extended) > SizeOf(Double)}
begin
  Result := Round(1.0 / (ARTheta * AInverseLeft + ATheta * AInverseRight));
end;
{$ELSE}
var
  LValue: Double;
begin
  // each product is exact in a Double and the sum is rounded to the nearest: the native quotient is within
  // 2^-52 of the exact one, and so is the one of the FPU
  LValue := ARTheta * Double(AInverseLeft) + ATheta * Double(AInverseRight);
  if LValue <> 0 then
  begin
    LValue := 1.0 / LValue;
    if TX87Double.CanRound(LValue, Abs(LValue)) then
      Exit(Round(LValue));
  end;
  Result := SlopeInverseDistanceExact(ARTheta, ATheta, AInverseLeft, AInverseRight);
end;
{$IFEND}

class function TRendererX87.FieldOfView(const AAspect: Double; AFineAngles: Integer): Integer;
begin
  // D_PI = 3.141592657 is a decimal literal of the 32 bit compiler: an Extended
  Result := Integer((TSoftArcTan.ArcTan(TSoftExtended.FromDouble(AAspect)) * TSoftExtended.FromInt64(AFineAngles) /
    TSoftExtended.FromRatio(3141592657, 1000000000)).Round);
end;

class function TRendererX87.VoxelColumnAngle(AY, AX: Integer): Int64;
begin
  // two integers choose the Single overload of ArcTan2 of System.Math: the arguments are Singles
  Result := (TSoftArcTan.ArcTan2(TSoftExtended.FromDouble(Single(AY)), TSoftExtended.FromDouble(Single(AX))) *
    (TSoftExtended.FromInt64($80000000) / TSoftExtended.FromRatio(3141592657, 1000000000))).Round;
end;

class function TRendererX87.VoxelSpinAngle(ALevelTime, ATicFraction, ATicRate: Integer; ASpin: Int64;
  AWithFraction: Boolean): Int64;
var
  LTime: TSoftExtended;
begin
  LTime := TSoftExtended.FromInt64(ALevelTime);
  if AWithFraction then
    LTime := LTime + TSoftExtended.FromInt64(ATicFraction) / TSoftExtended.FromInt64(FRACTION_UNIT);
  Result := ((LTime / TSoftExtended.FromInt64(ATicRate) * TSoftExtended.FromInt64(ASpin)) *
    TSoftExtended.FromRatio($FFFFFFFF, 360)).Round;
end;

class function TRendererX87.TeleportDistance(ATeleportTics, AZoom: Integer): Integer;
var
  LRatio: TSoftExtended;
  LDistance: Single;
begin
  LRatio := TSoftExtended.FromInt64(ATeleportTics) / TSoftExtended.FromInt64(FRACTION_UNIT);
  LDistance := (LRatio * LRatio / (TSoftExtended.FromInt64(AZoom) / TSoftExtended.FromInt64(FRACTION_UNIT))).ToSingle;
  Result := Integer((TSoftExtended.FromDouble(LDistance) * TSoftExtended.FromInt64(FRACTION_UNIT)).Round);
end;

class function TRendererX87.WallOffset(ADeltaX, ADeltaY: Integer): Integer;
var
  LX, LY: TSoftExtended;
begin
  LX := TSoftExtended.FromDouble((TSoftExtended.FromInt64(ADeltaX) / TSoftExtended.FromInt64(FRACTION_UNIT)).ToSingle);
  LY := TSoftExtended.FromDouble((TSoftExtended.FromInt64(ADeltaY) / TSoftExtended.FromInt64(FRACTION_UNIT)).ToSingle);
  Result := Integer((TSoftExtended.Sqrt(LX * LX + LY * LY) * TSoftExtended.FromInt64(FRACTION_UNIT)).Round);
end;

// a value that a Single keeps without overflow or underflow
function TrySingle(const AValue: TSoftExtended; out ASingle: Single): Boolean;
begin
  Result := AValue.IsZero or ((AValue.BinaryExponent + 63 < 100) and (AValue.BinaryExponent + 63 > -100));
  if Result then
    ASingle := AValue.ToSingle
  else
    ASingle := 0;
end;

class function TRendererX87.ScreenPoint(ADeltaX, ADeltaY, ADeltaZ, AViewCosine, AViewSine, AProjection,
  AProjectionY, ACenterX, ACenterY, AViewWidth, AViewHeight: Integer; out AX, AY: Integer;
  out AInside: Boolean): Boolean;
var
  LUnit, LTransX, LTransY, LTransZ, LCosine, LSine: TSoftExtended;
  LDepth, LHorizontal, LScaleX, LScaleY, LScreenX, LScreenY: Single;
begin
  Result := False;
  LUnit := TSoftExtended.FromInt64(FRACTION_UNIT);
  // each of these is a Single in the old code
  LTransX := TSoftExtended.FromDouble((TSoftExtended.FromInt64(ADeltaX) / LUnit).ToSingle);
  LTransY := TSoftExtended.FromDouble((TSoftExtended.FromInt64(ADeltaY) / LUnit).ToSingle);
  LTransZ := TSoftExtended.FromDouble((TSoftExtended.FromInt64(ADeltaZ) / LUnit).ToSingle);
  LCosine := TSoftExtended.FromDouble((TSoftExtended.FromInt64(AViewCosine) / LUnit).ToSingle);
  LSine := TSoftExtended.FromDouble((TSoftExtended.FromInt64(AViewSine) / LUnit).ToSingle);
  if not TrySingle(LTransX * LCosine + LTransY * LSine, LDepth) or (LDepth = 0) then
    Exit;
  if not TrySingle(TSoftExtended.FromInt64(AProjection) / LUnit / TSoftExtended.FromDouble(LDepth), LScaleX) then
    Exit;
  if not TrySingle(LTransX * LSine - LTransY * LCosine, LHorizontal) then
    Exit;
  if not TrySingle(TSoftExtended.FromInt64(ACenterX) +
    TSoftExtended.FromDouble(LHorizontal) * TSoftExtended.FromDouble(LScaleX), LScreenX) then
    Exit;
  if not TrySingle(TSoftExtended.FromInt64(AProjectionY) / LUnit / TSoftExtended.FromDouble(LDepth), LScaleY) then
    Exit;
  if not TrySingle(TSoftExtended.FromInt64(ACenterY) - LTransZ * TSoftExtended.FromDouble(LScaleY), LScreenY) then
    Exit;
  if (Abs(LScreenX) >= 2147483647.0) or (Abs(LScreenY) >= 2147483647.0) then
    Exit;
  AInside := (LScreenX < AViewWidth) and (LScreenX >= 0) and (LScreenY < AViewHeight) and (LScreenY >= 0);
  AX := Trunc(LScreenX);
  AY := Trunc(LScreenY);
  Result := True;
end;

end.
