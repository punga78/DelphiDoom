{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the scale of the texture of a wall            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.WallScale;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   R_ScaleFromGlobalAngle, R_ScaleFromGlobalAngle_Fixed and R_ScaleFromGlobalAngle_DBL
  ///   (r_scale.pas). What they read from globals (view angle, normal and distance of the
  ///   wall, projection, limit) comes in a TImagingScaleContext, and the sines from an
  ///   IImagingSineTable
  /// </summary>
  TImagingWallScale = class(TInterfacedObject, IImagingWallScale)
  private
    const
      MIN_SCALE = 256;
    var
      FSines: IImagingSineTable;
    class function FixedMul(AFirst, ASecond: Integer): Integer; static;
    class function FixedDiv(AFirst, ASecond: Integer): Integer; static;
    class function ShiftRightArithmetic(AValue, ABits: Integer): Integer; static;
    procedure Terms(const AContext: TImagingScaleContext; AVisAngle: Cardinal;
      out ANumerator, ADenominator: Integer);
    procedure Angles(const AContext: TImagingScaleContext; AVisAngle: Cardinal;
      out AAngleA, AAngleB: Cardinal);
  public
    constructor Create(const ASines: IImagingSineTable);
    function FromGlobalAngle(const AContext: TImagingScaleContext; AVisAngle: Cardinal;
      out AOverflow: Boolean): Integer;
    function FromGlobalAngleFixed(const AContext: TImagingScaleContext;
      AVisAngle: Cardinal): Integer;
    function FromGlobalAngleDouble(const AContext: TImagingScaleContext;
      AVisAngle: Cardinal): Double;
  end;

implementation

{ TImagingWallScale }

constructor TImagingWallScale.Create(const ASines: IImagingSineTable);
begin
  inherited Create;
  FSines := ASines;
end;

class function TImagingWallScale.FixedMul(AFirst, ASecond: Integer): Integer;
begin
  // the low 32 bits of the product shifted by 16 (imul + shrd of the engine)
  Result := Integer((Int64(AFirst) * Int64(ASecond)) shr IMAGING_FRACBITS);
end;

class function TImagingWallScale.ShiftRightArithmetic(AValue, ABits: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr ABits
  else
    Result := Integer((Cardinal(AValue) shr ABits) or not (Cardinal($FFFFFFFF) shr ABits));
end;

class function TImagingWallScale.FixedDiv(AFirst, ASecond: Integer): Integer;
var
  LAbsFirst: Integer;
  LAbsSecond: Integer;
begin
  if AFirst < 0 then
    LAbsFirst := -AFirst
  else
    LAbsFirst := AFirst;
  if ASecond < 0 then
    LAbsSecond := -ASecond
  else
    LAbsSecond := ASecond;
  if ShiftRightArithmetic(LAbsFirst, 14) >= LAbsSecond then
  begin
    if (AFirst xor ASecond) < 0 then
      Result := Integer($80000000)
    else
      Result := $7FFFFFFF;
  end
  else
    Result := Integer((Int64(AFirst) shl IMAGING_FRACBITS) div ASecond);
end;

procedure TImagingWallScale.Angles(const AContext: TImagingScaleContext; AVisAngle: Cardinal;
  out AAngleA, AAngleB: Cardinal);
begin
  AAngleA := IMAGING_ANGLE_90 + (AVisAngle - AContext.ViewAngle);
  AAngleB := IMAGING_ANGLE_90 + (AVisAngle - AContext.NormalAngle);
end;

procedure TImagingWallScale.Terms(const AContext: TImagingScaleContext; AVisAngle: Cardinal;
  out ANumerator, ADenominator: Integer);
var
  LAngleA: Cardinal;
  LAngleB: Cardinal;
begin
  Angles(AContext, AVisAngle, LAngleA, LAngleB);
  ANumerator := FixedMul(AContext.ProjectionY, FSines.Sine(LAngleB shr IMAGING_FRACBITS));
  ADenominator := FixedMul(AContext.Distance, FSines.Sine(LAngleA shr IMAGING_FRACBITS));
end;

function TImagingWallScale.FromGlobalAngle(const AContext: TImagingScaleContext;
  AVisAngle: Cardinal; out AOverflow: Boolean): Integer;
var
  LNumerator: Integer;
  LDenominator: Integer;
begin
  Terms(AContext, AVisAngle, LNumerator, LDenominator);
  // the engine compares the denominator with the integer part of the numerator
  if LDenominator > ShiftRightArithmetic(LNumerator, IMAGING_FRACBITS) then
  begin
    Result := FixedDiv(LNumerator, LDenominator);
    if Result > AContext.MaxScale then
    begin
      Result := AContext.MaxScale;
      AOverflow := AContext.PreciseOverflow;
    end
    else if Result < MIN_SCALE then
    begin
      Result := MIN_SCALE;
      AOverflow := AContext.PreciseOverflow;
    end
    else
      AOverflow := False;
  end
  else
  begin
    Result := AContext.MaxScale;
    AOverflow := AContext.PreciseOverflow;
  end;
end;

function TImagingWallScale.FromGlobalAngleFixed(const AContext: TImagingScaleContext;
  AVisAngle: Cardinal): Integer;
var
  LNumerator: Integer;
  LDenominator: Integer;
begin
  Terms(AContext, AVisAngle, LNumerator, LDenominator);
  if LDenominator > ShiftRightArithmetic(LNumerator, IMAGING_FRACBITS) then
  begin
    Result := FixedDiv(LNumerator, LDenominator);
    if Result > AContext.MaxScale then
      Result := AContext.MaxScale
    else if Result < MIN_SCALE then
      Result := MIN_SCALE;
  end
  else
    Result := AContext.MaxScale;
end;

function TImagingWallScale.FromGlobalAngleDouble(const AContext: TImagingScaleContext;
  AVisAngle: Cardinal): Double;
var
  LAngleA: Cardinal;
  LAngleB: Cardinal;
  LNumerator: Double;
  LDenominator: Double;
begin
  Angles(AContext, AVisAngle, LAngleA, LAngleB);
  LNumerator := AContext.ProjectionY * Sin(LAngleB * IMAGING_ANGLE_TO_RADIANS);
  LDenominator := AContext.Distance * Sin(LAngleA * IMAGING_ANGLE_TO_RADIANS);
  if LDenominator = 0 then
  begin
    if LNumerator < 0 then
      Result := MIN_SCALE
    else
      Result := AContext.MaxScale;
  end
  else
  begin
    Result := (LNumerator / LDenominator) * IMAGING_FRACUNIT;
    if Result < MIN_SCALE then
      Result := MIN_SCALE
    else if Result > AContext.MaxScale then
      Result := AContext.MaxScale;
  end;
end;

end.
