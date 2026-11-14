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
  ///   Static functions, no state besides the table of the sines of the columns. The sine is
  ///   TSoftExtended.Sin: equal to the one of the processor except, rarely, for the last of the 64 bits
  /// </remarks>
  TRendererX87 = class
  strict private
    class function AngleToRadians: TSoftExtended; static;
  public
    /// <summary>Sin(AAngle * ANGLE_T_TO_RAD) with 64 bits of mantissa (ANGLE_T_TO_RAD of tables.pas)</summary>
    class function AngleSine(AAngle: Cardinal): TSoftExtended; static;
    /// <summary>dviewsin of R_SetupFrame: Sin(AViewAngle / $FFFFFFFF * 2 * pi)</summary>
    class function ViewSine(AViewAngle: Cardinal): Double; static;
    /// <summary>dviewcos of R_SetupFrame: Cos(AViewAngle / $FFFFFFFF * 2 * pi)</summary>
    class function ViewCosine(AViewAngle: Cardinal): Double; static;
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

{ TRendererX87 }

class function TRendererX87.AngleToRadians: TSoftExtended;
begin
  Result := TSoftExtended.FromMantissa(ANGLE_TO_RADIANS_MANTISSA, ANGLE_TO_RADIANS_EXPONENT);
end;

class function TRendererX87.AngleSine(AAngle: Cardinal): TSoftExtended;
begin
  Result := TSoftExtended.Sin(TSoftExtended.FromInt64(AAngle) * AngleToRadians);
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

end.
