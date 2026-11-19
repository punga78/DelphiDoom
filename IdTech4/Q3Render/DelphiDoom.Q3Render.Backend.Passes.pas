{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1b) - the dynamic     }
{  light pass and the fog pass                                                 }
{                                                                              }
{  ProjectDlightTexture and RB_FogPass of renderer\tr_shade.c, and             }
{  R_TransformDlights of tr_light.c, as the draws they make: which texture,    }
{  which state, the indexes and the arrays the draw reads. Based on the Quake  }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Backend.Passes;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types,
  DelphiDoom.Decl.Q3Shader.Calc.FogCalc, DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>Which of the images the renderer makes itself a pass draws with</summary>
  TQ3PassImage = (piDlight, piFog);

  /// <summary>
  ///   One draw of a pass: the image to bind, the state, the triangles and the arrays the draw reads through the
  ///   pointers (two floats and four bytes per vertex of tess)
  /// </summary>
  TQ3PassDraw = record
    Image: TQ3PassImage;
    StateBits: Cardinal;
    Indexes: TArray<Integer>;
    TexCoords: TArray<Single>;
    Colors: TBytes;
  end;

  /// <summary>The passes of tr_shade.c that go after the stages of a shader (the original keeps no state in them)</summary>
  TQ3ShadingPasses = class sealed
  public
    /// <summary>
    ///   R_TransformDlights: the position of a dlight in the space of the entity: (origin - or.origin) . or.axis[i]
    /// </summary>
    class function TransformDlight(const AOrigin: TQ3Vec3; const AOrientationOrigin: TQ3Vec3;
      const AOrientationAxis: array of TQ3Vec3): TQ3Vec3; static;
    /// <summary>
    ///   ProjectDlightTexture: for every dlight whose bit is in ADlightBits, the vertexes of tess are lit with a
    ///   texture of the light, and the triangles that the light reaches are drawn. ATransformed is the position of
    ///   the lights in the space of the surface (what R_TransformDlights left in dl->transformed)
    /// </summary>
    class function ProjectDlights(const ATess: TQ3ShaderTess; ADlightBits: Integer;
      const ADlights: TArray<TQ3DynamicLight>; const ATransformed: TArray<TQ3Vec3>): TArray<TQ3PassDraw>; static;
    /// <summary>
    ///   RB_FogPass: the fog colour on every vertex with the texture coordinates of RB_CalcFogTexCoords, over everything
    ///   else (equal depth for FP_EQUAL)
    /// </summary>
    class function FogPass(const ATess: TQ3ShaderTess; AFogPass: TQ3FogPass; const AFogCalc: TQ3FogCalc): TQ3PassDraw; static;
  end;

implementation

uses
  DelphiDoom.Q3Render.Types;

const
  SFogNumber = 'RB_FogPass: the surface is in the fog %d, which the world does not have';

class function TQ3ShadingPasses.TransformDlight(const AOrigin: TQ3Vec3; const AOrientationOrigin: TQ3Vec3;
  const AOrientationAxis: array of TQ3Vec3): TQ3Vec3;
var
  LTemp: TQ3Vec3;
  LAxis: Integer;
  LSum, LTerm: Single;
begin
  for LAxis := 0 to 2 do
    LTemp[LAxis] := AOrigin[LAxis] - AOrientationOrigin[LAxis];
  for LAxis := 0 to 2 do
  begin
    LSum := LTemp[0] * AOrientationAxis[LAxis][0];
    LTerm := LTemp[1] * AOrientationAxis[LAxis][1];
    LSum := LSum + LTerm;
    LTerm := LTemp[2] * AOrientationAxis[LAxis][2];
    Result[LAxis] := LSum + LTerm;
  end;
end;

class function TQ3ShadingPasses.ProjectDlights(const ATess: TQ3ShaderTess; ADlightBits: Integer;
  const ADlights: TArray<TQ3DynamicLight>; const ATransformed: TArray<TQ3Vec3>): TArray<TQ3PassDraw>;
const
  Half: Single = 0.5;
var
  LLight, LVertex, LIndex, LClip, LAxis, LA, LB, LC, LNumber: Integer;
  LRadius, LScale, LModulate, LTerm, LHalfRadius: Single;
  LFloatColor: array[0..2] of Single;
  LDist: array[0..2] of Single;
  LTexCoords: TArray<Single>;
  LColors: TBytes;
  LClipBits: TArray<Integer>;
  LHit: TArray<Integer>;
  LDraw: TQ3PassDraw;
  LList: TArray<TQ3PassDraw>;
  LValue: Integer;
