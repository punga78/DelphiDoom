{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the reader of md5mesh files            }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md5.cpp   }
{  (idRenderModelMD5::LoadModel, ParseJoint). Copyright (C) 1999-2011 id       }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom 3 }
{  GPL source code and is therefore available under the GNU General Public     }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.ModelParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>
  ///   Reads an md5mesh with the lexer of idLib (flags LEXFL_ALLOWPATHNAMES and
  ///   LEXFL_NOSTRINGESCAPECHARS as the original). The joints of the file are absolute: the
  ///   default pose of the model is rewritten relative to the parents, as LoadModel does. It has no
  ///   state.
  /// </summary>
  TMd5ModelParser = class(TInterfacedObject, IMd5ModelParser)
  public
    /// <summary>
    ///   A malformed file is an EIdLexerException with the file name and the line. Differences
    ///   from the original, which reads uninitialised memory there: a parent that is not before
    ///   its joint is an error.
    /// </summary>
    function Parse(const AText, AName: AnsiString): IMd5Model;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Token,
  DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.MathCore.Float.Conversions,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Md5.Skeleton,
  DelphiDoom.Models.Md5.MeshParser,
  DelphiDoom.Models.Md5.Model;

{ TMd5ModelParser }

function TMd5ModelParser.Parse(const AText, AName: AnsiString): IMd5Model;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
  LVersion, LCount, LIndex, LParent: Integer;
  LJoints: TArray<TMd5Joint>;
  LPose: TArray<TMd5JointQuat>;
  LAbsolute: TArray<TMd5JointMat>;
  LMeshes: TArray<IMd5Mesh>;
  LParents: TArray<Integer>;
  LTriple: array[0..2] of Single;
  LParentRotation: TIdMat3;
begin
  LLexer := TIdLexer.Create(LEXFL_ALLOWPATHNAMES or LEXFL_NOSTRINGESCAPECHARS);
  try
    LLexer.LoadMemory(AText, AName);
    LToken := TIdToken.Create;

    LLexer.ExpectTokenString(MD5_VERSION_STRING);
    LVersion := LLexer.ParseInt;
    if LVersion <> MD5_VERSION then
      LLexer.Error('Invalid version %d.  Should be version %d', [LVersion, MD5_VERSION]);

    // skip the commandline
    LLexer.ExpectTokenString('commandline');
    LLexer.ReadToken(LToken);

    LLexer.ExpectTokenString('numJoints');
    LCount := LLexer.ParseInt;
    if LCount < 0 then
      LLexer.Error('Invalid size: %d', [LCount]);
    SetLength(LJoints, LCount);
    SetLength(LPose, LCount);
    SetLength(LAbsolute, LCount);
    SetLength(LParents, LCount);

    LLexer.ExpectTokenString('numMeshes');
    LCount := LLexer.ParseInt;
    if LCount < 0 then
      LLexer.Error('Invalid size: %d', [LCount]);
    SetLength(LMeshes, LCount);

    // joints: the file has absolute poses; the matrices are kept and the pose becomes relative
    LLexer.ExpectTokenString('joints');
    LLexer.ExpectTokenString('{');
    for LIndex := 0 to High(LJoints) do
    begin
      LLexer.ReadToken(LToken);
      LJoints[LIndex].Name := LToken.Text;
      LParent := LLexer.ParseInt;
      if LParent < 0 then
        LParent := -1
      else if (LParent >= Length(LJoints) - 1) or (LParent >= LIndex) then
        LLexer.Error('Invalid parent for joint ''%s''', [string(LJoints[LIndex].Name)]);
      LJoints[LIndex].Parent := LParent;
      LParents[LIndex] := LParent;

      LLexer.Parse1DMatrix(3, LTriple);
      LPose[LIndex].T := TIdVec3.Create(LTriple[0], LTriple[1], LTriple[2]);
      LLexer.Parse1DMatrix(3, LTriple);
      LPose[LIndex].Q := TIdQuat.Create(LTriple[0], LTriple[1], LTriple[2], 0.0);
      LPose[LIndex].Q.W := LPose[LIndex].Q.CalcW;

      LAbsolute[LIndex].SetRotation(TIdRotationConversions.QuatToMat(LPose[LIndex].Q));
      LAbsolute[LIndex].SetTranslation(LPose[LIndex].T);
      if LParent >= 0 then
      begin
        LParentRotation := LAbsolute[LParent].ToMat3.Transpose;
        LPose[LIndex].Q := TIdRotationConversions.MatToQuat(LAbsolute[LIndex].ToMat3 * LParentRotation);
        LPose[LIndex].T := (LAbsolute[LIndex].ToVec3 - LAbsolute[LParent].ToVec3) * LParentRotation;
      end;
    end;
    LLexer.ExpectTokenString('}');

    for LIndex := 0 to High(LMeshes) do
    begin
      LLexer.ExpectTokenString('mesh');
      LMeshes[LIndex] := TMd5MeshParser.Parse(LLexer, Length(LJoints));
    end;

    Result := TMd5Model.Create(AName, LJoints, LPose, LAbsolute, LMeshes, TMd5Skeleton.Create(LParents));
  finally
    LLexer.Free;
  end;
end;

end.
