{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - builders of static model files }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.StaticBuilders;

interface

uses
  System.SysUtils,
  System.Classes;

type
  /// <summary>One triangle of the test models: three point indexes</summary>
  TCubeTriangle = array[0..2] of Integer;

  /// <summary>
  ///   Builds the LWO2 files of the tests (nothing of Doom 3 is in the repository): an IFF
  ///   FORM with TAGS, LAYR, PNTS, VMAP, POLS, PTAG and SURF chunks, written by hand from the
  ///   description of the format.
  /// </summary>
  TLwoFileBuilder = class
  strict private
    FChunks: TBytesStream;
    FTagNames: TArray<AnsiString>;
  public
    constructor Create;
    destructor Destroy; override;
    class function F4(const AValue: Single): TBytes; static;
    class function U2(const AValue: Word): TBytes; static;
    class function U4(const AValue: Cardinal): TBytes; static;
    class function S0(const AText: AnsiString): TBytes; static;
    class function VX(const AValue: Integer): TBytes; static;
    class function Join(const AParts: array of TBytes): TBytes; static;
    /// <summary>A chunk: the four letters, the size and the data, padded to an even size</summary>
    class function Chunk(const AId: AnsiString; const AData: TBytes): TBytes; static;
    procedure AddRaw(const AData: TBytes);
    procedure AddTags(const ANames: array of AnsiString);
    procedure AddLayer(const AIndex: Integer; const AName: AnsiString);
    /// <summary>PNTS: x, y, z of every point</summary>
    procedure AddPoints(const ACoordinates: array of Single);
    /// <summary>POLS FACE: every polygon is the list of its point indexes</summary>
    procedure AddFaces(const AFaces: array of TCubeTriangle);
    /// <summary>VMAP TXUV by point: u, v of every point</summary>
    procedure AddTexCoords(const AName: AnsiString; const AValues: array of Single);
    /// <summary>VMAP RGBA by point: r, g, b, a of every point</summary>
    procedure AddColors(const AName: AnsiString; const AValues: array of Single);
    /// <summary>PTAG SURF: the tag of every polygon</summary>
    procedure AddSurfaceTags(const ATags: array of Integer);
    /// <summary>PTAG SMGP: the smoothing group of every polygon</summary>
    procedure AddSmoothingGroups(const AGroups: array of Integer);
    /// <summary>SURF with the colour and, if positive, the maximum smoothing angle (SMAN)</summary>
    procedure AddSurface(const AName: AnsiString; const ARed, AGreen, ABlue, ASmooth: Single);
    function Build: TBytes;
  end;

const
  /// <summary>The eight points of the cube in LightWave axes (Y up), x y z each</summary>
  CUBE_POINTS: array[0..23] of Single = (
    -1, -1, -1,   1, -1, -1,   1, 1, -1,   -1, 1, -1,
    -1, -1, 1,   1, -1, 1,   1, 1, 1,   -1, 1, 1);
  /// <summary>The twelve triangles of the cube</summary>
  CUBE_TRIANGLES: array[0..11] of TCubeTriangle = (
    (0, 3, 2), (0, 2, 1), (4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4),
    (3, 7, 6), (3, 6, 2), (0, 4, 7), (0, 7, 3), (1, 2, 6), (1, 6, 5));
  /// <summary>The texture coordinates of the points of the cube: (x + 1) / 2, (y + 1) / 2</summary>
  CUBE_TEXCOORDS: array[0..15] of Single = (
    0, 0,   1, 0,   1, 1,   0, 1,
    0, 0,   1, 0,   1, 1,   0, 1);

/// <summary>A triangle of three point indexes</summary>
function Tri(const A, B, C: Integer): TCubeTriangle;

/// <summary>A file of Tests\Data\Models\static (the folder is found from the executable)</summary>
function StaticDataFile(const AName: string): TBytes;

/// <summary>True if two byte arrays have the same content</summary>
function TArrayEquals(const ALeft, ARight: TBytes): Boolean;

/// <summary>The cube as a LWO2 file: one surface, texture coordinates, flat or smoothed normals</summary>
function BuildCubeLwo(const ASmooth: Single; const AWithColors: Boolean = False): TBytes;

