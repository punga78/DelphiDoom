{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore - patches of Quake III Arena: the normals of a mesh    }
{                                                                              }
{  Port of MakeMeshNormals (tr_curve.c). Based on the Quake III Arena GPL      }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Patch.Normals;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Patch.ControlMesh;

type
  /// <summary>
  ///   Computes the normal of every vertex of a mesh from the eight neighbours, with the
  ///   wrapping of closed meshes and the search for a farther neighbour (up to 3 steps) when
  ///   an edge is degenerate.
  /// </summary>
  TPatchNormals = class
  public
    /// <summary>MakeMeshNormals: sets the Normal of the cells of a Width x Height mesh</summary>
    class procedure Compute(const AMesh: TPatchControlMesh; const AWidth, AHeight: Integer); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Types, DelphiDoom.MathCore.Patch.VertexMath;

const
  NEIGHBORS: array[0..7, 0..1] of Integer = (
    (0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1));

class procedure TPatchNormals.Compute(const AMesh: TPatchControlMesh; const AWidth, AHeight: Integer);
var
  LI, LJ, LK, LDist, LX, LY: Integer;
  LNormal, LSum, LBase, LDelta, LTemp: TIdVec3;
  LAround: array[0..7] of TIdVec3;
  LGood: array[0..7] of Boolean;
  LWrapWidth, LWrapHeight: Boolean;
  LVertex: TPatchVertex;
begin
  LWrapWidth := False;
  LI := 0;
  while LI < AHeight do
  begin
    LDelta := AMesh[LI, 0].Position - AMesh[LI, AWidth - 1].Position;
    if TPatchVertexMath.LengthSquared(LDelta) > 1.0 then
      Break;
    Inc(LI);
  end;
  if LI = AHeight then
    LWrapWidth := True;

  LWrapHeight := False;
  LI := 0;
  while LI < AWidth do
  begin
    LDelta := AMesh[0, LI].Position - AMesh[AHeight - 1, LI].Position;
    if TPatchVertexMath.LengthSquared(LDelta) > 1.0 then
      Break;
    Inc(LI);
  end;
  if LI = AWidth then
    LWrapHeight := True;

  for LI := 0 to AWidth - 1 do
    for LJ := 0 to AHeight - 1 do
    begin
      LVertex := AMesh[LJ, LI];
      LBase := LVertex.Position;
      for LK := 0 to 7 do
      begin
        LAround[LK].Zero;
        LGood[LK] := False;
        for LDist := 1 to 3 do
        begin
          LX := LI + NEIGHBORS[LK, 0] * LDist;
          LY := LJ + NEIGHBORS[LK, 1] * LDist;
          if LWrapWidth then
          begin
            if LX < 0 then
              LX := AWidth - 1 + LX
            else if LX >= AWidth then
              LX := 1 + LX - AWidth;
          end;
          if LWrapHeight then
          begin
            if LY < 0 then
              LY := AHeight - 1 + LY
            else if LY >= AHeight then
              LY := 1 + LY - AHeight;
          end;
          if (LX < 0) or (LX >= AWidth) or (LY < 0) or (LY >= AHeight) then
            Break; // edge of patch
          LTemp := AMesh[LY, LX].Position - LBase;
          if TPatchVertexMath.Normalize2(LTemp, LTemp) = 0 then
            Continue; // degenerate edge, get more dist
          LGood[LK] := True;
          LAround[LK] := LTemp;
          Break; // good edge
        end;
      end;

      LSum.Zero;
      for LK := 0 to 7 do
      begin
        if (not LGood[LK]) or (not LGood[(LK + 1) and 7]) then
          Continue; // didn't get two points
        LNormal := TPatchVertexMath.Cross(LAround[(LK + 1) and 7], LAround[LK]);
        if TPatchVertexMath.Normalize2(LNormal, LNormal) = 0 then
          Continue;
        LSum := LNormal + LSum;
      end;
      // the original counts the good corners and sets the count to 1 when it is 0, but never uses it
      TPatchVertexMath.Normalize2(LSum, LNormal);
      LVertex.Normal := LNormal;
      AMesh[LJ, LI] := LVertex;
    end;
end;

end.
