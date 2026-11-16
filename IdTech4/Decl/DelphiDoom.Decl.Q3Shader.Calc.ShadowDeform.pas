{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - projection shadow             }
{                                                                              }
{  RB_ProjectionShadowDeform of renderer\tr_shadows.c of Quake III Arena (id   }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.ShadowDeform;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Calc.Types;

type
  /// <summary><c>deformVertexes projectionShadow</c>: the vertexes are flattened on the floor along the light</summary>
  TQ3ShadowDeform = class sealed
  public
    /// <summary>RB_ProjectionShadowDeform</summary>
    class procedure Apply(var ATess: TQ3ShaderTess); static;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.VectorMath, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

class procedure TQ3ShadowDeform.Apply(var ATess: TQ3ShaderTess);
const
  Half: Double = 0.5;
var
  LMask: IInterface;
  LGround, LLight, LLightDirection: TQ3Vec3;
  LGroundDistance, LDot, LHeight, LTerm, LTerm2, LTerm3: Single;
  LDouble, LProduct: Double;
  LIndex: Integer;
begin
  LMask := TQ3FloatMask.Enter;
  if not ATess.Entity.Present then
    raise EDeclQ3ShaderCalcException.Create('the shadow needs the current entity');
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  LGround[0] := ATess.Orientation.Axis[0][2];
  LGround[1] := ATess.Orientation.Axis[1][2];
  LGround[2] := ATess.Orientation.Axis[2][2];
  LGroundDistance := ATess.Orientation.Origin[2] - ATess.Entity.ShadowPlane;

  LLightDirection := ATess.Entity.LightDirection;
  LTerm := LLightDirection[0] * LGround[0];
  LTerm2 := LLightDirection[1] * LGround[1];
  LTerm3 := LLightDirection[2] * LGround[2];
  LTerm := LTerm + LTerm2;
  LDot := LTerm + LTerm3;
  // the shadows must not get too long or go negative
  if LDot < Half then
  begin
    // VectorMA( lightDir, (0.5 - d), ground, lightDir ) is a macro: the scale is a double and so is the
    // whole sum, narrowed to a float once
    LDouble := Half - Double(LDot);
    for LIndex := 0 to 2 do
    begin
      LProduct := Double(LGround[LIndex]) * LDouble;
      LProduct := Double(LLightDirection[LIndex]) + LProduct;
      LLightDirection[LIndex] := LProduct;
    end;
    LTerm := LLightDirection[0] * LGround[0];
    LTerm2 := LLightDirection[1] * LGround[1];
    LTerm3 := LLightDirection[2] * LGround[2];
    LTerm := LTerm + LTerm2;
    LDot := LTerm + LTerm3;
  end;
  LDouble := 1.0 / Double(LDot);
  LDot := LDouble;

  LLight[0] := LLightDirection[0] * LDot;
  LLight[1] := LLightDirection[1] * LDot;
  LLight[2] := LLightDirection[2] * LDot;

  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    LTerm := ATess.Xyz[LIndex * 4] * LGround[0];
    LTerm2 := ATess.Xyz[LIndex * 4 + 1] * LGround[1];
    LTerm3 := ATess.Xyz[LIndex * 4 + 2] * LGround[2];
    LTerm := LTerm + LTerm2;
    LTerm := LTerm + LTerm3;
    LHeight := LTerm + LGroundDistance;

    LTerm := LLight[0] * LHeight;
    ATess.Xyz[LIndex * 4] := ATess.Xyz[LIndex * 4] - LTerm;
    LTerm := LLight[1] * LHeight;
    ATess.Xyz[LIndex * 4 + 1] := ATess.Xyz[LIndex * 4 + 1] - LTerm;
    LTerm := LLight[2] * LHeight;
    ATess.Xyz[LIndex * 4 + 2] := ATess.Xyz[LIndex * 4 + 2] - LTerm;
  end;
end;

end.
