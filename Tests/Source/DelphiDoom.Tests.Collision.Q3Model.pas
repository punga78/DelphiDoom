{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the collision library - the Quake III collision model: }
{  loading, position tests, brushes and traces on small worlds built in memory }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Q3Model;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf,
  DelphiDoom.Tests.Collision.Q3Support;

type
  /// <summary>A patch collide that lowers the fraction to 0.25 and always has a position hit</summary>
  TFakePatchCollide = class(TInterfacedObject, IQ3PatchCollide)
  public
    procedure TraceThrough(var AWork: TQ3TraceWork);
    function PositionTest(const AWork: TQ3TraceWork): Boolean;
  end;

  TFakePatchBuilder = class(TInterfacedObject, IQ3PatchCollideBuilder)
  public
    Calls: Integer;
    LastWidth: Integer;
    LastHeight: Integer;
    LastPoints: Integer;
    function Generate(const AWidth, AHeight: Integer; const APoints: TArray<TQ3Vec3>): IQ3PatchCollide;
  end;

  [TestFixture]
  [Category('Collision')]
  TTestQ3Model = class
  strict private
    function LoadModel(const ABytes: TBytes; const ABuilder: IQ3PatchCollideBuilder = nil): IQ3CollisionModel;
    function Room: IQ3CollisionModel;
    function RoomWithPatch(const ABuilder: IQ3PatchCollideBuilder): IQ3CollisionModel;
    procedure AssertNear(const AExpected, AActual: Single; const AMessage: string);
    function Raises(const AProc: TProc): Boolean;
    procedure AssertRaises(const AWriter: TQ3BspWriter; const AText: string);
  public
    [Test]
    procedure DovrebbeCaricareLeStanzeConIConteggiAttesi;
    [Test]
    procedure DovrebbeRifiutareUnPianoDiUnLatoFuoriDalLump;
    [Test]
    procedure DovrebbeRifiutareUnBrushCheLeggeLatiOltreLaFine;
    [Test]
    procedure DovrebbePrendereLimitiDaiLatiSeguentiPerUnBrushConMenoDiSeiLati;
    [Test]
    procedure DovrebbeRifiutareUnaPatchConTroppiVertici;
    [Test]
    procedure DovrebbeRifiutareUnaPatchConVerticiFuoriDalLump;
    [Test]
    procedure DovrebbeTrovareLaFoglia;
    [Test]
    procedure DovrebbeDareIContenutiDiUnPunto;
    [Test]
    procedure DovrebbeUsareLeFoglieDiUnModelloInterno;
    [Test]
    procedure DovrebbeElencareLeFoglieEIBrushDiUnBox;
    [Test]
    procedure DovrebbeSegnalareLOverflowDellaListaDelleFoglie;
    [Test]
    procedure DovrebbeFermareUnaTracciaPuntualeControUnBrush;
    [Test]
    procedure DovrebbeFermareUnBoxPrimaDelBrushPerLaSuaMisura;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoPerUnaCapsula;
    [Test]
    procedure DovrebbeIgnorareIBrushFuoriDallaMaschera;
    [Test]
    procedure DovrebbeDareStartSolidDentroUnBrush;
    [Test]
    procedure DovrebbeFarPartireUnaTracciaDaDentroIlBrushSenzaAllSolid;
    [Test]
    procedure DovrebbeRuotareLaTracciaDiUnModelloTrasformato;
    [Test]
    procedure DovrebbeDareLeStesseRisposteSenzaRotazione;
    [Test]
    procedure DovrebbeUsareUnBoxTemporaneo;
    [Test]
    procedure DovrebbeRifiutareLaManiglieDellaCapsulaCome254;
    [Test]
    procedure DovrebbeRifiutareManiglieNonValide;
    [Test]
    procedure DovrebbeUsareLaPatchDelCostruttoreNellaTraccia;
    [Test]
    procedure DovrebbeUsareLaPatchDelCostruttoreNelTestDiPosizione;
    [Test]
    procedure DovrebbeIgnorareLePatchConNoCurves;
    [Test]
    procedure DovrebbeFarCollidereLaPatchSoloSeIlCostruttoreLaDa;
    [Test]
    procedure DovrebbeConnetterePortaleEAree;
    [Test]
    procedure DovrebbeRifiutareUnConteggioDiPortaliNegativo;
    [Test]
    procedure DovrebbeScrivereIBitDelleAree;
    [Test]
    procedure DovrebbeDareLaVisibilitaDiUnaMappaSenzaVisibilita;
    [Test]
    procedure DovrebbeDareLaVisibilitaDelFile;
    [Test]
    procedure DovrebbeRifiutareNumeriDiFogliaNonValidi;
    [Test]
    procedure DovrebbeDareContatoriEStringaDelleEntita;
    [Test]
    procedure DovrebbeDareIlRisultatoVuotoSenzaMappaCaricata;
    [Test]
    procedure DovrebbeCalcolareIVettoriDegliAngoli;
    [Test]
    procedure DovrebbeDareIlLatoDiUnBoxSuUnPiano;
    [Test]
    procedure DovrebbeLeggereUnFileDalFileSystemIniettato;
  end;

implementation

uses
  System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.Intf,
  DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Collision.Q3.Factory, DelphiDoom.Collision.Q3.ClipMap,
  DelphiDoom.Collision.Q3.Loader, DelphiDoom.Collision.Q3.Model, DelphiDoom.Collision.Q3.Math;

const
  MASK_SOLID = 1;
  MASK_CLIP = $10000;

{ TFakePatchCollide }

