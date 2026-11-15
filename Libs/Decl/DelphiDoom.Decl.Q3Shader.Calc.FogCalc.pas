{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - fog                           }
{                                                                              }
{  R_InitFogTable and R_FogFactor of renderer\tr_image.c, RB_CalcFogTexCoords  }
{  and the three RB_CalcModulate*ByFog of renderer\tr_shade_calc.c of Quake    }
{  III Arena (id Software, GPL v2 or later). Based on the Quake III Arena GPL  }
{  Source Code (id Software).                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.FogCalc;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Calc.Types;

type
  /// <summary>
  ///   The fog of the world on a surface: the density table, the texture coordinates that measure the distance
  ///   in the fog, and the modulation of the colors of a transparent surface by it.
  /// </summary>
  TQ3FogCalc = class
  strict private
    FTable: array[0..Q3_FOG_TABLE_SIZE - 1] of Single;
  public
    /// <summary>R_InitFogTable: the square root of the position in the table</summary>
    constructor Create;
    /// <summary>R_FogFactor: the density, 0 to 1, at the texture coordinates (s, t) of the fog</summary>
    function FogFactor(ACoordinateS, ACoordinateT: Single): Single;
    /// <summary>The value of tr.fogTable[AIndex]</summary>
    function TableValue(AIndex: Integer): Single;
    /// <summary>
    ///   RB_CalcFogTexCoords: two floats per vertex (s: the distance in the fog, t: where the point is against
    ///   the fog surface) in <c>ATexCoords</c>
    /// </summary>
    procedure CalcFogTexCoords(const ATess: TQ3ShaderTess; var ATexCoords: TArray<Single>);
    /// <summary>RB_CalcModulateColorsByFog: red, green and blue by one minus the density</summary>
    procedure CalcModulateColors(const ATess: TQ3ShaderTess; var AColors: TBytes);
    /// <summary>RB_CalcModulateAlphasByFog</summary>
    procedure CalcModulateAlphas(const ATess: TQ3ShaderTess; var AColors: TBytes);
    /// <summary>RB_CalcModulateRGBAsByFog: the four bytes</summary>
    procedure CalcModulateRGBAs(const ATess: TQ3ShaderTess; var AColors: TBytes);
  end;

implementation

uses
  System.Math, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

const
  SNoFog = 'the surface is in the fog %d, which the world does not have';

constructor TQ3FogCalc.Create;
var
  LIndex: Integer;
  LRatio: Single;
begin
  inherited Create;
  for LIndex := 0 to Q3_FOG_TABLE_SIZE - 1 do
  begin
    LRatio := LIndex / (Q3_FOG_TABLE_SIZE - 1);
    // pow( (float)i / (FOG_TABLE_SIZE-1), 0.5 ) of a float is the square root, rounded to a float
    FTable[LIndex] := Sqrt(Double(LRatio));
  end;
end;

function TQ3FogCalc.TableValue(AIndex: Integer): Single;
begin
  Result := FTable[AIndex];
end;

function TQ3FogCalc.FogFactor(ACoordinateS, ACoordinateT: Single): Single;
var
  LS, LT, LTerm: Single;
  LDouble: Double;
  LIndex: Integer;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  LS := ACoordinateS;
  LT := ACoordinateT;
  // the original goes on and indexes fogTable[INT_MIN]
  if IsNan(LS) or IsNan(LT) then
    raise EDeclQ3ShaderCalcException.Create('the fog texture coordinates are not numbers');
  // s -= 1.0/512: the subtraction is a double, the result goes back to a float
  LDouble := Double(LS) - 1.0 / 512;
  LS := LDouble;
  if LS < 0 then
    Exit(0);
  if LT < 1.0 / 32 then
    Exit(0);
  if LT < 31.0 / 32 then
  begin
    LTerm := LT - Single(1.0 / 32.0);
    LTerm := LTerm / Single(30.0 / 32.0);
    LS := LS * LTerm;
  end;
  // a lot of clamp range
  LS := LS * 8;
  if LS > 1.0 then
    LS := 1.0;
  LTerm := LS * (Q3_FOG_TABLE_SIZE - 1);
  LIndex := TQ3CMath.FloatToInt(LTerm);
  if (LIndex < 0) or (LIndex >= Q3_FOG_TABLE_SIZE) then
    raise EDeclQ3ShaderCalcException.Create('the fog texture coordinates are out of the fog table');
  Result := FTable[LIndex];
end;

procedure TQ3FogCalc.CalcFogTexCoords(const ATess: TQ3ShaderTess; var ATexCoords: TArray<Single>);
var
  LMask: IInterface;
  LFog: TQ3Fog;
  LLocal: array[0..2] of Single;
  LDistance, LDepth: array[0..3] of Single;
  LEyeT, LS, LT, LTerm, LTerm2: Single;
  LEyeOutside: Boolean;
  LDouble: Double;
  LIndex, LAxis: Integer;
  LX, LY, LZ: Single;
begin
  LMask := TQ3FloatMask.Enter;
  if (ATess.FogNumber < 0) or (ATess.FogNumber >= Length(ATess.Fogs)) then
    raise EDeclQ3ShaderCalcException.CreateFmt(SNoFog, [ATess.FogNumber]);
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  SetLength(ATexCoords, ATess.NumVertexes * 2);
  LFog := ATess.Fogs[ATess.FogNumber];

  // all fogging distance is based on world Z units
  for LAxis := 0 to 2 do
    LLocal[LAxis] := ATess.Orientation.Origin[LAxis] - ATess.View.Origin[LAxis];
  LDistance[0] := -ATess.Orientation.ModelMatrix[2];
  LDistance[1] := -ATess.Orientation.ModelMatrix[6];
  LDistance[2] := -ATess.Orientation.ModelMatrix[10];
  LX := LLocal[0] * ATess.View.Axis[0][0];
  LY := LLocal[1] * ATess.View.Axis[0][1];
  LZ := LLocal[2] * ATess.View.Axis[0][2];
  LX := LX + LY;
  LDistance[3] := LX + LZ;

  // scale the vectors by the thickness of the fog
  for LAxis := 0 to 3 do
    LDistance[LAxis] := LDistance[LAxis] * LFog.TcScale;

  // the gradient vector, rotated for this orientation
  if LFog.HasSurface then
  begin
    for LAxis := 0 to 2 do
    begin
      LX := LFog.Surface[0] * ATess.Orientation.Axis[LAxis][0];
      LY := LFog.Surface[1] * ATess.Orientation.Axis[LAxis][1];
      LZ := LFog.Surface[2] * ATess.Orientation.Axis[LAxis][2];
      LX := LX + LY;
      LDepth[LAxis] := LX + LZ;
    end;
    LX := ATess.Orientation.Origin[0] * LFog.Surface[0];
    LY := ATess.Orientation.Origin[1] * LFog.Surface[1];
    LZ := ATess.Orientation.Origin[2] * LFog.Surface[2];
    LX := LX + LY;
    LX := LX + LZ;
    LTerm := -LFog.Surface[3];
    LDepth[3] := LTerm + LX;

    LX := ATess.ViewOrigin[0] * LDepth[0];
    LY := ATess.ViewOrigin[1] * LDepth[1];
    LZ := ATess.ViewOrigin[2] * LDepth[2];
    LX := LX + LY;
    LX := LX + LZ;
    LEyeT := LX + LDepth[3];
  end
  else
  begin
    LDepth[0] := 0;
    LDepth[1] := 0;
    LDepth[2] := 0;
    LDepth[3] := 0;
    LEyeT := 1; // fog that is not a surface always has the eye inside
  end;

  // is the viewpoint outside: needed for the clipping distance even with constant fog
  LEyeOutside := LEyeT < 0;

  LDouble := Double(LDistance[3]) + 1.0 / 512;
  LDistance[3] := LDouble;

  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    // the length in the fog
    LX := ATess.Xyz[LIndex * 4] * LDistance[0];
    LY := ATess.Xyz[LIndex * 4 + 1] * LDistance[1];
    LZ := ATess.Xyz[LIndex * 4 + 2] * LDistance[2];
    LX := LX + LY;
    LX := LX + LZ;
    LS := LX + LDistance[3];
    LX := ATess.Xyz[LIndex * 4] * LDepth[0];
    LY := ATess.Xyz[LIndex * 4 + 1] * LDepth[1];
    LZ := ATess.Xyz[LIndex * 4 + 2] * LDepth[2];
    LX := LX + LY;
    LX := LX + LZ;
    LT := LX + LDepth[3];

    // partially clipped fogs use the T axis
    if LEyeOutside then
    begin
      if LT < 1.0 then
        LT := 1.0 / 32 // the point is outside: no fogging
      else
      begin
        // t = 1.0/32 + 30.0/32 * t / ( t - eyeT ): the division is a double
        LTerm2 := LT - LEyeT;
        LDouble := (30.0 / 32) * Double(LT);
        LDouble := LDouble / Double(LTerm2);
        LDouble := 1.0 / 32 + LDouble;
        LT := LDouble;
      end;
    end
    else
    begin
      if LT < 0 then
        LT := 1.0 / 32
      else
        LT := 31.0 / 32;
    end;
    ATexCoords[LIndex * 2] := LS;
    ATexCoords[LIndex * 2 + 1] := LT;
  end;
end;

procedure TQ3FogCalc.CalcModulateColors(const ATess: TQ3ShaderTess; var AColors: TBytes);
var
  LMask: IInterface;
  LTexCoords: TArray<Single>;
  LIndex, LByte: Integer;
  LFactor, LValue: Single;
  LDouble: Double;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireBytes(AColors, ATess.NumVertexes);
  CalcFogTexCoords(ATess, LTexCoords);
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    LDouble := 1.0 - Double(FogFactor(LTexCoords[LIndex * 2], LTexCoords[LIndex * 2 + 1]));
    LFactor := LDouble;
    for LByte := 0 to 2 do
      begin
      LValue := AColors[LIndex * 4 + LByte] * LFactor;
      AColors[LIndex * 4 + LByte] := Byte(TQ3CMath.FloatToInt(LValue));
      end;
  end;
end;

procedure TQ3FogCalc.CalcModulateAlphas(const ATess: TQ3ShaderTess; var AColors: TBytes);
var
  LMask: IInterface;
  LTexCoords: TArray<Single>;
  LIndex: Integer;
  LFactor, LValue: Single;
  LDouble: Double;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireBytes(AColors, ATess.NumVertexes);
  CalcFogTexCoords(ATess, LTexCoords);
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    LDouble := 1.0 - Double(FogFactor(LTexCoords[LIndex * 2], LTexCoords[LIndex * 2 + 1]));
    LFactor := LDouble;
    LValue := AColors[LIndex * 4 + 3] * LFactor;
    AColors[LIndex * 4 + 3] := Byte(TQ3CMath.FloatToInt(LValue));
  end;
end;

procedure TQ3FogCalc.CalcModulateRGBAs(const ATess: TQ3ShaderTess; var AColors: TBytes);
var
  LMask: IInterface;
  LTexCoords: TArray<Single>;
  LIndex, LByte: Integer;
  LFactor, LValue: Single;
  LDouble: Double;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireBytes(AColors, ATess.NumVertexes);
  CalcFogTexCoords(ATess, LTexCoords);
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    LDouble := 1.0 - Double(FogFactor(LTexCoords[LIndex * 2], LTexCoords[LIndex * 2 + 1]));
    LFactor := LDouble;
    for LByte := 0 to 3 do
      begin
      LValue := AColors[LIndex * 4 + LByte] * LFactor;
      AColors[LIndex * 4 + LByte] := Byte(TQ3CMath.FloatToInt(LValue));
      end;
  end;
end;

end.
