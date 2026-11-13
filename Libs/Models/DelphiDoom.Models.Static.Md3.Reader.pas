{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the reader of MD3 files      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md3.cpp   }
{  (idRenderModelMD3::InitFromFile). Copyright (C) 1999-2011 id Software LLC,  }
{  a ZeniMax Media company. This unit is derived from the Doom 3 GPL source    }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Md3.Reader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Md3.Types;

type
  /// <summary>
  ///   Reads a Quake 3 model as Doom 3 does: only the version is checked (not the identifier), a
  ///   model needs a frame, a surface has at most 1000 vertexes and 2000 triangles, the names of
  ///   the surfaces are lowercased and lose a trailing "_1" or "_2". The shaders are names. Where
  ///   the original trusts the offsets and counts of the file the reader checks them and raises
  ///   EStaticModelException with the offset. No state.
  /// </summary>
  TMd3Reader = class
  public
    function Read(const AData: TBytes; const AName: AnsiString): TMd3Model;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.ByteReader;

function ReadVec3(const AReader: TStaticByteReader): TIdVec3;
begin
  Result.X := AReader.ReadLeSingle;
  Result.Y := AReader.ReadLeSingle;
  Result.Z := AReader.ReadLeSingle;
end;

procedure CheckRange(const AReader: TStaticByteReader; const AWhat: string; const AOffset, ASize: Integer);
begin
  if (AOffset < 0) or (ASize < 0) or (Int64(AOffset) + ASize > AReader.Size) then
    raise EStaticModelException.CreateAtOffset(Format(SStaticMd3Offset, [AWhat, AOffset, ASize]), AOffset);
end;

procedure CheckCount(const AWhat: string; const ACount: Integer);
begin
  if ACount < 0 then
    raise EStaticModelException.CreateAtOffset(Format(SStaticMd3BadCount, [AWhat, ACount]), -1);
end;

function ReadSurface(const AReader: TStaticByteReader; const AStart: Integer; out ANext: Integer): TMd3Surface;
var
  LNumShaders, LNumTriangles, LOfsTriangles, LOfsShaders, LOfsSt, LOfsXyz, LOfsEnd: Integer;
  LIndex, LLength: Integer;
begin
  AReader.Position := AStart;
  AReader.ReadLeInt32;    // the identifier becomes SF_MD3 (0) and is not kept
  Result.Name := AReader.ReadFixedString(MD3_MAX_PATH);
  Result.Flags := AReader.ReadLeInt32;
  Result.NumFrames := AReader.ReadLeInt32;
  LNumShaders := AReader.ReadLeInt32;
  Result.NumVerts := AReader.ReadLeInt32;
  LNumTriangles := AReader.ReadLeInt32;
  LOfsTriangles := AReader.ReadLeInt32;
  LOfsShaders := AReader.ReadLeInt32;
  LOfsSt := AReader.ReadLeInt32;
  LOfsXyz := AReader.ReadLeInt32;
  LOfsEnd := AReader.ReadLeInt32;
  CheckCount('numFrames', Result.NumFrames);
  CheckCount('numShaders', LNumShaders);
  CheckCount('numVerts', Result.NumVerts);
  CheckCount('numTriangles', LNumTriangles);
  if Result.NumVerts > MD3_SHADER_MAX_VERTEXES then
    raise EStaticModelException.CreateAtOffset(Format(SStaticMd3TooManyVerts,
      [MD3_SHADER_MAX_VERTEXES, Result.NumVerts]), AStart);
  if LNumTriangles * 3 > MD3_SHADER_MAX_INDEXES then
    raise EStaticModelException.CreateAtOffset(Format(SStaticMd3TooManyTriangles,
      [MD3_SHADER_MAX_INDEXES div 3, LNumTriangles]), AStart);
  // lowercase the surface name so skin compares are faster
  Result.Name := AnsiString(LowerCase(string(Result.Name)));
  // strip off a trailing _1 or _2: this is a crutch for q3data being a mess
  LLength := Length(Result.Name);
  if (LLength > 2) and (Result.Name[LLength - 1] = '_') then
    SetLength(Result.Name, LLength - 2);

  CheckRange(AReader, 'shaders', AStart + LOfsShaders, LNumShaders * 68);
  AReader.Position := AStart + LOfsShaders;
  SetLength(Result.Shaders, LNumShaders);
  for LIndex := 0 to LNumShaders - 1 do
  begin
    Result.Shaders[LIndex] := AReader.ReadFixedString(MD3_MAX_PATH);
    AReader.Skip(4);
  end;

  CheckRange(AReader, 'triangles', AStart + LOfsTriangles, LNumTriangles * 12);
  AReader.Position := AStart + LOfsTriangles;
  SetLength(Result.Triangles, LNumTriangles * 3);
  for LIndex := 0 to High(Result.Triangles) do
    Result.Triangles[LIndex] := AReader.ReadLeInt32;

  CheckRange(AReader, 'texture coordinates', AStart + LOfsSt, Result.NumVerts * 8);
  AReader.Position := AStart + LOfsSt;
  SetLength(Result.St, Result.NumVerts);
  for LIndex := 0 to Result.NumVerts - 1 do
  begin
    Result.St[LIndex].X := AReader.ReadLeSingle;
    Result.St[LIndex].Y := AReader.ReadLeSingle;
  end;

  CheckRange(AReader, 'vertexes', AStart + LOfsXyz, Result.NumVerts * Result.NumFrames * 8);
  AReader.Position := AStart + LOfsXyz;
  SetLength(Result.XyzNormals, Result.NumVerts * Result.NumFrames * 4);
  for LIndex := 0 to High(Result.XyzNormals) do
    Result.XyzNormals[LIndex] := AReader.ReadLeInt16;
  if LOfsEnd < MD3_SURFACE_HEADER_SIZE then
    raise EStaticModelException.CreateAtOffset(Format(SStaticMd3Offset, ['end of the surface', LOfsEnd, AReader.Size]), AStart);
  ANext := AStart + LOfsEnd;
