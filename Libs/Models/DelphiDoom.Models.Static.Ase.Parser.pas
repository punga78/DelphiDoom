{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the reader of ASE files      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_ase.cpp   }
{  (ASE_Parse and the ASE_Key* functions). Copyright (C) 1999-2011 id          }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom 3 }
{  GPL source code and is therefore available under the GNU General Public     }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Ase.Parser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Ase.Types;

type
  /// <summary>
  ///   Reads a 3D Studio Max ASCII export: materials (bitmap and texture matrix) and geometry
  ///   objects (vertexes, texture vertexes, colours, faces, normals, animation frames). The
  ///   structure is the one of the original, a token reader and one handler per block; the
  ///   data goes into memory as it is in the file. Errors are EStaticModelException with the
  ///   line of the token. Instances have state while they parse: one parse at a time.
  /// </summary>
  TAseParser = class
  strict private
    type
      TTokenHandler = procedure(const AToken: AnsiString) of object;
  strict private
    FResolver: TStaticPathResolver;
    FBuffer: AnsiString;
    FPosition: Integer;
    FToken: AnsiString;
    FModel: TAseModel;
    FObject: TAseObject;
    FMesh: TAseMesh;
    FMaterial: TAseMaterial;
    FCurrentFace: Integer;
    FCurrentVertex: Integer;
    FTokenPosition: Integer;
    procedure Fail(const AMessage: string);
    function LineAt(const APosition: Integer): Integer;
    function GetToken(const ARestOfLine: Boolean): Boolean;
    procedure ParseBracedBlock(const AHandler: TTokenHandler);
    procedure SkipEnclosingBraces;
    procedure SkipRestOfLine;
    function NextFloat: Single;
    function NextInt: Integer;
    procedure KeyMapDiffuse(const AToken: AnsiString);
    procedure KeyMaterial(const AToken: AnsiString);
    procedure KeyMaterialList(const AToken: AnsiString);
    procedure KeyNodeTm(const AToken: AnsiString);
    procedure KeyMeshVertexList(const AToken: AnsiString);
    procedure KeyMeshFaceList(const AToken: AnsiString);
    procedure KeyTFaceList(const AToken: AnsiString);
    procedure KeyCFaceList(const AToken: AnsiString);
    procedure KeyMeshTVertList(const AToken: AnsiString);
    procedure KeyMeshCVertList(const AToken: AnsiString);
    procedure KeyMeshNormals(const AToken: AnsiString);
    procedure KeyMesh(const AToken: AnsiString);
    procedure KeyMeshAnimation(const AToken: AnsiString);
    procedure KeyGeomObject(const AToken: AnsiString);
    procedure KeyGroup(const AToken: AnsiString);
    procedure ParseGeomObject;
    procedure NeedFaces(const AWhat: string);
  public
    /// <summary>The resolver turns a bitmap path into a material name; nil keeps the path</summary>
    constructor Create(const AResolver: TStaticPathResolver = nil);
    /// <summary>ASE_Parse: the text of the file (cut at the first zero byte, like a C string)</summary>
    function Parse(const AText: AnsiString): TAseModel;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Numbers;

const
  MAX_NAME = 127;

{ TAseParser }

constructor TAseParser.Create(const AResolver: TStaticPathResolver);
begin
  inherited Create;
  FResolver := AResolver;
end;

