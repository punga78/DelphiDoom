{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the faces, triangle soups,      }
{  flares and visibility of a BSP, with the parity of the real tr_bsp.c        }
{  (bsp_surfaces.golden.txt)                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspSurfaces;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.MapFile.Bsp.Types,
  DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes;

type
  [TestFixture]
  [Category('MapFile')]
  TTestBspSurfacesGolden = class
  strict private
    FActual: TStringList;
    FFile: IBspFile;
    function DataFolder: string;
    function HexToBytes(const AText: string): TBytes;
    function Hash(const ABytes: TBytes; const ACount: Integer): Cardinal;
    function Bits(const AValue: Single): string;
    function ColorText(const AColor: array of Byte): string;
    procedure PrintFace(const AFace: TBspFaceSurface);
    procedure PrintTriangle(const ATriangle: TBspTriangleSurface);
    procedure PrintFlare(const AFlare: TBspFlareSurface);
    procedure ParseOne(const ASurface: TBspSurface; const AVerts: TArray<TBspDrawVert>;
      const AIndexes: TArray<Integer>; const AShift: Integer);
    procedure VisibilityCase(const ATag: string; const ATreeClusters: Integer; const ALump: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    /// <summary>
    ///   bsp_surfaces.golden.txt is what the real ParseFace, ParseTriSurf, ParseFlare and
    ///   R_LoadVisibility of tr_bsp.c print for the surfaces of the sample BSP (variant 0) and
    ///   for 24 surfaces made with a generator and a fixed seed (the inputs are in the file)
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroTrBsp;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestBspSurfaceLoaders = class
  strict private
    function Surface(const AType, AFirstVert, ANumVerts, AFirstIndex, ANumIndexes: Integer): TBspSurface;
    function Vertex(const AX, AY, AZ: Single): TBspDrawVert;
  public
    [Test]
    procedure DovrebbeRifiutareUnoShaderFuoriDallaTabella;
    [Test]
    procedure DovrebbeRifiutareVerticiEIndiciFuoriDaiLump;
    [Test]
    procedure DovrebbeCalcolareIlPianoDiUnaFaccia;
    [Test]
    procedure DovrebbeLimitareLaFacciaA64PuntiConUnAvviso;
    [Test]
    procedure DovrebbeAccettareLaFacciaSenzaLog;
    [Test]
    procedure DovrebbeDareUnaFacciaSenzaPunti;
    [Test]
    procedure DovrebbeSpostareIlColoreDeiVertici;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDaiVerticiDellaSoup;
    [Test]
    procedure DovrebbeDareLimitiDi99999PerUnaSoupVuota;
    [Test]
    procedure DovrebbeLeggereLeCoordinateDelFlare;
    [Test]
    procedure DovrebbeRifiutareUnLumpDiVisibilitaPiuCortoDellIntestazione;
    [Test]
    procedure DovrebbeDareLaStessaVisibilitaDelFile;
    [Test]
    procedure DovrebbeDareLaRigaNovisDi255ArrotondataA64;
    [Test]
    procedure DovrebbeCreareLeClassiPerMezzoDellaFactory;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Tests.IdLib.Fakes,
  DelphiDoom.Tests.MapFile.BspSample;

function FloatBits(const AValue: Single): Cardinal;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := PCardinal(@LValue)^;
end;

function RaisesBspError(const AProc: TProc): Boolean;
begin
  Result := False;
  try
    AProc();
  except
    on EBspFileException do
      Result := True;
  end;
end;

{ TTestBspSurfacesGolden }

procedure TTestBspSurfacesGolden.Setup;
begin
  FActual := TStringList.Create;
end;

procedure TTestBspSurfacesGolden.TearDown;
begin
  FActual.Free;
end;

function TTestBspSurfacesGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\MapFile\');
end;

function TTestBspSurfacesGolden.HexToBytes(const AText: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AText) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := StrToInt('$' + Copy(AText, LIndex * 2 + 1, 2));
end;

function TTestBspSurfacesGolden.Hash(const ABytes: TBytes; const ACount: Integer): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 0 to ACount - 1 do
    Result := (Result xor ABytes[LIndex]) * 16777619;
end;

function TTestBspSurfacesGolden.Bits(const AValue: Single): string;
begin
  Result := LowerCase(IntToHex(FloatBits(AValue), 8));
end;

function TTestBspSurfacesGolden.ColorText(const AColor: array of Byte): string;
begin
  Result := LowerCase(Format('%.2x%.2x%.2x%.2x', [AColor[0], AColor[1], AColor[2], AColor[3]]));
end;

procedure TTestBspSurfacesGolden.PrintFace(const AFace: TBspFaceSurface);
var
  LIndex, LAxis: Integer;
  LLine: string;
begin
  FActual.Add(Format('face type 2 points %d indices %d plane %s %s %s %s ptype %d sb %d',
    [Length(AFace.Points), Length(AFace.Indexes), Bits(AFace.PlaneNormal[0]), Bits(AFace.PlaneNormal[1]),
     Bits(AFace.PlaneNormal[2]), Bits(AFace.PlaneDist), AFace.PlaneType, AFace.PlaneSignBits]));
  for LIndex := 0 to High(AFace.Points) do
  begin
    LLine := Format('fp %d', [LIndex]);
    for LAxis := 0 to 2 do
      LLine := LLine + ' ' + Bits(AFace.Points[LIndex].Xyz[LAxis]);
    for LAxis := 0 to 1 do
      LLine := LLine + ' ' + Bits(AFace.Points[LIndex].St[LAxis]);
    for LAxis := 0 to 1 do
      LLine := LLine + ' ' + Bits(AFace.Points[LIndex].Lightmap[LAxis]);
    FActual.Add(LLine + ' ' + ColorText(AFace.Points[LIndex].Color));
  end;
  LLine := 'fi';
  for LIndex := 0 to High(AFace.Indexes) do
    LLine := LLine + ' ' + IntToStr(AFace.Indexes[LIndex]);
  FActual.Add(LLine);
end;

procedure TTestBspSurfacesGolden.PrintTriangle(const ATriangle: TBspTriangleSurface);
var
  LIndex, LAxis: Integer;
  LLine: string;
begin
  FActual.Add(Format('tri type 4 verts %d indexes %d mins %s %s %s maxs %s %s %s',
    [Length(ATriangle.Verts), Length(ATriangle.Indexes), Bits(ATriangle.Mins[0]), Bits(ATriangle.Mins[1]),
     Bits(ATriangle.Mins[2]), Bits(ATriangle.Maxs[0]), Bits(ATriangle.Maxs[1]), Bits(ATriangle.Maxs[2])]));
  for LIndex := 0 to High(ATriangle.Verts) do
  begin
    LLine := Format('tv %d', [LIndex]);
    for LAxis := 0 to 2 do
      LLine := LLine + ' ' + Bits(ATriangle.Verts[LIndex].Xyz[LAxis]);
    for LAxis := 0 to 1 do
      LLine := LLine + ' ' + Bits(ATriangle.Verts[LIndex].St[LAxis]);
    for LAxis := 0 to 1 do
      LLine := LLine + ' ' + Bits(ATriangle.Verts[LIndex].Lightmap[LAxis]);
    for LAxis := 0 to 2 do
      LLine := LLine + ' ' + Bits(ATriangle.Verts[LIndex].Normal[LAxis]);
    FActual.Add(LLine + ' ' + ColorText(ATriangle.Verts[LIndex].Color));
  end;
  LLine := 'ti';
  for LIndex := 0 to High(ATriangle.Indexes) do
    LLine := LLine + ' ' + IntToStr(ATriangle.Indexes[LIndex]);
  FActual.Add(LLine);
end;

procedure TTestBspSurfacesGolden.PrintFlare(const AFlare: TBspFlareSurface);
begin
  FActual.Add(Format('flare type 8 origin %s %s %s color %s %s %s normal %s %s %s',
    [Bits(AFlare.Origin[0]), Bits(AFlare.Origin[1]), Bits(AFlare.Origin[2]), Bits(AFlare.Color[0]),
     Bits(AFlare.Color[1]), Bits(AFlare.Color[2]), Bits(AFlare.Normal[0]), Bits(AFlare.Normal[1]),
     Bits(AFlare.Normal[2])]));
end;

procedure TTestBspSurfacesGolden.ParseOne(const ASurface: TBspSurface; const AVerts: TArray<TBspDrawVert>;
  const AIndexes: TArray<Integer>; const AShift: Integer);
var
  LLog: TIdLibLogRecorder;
  LLogIntf: IIdLibLog;
  LFace: TBspFaceSurface;
  LTriangle: TBspTriangleSurface;
  LFlare: TBspFlareSurface;
  LFog: Integer;
  LDefault: Boolean;
  LMessage: string;
begin
  LLog := TIdLibLogRecorder.Create;
  LLogIntf := LLog;
  LDefault := False;
  try
    case ASurface.SurfaceType of
      MST_PLANAR:
        begin
          LFace := TBspFactory.CreateFaceLoader(AShift, LLogIntf).Parse(ASurface, AVerts, AIndexes, 3);
          LFog := LFace.FogIndex;
          LDefault := LFace.UsesDefaultShader;
        end;
      MST_TRIANGLE_SOUP:
        begin
          LTriangle := TBspFactory.CreateTriangleLoader(AShift).Parse(ASurface, AVerts, AIndexes, 3);
          LFog := LTriangle.FogIndex;
        end;
      MST_FLARE:
        begin
          LFlare := TBspFactory.CreateFlareLoader.Parse(ASurface, 3);
          LFog := LFlare.FogIndex;
        end;
    else
      Exit;
    end;
  except
    on E: EBspFileException do
    begin
      FActual.Add('ERROR ' + E.Message);
      Exit;
    end;
  end;
  // the warnings come first, as the C prints them while it parses
  for LMessage in LLog.Entries do
    FActual.Add('ri ' + Copy(LMessage, 3, Length(LMessage) - 3));
  // the shader of the stub is "default" only when the original asked for the default shader
  if (ASurface.SurfaceType = MST_PLANAR) and LDefault then
    FActual.Add(Format('surf fog %d shader default', [LFog]))
  else
    FActual.Add(Format('surf fog %d shader found', [LFog]));
  case ASurface.SurfaceType of
    MST_PLANAR: PrintFace(LFace);
    MST_TRIANGLE_SOUP: PrintTriangle(LTriangle);
    MST_FLARE: PrintFlare(LFlare);
  end;
end;

procedure TTestBspSurfacesGolden.VisibilityCase(const ATag: string; const ATreeClusters: Integer;
  const ALump: TBytes);
var
  LVisibility: TBspVisibility;
  LNovisLength: Integer;
  LVisHash: Cardinal;
begin
  LVisibility := TBspFactory.CreateVisibilityLoader.Load(ALump, ATreeClusters);
  LNovisLength := (ATreeClusters + 63) and not 63;
  // the driver prints 0 for the hash of an empty lump
  LVisHash := 0;
  if Length(ALump) > 0 then
    LVisHash := Hash(LVisibility.Vis, Length(LVisibility.Vis));
  FActual.Add(Format('visout clusters %d bytes %d novis %d %s vis %d %s',
    [LVisibility.NumClusters, LVisibility.ClusterBytes, Length(LVisibility.Novis),
     LowerCase(IntToHex(Hash(LVisibility.Novis, LNovisLength), 8)), Length(LVisibility.Vis),
     LowerCase(IntToHex(LVisHash, 8))]));
  Assert.AreEqual<Integer>(LNovisLength, Length(LVisibility.Novis), 'novis length of ' + ATag);
end;

procedure TTestBspSurfacesGolden.DovrebbeDareLeStesseRisposteDelVeroTrBsp;
var
  LGolden: TStringList;
  LBuilder: TBspSampleBuilder;
  LSurfaces: TArray<TBspSurface>;
  LVerts: TArray<TBspDrawVert>;
  LIndexes: TArray<Integer>;
  LSurface: TBspSurface;
  LBytes, LLump: TBytes;
  LTokens: TArray<string>;
  LLine: string;
  LIndex, LNext, LShift, LTree, LCluster: Integer;
begin
  LGolden := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + 'bsp_surfaces.golden.txt'), 'bsp_surfaces.golden.txt not found');
    LGolden.LoadFromFile(DataFolder + 'bsp_surfaces.golden.txt');
    Assert.IsTrue(LGolden.Count > 600, 'too few golden lines');

    LBuilder := TBspSampleBuilder.Create;
    try
      FFile := TBspFactory.CreateReader.ParseBytes(LBuilder.Build(0), 'sample');
    finally
      LBuilder.Free;
    end;
    LTree := 0;
    for LCluster := 0 to High(FFile.Leafs) do
      if FFile.Leafs[LCluster].Cluster >= LTree then
        LTree := FFile.Leafs[LCluster].Cluster + 1;

    LIndex := 0;
    while LIndex < LGolden.Count do
    begin
      LLine := LGolden[LIndex];
      LTokens := LLine.Split([' ']);
      if LLine.StartsWith('file surfaces') then
      begin
        FActual.Add(Format('file surfaces %d', [Length(FFile.Surfaces)]));
        Inc(LIndex);
      end
      else if LLine.StartsWith('filesurf ') then
      begin
        LNext := StrToInt(LTokens[1]);
        FActual.Add(LLine);
        ParseOne(FFile.Surfaces[LNext], FFile.DrawVerts, FFile.DrawIndexes, 1);
        Inc(LIndex);
      end
      else if LLine.StartsWith('vis ') then
      begin
        LNext := StrToInt(LTokens[3]);
        if LTokens[1] = 'file' then
        begin
          Assert.AreEqual<Integer>(LNext, LTree, 'clusters of the tree');
          LLump := FFile.LumpData[LUMP_VISIBILITY];
        end
        else
          LLump := nil;
        FActual.Add(LLine);
        Inc(LIndex);
        if (LIndex < LGolden.Count) and LGolden[LIndex].StartsWith('in lump') then
        begin
          if LTokens[1] <> 'file' then
            LLump := HexToBytes(LGolden[LIndex].Substring(8));
          FActual.Add(LGolden[LIndex]);
          Inc(LIndex);
        end;
        VisibilityCase(LTokens[1], LNext, LLump);
      end
      else if LLine.StartsWith('case ') then
      begin
        LShift := StrToInt(LTokens[5]);
        FActual.Add(LLine);
        FillChar(LSurface, SizeOf(LSurface), 0);
        LBytes := HexToBytes(LGolden[LIndex + 1].Substring(11));
        Move(LBytes[0], LSurface, SizeOf(LSurface));
        FActual.Add(LGolden[LIndex + 1]);
        LBytes := HexToBytes(LGolden[LIndex + 2].Substring(9));
        SetLength(LVerts, Length(LBytes) div SizeOf(TBspDrawVert));
        Move(LBytes[0], LVerts[0], Length(LVerts) * SizeOf(TBspDrawVert));
        FActual.Add(LGolden[LIndex + 2]);
        LBytes := HexToBytes(LGolden[LIndex + 3].Substring(11));
        SetLength(LIndexes, Length(LBytes) div 4);
        Move(LBytes[0], LIndexes[0], Length(LIndexes) * 4);
        FActual.Add(LGolden[LIndex + 3]);
        Inc(LIndex, 4);
        ParseOne(LSurface, LVerts, LIndexes, LShift);
      end
      else
        Inc(LIndex);
      // the answer of the C that follows is skipped here: the whole actual list is compared at the end
      while (LIndex < LGolden.Count) and not (LGolden[LIndex].StartsWith('filesurf ') or
        LGolden[LIndex].StartsWith('vis ') or LGolden[LIndex].StartsWith('case ')) do
        Inc(LIndex);
    end;

    Assert.AreEqual<Integer>(LGolden.Count, FActual.Count, 'number of lines');
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], FActual[LIndex], 'line ' + IntToStr(LIndex + 1));
  finally
    LGolden.Free;
  end;
