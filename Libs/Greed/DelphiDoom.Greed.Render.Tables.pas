{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the tables of the renderer                       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): InitTables, SetViewSize and }
{  InitWalls of r_public.pas and r_walls.pas                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.Tables;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Render.Types;

type
  PGreedFixedArray = ^TGreedFixedArray;
  TGreedFixedArray = array[0..$FFFFFF] of Integer;

  /// <summary>
  ///   The tables that do not depend on the size of the picture: the tangents of the rays of the wall tracing and the
  ///   high precision sines and cosines of the distances (tangents, sines and cosines of r_public.pas). Built once
  /// </summary>
  TGreedFineTables = class
  strict private
    class var FTangents: array[0..GREED_TAN_ANGLES * 2 - 1] of Integer;
    class var FSines: array[0..GREED_TAN_ANGLES * 5 - 1] of Integer;
    class constructor Create;
  public
    class function Tangents: PGreedFixedArray; static;
    /// <summary>cosines: the sines a quarter of the circle later</summary>
    class function Cosines: PGreedFixedArray; static;
    class function Sines: PGreedFixedArray; static;
  end;

  /// <summary>
  ///   What depends on the size of the picture: the angle and the cosine of the ray of each column, the slopes of
  ///   the columns and of the rows, the scale of the projection and the steps of the sky (SetViewSize and the angles
  ///   of InitWalls). The scroll is the number of rows that the view can be moved up and down
  /// </summary>
  TGreedViewTables = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FMaxScroll: Integer;
    FCenterX: Integer;
    FCenterY: Integer;
    FScale: Integer;
    FInverseScale: Integer;
    FHFrac: Integer;
    FAFrac: Integer;
    FPixelAngle: TArray<Integer>;
    FPixelCosine: TArray<Integer>;
    FXSlope: TArray<Integer>;
    FYSlope: TArray<Integer>;
    FBackTangents: TArray<Integer>;
  public
    /// <summary>EGreedRenderException if the size is not 1..640 x 1..400</summary>
    constructor Create(AWidth, AHeight: Integer);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property MaxScroll: Integer read FMaxScroll;
    property CenterX: Integer read FCenterX;
    property CenterY: Integer read FCenterY;
    /// <summary>FSCALE: (width div 2) in fixed point</summary>
    property Scale: Integer read FScale;
    /// <summary>ISCALE</summary>
    property InverseScale: Integer read FInverseScale;
    property HFrac: Integer read FHFrac;
    property AFrac: Integer read FAFrac;
    property PixelAngle: TArray<Integer> read FPixelAngle;
    property PixelCosine: TArray<Integer> read FPixelCosine;
    property XSlope: TArray<Integer> read FXSlope;
    /// <summary>Indexed by the row plus MaxScroll</summary>
    property YSlope: TArray<Integer> read FYSlope;
    property BackTangents: TArray<Integer> read FBackTangents;
  end;

/// <summary>rint of the original: Trunc(x + 0.5)</summary>
function GreedRint(const AValue: Double): Integer; inline;

implementation

uses
  System.Math, DelphiDoom.Greed.FixedMath;

const
  GREED_PI = 3.14159265;

function GreedRint(const AValue: Double): Integer;
begin
  Result := Trunc(AValue + 0.5);
end;

{ TGreedFineTables }

class constructor TGreedFineTables.Create;
var
  LIndex, LValueInt: Integer;
  LAngle, LValue, LInverse: Double;
begin
  for LIndex := 0 to GREED_TAN_ANGLES div 2 - 1 do
  begin
    LAngle := (LIndex + 0.5) * GREED_PI / (GREED_TAN_ANGLES * 2);
    LValue := Tan(LAngle);
    LInverse := 1 / LValue;
    LValue := GreedRint(LValue * GREED_FRACUNIT);
    LInverse := GreedRint(LInverse * GREED_FRACUNIT);
    FTangents[GREED_TAN_ANGLES + LIndex] := Trunc(-LValue);
    FTangents[GREED_TAN_ANGLES + GREED_TAN_ANGLES - 1 - LIndex] := Trunc(-LInverse);
    FTangents[LIndex] := Trunc(LInverse);
    FTangents[GREED_TAN_ANGLES - 1 - LIndex] := Trunc(LValue);
  end;
  for LIndex := 0 to GREED_TAN_ANGLES - 1 do
  begin
    LAngle := (LIndex + 0.5) * GREED_PI / (GREED_TAN_ANGLES * 2);
    LValue := Sin(LAngle);
    LValueInt := GreedRint(LValue * GREED_FRACUNIT);
    FSines[LIndex] := LValueInt;
    FSines[GREED_TAN_ANGLES * 4 + LIndex] := LValueInt;
    FSines[GREED_TAN_ANGLES * 2 - 1 - LIndex] := LValueInt;
    FSines[GREED_TAN_ANGLES * 2 + LIndex] := -LValueInt;
    FSines[GREED_TAN_ANGLES * 4 - 1 - LIndex] := -LValueInt;
  end;
end;

class function TGreedFineTables.Tangents: PGreedFixedArray;
begin
  Result := @FTangents[0];
end;

class function TGreedFineTables.Sines: PGreedFixedArray;
begin
  Result := @FSines[0];
end;

class function TGreedFineTables.Cosines: PGreedFixedArray;
begin
  Result := @FSines[GREED_TAN_ANGLES];
end;

{ TGreedViewTables }

constructor TGreedViewTables.Create(AWidth, AHeight: Integer);
var
  LIndex, LAngle: Integer;
  LCosines: PGreedFixedArray;
  LTangents: PGreedFixedArray;
begin
  inherited Create;
  if (AWidth < 2) or (AHeight < 2) or (AWidth > GREED_RENDER_MAX_WIDTH) or (AHeight > GREED_RENDER_MAX_HEIGHT) then
    raise EGreedRenderException.CreateFmt(SGreedRenderSize, [AWidth, AHeight, GREED_RENDER_MAX_WIDTH,
      GREED_RENDER_MAX_HEIGHT]);
  FWidth := AWidth;
  FHeight := AHeight;
  // MAXSCROLL1 of the original is 120 for a picture of 400 rows and half of it in the low resolution
  if AHeight > 200 then
    FMaxScroll := 120
  else
    FMaxScroll := 60;
  FCenterX := AWidth div 2;
  FCenterY := AHeight div 2;
  FScale := (AWidth div 2) * GREED_FRACUNIT;
  FInverseScale := GREED_FRACUNIT div (AWidth div 2);
  LCosines := TGreedFineTables.Cosines;
  LTangents := TGreedFineTables.Tangents;
  SetLength(FPixelAngle, AWidth + 1);
  SetLength(FPixelCosine, AWidth + 1);
  SetLength(FXSlope, AWidth + 1);
  for LIndex := 0 to AWidth do
  begin
    LAngle := GreedRint(ArcTan((FCenterX - (LIndex + 1.0)) / FCenterX) / GREED_PI * GREED_TAN_ANGLES * 2);
    FPixelAngle[LIndex] := LAngle;
    FPixelCosine[LIndex] := LCosines^[LAngle and (GREED_TAN_ANGLES * 4 - 1)];
    FXSlope[LIndex] := GreedRint((LIndex + 1 - FCenterX) / FCenterX * GREED_FRACUNIT);
  end;
  SetLength(FYSlope, AHeight + 2 * FMaxScroll);
  for LIndex := -FMaxScroll to AHeight + FMaxScroll - 1 do
    FYSlope[LIndex + FMaxScroll] := GreedRint(-(LIndex - 0.5 - FCenterY) / FCenterX * GREED_FRACUNIT);
  SetLength(FBackTangents, GREED_TAN_ANGLES * 2);
  for LIndex := 0 to GREED_TAN_ANGLES * 2 - 1 do
    FBackTangents[LIndex] := ((AWidth div 2) * LTangents^[LIndex]) div GREED_FRACUNIT;
  // the backdrop of the original is 200 rows high
  FHFrac := TGreedFixedMath.Divide(200 * (GREED_FRACUNIT div 2), (AHeight div 2) * GREED_FRACUNIT);
  FAFrac := TGreedFixedMath.Divide(GREED_TAN_ANGLES * GREED_FRACUNIT, AWidth * GREED_FRACUNIT);
end;

end.
