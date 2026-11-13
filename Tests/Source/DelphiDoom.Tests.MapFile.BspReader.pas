{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - reading BSP files of Quake III  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspReader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Bsp.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestBspReader = class
  strict private
    FBytes: TBytes;
    FReader: IBspReader;
    procedure ExpectError(const ABytes: TBytes; const AMessagePart: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLeDimensioniDeiRecordDelC;
    [Test]
    procedure DovrebbeLeggereLeIntestazioniEIConteggi;
    [Test]
    procedure DovrebbeDareIRecordPerIndice;
    [Test]
    procedure DovrebbeDareITestiDelleEntitaEIDeiNomi;
    [Test]
    procedure DovrebbeDareLightmapLightGridEVisibilita;
    [Test]
    procedure DovrebbeDareIByteDiOgniLumpComeNelFile;
    [Test]
    procedure DovrebbeAccettareILumpOpzionaliVuoti;
    [Test]
    procedure DovrebbeLeggereUnFileDaUnFileSystemIniettato;
    [Test]
    procedure DovrebbeDareNilPerUnFileCheNonEsiste;
    [Test]
    procedure DovrebbeDareNilSenzaFileSystem;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnIdentificatoreSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnLumpFuoriDalFile;
    [Test]
    procedure DovrebbeRifiutareUnLumpConLunghezzaNegativa;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaCheNonESuoloMultiploDelRecord;
    [Test]
    procedure DovrebbeRifiutareUnaMappaSenzaShader;
    [Test]
    procedure DovrebbeRifiutareUnaMappaSenzaPiani;
    [Test]
    procedure DovrebbeRifiutareUnaMappaSenzaNodi;
    [Test]
    procedure DovrebbeRifiutareUnaMappaSenzaFoglie;
    [Test]
    procedure DovrebbeRifiutareUnaMappaSenzaModelli;
    [Test]
    procedure DovrebbeRifiutareTroppiModelli;
    [Test]
    procedure DovrebbeRifiutareUnaVisibilitaSenzaIntestazione;
    [Test]
    procedure DovrebbeLeggereLeEntitaComeNelFileMap;
    [Test]
    procedure DovrebbeRifiutareUnTestoDelleEntitaCheNonSiChiude;
  end;

implementation

uses
  System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Entity,
  DelphiDoom.MapFile.Bsp.EntityReader, DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.MapFile.Bsp.Types,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.MapFile.BspSample;

{ TTestBspReader }

procedure TTestBspReader.Setup;
var
  LBuilder: TBspSampleBuilder;
begin
  LBuilder := TBspSampleBuilder.Create;
  try
    FBytes := LBuilder.Build(0);
  finally
    LBuilder.Free;
  end;
  FReader := TBspFactory.CreateReader;
end;

procedure TTestBspReader.ExpectError(const ABytes: TBytes; const AMessagePart: string);
var
  LMessage: string;
begin
  LMessage := '';
  try
    FReader.ParseBytes(ABytes, 'test.bsp');
  except
    on E: EBspFileException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(LMessage <> '', 'no error raised (expected "' + AMessagePart + '")');
  Assert.IsTrue(Pos(AMessagePart, LMessage) > 0, 'error was "' + LMessage + '", expected "' + AMessagePart + '"');
end;

procedure TTestBspReader.DovrebbeDareLeDimensioniDeiRecordDelC;
begin
  // the sizes the real structs of qfiles.h have (bspgen.exe prints them in bsp.golden.txt)
  Assert.AreEqual(8, SizeOf(TBspLump));
  Assert.AreEqual(144, SizeOf(TBspHeader));
  Assert.AreEqual(40, SizeOf(TBspModel));
  Assert.AreEqual(72, SizeOf(TBspShader));
  Assert.AreEqual(16, SizeOf(TBspPlane));
  Assert.AreEqual(36, SizeOf(TBspNode));
  Assert.AreEqual(48, SizeOf(TBspLeaf));
  Assert.AreEqual(8, SizeOf(TBspBrushSide));
  Assert.AreEqual(12, SizeOf(TBspBrush));
  Assert.AreEqual(72, SizeOf(TBspFog));
  Assert.AreEqual(44, SizeOf(TBspDrawVert));
  Assert.AreEqual(104, SizeOf(TBspSurface));
end;

procedure TTestBspReader.DovrebbeLeggereLeIntestazioniEIConteggi;
var
  LFile: IBspFile;
begin
  LFile := FReader.ParseBytes(FBytes, 'test.bsp');
  Assert.AreEqual(BSP_VERSION, LFile.Version);
  Assert.AreEqual(144, LFile.Lumps[LUMP_ENTITIES].FileOfs);
  Assert.AreEqual<Integer>(3, Length(LFile.Shaders));
  Assert.AreEqual<Integer>(8, Length(LFile.Planes));
  Assert.AreEqual<Integer>(1, Length(LFile.Nodes));
  Assert.AreEqual<Integer>(2, Length(LFile.Leafs));
  Assert.AreEqual<Integer>(8, Length(LFile.LeafSurfaces));
  Assert.AreEqual<Integer>(1, Length(LFile.LeafBrushes));
  Assert.AreEqual<Integer>(1, Length(LFile.Models));
  Assert.AreEqual<Integer>(1, Length(LFile.Brushes));
  Assert.AreEqual<Integer>(6, Length(LFile.BrushSides));
  Assert.AreEqual<Integer>(65, Length(LFile.DrawVerts));
  Assert.AreEqual<Integer>(6, Length(LFile.DrawIndexes));
  Assert.AreEqual<Integer>(1, Length(LFile.Fogs));
  Assert.AreEqual<Integer>(8, Length(LFile.Surfaces));
end;

procedure TTestBspReader.DovrebbeDareIRecordPerIndice;
var
  LFile: IBspFile;
begin
  LFile := FReader.ParseBytes(FBytes, 'test.bsp');
  Assert.AreEqual<Single>(12.5, LFile.Planes[6].Dist);
  Assert.AreEqual<Single>(-1, LFile.Planes[3].Normal[1]);
  Assert.AreEqual(6, LFile.Nodes[0].PlaneNum);
  Assert.AreEqual(-2, LFile.Nodes[0].Children[1]);
  Assert.AreEqual(8, LFile.Leafs[0].NumLeafSurfaces);
  Assert.AreEqual(1, LFile.Leafs[1].Cluster);
  Assert.AreEqual(6, LFile.Brushes[0].NumSides);
  Assert.AreEqual<Single>(64, LFile.DrawVerts[1].Xyz[0]);
  Assert.AreEqual<Single>(1, LFile.DrawVerts[2].St[1]);
  Assert.AreEqual(255, Integer(LFile.DrawVerts[0].Color[0]));
  Assert.AreEqual(MST_PLANAR, LFile.Surfaces[0].SurfaceType);
  Assert.AreEqual(MST_PATCH, LFile.Surfaces[3].SurfaceType);
  Assert.AreEqual(3, LFile.Surfaces[3].PatchWidth);
  Assert.AreEqual<Single>(256, LFile.Surfaces[3].LightmapVecs[1, 0]);
  Assert.AreEqual(5, LFile.Surfaces[7].PatchHeight);
  Assert.AreEqual(SURF_NODRAW, LFile.Shaders[1].SurfaceFlags);
end;

procedure TTestBspReader.DovrebbeDareITestiDelleEntitaEIDeiNomi;
var
  LFile: IBspFile;
begin
  LFile := FReader.ParseBytes(FBytes, 'test.bsp');
  Assert.IsTrue(string(LFile.EntityText).StartsWith('{'#10'"classname" "worldspawn"'));
  Assert.AreEqual<Integer>(Integer(LFile.Lumps[LUMP_ENTITIES].FileLen - 1), Length(LFile.EntityText),
    'the text ends at the NUL');
  Assert.AreEqual('textures/test/wall', string(LFile.ShaderName(0)));
  Assert.AreEqual('textures/test/curve', string(LFile.ShaderName(2)));
  Assert.AreEqual('textures/test/fog', string(LFile.FogShaderName(0)));
end;

procedure TTestBspReader.DovrebbeDareLightmapLightGridEVisibilita;
var
  LFile: IBspFile;
begin
  LFile := FReader.ParseBytes(FBytes, 'test.bsp');
  Assert.AreEqual(2, LFile.LightmapCount);
  Assert.AreEqual<Integer>(2 * BSP_LIGHTMAP_BYTES, Length(LFile.Lightmaps));
  Assert.AreEqual<Integer>(48, Length(LFile.LightGrid));
  Assert.AreEqual(2, LFile.NumClusters);
  Assert.AreEqual(8, LFile.ClusterBytes);
  Assert.AreEqual<Integer>(16, Length(LFile.Visibility));
end;

procedure TTestBspReader.DovrebbeDareIByteDiOgniLumpComeNelFile;
var
  LFile: IBspFile;
  LIndex: Integer;
begin
  LFile := FReader.ParseBytes(FBytes, 'test.bsp');
  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    Assert.AreEqual<Integer>(LFile.Lumps[LIndex].FileLen, Length(LFile.LumpData[LIndex]), 'lump ' + IntToStr(LIndex));
    Assert.IsTrue(CompareMem(@FBytes[LFile.Lumps[LIndex].FileOfs], @LFile.LumpData[LIndex][0],
      LFile.Lumps[LIndex].FileLen), 'bytes of lump ' + IntToStr(LIndex));
  end;
end;

procedure TTestBspReader.DovrebbeAccettareILumpOpzionaliVuoti;
var
  LBytes: TBytes;
  LFile: IBspFile;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_LIGHTMAPS, 0);
  BspPatchLumpLength(LBytes, LUMP_LIGHTGRID, 0);
  BspPatchLumpLength(LBytes, LUMP_VISIBILITY, 0);
  BspPatchLumpLength(LBytes, LUMP_DRAWVERTS, 0);
  BspPatchLumpLength(LBytes, LUMP_SURFACES, 0);
  BspPatchLumpLength(LBytes, LUMP_ENTITIES, 0);
  LFile := FReader.ParseBytes(LBytes, 'test.bsp');
  Assert.AreEqual(0, LFile.LightmapCount);
  Assert.AreEqual(0, LFile.NumClusters);
  Assert.AreEqual<Integer>(0, Length(LFile.Visibility));
  Assert.AreEqual<Integer>(0, Length(LFile.Surfaces));
  Assert.AreEqual('', string(LFile.EntityText));
end;

procedure TTestBspReader.DovrebbeLeggereUnFileDaUnFileSystemIniettato;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LData: AnsiString;
  LFile: IBspFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  SetLength(LData, Length(FBytes));
  Move(FBytes[0], LData[1], Length(FBytes));
  LFileSystem.SetFile('maps/test.bsp', LData);
  LFile := TBspFactory.CreateReader(LFileSystem).Parse('maps/test.bsp');
  Assert.IsTrue(Assigned(LFile));
  Assert.AreEqual<Integer>(8, Length(LFile.Surfaces));
end;

procedure TTestBspReader.DovrebbeDareNilPerUnFileCheNonEsiste;
var
  LFileSystem: IIdLibFileSystem;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  Assert.IsFalse(Assigned(TBspFactory.CreateReader(LFileSystem).Parse('maps/none.bsp')));
end;

procedure TTestBspReader.DovrebbeDareNilSenzaFileSystem;
begin
  Assert.IsFalse(Assigned(FReader.Parse('maps/test.bsp')));
end;

procedure TTestBspReader.DovrebbeRifiutareUnFileTroppoCorto;
begin
  ExpectError(Copy(FBytes, 0, 100), 'too short');
  ExpectError(nil, 'too short');
end;

procedure TTestBspReader.DovrebbeRifiutareUnIdentificatoreSbagliato;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  LBytes[0] := Ord('R');
  ExpectError(LBytes, 'not a BSP file');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaVersioneSbagliata;
var
  LBytes: TBytes;
  LVersion: Integer;
begin
  LBytes := Copy(FBytes);
  LVersion := 47;
  Move(LVersion, LBytes[4], 4);
  ExpectError(LBytes, 'wrong version number (47 should be 46)');
end;

procedure TTestBspReader.DovrebbeRifiutareUnLumpFuoriDalFile;
var
  LBytes: TBytes;
begin
  // the original reads past the buffer
  LBytes := Copy(FBytes, 0, Length(FBytes) - 10);
  ExpectError(LBytes, 'lump 16');
end;

procedure TTestBspReader.DovrebbeRifiutareUnLumpConLunghezzaNegativa;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_FOGS, -72);
  ExpectError(LBytes, 'lump 12');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaLunghezzaCheNonESuoloMultiploDelRecord;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_SHADERS, 217);
  ExpectError(LBytes, 'funny lump size');
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_DRAWINDEXES, 22);
  ExpectError(LBytes, 'funny lump size');
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_SURFACES, 105);
  ExpectError(LBytes, 'funny lump size');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaMappaSenzaShader;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_SHADERS, 0);
  ExpectError(LBytes, 'Map with no shaders');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaMappaSenzaPiani;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_PLANES, 0);
  ExpectError(LBytes, 'Map with no planes');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaMappaSenzaNodi;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_NODES, 0);
  ExpectError(LBytes, 'Map has no nodes');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaMappaSenzaFoglie;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_LEAFS, 0);
  ExpectError(LBytes, 'Map with no leafs');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaMappaSenzaModelli;
