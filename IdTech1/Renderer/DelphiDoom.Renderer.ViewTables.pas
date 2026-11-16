{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the tables of the size of the view           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the tables of R_ExecuteSetViewSize of r_main.pas                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.ViewTables;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   The size of the view and the tables of the rows, the columns and the lights that come
  ///   from it. They are made when the size of the view changes (or the player looks up or
  ///   down), never for a frame
  /// </summary>
  TRendererViewTables = class(TInterfacedObject, IRendererViewTables)
  public
    function Dimensions(ASetBlocks, AScreenWidth, AScreenHeight, AFullViewHeight, ABlockBase,
      ABlockDivisor: Integer): TRendererViewDimensions;
    function Slopes(AProjectionY, ACenterYFrac, AViewHeight: Integer): TRendererSlopeTables;
    function DistanceScales(const AColumnCosines: TArray<Integer>): TArray<Integer>;
    function LightLevels(ALevels, AColumns, AViewWidth, AScreenWidth: Integer;
      ADoomStyle: Boolean): TArray<Integer>;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath;

const
  FULL_SIZE_BLOCKS = 10;
  // the lowest distance that the lights of the slopes use
  LIGHT_MINIMUM_DISTANCE = 4 * RENDERER_FRACUNIT;

{ TRendererViewTables }

function TRendererViewTables.Dimensions(ASetBlocks, AScreenWidth, AScreenHeight,
  AFullViewHeight, ABlockBase, ABlockDivisor: Integer): TRendererViewDimensions;
begin
  if ASetBlocks > FULL_SIZE_BLOCKS then
  begin
    Result.ScaledViewWidth := AScreenWidth;
    Result.ViewHeight := AScreenHeight;
  end
  else
  begin
    if ASetBlocks = FULL_SIZE_BLOCKS then
      Result.ScaledViewWidth := AScreenWidth
    else
      Result.ScaledViewWidth := (ASetBlocks * AScreenWidth div FULL_SIZE_BLOCKS) and not 7;
    if ASetBlocks = FULL_SIZE_BLOCKS then
      Result.ViewHeight := AFullViewHeight
    else
      Result.ViewHeight := (ASetBlocks * ABlockBase div ABlockDivisor) and not 7;
  end;
end;

function TRendererViewTables.Slopes(AProjectionY, ACenterYFrac,
  AViewHeight: Integer): TRendererSlopeTables;
var
  LIndex: Integer;
  LDistance: Integer;
  LAbsolute: Integer;
begin
  SetLength(Result.YSlope, AViewHeight);
  SetLength(Result.LightYSlope, AViewHeight);
  LDistance := ACenterYFrac + RENDERER_FRACUNIT div 2;
  for LIndex := 0 to AViewHeight - 1 do
  begin
    LDistance := LDistance - RENDERER_FRACUNIT;
    LAbsolute := Abs(LDistance);
    Result.YSlope[LIndex] := TFixedMath.Divide(AProjectionY, LAbsolute); // for the right aspect

    // for the lightmap of the slopes
    if LAbsolute < LIGHT_MINIMUM_DISTANCE then
      Result.LightYSlope[LIndex] := TFixedMath.Divide(AProjectionY, LIGHT_MINIMUM_DISTANCE)
    else
      Result.LightYSlope[LIndex] := Result.YSlope[LIndex];
  end;
end;

function TRendererViewTables.DistanceScales(const AColumnCosines: TArray<Integer>): TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AColumnCosines));
  for LIndex := 0 to High(AColumnCosines) do
    Result[LIndex] := TFixedMath.Divide(RENDERER_FRACUNIT, Abs(AColumnCosines[LIndex]));
end;

function TRendererViewTables.LightLevels(ALevels, AColumns, AViewWidth, AScreenWidth: Integer;
  ADoomStyle: Boolean): TArray<Integer>;
var
  LLevel: Integer;
  LColumn: Integer;
  LStart: Integer;
  LValue: Integer;
begin
  SetLength(Result, ALevels * AColumns);
  for LLevel := 0 to ALevels - 1 do
  begin
    LStart := ((ALevels - 1 - LLevel) * 2 * RENDERER_FRACUNIT) div ALevels;
    for LColumn := 0 to AColumns - 1 do
    begin
      if ADoomStyle then
        LValue := LStart - (LColumn * AScreenWidth) div AViewWidth * 16
      else
        LValue := LStart - LColumn * 16 * AScreenWidth div AViewWidth;

      if LValue < 0 then
        Result[LLevel * AColumns + LColumn] := RENDERER_FRACUNIT
      else if LValue >= RENDERER_FRACUNIT then
        Result[LLevel * AColumns + LColumn] := 1
      else
        Result[LLevel * AColumns + LColumn] := RENDERER_FRACUNIT - LValue;
    end;
  end;
end;

end.