procedure TFakePatchCollide.TraceThrough(var AWork: TQ3TraceWork);
begin
  if AWork.Trace.Fraction > 0.25 then
    AWork.Trace.Fraction := 0.25;
end;

function TFakePatchCollide.PositionTest(const AWork: TQ3TraceWork): Boolean;
begin
  Result := True;
end;

{ TFakePatchBuilder }

function TFakePatchBuilder.Generate(const AWidth, AHeight: Integer; const APoints: TArray<TQ3Vec3>): IQ3PatchCollide;
begin
  Inc(Calls);
  LastWidth := AWidth;
  LastHeight := AHeight;
  LastPoints := Length(APoints);
  Result := TFakePatchCollide.Create;
end;

{ TTestQ3Model }

function TTestQ3Model.LoadModel(const ABytes: TBytes; const ABuilder: IQ3PatchCollideBuilder): IQ3CollisionModel;
begin
  Result := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, ABytes, 'test.bsp', ABuilder);
end;

function TTestQ3Model.Room: IQ3CollisionModel;
begin
  Result := LoadModel(BuildRoomBsp);
end;

function TTestQ3Model.RoomWithPatch(const ABuilder: IQ3PatchCollideBuilder): IQ3CollisionModel;
var
  LWriter: TQ3BspWriter;
begin
  LWriter := NewRoomWriter;
  try
    // a patch of shader 2 (player clip, surface flags $20) in the empty leaf
    LWriter.AddPatch(3, 3, 2, 0, 0, 40);
    LWriter.Leafs[2].NumLeafSurfaces := 1;
    SetLength(LWriter.LeafSurfaces, 1);
    LWriter.LeafSurfaces[0] := 0;
    Result := LoadModel(LWriter.Build, ABuilder);
  finally
    LWriter.Free;
  end;
end;

procedure TTestQ3Model.AssertNear(const AExpected, AActual: Single; const AMessage: string);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual), 0.00001, AMessage);
end;

function TTestQ3Model.Raises(const AProc: TProc): Boolean;
begin
  Result := False;
  try
    AProc;
  except
    on EQ3CollisionException do
      Result := True;
  end;
end;

procedure TTestQ3Model.AssertRaises(const AWriter: TQ3BspWriter; const AText: string);
var
  LMessage: string;
begin
  LMessage := '';
  try
    LoadModel(AWriter.Build);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(Pos(AText, LMessage) > 0, 'message: "' + LMessage + '", expected "' + AText + '"');
end;

procedure TTestQ3Model.DovrebbeCaricareLeStanzeConIConteggiAttesi;
var
  LModel: IQ3CollisionModel;