begin
  SetLength(LList, 0);
  for LLight := 0 to High(ADlights) do
  begin
    // this surface definately doesn't have any of this light
    if (ADlightBits and (1 shl LLight)) = 0 then
      Continue;
    LRadius := ADlights[LLight].Radius;
    LScale := 1.0 / LRadius;
    LFloatColor[0] := ADlights[LLight].Color[0] * 255.0;
    LFloatColor[1] := ADlights[LLight].Color[1] * 255.0;
    LFloatColor[2] := ADlights[LLight].Color[2] * 255.0;
    SetLength(LTexCoords, ATess.NumVertexes * 2);
    SetLength(LColors, ATess.NumVertexes * 4);
    SetLength(LClipBits, ATess.NumVertexes);
    for LVertex := 0 to ATess.NumVertexes - 1 do
    begin
      for LAxis := 0 to 2 do
        LDist[LAxis] := ATransformed[LLight][LAxis] - ATess.Xyz[LVertex * 4 + LAxis];
      LTerm := LDist[0] * LScale;
      LTexCoords[LVertex * 2] := Half + LTerm;
      LTerm := LDist[1] * LScale;
      LTexCoords[LVertex * 2 + 1] := Half + LTerm;
      LClip := 0;
      if LTexCoords[LVertex * 2] < 0.0 then
        LClip := LClip or 1
      else if LTexCoords[LVertex * 2] > 1.0 then
        LClip := LClip or 2;
      if LTexCoords[LVertex * 2 + 1] < 0.0 then
        LClip := LClip or 4
      else if LTexCoords[LVertex * 2 + 1] > 1.0 then
        LClip := LClip or 8;
      // modulate the strength based on the height and color
      if LDist[2] > LRadius then
      begin
        LClip := LClip or 16;
        LModulate := 0.0;
      end
      else if LDist[2] < -LRadius then
      begin
        LClip := LClip or 32;
        LModulate := 0.0;
      end
      else
      begin
        LDist[2] := Abs(LDist[2]);
        LHalfRadius := LRadius * 0.5;
        if LDist[2] < LHalfRadius then
          LModulate := 1.0
        else
        begin
          LTerm := LRadius - LDist[2];
          LTerm := 2.0 * LTerm;
          LModulate := LTerm * LScale;
        end;
      end;
      LClipBits[LVertex] := LClip;
      for LAxis := 0 to 2 do
      begin
        LTerm := LFloatColor[LAxis] * LModulate;
        LValue := TQ3CMath.FloatToInt(LTerm);
        LColors[LVertex * 4 + LAxis] := Byte(LValue and $FF);
      end;
      LColors[LVertex * 4 + 3] := 255;
    end;
    // build a list of triangles that need light
    SetLength(LHit, ATess.NumIndexes);
    LNumber := 0;
    LIndex := 0;
    while LIndex < ATess.NumIndexes do
    begin
      LA := ATess.Indexes[LIndex];
      LB := ATess.Indexes[LIndex + 1];
      LC := ATess.Indexes[LIndex + 2];
      // not lighted
      if (LClipBits[LA] and LClipBits[LB] and LClipBits[LC]) = 0 then
      begin
        LHit[LNumber] := LA;
        LHit[LNumber + 1] := LB;
        LHit[LNumber + 2] := LC;
        Inc(LNumber, 3);
      end;
      Inc(LIndex, 3);
    end;
    if LNumber = 0 then
      Continue;
    SetLength(LHit, LNumber);
    LDraw := Default(TQ3PassDraw);
    LDraw.Image := piDlight;
    // GLS_DEPTHFUNC_EQUAL so that alpha tested surfaces don't add light where they aren't rendered
    if ADlights[LLight].Additive <> 0 then
      LDraw.StateBits := GLS_SRCBLEND_ONE or GLS_DSTBLEND_ONE or GLS_DEPTHFUNC_EQUAL
    else
      LDraw.StateBits := GLS_SRCBLEND_DST_COLOR or GLS_DSTBLEND_ONE or GLS_DEPTHFUNC_EQUAL;
    LDraw.Indexes := LHit;
    LDraw.TexCoords := Copy(LTexCoords);
    LDraw.Colors := Copy(LColors);
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := LDraw;
    LHit := nil;
  end;
  Result := LList;
end;

class function TQ3ShadingPasses.FogPass(const ATess: TQ3ShaderTess; AFogPass: TQ3FogPass;
  const AFogCalc: TQ3FogCalc): TQ3PassDraw;
var
  LVertex, LByte: Integer;
  LColor: Cardinal;
begin
  if (ATess.FogNumber < 0) or (ATess.FogNumber >= Length(ATess.Fogs)) then
    raise EQ3RenderException.CreateFmt(SFogNumber, [ATess.FogNumber]);
  Result := Default(TQ3PassDraw);
  Result.Image := piFog;
  SetLength(Result.Colors, ATess.NumVertexes * 4);
  LColor := ATess.Fogs[ATess.FogNumber].ColorInt;
  for LVertex := 0 to ATess.NumVertexes - 1 do
    for LByte := 0 to 3 do
      Result.Colors[LVertex * 4 + LByte] := Byte(LColor shr (LByte * 8));
  AFogCalc.CalcFogTexCoords(ATess, Result.TexCoords);
  if AFogPass = fpEqual then
    Result.StateBits := GLS_SRCBLEND_SRC_ALPHA or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA or GLS_DEPTHFUNC_EQUAL
  else
    Result.StateBits := GLS_SRCBLEND_SRC_ALPHA or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA;
  SetLength(Result.Indexes, ATess.NumIndexes);
  for LVertex := 0 to ATess.NumIndexes - 1 do
    Result.Indexes[LVertex] := ATess.Indexes[LVertex];
end;

end.