end;

{ TTestBspSurfaceLoaders }

function TTestBspSurfaceLoaders.Surface(const AType, AFirstVert, ANumVerts, AFirstIndex, ANumIndexes: Integer): TBspSurface;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.SurfaceType := AType;
  Result.FirstVert := AFirstVert;
  Result.NumVerts := ANumVerts;
  Result.FirstIndex := AFirstIndex;
  Result.NumIndexes := ANumIndexes;
end;

function TTestBspSurfaceLoaders.Vertex(const AX, AY, AZ: Single): TBspDrawVert;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Xyz[0] := AX;
  Result.Xyz[1] := AY;
  Result.Xyz[2] := AZ;
end;

procedure TTestBspSurfaceLoaders.DovrebbeRifiutareUnoShaderFuoriDallaTabella;
var
  LSurface: TBspSurface;
begin
  LSurface := Surface(MST_PLANAR, 0, 0, 0, 0);
  LSurface.ShaderNum := 3;
  Assert.IsTrue(RaisesBspError(procedure
    begin
      TBspFactory.CreateFaceLoader.Parse(LSurface, nil, nil, 3);
    end), 'face');
  LSurface.ShaderNum := -1;
  Assert.IsTrue(RaisesBspError(procedure
    begin
      TBspFactory.CreateFlareLoader.Parse(LSurface, 3);
    end), 'flare');
