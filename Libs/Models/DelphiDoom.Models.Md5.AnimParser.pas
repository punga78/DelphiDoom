{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the reader of md5anim files            }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim.cpp       }
{  (idMD5Anim::LoadAnim). Copyright (C) 1999-2011 id Software LLC, a ZeniMax   }
{  Media company. This unit is derived from the Doom 3 GPL source code and is  }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.AnimParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>
  ///   Reads an md5anim with the lexer of idLib (flags LEXFL_ALLOWPATHNAMES,
  ///   LEXFL_NOSTRINGESCAPECHARS and LEXFL_NOSTRINGCONCAT as the original). It has no state.
  /// </summary>
  TMd5AnimParser = class(TInterfacedObject, IMd5AnimParser)
  public
    /// <summary>
    ///   A malformed file is an EIdLexerException with the file name and the line. Differences
    ///   from the original, which reads memory out of range there: a frame rate of zero (the
    ///   length divides by it) and components of a joint that go beyond the components of the
    ///   frame are errors.
    /// </summary>
    function Parse(const AText, AName: AnsiString): IMd5Anim;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Token,
  DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.MathCore.Float.CQuat,
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.Anim;

function ComponentCount(const ABits: Integer): Integer;
var
  LBit: Integer;
begin
  Result := 0;
  for LBit := 0 to 5 do
    if (ABits and (1 shl LBit)) <> 0 then
      Inc(Result);
end;

{ TMd5AnimParser }

function TMd5AnimParser.Parse(const AText, AName: AnsiString): IMd5Anim;
var
  LLexer: TIdLexer;
  LToken: TIdToken;
  LVersion, LFrames, LJoints, LRate, LComponents, LIndex, LFrame, LNum, LPtr: Integer;
  LInfo: TArray<TMd5AnimJointInfo>;
  LBounds: TArray<TGeoBounds>;
  LBase: TArray<TMd5JointQuat>;
  LData: TArray<Single>;
  LTriple: array[0..2] of Single;
  LCQuat: TIdCQuat;
  LDelta: TIdVec3;
  LMins, LMaxs: TGeoVec3;