function TAseParser.LineAt(const APosition: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 1;
  for LIndex := 1 to APosition - 1 do
    if (LIndex <= Length(FBuffer)) and (FBuffer[LIndex] = #10) then
      Inc(Result);
end;

procedure TAseParser.Fail(const AMessage: string);
begin
  raise EStaticModelException.CreateAtLine(AMessage, LineAt(FTokenPosition));
end;

function TAseParser.GetToken(const ARestOfLine: Boolean): Boolean;
var
  LByte: Byte;
begin
  Result := False;
  if FPosition > Length(FBuffer) then
    Exit;
  FToken := '';
  // skip over crap: the original compares a signed char, so the bytes of 128 and more count too
  while (FPosition <= Length(FBuffer)) and (ShortInt(Byte(FBuffer[FPosition])) <= 32) do
    Inc(FPosition);
  FTokenPosition := FPosition;
  while FPosition <= Length(FBuffer) do
  begin
    LByte := Byte(FBuffer[FPosition]);
    Inc(FPosition);
    if ((ShortInt(LByte) <= 32) and not ARestOfLine) or (LByte = 10) or (LByte = 13) then
      Break;
    FToken := FToken + AnsiChar(LByte);
  end;
  Result := True;
end;

procedure TAseParser.ParseBracedBlock(const AHandler: TTokenHandler);
var
  LIndent: Integer;
begin
  LIndent := 0;
  while GetToken(False) do
  begin
    if FToken = '{' then
      Inc(LIndent)
    else if FToken = '}' then
    begin
      Dec(LIndent);
      if LIndent = 0 then
        Break
      else if LIndent < 0 then
        Fail(SStaticAseUnexpectedBrace);
    end
    else if Assigned(AHandler) then
      AHandler(FToken);
  end;
end;

procedure TAseParser.SkipEnclosingBraces;
begin
  ParseBracedBlock(nil);
end;

procedure TAseParser.SkipRestOfLine;
begin
  GetToken(True);
end;

function TAseParser.NextFloat: Single;
begin
  GetToken(False);
  Result := TStaticNumbers.Atof(FToken);
end;

function TAseParser.NextInt: Integer;
begin
  GetToken(False);
  Result := TStaticNumbers.Atoi(FToken);
end;

procedure TAseParser.NeedFaces(const AWhat: string);
begin
  if FMesh.Faces = nil then
    Fail(Format(SStaticAseBeforeFaces, [AWhat]));
end;

procedure TAseParser.KeyMapDiffuse(const AToken: AnsiString);
var
  LPath: AnsiString;
  LQuote: Integer;
  LIndex: Integer;
begin
  if AToken = '*BITMAP' then
  begin
    GetToken(False);
    // remove the quotes
    LPath := Copy(FToken, 2, MaxInt);
    LQuote := Pos(AnsiString('"'), LPath);
    if LQuote > 0 then
      LPath := Copy(LPath, 1, LQuote - 1);
    // convert the 3DSMax material pathname to a qpath
    for LIndex := 1 to Length(LPath) do
      if LPath[LIndex] = '\' then
        LPath[LIndex] := '/';
    if Assigned(FResolver) then
      LPath := FResolver(LPath);
    FMaterial.Name := Copy(LPath, 1, MAX_NAME);
  end
  else if AToken = '*UVW_U_OFFSET' then
    FMaterial.UOffset := NextFloat
  else if AToken = '*UVW_V_OFFSET' then
    FMaterial.VOffset := NextFloat
  else if AToken = '*UVW_U_TILING' then
    FMaterial.UTiling := NextFloat
  else if AToken = '*UVW_V_TILING' then
    FMaterial.VTiling := NextFloat
  else if AToken = '*UVW_ANGLE' then
    FMaterial.Angle := NextFloat;
end;

procedure TAseParser.KeyMaterial(const AToken: AnsiString);
begin
  if AToken = '*MAP_DIFFUSE' then
    ParseBracedBlock(KeyMapDiffuse);
end;

procedure TAseParser.KeyMaterialList(const AToken: AnsiString);
begin
  if AToken = '*MATERIAL_COUNT' then
    GetToken(False)
  else if AToken = '*MATERIAL' then
  begin
    FMaterial := Default(TAseMaterial);
    FMaterial.UTiling := 1;
    FMaterial.VTiling := 1;
    ParseBracedBlock(KeyMaterial);
    SetLength(FModel.Materials, Length(FModel.Materials) + 1);
    FModel.Materials[High(FModel.Materials)] := FMaterial;
  end;
end;

procedure TAseParser.KeyNodeTm(const AToken: AnsiString);
var
  LRow, LColumn: Integer;
begin
  for LRow := 0 to 3 do
    if AToken = '*TM_ROW' + AnsiString(IntToStr(LRow)) then
      for LColumn := 0 to 2 do
        FObject.Mesh.Transform[LRow][LColumn] := NextFloat;
end;

procedure TAseParser.KeyMeshVertexList(const AToken: AnsiString);
begin
  if AToken = '*MESH_VERTEX' then
  begin
    GetToken(False);    // skip number
    if FCurrentVertex >= Length(FMesh.Vertexes) then
      Fail(Format(SStaticAseOutOfRange, ['ase.currentVertex', FCurrentVertex, Length(FMesh.Vertexes)]));
    FMesh.Vertexes[FCurrentVertex].X := NextFloat;
    FMesh.Vertexes[FCurrentVertex].Y := NextFloat;
    FMesh.Vertexes[FCurrentVertex].Z := NextFloat;
    Inc(FCurrentVertex);
  end
  else
    Fail(Format(SStaticAseUnknownToken, [string(AToken), 'MESH_VERTEX_LIST']));
end;

procedure TAseParser.KeyMeshFaceList(const AToken: AnsiString);
begin
  if AToken = '*MESH_FACE' then
  begin
    if FCurrentFace >= Length(FMesh.Faces) then
      Fail(Format(SStaticAseOutOfRange, ['ase.currentFace', FCurrentFace, Length(FMesh.Faces)]));
    GetToken(False);    // skip face number
    // we are flipping the order here to change the front/back facing
    // from 3DS to our standard (clockwise facing out)
    GetToken(False);    // skip label
    FMesh.Faces[FCurrentFace].VertexNum[0] := NextInt;    // first vertex
    GetToken(False);    // skip label
    FMesh.Faces[FCurrentFace].VertexNum[2] := NextInt;    // second vertex
    GetToken(False);    // skip label
    FMesh.Faces[FCurrentFace].VertexNum[1] := NextInt;    // third vertex
    GetToken(True);     // the material id and the smoothing groups are not read
    Inc(FCurrentFace);
  end
  else
    Fail(Format(SStaticAseUnknownToken, [string(AToken), 'MESH_FACE_LIST']));
end;

procedure TAseParser.KeyTFaceList(const AToken: AnsiString);
var
  LA, LB, LC: Integer;
begin
  if AToken = '*MESH_TFACE' then
  begin
    if FCurrentFace >= Length(FMesh.Faces) then
      Fail(Format(SStaticAseOutOfRange, ['ase.currentFace', FCurrentFace, Length(FMesh.Faces)]));
    GetToken(False);
    LA := NextInt;
    LC := NextInt;
    LB := NextInt;
    FMesh.Faces[FCurrentFace].TVertexNum[0] := LA;
    FMesh.Faces[FCurrentFace].TVertexNum[1] := LB;
    FMesh.Faces[FCurrentFace].TVertexNum[2] := LC;
    Inc(FCurrentFace);
  end
  else
    Fail(Format(SStaticAseUnknownToken, [string(AToken), 'MESH_TFACE']));
end;

procedure TAseParser.KeyCFaceList(const AToken: AnsiString);
const
  REMAP: array[0..2] of Integer = (0, 2, 1);
var
  LIndex, LVertex: Integer;
begin
  if AToken = '*MESH_CFACE' then
  begin
    if FCurrentFace >= Length(FMesh.Faces) then
      Fail(Format(SStaticAseOutOfRange, ['ase.currentFace', FCurrentFace, Length(FMesh.Faces)]));
    GetToken(False);
    for LIndex := 0 to 2 do
    begin
      LVertex := NextInt;
      if (LVertex < 0) or (LVertex >= Length(FMesh.CVertexes)) then
        Fail(Format(SStaticAseOutOfRange, ['MESH_CFACE colour vertex', LVertex, Length(FMesh.CVertexes)]));
      // we flip the vertex order to change the face direction to our style
      FMesh.Faces[FCurrentFace].VertexColors[REMAP[LIndex]].R := Byte(Trunc(FMesh.CVertexes[LVertex].X * 255) and $FF);
      FMesh.Faces[FCurrentFace].VertexColors[REMAP[LIndex]].G := Byte(Trunc(FMesh.CVertexes[LVertex].Y * 255) and $FF);
      FMesh.Faces[FCurrentFace].VertexColors[REMAP[LIndex]].B := Byte(Trunc(FMesh.CVertexes[LVertex].Z * 255) and $FF);
    end;
    Inc(FCurrentFace);
  end
  else
    Fail(Format(SStaticAseUnknownToken, [string(AToken), 'MESH_CFACE']));
end;

procedure TAseParser.KeyMeshTVertList(const AToken: AnsiString);
var
  LU, LV: AnsiString;
begin
  if AToken = '*MESH_TVERT' then
  begin
    GetToken(False);
    GetToken(False);
    LU := FToken;
    GetToken(False);
    LV := FToken;
    GetToken(False);    // w
    if FCurrentVertex >= Length(FMesh.TVertexes) then
      Fail(Format(SStaticAseOutOfRange, ['ase.currentVertex', FCurrentVertex, Length(FMesh.TVertexes)]));
    FMesh.TVertexes[FCurrentVertex].X := TStaticNumbers.Atof(LU);
    // our OpenGL second texture axis is inverted from MAX's sense
    FMesh.TVertexes[FCurrentVertex].Y := 1.0 - TStaticNumbers.Atof(LV);
    Inc(FCurrentVertex);
  end
  else
    Fail(Format(SStaticAseUnknownToken, [string(AToken), 'MESH_TVERTLIST']));
end;

procedure TAseParser.KeyMeshCVertList(const AToken: AnsiString);
begin
  FMesh.ColorsParsed := True;
  if AToken = '*MESH_VERTCOL' then
  begin
    GetToken(False);
    GetToken(False);
    GetToken(False);
    GetToken(False);
    if FCurrentVertex >= Length(FMesh.CVertexes) then
      Fail(Format(SStaticAseOutOfRange, ['ase.currentVertex', FCurrentVertex, Length(FMesh.CVertexes)]));
    // the original converts the name of the key (atof( token ) instead of ase.token): zero
    FMesh.CVertexes[FCurrentVertex].X := TStaticNumbers.Atof(AToken);
    FMesh.CVertexes[FCurrentVertex].Y := TStaticNumbers.Atof(AToken);
    FMesh.CVertexes[FCurrentVertex].Z := TStaticNumbers.Atof(AToken);
    Inc(FCurrentVertex);
  end
  else
    Fail(Format(SStaticAseUnknownToken, [string(AToken), 'MESH_CVERTLIST']));
end;

procedure TAseParser.KeyMeshNormals(const AToken: AnsiString);
var
  LNum, LVertex: Integer;
  LX, LY, LZ: Single;
  LResult: TIdVec3;
begin
  FMesh.NormalsParsed := True;
  if AToken = '*MESH_FACENORMAL' then
  begin
    LNum := NextInt;
    if (LNum >= FMesh.NumFaces) or (LNum < 0) then
      Fail(Format(SStaticAseOutOfRange, ['MESH_NORMALS face index', LNum, FMesh.NumFaces]));
    if LNum <> FCurrentFace then
      Fail(SStaticAseNormalFace);
    NeedFaces('*MESH_NORMALS');
    LX := NextFloat;
    LY := NextFloat;
    LZ := NextFloat;
    LResult.X := LX * FMesh.Transform[0].X + LY * FMesh.Transform[1].X + LZ * FMesh.Transform[2].X;
    LResult.Y := LX * FMesh.Transform[0].Y + LY * FMesh.Transform[1].Y + LZ * FMesh.Transform[2].Y;
    LResult.Z := LX * FMesh.Transform[0].Z + LY * FMesh.Transform[1].Z + LZ * FMesh.Transform[2].Z;
    LResult.Normalize;
    FMesh.Faces[FCurrentFace].FaceNormal := LResult;
    Inc(FCurrentFace);
  end
  else if AToken = '*MESH_VERTEXNORMAL' then
  begin
    LNum := NextInt;
    if (LNum >= FMesh.NumVertexes) or (LNum < 0) then
      Fail(Format(SStaticAseOutOfRange, ['MESH_NORMALS vertex index', LNum, FMesh.NumVertexes]));
    if (FCurrentFace < 1) or (FCurrentFace > Length(FMesh.Faces)) then
      Fail(SStaticAseNormalVertex);
    LVertex := 0;
    while (LVertex < 3) and (LNum <> FMesh.Faces[FCurrentFace - 1].VertexNum[LVertex]) do
      Inc(LVertex);
    if LVertex = 3 then
      Fail(SStaticAseNormalVertex);
    LX := NextFloat;
    LY := NextFloat;
    LZ := NextFloat;
    LResult.X := LX * FMesh.Transform[0].X + LY * FMesh.Transform[1].X + LZ * FMesh.Transform[2].X;
    LResult.Y := LX * FMesh.Transform[0].Y + LY * FMesh.Transform[1].Y + LZ * FMesh.Transform[2].Y;
    LResult.Z := LX * FMesh.Transform[0].Z + LY * FMesh.Transform[1].Z + LZ * FMesh.Transform[2].Z;
    LResult.Normalize;
    FMesh.Faces[FCurrentFace - 1].VertexNormals[LVertex] := LResult;
  end;
end;

procedure TAseParser.KeyMesh(const AToken: AnsiString);
begin
  if AToken = '*TIMEVALUE' then
    FMesh.TimeValue := NextInt
  else if AToken = '*MESH_NUMVERTEX' then
    FMesh.NumVertexes := NextInt
  else if AToken = '*MESH_NUMTVERTEX' then
    FMesh.NumTVertexes := NextInt
  else if AToken = '*MESH_NUMCVERTEX' then
    FMesh.NumCVertexes := NextInt
  else if AToken = '*MESH_NUMFACES' then
    FMesh.NumFaces := NextInt
  else if AToken = '*MESH_NUMTVFACES' then
  begin
    FMesh.NumTVFaces := NextInt;
    if FMesh.NumTVFaces <> FMesh.NumFaces then
      Fail(SStaticAseCountMismatch);
  end
  else if AToken = '*MESH_NUMCVFACES' then
  begin
    FMesh.NumCVFaces := NextInt;
    // the original compares the texture faces here (a copy and paste): kept
    if FMesh.NumTVFaces <> FMesh.NumFaces then
      Fail(SStaticAseCountMismatch);
  end
  else if AToken = '*MESH_VERTEX_LIST' then
  begin
    if FMesh.NumVertexes < 0 then
      Fail(Format(SStaticAseOutOfRange, ['MESH_NUMVERTEX', FMesh.NumVertexes, 0]));
    SetLength(FMesh.Vertexes, FMesh.NumVertexes);
    FCurrentVertex := 0;
    ParseBracedBlock(KeyMeshVertexList);
  end
  else if AToken = '*MESH_TVERTLIST' then
  begin
    if FMesh.NumTVertexes < 0 then
      Fail(Format(SStaticAseOutOfRange, ['MESH_NUMTVERTEX', FMesh.NumTVertexes, 0]));
    FCurrentVertex := 0;
    SetLength(FMesh.TVertexes, FMesh.NumTVertexes);
    ParseBracedBlock(KeyMeshTVertList);
  end
  else if AToken = '*MESH_CVERTLIST' then
  begin
    if FMesh.NumCVertexes < 0 then
      Fail(Format(SStaticAseOutOfRange, ['MESH_NUMCVERTEX', FMesh.NumCVertexes, 0]));
    FCurrentVertex := 0;
    SetLength(FMesh.CVertexes, FMesh.NumCVertexes);
    ParseBracedBlock(KeyMeshCVertList);
  end
  else if AToken = '*MESH_FACE_LIST' then
  begin
    if FMesh.NumFaces < 0 then
      Fail(Format(SStaticAseOutOfRange, ['MESH_NUMFACES', FMesh.NumFaces, 0]));
    SetLength(FMesh.Faces, FMesh.NumFaces);
    FCurrentFace := 0;
    ParseBracedBlock(KeyMeshFaceList);
  end
  else if AToken = '*MESH_TFACELIST' then
  begin
    NeedFaces('*MESH_TFACELIST');
    FCurrentFace := 0;
    ParseBracedBlock(KeyTFaceList);
  end
  else if AToken = '*MESH_CFACELIST' then
  begin
    NeedFaces('*MESH_CFACELIST');
    FCurrentFace := 0;
    ParseBracedBlock(KeyCFaceList);
  end
  else if AToken = '*MESH_NORMALS' then
  begin
    FCurrentFace := 0;
    ParseBracedBlock(KeyMeshNormals);
  end;
end;

procedure TAseParser.KeyMeshAnimation(const AToken: AnsiString);
begin
  // loads a single animation frame
  if AToken = '*MESH' then
  begin
    FMesh := Default(TAseMesh);
    ParseBracedBlock(KeyMesh);
    SetLength(FObject.Frames, Length(FObject.Frames) + 1);
    FObject.Frames[High(FObject.Frames)] := FMesh;
  end
  else
    Fail(Format(SStaticAseUnknownToken, [string(AToken), 'MESH_ANIMATION']));
end;

procedure TAseParser.KeyGeomObject(const AToken: AnsiString);
begin
  if AToken = '*NODE_NAME' then
  begin
    GetToken(True);
    FObject.Name := Copy(FToken, 1, MAX_NAME);
  end
  else if AToken = '*NODE_PARENT' then
    SkipRestOfLine
  // ignore unused data blocks
  else if (AToken = '*NODE_TM') or (AToken = '*TM_ANIMATION') then
    ParseBracedBlock(KeyNodeTm)
  // the regular mesh that is not part of the animation
  else if AToken = '*MESH' then
  begin
    FMesh := FObject.Mesh;
    // the original clears sizeof( pointer ) bytes of the mesh: only the time value
    FMesh.TimeValue := 0;
    ParseBracedBlock(KeyMesh);
    FObject.Mesh := FMesh;
  end
  // according to spec this is obsolete
  else if AToken = '*MATERIAL_REF' then
    FObject.MaterialRef := NextInt
  // loads a sequence of animation frames
  else if AToken = '*MESH_ANIMATION' then
    ParseBracedBlock(KeyMeshAnimation)
  // skip unused info
  else if (AToken = '*PROP_MOTIONBLUR') or (AToken = '*PROP_CASTSHADOW') or (AToken = '*PROP_RECVSHADOW') then
    SkipRestOfLine;
end;

procedure TAseParser.ParseGeomObject;
begin
  FObject := Default(TAseObject);
  ParseBracedBlock(KeyGeomObject);
  SetLength(FModel.Objects, Length(FModel.Objects) + 1);
  FModel.Objects[High(FModel.Objects)] := FObject;
end;

procedure TAseParser.KeyGroup(const AToken: AnsiString);
begin
  if AToken = '*GEOMOBJECT' then
    ParseGeomObject;
end;

function TAseParser.Parse(const AText: AnsiString): TAseModel;
var
  LZero: Integer;
begin
  FBuffer := AText;
  LZero := Pos(AnsiString(#0), FBuffer);
  if LZero > 0 then
    SetLength(FBuffer, LZero - 1);
  FPosition := 1;
  FTokenPosition := 1;
  FModel := Default(TAseModel);
  while GetToken(False) do
  begin
    if (FToken = '*3DSMAX_ASCIIEXPORT') or (FToken = '*COMMENT') then
      SkipRestOfLine
    else if FToken = '*SCENE' then
      SkipEnclosingBraces
    else if FToken = '*GROUP' then
    begin
      GetToken(False);    // group name
      ParseBracedBlock(KeyGroup);
    end
    else if (FToken = '*SHAPEOBJECT') or (FToken = '*CAMERAOBJECT') then
      SkipEnclosingBraces
    else if FToken = '*MATERIAL_LIST' then
      ParseBracedBlock(KeyMaterialList)
    else if FToken = '*GEOMOBJECT' then
      ParseGeomObject;
    // any other token is printed and ignored by the original
  end;
  Result := FModel;
end;

end.