end;

{ TMd3Reader }

function TMd3Reader.Read(const AData: TBytes; const AName: AnsiString): TMd3Model;
var
  LReader: TStaticByteReader;
  LVersion, LNumFrames, LNumSurfaces, LOfsFrames, LOfsTags, LOfsSurfaces, LOfsEnd, LIndex, LTagIndex, LSurface: Integer;
  LNext: Integer;
begin
  LReader := TStaticByteReader.Create(AData);
  try
    if Length(AData) < MD3_HEADER_SIZE then
      raise EStaticModelException.CreateAtOffset(Format(SStaticTruncated, [MD3_HEADER_SIZE, 0, Length(AData)]), 0);
    LReader.ReadLeInt32;    // the identifier is not checked
    LVersion := LReader.ReadLeInt32;
    if LVersion <> MD3_VERSION then
      raise EStaticModelException.CreateAtOffset(Format(SStaticMd3Version, [LVersion, MD3_VERSION]), 4);
    Result.Name := AName;
    LReader.ReadFixedString(MD3_MAX_PATH);    // the name in the file is not used: the model gets the file name
    Result.Flags := LReader.ReadLeInt32;
    LNumFrames := LReader.ReadLeInt32;
    Result.NumTags := LReader.ReadLeInt32;
    LNumSurfaces := LReader.ReadLeInt32;
    Result.NumSkins := LReader.ReadLeInt32;
    LOfsFrames := LReader.ReadLeInt32;
    LOfsTags := LReader.ReadLeInt32;
    LOfsSurfaces := LReader.ReadLeInt32;
    LOfsEnd := LReader.ReadLeInt32;
    CheckCount('numFrames', LNumFrames);
    CheckCount('numTags', Result.NumTags);
    CheckCount('numSurfaces', LNumSurfaces);
    if LNumFrames < 1 then
      raise EStaticModelException.CreateAtOffset(SStaticMd3NoFrames, 0);
    // the original copies ofsEnd bytes of the file
    if (LOfsEnd < MD3_HEADER_SIZE) or (LOfsEnd > Length(AData)) then
      raise EStaticModelException.CreateAtOffset(Format(SStaticMd3Offset, ['end of the model', LOfsEnd, Length(AData)]), LOfsEnd);

    CheckRange(LReader, 'frames', LOfsFrames, LNumFrames * MD3_FRAME_SIZE);
    LReader.Position := LOfsFrames;
    SetLength(Result.Frames, LNumFrames);
    for LIndex := 0 to LNumFrames - 1 do
    begin
      Result.Frames[LIndex].BoundsMin := ReadVec3(LReader);
      Result.Frames[LIndex].BoundsMax := ReadVec3(LReader);
      Result.Frames[LIndex].LocalOrigin := ReadVec3(LReader);
      Result.Frames[LIndex].Radius := LReader.ReadLeSingle;
      Result.Frames[LIndex].Name := LReader.ReadFixedString(16);
    end;

    CheckRange(LReader, 'tags', LOfsTags, Result.NumTags * LNumFrames * MD3_TAG_SIZE);
    LReader.Position := LOfsTags;
    SetLength(Result.Tags, Result.NumTags * LNumFrames);
    for LTagIndex := 0 to High(Result.Tags) do
    begin
      Result.Tags[LTagIndex].Name := LReader.ReadFixedString(MD3_MAX_PATH);
      Result.Tags[LTagIndex].Origin := ReadVec3(LReader);
      for LIndex := 0 to 2 do
        Result.Tags[LTagIndex].Axis[LIndex] := ReadVec3(LReader);
    end;

    SetLength(Result.Surfaces, LNumSurfaces);
    LNext := LOfsSurfaces;
    for LSurface := 0 to LNumSurfaces - 1 do
    begin
      CheckRange(LReader, 'surface', LNext, MD3_SURFACE_HEADER_SIZE);
      // the next surface follows at ofsEnd of this one
      Result.Surfaces[LSurface] := ReadSurface(LReader, LNext, LNext);
    end;
  finally
    LReader.Free;
  end;
end;

end.