begin
  LLexer := TIdLexer.Create(LEXFL_ALLOWPATHNAMES or LEXFL_NOSTRINGESCAPECHARS or LEXFL_NOSTRINGCONCAT);
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

    LLexer.ExpectTokenString('numFrames');
    LFrames := LLexer.ParseInt;
    if LFrames <= 0 then
      LLexer.Error('Invalid number of frames: %d', [LFrames]);

    LLexer.ExpectTokenString('numJoints');
    LJoints := LLexer.ParseInt;
    if LJoints <= 0 then
      LLexer.Error('Invalid number of joints: %d', [LJoints]);

    LLexer.ExpectTokenString('frameRate');
    LRate := LLexer.ParseInt;
    if LRate <= 0 then
      LLexer.Error('Invalid frame rate: %d', [LRate]);

    LLexer.ExpectTokenString('numAnimatedComponents');
    LComponents := LLexer.ParseInt;
    if (LComponents < 0) or (LComponents > LJoints * 6) then
      LLexer.Error('Invalid number of animated components: %d', [LComponents]);

    // hierarchy
    SetLength(LInfo, LJoints);
    LLexer.ExpectTokenString('hierarchy');
    LLexer.ExpectTokenString('{');
    for LIndex := 0 to LJoints - 1 do
    begin
      LLexer.ReadToken(LToken);
      LInfo[LIndex].Name := LToken.Text;

      LInfo[LIndex].ParentNum := LLexer.ParseInt;
      if LInfo[LIndex].ParentNum >= LIndex then
        LLexer.Error('Invalid parent num: %d', [LInfo[LIndex].ParentNum]);
      if (LIndex <> 0) and (LInfo[LIndex].ParentNum < 0) then
        LLexer.Error('Animations may have only one root joint', []);

      LInfo[LIndex].AnimBits := LLexer.ParseInt;
      if (LInfo[LIndex].AnimBits and not 63) <> 0 then
        LLexer.Error('Invalid anim bits: %d', [LInfo[LIndex].AnimBits]);

      LInfo[LIndex].FirstComponent := LLexer.ParseInt;
      if (LComponents > 0) and ((LInfo[LIndex].FirstComponent < 0) or
        (LInfo[LIndex].FirstComponent >= LComponents)) then
        LLexer.Error('Invalid first component: %d', [LInfo[LIndex].FirstComponent]);
      if (LComponents > 0) and (LInfo[LIndex].FirstComponent + ComponentCount(LInfo[LIndex].AnimBits) > LComponents) then
        LLexer.Error('The components of the joint go beyond the %d of a frame', [LComponents]);
    end;
    LLexer.ExpectTokenString('}');

    // bounds
    LLexer.ExpectTokenString('bounds');
    LLexer.ExpectTokenString('{');
    SetLength(LBounds, LFrames);
    for LIndex := 0 to LFrames - 1 do
    begin
      LLexer.Parse1DMatrix(3, LTriple);
      LMins := TGeoVec3.Make(LTriple[0], LTriple[1], LTriple[2]);
      LLexer.Parse1DMatrix(3, LTriple);
      LMaxs := TGeoVec3.Make(LTriple[0], LTriple[1], LTriple[2]);
      LBounds[LIndex] := TGeoBounds.Make(LMins, LMaxs);
    end;
    LLexer.ExpectTokenString('}');

    // base frame
    SetLength(LBase, LJoints);
    LLexer.ExpectTokenString('baseframe');
    LLexer.ExpectTokenString('{');
    for LIndex := 0 to LJoints - 1 do
    begin
      LLexer.Parse1DMatrix(3, LTriple);
      LBase[LIndex].T := TIdVec3.Create(LTriple[0], LTriple[1], LTriple[2]);
      LLexer.Parse1DMatrix(3, LTriple);
      LCQuat := TIdCQuat.Create(LTriple[0], LTriple[1], LTriple[2]);
      LBase[LIndex].Q := LCQuat.ToQuat;
    end;
    LLexer.ExpectTokenString('}');

    // frames
    SetLength(LData, LComponents * LFrames);
    LPtr := 0;
    for LFrame := 0 to LFrames - 1 do
    begin
      LLexer.ExpectTokenString('frame');
      LNum := LLexer.ParseInt;
      if LNum <> LFrame then
        LLexer.Error('Expected frame number %d', [LFrame]);
      LLexer.ExpectTokenString('{');
      for LIndex := 0 to LComponents - 1 do
      begin
        LData[LPtr] := LLexer.ParseFloat;
        Inc(LPtr);
      end;
      LLexer.ExpectTokenString('}');
    end;

    // the total move delta: the root translation is relative to the base frame
    LDelta.Zero;
    if LComponents > 0 then
    begin
      LPtr := LInfo[0].FirstComponent;
      if (LInfo[0].AnimBits and ANIM_TX) <> 0 then
      begin
        for LFrame := 0 to LFrames - 1 do
          LData[LPtr + LComponents * LFrame] := LData[LPtr + LComponents * LFrame] - LBase[0].T.X;
        LDelta.X := LData[LPtr + LComponents * (LFrames - 1)];
        Inc(LPtr);
      end;
      if (LInfo[0].AnimBits and ANIM_TY) <> 0 then
      begin
        for LFrame := 0 to LFrames - 1 do
          LData[LPtr + LComponents * LFrame] := LData[LPtr + LComponents * LFrame] - LBase[0].T.Y;
        LDelta.Y := LData[LPtr + LComponents * (LFrames - 1)];
        Inc(LPtr);
      end;
      if (LInfo[0].AnimBits and ANIM_TZ) <> 0 then
      begin
        for LFrame := 0 to LFrames - 1 do
          LData[LPtr + LComponents * LFrame] := LData[LPtr + LComponents * LFrame] - LBase[0].T.Z;
        LDelta.Z := LData[LPtr + LComponents * (LFrames - 1)];
      end;
    end;
    LBase[0].T.Zero;

    Result := TMd5Anim.Create(AName, LRate, LComponents, LInfo, LBounds, LBase, LData, LDelta);
  finally
    LLexer.Free;
  end;
end;

end.