end;

procedure TTestBspSurfaceLoaders.DovrebbeRifiutareVerticiEIndiciFuoriDaiLump;
var
  LVerts: TArray<TBspDrawVert>;
begin
  SetLength(LVerts, 2);
  Assert.IsTrue(RaisesBspError(procedure
    begin
      TBspFactory.CreateFaceLoader.Parse(Surface(MST_PLANAR, 1, 2, 0, 0), LVerts, nil, 1);
    end), 'vertices of a face');
  Assert.IsTrue(RaisesBspError(procedure
    begin
      TBspFactory.CreateTriangleLoader.Parse(Surface(MST_TRIANGLE_SOUP, 0, 2, 0, 3), LVerts, TArray<Integer>.Create(0, 1), 1);
    end), 'indexes of a soup');
end;

procedure TTestBspSurfaceLoaders.DovrebbeCalcolareIlPianoDiUnaFaccia;
var
  LSurface: TBspSurface;
  LFace: TBspFaceSurface;
begin
  LSurface := Surface(MST_PLANAR, 0, 1, 0, 0);
  LSurface.LightmapVecs[2, 2] := 1;
  LFace := TBspFactory.CreateFaceLoader.Parse(LSurface, TArray<TBspDrawVert>.Create(Vertex(1, 2, 7)), nil, 1);
  Assert.AreEqual<Integer>(2, LFace.PlaneType);
  Assert.AreEqual<Integer>(0, LFace.PlaneSignBits);
  Assert.AreEqual(Double(7), Double(LFace.PlaneDist));
  LSurface.LightmapVecs[2, 0] := -0.5;
  LSurface.LightmapVecs[2, 2] := -1;
  LFace := TBspFactory.CreateFaceLoader.Parse(LSurface, TArray<TBspDrawVert>.Create(Vertex(2, 0, 4)), nil, 1);
  Assert.AreEqual<Integer>(3, LFace.PlaneType);
  Assert.AreEqual<Integer>(5, LFace.PlaneSignBits);
  Assert.AreEqual(Double(-5), Double(LFace.PlaneDist));