var
  LBytes: TBytes;
begin
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_MODELS, 0);
  ExpectError(LBytes, 'Map with no models');
end;

procedure TTestBspReader.DovrebbeRifiutareTroppiModelli;
var
  LBytes: TBytes;
  LOffset: Integer;
begin
  // 257 models that sit on the lightmaps, which are big enough
  LBytes := Copy(FBytes);
  LOffset := BspLumpOffset(LBytes, LUMP_LIGHTMAPS);
  Move(LOffset, LBytes[8 + LUMP_MODELS * 8], 4);
  BspPatchLumpLength(LBytes, LUMP_MODELS, 257 * SizeOf(TBspModel));
  ExpectError(LBytes, 'MAX_SUBMODELS exceeded');
end;

procedure TTestBspReader.DovrebbeRifiutareUnaVisibilitaSenzaIntestazione;
var
  LBytes: TBytes;
begin
  // the original reads two integers from a lump that may be shorter than 8 bytes
  LBytes := Copy(FBytes);
  BspPatchLumpLength(LBytes, LUMP_VISIBILITY, 4);
  ExpectError(LBytes, 'visibility lump');
end;

procedure TTestBspReader.DovrebbeLeggereLeEntitaComeNelFileMap;
var
  LFile: IBspFile;
  LEntities: TObjectList<TMapEntity>;
begin
  LFile := FReader.ParseBytes(FBytes, 'test.bsp');
  LEntities := TBspEntityReader.Parse(LFile.EntityText);
  try
    Assert.AreEqual(2, LEntities.Count);
    Assert.AreEqual('worldspawn', string(LEntities[0].Epairs.GetString('classname')));
    Assert.AreEqual('q3 test variant 0', string(LEntities[0].Epairs.GetString('message')));
    Assert.AreEqual('info_player_deathmatch', string(LEntities[1].Epairs.GetString('classname')));
    Assert.AreEqual('0 0 24', string(LEntities[1].Epairs.GetString('origin')));
    Assert.AreEqual(90, LEntities[1].Epairs.GetInt('angle'));
  finally
    LEntities.Free;
  end;
end;

procedure TTestBspReader.DovrebbeRifiutareUnTestoDelleEntitaCheNonSiChiude;
begin
  Assert.WillRaise(
    procedure
    begin
      TBspEntityReader.Parse('{ "classname" "worldspawn"').Free;
    end, EBspFileException);
end;

end.