/// <summary>
///   Five points and three triangles with two pairs of points that are within the welding
///   tolerances (the point 3 is near the point 1, the uv too)
/// </summary>
function BuildWeldLwo: TBytes;

/// <summary>Four triangles on three surfaces, two of which have the same name without case</summary>
function BuildMergeLwo: TBytes;

/// <summary>The cube smoothed at 1.6 radians with smoothing groups that alternate by polygon</summary>
function BuildGroupsLwo: TBytes;

/// <summary>Two copies of the cube object with the same material (merged by default)</summary>
function BuildTwoObjectsAse: AnsiString;

/// <summary>A triangle with vertex colours (CVERTLIST and CFACELIST)</summary>
function BuildColorsAse: AnsiString;

/// <summary>The cube as an ASE text: a material with a texture matrix, texture vertexes, normals</summary>
function BuildCubeAse(const AWithNormals: Boolean; const AWithMaterial: Boolean = True): AnsiString;

implementation

uses
  System.IOUtils;

function Tri(const A, B, C: Integer): TCubeTriangle;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
end;

function StaticDataFile(const AName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Models\static\' + AName)));
end;

function TArrayEquals(const ALeft, ARight: TBytes): Boolean;
begin
  Result := (Length(ALeft) = Length(ARight)) and
    ((Length(ALeft) = 0) or CompareMem(@ALeft[0], @ARight[0], Length(ALeft)));
end;

{ TLwoFileBuilder }

constructor TLwoFileBuilder.Create;
begin
  inherited Create;
  FChunks := TBytesStream.Create;
end;

destructor TLwoFileBuilder.Destroy;
begin
  FChunks.Free;
  inherited Destroy;
end;

class function TLwoFileBuilder.F4(const AValue: Single): TBytes;
var
  LBits: Cardinal;
begin
  LBits := PCardinal(@AValue)^;
  Result := U4(LBits);
end;

class function TLwoFileBuilder.U2(const AValue: Word): TBytes;
begin
  SetLength(Result, 2);
  Result[0] := AValue shr 8;
  Result[1] := AValue and $FF;
end;

class function TLwoFileBuilder.U4(const AValue: Cardinal): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := AValue shr 24;
  Result[1] := (AValue shr 16) and $FF;
  Result[2] := (AValue shr 8) and $FF;
  Result[3] := AValue and $FF;
end;

class function TLwoFileBuilder.S0(const AText: AnsiString): TBytes;
var
  LLength: Integer;
begin
  LLength := Length(AText) + 1;
  LLength := LLength + (LLength and 1);
  SetLength(Result, LLength);
  FillChar(Result[0], LLength, 0);
  if Length(AText) > 0 then
    Move(AText[1], Result[0], Length(AText));
end;

class function TLwoFileBuilder.VX(const AValue: Integer): TBytes;
begin
  if AValue < $FF00 then
    Result := U2(AValue)
  else
    Result := Join([TBytes.Create($FF), TBytes.Create((AValue shr 16) and $FF, (AValue shr 8) and $FF, AValue and $FF)]);
end;

class function TLwoFileBuilder.Join(const AParts: array of TBytes): TBytes;
var
  LStream: TBytesStream;
  LIndex: Integer;
begin
  LStream := TBytesStream.Create;
  try
    for LIndex := 0 to High(AParts) do
      if Length(AParts[LIndex]) > 0 then
        LStream.WriteBuffer(AParts[LIndex][0], Length(AParts[LIndex]));
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TLwoFileBuilder.Chunk(const AId: AnsiString; const AData: TBytes): TBytes;
var
  LData: TBytes;
begin
  LData := AData;
  if Odd(Length(LData)) then
  begin
    SetLength(LData, Length(LData) + 1);
    LData[High(LData)] := 0;
  end;
  Result := Join([TBytes(BytesOf(AId)), U4(Length(AData)), LData]);
end;

procedure TLwoFileBuilder.AddRaw(const AData: TBytes);
begin
  if Length(AData) > 0 then
    FChunks.WriteBuffer(AData[0], Length(AData));
end;

procedure TLwoFileBuilder.AddTags(const ANames: array of AnsiString);
var
  LIndex: Integer;
  LData: TBytes;
begin
  SetLength(FTagNames, Length(ANames));
  for LIndex := 0 to High(ANames) do
  begin
    FTagNames[LIndex] := ANames[LIndex];
    LData := Join([LData, S0(ANames[LIndex])]);
  end;
  AddRaw(Chunk('TAGS', LData));
end;

procedure TLwoFileBuilder.AddLayer(const AIndex: Integer; const AName: AnsiString);
begin
  AddRaw(Chunk('LAYR', Join([U2(AIndex), U2(0), F4(0), F4(0), F4(0), S0(AName)])));
end;

procedure TLwoFileBuilder.AddPoints(const ACoordinates: array of Single);
var
  LIndex: Integer;
  LData: TBytes;
begin
  for LIndex := 0 to High(ACoordinates) do
    LData := Join([LData, F4(ACoordinates[LIndex])]);
  AddRaw(Chunk('PNTS', LData));
end;

procedure TLwoFileBuilder.AddFaces(const AFaces: array of TCubeTriangle);
var
  LIndex, LVert: Integer;
  LData: TBytes;
begin
  LData := TBytes(BytesOf(AnsiString('FACE')));
  for LIndex := 0 to High(AFaces) do
  begin
    LData := Join([LData, U2(3)]);
    for LVert := 0 to 2 do
      LData := Join([LData, VX(AFaces[LIndex][LVert])]);
  end;
  AddRaw(Chunk('POLS', LData));
end;

procedure TLwoFileBuilder.AddTexCoords(const AName: AnsiString; const AValues: array of Single);
var
  LIndex: Integer;
  LData: TBytes;
begin
  LData := Join([TBytes(BytesOf(AnsiString('TXUV'))), U2(2), S0(AName)]);
  for LIndex := 0 to (Length(AValues) div 2) - 1 do
    LData := Join([LData, VX(LIndex), F4(AValues[LIndex * 2]), F4(AValues[LIndex * 2 + 1])]);
  AddRaw(Chunk('VMAP', LData));
end;

procedure TLwoFileBuilder.AddColors(const AName: AnsiString; const AValues: array of Single);
var
  LIndex, LChannel: Integer;
  LData: TBytes;
begin
  LData := Join([TBytes(BytesOf(AnsiString('RGBA'))), U2(4), S0(AName)]);
  for LIndex := 0 to (Length(AValues) div 4) - 1 do
  begin
    LData := Join([LData, VX(LIndex)]);
    for LChannel := 0 to 3 do
      LData := Join([LData, F4(AValues[LIndex * 4 + LChannel])]);
  end;
  AddRaw(Chunk('VMAP', LData));
end;

procedure TLwoFileBuilder.AddSurfaceTags(const ATags: array of Integer);
var
  LIndex: Integer;
  LData: TBytes;
begin
  LData := TBytes(BytesOf(AnsiString('SURF')));
  for LIndex := 0 to High(ATags) do
    LData := Join([LData, VX(LIndex), VX(ATags[LIndex])]);
  AddRaw(Chunk('PTAG', LData));
end;

procedure TLwoFileBuilder.AddSmoothingGroups(const AGroups: array of Integer);
var
  LIndex: Integer;
  LData: TBytes;
begin
  LData := TBytes(BytesOf(AnsiString('SMGP')));
  for LIndex := 0 to High(AGroups) do
    LData := Join([LData, VX(LIndex), VX(AGroups[LIndex])]);
  AddRaw(Chunk('PTAG', LData));
end;

procedure TLwoFileBuilder.AddSurface(const AName: AnsiString; const ARed, AGreen, ABlue, ASmooth: Single);
var
  LData: TBytes;
begin
  LData := Join([S0(AName), S0(''),
    TBytes(BytesOf(AnsiString('COLR'))), U2(14), F4(ARed), F4(AGreen), F4(ABlue), VX(0),
    // a subchunk that the reader skips (DIFF, 1.0)
    TBytes(BytesOf(AnsiString('DIFF'))), U2(6), F4(1.0), VX(0)]);
  if ASmooth > 0 then
    LData := Join([LData, TBytes(BytesOf(AnsiString('SMAN'))), U2(4), F4(ASmooth)]);
  AddRaw(Chunk('SURF', LData));
end;

function TLwoFileBuilder.Build: TBytes;
var
  LBody: TBytes;
begin
  SetLength(LBody, FChunks.Size);
  if FChunks.Size > 0 then
    Move(FChunks.Bytes[0], LBody[0], FChunks.Size);
  Result := Join([TBytes(BytesOf(AnsiString('FORM'))), U4(4 + Length(LBody)),
    TBytes(BytesOf(AnsiString('LWO2'))), LBody]);
end;

function BuildCubeLwo(const ASmooth: Single; const AWithColors: Boolean): TBytes;
var
  LBuilder: TLwoFileBuilder;
  LTags: array[0..11] of Integer;
  LIndex: Integer;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['textures/test/cube']);
    LBuilder.AddLayer(0, 'cube');
    LBuilder.AddPoints(CUBE_POINTS);
    LBuilder.AddTexCoords('uv', CUBE_TEXCOORDS);
    if AWithColors then
      LBuilder.AddColors('rgba', [1, 0, 0, 1,  0, 1, 0, 1,  0, 0, 1, 1,  1, 1, 0, 1,
        0, 1, 1, 1,  1, 0, 1, 1,  0.5, 0.5, 0.5, 1,  1, 1, 1, 0.5]);
    LBuilder.AddFaces(CUBE_TRIANGLES);
    for LIndex := 0 to High(LTags) do
      LTags[LIndex] := 0;
    LBuilder.AddSurfaceTags(LTags);
    LBuilder.AddSurface('textures/test/cube', 0.5, 0.25, 1.0, ASmooth);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

