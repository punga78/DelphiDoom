{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the reader of a mesh of an md5mesh     }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md5.cpp   }
{  (idMD5Mesh::ParseMesh). Copyright (C) 1999-2011 id Software LLC, a ZeniMax  }
{  Media company. This unit is derived from the Doom 3 GPL source code and is  }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.MeshParser;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>Reads the block after the word "mesh": it has no state</summary>
  TMd5MeshParser = class
  public
    /// <summary>
    ///   idMD5Mesh::ParseMesh without the material lookup and the deform info. The lexer is at the
    ///   "{" after "mesh". Errors are EIdLexerException with file and line. Differences from the
    ///   original, which reads memory out of range there: a weight index outside the weights and a
    ///   triangle vertex outside the vertexes are errors.
    /// </summary>
    class function Parse(const ALexer: TIdLexer; const ANumJoints: Integer): IMd5Mesh; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.IdLib.Text.Token,
  DelphiDoom.Models.Md5.Mesh;

type
  TVertexWeight = record
    Joint: Integer;
    JointWeight: Single;
    Offset: TIdVec3;
  end;

{ TMd5MeshParser }

class function TMd5MeshParser.Parse(const ALexer: TIdLexer; const ANumJoints: Integer): IMd5Mesh;
var
  LToken: TIdToken;
  LName, LShader: AnsiString;
  LCount, LIndex, LWeightIndex, LNum, LJoint, LMaxWeight, LTotal: Integer;
  LCoords: TArray<TIdVec2>;
  LFirst, LNumFor, LTris, LJoints: TArray<Integer>;
  LTemp: TArray<TVertexWeight>;
  LScaled: TArray<TIdVec4>;
  LEnds: TArray<Boolean>;
  LPair: array[0..1] of Single;
  LTriple: array[0..2] of Single;
  LTexCoord: TIdVec2;
  LOffset: TIdVec3;
begin
  LToken := TIdToken.Create;
  ALexer.ExpectTokenString('{');

  // name (optional) and shader
  LName := '';
  if ALexer.CheckTokenString('name') then
  begin
    ALexer.ReadToken(LToken);
    LName := LToken.Text;
  end;
  ALexer.ExpectTokenString('shader');
  ALexer.ReadToken(LToken);
  LShader := LToken.Text;

  // texture coordinates and the weights of every vertex
  ALexer.ExpectTokenString('numverts');
  LCount := ALexer.ParseInt;
  if LCount < 0 then
    ALexer.Error('Invalid size: %d', [LCount]);
  SetLength(LCoords, LCount);
  SetLength(LFirst, LCount);
  SetLength(LNumFor, LCount);
  LTotal := 0;
  LMaxWeight := 0;
  for LIndex := 0 to LCount - 1 do
  begin
    ALexer.ExpectTokenString('vert');
    ALexer.ParseInt;
    ALexer.Parse1DMatrix(2, LPair);
    LTexCoord.X := LPair[0];
    LTexCoord.Y := LPair[1];
    LCoords[LIndex] := LTexCoord;
    LFirst[LIndex] := ALexer.ParseInt;
    LNumFor[LIndex] := ALexer.ParseInt;
    if LNumFor[LIndex] = 0 then
      ALexer.Error('Vertex without any joint weights.', []);
    if (LNumFor[LIndex] < 0) or (LFirst[LIndex] < 0) then
      ALexer.Error('Invalid weights for a vertex: first %d, count %d', [LFirst[LIndex], LNumFor[LIndex]]);
    Inc(LTotal, LNumFor[LIndex]);
    if LNumFor[LIndex] + LFirst[LIndex] > LMaxWeight then
      LMaxWeight := LNumFor[LIndex] + LFirst[LIndex];
  end;

  // triangles
  ALexer.ExpectTokenString('numtris');
  LCount := ALexer.ParseInt;
  if LCount < 0 then
    ALexer.Error('Invalid size: %d', [LCount]);
  SetLength(LTris, LCount * 3);
  for LIndex := 0 to LCount - 1 do
  begin
    ALexer.ExpectTokenString('tri');
    ALexer.ParseInt;
    for LNum := 0 to 2 do
    begin
      LTris[LIndex * 3 + LNum] := ALexer.ParseInt;
      if (LTris[LIndex * 3 + LNum] < 0) or (LTris[LIndex * 3 + LNum] >= Length(LCoords)) then
        ALexer.Error('Triangle vertex out of range(%d): %d', [Length(LCoords), LTris[LIndex * 3 + LNum]]);
    end;
  end;

  // weights
  ALexer.ExpectTokenString('numweights');
  LCount := ALexer.ParseInt;
  if LCount < 0 then
    ALexer.Error('Invalid size: %d', [LCount]);
  if LMaxWeight > LCount then
    ALexer.Error('Vertices reference out of range weights in model (%d of %d weights).', [LMaxWeight, LCount]);
  SetLength(LTemp, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    ALexer.ExpectTokenString('weight');
    ALexer.ParseInt;
    LJoint := ALexer.ParseInt;
    if (LJoint < 0) or (LJoint >= ANumJoints) then
      ALexer.Error('Joint Index out of range(%d): %d', [ANumJoints, LJoint]);
    LTemp[LIndex].Joint := LJoint;
    LTemp[LIndex].JointWeight := ALexer.ParseFloat;
    ALexer.Parse1DMatrix(3, LTriple);
    LOffset.X := LTriple[0];
    LOffset.Y := LTriple[1];
    LOffset.Z := LTriple[2];
    LTemp[LIndex].Offset := LOffset;
  end;

  // pre-scaled weights, in the order of the vertexes, and the end of every vertex
  SetLength(LScaled, LTotal);
  SetLength(LJoints, LTotal);
  SetLength(LEnds, LTotal);
  LWeightIndex := 0;
  for LIndex := 0 to High(LCoords) do
  begin
    LNum := LFirst[LIndex];
    for LJoint := 0 to LNumFor[LIndex] - 1 do
    begin
      LScaled[LWeightIndex] := TIdVec4.Create(
        LTemp[LNum].Offset.X * LTemp[LNum].JointWeight,
        LTemp[LNum].Offset.Y * LTemp[LNum].JointWeight,
        LTemp[LNum].Offset.Z * LTemp[LNum].JointWeight,
        LTemp[LNum].JointWeight);
      LJoints[LWeightIndex] := LTemp[LNum].Joint;
      LEnds[LWeightIndex] := LJoint = LNumFor[LIndex] - 1;
      Inc(LNum);
      Inc(LWeightIndex);
    end;
  end;

  ALexer.ExpectTokenString('}');
  Result := TMd5Mesh.Create(LName, LShader, LCoords, LTris, LScaled, LJoints, LEnds);
end;

end.