end;

procedure TTestBspSurfaceLoaders.DovrebbeLimitareLaFacciaA64PuntiConUnAvviso;
var
  LVerts: TArray<TBspDrawVert>;
  LLog: TIdLibLogRecorder;
  LLogIntf: IIdLibLog;
  LFace: TBspFaceSurface;
begin
  SetLength(LVerts, 70);
  LLog := TIdLibLogRecorder.Create;
  LLogIntf := LLog;
  LFace := TBspFactory.CreateFaceLoader(1, LLogIntf).Parse(Surface(MST_PLANAR, 0, 70, 0, 0), LVerts, nil, 1);
  Assert.AreEqual<Integer>(64, Length(LFace.Points));
  Assert.IsTrue(LFace.UsesDefaultShader);
  Assert.AreEqual<Integer>(1, LLog.Entries.Count);
  Assert.IsTrue(LLog.Entries[0].StartsWith('W:WARNING: MAX_FACE_POINTS exceeded: 70'));
end;

procedure TTestBspSurfaceLoaders.DovrebbeAccettareLaFacciaSenzaLog;
var
  LVerts: TArray<TBspDrawVert>;
begin
  SetLength(LVerts, 65);
  Assert.AreEqual<Integer>(64, Length(TBspFactory.CreateFaceLoader.Parse(Surface(MST_PLANAR, 0, 65, 0, 0), LVerts, nil, 1).Points));
