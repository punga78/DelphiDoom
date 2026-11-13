{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - reading .aas files              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.AasReader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestAasFileReader = class
  strict private
    FReader: IAasFileReader;
    function Parse(const ABody: AnsiString): TAasFile;
    procedure ExpectError(const ABody: AnsiString; const AMessagePart: string);
    procedure ExpectRawError(const AText: AnsiString; const AMessagePart: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereUnFileSenzaSezioni;
    [Test]
    procedure DovrebbeDareLeImpostazioniPredefiniteSenzaSettings;
    [Test]
    procedure DovrebbeLeggereLeImpostazioni;
    [Test]
    procedure DovrebbeDerivareLaDirezioneDellaGravita;
    [Test]
    procedure DovrebbeRifiutareUnaImpostazioneSconosciuta;
    [Test]
    procedure DovrebbeRifiutareTroppiBoundingBox;
    [Test]
    procedure DovrebbeRifiutareImpostazioniSenzaBoundingBox;
    [Test]
    procedure DovrebbeLeggerePianiConLaDistanzaDelFile;
    [Test]
    procedure DovrebbeLeggereVerticiESpigoli;
    [Test]
    procedure DovrebbeTroncareICampiStrettiComeIlC;
    [Test]
    procedure DovrebbeMettereLeReachabilityNellOrdineDellaCatenaDelC;
    [Test]
    procedure DovrebbeCollegareLeReachabilityInverse;
    [Test]
    procedure DovrebbeLeggereLeCoppieDiUnaReachabilitySpeciale;
    [Test]
    procedure DovrebbeRifiutareUnaReachabilityVersoUnAreaCheNonEsiste;
    [Test]
    procedure DovrebbeCalcolareIBoundsEIFlagDiViaggioDelleAree;
    [Test]
    procedure DovrebbeCalcolareIlCentroDelleAree;
    [Test]
    procedure DovrebbeCalcolareLaProfonditaDellAlbero;
    [Test]
    procedure DovrebbeRifiutareUnAlberoConUnCiclo;
    [Test]
    procedure DovrebbeRifiutareUnFiglioFuoriDallaLista;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiFacciaFuoriDallaLista;
    [Test]
    procedure DovrebbeSegnalareUnAlberoTroppoProfondoSenzaRifiutare;
    [Test]
    procedure DovrebbeRifiutareUnIdentificatoreSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnFileConUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnFileTroncato;
    [Test]
    procedure DovrebbeRifiutareUnContoNegativoOEnorme;
    [Test]
    procedure DovrebbeSegnalareUnFileFuoriData;
    [Test]
    procedure DovrebbeAccettareUnCrcUgualeOZero;
    [Test]
    procedure DovrebbeDireLaRigaDellErrore;
    [Test]
    procedure DovrebbeLeggereUnFileDalFileSystem;
    [Test]
    procedure DovrebbeDareNilSeIlFileNonEsiste;
    [Test]
    procedure DovrebbeLeggereLeSezioniInQualsiasiOrdine;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Types,
  DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area, DelphiDoom.MapFile.Aas.Reachability,
  DelphiDoom.MapFile.Aas.Geometry, DelphiDoom.MapFile.Aas.Factory, DelphiDoom.Tests.IdLib.Fakes;

const
  HEAD = 'DewmAAS "1.07"'#10#10'99'#10;
  // a square room of 16 x 16 at height 0..8: eight vertices, one face per side is not needed for the tests
  VERTICES = 'vertices 3 {'#10'0 ( 0 0 0 )'#10'1 ( 16 0 0 )'#10'2 ( 16 16 8 )'#10'}'#10;
  EDGES = 'edges 3 {'#10'0 ( 0 0 )'#10'1 ( 0 1 )'#10'2 ( 1 2 )'#10'}'#10;
  // face 1 has the edges 1, 2 and -1 (back); edge index 0 is a dummy
  EDGEINDEX = 'edgeIndex 4 {'#10'0 ( 0 )'#10'1 ( 1 )'#10'2 ( 2 )'#10'3 ( -1 )'#10'}'#10;
  FACES = 'faces 2 {'#10'0 ( 0 0 0 0 0 0 )'#10'1 ( 1 4 0 1 1 3 )'#10'}'#10;
  FACEINDEX = 'faceIndex 2 {'#10'0 ( 0 )'#10'1 ( -1 )'#10'}'#10;
  SHAPES = VERTICES + EDGES + EDGEINDEX + FACES + FACEINDEX;

{ TTestAasFileReader }

procedure TTestAasFileReader.Setup;
begin
  FReader := TAasFileFactory.CreateReader(TIdLibMemoryFileSystem.Create);
end;

function TTestAasFileReader.Parse(const ABody: AnsiString): TAasFile;
begin
  Result := FReader.ParseText(HEAD + ABody, 'test.aas48');
end;

procedure TTestAasFileReader.ExpectRawError(const AText: AnsiString; const AMessagePart: string);
var
  LFile: TAasFile;
  LRaised: Boolean;
begin
  LRaised := False;
  LFile := nil;
  try
    try
      LFile := FReader.ParseText(AText, 'test.aas48');
    except
      on E: EAasFileException do
      begin
        LRaised := True;
        Assert.IsTrue(Pos(AMessagePart, E.Message) > 0, 'message: ' + E.Message);
      end;
    end;
  finally
    LFile.Free;
  end;
  Assert.IsTrue(LRaised, 'no error for: ' + string(AText));
end;

procedure TTestAasFileReader.ExpectError(const ABody: AnsiString; const AMessagePart: string);
begin
  ExpectRawError(HEAD + ABody, AMessagePart);
end;

procedure TTestAasFileReader.DovrebbeLeggereUnFileSenzaSezioni;
var
  LFile: TAasFile;
begin
  LFile := Parse('');
  try
    Assert.AreEqual<Cardinal>(99, LFile.Crc);
    Assert.AreEqual(0, LFile.NumAreas);
    Assert.AreEqual(0, LFile.NumPlanes);
    Assert.AreEqual(0, LFile.NumNodes);
    Assert.AreEqual('test.aas48', string(LFile.Name));
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeDareLeImpostazioniPredefiniteSenzaSettings;
var
  LFile: TAasFile;
begin
  LFile := Parse('');
  try
    Assert.AreEqual(1, LFile.Settings.NumBoundingBoxes);
    Assert.AreEqual(72.0, Double(LFile.Settings.BoundingBoxes[0].Maxs.Z), 0);
    Assert.AreEqual('aas48', string(LFile.Settings.FileExtension));
    Assert.AreEqual(14.0, Double(LFile.Settings.MaxStepHeight), 0);
    Assert.AreEqual(100, LFile.Settings.WaterJumpTime);
    Assert.AreEqual(-1066.0, Double(LFile.Settings.Gravity.Z), 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeLeggereLeImpostazioni;
var
  LFile: TAasFile;
begin
  LFile := Parse('settings'#10'{'#10'bboxes'#10'{'#10'(-8 -8 0)-(8 8 40)'#10'(-4 -4 0)-(4 4 20)'#10'}'#10 +
    'usePatches = 1'#10'writeBrushMap = 1'#10'playerFlood = 1'#10'allowSwimReachabilities = 1'#10 +
    'allowFlyReachabilities = 1'#10'fileExtension = "aas32"'#10'maxStepHeight = 12.5'#10 +
    'maxBarrierHeight = 30'#10'maxWaterJumpHeight = 18'#10'maxFallHeight = 70'#10'minFloorCos = 0.5'#10 +
    'tt_barrierJump = 1'#10'tt_startCrouching = 2'#10'tt_waterJump = 3'#10'tt_startWalkOffLedge = 4'#10'}'#10);
  try
    Assert.AreEqual(2, LFile.Settings.NumBoundingBoxes);
    Assert.AreEqual(-8.0, Double(LFile.Settings.BoundingBoxes[0].Mins.X), 0);
    Assert.AreEqual(20.0, Double(LFile.Settings.BoundingBoxes[1].Maxs.Z), 0);
    Assert.IsTrue(LFile.Settings.UsePatches and LFile.Settings.WriteBrushMap and LFile.Settings.PlayerFlood);
    Assert.IsTrue(LFile.Settings.AllowSwimReachabilities and LFile.Settings.AllowFlyReachabilities);
    Assert.AreEqual('aas32', string(LFile.Settings.FileExtension));
    Assert.AreEqual(12.5, Double(LFile.Settings.MaxStepHeight), 0);
    Assert.AreEqual(0.5, Double(LFile.Settings.MinFloorCos), 0);
    Assert.AreEqual(1, LFile.Settings.BarrierJumpTime);
    Assert.AreEqual(4, LFile.Settings.StartWalkOffLedgeTime);
    Assert.IsTrue(LFile.Settings.ValidForBounds(TGeoBounds.Make(TGeoVec3.Make(-8, -8, 0), TGeoVec3.Make(8, 8, 40))));
    Assert.IsFalse(LFile.Settings.ValidForBounds(TGeoBounds.Make(TGeoVec3.Make(-9, -8, 0), TGeoVec3.Make(8, 8, 40))));
    Assert.IsFalse(LFile.Settings.ValidForBounds(TGeoBounds.Make(TGeoVec3.Make(-8, -8, 0), TGeoVec3.Make(8, 8, 41))));
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeDerivareLaDirezioneDellaGravita;
var
  LFile: TAasFile;
begin
  LFile := Parse('settings { bboxes { (0 0 0)-(1 1 1) } gravity = (0 0 -800) }'#10);
  try
    Assert.AreEqual(-800.0, Double(LFile.Settings.Gravity.Z), 0);
    Assert.AreEqual(-1.0, Double(LFile.Settings.GravityDir.Z), 1e-6);
    Assert.AreEqual(800.0, Double(LFile.Settings.GravityValue), 1e-3);
    Assert.AreEqual(1.0, Double(LFile.Settings.InvGravityDir.Z), 1e-6);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnaImpostazioneSconosciuta;
begin
  ExpectError('settings { bboxes { (0 0 0)-(1 1 1) } colour = 1 }'#10, 'invalid token ''colour''');
end;

procedure TTestAasFileReader.DovrebbeRifiutareTroppiBoundingBox;
begin
  ExpectError('settings { bboxes { (0 0 0)-(1 1 1) (0 0 0)-(1 1 1) (0 0 0)-(1 1 1) (0 0 0)-(1 1 1) ' +
    '(0 0 0)-(1 1 1) } }'#10, 'more than 4 bounding boxes');
end;

procedure TTestAasFileReader.DovrebbeRifiutareImpostazioniSenzaBoundingBox;
begin
  ExpectError('settings { bboxes { } }'#10, 'no valid bounding box');
end;

procedure TTestAasFileReader.DovrebbeLeggerePianiConLaDistanzaDelFile;
var
  LFile: TAasFile;
begin
  LFile := Parse('planes 2 {'#10'0 ( 0 0 0 0 )'#10'1 ( 0 0 1 32 )'#10'}'#10);
  try
    Assert.AreEqual(2, LFile.NumPlanes);
    // idPlane::SetDist: the fourth number of the file is the distance, d is its opposite
    Assert.AreEqual(-32.0, Double(LFile.Planes[1].D), 0);
    Assert.AreEqual(32.0, Double(LFile.Planes[1].Dist), 0);
    Assert.AreEqual(1.0, Double(LFile.Planes[1].C), 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeLeggereVerticiESpigoli;
var
  LFile: TAasFile;
begin
  LFile := Parse(SHAPES);
  try
    Assert.AreEqual(3, LFile.NumVertices);
    Assert.AreEqual(8.0, Double(LFile.Vertices[2].Z), 0);
    Assert.AreEqual(3, LFile.NumEdges);
    Assert.AreEqual(2, LFile.Edges[2].VertexNum[1]);
    Assert.AreEqual<TArray<Integer>>([0, 1, 2, -1], LFile.EdgeIndex);
    Assert.AreEqual(1, Integer(LFile.Faces[1].PlaneNum));
    Assert.AreEqual(4, Integer(LFile.Faces[1].Flags));
    Assert.AreEqual(3, LFile.Faces[1].NumEdges);
    Assert.AreEqual(1, LFile.Faces[1].FirstEdge);
    Assert.AreEqual<TArray<Integer>>([0, -1], LFile.FaceIndex);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeTroncareICampiStrettiComeIlC;
var
  LFile: TAasFile;
begin
  LFile := Parse('faces 2 {'#10'0 ( 0 0 0 0 0 0 )'#10'1 ( 65537 -1 40000 -40000 5 3 )'#10'}'#10);
  try
    Assert.AreEqual(1, Integer(LFile.Faces[1].PlaneNum));
    Assert.AreEqual(65535, Integer(LFile.Faces[1].Flags));
    Assert.AreEqual(-25536, Integer(LFile.Faces[1].Areas[0]));
    Assert.AreEqual(25536, Integer(LFile.Faces[1].Areas[1]));
  finally
    LFile.Free;
  end;
end;

const
  TWO_AREAS =
    'areas 3 {'#10 +
    '0 ( 0 1 0 0 0 0 ) 0 {'#10'}'#10 +
    '1 ( 1 0 0 0 1 1 ) 3 {'#10 +
    '2 2 (1 2 3) (4 5 6) 9 25'#10 +
    '2 2 (0 0 0) (1 1 1) 8 26'#10 +
    '4096 2 (7 8 9) (10 11 12) 7 27'#10'{'#10'"a" "b"'#10'}'#10 +
    '}'#10 +
    '2 ( 1 2 0 0 1 2 ) 1 {'#10 +
    '2 1 (0 0 0) (0 0 0) 6 28'#10 +
    '}'#10 +
    '}'#10;

procedure TTestAasFileReader.DovrebbeMettereLeReachabilityNellOrdineDellaCatenaDelC;
var
  LFile: TAasFile;
begin
  LFile := Parse(TWO_AREAS);
  try
    // the original puts each new one in front: the last of the file comes first
    Assert.AreEqual(3, LFile.Areas[1].Reach.Count);
    Assert.AreEqual(TFL_SPECIAL, LFile.Areas[1].Reach[0].TravelType);
    Assert.AreEqual(26, Integer(LFile.Areas[1].Reach[1].TravelTime));
    Assert.AreEqual(25, Integer(LFile.Areas[1].Reach[2].TravelTime));
    Assert.AreEqual(1, Integer(LFile.Areas[1].Reach[0].FromAreaNum));
    Assert.AreEqual(4.0, Double(LFile.Areas[1].Reach[2].EndPoint.X), 0);
    Assert.AreEqual(9, LFile.Areas[1].Reach[2].EdgeNum);
    Assert.AreEqual(4, LFile.NumReachabilities);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeCollegareLeReachabilityInverse;
var
  LFile: TAasFile;
begin
  LFile := Parse(TWO_AREAS);
  try
    // the four reachabilities lead to area 2 (three) and to area 1 (one)
    Assert.AreEqual(3, LFile.Areas[2].ReverseReach.Count);
    Assert.AreEqual(1, LFile.Areas[1].ReverseReach.Count);
    // area 2 is led to by the chain of area 1 in the order of that chain (special, 26, 25)... as the original
    // pushes in the order of the visit: the last one pushed comes first
    Assert.AreEqual(25, Integer(LFile.Areas[2].ReverseReach[0].TravelTime));
    Assert.AreEqual(1, Integer(LFile.Areas[1].ReverseReach[0].ToAreaNum));
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeLeggereLeCoppieDiUnaReachabilitySpeciale;
var
  LFile: TAasFile;
  LSpecial: TAasReachability;
begin
  LFile := Parse(TWO_AREAS);
  try
    LSpecial := LFile.Areas[1].Reach[0];
    Assert.IsNotNull(LSpecial.Special);
    Assert.AreEqual('b', string(LSpecial.Special.GetString('A')));
    Assert.IsNull(LFile.Areas[1].Reach[1].Special);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnaReachabilityVersoUnAreaCheNonEsiste;
begin
  ExpectError('areas 1 {'#10'0 ( 0 1 0 0 0 0 ) 1 {'#10'2 5 (0 0 0) (0 0 0) 0 1'#10'}'#10'}'#10, 'leads to area 5');
end;

procedure TTestAasFileReader.DovrebbeCalcolareIBoundsEIFlagDiViaggioDelleAree;
var
  LFile: TAasFile;
begin
  LFile := Parse(SHAPES + 'areas 3 {'#10'0 ( 0 1 0 0 0 0 ) 0 {'#10'}'#10'1 ( 0 0 1 1 1 1 ) 0 {'#10'}'#10 +
    '2 ( 0 2 0 0 1 2 ) 0 {'#10'}'#10'}'#10);
  try
    // face 1 gives the vertices 0, 1 and 1 (the entries 1, 2 and -1 of the edge index)
    Assert.AreEqual(0.0, Double(LFile.Areas[1].Bounds.Mins.X), 0);
    Assert.AreEqual(16.0, Double(LFile.Areas[1].Bounds.Maxs.X), 0);
    Assert.AreEqual(0.0, Double(LFile.Areas[1].Bounds.Maxs.Y), 0);
    Assert.AreEqual(0.0, Double(LFile.Areas[1].Bounds.Maxs.Z), 0);
    Assert.IsTrue(LFile.Areas[0].Bounds.IsCleared or (LFile.Areas[0].Bounds.Mins.X > LFile.Areas[0].Bounds.Maxs.X));
    Assert.AreEqual(TFL_AIR, LFile.Areas[1].TravelFlags);
    Assert.AreEqual(TFL_WATER, LFile.Areas[2].TravelFlags);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeCalcolareIlCentroDelleAree;
var
  LFile: TAasFile;
  LCenter: TGeoVec3;
begin
  LFile := Parse(SHAPES + 'areas 2 {'#10'0 ( 0 1 0 0 0 0 ) 0 {'#10'}'#10'1 ( 0 0 1 1 1 1 ) 0 {'#10'}'#10'}'#10);
  try
    // the face has three entries of the edge index: edges 1, 2 and 1 backwards; the vertices that
    // they give are 0, 1 and 1 (edge 1 backwards starts at its second vertex)
    LCenter := TAasGeometry.FaceCenter(LFile, 1);
    Assert.AreEqual(Double(Single(2.0) * (Single(1.0) / Single(3.0)) * 16), Double(LCenter.X), 1e-4);
    LCenter := TAasGeometry.AreaCenter(LFile, 1);
    Assert.AreEqual(Double(Single(2.0) * (Single(1.0) / Single(3.0)) * 16), Double(LCenter.X), 1e-4);
    LCenter := TAasGeometry.EdgeCenter(LFile, 2);
    Assert.AreEqual(16.0, Double(LCenter.X), 0);
    Assert.AreEqual(8.0, Double(LCenter.Y), 0);
    Assert.AreEqual(4.0, Double(LCenter.Z), 0);
    Assert.AreEqual(8.0, Double(TAasGeometry.EdgeBounds(LFile, -1).Maxs.X) / 2, 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeCalcolareLaProfonditaDellAlbero;
var
  LFile: TAasFile;
begin
  LFile := Parse('nodes 4 {'#10'0 ( 0 0 0 )'#10'1 ( 1 2 -1 )'#10'2 ( 1 3 0 )'#10'3 ( 1 -2 -3 )'#10'}'#10);
  try
    Assert.AreEqual(3, TAasGeometry.MaxTreeDepth(LFile));
  finally
    LFile.Free;
  end;
  LFile := Parse('nodes 2 {'#10'0 ( 0 0 0 )'#10'1 ( 1 0 -1 )'#10'}'#10);
  try
    Assert.AreEqual(1, TAasGeometry.MaxTreeDepth(LFile));
  finally
    LFile.Free;
  end;
  LFile := Parse('');
  try
    Assert.AreEqual(0, TAasGeometry.MaxTreeDepth(LFile));
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnAlberoConUnCiclo;
begin
  ExpectError('nodes 3 {'#10'0 ( 0 0 0 )'#10'1 ( 1 2 0 )'#10'2 ( 1 1 0 )'#10'}'#10 +
    'areas 0 {'#10'}'#10, 'reached twice');
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnFiglioFuoriDallaLista;
begin
  ExpectError('nodes 2 {'#10'0 ( 0 0 0 )'#10'1 ( 1 7 0 )'#10'}'#10, 'child 7 of the tree');
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnIndiceDiFacciaFuoriDallaLista;
begin
  ExpectError(SHAPES + 'areas 2 {'#10'0 ( 0 1 0 0 0 0 ) 0 {'#10'}'#10'1 ( 0 0 1 3 1 1 ) 0 {'#10'}'#10'}'#10,
    'face index 2 is not in 0..1');
  ExpectError(VERTICES + 'edges 1 {'#10'0 ( 9 0 )'#10'}'#10'edgeIndex 1 {'#10'0 ( 0 )'#10'}'#10 +
    'faces 1 {'#10'0 ( 0 0 0 0 0 1 )'#10'}'#10'faceIndex 1 {'#10'0 ( 0 )'#10'}'#10 +
    'areas 1 {'#10'0 ( 0 1 0 1 0 0 ) 0 {'#10'}'#10'}'#10, 'vertex 9 is not in 0..2');
end;

procedure TTestAasFileReader.DovrebbeSegnalareUnAlberoTroppoProfondoSenzaRifiutare;
var
  LLog: TIdLibLogRecorder;
  LReader: IAasFileReader;
  LFile: TAasFile;
  LText: string;
  LIndex: Integer;
begin
  LText := 'nodes 202 {'#10'0 ( 0 0 0 )'#10;
  for LIndex := 1 to 200 do
    LText := LText + Format('%d ( 1 %d 0 )'#10, [LIndex, LIndex + 1]);
  LText := LText + '201 ( 1 0 0 )'#10'}'#10;
  LLog := TIdLibLogRecorder.Create;
  LReader := TAasFileFactory.CreateReader(TIdLibMemoryFileSystem.Create, LLog);
  LFile := LReader.ParseText(HEAD + AnsiString(LText), 'x');
  try
    Assert.AreEqual(201, TAasGeometry.MaxTreeDepth(LFile));
    Assert.IsTrue(Pos('tree depth = 201', LLog.Entries.Text) > 0, LLog.Entries.Text);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnIdentificatoreSbagliato;
begin
  ExpectRawError('DewmAAT "1.07"'#10'5'#10, 'Not an AAS file');
  ExpectRawError('', 'Not an AAS file');
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnaVersioneSbagliata;
begin
  ExpectRawError('DewmAAS "1.06"'#10'5'#10, 'has version 1.06 instead of 1.07');
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnFileConUnaParolaSconosciuta;
begin
  ExpectError('bogus 1 {'#10'}'#10, 'bad token "bogus"');
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnFileTroncato;
begin
  ExpectError('planes 2 {'#10'0 ( 1 0 0 0 )'#10'1 ( 0 1', 'floating point');
  ExpectError('areas 1 {'#10'0 ( 0 1 0 0 0 0 ) 1 {'#10'2 0 (0 0 0) (0 0 0) 0 1'#10, 'expected');
  ExpectError('areas 1 {'#10'0 ( 0 1 0 0 0 0 ) 1 {'#10'4096 0 (0 0 0) (0 0 0) 0 1'#10'{'#10'"a" "b"'#10,
    'special reachability');
  ExpectRawError('DewmAAS "1.07"'#10'x'#10, 'expected');
end;

procedure TTestAasFileReader.DovrebbeRifiutareUnContoNegativoOEnorme;
begin
  ExpectError('planes -1 {'#10'}'#10, 'bad number of planes');
  ExpectError('vertices 2000000000 {'#10'}'#10, 'bad number of vertices');
  ExpectError('areas 1 {'#10'0 ( 0 1 0 0 0 0 ) -2 {'#10'}'#10'}'#10, 'bad number of reachabilities');
end;

procedure TTestAasFileReader.DovrebbeSegnalareUnFileFuoriData;
var
  LFile: TAasFile;
  LRaised: Boolean;
begin
  LRaised := False;
  LFile := nil;
  try
    try
      LFile := FReader.ParseText(HEAD, 'x', 5);
    except
      on E: EAasFileOutOfDateException do
        LRaised := True;
    end;
  finally
    LFile.Free;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestAasFileReader.DovrebbeAccettareUnCrcUgualeOZero;
var
  LFile: TAasFile;
begin
  LFile := FReader.ParseText(HEAD, 'x', 99);
  Assert.IsNotNull(LFile);
  LFile.Free;
  LFile := FReader.ParseText(HEAD, 'x', 0);
  Assert.IsNotNull(LFile);
  LFile.Free;
end;

procedure TTestAasFileReader.DovrebbeDireLaRigaDellErrore;
var
  LFile: TAasFile;
  LLine: Integer;
begin
  LLine := 0;
  LFile := nil;
  try
    try
      LFile := Parse(#10#10'bogus'#10);
    except
      on E: EMapFileException do
        LLine := E.Line;
    end;
  finally
    LFile.Free;
  end;
  Assert.AreEqual(6, LLine);
end;

procedure TTestAasFileReader.DovrebbeLeggereUnFileDalFileSystem;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LFile: TAasFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  FReader := TAasFileFactory.CreateReader(LFileSystem);
  LFileSystem.SetFile('maps/game/mars.aas48', HEAD);
  LFile := FReader.Parse('maps/game/mars.aas48');
  try
    Assert.IsNotNull(LFile);
    Assert.AreEqual('maps/game/mars.aas48', string(LFile.Name));
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileReader.DovrebbeDareNilSeIlFileNonEsiste;
begin
  Assert.IsNull(FReader.Parse('maps/game/none.aas48'));
end;

procedure TTestAasFileReader.DovrebbeLeggereLeSezioniInQualsiasiOrdine;
var
  LFile: TAasFile;
begin
  LFile := Parse('clusters 1 {'#10'0 ( 5 4 3 2 )'#10'}'#10'portals 1 {'#10'0 ( 1 2 3 4 5 )'#10'}'#10 +
    'portalIndex 1 {'#10'0 ( 7 )'#10'}'#10'nodes 1 {'#10'0 ( 6 -1 2 )'#10'}'#10);
  try
    Assert.AreEqual(5, LFile.Clusters[0].NumAreas);
    Assert.AreEqual(2, LFile.Clusters[0].NumPortals);
    Assert.AreEqual(1, Integer(LFile.Portals[0].AreaNum));
    Assert.AreEqual(5, Integer(LFile.Portals[0].ClusterAreaNum[1]));
    Assert.AreEqual(0, Integer(LFile.Portals[0].MaxAreaTravelTime));
    Assert.AreEqual(7, LFile.PortalIndex[0]);
    Assert.AreEqual(6, Integer(LFile.Nodes[0].PlaneNum));
    Assert.AreEqual(-1, LFile.Nodes[0].Children[0]);
  finally
    LFile.Free;
  end;
end;

end.
