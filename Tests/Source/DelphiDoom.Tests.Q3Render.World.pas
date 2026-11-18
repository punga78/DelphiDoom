{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R0) - the world  }
{  loader over the BSP samples of Tests\Source\DelphiDoom.Tests.MapFile.       }
{  BspSample (the lumps have their parity with the C in the tests of           }
{  IdTech4\MapFile); here the order of RE_LoadWorldMap and the counts          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.World;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3WorldLoader = class
  public
    [Test]
    procedure DovrebbeCaricareLeSuperficiPerTipo;
    [Test]
    procedure DovrebbeDareNilPerUnFileCheNonCe;
    [Test]
    procedure DovrebbeDareUnaEccezioneDelRendererPerUnBspDanneggiato;
    [Test]
    procedure DovrebbeContareLeSuperficiRifiutateSenzaFermareIlCaricamento;
    [Test]
    procedure DovrebbeDireCheUnPuntoVedeSeStesso;
    [Test]
    procedure DovrebbeDareLeBoundsDeiModelliDelMondo;
    [Test]
    procedure DovrebbeDareIlNumeroDelleLightmapEDeiNomiDelleShader;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf,
  DelphiDoom.Tests.Q3Render.Support, DelphiDoom.Tests.MapFile.BspSample;

function LoadSample(out AFiles: TMemoryFiles; out AKeep: IQ3RenderFiles; out ASystem: IQ3RenderSystem;
  AVariant: Integer; out ASurfaces: Integer): IQ3RenderWorld;
var
  LBuilder: TBspSampleBuilder;
begin
  AFiles := TMemoryFiles.Create;
  AKeep := AFiles;
  LBuilder := TBspSampleBuilder.Create;
  try
    AFiles.Add('maps/room.bsp', LBuilder.Build(AVariant));
    ASurfaces := LBuilder.SurfaceCount(AVariant);
  finally
    LBuilder.Free;
  end;
  ASystem := TTestSupport.BuildSystem(AKeep, []);
  Result := ASystem.WorldLoader.Load('maps/room.bsp');
end;

procedure TTestQ3WorldLoader.DovrebbeCaricareLeSuperficiPerTipo;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LWorld: IQ3RenderWorld;
  LSurfaces: Integer;
begin
  LWorld := LoadSample(LFiles, LKeep, LSystem, 0, LSurfaces);
  Assert.IsNotNull(LWorld);
  Assert.AreEqual(LSurfaces, LWorld.SurfaceCount);
  Assert.AreEqual<Integer>(1, Length(LWorld.GetFaces), 'the quad');
  Assert.AreEqual<Integer>(1, Length(LWorld.GetTriangleSurfaces), 'the soup');
  Assert.AreEqual<Integer>(1, Length(LWorld.GetFlares), 'the flare');
  // every other surface is a patch; the one with SURF_NODRAW has no grid
  Assert.AreEqual(LSurfaces - 3 - 1, LWorld.PatchCount);
  Assert.AreEqual(0, LWorld.RefusedCount);
  Assert.IsTrue(LWorld.GetTree.NumDecisionNodes >= 0);
  Assert.IsTrue(Length(LWorld.GetTree.Nodes) >= 1);
end;

procedure TTestQ3WorldLoader.DovrebbeDareNilPerUnFileCheNonCe;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  LFiles := TMemoryFiles.Create;
  LKeep := LFiles;
  LSystem := TTestSupport.BuildSystem(LKeep, []);
  Assert.IsNull(LSystem.WorldLoader.Load('maps/none.bsp'));
end;

procedure TTestQ3WorldLoader.DovrebbeDareUnaEccezioneDelRendererPerUnBspDanneggiato;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
begin
  LFiles := TMemoryFiles.Create;
  LKeep := LFiles;
  LFiles.Add('maps/bad.bsp', TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8));
  LSystem := TTestSupport.BuildSystem(LKeep, []);
  Assert.WillRaise(
    procedure
    begin
      LSystem.WorldLoader.Load('maps/bad.bsp');
    end, EQ3RenderException);
end;

procedure TTestQ3WorldLoader.DovrebbeContareLeSuperficiRifiutateSenzaFermareIlCaricamento;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LBuilder: TBspSampleBuilder;
  LBytes: TBytes;
  LWorld: IQ3RenderWorld;