function BuildWeldLwo: TBytes;
var
  LBuilder: TLwoFileBuilder;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['textures/weld']);
    LBuilder.AddLayer(0, 'weld');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0,  1.004, 0.003, 0,  1, 1, 0]);
    LBuilder.AddTexCoords('uv', [0, 0,  1, 0,  0, 1,  1.0005, 0.0004,  1, 1]);
    LBuilder.AddFaces([Tri(0, 1, 2), Tri(3, 4, 2), Tri(1, 3, 4)]);
    LBuilder.AddSurfaceTags([0, 0, 0]);
    LBuilder.AddSurface('textures/weld', 0.2, 0.4, 0.6, 0);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

function BuildMergeLwo: TBytes;
var
  LBuilder: TLwoFileBuilder;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['tex/a', 'TEX/A', 'tex/b']);
    LBuilder.AddLayer(0, 'merge');
    LBuilder.AddPoints([0, 0, 0,  1, 0, 0,  0, 1, 0,  1, 1, 0]);
    LBuilder.AddTexCoords('uv', [0, 0,  1, 0,  0, 1,  1, 1]);
    LBuilder.AddFaces([Tri(0, 1, 2), Tri(1, 3, 2), Tri(0, 2, 1), Tri(1, 2, 3)]);
    LBuilder.AddSurfaceTags([0, 1, 2, 0]);
    LBuilder.AddSurface('tex/a', 1, 0, 0, 0);
    LBuilder.AddSurface('TEX/A', 0, 1, 0, 0);
    LBuilder.AddSurface('tex/b', 0, 0, 1, 0);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