end;

procedure TTestBspSurfaceLoaders.DovrebbeDareUnaFacciaSenzaPunti;
var
  LFace: TBspFaceSurface;
begin
  LFace := TBspFactory.CreateFaceLoader.Parse(Surface(MST_PLANAR, 0, 0, 0, 0), nil, nil, 1);
  Assert.AreEqual<Integer>(0, Length(LFace.Points));
  Assert.AreEqual(Double(0), Double(LFace.PlaneDist));
  Assert.AreEqual<Integer>(3, LFace.PlaneType);
end;

procedure TTestBspSurfaceLoaders.DovrebbeSpostareIlColoreDeiVertici;
var
  LVerts: TArray<TBspDrawVert>;
  LFace: TBspFaceSurface;
  LTriangle: TBspTriangleSurface;
begin
  SetLength(LVerts, 1);
  LVerts[0] := Vertex(0, 0, 0);
  LVerts[0].Color[0] := 10;
  LVerts[0].Color[1] := 20;
  LVerts[0].Color[2] := 30;
  LVerts[0].Color[3] := 77;
  LFace := TBspFactory.CreateFaceLoader(2).Parse(Surface(MST_PLANAR, 0, 1, 0, 0), LVerts, nil, 1);
  Assert.AreEqual<Integer>(40, LFace.Points[0].Color[0]);
  Assert.AreEqual<Integer>(120, LFace.Points[0].Color[2]);
  Assert.AreEqual<Integer>(77, LFace.Points[0].Color[3]);
  LTriangle := TBspFactory.CreateTriangleLoader(1).Parse(Surface(MST_TRIANGLE_SOUP, 0, 1, 0, 0), LVerts, nil, 1);
  Assert.AreEqual<Integer>(20, LTriangle.Verts[0].Color[0]);
