{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - the quad stamp                }
{                                                                              }
{  RB_AddQuadStampExt and RB_AddQuadStamp of renderer\tr_surface.c of Quake    }
{  III Arena (id Software, GPL v2 or later): a quad added to the surface       }
{  being built. Based on the Quake III Arena GPL Source Code (id Software).    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.QuadStamp;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Decl.Q3Shader.Calc.Types;

type
  /// <summary>
  ///   Adds a quad (four vertexes, six indexes) to the buffers of <c>TQ3ShaderTess</c> after the ones in use:
  ///   the sprites and the text of the deformations are made of these. The original flushes the surface when
  ///   it would overflow (<c>RB_CHECKOVERFLOW</c>); here a quad that does not fit in the buffers is an
  ///   <c>EDeclQ3ShaderCalcException</c>.
  /// </summary>
  TQ3QuadStamp = class sealed
  public
    /// <summary>
    ///   RB_AddQuadStampExt: the corners are <c>origin + left + up</c>, <c>origin - left + up</c>,
    ///   <c>origin - left - up</c> and <c>origin + left - up</c>; the normal is minus the forward axis of the
    ///   view, the color of every vertex <c>AColor</c> (four bytes) and the texture coordinates the square
    ///   <c>(S1, T1)</c> to <c>(S2, T2)</c> in both sets.
    /// </summary>
    class procedure AddExt(var ATess: TQ3ShaderTess; const AOrigin, ALeft, AUp: TQ3Vec3; const AColor: Cardinal;
      const AS1, AT1, AS2, AT2: Single); static;
    /// <summary>RB_AddQuadStamp: the whole texture on the quad</summary>
    class procedure Add(var ATess: TQ3ShaderTess; const AOrigin, ALeft, AUp: TQ3Vec3;
      const AColor: Cardinal); static;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.VectorMath;

const
  SQuadDoesNotFit = 'the quad does not fit in the buffers of the surface (%d vertexes, %d indexes)';

class procedure TQ3QuadStamp.AddExt(var ATess: TQ3ShaderTess; const AOrigin, ALeft, AUp: TQ3Vec3;
  const AColor: Cardinal; const AS1, AT1, AS2, AT2: Single);
var
  LIndex, LAxis, LCorner, LByte: Integer;
  LNormal, LZero: TQ3Vec3;
  LSum, LTerm: Single;
  LCoordinate: array[0..3, 0..1] of Single;
begin
  LIndex := ATess.NumVertexes;
  if (Length(ATess.Xyz) < (LIndex + 4) * 4) or (Length(ATess.Normal) < (LIndex + 4) * 4) or
    (Length(ATess.TexCoords) < (LIndex + 4) * 4) or (Length(ATess.VertexColors) < (LIndex + 4) * 4) or
    (Length(ATess.Indexes) < ATess.NumIndexes + 6) then
    raise EDeclQ3ShaderCalcException.CreateFmt(SQuadDoesNotFit, [LIndex + 4, ATess.NumIndexes + 6]);

  // the triangle indexes of a simple quad
  ATess.Indexes[ATess.NumIndexes] := LIndex;
  ATess.Indexes[ATess.NumIndexes + 1] := LIndex + 1;
  ATess.Indexes[ATess.NumIndexes + 2] := LIndex + 3;
  ATess.Indexes[ATess.NumIndexes + 3] := LIndex + 3;
  ATess.Indexes[ATess.NumIndexes + 4] := LIndex + 1;
  ATess.Indexes[ATess.NumIndexes + 5] := LIndex + 2;

  // origin + left + up, origin - left + up, origin - left - up, origin + left - up: each sum is
  // (origin +- left) +- up, as the C evaluates it from the left
  // each partial sum is held in a Single: the x87 would keep it extended
  for LAxis := 0 to 2 do
  begin
    LSum := AOrigin[LAxis] + ALeft[LAxis];
    LTerm := LSum + AUp[LAxis];
    ATess.Xyz[LIndex * 4 + LAxis] := LTerm;
    LTerm := LSum - AUp[LAxis];
    ATess.Xyz[(LIndex + 3) * 4 + LAxis] := LTerm;
    LSum := AOrigin[LAxis] - ALeft[LAxis];
    LTerm := LSum + AUp[LAxis];
    ATess.Xyz[(LIndex + 1) * 4 + LAxis] := LTerm;
    LTerm := LSum - AUp[LAxis];
    ATess.Xyz[(LIndex + 2) * 4 + LAxis] := LTerm;
  end;

  // a constant normal all the way around: vec3_origin - axis[0], so +0 where the axis is 0
  // (a variable zero: the compiler would turn 0 - x into -x, which differs for x = 0)
  FillChar(LZero, SizeOf(LZero), 0);
  LNormal := TQ3VectorMath.Subtract(LZero, ATess.View.Axis[0]);
  for LCorner := 0 to 3 do
    for LAxis := 0 to 2 do
      ATess.Normal[(LIndex + LCorner) * 4 + LAxis] := LNormal[LAxis];

  // the standard square texture coordinates, in the two sets
  LCoordinate[0][0] := AS1;
  LCoordinate[0][1] := AT1;
  LCoordinate[1][0] := AS2;
  LCoordinate[1][1] := AT1;
  LCoordinate[2][0] := AS2;
  LCoordinate[2][1] := AT2;
  LCoordinate[3][0] := AS1;
  LCoordinate[3][1] := AT2;
  for LCorner := 0 to 3 do
  begin
    ATess.TexCoords[(LIndex + LCorner) * 4] := LCoordinate[LCorner][0];
    ATess.TexCoords[(LIndex + LCorner) * 4 + 1] := LCoordinate[LCorner][1];
    ATess.TexCoords[(LIndex + LCorner) * 4 + 2] := LCoordinate[LCorner][0];
    ATess.TexCoords[(LIndex + LCorner) * 4 + 3] := LCoordinate[LCorner][1];
  end;

  // the same color on every vertex (little endian: the first byte is the red one)
  for LCorner := 0 to 3 do
    for LByte := 0 to 3 do
      ATess.VertexColors[(LIndex + LCorner) * 4 + LByte] := Byte(AColor shr (LByte * 8));

  Inc(ATess.NumVertexes, 4);
  Inc(ATess.NumIndexes, 6);
end;

class procedure TQ3QuadStamp.Add(var ATess: TQ3ShaderTess; const AOrigin, ALeft, AUp: TQ3Vec3;
  const AColor: Cardinal);
begin
  AddExt(ATess, AOrigin, ALeft, AUp, AColor, 0, 0, 1, 1);
end;

end.