begin
  LModel := Room;
  Assert.AreEqual(2, LModel.NumClusters);
  Assert.AreEqual(2, LModel.NumAreas);
  Assert.AreEqual(1, LModel.NumInlineModels);
  Assert.AreEqual('{'#10'"classname" "worldspawn"'#10'}'#10, string(LModel.EntityString));
  Assert.AreEqual(0, LModel.InlineModel(0));
end;

procedure TTestQ3Model.DovrebbeRifiutareUnPianoDiUnLatoFuoriDalLump;
var
  LWriter: TQ3BspWriter;
begin
  LWriter := NewRoomWriter;
  try
    LWriter.BrushSides[3].PlaneNum := 999;
    AssertRaises(LWriter, 'outside');
  finally
    LWriter.Free;
  end;
end;

procedure TTestQ3Model.DovrebbeRifiutareUnBrushCheLeggeLatiOltreLaFine;
var
  LWriter: TQ3BspWriter;
begin
  LWriter := NewRoomWriter;
  try
    // the last brush starts two sides before the end: the six axial sides are not all there
    LWriter.Brushes[1].FirstSide := Length(LWriter.BrushSides) - 2;
    LWriter.Brushes[1].NumSides := 2;
    AssertRaises(LWriter, 'six axial sides');
  finally
    LWriter.Free;
  end;
end;

procedure TTestQ3Model.DovrebbePrendereLimitiDaiLatiSeguentiPerUnBrushConMenoDiSeiLati;
var
  LWriter: TQ3BspWriter;
  LBytes: TBytes;
  LMap: TQ3ClipMap;
  LLoader: TQ3ClipMapLoader;
begin
  LWriter := NewRoomWriter;
  try
    // as the original: the bounds of brush 0 come from its sides 0..5, whatever NumSides says
    LWriter.Brushes[0].NumSides := 3;
    LBytes := LWriter.Build;
  finally
    LWriter.Free;
  end;
  LLoader := TQ3ClipMapLoader.Create(TBspFactory.CreateValidator, nil);
  try
    LMap := LLoader.Load(TBspFactory.CreateReader.ParseBytes(LBytes, 'a'), 'a');
    try
      Assert.AreEqual(3, LMap.Brushes[0].NumSides);
      AssertNear(-1000, LMap.Brushes[0].Bounds[0][0], 'min x');
      AssertNear(1000, LMap.Brushes[0].Bounds[1][0], 'max x');
      AssertNear(-64, LMap.Brushes[0].Bounds[0][2], 'min z');
      AssertNear(0, LMap.Brushes[0].Bounds[1][2], 'max z');
    finally
      LMap.Free;
    end;
  finally
    LLoader.Free;
  end;
end;

procedure TTestQ3Model.DovrebbeRifiutareUnaPatchConTroppiVertici;
var
  LWriter: TQ3BspWriter;
  LLoader: TQ3ClipMapLoader;
  LMessage: string;
begin
  LWriter := NewRoomWriter;
  try
    LWriter.AddPatch(33, 33, 2, 0, 0, 0);
    LLoader := TQ3ClipMapLoader.Create(nil, nil);
    try
      LMessage := '';
      try
        LLoader.Load(TBspFactory.CreateReader.ParseBytes(LWriter.Build, 'a'), 'a').Free;
      except
        on E: EQ3CollisionException do
          LMessage := E.Message;
      end;
      Assert.AreEqual('ParseMesh: MAX_PATCH_VERTS', LMessage);
    finally
      LLoader.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

procedure TTestQ3Model.DovrebbeRifiutareUnaPatchConVerticiFuoriDalLump;
var
  LWriter: TQ3BspWriter;
  LLoader: TQ3ClipMapLoader;
  LMessage: string;
begin
  LWriter := NewRoomWriter;
  try
    LWriter.AddPatch(3, 3, 2, 0, 0, 0);
    LWriter.Surfaces[0].FirstVert := 100000;
    LLoader := TQ3ClipMapLoader.Create(nil, nil);
    try
      LMessage := '';
      try
        LLoader.Load(TBspFactory.CreateReader.ParseBytes(LWriter.Build, 'a'), 'a').Free;
      except
        on E: EQ3CollisionException do
          LMessage := E.Message;
      end;
      Assert.IsTrue(Pos('surface 0 has 9 vertices', LMessage) > 0, LMessage);
    finally
      LLoader.Free;
    end;
  finally
    LWriter.Free;
  end;
end;

procedure TTestQ3Model.DovrebbeTrovareLaFoglia;
var
  LModel: IQ3CollisionModel;
begin
  LModel := Room;
  Assert.AreEqual(0, LModel.PointLeafnum(Vec(0, 0, -10)), 'floor');
  Assert.AreEqual(1, LModel.PointLeafnum(Vec(120, 0, 10)), 'pillar leaf');
  Assert.AreEqual(2, LModel.PointLeafnum(Vec(0, 0, 10)), 'empty leaf');
  // a point on the plane is in front of it (d = 0 is not below)
  Assert.AreEqual(2, LModel.PointLeafnum(Vec(0, 0, 0)), 'on the plane');
  Assert.IsTrue(LModel.PointContentsCount >= 4, 'counter');
end;

procedure TTestQ3Model.DovrebbeDareIContenutiDiUnPunto;
var
  LModel: IQ3CollisionModel;
begin
  LModel := Room;
  Assert.AreEqual(MASK_SOLID, LModel.PointContents(Vec(0, 0, -10), 0), 'in the floor');
  Assert.AreEqual(MASK_SOLID, LModel.PointContents(Vec(116, 0, 50), 0), 'in the pillar');
  Assert.AreEqual(0, LModel.PointContents(Vec(200, 0, 50), 0), 'in the leaf of the pillar, outside it');
  Assert.AreEqual(0, LModel.PointContents(Vec(0, 0, 50), 0), 'in the air');
  // the surface of the floor belongs to the leaf in front of it, which has no brush
  Assert.AreEqual(0, LModel.PointContents(Vec(0, 0, 0), 0), 'on the floor');
  // on a plane of a brush the point is inside (the original tests with > and not >=)
  Assert.AreEqual(MASK_SOLID, LModel.PointContents(Vec(0, 0, -64), 0), 'on the bottom plane');
end;

procedure TTestQ3Model.DovrebbeUsareLeFoglieDiUnModelloInterno;
var
  LWriter: TQ3BspWriter;
  LModel: IQ3CollisionModel;
  LMins, LMaxs: TQ3Vec3;
  LTrace: TQ3Trace;
begin
  LWriter := NewRoomWriter;
  try
    LWriter.AddModel(0, 2, 0, 0);
    LWriter.AddModel(1, 1, 0, 0); // the model 1 holds the pillar
    LModel := LoadModel(LWriter.Build);
  finally
    LWriter.Free;
  end;
  Assert.AreEqual(2, LModel.NumInlineModels);
  Assert.AreEqual(MASK_SOLID, LModel.PointContents(Vec(116, 0, 50), 1), 'in the model');
  Assert.AreEqual(0, LModel.PointContents(Vec(0, 0, 50), 1), 'outside the model');
  LModel.ModelBounds(1, LMins, LMaxs);
  AssertNear(-101, LMins[0], 'mins is spread by one unit');
  AssertNear(101, LMaxs[2], 'maxs is spread by one unit');
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 1, MASK_SOLID, False);
  AssertNear(0.332916, LTrace.Fraction, 'trace in the model');
end;

procedure TTestQ3Model.DovrebbeElencareLeFoglieEIBrushDiUnBox;
var
  LModel: IQ3CollisionModel;
  LLeafs: TArray<Integer>;
  LBrushes: TArray<Integer>;
  LLast, LCount: Integer;
begin
  LModel := Room;
  LCount := LModel.BoxLeafnums(Vec(-10, -10, -10), Vec(110, 10, 10), 8, LLeafs, LLast);
  Assert.AreEqual(3, LCount, 'the box crosses the three leaves');
  Assert.AreEqual<Integer>(3, Length(LLeafs));
  Assert.AreEqual(2, LLast, 'the last leaf that is not solid');
  LBrushes := LModel.BoxBrushes(Vec(-10, -10, -10), Vec(110, 10, 10), 8);
  Assert.AreEqual<Integer>(2, Length(LBrushes), 'floor and pillar');
  LBrushes := LModel.BoxBrushes(Vec(-10, -10, 10), Vec(50, 10, 20), 8);
  Assert.AreEqual<Integer>(0, Length(LBrushes), 'nothing touches');