end;

procedure TTestBspSurfaceLoaders.DovrebbeRifiutareUnIndiceFuoriDaiVerticiDellaSoup;
var
  LVerts: TArray<TBspDrawVert>;
begin
  SetLength(LVerts, 2);
  Assert.IsTrue(RaisesBspError(procedure
    begin
      TBspFactory.CreateTriangleLoader.Parse(Surface(MST_TRIANGLE_SOUP, 0, 2, 0, 3), LVerts,
        TArray<Integer>.Create(0, 1, 2), 1);
    end), 'too big');
  Assert.IsTrue(RaisesBspError(procedure
    begin
      TBspFactory.CreateTriangleLoader.Parse(Surface(MST_TRIANGLE_SOUP, 0, 2, 0, 3), LVerts,
        TArray<Integer>.Create(0, -1, 1), 1);
    end), 'negative');
end;

procedure TTestBspSurfaceLoaders.DovrebbeDareLimitiDi99999PerUnaSoupVuota;
var
  LTriangle: TBspTriangleSurface;
begin
  LTriangle := TBspFactory.CreateTriangleLoader.Parse(Surface(MST_TRIANGLE_SOUP, 0, 0, 0, 0), nil, nil, 1);
  Assert.AreEqual(Double(99999), Double(LTriangle.Mins[1]));
  Assert.AreEqual(Double(-99999), Double(LTriangle.Maxs[2]));
end;

procedure TTestBspSurfaceLoaders.DovrebbeLeggereLeCoordinateDelFlare;
var
  LSurface: TBspSurface;
  LFlare: TBspFlareSurface;
