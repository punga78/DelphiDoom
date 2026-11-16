{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - which colormap each light and distance uses    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.LightTables;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   The numbers of R_InitLightTables (zlight and the hi-resolution zlightlevels) and of the
  ///   scalelight of R_ExecuteSetViewSize / R_RecalcColormaps. They give the index of the
  ///   colormap row; the engine turns it into a pointer (@colormaps[index * 256])
  /// </summary>
  TLightTableCalculator = class(TInterfacedObject, ILightTableCalculator)
  strict private
    class function FixedDivide(AValue, ADivisor: Integer): Integer; static;
    class function StartMap(const AConfig: TLightTableConfig; ALevel: Integer): Integer; static;
    class function ClampLevel(ALevel, AMaximum: Integer): Integer; static;
  public
    function ZLight(const AConfig: TLightTableConfig): TArray<Integer>;
    function ScaleLight(const AConfig: TLightTableConfig; AViewWidth, AScreenWidth: Integer): TArray<Integer>;
    function HiResZLight(const AConfig: TLightTableConfig): TArray<Integer>;
  end;

implementation

{ TLightTableCalculator }

class function TLightTableCalculator.FixedDivide(AValue, ADivisor: Integer): Integer;
begin
  // FixedDiv of m_fixed.pas: (AValue shl 16) div ADivisor on 64 bits, saturated on overflow
  if (Abs(AValue) shr 14) >= Abs(ADivisor) then
  begin
    if (AValue xor ADivisor) < 0 then
      Result := Low(Integer)
    else
      Result := High(Integer);
  end
  else
    Result := Integer((Int64(AValue) shl 16) div ADivisor);
end;

class function TLightTableCalculator.StartMap(const AConfig: TLightTableConfig;
  ALevel: Integer): Integer;
begin
  Result := ((AConfig.LightLevels - 1 - ALevel) * 2 * AConfig.NumColorMaps) div AConfig.LightLevels;
end;

class function TLightTableCalculator.ClampLevel(ALevel, AMaximum: Integer): Integer;
begin
  if ALevel < 0 then
    Result := 0
  else if ALevel >= AMaximum then
    Result := AMaximum - 1
  else
    Result := ALevel;
end;

function TLightTableCalculator.ZLight(const AConfig: TLightTableConfig): TArray<Integer>;
var
  LLevel: Integer;
  LStep: Integer;
  LScale: Integer;
begin
  SetLength(Result, AConfig.LightLevels * AConfig.MaxLightZ);
  for LLevel := 0 to AConfig.LightLevels - 1 do
    for LStep := 0 to AConfig.MaxLightZ - 1 do
    begin
      LScale := FixedDivide(AConfig.ReferenceHalfWidth * AConfig.FracUnit,
        (LStep + 1) shl AConfig.LightZShift);
      LScale := LScale shr AConfig.LightScaleShift; // positive: the same as an arithmetic shift
      Result[LLevel * AConfig.MaxLightZ + LStep] :=
        ClampLevel(StartMap(AConfig, LLevel) - LScale div AConfig.DistMap, AConfig.NumColorMaps);
    end;
end;

function TLightTableCalculator.ScaleLight(const AConfig: TLightTableConfig; AViewWidth,
  AScreenWidth: Integer): TArray<Integer>;
var
  LLevel: Integer;
  LStep: Integer;
begin
  if AViewWidth <= 0 then
    raise EPaletteException.CreateFmt(SViewWidthInvalid, [AViewWidth]);
  SetLength(Result, AConfig.LightLevels * AConfig.MaxLightScale);
  for LLevel := 0 to AConfig.LightLevels - 1 do
    for LStep := 0 to AConfig.MaxLightScale - 1 do
      Result[LLevel * AConfig.MaxLightScale + LStep] := ClampLevel(
        StartMap(AConfig, LLevel) - LStep * AScreenWidth div AViewWidth div AConfig.DistMap,
        AConfig.NumColorMaps);
end;

function TLightTableCalculator.HiResZLight(const AConfig: TLightTableConfig): TArray<Integer>;
var
  LLevel: Integer;
  LStep: Integer;
  LStartMap: Integer;
  LScale: Integer;
begin
  SetLength(Result, AConfig.LightLevels * AConfig.HiResMaxLightZ);
  for LLevel := 0 to AConfig.LightLevels - 1 do
  begin
    LStartMap := ((AConfig.LightLevels - 1 - LLevel) * 2 * AConfig.FracUnit) div AConfig.LightLevels;
    for LStep := 0 to AConfig.HiResMaxLightZ - 1 do
    begin
      LScale := FixedDivide(AConfig.ReferenceHalfWidth * AConfig.FracUnit,
        (LStep + 1) shl AConfig.HiResLightZShift);
      LScale := LScale shr AConfig.HiResLightScaleShift;
      Result[LLevel * AConfig.HiResMaxLightZ + LStep] :=
        ClampLevel(AConfig.FracUnit - LStartMap + LScale div AConfig.DistMap, AConfig.FracUnit);
    end;
  end;
end;

end.