end;

procedure TTestQ3Model.DovrebbeSegnalareLOverflowDellaListaDelleFoglie;
var
  LModel: IQ3CollisionModel;
  LLeafs: TArray<Integer>;
  LLast, LCount: Integer;
begin
  LModel := Room;
  LCount := LModel.BoxLeafnums(Vec(-10, -10, -10), Vec(110, 10, 10), 1, LLeafs, LLast);
  Assert.AreEqual(1, LCount);
  Assert.AreEqual(2, LLast, 'the last leaf is stored also after the overflow');
  LCount := LModel.BoxLeafnums(Vec(-10, -10, -10), Vec(110, 10, 10), -5, LLeafs, LLast);
  Assert.AreEqual(0, LCount);
  LCount := LModel.BoxBrushes(Vec(-10, -10, -10), Vec(110, 10, 10), 1)[0];
  Assert.AreEqual(1, LCount, 'the first brush found is the pillar');
end;

procedure TTestQ3Model.DovrebbeFermareUnaTracciaPuntualeControUnBrush;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := Room;
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_SOLID, False);
  AssertNear((100 - 0.125) / 300, LTrace.Fraction, 'fraction');
  AssertNear(-1, LTrace.Plane.Normal[0], 'normal');
  Assert.AreEqual(MASK_SOLID, LTrace.Contents);
  Assert.IsFalse(LTrace.StartSolid);
  AssertNear(Single(0 + LTrace.Fraction * 300), LTrace.EndPos[0], 'endpos');

  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(0, 0, -50), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_SOLID, False);
  AssertNear((50 - 0.125) / 100, LTrace.Fraction, 'floor');
  AssertNear(1, LTrace.Plane.Normal[2], 'floor normal');
  Assert.AreEqual(Byte(Q3_PLANE_Z), LTrace.Plane.PlaneType);

  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(0, 0, 80), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_SOLID, False);
  AssertNear(1, LTrace.Fraction, 'no hit');
  AssertNear(80, LTrace.EndPos[2], 'endpos of a trace that does not hit');
  Assert.IsTrue(LModel.TraceCount >= 3);
  Assert.AreEqual(2, LModel.BrushTraceCount, 'the pillar and the floor');
end;

procedure TTestQ3Model.DovrebbeFermareUnBoxPrimaDelBrushPerLaSuaMisura;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := Room;
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(-8, -8, -8), Vec(8, 8, 8), 0, MASK_SOLID, False);
  AssertNear((92 - 0.125) / 300, LTrace.Fraction, 'box of 16');
  // an asymmetric box is moved to its centre and gives the same stop for its own extent
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(-4, -8, -8), Vec(12, 8, 8), 0, MASK_SOLID, False);
  AssertNear((88 - 0.125) / 300, LTrace.Fraction, 'asymmetric box');
end;

procedure TTestQ3Model.DovrebbeDareLoStessoRisultatoPerUnaCapsula;
var
  LModel: IQ3CollisionModel;
  LBox, LCapsule: TQ3Trace;
begin
  LModel := Room;
  LBox := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(-8, -8, -8), Vec(8, 8, 8), 0, MASK_SOLID, False);
  LCapsule := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(-8, -8, -8), Vec(8, 8, 8), 0, MASK_SOLID, True);
  AssertNear(LBox.Fraction, LCapsule.Fraction, 'capsule against a flat side');
  // a capsule that is higher than wide: it rests on the floor with the end of its axis
  LCapsule := LModel.BoxTrace(Vec(0, 0, 50), Vec(0, 0, -50), Vec(-8, -8, -24), Vec(8, 8, 24), 0, MASK_SOLID, True);
  AssertNear((26 - 0.125) / 100, LCapsule.Fraction, 'capsule on the floor');
  // and it is solid at the start inside the floor
  LCapsule := LModel.BoxTrace(Vec(0, 0, -10), Vec(0, 0, -10), Vec(-8, -8, -24), Vec(8, 8, 24), 0, MASK_SOLID, True);
  Assert.IsTrue(LCapsule.AllSolid, 'position test of a capsule');
end;

procedure TTestQ3Model.DovrebbeIgnorareIBrushFuoriDallaMaschera;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := Room;
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, 32, False);
  AssertNear(1, LTrace.Fraction, 'water mask: nothing');
  LTrace := LModel.BoxTrace(Vec(0, 0, -10), Vec(0, 0, -10), Vec(0, 0, 0), Vec(0, 0, 0), 0, 32, False);
  Assert.IsFalse(LTrace.AllSolid, 'the position test also skips the brush');
end;

procedure TTestQ3Model.DovrebbeDareStartSolidDentroUnBrush;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := Room;
  LTrace := LModel.BoxTrace(Vec(0, 0, -10), Vec(0, 0, -10), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_SOLID, False);
  Assert.IsTrue(LTrace.AllSolid);
  Assert.IsTrue(LTrace.StartSolid);
  AssertNear(0, LTrace.Fraction, 'fraction');
  Assert.AreEqual(MASK_SOLID, LTrace.Contents);
  // a box that touches the pillar with its side
  LTrace := LModel.BoxTrace(Vec(95, 0, 50), Vec(95, 0, 50), Vec(-8, -8, -8), Vec(8, 8, 8), 0, MASK_SOLID, False);
  Assert.IsTrue(LTrace.AllSolid, 'box inside the pillar');
  LTrace := LModel.BoxTrace(Vec(80, 0, 50), Vec(80, 0, 50), Vec(-8, -8, -8), Vec(8, 8, 8), 0, MASK_SOLID, False);
  Assert.IsFalse(LTrace.AllSolid, 'box in front of the pillar');