begin
  LSurface := Surface(MST_FLARE, 0, 1, 0, 0);
  LSurface.FogNum := 4;
  LSurface.LightmapOrigin[1] := 12.5;
  LSurface.LightmapVecs[0, 2] := 3;
  LSurface.LightmapVecs[2, 0] := -2;
  LFlare := TBspFactory.CreateFlareLoader.Parse(LSurface, 1);
  Assert.AreEqual<Integer>(5, LFlare.FogIndex);
  Assert.AreEqual(Double(12.5), Double(LFlare.Origin[1]));
  Assert.AreEqual(Double(3), Double(LFlare.Color[2]));
  Assert.AreEqual(Double(-2), Double(LFlare.Normal[0]));
end;

procedure TTestBspSurfaceLoaders.DovrebbeRifiutareUnLumpDiVisibilitaPiuCortoDellIntestazione;
begin
  Assert.IsTrue(RaisesBspError(procedure
    begin
      TBspFactory.CreateVisibilityLoader.Load(TBytes.Create(1, 0, 0, 0), 2);
    end));
end;

procedure TTestBspSurfaceLoaders.DovrebbeDareLaStessaVisibilitaDelFile;
var
  LBuilder: TBspSampleBuilder;
  LFile: IBspFile;
  LVisibility: TBspVisibility;
begin
  LBuilder := TBspSampleBuilder.Create;
  try
    LFile := TBspFactory.CreateReader.ParseBytes(LBuilder.Build(1), 'sample');
  finally
    LBuilder.Free;
  end;
  LVisibility := TBspFactory.CreateVisibilityLoader.Load(LFile.LumpData[LUMP_VISIBILITY], 2);
  // what the collision model keeps is IBspFile.Visibility too: the same bytes can be shared
  Assert.AreEqual<Integer>(LFile.NumClusters, LVisibility.NumClusters);
  Assert.AreEqual<Integer>(LFile.ClusterBytes, LVisibility.ClusterBytes);
  Assert.IsTrue(Length(LFile.Visibility) > 0);
  Assert.IsTrue(CompareMem(@LFile.Visibility[0], @LVisibility.Vis[0], Length(LFile.Visibility)));
  Assert.AreEqual<Integer>(Length(LFile.Visibility), Length(LVisibility.Vis));
  // from the file nothing is decoded: the rows are the very same array
  LVisibility := TBspFactory.CreateVisibilityLoader.LoadFromFile(LFile, 2);
  Assert.AreEqual<Integer>(LFile.NumClusters, LVisibility.NumClusters);
  Assert.AreEqual<Integer>(LFile.ClusterBytes, LVisibility.ClusterBytes);
  Assert.IsTrue(Pointer(LFile.Visibility) = Pointer(LVisibility.Vis));
  Assert.AreEqual<Integer>(64, Length(LVisibility.Novis));
end;

procedure TTestBspSurfaceLoaders.DovrebbeDareLaRigaNovisDi255ArrotondataA64;
var
  LVisibility: TBspVisibility;
begin
  LVisibility := TBspFactory.CreateVisibilityLoader.Load(nil, 65);
  Assert.AreEqual<Integer>(128, Length(LVisibility.Novis));
  Assert.AreEqual<Integer>(255, LVisibility.Novis[127]);
  Assert.AreEqual<Integer>(65, LVisibility.NumClusters);
  Assert.AreEqual<Integer>(0, Length(LVisibility.Vis));
end;

procedure TTestBspSurfaceLoaders.DovrebbeCreareLeClassiPerMezzoDellaFactory;
begin
  Assert.IsNotNull(TBspFactory.CreateFaceLoader);
  Assert.IsNotNull(TBspFactory.CreateTriangleLoader);
  Assert.IsNotNull(TBspFactory.CreateFlareLoader);
  Assert.IsNotNull(TBspFactory.CreateVisibilityLoader);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBspSurfacesGolden);
  TDUnitX.RegisterTestFixture(TTestBspSurfaceLoaders);

end.