function BuildGroupsLwo: TBytes;
var
  LBuilder: TLwoFileBuilder;
  LTags, LGroups: array[0..11] of Integer;
  LIndex: Integer;
begin
  LBuilder := TLwoFileBuilder.Create;
  try
    LBuilder.AddTags(['textures/groups']);
    LBuilder.AddLayer(0, 'cube');
    LBuilder.AddPoints(CUBE_POINTS);
    LBuilder.AddTexCoords('uv', CUBE_TEXCOORDS);
    LBuilder.AddFaces(CUBE_TRIANGLES);
    for LIndex := 0 to 11 do
    begin
      LTags[LIndex] := 0;
      LGroups[LIndex] := LIndex mod 2;
    end;
    LBuilder.AddSurfaceTags(LTags);
    LBuilder.AddSmoothingGroups(LGroups);
    LBuilder.AddSurface('textures/groups', 1, 1, 1, 1.6);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

function BuildTwoObjectsAse: AnsiString;
var
  LText: AnsiString;
begin
  LText := BuildCubeAse(True);
  Result := LText + Copy(LText, Pos(AnsiString('*GEOMOBJECT'), LText), MaxInt);
end;

function BuildColorsAse: AnsiString;
begin
  Result := '*MATERIAL_LIST {'#10#9'*MATERIAL 0 {'#10#9#9'*MAP_DIFFUSE {'#10#9#9#9'*BITMAP "x.tga"'#10#9#9'}'#10#9'}'#10'}'#10 +
    '*GEOMOBJECT {'#10'*NODE_TM {'#10'*TM_ROW0 1 0 0'#10'*TM_ROW1 0 1 0'#10'*TM_ROW2 0 0 1'#10'*TM_ROW3 0 0 0'#10'}'#10 +
    '*MESH {'#10'*MESH_NUMVERTEX 3'#10'*MESH_NUMFACES 1'#10'*MESH_VERTEX_LIST {'#10'*MESH_VERTEX 0 0 0 0'#10 +
    '*MESH_VERTEX 1 1 0 0'#10'*MESH_VERTEX 2 0 1 0'#10'}'#10'*MESH_FACE_LIST {'#10 +
    '*MESH_FACE 0: A: 0 B: 1 C: 2 AB: 1 BC: 1 CA: 1'#10'}'#10'*MESH_NUMTVFACES 1'#10'*MESH_NUMTVERTEX 3'#10 +
    '*MESH_TVERTLIST {'#10'*MESH_TVERT 0 0 0 0'#10'*MESH_TVERT 1 1 0 0'#10'*MESH_TVERT 2 0 1 0'#10'}'#10 +
    '*MESH_TFACELIST {'#10'*MESH_TFACE 0 0 1 2'#10'}'#10'*MESH_NUMCVERTEX 3'#10'*MESH_CVERTLIST {'#10 +
    '*MESH_VERTCOL 0 1.0 0.0 0.0'#10'*MESH_VERTCOL 1 0.0 1.0 0.0'#10'*MESH_VERTCOL 2 0.0 0.0 1.0'#10'}'#10 +
    '*MESH_NUMCVFACES 1'#10'*MESH_CFACELIST {'#10'*MESH_CFACE 0 0 1 2'#10'}'#10'}'#10'*MATERIAL_REF 0'#10'}'#10;
