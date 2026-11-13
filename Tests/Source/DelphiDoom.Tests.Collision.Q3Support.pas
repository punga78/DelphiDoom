{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the collision library - the Quake III collision model: }
{  small BSPs built in memory and helpers                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Q3Support;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Collision.Q3.Intf;

type
  /// <summary>
  ///   Builds a small BSP file in memory: lists of the records of the lumps that the test fills
  ///   (directly or with AddBox) and the bytes of the file. Shader 0 is solid, 1 is water, 2 is
  ///   player clip; the sides of a shader carry its surface flags (shader 2: $20).
  /// </summary>
  TQ3BspWriter = class
  public
    Shaders: TArray<TBspShader>;
    Planes: TArray<TBspPlane>;
    Nodes: TArray<TBspNode>;
    Leafs: TArray<TBspLeaf>;
    LeafBrushes: TArray<Integer>;
    LeafSurfaces: TArray<Integer>;
    Models: TArray<TBspModel>;
    Brushes: TArray<TBspBrush>;
    BrushSides: TArray<TBspBrushSide>;
    DrawVerts: TArray<TBspDrawVert>;
    Surfaces: TArray<TBspSurface>;
    Visibility: TBytes;
    Entities: AnsiString;
    constructor Create;
    function AddPlane(const AX, AY, AZ, ADist: Single): Integer;
    /// <summary>The six sides of an axial box in the order the engine wants (-x +x -y +y -z +z)</summary>
    function AddBox(const AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single; const AShader: Integer): Integer;
    function AddNode(const APlane, AFront, ABack: Integer): Integer;
    function AddLeaf(const ACluster, AArea: Integer; const ABrushes: array of Integer;
      const ASurfaces: array of Integer): Integer;
    procedure AddModel(const AFirstBrush, ANumBrushes, AFirstSurface, ANumSurfaces: Integer);
    /// <summary>A surface that is a patch of AWidth x AHeight points taken from the draw verts that were added</summary>
    procedure AddPatch(const AWidth, AHeight, AShader: Integer; const AX, AY, AZ: Single);
    function Build: TBytes;
  end;

function Vec(const AX, AY, AZ: Single): TQ3Vec3;

/// <summary>The bits of a float, as 8 hex digits</summary>
function FloatBitsHex(const AValue: Single): string;

function BitsOfFloat(const AValue: Single): Cardinal;

function FloatOfBits(const ABits: Cardinal): Single;

/// <summary>
///   A world with a floor (brush 0, z from -64 to 0) and a pillar (brush 1, x 100..132); three
///   leaves (floor, pillar, empty with cluster 1 and area 1); the caller builds or changes it
/// </summary>
function NewRoomWriter: TQ3BspWriter;

/// <summary>The bytes of NewRoomWriter</summary>
function BuildRoomBsp: TBytes;

implementation

function Vec(const AX, AY, AZ: Single): TQ3Vec3;
begin
  Result[0] := AX;
  Result[1] := AY;
  Result[2] := AZ;
end;

function BitsOfFloat(const AValue: Single): Cardinal;
begin
  Move(AValue, Result, 4);
end;

function FloatOfBits(const ABits: Cardinal): Single;
begin
  Move(ABits, Result, 4);
end;

function FloatBitsHex(const AValue: Single): string;
begin
  Result := IntToHex(BitsOfFloat(AValue), 8).ToLower;
end;

{ TQ3BspWriter }

constructor TQ3BspWriter.Create;
var
  LIndex: Integer;
  LShader: TBspShader;
begin
  inherited Create;
  for LIndex := 0 to 2 do
  begin
    FillChar(LShader, SizeOf(LShader), 0);
    case LIndex of
      0:
        LShader.ContentFlags := Q3_CONTENTS_SOLID;
      1:
        LShader.ContentFlags := 32;
      2:
        begin
          LShader.ContentFlags := $10000;
          LShader.SurfaceFlags := $20;
        end;
    end;
    SetLength(Shaders, Length(Shaders) + 1);
    Shaders[High(Shaders)] := LShader;
  end;
  Entities := '{'#10'"classname" "worldspawn"'#10'}'#10;
end;

function TQ3BspWriter.AddPlane(const AX, AY, AZ, ADist: Single): Integer;
begin
  Result := Length(Planes);
  SetLength(Planes, Result + 1);
  Planes[Result].Normal[0] := AX;
  Planes[Result].Normal[1] := AY;
  Planes[Result].Normal[2] := AZ;
  Planes[Result].Dist := ADist;
end;

function TQ3BspWriter.AddBox(const AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single;
  const AShader: Integer): Integer;
var
  LPlanes: array[0..5] of Integer;
  LIndex: Integer;
begin
  LPlanes[0] := AddPlane(-1, 0, 0, -AMinX);
  LPlanes[1] := AddPlane(1, 0, 0, AMaxX);
  LPlanes[2] := AddPlane(0, -1, 0, -AMinY);
  LPlanes[3] := AddPlane(0, 1, 0, AMaxY);
  LPlanes[4] := AddPlane(0, 0, -1, -AMinZ);
  LPlanes[5] := AddPlane(0, 0, 1, AMaxZ);
  Result := Length(Brushes);
  SetLength(Brushes, Result + 1);
  Brushes[Result].FirstSide := Length(BrushSides);
  Brushes[Result].NumSides := 6;
  Brushes[Result].ShaderNum := AShader;
  for LIndex := 0 to 5 do
  begin
    SetLength(BrushSides, Length(BrushSides) + 1);
    BrushSides[High(BrushSides)].PlaneNum := LPlanes[LIndex];
    BrushSides[High(BrushSides)].ShaderNum := AShader;
  end;
end;

function TQ3BspWriter.AddNode(const APlane, AFront, ABack: Integer): Integer;
begin
  Result := Length(Nodes);
  SetLength(Nodes, Result + 1);
  Nodes[Result].PlaneNum := APlane;
  Nodes[Result].Children[0] := AFront;
  Nodes[Result].Children[1] := ABack;
end;

function TQ3BspWriter.AddLeaf(const ACluster, AArea: Integer; const ABrushes, ASurfaces: array of Integer): Integer;
var
  LIndex: Integer;
begin
  Result := Length(Leafs);
  SetLength(Leafs, Result + 1);
  Leafs[Result].Cluster := ACluster;
  Leafs[Result].Area := AArea;
  Leafs[Result].FirstLeafBrush := Length(LeafBrushes);
  Leafs[Result].NumLeafBrushes := Length(ABrushes);
  for LIndex := 0 to High(ABrushes) do
  begin
    SetLength(LeafBrushes, Length(LeafBrushes) + 1);
    LeafBrushes[High(LeafBrushes)] := ABrushes[LIndex];
  end;
  Leafs[Result].FirstLeafSurface := Length(LeafSurfaces);
  Leafs[Result].NumLeafSurfaces := Length(ASurfaces);
  for LIndex := 0 to High(ASurfaces) do
  begin
    SetLength(LeafSurfaces, Length(LeafSurfaces) + 1);
    LeafSurfaces[High(LeafSurfaces)] := ASurfaces[LIndex];
  end;
end;

procedure TQ3BspWriter.AddModel(const AFirstBrush, ANumBrushes, AFirstSurface, ANumSurfaces: Integer);
var
  LIndex: Integer;
begin
  SetLength(Models, Length(Models) + 1);
  for LIndex := 0 to 2 do
  begin
    Models[High(Models)].Mins[LIndex] := -100;
    Models[High(Models)].Maxs[LIndex] := 100;
  end;
  Models[High(Models)].FirstBrush := AFirstBrush;
  Models[High(Models)].NumBrushes := ANumBrushes;
  Models[High(Models)].FirstSurface := AFirstSurface;
  Models[High(Models)].NumSurfaces := ANumSurfaces;
end;

procedure TQ3BspWriter.AddPatch(const AWidth, AHeight, AShader: Integer; const AX, AY, AZ: Single);
var
  LFirst, LIndex, LColumn: Integer;
begin
  LFirst := Length(DrawVerts);
  for LIndex := 0 to AHeight - 1 do
    for LColumn := 0 to AWidth - 1 do
    begin
      SetLength(DrawVerts, Length(DrawVerts) + 1);
      FillChar(DrawVerts[High(DrawVerts)], SizeOf(TBspDrawVert), 0);
      DrawVerts[High(DrawVerts)].Xyz[0] := AX + LColumn * 16;
      DrawVerts[High(DrawVerts)].Xyz[1] := AY + LIndex * 16;
      DrawVerts[High(DrawVerts)].Xyz[2] := AZ;
    end;
  SetLength(Surfaces, Length(Surfaces) + 1);
  FillChar(Surfaces[High(Surfaces)], SizeOf(TBspSurface), 0);
  Surfaces[High(Surfaces)].ShaderNum := AShader;
  Surfaces[High(Surfaces)].FogNum := -1;
  Surfaces[High(Surfaces)].SurfaceType := MST_PATCH;
  Surfaces[High(Surfaces)].FirstVert := LFirst;
  Surfaces[High(Surfaces)].NumVerts := AWidth * AHeight;
  Surfaces[High(Surfaces)].LightmapNum := -1;
  Surfaces[High(Surfaces)].PatchWidth := AWidth;
  Surfaces[High(Surfaces)].PatchHeight := AHeight;
end;

function TQ3BspWriter.Build: TBytes;
var
  LLumps: array[0..HEADER_LUMPS - 1] of TBytes;
  LHeader: TBspHeader;
  LIndex, LOffset: Integer;
  LStream: TBytesStream;
  LZero: Byte;

  function ToBytes(const ASource; const ASize: Integer): TBytes;
  begin
    SetLength(Result, ASize);
    if ASize > 0 then
      Move(ASource, Result[0], ASize);
  end;

begin
  LZero := 0;
  if Length(Models) = 0 then
    AddModel(0, Length(Brushes), 0, 0);
  SetLength(LLumps[LUMP_ENTITIES], Length(Entities) + 1);
  if Length(Entities) > 0 then
    Move(Entities[1], LLumps[LUMP_ENTITIES][0], Length(Entities));
  LLumps[LUMP_SHADERS] := ToBytes(Shaders[0], Length(Shaders) * SizeOf(TBspShader));
  LLumps[LUMP_PLANES] := ToBytes(Planes[0], Length(Planes) * SizeOf(TBspPlane));
  LLumps[LUMP_NODES] := ToBytes(Nodes[0], Length(Nodes) * SizeOf(TBspNode));
  LLumps[LUMP_LEAFS] := ToBytes(Leafs[0], Length(Leafs) * SizeOf(TBspLeaf));
  if Length(LeafSurfaces) > 0 then
    LLumps[LUMP_LEAFSURFACES] := ToBytes(LeafSurfaces[0], Length(LeafSurfaces) * 4);
  if Length(LeafBrushes) > 0 then
    LLumps[LUMP_LEAFBRUSHES] := ToBytes(LeafBrushes[0], Length(LeafBrushes) * 4);
  LLumps[LUMP_MODELS] := ToBytes(Models[0], Length(Models) * SizeOf(TBspModel));
  if Length(Brushes) > 0 then
    LLumps[LUMP_BRUSHES] := ToBytes(Brushes[0], Length(Brushes) * SizeOf(TBspBrush));
  if Length(BrushSides) > 0 then
    LLumps[LUMP_BRUSHSIDES] := ToBytes(BrushSides[0], Length(BrushSides) * SizeOf(TBspBrushSide));
  if Length(DrawVerts) > 0 then
    LLumps[LUMP_DRAWVERTS] := ToBytes(DrawVerts[0], Length(DrawVerts) * SizeOf(TBspDrawVert));
  if Length(Surfaces) > 0 then
    LLumps[LUMP_SURFACES] := ToBytes(Surfaces[0], Length(Surfaces) * SizeOf(TBspSurface));
  LLumps[LUMP_VISIBILITY] := Visibility;

  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Ident := BSP_IDENT;
  LHeader.Version := BSP_VERSION;
  LOffset := SizeOf(TBspHeader);
  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    LHeader.Lumps[LIndex].FileOfs := LOffset;
    LHeader.Lumps[LIndex].FileLen := Length(LLumps[LIndex]);
    Inc(LOffset, (Length(LLumps[LIndex]) + 3) and not 3);
  end;
  LStream := TBytesStream.Create;
  try
    LStream.WriteBuffer(LHeader, SizeOf(LHeader));
    for LIndex := 0 to HEADER_LUMPS - 1 do
    begin
      if Length(LLumps[LIndex]) > 0 then
        LStream.WriteBuffer(LLumps[LIndex][0], Length(LLumps[LIndex]));
      LOffset := ((Length(LLumps[LIndex]) + 3) and not 3) - Length(LLumps[LIndex]);
      while LOffset > 0 do
      begin
        LStream.WriteBuffer(LZero, 1);
        Dec(LOffset);
      end;
    end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

function NewRoomWriter: TQ3BspWriter;
var
  LFloor, LPillar, LSplitZ, LSplitX: Integer;
begin
  Result := TQ3BspWriter.Create;
  try
    // brush 0: the floor, z from -64 to 0; brush 1: a pillar at x 100..132
    LFloor := Result.AddBox(-1000, -1000, -64, 1000, 1000, 0, 0);
    LPillar := Result.AddBox(100, -16, 0, 132, 16, 128, 0);
    // tree: z = 0 splits floor (below) from the rest; the rest is split at x = 100
    LSplitZ := Result.AddPlane(0, 0, 1, 0);
    LSplitX := Result.AddPlane(1, 0, 0, 100);
    Result.AddNode(LSplitZ, 1, -1);
    // node 1: x >= 100 -> leaf with the pillar (-2), otherwise empty leaf (-3)
    Result.AddNode(LSplitX, -2, -3);
    Result.AddLeaf(-1, 0, [LFloor], []);
    Result.AddLeaf(0, 0, [LPillar], []);
    Result.AddLeaf(1, 1, [], []);
  except
    Result.Free;
    raise;
  end;
end;

function BuildRoomBsp: TBytes;
var
  LWriter: TQ3BspWriter;
begin
  LWriter := NewRoomWriter;
  try
    Result := LWriter.Build;
  finally
    LWriter.Free;
  end;
end;

end.
