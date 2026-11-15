{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - sprites and text              }
{                                                                              }
{  AutospriteDeform, Autosprite2Deform and DeformText of                       }
{  renderer\tr_shade_calc.c of Quake III Arena (id Software, GPL v2 or         }
{  later): the deformations that rebuild the quads of a surface from the       }
{  view. Based on the Quake III Arena GPL Source Code (id Software).           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.SpriteDeform;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Decl.Q3Shader.Calc.Types;

type
  /// <summary>
  ///   <c>deformVertexes autosprite</c>, <c>autosprite2</c> and <c>text0..7</c> on the buffers of
  ///   <c>TQ3ShaderTess</c>. The original warns about an odd vertex or index count and reads past the buffers;
  ///   here it is an <c>EDeclQ3ShaderCalcException</c>.
  /// </summary>
  TQ3SpriteDeform = class sealed
  strict private
    class function Vertex(const ATess: TQ3ShaderTess; AIndex: Integer): TQ3Vec3; static;
    class function GlobalVectorToLocal(const ATess: TQ3ShaderTess; const AVector: TQ3Vec3): TQ3Vec3; static;
    class procedure CheckQuads(const ATess: TQ3ShaderTess); static;
  public
    /// <summary>AutospriteDeform: every quad becomes a sprite that faces the view, around its middle</summary>
    class procedure AutoSprite(var ATess: TQ3ShaderTess); static;
    /// <summary>Autosprite2Deform: every quad pivots along the middle of its long axis</summary>
    class procedure AutoSprite2(var ATess: TQ3ShaderTess); static;
    /// <summary>DeformText: the first quad of the surface is replaced by one quad per character of the text</summary>
    class procedure DeformText(var ATess: TQ3ShaderTess; const AText: AnsiString); static;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.VectorMath, DelphiDoom.Decl.Q3Shader.Calc.QuadStamp,
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

const
  SOddCounts = 'autosprite surface with an odd vertex or index count';
  SNoEntity = 'the deformation needs the current entity';
  EdgeVertexes: array[0..5, 0..1] of Integer = ((0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3));

class function TQ3SpriteDeform.Vertex(const ATess: TQ3ShaderTess; AIndex: Integer): TQ3Vec3;
begin
  Result[0] := ATess.Xyz[AIndex * 4];
  Result[1] := ATess.Xyz[AIndex * 4 + 1];
  Result[2] := ATess.Xyz[AIndex * 4 + 2];
end;

class function TQ3SpriteDeform.GlobalVectorToLocal(const ATess: TQ3ShaderTess; const AVector: TQ3Vec3): TQ3Vec3;
var
  LAxis: Integer;
  LX, LY, LZ: Single;
begin
  for LAxis := 0 to 2 do
  begin
    LX := AVector[0] * ATess.Orientation.Axis[LAxis][0];
    LY := AVector[1] * ATess.Orientation.Axis[LAxis][1];
    LZ := AVector[2] * ATess.Orientation.Axis[LAxis][2];
    LX := LX + LY;
    Result[LAxis] := LX + LZ;
  end;
end;

class procedure TQ3SpriteDeform.CheckQuads(const ATess: TQ3ShaderTess);
begin
  if ((ATess.NumVertexes and 3) <> 0) or (Length(ATess.Xyz) < ATess.NumVertexes * 4) or
    (Length(ATess.Indexes) < (ATess.NumVertexes shr 2) * 6) then
    raise EDeclQ3ShaderCalcException.Create(SOddCounts);
end;

class procedure TQ3SpriteDeform.AutoSprite(var ATess: TQ3ShaderTess);
const
  Radius707: Single = 0.707;
  Quarter: Single = 0.25;
var
  LMask: IInterface;
  LOldVertexes, LIndex, LAxis: Integer;
  LMid, LDelta, LLeftDirection, LUpDirection, LLeft, LUp, LZero: TQ3Vec3;
  LRadius, LSum, LAxisLength: Single;
  LColor: Cardinal;
begin
  LMask := TQ3FloatMask.Enter;
  CheckQuads(ATess);
  if not ATess.Entity.Present then
    raise EDeclQ3ShaderCalcException.Create(SNoEntity);
  FillChar(LZero, SizeOf(LZero), 0);
  LOldVertexes := ATess.NumVertexes;
  ATess.NumVertexes := 0;
  ATess.NumIndexes := 0;

  if not ATess.Entity.IsWorld then
  begin
    LLeftDirection := GlobalVectorToLocal(ATess, ATess.View.Axis[1]);
    LUpDirection := GlobalVectorToLocal(ATess, ATess.View.Axis[2]);
  end
  else
  begin
    LLeftDirection := ATess.View.Axis[1];
    LUpDirection := ATess.View.Axis[2];
  end;

  LIndex := 0;
  while LIndex < LOldVertexes do
  begin
    // the middle: 0.25f * (a + b + c + d), summed from the left
    for LAxis := 0 to 2 do
    begin
      LSum := ATess.Xyz[LIndex * 4 + LAxis] + ATess.Xyz[(LIndex + 1) * 4 + LAxis];
      LSum := LSum + ATess.Xyz[(LIndex + 2) * 4 + LAxis];
      LSum := LSum + ATess.Xyz[(LIndex + 3) * 4 + LAxis];
      LMid[LAxis] := Quarter * LSum;
    end;
    LDelta := TQ3VectorMath.Subtract(Vertex(ATess, LIndex), LMid);
    LRadius := TQ3VectorMath.Length(LDelta);
    LRadius := LRadius * Radius707;
    LLeft := TQ3VectorMath.Scale(LLeftDirection, LRadius);
    LUp := TQ3VectorMath.Scale(LUpDirection, LRadius);
    if ATess.View.IsMirror then
      LLeft := TQ3VectorMath.Subtract(LZero, LLeft);
    // compensate for the scale of the axes
    if ATess.Entity.NonNormalizedAxes then
    begin
      LAxisLength := TQ3VectorMath.Length(ATess.Entity.Axis[0]);
      if LAxisLength = 0 then
        LAxisLength := 0
      else
        LAxisLength := 1 / LAxisLength;
      LLeft := TQ3VectorMath.Scale(LLeft, LAxisLength);
      LUp := TQ3VectorMath.Scale(LUp, LAxisLength);
    end;
    // the color of the first vertex of the quad (the stamp may overwrite it: it is the same slot)
    LColor := PCardinal(@ATess.VertexColors[LIndex * 4])^;
    TQ3QuadStamp.Add(ATess, LMid, LLeft, LUp, LColor);
    Inc(LIndex, 4);
  end;
end;

class procedure TQ3SpriteDeform.AutoSprite2(var ATess: TQ3ShaderTess);
var
  LMask: IInterface;
  LForward, LMajor, LMinor, LTemp: TQ3Vec3;
  LMids: array[0..1] of TQ3Vec3;
  LLengths: array[0..1] of Single;
  LNumbers: array[0..1] of Integer;
  LI, LIndexes, LJ, LK, LAxis, LVertexA, LVertexB: Integer;
  LLength, LHalf: Single;
  LRoot: Double;
  LV1, LV2: TQ3Vec3;
begin
  LMask := TQ3FloatMask.Enter;
  CheckQuads(ATess);
  if not ATess.Entity.Present then
    raise EDeclQ3ShaderCalcException.Create(SNoEntity);
  if not ATess.Entity.IsWorld then
    LForward := GlobalVectorToLocal(ATess, ATess.View.Axis[0])
  else
    LForward := ATess.View.Axis[0];

  LI := 0;
  LIndexes := 0;
  while LI < ATess.NumVertexes do
  begin
    // the two shortest edges
    LNumbers[0] := 0;
    LNumbers[1] := 0;
    LLengths[0] := 999999;
    LLengths[1] := 999999;
    for LJ := 0 to 5 do
    begin
      LTemp := TQ3VectorMath.Subtract(Vertex(ATess, LI + EdgeVertexes[LJ][0]), Vertex(ATess, LI + EdgeVertexes[LJ][1]));
      LLength := TQ3VectorMath.LengthSquared(LTemp);
      if LLength < LLengths[0] then
      begin
        LNumbers[1] := LNumbers[0];
        LLengths[1] := LLengths[0];
        LNumbers[0] := LJ;
        LLengths[0] := LLength;
      end
      else if LLength < LLengths[1] then
      begin
        LNumbers[1] := LJ;
        LLengths[1] := LLength;
      end;
    end;

    for LJ := 0 to 1 do
    begin
      LV1 := Vertex(ATess, LI + EdgeVertexes[LNumbers[LJ]][0]);
      LV2 := Vertex(ATess, LI + EdgeVertexes[LNumbers[LJ]][1]);
      LHalf := LV1[0] + LV2[0];
      LMids[LJ][0] := 0.5 * LHalf;
      LHalf := LV1[1] + LV2[1];
      LMids[LJ][1] := 0.5 * LHalf;
      LHalf := LV1[2] + LV2[2];
      LMids[LJ][2] := 0.5 * LHalf;
    end;

    // the major axis, and the minor one across the view direction
    LMajor := TQ3VectorMath.Subtract(LMids[1], LMids[0]);
    LMinor := TQ3VectorMath.Cross(LMajor, LForward);
    TQ3VectorMath.Normalize(LMinor);

    // re-project the points
    for LJ := 0 to 1 do
    begin
      LVertexA := LI + EdgeVertexes[LNumbers[LJ]][0];
      LVertexB := LI + EdgeVertexes[LNumbers[LJ]][1];
      LRoot := 0.5 * Sqrt(Double(LLengths[LJ]));
      LLength := LRoot;
      // the direction in which the edge is used says the direction of the projection
      LK := 0;
      while LK < 5 do
      begin
        if (ATess.Indexes[LIndexes + LK] = LVertexA) and (ATess.Indexes[LIndexes + LK + 1] = LVertexB) then
          Break;
        Inc(LK);
      end;
      if LK = 5 then
      begin
        LV1 := TQ3VectorMath.MultiplyAdd(LMids[LJ], LLength, LMinor);
        LV2 := TQ3VectorMath.MultiplyAdd(LMids[LJ], -LLength, LMinor);
      end
      else
      begin
        LV1 := TQ3VectorMath.MultiplyAdd(LMids[LJ], -LLength, LMinor);
        LV2 := TQ3VectorMath.MultiplyAdd(LMids[LJ], LLength, LMinor);
      end;
      for LAxis := 0 to 2 do
      begin
        ATess.Xyz[LVertexA * 4 + LAxis] := LV1[LAxis];
        ATess.Xyz[LVertexB * 4 + LAxis] := LV2[LAxis];
      end;
    end;
    Inc(LI, 4);
    Inc(LIndexes, 6);
  end;
end;

class procedure TQ3SpriteDeform.DeformText(var ATess: TQ3ShaderTess; const AText: AnsiString);
const
  Quarter: Single = 0.25;
  Half: Single = 0.5;
  ThreeQuarters: Single = -0.75;
  Sixteenth: Single = 0.0625;
var
  LMask: IInterface;
  LOrigin, LWidth, LHeight, LMid, LVertex: TQ3Vec3;
  LBottom, LTop, LRow, LColumn, LSize, LScale: Single;
  LIndex, LCharacter, LLength: Integer;
begin
  LMask := TQ3FloatMask.Enter;
  if (ATess.NumVertexes < 4) or (Length(ATess.Xyz) < 16) or (Length(ATess.Normal) < 4) then
    raise EDeclQ3ShaderCalcException.Create(SOddCounts);
  LHeight[0] := 0;
  LHeight[1] := 0;
  LHeight[2] := -1;
  LVertex[0] := ATess.Normal[0];
  LVertex[1] := ATess.Normal[1];
  LVertex[2] := ATess.Normal[2];
  LWidth := TQ3VectorMath.Cross(LVertex, LHeight);

  // the middle of the box
  FillChar(LMid, SizeOf(LMid), 0);
  LBottom := 999999;
  LTop := -999999;
  for LIndex := 0 to 3 do
  begin
    LVertex := Vertex(ATess, LIndex);
    LMid := TQ3VectorMath.Add(LVertex, LMid);
    if LVertex[2] < LBottom then
      LBottom := LVertex[2];
    if LVertex[2] > LTop then
      LTop := LVertex[2];
  end;
  LOrigin := TQ3VectorMath.Scale(LMid, Quarter);

  // the size of a character
  LHeight[0] := 0;
  LHeight[1] := 0;
  LScale := LTop - LBottom;
  LHeight[2] := LScale * Half;
  LScale := LHeight[2] * ThreeQuarters;
  LWidth := TQ3VectorMath.Scale(LWidth, LScale);

  // the starting position
  LLength := Length(AText);
  LOrigin := TQ3VectorMath.MultiplyAdd(LOrigin, LLength - 1, LWidth);

  ATess.NumIndexes := 0;
  ATess.NumVertexes := 0;

  for LIndex := 1 to LLength do
  begin
    LCharacter := Ord(AText[LIndex]) and 255;
    if LCharacter <> Ord(' ') then
    begin
      LRow := (LCharacter shr 4) * Sixteenth;
      LColumn := (LCharacter and 15) * Sixteenth;
      LSize := Sixteenth;
      TQ3QuadStamp.AddExt(ATess, LOrigin, LWidth, LHeight, $FFFFFFFF, LColumn, LRow, LColumn + LSize, LRow + LSize);
    end;
    LOrigin := TQ3VectorMath.MultiplyAdd(LOrigin, -2, LWidth);
  end;
end;

end.