end;

function BuildCubeAse(const AWithNormals: Boolean; const AWithMaterial: Boolean): AnsiString;
const
  VERTS: array[0..7] of string = (
    '-1.0000 -1.0000 -1.0000', '1.0000 -1.0000 -1.0000', '1.0000 1.0000 -1.0000', '-1.0000 1.0000 -1.0000',
    '-1.0000 -1.0000 1.0000', '1.0000 -1.0000 1.0000', '1.0000 1.0000 1.0000', '-1.0000 1.0000 1.0000');
  TVERTS: array[0..7] of string = (
    '0.0000 0.0000 0.0000', '1.0000 0.0000 0.0000', '1.0000 1.0000 0.0000', '0.0000 1.0000 0.0000',
    '0.0000 0.0000 0.0000', '1.0000 0.0000 0.0000', '1.0000 1.0000 0.0000', '0.0000 1.0000 0.0000');
var
  LText: TStringList;
  LFace, LCorner, LIndex: Integer;
  LTri: TCubeTriangle;
begin
  LText := TStringList.Create;
  try
    LText.Add('*3DSMAX_ASCIIEXPORT'#9'200');
    LText.Add('*COMMENT "test cube"');
    LText.Add('*SCENE {');
    LText.Add(#9'*SCENE_FILENAME "cube.max"');
    LText.Add('}');
    if AWithMaterial then
    begin
      LText.Add('*MATERIAL_LIST {');
      LText.Add(#9'*MATERIAL_COUNT 1');
      LText.Add(#9'*MATERIAL 0 {');
      LText.Add(#9#9'*MATERIAL_NAME "mat"');
      LText.Add(#9#9'*MAP_DIFFUSE {');
      LText.Add(#9#9#9'*MAP_NAME "map"');
      LText.Add(#9#9#9'*BITMAP "C:\work\base\textures\test\cube.tga"');
      LText.Add(#9#9#9'*UVW_U_OFFSET 0.25');
      LText.Add(#9#9#9'*UVW_V_OFFSET 0.5');
      LText.Add(#9#9#9'*UVW_U_TILING 2.0');
      LText.Add(#9#9#9'*UVW_V_TILING 0.5');
      LText.Add(#9#9#9'*UVW_ANGLE 0.5');
      LText.Add(#9#9'}');
      LText.Add(#9'}');
      LText.Add('}');
    end;
    LText.Add('*GEOMOBJECT {');
    LText.Add(#9'*NODE_NAME "Box01"');
    LText.Add(#9'*NODE_TM {');
    LText.Add(#9#9'*TM_ROW0 1.0000 0.0000 0.0000');
    LText.Add(#9#9'*TM_ROW1 0.0000 1.0000 0.0000');
    LText.Add(#9#9'*TM_ROW2 0.0000 0.0000 1.0000');
    LText.Add(#9#9'*TM_ROW3 0.0000 0.0000 0.0000');
    LText.Add(#9'}');
    LText.Add(#9'*MESH {');
    LText.Add(#9#9'*TIMEVALUE 0');
    LText.Add(#9#9'*MESH_NUMVERTEX 8');
    LText.Add(#9#9'*MESH_NUMFACES 12');
    LText.Add(#9#9'*MESH_VERTEX_LIST {');
    for LIndex := 0 to 7 do
      LText.Add(#9#9#9'*MESH_VERTEX ' + IntToStr(LIndex) + ' ' + VERTS[LIndex]);
    LText.Add(#9#9'}');
    LText.Add(#9#9'*MESH_FACE_LIST {');
    for LFace := 0 to 11 do
    begin
      LTri := CUBE_TRIANGLES[LFace];
      LText.Add(Format(#9#9#9'*MESH_FACE %d: A: %d B: %d C: %d AB: 1 BC: 1 CA: 1 *MESH_SMOOTHING 1 *MESH_MTLID 0',
        [LFace, LTri[0], LTri[1], LTri[2]]));
    end;
    LText.Add(#9#9'}');
    LText.Add(#9#9'*MESH_NUMTVERTEX 8');
    LText.Add(#9#9'*MESH_TVERTLIST {');
    for LIndex := 0 to 7 do
      LText.Add(#9#9#9'*MESH_TVERT ' + IntToStr(LIndex) + ' ' + TVERTS[LIndex]);
    LText.Add(#9#9'}');
    LText.Add(#9#9'*MESH_NUMTVFACES 12');
    LText.Add(#9#9'*MESH_TFACELIST {');
    for LFace := 0 to 11 do
    begin
      LTri := CUBE_TRIANGLES[LFace];
      LText.Add(Format(#9#9#9'*MESH_TFACE %d %d %d %d', [LFace, LTri[0], LTri[1], LTri[2]]));
    end;
    LText.Add(#9#9'}');
    if AWithNormals then
    begin
      LText.Add(#9#9'*MESH_NORMALS {');
      for LFace := 0 to 11 do
      begin
        LTri := CUBE_TRIANGLES[LFace];
        LText.Add(Format(#9#9#9'*MESH_FACENORMAL %d 0.0000 0.0000 1.0000', [LFace]));
        for LCorner := 0 to 2 do
          if Odd(LFace) then
            LText.Add(Format(#9#9#9#9'*MESH_VERTEXNORMAL %d 0.0000 1.0000 0.0000', [LTri[LCorner]]))
          else
            LText.Add(Format(#9#9#9#9'*MESH_VERTEXNORMAL %d 0.0000 0.0000 1.0000', [LTri[LCorner]]));
      end;
      LText.Add(#9#9'}');
    end;
    LText.Add(#9'}');
    LText.Add(#9'*PROP_MOTIONBLUR 0');
    LText.Add(#9'*PROP_CASTSHADOW 1');
    if AWithMaterial then
      LText.Add(#9'*MATERIAL_REF 0');
    LText.Add('}');
    Result := AnsiString(StringReplace(LText.Text, #13#10, #10, [rfReplaceAll]));
  finally
    LText.Free;
  end;
end;

end.