begin
  LFiles := TMemoryFiles.Create;
  LKeep := LFiles;
  LBuilder := TBspSampleBuilder.Create;
  try
    LBytes := LBuilder.Build(0);
  finally
    LBuilder.Free;
  end;
  // the first surface (the quad) gets a shader number past the table: the C reads past the shader lump
  BspPatchInt(LBytes, LUMP_SURFACES, 0, 9999);
  LFiles.Add('maps/room.bsp', LBytes);
  LSystem := TTestSupport.BuildSystem(LKeep, []);
  LWorld := LSystem.WorldLoader.Load('maps/room.bsp');
  Assert.IsNotNull(LWorld);
  Assert.AreEqual(1, LWorld.RefusedCount);
  Assert.AreEqual<Integer>(0, Length(LWorld.GetFaces));
  Assert.AreEqual<Integer>(1, Length(LWorld.GetTriangleSurfaces), 'the others are loaded');
end;

procedure TTestQ3WorldLoader.DovrebbeDireCheUnPuntoVedeSeStesso;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LWorld: IQ3RenderWorld;
  LSurfaces: Integer;
  LPoint: TQ3RenderVec3;
  LBytes: TBytes;
begin
  LWorld := LoadSample(LFiles, LKeep, LSystem, 0, LSurfaces);
  LPoint[0] := 0;
  LPoint[1] := 0;
  LPoint[2] := 64;
  Assert.AreEqual(2, LWorld.GetVisibility.NumClusters);
  LFiles.ReadFile('maps/room.bsp', LBytes);
  LBytes := Copy(LBytes, 0, Length(LBytes));
  // every row of the visibility lump all ones: the point sees itself
  FillChar(LBytes[BspLumpOffset(LBytes, LUMP_VISIBILITY) + 8], 16, $FF);
  LFiles.Add('maps/seen.bsp', LBytes);
  Assert.IsTrue(LSystem.WorldLoader.Load('maps/seen.bsp').InPvs(LPoint, LPoint));
  // all zeros: it does not see even itself (the rows say so, the C does not special-case it)
  FillChar(LBytes[BspLumpOffset(LBytes, LUMP_VISIBILITY) + 8], 16, 0);
  LFiles.Add('maps/blind.bsp', LBytes);
  Assert.IsFalse(LSystem.WorldLoader.Load('maps/blind.bsp').InPvs(LPoint, LPoint));
end;

procedure TTestQ3WorldLoader.DovrebbeDareLeBoundsDeiModelliDelMondo;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LWorld: IQ3RenderWorld;
  LSurfaces: Integer;
  LMins, LMaxs: TQ3RenderVec3;
begin
  LWorld := LoadSample(LFiles, LKeep, LSystem, 0, LSurfaces);
  Assert.IsTrue(LWorld.SubmodelCount >= 1);
  Assert.IsTrue(LWorld.SubmodelBounds(0, LMins, LMaxs));
  Assert.IsTrue(LMaxs[0] > LMins[0]);
  Assert.IsFalse(LWorld.SubmodelBounds(LWorld.SubmodelCount, LMins, LMaxs));
  Assert.IsFalse(LWorld.SubmodelBounds(-1, LMins, LMaxs));
end;

procedure TTestQ3WorldLoader.DovrebbeDareIlNumeroDelleLightmapEDeiNomiDelleShader;
var
  LFiles: TMemoryFiles;
  LKeep: IQ3RenderFiles;
  LSystem: IQ3RenderSystem;
  LWorld: IQ3RenderWorld;
  LSurfaces: Integer;
begin
  LWorld := LoadSample(LFiles, LKeep, LSystem, 0, LSurfaces);
  Assert.AreEqual(Length(LWorld.GetBsp.Shaders), Length(LWorld.ShaderNames));
  Assert.AreEqual(AnsiString(LWorld.GetBsp.ShaderName(0)), LWorld.ShaderNames[0]);
  // every lightmap is an RGBA image of 128 x 128
  if Length(LWorld.GetLightmaps) > 0 then
    Assert.AreEqual<Integer>(65536, Length(LWorld.GetLightmaps[0]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3WorldLoader);

end.
