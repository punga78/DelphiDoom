{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R1b) - the        }
{  surface functions against the real C                                         }
{                                                                              }
{  Tests\Data\Q3Render\surf.golden.txt and surf.map.golden.txt are the output   }
{  of the REAL tr_surface.c and tr_curve.c of Quake III (and of ParseMesh,      }
{  R_StitchAllPatches and R_FixSharedVertexLodError of tr_bsp.c for the map):   }
{  Tools\Verifica\254\build-surf.sh, gcc, 32 bit SSE. The commands are in       }
{  surf.cases.txt and surf.map.cases.txt (the same files the C reads); the      }
{  test runs them through TQ3SurfaceTessellator and compares the batches of     }
{  tess (counts, dlight bits and FNV-1a of the positions, normals, texture      }
{  coordinates, colours and indexes) and the vertexes of the beams. The map     }
{  part is ignored when OpenArena is not there                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Surfaces;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3Surfaces = class
  public
    [Test]
    procedure DovrebbeDareLeStesseGrigliePoligoniSpriteRaggiEMeshDelCDiQuake;
    [Test]
    [Category('OpenArena')]
    procedure DovrebbeDareLeStesseGrigliedelleMappeDelCDiQuake;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaCheLaSuperficieNonHa;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Zip, System.Generics.Collections,
  DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Decl.Q3Shader.Calc.Types, DelphiDoom.Decl.Q3Shader.Calc.FuncTables,
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask,
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Patch.Intf,
  DelphiDoom.MathCore.Patch.Types, DelphiDoom.MathCore.Patch.Factory, DelphiDoom.Models.Static.Md3.Types,
  DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Factory,
  DelphiDoom.Q3Render.Backend.Surfaces, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Q3Render.Support;

const
  SHADER_MAX_VERTEXES = 1000;

type
  /// <summary>Runs the commands of surfgen.c and writes the lines it prints</summary>
  TSurfaceCaseRunner = class
  strict private
    FTess: TQ3ShaderTess;
    FDlightBits: Integer;
    FLines: TStringList;
    FTessellator: TQ3SurfaceTessellator;
    FFuncTables: TQ3FuncTables;
    FSubdivider: IPatchSubdivider;
    FView: TQ3ViewOrientation;
    FEntity: TQ3ViewOrientation;
    FMirror: Boolean;
    FRailWidth: Integer;
    FRailCoreWidth: Integer;
    FRailSegmentLength: Single;
    FGrids: TArray<IPatchGrid>;
    FInvariant: TFormatSettings;
    function Bits(const AValue: Single): string;
    /// <summary>The bits of a float; every NaN is one value (its payload depends on the instruction: x87 or SSE)</summary>
    function Canonical(const AValue: Single): Cardinal;
    function Fnv(AHash: Cardinal; AValue: Cardinal): Cardinal;
    function FnvByte(AHash: Cardinal; AValue: Byte): Cardinal;
    function Number(const AWord: string): Single;
    function Orientation(const AWords: TArray<string>; AFrom: Integer): TQ3ViewOrientation;
    procedure ResetTess(ANeedsNormal: Boolean);
    procedure BeginSurface;
    procedure EndSurface;
    procedure DumpBatch;
    procedure MakeGrid(const AWords: TArray<string>);
    procedure MapGrids;
    procedure Poly(const AWords: TArray<string>);
    procedure EntityCase(const AWords: TArray<string>);
    procedure MeshCase(const AWords: TArray<string>);
    function MakeMesh(ANumVerts, ANumTriangles, ANumFrames, ASeed: Integer): TMd3Surface;
  public
    constructor Create(const ALines: TStringList);
    destructor Destroy; override;
    /// <summary>The grids of a world (the surface number is the index)</summary>
    procedure SetWorldGrids(const AGrids: TArray<IPatchGrid>);
    procedure Run(const ACases: TStrings);
  end;

{ TSurfaceCaseRunner }

constructor TSurfaceCaseRunner.Create(const ALines: TStringList);
begin
  inherited Create;
  FLines := ALines;
  FInvariant := TFormatSettings.Invariant;
  FFuncTables := TQ3FuncTables.Create;
  FTessellator := TQ3SurfaceTessellator.Create(EndSurface, BeginSurface, FFuncTables.SinTable);
  FSubdivider := TPatchFactory.CreateSubdivider(4);
  FRailWidth := 16;
  FRailCoreWidth := 6;
  FRailSegmentLength := 32;
  FTessellator.SetLodCurveError(250);
end;

destructor TSurfaceCaseRunner.Destroy;
begin
  FTessellator.Free;
  FFuncTables.Free;
  inherited Destroy;
end;

procedure TSurfaceCaseRunner.SetWorldGrids(const AGrids: TArray<IPatchGrid>);
begin
  FGrids := AGrids;
end;

function TSurfaceCaseRunner.Bits(const AValue: Single): string;
var
  LCopy: Single;
begin
  LCopy := AValue;
  Result := LowerCase(IntToHex(PCardinal(@LCopy)^, 8));
end;

function TSurfaceCaseRunner.Canonical(const AValue: Single): Cardinal;
var
  LCopy: Single;
  LBits: Cardinal;
begin
  LCopy := AValue;
  LBits := PCardinal(@LCopy)^;
  if ((LBits and $7F800000) = $7F800000) and ((LBits and $007FFFFF) <> 0) then
    Result := $7FC00000
  else
    Result := LBits;
end;

function TSurfaceCaseRunner.FnvByte(AHash: Cardinal; AValue: Byte): Cardinal;
begin
  Result := (AHash xor AValue) * 16777619;
end;

function TSurfaceCaseRunner.Fnv(AHash: Cardinal; AValue: Cardinal): Cardinal;
var
  LIndex: Integer;
begin
  Result := AHash;
  for LIndex := 0 to 3 do
    Result := FnvByte(Result, Byte(AValue shr (8 * LIndex)));
end;

function TSurfaceCaseRunner.Number(const AWord: string): Single;
begin
  Result := StrToFloat(AWord, FInvariant);
end;

function TSurfaceCaseRunner.Orientation(const AWords: TArray<string>; AFrom: Integer): TQ3ViewOrientation;
var
  LAngles: TQ3Vec3;
  LIndex: Integer;
begin
  Result := Default(TQ3ViewOrientation);
  for LIndex := 0 to 2 do
  begin
    Result.Origin[LIndex] := Number(AWords[AFrom + LIndex]);
    LAngles[LIndex] := Number(AWords[AFrom + 3 + LIndex]);
  end;
  TQ3Math.AngleVectors(LAngles, Result.Axis[0], Result.Axis[1], Result.Axis[2]);
end;

procedure TSurfaceCaseRunner.ResetTess(ANeedsNormal: Boolean);
begin
  FTess := Default(TQ3ShaderTess);
  SetLength(FTess.Xyz, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.Normal, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.TexCoords, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.VertexColors, SHADER_MAX_VERTEXES * 4);
  SetLength(FTess.Indexes, 6 * SHADER_MAX_VERTEXES);
  FDlightBits := 0;
end;

procedure TSurfaceCaseRunner.BeginSurface;
begin
  FTess.NumIndexes := 0;
  FTess.NumVertexes := 0;
  FDlightBits := 0;
end;

procedure TSurfaceCaseRunner.DumpBatch;
var
  LX, LN, LT, LC, LI: Cardinal;
  LVertex, LK: Integer;
begin
  LX := 2166136261;
  LN := 2166136261;
  LT := 2166136261;
  LC := 2166136261;
  LI := 2166136261;
  for LVertex := 0 to FTess.NumVertexes - 1 do
  begin
    for LK := 0 to 2 do
      LX := Fnv(LX, Canonical(FTess.Xyz[LVertex * 4 + LK]));
    for LK := 0 to 2 do
      LN := Fnv(LN, Canonical(FTess.Normal[LVertex * 4 + LK]));
    for LK := 0 to 3 do
      LT := Fnv(LT, Canonical(FTess.TexCoords[LVertex * 4 + LK]));
    for LK := 0 to 3 do
      LC := FnvByte(LC, FTess.VertexColors[LVertex * 4 + LK]);
  end;
  for LVertex := 0 to FTess.NumIndexes - 1 do
    LI := Fnv(LI, Cardinal(FTess.Indexes[LVertex]));
  FLines.Add(Format('batch %d %d %s %s %s %s %s %s', [FTess.NumVertexes, FTess.NumIndexes,
    LowerCase(IntToHex(FDlightBits, 1)),
    LowerCase(IntToHex(LX, 8)), LowerCase(IntToHex(LN, 8)), LowerCase(IntToHex(LT, 8)), LowerCase(IntToHex(LC, 8)),
    LowerCase(IntToHex(LI, 8))]));
end;

procedure TSurfaceCaseRunner.EndSurface;
begin
  if FTess.NumIndexes = 0 then
    Exit;
  DumpBatch;
  FTess.NumIndexes := 0;
  FTess.NumVertexes := 0;
end;

procedure TSurfaceCaseRunner.MakeGrid(const AWords: TArray<string>);
var
  LWidth, LHeight, LBulge, LDlight, LColumn, LRow, LDi, LDj: Integer;
  LNormal: Boolean;
  LPoints: TArray<TPatchVertex>;
  LGrid: IPatchGrid;
  LVertex: TPatchVertex;
  LOrigin: TIdVec3;
begin
  LWidth := StrToInt(AWords[1]);
  LHeight := StrToInt(AWords[2]);
  LBulge := StrToInt(AWords[3]);
  LDlight := StrToInt(AWords[4]);
  LNormal := AWords[5] <> '0';
  SetLength(LPoints, LWidth * LHeight);
  for LRow := 0 to LHeight - 1 do
    for LColumn := 0 to LWidth - 1 do
    begin
      LDi := LColumn - LWidth div 2;
      LDj := LRow - LHeight div 2;
      LVertex := Default(TPatchVertex);
      LVertex.Position.X := LColumn * 40 + ((LColumn * 13 + LRow * 7) mod 9) - 4;
      LVertex.Position.Y := LRow * 40 + ((LColumn * 5 + LRow * 11) mod 7) - 3;
      LVertex.Position.Z := LBulge - (LDi * LDi + LDj * LDj) * LBulge div 8 + ((LColumn * 3 + LRow * 17) mod 5);
      LVertex.TexCoord.X := Single(LColumn) / Single(LWidth - 1);
      LVertex.TexCoord.Y := Single(LRow) / Single(LHeight - 1);
      LVertex.Lightmap.X := Single(LColumn * 2) / 32.0;
      LVertex.Lightmap.Y := Single(LRow * 2) / 32.0;
      LVertex.Normal.Z := 1;
      LVertex.Color[0] := Byte(LColumn * 31 + LRow * 7);
      LVertex.Color[1] := Byte(LColumn * 11 + LRow * 29);
      LVertex.Color[2] := Byte(LColumn * 5 + LRow * 3);
      LVertex.Color[3] := 255;
      LPoints[LRow * LWidth + LColumn] := LVertex;
    end;
  LGrid := FSubdivider.SubdividePatchToGrid(LWidth, LHeight, LPoints);
  LOrigin.X := Number(AWords[6]);
  LOrigin.Y := Number(AWords[7]);
  LOrigin.Z := Number(AWords[8]);
  LGrid.LodOrigin := LOrigin;
  LGrid.LodRadius := Number(AWords[9]);
  FLines.Add(Format('grid %d %d', [LGrid.Width, LGrid.Height]));
  ResetTess(LNormal);
  FTessellator.Grid(FTess, FDlightBits, LNormal, LGrid, LDlight);
  EndSurface;
end;

procedure TSurfaceCaseRunner.MapGrids;
var
  LIndex: Integer;
  LGrid: IPatchGrid;
  LDlight, LDump: Integer;
begin
  for LIndex := 0 to High(FGrids) do
  begin
    LGrid := FGrids[LIndex];
    if not Assigned(LGrid) then
      Continue;
    LDlight := Integer((Cardinal((UInt64(LIndex) * 2654435761) and $FFFFFFFF) shr 16) and $FFFF);
    ResetTess((LIndex and 1) <> 0);
    FLines.Add(Format('surface %d %d %d %s %s %s %s', [LIndex, LGrid.Width, LGrid.Height, Bits(LGrid.LodOrigin.X),
      Bits(LGrid.LodOrigin.Y), Bits(LGrid.LodOrigin.Z), Bits(LGrid.LodRadius)]));
    FTessellator.Grid(FTess, FDlightBits, (LIndex and 1) <> 0, LGrid, LDlight);
    EndSurface;
    if (GetEnvironmentVariable('SURFGEN_DUMP') <> '') and (StrToIntDef(GetEnvironmentVariable('SURFGEN_DUMP'), -1) = LIndex) then
      for LDump := 0 to LGrid.Width * LGrid.Height - 1 do
        FLines.Add(Format('v %d %s %s %s %s %s', [LDump, Bits(LGrid.Vertices[LDump].TexCoord.X),
          Bits(LGrid.Vertices[LDump].TexCoord.Y), Bits(LGrid.Vertices[LDump].Lightmap.X),
          Bits(LGrid.Vertices[LDump].Lightmap.Y), Bits(LGrid.Vertices[LDump].Position.X)]));
  end;
end;

procedure TSurfaceCaseRunner.Poly(const AWords: TArray<string>);
var
  LCount, LPolys, LIndex: Integer;
  LPoly: TQ3ScenePoly;
begin
  LCount := StrToInt(AWords[1]);
  LPolys := StrToInt(AWords[2]);
  SetLength(LPoly.Verts, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LPoly.Verts[LIndex].Xyz[0] := LIndex * 8 + 3;
    LPoly.Verts[LIndex].Xyz[1] := (LIndex * 5) mod 11 - 5;
    LPoly.Verts[LIndex].Xyz[2] := LIndex mod 3 * 4;
    LPoly.Verts[LIndex].St[0] := Single(LIndex) / 8.0;
    LPoly.Verts[LIndex].St[1] := Single(LCount - LIndex) / 16.0;
    LPoly.Verts[LIndex].Modulate[0] := Byte(LIndex * 9);
    LPoly.Verts[LIndex].Modulate[1] := Byte(255 - LIndex * 3);
    LPoly.Verts[LIndex].Modulate[2] := Byte(LIndex * 17);
    LPoly.Verts[LIndex].Modulate[3] := Byte(200 + LIndex mod 50);
  end;
  ResetTess(False);
  while LPolys > 0 do
  begin
    FTessellator.Polychain(FTess, LPoly);
    Dec(LPolys);
  end;
  EndSurface;
end;

procedure TSurfaceCaseRunner.EntityCase(const AWords: TArray<string>);
var
  LEntity: TQ3RefEntity;
  LIndex: Integer;
  LStrip: TArray<TQ3Vec3>;
begin
  LEntity := Default(TQ3RefEntity);
  for LIndex := 0 to 2 do
  begin
    LEntity.Origin[LIndex] := Number(AWords[1 + LIndex]);
    LEntity.OldOrigin[LIndex] := Number(AWords[4 + LIndex]);
  end;
  LEntity.Radius := Number(AWords[7]);
  LEntity.Rotation := Number(AWords[8]);
  for LIndex := 0 to 3 do
    LEntity.ShaderRGBA[LIndex] := Byte(StrToInt(AWords[9 + LIndex]));
  ResetTess(False);
  if AWords[0] = 'sprite' then
    FTessellator.Sprite(FTess, LEntity)
  else if AWords[0] = 'beam' then
  begin
    LStrip := FTessellator.BeamStrip(LEntity);
    if Length(LStrip) > 0 then
    begin
      FLines.Add('gl bind');
      FLines.Add('gl state 00000022');
      FLines.Add('gl color3f 3f800000 00000000 00000000');
      FLines.Add('gl begin 5');
      for LIndex := 0 to High(LStrip) do
        FLines.Add(Format('gl vertex3fv %s %s %s', [Bits(LStrip[LIndex][0]), Bits(LStrip[LIndex][1]),
          Bits(LStrip[LIndex][2])]));
      FLines.Add('gl end');
    end;
  end
  else if AWords[0] = 'railcore' then
    FTessellator.RailCore(FTess, LEntity)
  else if AWords[0] = 'railrings' then
    FTessellator.RailRings(FTess, LEntity)
  else
    FTessellator.LightningBolt(FTess, LEntity);
  EndSurface;
end;

function TSurfaceCaseRunner.MakeMesh(ANumVerts, ANumTriangles, ANumFrames, ASeed: Integer): TMd3Surface;
var
  LIndex, LFrame, LBase, LLat, LLng: Integer;
begin
  Result := Default(TMd3Surface);
  Result.NumFrames := ANumFrames;
  Result.NumVerts := ANumVerts;
  SetLength(Result.Triangles, ANumTriangles * 3);
  for LIndex := 0 to ANumTriangles - 1 do
  begin
    Result.Triangles[LIndex * 3] := (LIndex * 3 + ASeed) mod ANumVerts;
    Result.Triangles[LIndex * 3 + 1] := (LIndex * 5 + 1) mod ANumVerts;
    Result.Triangles[LIndex * 3 + 2] := (LIndex * 7 + 2) mod ANumVerts;
  end;
  SetLength(Result.St, ANumVerts);
  for LIndex := 0 to ANumVerts - 1 do
  begin
    Result.St[LIndex].X := Single(LIndex mod 17) / 16.0;
    Result.St[LIndex].Y := Single(LIndex mod 13) / 12.0;
  end;
  SetLength(Result.XyzNormals, ANumVerts * ANumFrames * 4);
  for LFrame := 0 to ANumFrames - 1 do
    for LIndex := 0 to ANumVerts - 1 do
    begin
      LBase := (LFrame * ANumVerts + LIndex) * 4;
      LLat := (LIndex * 7 + LFrame * 3 + ASeed) and 255;
      LLng := (LIndex * 13 + LFrame * 5) and 255;
      Result.XyzNormals[LBase] := SmallInt(((LIndex * 37 + LFrame * 11 + ASeed) mod 2001) - 1000);
      Result.XyzNormals[LBase + 1] := SmallInt(((LIndex * 53 + LFrame * 7) mod 2001) - 1000);
      Result.XyzNormals[LBase + 2] := SmallInt(((LIndex * 29 + LFrame * 19) mod 1601) - 800);
      Result.XyzNormals[LBase + 3] := SmallInt((LLat shl 8) or LLng);
    end;
end;

procedure TSurfaceCaseRunner.MeshCase(const AWords: TArray<string>);
var
  LSurface: TMd3Surface;
  LRepeat: Integer;
begin
  LSurface := MakeMesh(StrToInt(AWords[1]), StrToInt(AWords[2]), StrToInt(AWords[3]), StrToInt(AWords[7]));
  LRepeat := StrToInt(AWords[8]);
  ResetTess(True);
  while LRepeat > 0 do
  begin
    FTessellator.Mesh(FTess, LSurface, StrToInt(AWords[4]), StrToInt(AWords[5]), Number(AWords[6]));
    Dec(LRepeat);
  end;
  EndSurface;
end;

procedure TSurfaceCaseRunner.Run(const ACases: TStrings);
var
  LNumber: Integer;
  LLine, LWord: string;
  LWords: TArray<string>;
  LMask: IInterface;
begin
  // the C does not stop on a NaN or an infinity: the FPU exceptions are masked while the surfaces are made
  LMask := TQ3FloatMask.Enter;
  LNumber := 0;
  for LLine in ACases do
  begin
    Inc(LNumber);
    if (Trim(LLine) = '') or (LLine[1] = '#') then
      Continue;
    LWords := Trim(LLine).Split([' '], TStringSplitOptions.ExcludeEmpty);
    LWord := LWords[0];
    if LWord = 'lod' then
      FTessellator.SetLodCurveError(Number(LWords[1]))
    else if LWord = 'subdiv' then
      FSubdivider := TPatchFactory.CreateSubdivider(Number(LWords[1]))
    else if LWord = 'rail' then
      FTessellator.SetRailSettings(StrToInt(LWords[1]), StrToInt(LWords[2]), Number(LWords[3]))
    else if LWord = 'view' then
    begin
      FView := Orientation(LWords, 1);
      FMirror := LWords[7] <> '0';
      FTessellator.SetView(FView, FMirror);
    end
    else if LWord = 'or' then
    begin
      FEntity := Orientation(LWords, 1);
      FTessellator.SetEntityOrientation(FEntity);
    end
    else
    begin
      FLines.Add(Format('case %d', [LNumber]));
      if LWord = 'grid' then
        MakeGrid(LWords)
      else if LWord = 'mapgrids' then
        MapGrids
      else if LWord = 'poly' then
        Poly(LWords)
      else if LWord = 'mesh' then
        MeshCase(LWords)
      else
        EntityCase(LWords);
    end;
  end;
end;

{ TTestQ3Surfaces }

procedure TTestQ3Surfaces.DovrebbeDareLeStesseGrigliePoligoniSpriteRaggiEMeshDelCDiQuake;
var
  LCasesFile, LGoldenFile: string;
  LCases, LActual, LGolden: TStringList;
  LRunner: TSurfaceCaseRunner;
begin
  LCasesFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\surf.cases.txt');
  LGoldenFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\surf.golden.txt');
  Assert.IsTrue((LCasesFile <> '') and (LGoldenFile <> ''), 'surf.cases.txt and surf.golden.txt must be there');
  LCases := TStringList.Create;
  LActual := TStringList.Create;
  try
    LCases.LoadFromFile(LCasesFile);
    LRunner := TSurfaceCaseRunner.Create(LActual);
    try
      LRunner.Run(LCases);
    finally
      LRunner.Free;
    end;
    if GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_SURF_OUT') <> '' then
      LActual.SaveToFile(GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_SURF_OUT'));
    LGolden := TTestFiles.Lines(LGoldenFile);
    try
      TTestGolden.AssertSameLines(LGolden, LActual);
    finally
      LGolden.Free;
    end;
  finally
    LCases.Free;
    LActual.Free;
  end;
end;

procedure TTestQ3Surfaces.DovrebbeDareLeStesseGrigliedelleMappeDelCDiQuake;
var
  LFolder, LCasesFile, LGoldenFile: string;
  LZip: TZipFile;
  LBytes: TBytes;
  LFiles: TMemoryFiles;
  LSystem: IQ3RenderSystem;
  LWorld: IQ3RenderWorld;
  LCases, LActual, LGolden: TStringList;
  LRunner: TSurfaceCaseRunner;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  LFolder := TTestSupport.OpenArenaFolder;
  LCasesFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\surf.map.cases.txt');
  LGoldenFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\surf.map.golden.txt');
  Assert.IsTrue((LCasesFile <> '') and (LGoldenFile <> ''), 'surf.map.cases.txt and surf.map.golden.txt must be there');
  // oa_ctf2 of pak1-maps.pk3, the one the golden was made with (pak6-patch088 has another version of the map)
  LZip := TZipFile.Create;
  try
    LZip.Open(TPath.Combine(LFolder, 'baseoa\pak1-maps.pk3'), zmRead);
    LZip.Read('maps/oa_ctf2.bsp', LBytes);
  finally
    LZip.Free;
  end;
  LFiles := TMemoryFiles.Create;
  LCases := TStringList.Create;
  LActual := TStringList.Create;
  try
    LFiles.Add('maps/oa_ctf2.bsp', LBytes);
    LSystem := TTestSupport.BuildSystem(LFiles as IQ3RenderFiles, nil);
    LWorld := LSystem.WorldLoader.Load('maps/oa_ctf2.bsp');
    Assert.IsTrue(Assigned(LWorld), 'oa_ctf2 must load');
    LCases.LoadFromFile(LCasesFile);
    LRunner := TSurfaceCaseRunner.Create(LActual);
    try
      LRunner.SetWorldGrids(LWorld.GetGrids);
      LRunner.Run(LCases);
    finally
      LRunner.Free;
    end;
    if GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_SURF_OUT') <> '' then
      LActual.SaveToFile(GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_SURF_OUT') + '.map');
    LGolden := TTestFiles.Lines(LGoldenFile);
    try
      TTestGolden.AssertSameLines(LGolden, LActual);
    finally
      LGolden.Free;
    end;
  finally
    LCases.Free;
    LActual.Free;
  end;
end;

procedure TTestQ3Surfaces.DovrebbeRifiutareUnFotogrammaCheLaSuperficieNonHa;
var
  LLines: TStringList;
  LCases: TStringList;
  LRunner: TSurfaceCaseRunner;
  LRaised: Boolean;
begin
  // the C reads past the surface for a frame it does not have: here it is an exception
  LLines := TStringList.Create;
  LCases := TStringList.Create;
  try
    LCases.Add('mesh 10 5 2 7 7 0 1 1');
    LRunner := TSurfaceCaseRunner.Create(LLines);
    try
      LRaised := False;
      try
        LRunner.Run(LCases);
      except
        on EQ3RenderException do
          LRaised := True;
      end;
      Assert.IsTrue(LRaised, 'a frame that the surface does not have must be refused');
    finally
      LRunner.Free;
    end;
  finally
    LCases.Free;
    LLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Surfaces);

end.
