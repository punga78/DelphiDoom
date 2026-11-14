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
  DelphiDoom.MathCore.SoftExtended, DelphiDoom.MathCore.X87Double;

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

end.
