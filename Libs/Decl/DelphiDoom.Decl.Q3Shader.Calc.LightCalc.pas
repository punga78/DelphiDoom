{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - vertex lighting               }
{                                                                              }
{  RB_CalcSpecularAlpha and RB_CalcDiffuseColor of renderer\tr_shade_calc.c    }
{  of Quake III Arena (id Software, GPL v2 or later). Based on the Quake III   }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.LightCalc;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Calc.Types;

type
  /// <summary>The lighting of the vertices that a shader asks for (<c>rgbGen lightingDiffuse</c>, <c>alphaGen lightingSpecular</c>)</summary>
  TQ3LightCalc = class sealed
  public
    /// <summary>
    ///   RB_CalcSpecularAlpha: the specular coefficient of every vertex into the alpha byte, from the fixed
    ///   light of the original (<c>lightOrigin</c> = (-960, 1980, 96), "FIXME: track dynamically"); the other
    ///   bytes are not touched
    /// </summary>
    class procedure CalcSpecularAlpha(const ATess: TQ3ShaderTess; var AColors: TBytes); static;
    /// <summary>
    ///   RB_CalcDiffuseColor: ambient plus directed light by the cosine with the light direction, clamped to
    ///   255; a vertex that faces away takes the ambient color as it is; alpha 255
    /// </summary>
    class procedure CalcDiffuseColor(const ATess: TQ3ShaderTess; var AColors: TBytes); static;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

class procedure TQ3LightCalc.CalcSpecularAlpha(const ATess: TQ3ShaderTess; var AColors: TBytes);
const
  LightOrigin: array[0..2] of Single = (-960, 1980, 96);
var
  LMask: IInterface;
  LIndex, LAxis, LValue: Integer;
  LLightDirection: TArray<Single>;
  LReflected, LViewer: TQ3Vec3;
  LDot, LInverseLength, LLength, LTerm, LTerm2, LTerm3: Single;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  TQ3CMath.RequireFloats(ATess.Normal, ATess.NumVertexes, 4, 'normal');
  TQ3CMath.RequireBytes(AColors, ATess.NumVertexes);
  SetLength(LLightDirection, 3);
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    for LAxis := 0 to 2 do
      LLightDirection[LAxis] := LightOrigin[LAxis] - ATess.Xyz[LIndex * 4 + LAxis];
    TQ3CMath.NormalizeFast(LLightDirection, 0);

    // the specular color
    LTerm := ATess.Normal[LIndex * 4] * LLightDirection[0];
    LTerm2 := ATess.Normal[LIndex * 4 + 1] * LLightDirection[1];
    LTerm3 := ATess.Normal[LIndex * 4 + 2] * LLightDirection[2];
    LTerm := LTerm + LTerm2;
    LDot := LTerm + LTerm3;

    // reflected = normal * 2 * d - lightDir (left to right, each step a float)
    for LAxis := 0 to 2 do
    begin
      LTerm := ATess.Normal[LIndex * 4 + LAxis] * 2;
      LTerm := LTerm * LDot;
      LReflected[LAxis] := LTerm - LLightDirection[LAxis];
      LViewer[LAxis] := ATess.ViewOrigin[LAxis] - ATess.Xyz[LIndex * 4 + LAxis];
    end;
    LTerm := LViewer[0] * LViewer[0];
    LTerm2 := LViewer[1] * LViewer[1];
    LTerm3 := LViewer[2] * LViewer[2];
    LTerm := LTerm + LTerm2;
    LTerm := LTerm + LTerm3;
    LInverseLength := TQ3CMath.Rsqrt(LTerm);
    LTerm := LReflected[0] * LViewer[0];
    LTerm2 := LReflected[1] * LViewer[1];
    LTerm3 := LReflected[2] * LViewer[2];
    LTerm := LTerm + LTerm2;
    LLength := LTerm + LTerm3;
    LLength := LLength * LInverseLength;

    if LLength < 0 then
      LValue := 0
    else
    begin
      LLength := LLength * LLength;
      LLength := LLength * LLength;
      LTerm := LLength * 255;
      LValue := TQ3CMath.FloatToInt(LTerm);
      if LValue > 255 then
        LValue := 255;
    end;
    AColors[LIndex * 4 + 3] := Byte(LValue);
  end;
end;

class procedure TQ3LightCalc.CalcDiffuseColor(const ATess: TQ3ShaderTess; var AColors: TBytes);
var
  LMask: IInterface;
  LIndex, LAxis, LValue: Integer;
  LIncoming, LTerm, LTerm2, LTerm3: Single;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATess.Normal, ATess.NumVertexes, 4, 'normal');
  TQ3CMath.RequireBytes(AColors, ATess.NumVertexes);
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    LTerm := ATess.Normal[LIndex * 4] * ATess.Entity.LightDirection[0];
    LTerm2 := ATess.Normal[LIndex * 4 + 1] * ATess.Entity.LightDirection[1];
    LTerm3 := ATess.Normal[LIndex * 4 + 2] * ATess.Entity.LightDirection[2];
    LTerm := LTerm + LTerm2;
    LIncoming := LTerm + LTerm3;
    if LIncoming <= 0 then
    begin
      for LAxis := 0 to 3 do
        AColors[LIndex * 4 + LAxis] := Byte(ATess.Entity.AmbientLightInt shr (LAxis * 8));
      Continue;
    end;
    for LAxis := 0 to 2 do
    begin
      LTerm := LIncoming * ATess.Entity.DirectedLight[LAxis];
      LTerm := ATess.Entity.AmbientLight[LAxis] + LTerm;
      LValue := TQ3CMath.FloatToInt(LTerm);
      if LValue > 255 then
        LValue := 255;
      AColors[LIndex * 4 + LAxis] := Byte(LValue);
    end;
    AColors[LIndex * 4 + 3] := 255;
  end;
end;

end.
