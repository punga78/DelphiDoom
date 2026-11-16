{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the colours of a stage                      }
{                                                                              }
{  Port of ComputeColors of renderer\tr_shade.c. Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.StageColors;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types,
  DelphiDoom.Decl.Q3Shader.Calc.ColorCalc, DelphiDoom.Decl.Q3Shader.Calc.FogCalc;

type
  /// <summary>What <c>ComputeColors</c> reads of <c>tr</c> and of the shader of the surface</summary>
  TQ3StageLighting = record
    /// <summary>tr.identityLight: 1 / (1 shl overbright bits)</summary>
    IdentityLight: Single;
    /// <summary>tr.identityLightByte: 255 * identityLight, truncated</summary>
    IdentityLightByte: Byte;
    /// <summary>tess.shader->portalRange, for <c>alphaGen portal</c></summary>
    PortalRange: Single;
  end;

  /// <summary>
  ///   ComputeColors: the colour (<c>rgbGen</c>) and the alpha (<c>alphaGen</c>) of every vertex of a stage,
  ///   then the fade of both by the fog the surface is in. The result is written to the buffer it is given
  ///   (<c>tess.svars.colors</c>, four bytes per vertex); a byte that the generation does not write keeps the
  ///   value it had, as in the original. The functions of the generations are those of the color,
  ///   light and fog classes; the fog volume of <c>rgbGen fog</c> is <c>Fogs[FogNumber]</c> of the surface.
  /// </summary>
  TQ3StageColors = class
  strict private
    FColors: TQ3ColorCalc;
    FFog: TQ3FogCalc;
    procedure ComputeRgb(const AStage: TQ3ShaderStage; const ATess: TQ3ShaderTess;
      const ALighting: TQ3StageLighting; var AColors: TBytes);
    procedure ComputeAlpha(const AStage: TQ3ShaderStage; const ATess: TQ3ShaderTess;
      const ALighting: TQ3StageLighting; var AColors: TBytes);
    class procedure ComputePortalAlpha(const ATess: TQ3ShaderTess; const APortalRange: Single;
      var AColors: TBytes); static;
  public
    /// <summary>The calculation classes are not owned</summary>
    constructor Create(const AColors: TQ3ColorCalc; const AFog: TQ3FogCalc);
    procedure Compute(const AStage: TQ3ShaderStage; const ATess: TQ3ShaderTess;
      const ALighting: TQ3StageLighting; var AColors: TBytes);
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.VectorMath, DelphiDoom.Decl.Q3Shader.Calc.LightCalc,
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

resourcestring
  SStageVertexColors = 'tess.vertexColors is too short for %d vertexes';
  SStageFogNumber = 'rgbGen fog: the fog %d is not in the world';

{ TQ3StageColors }

constructor TQ3StageColors.Create(const AColors: TQ3ColorCalc; const AFog: TQ3FogCalc);
begin
  inherited Create;
  FColors := AColors;
  FFog := AFog;
end;

procedure TQ3StageColors.ComputeRgb(const AStage: TQ3ShaderStage; const ATess: TQ3ShaderTess;
  const ALighting: TQ3StageLighting; var AColors: TBytes);
var
  LIndex, LAxis: Integer;
  LValue: Single;
  LFogColor: Cardinal;
begin
  case AStage.RgbGen of
    cgIdentity:
      for LIndex := 0 to ATess.NumVertexes * 4 - 1 do
        AColors[LIndex] := $FF;
    cgLightingDiffuse:
      TQ3LightCalc.CalcDiffuseColor(ATess, AColors);
    cgExactVertex:
      for LIndex := 0 to ATess.NumVertexes * 4 - 1 do
        AColors[LIndex] := ATess.VertexColors[LIndex];
    cgConst:
      for LIndex := 0 to ATess.NumVertexes - 1 do
        for LAxis := 0 to 3 do
          AColors[LIndex * 4 + LAxis] := AStage.ConstantColor[LAxis];
    cgVertex:
      if ALighting.IdentityLight = 1 then
      begin
        for LIndex := 0 to ATess.NumVertexes * 4 - 1 do
          AColors[LIndex] := ATess.VertexColors[LIndex];
      end
      else
        for LIndex := 0 to ATess.NumVertexes - 1 do
        begin
          for LAxis := 0 to 2 do
          begin
            LValue := ATess.VertexColors[LIndex * 4 + LAxis] * ALighting.IdentityLight;
            AColors[LIndex * 4 + LAxis] := Byte(TQ3CMath.FloatToInt(LValue));
          end;
          AColors[LIndex * 4 + 3] := ATess.VertexColors[LIndex * 4 + 3];
        end;
    cgOneMinusVertex:
      for LIndex := 0 to ATess.NumVertexes - 1 do
        for LAxis := 0 to 2 do
          if ALighting.IdentityLight = 1 then
            AColors[LIndex * 4 + LAxis] := Byte(255 - ATess.VertexColors[LIndex * 4 + LAxis])
          else
          begin
            LValue := (255 - ATess.VertexColors[LIndex * 4 + LAxis]) * ALighting.IdentityLight;
            AColors[LIndex * 4 + LAxis] := Byte(TQ3CMath.FloatToInt(LValue));
          end;
    cgFog:
      begin
        if (ATess.FogNumber < 0) or (ATess.FogNumber >= Length(ATess.Fogs)) then
          raise EDeclQ3ShaderCalcException.CreateFmt(SStageFogNumber, [ATess.FogNumber]);
        LFogColor := ATess.Fogs[ATess.FogNumber].ColorInt;
        for LIndex := 0 to ATess.NumVertexes - 1 do
          for LAxis := 0 to 3 do
            AColors[LIndex * 4 + LAxis] := Byte(LFogColor shr (LAxis * 8));
      end;
    cgWaveform:
      FColors.CalcWaveColor(AStage.RgbWave, ATess.ShaderTime, ALighting.IdentityLight, ATess.NumVertexes, AColors);
    cgEntity:
      TQ3ColorCalc.CalcColorFromEntity(ATess.Entity, ATess.NumVertexes, AColors);
    cgOneMinusEntity:
      TQ3ColorCalc.CalcColorFromOneMinusEntity(ATess.Entity, ATess.NumVertexes, AColors);
  else
    // CGEN_IDENTITY_LIGHTING, and the default of the original for the rest (CGEN_BAD)
    for LIndex := 0 to ATess.NumVertexes * 4 - 1 do
      AColors[LIndex] := ALighting.IdentityLightByte;
  end;
end;

class procedure TQ3StageColors.ComputePortalAlpha(const ATess: TQ3ShaderTess; const APortalRange: Single;
  var AColors: TBytes);
var
  LIndex, LAxis: Integer;
  LPoint: TQ3Vec3;
  LLength, LScaled: Single;
  LAlpha: Byte;
begin
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    for LAxis := 0 to 2 do
      LPoint[LAxis] := ATess.Xyz[LIndex * 4 + LAxis];
    LLength := TQ3VectorMath.Length(TQ3VectorMath.Subtract(LPoint, ATess.View.Origin));
    LLength := LLength / APortalRange;
    if LLength < 0 then
      LAlpha := 0
    else if LLength > 1 then
      LAlpha := $FF
    else
    begin
      // alpha = len * 0xff: the float is truncated to an int and the low byte kept (a NaN is the indefinite int)
      LScaled := LLength * 255;
      LAlpha := Byte(TQ3CMath.FloatToInt(LScaled));
    end;
    AColors[LIndex * 4 + 3] := LAlpha;
  end;
end;

procedure TQ3StageColors.ComputeAlpha(const AStage: TQ3ShaderStage; const ATess: TQ3ShaderTess;
  const ALighting: TQ3StageLighting; var AColors: TBytes);
var
  LIndex: Integer;
begin
  case AStage.AlphaGen of
    agSkip:
      ;
    agIdentity:
      if AStage.RgbGen <> cgIdentity then
        if ((AStage.RgbGen = cgVertex) and (ALighting.IdentityLight <> 1)) or (AStage.RgbGen <> cgVertex) then
          for LIndex := 0 to ATess.NumVertexes - 1 do
            AColors[LIndex * 4 + 3] := $FF;
    agConst:
      if AStage.RgbGen <> cgConst then
        for LIndex := 0 to ATess.NumVertexes - 1 do
          AColors[LIndex * 4 + 3] := AStage.ConstantColor[3];
    agWaveform:
      FColors.CalcWaveAlpha(AStage.AlphaWave, ATess.ShaderTime, ATess.NumVertexes, AColors);
    agLightingSpecular:
      TQ3LightCalc.CalcSpecularAlpha(ATess, AColors);
    agEntity:
      TQ3ColorCalc.CalcAlphaFromEntity(ATess.Entity, ATess.NumVertexes, AColors);
    agOneMinusEntity:
      TQ3ColorCalc.CalcAlphaFromOneMinusEntity(ATess.Entity, ATess.NumVertexes, AColors);
    agVertex:
      if AStage.RgbGen <> cgVertex then
        for LIndex := 0 to ATess.NumVertexes - 1 do
          AColors[LIndex * 4 + 3] := ATess.VertexColors[LIndex * 4 + 3];
    agOneMinusVertex:
      for LIndex := 0 to ATess.NumVertexes - 1 do
        AColors[LIndex * 4 + 3] := Byte(255 - ATess.VertexColors[LIndex * 4 + 3]);
    agPortal:
      ComputePortalAlpha(ATess, ALighting.PortalRange, AColors);
  end;
end;

procedure TQ3StageColors.Compute(const AStage: TQ3ShaderStage; const ATess: TQ3ShaderTess;
  const ALighting: TQ3StageLighting; var AColors: TBytes);
var
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireBytes(AColors, ATess.NumVertexes);
  if (AStage.RgbGen in [cgExactVertex, cgVertex, cgOneMinusVertex]) or
     (AStage.AlphaGen in [agVertex, agOneMinusVertex]) then
    if Length(ATess.VertexColors) < ATess.NumVertexes * 4 then
      raise EDeclQ3ShaderCalcException.CreateFmt(SStageVertexColors, [ATess.NumVertexes]);

  ComputeRgb(AStage, ATess, ALighting, AColors);
  ComputeAlpha(AStage, ATess, ALighting, AColors);

  // fog adjustment for colors to fade out as fog increases
  if ATess.FogNumber <> 0 then
    case AStage.AdjustColorsForFog of
      acModulateRgb:
        FFog.CalcModulateColors(ATess, AColors);
      acModulateAlpha:
        FFog.CalcModulateAlphas(ATess, AColors);
      acModulateRgba:
        FFog.CalcModulateRGBAs(ATess, AColors);
    end;
end;

end.