end;

procedure TTestQ3Model.DovrebbeFarPartireUnaTracciaDaDentroIlBrushSenzaAllSolid;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := Room;
  // from inside the floor to above it: it starts solid, but the end is free
  LTrace := LModel.BoxTrace(Vec(0, 0, -10), Vec(0, 0, 40), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_SOLID, False);
  Assert.IsTrue(LTrace.StartSolid);
  Assert.IsFalse(LTrace.AllSolid);
  AssertNear(1, LTrace.Fraction, 'it is not stopped');
end;

procedure TTestQ3Model.DovrebbeRuotareLaTracciaDiUnModelloTrasformato;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := Room;
  // yaw 90: the world +y is the +x of the model: the pillar is hit going to +y
  LTrace := LModel.TransformedBoxTrace(Vec(0, 0, 50), Vec(0, 300, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0,
    MASK_SOLID, Vec(0, 0, 0), Vec(0, 90, 0), False);
  AssertNear((100 - 0.125) / 300, LTrace.Fraction, 'fraction');
  AssertNear(-1, LTrace.Plane.Normal[1], 'the normal is back in the world frame');
  AssertNear(0, LTrace.Plane.Normal[0], 'the normal has no x');
  AssertNear(Single(0 + LTrace.Fraction * 300), LTrace.EndPos[1], 'endpos from the original points');
  // transformed point contents with the same rotation: the pillar is at world y 100..132
  Assert.AreEqual(MASK_SOLID, LModel.TransformedPointContents(Vec(0, 116, 50), 0, Vec(0, 0, 0), Vec(0, 90, 0)));
  Assert.AreEqual(0, LModel.TransformedPointContents(Vec(116, 0, 50), 0, Vec(0, 0, 0), Vec(0, 90, 0)));
end;

procedure TTestQ3Model.DovrebbeDareLeStesseRisposteSenzaRotazione;
var
  LModel: IQ3CollisionModel;
  LPlain, LMoved: TQ3Trace;
begin
  LModel := Room;
  LPlain := LModel.BoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(-8, -8, -8), Vec(8, 8, 8), 0, MASK_SOLID, False);
  LMoved := LModel.TransformedBoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(-8, -8, -8), Vec(8, 8, 8), 0,
    MASK_SOLID, Vec(0, 0, 0), Vec(0, 0, 0), False);
  AssertNear(LPlain.Fraction, LMoved.Fraction, 'fraction');
  // an origin moves the model: the pillar at x 100 is found at x 150 with an origin of 50
  LMoved := LModel.TransformedBoxTrace(Vec(0, 0, 50), Vec(300, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0,
    MASK_SOLID, Vec(50, 0, 0), Vec(0, 0, 0), False);
  AssertNear((150 - 0.125) / 300, LMoved.Fraction, 'moved');
  Assert.AreEqual(MASK_SOLID, LModel.TransformedPointContents(Vec(166, 0, 50), 0, Vec(50, 0, 0), Vec(0, 0, 0)));
end;

procedure TTestQ3Model.DovrebbeUsareUnBoxTemporaneo;
var
  LModel: IQ3CollisionModel;
  LHandle: Integer;
  LTrace: TQ3Trace;
  LMins, LMaxs: TQ3Vec3;
begin
  LModel := Room;
  LHandle := LModel.TempBoxModel(Vec(-8, -8, -8), Vec(8, 8, 8), False);
  Assert.AreEqual(Q3_BOX_MODEL_HANDLE, LHandle);
  LModel.ModelBounds(LHandle, LMins, LMaxs);
  AssertNear(-8, LMins[1], 'bounds');
  Assert.AreEqual(Q3_CONTENTS_BODY, LModel.PointContents(Vec(0, 0, 0), LHandle), 'inside the box');
  Assert.AreEqual(0, LModel.PointContents(Vec(20, 0, 0), LHandle), 'outside the box');
  LTrace := LModel.BoxTrace(Vec(-100, 0, 0), Vec(100, 0, 0), Vec(0, 0, 0), Vec(0, 0, 0), LHandle,
    Q3_CONTENTS_BODY, False);
  AssertNear((92 - 0.125) / 200, LTrace.Fraction, 'trace against the box');
  // rotation is not applied to a box model
  Assert.AreEqual(Q3_CONTENTS_BODY, LModel.TransformedPointContents(Vec(0, 0, 0), LHandle, Vec(0, 0, 0),
    Vec(0, 45, 0)));
  LTrace := LModel.BoxTrace(Vec(0, 0, 0), Vec(0, 0, 0), Vec(-1, -1, -1), Vec(1, 1, 1), LHandle,
    Q3_CONTENTS_BODY, False);
  Assert.IsTrue(LTrace.AllSolid, 'position test in the box');
end;

procedure TTestQ3Model.DovrebbeRifiutareLaManiglieDellaCapsulaCome254;
var
  LModel: IQ3CollisionModel;
  LHandle: Integer;
  LRaised: Boolean;
begin
  LModel := Room;
  LHandle := LModel.TempBoxModel(Vec(-8, -8, -8), Vec(8, 8, 8), True);
  Assert.AreEqual(Q3_CAPSULE_MODEL_HANDLE, LHandle);
  LRaised := False;
  try
    LModel.BoxTrace(Vec(0, 0, 0), Vec(1, 0, 0), Vec(0, 0, 0), Vec(0, 0, 0), LHandle, 1, True);
  except
    on EQ3CollisionException do
      LRaised := True;
  end;
  // the original has no case for the handle in CM_ClipHandleToModel: ERR_DROP
  Assert.IsTrue(LRaised);
end;

procedure TTestQ3Model.DovrebbeRifiutareManiglieNonValide;
var
  LModel: IQ3CollisionModel;
  LMins, LMaxs: TQ3Vec3;
  LMessage: string;
begin
  LModel := Room;
  LMessage := '';
  try
    LModel.ModelBounds(-1, LMins, LMaxs);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('CM_ClipHandleToModel: bad handle -1', LMessage);
  LMessage := '';
  try
    LModel.ModelBounds(5, LMins, LMaxs);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('CM_ClipHandleToModel: bad handle 1 < 5 < 256', LMessage);
  LMessage := '';
  try
    LModel.ModelBounds(300, LMins, LMaxs);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('CM_ClipHandleToModel: bad handle 556', LMessage);
  LMessage := '';
  try
    LModel.InlineModel(1);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('CM_InlineModel: bad number', LMessage);
end;

procedure TTestQ3Model.DovrebbeUsareLaPatchDelCostruttoreNellaTraccia;
var
  LBuilder: TFakePatchBuilder;
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LBuilder := TFakePatchBuilder.Create;
  LModel := RoomWithPatch(LBuilder);
  Assert.AreEqual(1, LBuilder.Calls);
  Assert.AreEqual(3, LBuilder.LastWidth);
  Assert.AreEqual(3, LBuilder.LastHeight);
  Assert.AreEqual(9, LBuilder.LastPoints);
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(50, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_CLIP, False);
  AssertNear(0.25, LTrace.Fraction, 'the patch lowers the fraction');
  Assert.AreEqual(MASK_CLIP, LTrace.Contents, 'contents of the patch');
  Assert.AreEqual($20, LTrace.SurfaceFlags, 'flags of the patch');
  Assert.AreEqual(1, LModel.PatchTraceCount);
  // a patch is tested once per trace
  LModel.BoxTrace(Vec(0, 0, 50), Vec(50, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_CLIP, False);
  Assert.AreEqual(2, LModel.PatchTraceCount);
  // the mask does not include the patch
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(50, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_SOLID, False);
  AssertNear(1, LTrace.Fraction, 'the mask');
end;

procedure TTestQ3Model.DovrebbeUsareLaPatchDelCostruttoreNelTestDiPosizione;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := RoomWithPatch(TFakePatchBuilder.Create);
  LTrace := LModel.BoxTrace(Vec(10, 0, 50), Vec(10, 0, 50), Vec(-2, -2, -2), Vec(2, 2, 2), 0, MASK_CLIP, False);
  Assert.IsTrue(LTrace.AllSolid);
  AssertNear(0, LTrace.Fraction, 'fraction');
  Assert.AreEqual(MASK_CLIP, LTrace.Contents);
end;

procedure TTestQ3Model.DovrebbeIgnorareLePatchConNoCurves;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := RoomWithPatch(TFakePatchBuilder.Create);
  LModel.NoCurves := True;
  Assert.IsTrue(LModel.NoCurves);
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(50, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_CLIP, False);
  AssertNear(1, LTrace.Fraction, 'trace');
  LTrace := LModel.BoxTrace(Vec(10, 0, 50), Vec(10, 0, 50), Vec(-2, -2, -2), Vec(2, 2, 2), 0, MASK_CLIP, False);
  Assert.IsFalse(LTrace.AllSolid, 'position');
end;

procedure TTestQ3Model.DovrebbeFarCollidereLaPatchSoloSeIlCostruttoreLaDa;
var
  LModel: IQ3CollisionModel;
  LTrace: TQ3Trace;
begin
  LModel := RoomWithPatch(nil);
  LTrace := LModel.BoxTrace(Vec(0, 0, 50), Vec(50, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, MASK_CLIP, False);
  AssertNear(1, LTrace.Fraction, 'no builder, no collision');
  Assert.AreEqual(1, LModel.PatchTraceCount, 'the patch is still visited');
  LTrace := LModel.BoxTrace(Vec(10, 0, 50), Vec(10, 0, 50), Vec(-2, -2, -2), Vec(2, 2, 2), 0, MASK_CLIP, False);
  Assert.IsFalse(LTrace.AllSolid);
end;

procedure TTestQ3Model.DovrebbeConnetterePortaleEAree;
var
  LModel: IQ3CollisionModel;
begin
  LModel := Room;
  Assert.IsFalse(LModel.AreasConnected(0, 1), 'closed at first');
  Assert.IsTrue(LModel.AreasConnected(1, 1));
  Assert.IsFalse(LModel.AreasConnected(-1, 0), 'a negative area is not connected');
  LModel.AdjustAreaPortalState(0, 1, True);
  Assert.IsTrue(LModel.AreasConnected(0, 1), 'open');
  LModel.AdjustAreaPortalState(0, 1, False);
  Assert.IsFalse(LModel.AreasConnected(0, 1), 'closed');
  LModel.AdjustAreaPortalState(-1, 1, True); // ignored
  LModel.NoAreas := True;
  Assert.IsTrue(LModel.NoAreas);
  Assert.IsTrue(LModel.AreasConnected(0, 1), 'cm_noAreas');
end;

procedure TTestQ3Model.DovrebbeRifiutareUnConteggioDiPortaliNegativo;
var
  LModel: IQ3CollisionModel;
  LMessage: string;
begin
  LModel := Room;
  LMessage := '';
  try
    LModel.AdjustAreaPortalState(0, 1, False);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('CM_AdjustAreaPortalState: negative reference count', LMessage);
  LMessage := '';
  try
    LModel.AdjustAreaPortalState(0, 5, True);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('CM_ChangeAreaPortalState: bad area number', LMessage);
  LMessage := '';
  try
    LModel.AreasConnected(0, 5);
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('area >= cm.numAreas', LMessage);
end;

procedure TTestQ3Model.DovrebbeScrivereIBitDelleAree;
var
  LModel: IQ3CollisionModel;
  LBuffer: TBytes;
begin
  LModel := Room;
  Assert.AreEqual(1, LModel.WriteAreaBits(LBuffer, 0), 'the buffer is made long enough');
  Assert.AreEqual(Byte(1), LBuffer[0], 'area 0 is alone');
  LModel.AdjustAreaPortalState(0, 1, True);
  LBuffer[0] := $80;
  LModel.WriteAreaBits(LBuffer, 1);
  Assert.AreEqual(Byte($83), LBuffer[0], 'the bits are ORed in');
  LModel.WriteAreaBits(LBuffer, -1);
  Assert.AreEqual(Byte(255), LBuffer[0], 'everything for -1');
  LBuffer[0] := 0;
  Assert.IsTrue(Raises(
    procedure
    begin
      LModel.WriteAreaBits(LBuffer, 7);
    end));
end;

procedure TTestQ3Model.DovrebbeDareLaVisibilitaDiUnaMappaSenzaVisibilita;
var
  LModel: IQ3CollisionModel;
  LRow: TBytes;
  LIndex: Integer;
begin
  LModel := Room;
  LRow := LModel.ClusterPVS(1);
  // as the original: (clusters + 31) & ~31 bytes of 255
  Assert.AreEqual(32, Integer(Length(LRow)));
  for LIndex := 0 to High(LRow) do
    Assert.AreEqual(Byte(255), LRow[LIndex]);
  Assert.AreEqual(32, Integer(Length(LModel.ClusterPVS(-1))));
end;

procedure TTestQ3Model.DovrebbeDareLaVisibilitaDelFile;
var
  LWriter: TQ3BspWriter;
  LModel: IQ3CollisionModel;
  LRow: TBytes;
begin
  LWriter := NewRoomWriter;
  try
    // two clusters of one byte: 8, 4 clusters
    SetLength(LWriter.Visibility, 8 + 2);
    PInteger(@LWriter.Visibility[0])^ := 2;
    PInteger(@LWriter.Visibility[4])^ := 1;
    LWriter.Visibility[8] := $0F;
    LWriter.Visibility[9] := $F0;
    LModel := LoadModel(LWriter.Build);
  finally
    LWriter.Free;
  end;
  LRow := LModel.ClusterPVS(1);
  Assert.AreEqual(1, Integer(Length(LRow)));
  Assert.AreEqual(Byte($F0), LRow[0]);
  Assert.AreEqual(Byte($0F), LModel.ClusterPVS(0)[0]);
  Assert.AreEqual(Byte($0F), LModel.ClusterPVS(9)[0], 'a cluster out of range gives the first row');
end;

procedure TTestQ3Model.DovrebbeRifiutareNumeriDiFogliaNonValidi;
var
  LModel: IQ3CollisionModel;
begin
  LModel := Room;
  Assert.AreEqual(-1, LModel.LeafCluster(0));
  Assert.AreEqual(1, LModel.LeafCluster(2));
  Assert.AreEqual(1, LModel.LeafArea(2));
  Assert.IsTrue(Raises(
    procedure
    begin
      LModel.LeafCluster(3);
    end));
  Assert.IsTrue(Raises(
    procedure
    begin
      LModel.LeafArea(-1);
    end));
end;

procedure TTestQ3Model.DovrebbeDareContatoriEStringaDelleEntita;
var
  LModel: IQ3CollisionModel;
begin
  LModel := Room;
  Assert.AreEqual(0, LModel.TraceCount);
  LModel.BoxTrace(Vec(0, 0, 50), Vec(1, 0, 50), Vec(0, 0, 0), Vec(0, 0, 0), 0, 1, False);
  Assert.AreEqual(1, LModel.TraceCount);
  Assert.AreEqual(0, LModel.PatchTraceCount);
end;

procedure TTestQ3Model.DovrebbeDareIlRisultatoVuotoSenzaMappaCaricata;
var
  LMap: TQ3ClipMap;
  LModel: IQ3CollisionModel;
  LList: TArray<Integer>;
  LLast: Integer;
begin
  LMap := TQ3ClipMap.Create;
  LModel := TQ3CollisionModel.Create(LMap);
  Assert.AreEqual(0, LModel.PointLeafnum(Vec(1, 2, 3)));
  Assert.AreEqual(0, LModel.PointContents(Vec(1, 2, 3), 0));
  Assert.AreEqual(0, LModel.NumClusters);
  Assert.AreEqual(0, LModel.BoxLeafnums(Vec(0, 0, 0), Vec(1, 1, 1), 0, LList, LLast));
  Assert.IsTrue(Raises(
    procedure
    begin
      LModel.TempBoxModel(Vec(0, 0, 0), Vec(1, 1, 1), False);
    end));
  // the trace needs a model first: the original raises for the handle 0 of an empty map
  Assert.IsTrue(Raises(
    procedure
    begin
      LModel.BoxTrace(Vec(0, 0, 0), Vec(1, 1, 1), Vec(0, 0, 0), Vec(0, 0, 0), 0, 1, False);
    end));
  // with one model the default trace comes back
  SetLength(LMap.Models, 1);
  LMap.NumSubModels := 1;
  Assert.AreEqual(Single(1.0), LModel.BoxTrace(Vec(0, 0, 0), Vec(1, 1, 1), Vec(0, 0, 0), Vec(0, 0, 0), 0, 1,
    False).Fraction);
end;

procedure TTestQ3Model.DovrebbeCalcolareIVettoriDegliAngoli;
var
  LForward, LRight, LUp: TQ3Vec3;
  LMatrix, LTranspose: TQ3Mat3;
  LPoint: TQ3Vec3;
begin
  TQ3Math.AngleVectors(Vec(0, 90, 0), LForward, LRight, LUp);
  AssertNear(0, LForward[0], 'forward x');
  AssertNear(1, LForward[1], 'forward y');
  AssertNear(1, LRight[0], 'right x');
  AssertNear(1, LUp[2], 'up z');
  TQ3Math.CreateRotationMatrix(Vec(0, 90, 0), LMatrix);
  AssertNear(-1, LMatrix[1][0], 'the right vector is inverted');
  LPoint := Vec(0, 5, 0);
  TQ3Math.RotatePoint(LPoint, LMatrix);
  AssertNear(5, LPoint[0], 'rotated');
  TQ3Math.TransposeMatrix(LMatrix, LTranspose);
  TQ3Math.RotatePoint(LPoint, LTranspose);
  AssertNear(5, LPoint[1], 'and back');
  Assert.AreEqual(Byte(Q3_PLANE_X), TQ3Math.PlaneTypeForNormal(Vec(1, 0, 0)));
  Assert.AreEqual(Byte(Q3_PLANE_Y), TQ3Math.PlaneTypeForNormal(Vec(0, 1, 0)));
  Assert.AreEqual(Byte(Q3_PLANE_Z), TQ3Math.PlaneTypeForNormal(Vec(0, 0, 1)));
  Assert.AreEqual(Byte(Q3_PLANE_NON_AXIAL), TQ3Math.PlaneTypeForNormal(Vec(0, 0, -1)));
  Assert.AreEqual(Byte(5), TQ3Math.SignBitsOf(Vec(-1, 1, -1)));
end;

procedure TTestQ3Model.DovrebbeDareIlLatoDiUnBoxSuUnPiano;
var
  LPlane: TQ3Plane;
begin
  FillChar(LPlane, SizeOf(LPlane), 0);
  LPlane.Normal[0] := 1;
  LPlane.Dist := 10;
  LPlane.PlaneType := Q3_PLANE_X;
  Assert.AreEqual(1, TQ3Math.BoxOnPlaneSide(Vec(10, 0, 0), Vec(20, 1, 1), LPlane), 'front');
  Assert.AreEqual(2, TQ3Math.BoxOnPlaneSide(Vec(0, 0, 0), Vec(10, 1, 1), LPlane), 'behind');
  Assert.AreEqual(3, TQ3Math.BoxOnPlaneSide(Vec(0, 0, 0), Vec(20, 1, 1), LPlane), 'across');
  // a slanted plane: x + y = 10 with the sign bits of its normal
  LPlane.Normal[0] := 1;
  LPlane.Normal[1] := -1;
  LPlane.Dist := 0;
  LPlane.PlaneType := Q3_PLANE_NON_AXIAL;
  LPlane.SignBits := TQ3Math.SignBitsOf(LPlane.Normal);
  Assert.AreEqual(1, TQ3Math.BoxOnPlaneSide(Vec(5, 0, 0), Vec(6, 1, 1), LPlane), 'slanted front');
  Assert.AreEqual(2, TQ3Math.BoxOnPlaneSide(Vec(0, 5, 0), Vec(1, 6, 1), LPlane), 'slanted behind');
  Assert.AreEqual(3, TQ3Math.BoxOnPlaneSide(Vec(0, 0, 0), Vec(2, 2, 1), LPlane), 'slanted across');
  LPlane.SignBits := 9;
  Assert.AreEqual(1, TQ3Math.BoxOnPlaneSide(Vec(0, 0, 0), Vec(1, 1, 1), LPlane), 'a bad sign mask');
end;

type
  TOneFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  strict private
    FName: AnsiString;
    FData: TBytes;
  public
    constructor Create(const AName: AnsiString; const AData: TBytes);
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

constructor TOneFileSystem.Create(const AName: AnsiString; const AData: TBytes);
begin
  inherited Create;
  FName := AName;
  FData := AData;
end;

function TOneFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
begin
  Result := AName = FName;
  if Result then
    AFile.Data := FData;
end;

function TOneFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Result := False;
end;

procedure TTestQ3Model.DovrebbeLeggereUnFileDalFileSystemIniettato;
var
  LModel: IQ3CollisionModel;
  LMessage: string;
begin
  LModel := TQ3CollisionFactory.CreateFromFile(TBspFactory.CreateReader(TOneFileSystem.Create('maps/a.bsp',
    BuildRoomBsp)), 'maps/a.bsp');
  Assert.AreEqual(2, LModel.NumAreas);
  LMessage := '';
  try
    TQ3CollisionFactory.CreateFromFile(TBspFactory.CreateReader(TOneFileSystem.Create('maps/a.bsp',
      BuildRoomBsp)), 'maps/b.bsp');
  except
    on E: EQ3CollisionException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('Couldn''t load maps/b.bsp', LMessage);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Model);

end.
