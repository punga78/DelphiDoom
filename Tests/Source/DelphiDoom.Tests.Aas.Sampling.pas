{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - sampling (points, traces, faces,     }
{  boxes, areas) on the small worlds of the tests and on corrupted ones        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Sampling;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Tests.Aas.Support;

type
  /// <summary>The worlds of the tests: the samples, and trees with a chain of nodes</summary>
  TAasWorlds = class
  public
    class function Make(const AData: TAasFileData): IAasFile; static;
    class function Sample(const AVariant: Integer = 0): IAasFile; static;
    /// <summary>
    ///   A tree of ACount nodes (plane x = 1000 - 5 i, so a line that goes up the x axis is cut again and again
    ///   in its near piece): the child at the back of node i is node i + 1, the child at the front is the area 2
    /// </summary>
    class function Chain(const ACount: Integer): IAasFile; static;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasVectorMath = class
  public
    [Test]
    procedure DovrebbeFareIlProdottoScalareASingolaPrecisione;
    [Test]
    procedure DovrebbeSottrarreEFareIlProdottoVettoriale;
    [Test]
    procedure LaLunghezzaDovrebbeEssereLaRadiceDelProdottoScalare;
    [Test]
    procedure NormalizzareDovrebbeDareLunghezzaUnoELaVecchiaLunghezza;
    [Test]
    procedure NormalizzareUnVettoreNulloDovrebbeLasciarloCosiCom;
    [Test]
    procedure MultiplyAddDovrebbeUsareUnaScalaInDoppiaPrecisione;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasBoxMath = class
  public
    [Test]
    procedure IlBoxDelClienteDovrebbeEssereQuelloDelTipoDiPresenza;
    [Test]
    procedure UnTipoDiPresenzaSconosciutoDovrebbeStampareUnErroreEDareIlBoxAccovacciato;
    [Test]
    procedure LaDistanzaDellOrigineDovrebbeUsareIlVerticeGiusto;
    [Test]
    procedure UnaNormaleQuasiNullaDovrebbeDareZero;
    [Test]
    procedure IlLatoDelBoxDovrebbeEssereFronteRetroOEntrambi;
    [Test]
    procedure LaMacroDovrebbeUsareIPianiAssialiESaltareAlCasoGenerale;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasSampler = class
  public
    [Test]
    procedure UnPuntoDovrebbeDareLArea;
    [Test]
    procedure UnPuntoNelSolidoDovrebbeDareZeroEPresenzaNessuna;
    [Test]
    procedure LaPresenzaDelPuntoDovrebbeEssereQuellaDellArea;
    [Test]
    procedure IlRootDelSecondoMondoDovrebbeUsareIlPianoObliquo;
    [Test]
    procedure IlNumeroDiAreeConRaggiungibilitaDovrebbeSommareIClusterSoloSeInizializzato;
    [Test]
    procedure LIndiceDiRaggiungibilitaDovrebbeContareIClusterPrecedenti;
    [Test]
    procedure UnAreaPortaleDovrebbeUsareIlPortaleDellArea;
    [Test]
    procedure UnAreaSenzaRaggiungibilitaDovrebbeDareZero;
    [Test]
    procedure UnNodoFuoriDallaTabellaDovrebbeStampareUnErrore;
    [Test]
    procedure UnPianoFuoriDallaTabellaDovrebbeStampareUnErrore;
    [Test]
    procedure UnAlberoConUnCicloDovrebbeStampareUnErrore;
    [Test]
    procedure UnAreaFuoriDallaTabellaDelleImpostazioniDovrebbeDareZero;
    [Test]
    procedure UnPortaleFuoriDallaTabellaDovrebbeDareZero;
    [Test]
    procedure UnClusterFuoriDallaTabellaDovrebbeDareZero;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasTracer = class
  public
    [Test]
    procedure LeAreeDiUnaLineaDovrebbeVenireNellOrdineDellaLinea;
    [Test]
    procedure IlMassimoDiAreeDovrebbeTroncareLaLista;
    [Test]
    procedure UnMassimoNonPositivoDovrebbeDareUnaListaVuota;
    [Test]
    procedure UnaLineaFuoriDalMondoNonDovrebbeTrovareAree;
    [Test]
    procedure UnaLineaChePassaInTuttiIRamiDovrebbeStampareLoStackOverflow;
    [Test]
    procedure UnTraceInAreeAccessibiliDovrebbeArrivareInFondo;
    [Test]
    procedure UnTraceInUnAreaSenzaLaPresenzaDovrebbeFermarsi;
    [Test]
    procedure UnTraceCheParteInUnAreaNonAccessibileDovrebbeDareStartSolid;
    [Test]
    procedure UnTraceControIlSolidoDovrebbeFermarsiSulMuro;
    [Test]
    procedure UnTraceCheParteNelSolidoDovrebbeDareStartSolid;
    [Test]
    procedure IlPianoDelTraceDovrebbeGuardareVersoLInizio;
    [Test]
    procedure UnTraceNelloStessoPuntoDovrebbeDareStartSolidSeLAreaNonVaBene;
    [Test]
    procedure UnTraceChePassaInTuttiIRamiDovrebbeStampareLoStackOverflow;
    [Test]
    procedure UnTraceConUnaStradaCheSiAllontanaDovrebbeFermarsiNelLoStessoPunto;
    [Test]
    procedure UnAlberoCorrottoDovrebbeFermareIlTrace;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasFaceTester = class
  public
    [Test]
    procedure LaFacciaDiTerraDovrebbeContenereIlPuntoSopraDiLei;
    [Test]
    procedure UnPuntoFuoriDallaFacciaNonDovrebbeEssereDentro;
    [Test]
    procedure LaToleranzaDovrebbeAllargareLaFaccia;
    [Test]
    procedure InsideFaceDovrebbeUsareLaNormaleDataEPointInsideFaceQuellaDelPiano;
    [Test]
    procedure IlPianoDellaFacciaDovrebbeEssereQuelloDelFile;
    [Test]
    procedure UnaFacciaFuoriDallaTabellaDovrebbeStampareUnErrore;
    [Test]
    procedure LaFacciaDiTerraDiUnAreaDovrebbeEssereQuellaSottoIlPunto;
    [Test]
    procedure UnAreaFuoriDallaTabellaNonDovrebbeAvereFacciaDiTerra;
    [Test]
    procedure LaFacciaDellaFineDelTraceDovrebbeEssereQuellaDelMuro;
    [Test]
    procedure UnTraceCheParteNelSolidoNonDovrebbeAvereFacciaDiFine;
    [Test]
    procedure UnUltimaAreaFuoriDallaTabellaNonDovrebbeAvereFacciaDiFine;
    [Test]
    procedure UnaFacciaConBordiFuoriDallaTabellaDovrebbeStampareUnErrore;
    [Test]
    procedure IndiciDelleFacceFuoriDallaTabellaDovrebberoFermareLaRicerca;
    [Test]
    procedure UnPianoDellaFacciaFuoriDallaTabellaDovrebbeDareFalso;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasBoxAreas = class
  public
    [Test]
    procedure UnBoxDovrebbeDareLeAreeCheTocca;
    [Test]
    procedure LeAreeDovrebberoVenireInOrdineInversoDiScoperta;
    [Test]
    procedure IlMassimoDiAreeDovrebbeTenereLeUltimeTrovate;
    [Test]
    procedure UnBoxNelSolidoNonDovrebbeToccareAree;
    [Test]
    procedure UnMassimoNonPositivoDovrebbeDareUnaListaVuota;
    [Test]
    procedure UnBoxChePassaInTuttiIRamiDovrebbeStampareLoStackOverflow;
    [Test]
    procedure UnNodoFuoriDallaTabellaDovrebbeStampareUnErrore;
  end;

  [TestFixture]
  [Category('Aas')]
  TTestAasAreaQuery = class
  public
    [Test]
    procedure ClusterEPresenzaDovrebberoVenireDalleImpostazioni;
    [Test]
    procedure UnNumeroDiAreaNonValidoDovrebbeStampareUnErroreEDareZero;
    [Test]
    procedure AreaInfoDovrebbeDareLeInformazioniDellArea;
    [Test]
    procedure AreaInfoConUnNumeroNonValidoDovrebbeDareZero;
    [Test]
    procedure LaRaggiungibilitaDovrebbeContareLeAreeRaggiungibili;
    [Test]
    procedure LaRaggiungibilitaFuoriDallaTabellaDovrebbeStampareUnErroreFatale;
    [Test]
    procedure LeFunzioniPerContenutiEFlagDovrebberoGuardareLeImpostazioni;
    [Test]
    procedure LeFunzioniPerContenutiEFlagFuoriDallaTabellaDovrebberoDareFalso;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.AasFile, DelphiDoom.Aas.Factory, DelphiDoom.Aas.BoxMath,
  DelphiDoom.Aas.VectorMath, DelphiDoom.Tests.Aas.Sample;

{ TAasWorlds }

class function TAasWorlds.Make(const AData: TAasFileData): IAasFile;
begin
  Result := TAasFile.Create(AData);
end;

class function TAasWorlds.Sample(const AVariant: Integer): IAasFile;
begin
  Result := Make(TAasSample.Content(AVariant));
end;

class function TAasWorlds.Chain(const ACount: Integer): IAasFile;
var
  LData: TAasFileData;
  LIndex: Integer;
begin
  FillChar(LData, SizeOf(LData), 0);
  SetLength(LData.Planes, 2 * (ACount + 1));
  SetLength(LData.Nodes, ACount + 1);
  SetLength(LData.AreaSettings, 3);
  SetLength(LData.Areas, 3);
  for LIndex := 1 to 2 do
    LData.AreaSettings[LIndex].PresenceType := PRESENCE_NORMAL or PRESENCE_CROUCH;
  for LIndex := 0 to ACount do
  begin
    LData.Planes[2 * LIndex].Normal := Vec(1, 0, 0);
    LData.Planes[2 * LIndex].Dist := 1000 - 5 * LIndex;
    LData.Planes[2 * LIndex].PlaneType := 0;
    LData.Planes[2 * LIndex + 1].Normal := Vec(-1, 0, 0);
    LData.Planes[2 * LIndex + 1].Dist := -(1000 - 5 * LIndex);
    LData.Planes[2 * LIndex + 1].PlaneType := 0;
  end;
  for LIndex := 1 to ACount do
  begin
    LData.Nodes[LIndex].PlaneNum := 2 * LIndex;
    LData.Nodes[LIndex].Children[0] := -2;
    if LIndex < ACount then
      LData.Nodes[LIndex].Children[1] := LIndex + 1
    else
      LData.Nodes[LIndex].Children[1] := -1;
  end;
  Result := Make(LData);
end;

{ TTestAasVectorMath }

procedure TTestAasVectorMath.DovrebbeFareIlProdottoScalareASingolaPrecisione;
begin
  Assert.AreEqual<Single>(32, TAasVectorMath.Dot(Vec(1, 2, 3), Vec(4, 5, 6)));
  // 16777216 + 1 is not a float: the sum is rounded after each operation
  Assert.AreEqual<Single>(16777216, TAasVectorMath.Dot(Vec(16777216, 1, 0), Vec(1, 1, 0)));
end;

procedure TTestAasVectorMath.DovrebbeSottrarreEFareIlProdottoVettoriale;
var
  LOut: TVec3;
begin
  TAasVectorMath.Subtract(Vec(5, 7, 9), Vec(1, 2, 3), LOut);
  Assert.AreEqual<Single>(4, LOut[0]);
  Assert.AreEqual<Single>(5, LOut[1]);
  Assert.AreEqual<Single>(6, LOut[2]);
  TAasVectorMath.Cross(Vec(1, 0, 0), Vec(0, 1, 0), LOut);
  Assert.AreEqual<Single>(0, LOut[0]);
  Assert.AreEqual<Single>(0, LOut[1]);
  Assert.AreEqual<Single>(1, LOut[2]);
  TAasVectorMath.Cross(Vec(0, 1, 0), Vec(0, 0, 1), LOut);
  Assert.AreEqual<Single>(1, LOut[0]);
  TAasVectorMath.Cross(Vec(0, 0, 1), Vec(1, 0, 0), LOut);
  Assert.AreEqual<Single>(1, LOut[1]);
end;

procedure TTestAasVectorMath.LaLunghezzaDovrebbeEssereLaRadiceDelProdottoScalare;
begin
  Assert.AreEqual<Single>(5, TAasVectorMath.Length(Vec(3, 4, 0)));
  Assert.AreEqual<Single>(0, TAasVectorMath.Length(Vec(0, 0, 0)));
end;

procedure TTestAasVectorMath.NormalizzareDovrebbeDareLunghezzaUnoELaVecchiaLunghezza;
var
  LVector: TVec3;
begin
  LVector := Vec(0, 3, 4);
  Assert.AreEqual<Single>(5, TAasVectorMath.Normalize(LVector));
  Assert.AreEqual(Double(0.6), Double(LVector[1]), 0.000001);
  Assert.AreEqual(Double(0.8), Double(LVector[2]), 0.000001);
end;

procedure TTestAasVectorMath.NormalizzareUnVettoreNulloDovrebbeLasciarloCosiCom;
var
  LVector: TVec3;
begin
  LVector := Vec(0, 0, 0);
  Assert.AreEqual<Single>(0, TAasVectorMath.Normalize(LVector));
  Assert.AreEqual<Single>(0, LVector[0]);
end;

procedure TTestAasVectorMath.MultiplyAddDovrebbeUsareUnaScalaInDoppiaPrecisione;
var
  LOut: TVec3;
begin
  TAasVectorMath.MultiplyAdd(Vec(10, 20, 30), Vec(1, 2, 3), -0.125, LOut);
  Assert.AreEqual<Single>(9.875, LOut[0]);
  Assert.AreEqual<Single>(19.75, LOut[1]);
  Assert.AreEqual<Single>(29.625, LOut[2]);
end;

{ TTestAasBoxMath }

procedure TTestAasBoxMath.IlBoxDelClienteDovrebbeEssereQuelloDelTipoDiPresenza;
var
  LMins, LMaxs: TVec3;
begin
  TAasBoxMath.PresenceTypeBoundingBox(nil, PRESENCE_NORMAL, LMins, LMaxs);
  Assert.AreEqual<Single>(-24, LMins[2]);
  Assert.AreEqual<Single>(32, LMaxs[2]);
  TAasBoxMath.PresenceTypeBoundingBox(nil, PRESENCE_CROUCH, LMins, LMaxs);
  Assert.AreEqual<Single>(-15, LMins[0]);
  Assert.AreEqual<Single>(8, LMaxs[2]);
end;

procedure TTestAasBoxMath.UnTipoDiPresenzaSconosciutoDovrebbeStampareUnErroreEDareIlBoxAccovacciato;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LMins, LMaxs: TVec3;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  TAasBoxMath.PresenceTypeBoundingBox(LKeeper, 3, LMins, LMaxs);
  Assert.AreEqual<Single>(8, LMaxs[2]);
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.AreEqual(PRT_FATAL, LImport.Level(0));
  Assert.AreEqual('AAS_PresenceTypeBoundingBox: unknown presence type'#10, LImport.Message(0));
end;

procedure TTestAasBoxMath.LaDistanzaDellOrigineDovrebbeUsareIlVerticeGiusto;
var
  LMins, LMaxs: TVec3;
begin
  LMins := Vec(-15, -15, -24);
  LMaxs := Vec(15, 15, 32);
  // normal +z: on the side of the normal the vertex is the one with the lowest z (-24), the dot product with -normal is +24
  Assert.AreEqual<Single>(24, TAasBoxMath.BoxOriginDistanceFromPlane(Vec(0, 0, 1), LMins, LMaxs, 0));
  Assert.AreEqual<Single>(-32, TAasBoxMath.BoxOriginDistanceFromPlane(Vec(0, 0, 1), LMins, LMaxs, 1));
  // normal -x: the opposite
  Assert.AreEqual<Single>(15, TAasBoxMath.BoxOriginDistanceFromPlane(Vec(-1, 0, 0), LMins, LMaxs, 0));
  Assert.AreEqual<Single>(-15, TAasBoxMath.BoxOriginDistanceFromPlane(Vec(-1, 0, 0), LMins, LMaxs, 1));
end;

procedure TTestAasBoxMath.UnaNormaleQuasiNullaDovrebbeDareZero;
begin
  Assert.AreEqual<Single>(0, TAasBoxMath.BoxOriginDistanceFromPlane(Vec(0.0005, -0.0005, 0), Vec(-1, -1, -1),
    Vec(1, 1, 1), 0));
end;

procedure TTestAasBoxMath.IlLatoDelBoxDovrebbeEssereFronteRetroOEntrambi;
var
  LPlane: TAasPlane;
begin
  LPlane.Normal := Vec(0.6, 0.8, 0);
  LPlane.Dist := 10;
  LPlane.PlaneType := 3;
  // the corner at the front is (maxs) 0.6 * 20 + 0.8 * 20 = 28 >= 10; the one at the back (mins) 0 < 10 is not behind
  Assert.AreEqual<Integer>(1, TAasBoxMath.BoxOnPlaneSide2(Vec(20, 20, 0), Vec(30, 30, 5), LPlane));
  Assert.AreEqual<Integer>(2, TAasBoxMath.BoxOnPlaneSide2(Vec(-30, -30, 0), Vec(-20, -20, 5), LPlane));
  Assert.AreEqual<Integer>(3, TAasBoxMath.BoxOnPlaneSide2(Vec(-5, -5, 0), Vec(30, 30, 5), LPlane));
  // negative components swap the corners
  LPlane.Normal := Vec(-0.6, -0.8, 0);
  LPlane.Dist := -10;
  Assert.AreEqual<Integer>(3, TAasBoxMath.BoxOnPlaneSide2(Vec(-5, -5, 0), Vec(30, 30, 5), LPlane));
end;

procedure TTestAasBoxMath.LaMacroDovrebbeUsareIPianiAssialiESaltareAlCasoGenerale;
var
  LPlane: TAasPlane;
begin
  LPlane.Normal := Vec(1, 0, 0);
  LPlane.Dist := 10;
  LPlane.PlaneType := 0;
  Assert.AreEqual<Integer>(1, TAasBoxMath.BoxOnPlaneSide(Vec(10, 0, 0), Vec(20, 5, 5), LPlane));
  Assert.AreEqual<Integer>(2, TAasBoxMath.BoxOnPlaneSide(Vec(0, 0, 0), Vec(10, 5, 5), LPlane));
  Assert.AreEqual<Integer>(3, TAasBoxMath.BoxOnPlaneSide(Vec(0, 0, 0), Vec(20, 5, 5), LPlane));
  LPlane.PlaneType := 3;
  Assert.AreEqual<Integer>(3, TAasBoxMath.BoxOnPlaneSide(Vec(0, 0, 0), Vec(20, 5, 5), LPlane));
  LPlane.PlaneType := -1;
  Assert.AreEqual<Integer>(3, TAasBoxMath.BoxOnPlaneSide(Vec(0, 0, 0), Vec(20, 5, 5), LPlane));
end;

{ TTestAasSampler }

procedure TTestAasSampler.UnPuntoDovrebbeDareLArea;
var
  LSampler: IAasSampler;
begin
  LSampler := TAasFactory.CreateSampler(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(1, LSampler.PointAreaNum(Vec(32, 32, 32)));
  Assert.AreEqual<Integer>(2, LSampler.PointAreaNum(Vec(96, 10, 10)));
  Assert.AreEqual<Integer>(3, LSampler.PointAreaNum(Vec(160, 60, 60)));
  Assert.AreEqual<Integer>(4, LSampler.PointAreaNum(Vec(250, 32, 32)));
end;

procedure TTestAasSampler.UnPuntoNelSolidoDovrebbeDareZeroEPresenzaNessuna;
var
  LSampler: IAasSampler;
begin
  LSampler := TAasFactory.CreateSampler(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(0, LSampler.PointAreaNum(Vec(32, -1, 32)));
  Assert.AreEqual<Integer>(0, LSampler.PointAreaNum(Vec(32, 65, 32)));
  Assert.AreEqual<Integer>(0, LSampler.PointAreaNum(Vec(32, 32, -1)));
  Assert.AreEqual<Integer>(0, LSampler.PointAreaNum(Vec(32, 32, 65)));
  Assert.AreEqual<Integer>(PRESENCE_NONE, LSampler.PointPresenceType(Vec(32, -1, 32)));
end;

procedure TTestAasSampler.LaPresenzaDelPuntoDovrebbeEssereQuellaDellArea;
var
  LSampler: IAasSampler;
begin
  LSampler := TAasFactory.CreateSampler(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(PRESENCE_NORMAL or PRESENCE_CROUCH, LSampler.PointPresenceType(Vec(32, 32, 32)));
  Assert.AreEqual<Integer>(PRESENCE_CROUCH, LSampler.PointPresenceType(Vec(96, 32, 32)));
end;

procedure TTestAasSampler.IlRootDelSecondoMondoDovrebbeUsareIlPianoObliquo;
var
  LSampler: IAasSampler;
begin
  LSampler := TAasFactory.CreateSampler(TAasWorlds.Sample(1), nil);
  // the plane 0.75 x + 0.5 y = 160: at y = 32 the cut is at x = 192, between the areas 3 and 4
  Assert.AreEqual<Integer>(3, LSampler.PointAreaNum(Vec(150, 32, 32)));
  Assert.AreEqual<Integer>(4, LSampler.PointAreaNum(Vec(200, 32, 32)));
  // at y = 64 the cut is at x = 170.67: the point 180 is already in the area 4 side (front)
  Assert.AreEqual<Integer>(4, LSampler.PointAreaNum(Vec(180, 63, 32)));
end;

procedure TTestAasSampler.IlNumeroDiAreeConRaggiungibilitaDovrebbeSommareIClusterSoloSeInizializzato;
begin
  Assert.AreEqual<Integer>(5, TAasFactory.CreateSampler(TAasWorlds.Sample, nil, True).ReachabilityAreaCount);
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Sample, nil, False).ReachabilityAreaCount);
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Sample, nil).PointReachabilityAreaIndex(Vec(32, 32, 32)));
end;

procedure TTestAasSampler.LIndiceDiRaggiungibilitaDovrebbeContareIClusterPrecedenti;
var
  LSampler: IAasSampler;
begin
  LSampler := TAasFactory.CreateSampler(TAasWorlds.Sample, nil, True);
  // area 1: cluster 1, number 1 in it; area 2: number 2; area 3: cluster 2 after the 3 of the cluster 1
  Assert.AreEqual<Integer>(1, LSampler.PointReachabilityAreaIndex(Vec(32, 32, 32)));
  Assert.AreEqual<Integer>(2, LSampler.PointReachabilityAreaIndex(Vec(96, 32, 32)));
  Assert.AreEqual<Integer>(4, LSampler.PointReachabilityAreaIndex(Vec(160, 32, 32)));
  Assert.AreEqual<Integer>(0, LSampler.PointReachabilityAreaIndex(Vec(32, -3, 32)));
end;

procedure TTestAasSampler.UnAreaPortaleDovrebbeUsareIlPortaleDellArea;
begin
  // the original indexes the portals with the cluster it just replaced (a negative index, outside the
  // table); here the portal of the area gives its cluster (1) and the number of the area in it (3)
  Assert.AreEqual<Integer>(3, TAasFactory.CreateSampler(TAasWorlds.Sample, nil, True).PointReachabilityAreaIndex(
    Vec(224, 32, 32)));
end;

procedure TTestAasSampler.UnAreaSenzaRaggiungibilitaDovrebbeDareZero;
var
  LData: TAasFileData;
begin
  LData := TAasSample.Content(0);
  LData.AreaSettings[1].NumReachableAreas := 0;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), nil, True).PointReachabilityAreaIndex(
    Vec(32, 32, 32)));
end;

procedure TTestAasSampler.UnNodoFuoriDallaTabellaDovrebbeStampareUnErrore;
var
  LData: TAasFileData;
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LData := TAasSample.Content(0);
  LData.Nodes[1].Children[0] := 999;
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), LKeeper).PointAreaNum(Vec(32, 32, 32)));
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.AreEqual(PRT_ERROR, LImport.Level(0));
  Assert.AreEqual('nodenum = 999 >= aasworld.numnodes = 8'#10, LImport.Message(0));
end;

procedure TTestAasSampler.UnPianoFuoriDallaTabellaDovrebbeStampareUnErrore;
var
  LData: TAasFileData;
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LData := TAasSample.Content(0);
  LData.Nodes[1].PlaneNum := -5;
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), LKeeper).PointAreaNum(Vec(32, 32, 32)));
  Assert.AreEqual('node->planenum = -5 >= aasworld.numplanes = 20'#10, LImport.Message(0));
end;

procedure TTestAasSampler.UnAlberoConUnCicloDovrebbeStampareUnErrore;
var
  LData: TAasFileData;
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LData := TAasSample.Content(0);
  LData.Nodes[1].Children[0] := 1;
  LData.Nodes[1].Children[1] := 1;
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), LKeeper).PointAreaNum(Vec(32, 32, 32)));
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.AreEqual('AAS_PointAreaNum: the tree of nodes has a loop'#10, LImport.Message(0));
end;

procedure TTestAasSampler.UnAreaFuoriDallaTabellaDelleImpostazioniDovrebbeDareZero;
var
  LData: TAasFileData;
begin
  LData := TAasSample.Content(0);
  SetLength(LData.AreaSettings, 2);
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), nil).PointPresenceType(
    Vec(160, 32, 32)));
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), nil, True).PointReachabilityAreaIndex(
    Vec(160, 32, 32)));
end;

procedure TTestAasSampler.UnPortaleFuoriDallaTabellaDovrebbeDareZero;
var
  LData: TAasFileData;
begin
  LData := TAasSample.Content(0);
  SetLength(LData.Portals, 1);
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), nil, True).PointReachabilityAreaIndex(
    Vec(224, 32, 32)));
end;

procedure TTestAasSampler.UnClusterFuoriDallaTabellaDovrebbeDareZero;
var
  LData: TAasFileData;
begin
  LData := TAasSample.Content(0);
  LData.AreaSettings[1].Cluster := 40;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateSampler(TAasWorlds.Make(LData), nil, True).PointReachabilityAreaIndex(
    Vec(32, 32, 32)));
end;

{ TTestAasTracer }

procedure TTestAasTracer.LeAreeDiUnaLineaDovrebbeVenireNellOrdineDellaLinea;
var
  LTracer: IAasTracer;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
begin
  LTracer := TAasFactory.CreateTracer(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(4, LTracer.TraceAreas(Vec(10, 32, 32), Vec(250, 32, 32), 16, LAreas, LPoints));
  Assert.AreEqual<Integer>(4, Length(LAreas));
  Assert.AreEqual<Integer>(1, LAreas[0]);
  Assert.AreEqual<Integer>(2, LAreas[1]);
  Assert.AreEqual<Integer>(3, LAreas[2]);
  Assert.AreEqual<Integer>(4, LAreas[3]);
  // the first point is the start, the others are where the areas are entered (x = 64, 128, 192)
  Assert.AreEqual<Single>(10, LPoints[0][0]);
  Assert.AreEqual(Double(64), Double(LPoints[1][0]), 0.01);
  Assert.AreEqual(Double(128), Double(LPoints[2][0]), 0.01);
  Assert.AreEqual(Double(192), Double(LPoints[3][0]), 0.01);
  // and backwards
  Assert.AreEqual<Integer>(4, LTracer.TraceAreas(Vec(250, 32, 32), Vec(10, 32, 32), 16, LAreas, LPoints));
  Assert.AreEqual<Integer>(4, LAreas[0]);
  Assert.AreEqual<Integer>(1, LAreas[3]);
end;

procedure TTestAasTracer.IlMassimoDiAreeDovrebbeTroncareLaLista;
var
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
begin
  Assert.AreEqual<Integer>(2, TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceAreas(Vec(10, 32, 32),
    Vec(250, 32, 32), 2, LAreas, LPoints));
  Assert.AreEqual<Integer>(2, Length(LAreas));
  Assert.AreEqual<Integer>(2, LAreas[1]);
end;

procedure TTestAasTracer.UnMassimoNonPositivoDovrebbeDareUnaListaVuota;
var
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
begin
  Assert.AreEqual<Integer>(0, TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceAreas(Vec(10, 32, 32),
    Vec(250, 32, 32), 0, LAreas, LPoints));
  Assert.AreEqual<Integer>(0, Length(LAreas));
end;

procedure TTestAasTracer.UnaLineaFuoriDalMondoNonDovrebbeTrovareAree;
var
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
begin
  Assert.AreEqual<Integer>(0, TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceAreas(Vec(10, -30, 32),
    Vec(250, -30, 32), 16, LAreas, LPoints));
end;

procedure TTestAasTracer.UnaLineaChePassaInTuttiIRamiDovrebbeStampareLoStackOverflow;
var
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  TAasFactory.CreateTracer(TAasWorlds.Chain(130), LKeeper).TraceAreas(Vec(-10, 0, 0), Vec(2000, 0, 0), 500, LAreas,
    LPoints);
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.AreEqual('AAS_TraceAreas: stack overflow'#10, LImport.Message(0));
  Assert.AreEqual(PRT_ERROR, LImport.Level(0));
  // a shorter chain fits in the stack: 1 start piece plus one area per level
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  Assert.AreEqual<Integer>(101, TAasFactory.CreateTracer(TAasWorlds.Chain(100), LKeeper).TraceAreas(Vec(-10, 0, 0),
    Vec(2000, 0, 0), 500, LAreas, LPoints));
  Assert.AreEqual<Integer>(0, LImport.Count);
end;

procedure TTestAasTracer.UnTraceInAreeAccessibiliDovrebbeArrivareInFondo;
var
  LTrace: TAasTrace;
begin
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(10, 32, 32), Vec(250, 32, 32),
    PRESENCE_CROUCH, -1);
  Assert.IsFalse(LTrace.StartSolid);
  Assert.AreEqual<Single>(1, LTrace.Fraction);
  Assert.AreEqual<Single>(250, LTrace.EndPos[0]);
  Assert.AreEqual<Integer>(0, LTrace.Area);
  Assert.AreEqual<Integer>(0, LTrace.PlaneNum);
  Assert.AreEqual<Integer>(0, LTrace.Ent);
  Assert.AreEqual<Integer>(4, LTrace.LastArea);
end;

procedure TTestAasTracer.UnTraceInUnAreaSenzaLaPresenzaDovrebbeFermarsi;
var
  LTrace: TAasTrace;
begin
  // the area 2 is only for crouching: the box of the standing client stops before it
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(10, 32, 32), Vec(250, 32, 32),
    PRESENCE_NORMAL, -1);
  Assert.IsFalse(LTrace.StartSolid);
  Assert.AreEqual<Integer>(2, LTrace.Area);
  Assert.AreEqual<Integer>(1, LTrace.LastArea);
  Assert.IsTrue(LTrace.EndPos[0] < 64);
  Assert.IsTrue(LTrace.EndPos[0] > 60);
  Assert.IsTrue((LTrace.Fraction > 0.2) and (LTrace.Fraction < 0.25));
end;

procedure TTestAasTracer.UnTraceCheParteInUnAreaNonAccessibileDovrebbeDareStartSolid;
var
  LTrace: TAasTrace;
begin
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(96, 32, 32), Vec(250, 32, 32),
    PRESENCE_NORMAL, -1);
  Assert.IsTrue(LTrace.StartSolid);
  Assert.AreEqual<Single>(0, LTrace.Fraction);
  Assert.AreEqual<Integer>(2, LTrace.Area);
  Assert.AreEqual<Single>(96, LTrace.EndPos[0]);
end;

procedure TTestAasTracer.UnTraceControIlSolidoDovrebbeFermarsiSulMuro;
var
  LTrace: TAasTrace;
begin
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(32, 32, 32), Vec(32, 200, 32),
    PRESENCE_NORMAL, -1);
  Assert.IsFalse(LTrace.StartSolid);
  Assert.AreEqual<Integer>(0, LTrace.Area);
  Assert.AreEqual<Integer>(1, LTrace.LastArea);
  Assert.IsTrue((LTrace.EndPos[1] < 64) and (LTrace.EndPos[1] > 63));
  Assert.IsTrue(LTrace.Fraction < 0.2);
end;

procedure TTestAasTracer.UnTraceCheParteNelSolidoDovrebbeDareStartSolid;
var
  LTrace: TAasTrace;
begin
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(32, -20, 32), Vec(32, 30, 32),
    PRESENCE_NORMAL, -1);
  Assert.IsTrue(LTrace.StartSolid);
  Assert.AreEqual<Single>(0, LTrace.Fraction);
  Assert.AreEqual<Integer>(0, LTrace.Area);
  Assert.AreEqual<Single>(-20, LTrace.EndPos[1]);
end;

procedure TTestAasTracer.IlPianoDelTraceDovrebbeGuardareVersoLInizio;
var
  LTrace: TAasTrace;
  LPlanes: TArray<TAasPlane>;
begin
  LPlanes := TAasWorlds.Sample.Planes;
  // going up the y axis against the wall y = 64 (planes 2 and 3): the one facing the start is the -y one
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(32, 32, 32), Vec(32, 200, 32),
    PRESENCE_NORMAL, -1);
  Assert.IsTrue(LPlanes[LTrace.PlaneNum].Normal[1] < 0);
  // going down against the wall y = 0 (planes 0 and 1): the plane faces +y
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(32, 32, 32), Vec(32, -200, 32),
    PRESENCE_NORMAL, -1);
  Assert.IsTrue(LPlanes[LTrace.PlaneNum].Normal[1] > 0);
end;

procedure TTestAasTracer.UnTraceNelloStessoPuntoDovrebbeDareStartSolidSeLAreaNonVaBene;
var
  LTrace: TAasTrace;
begin
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(32, 32, 32), Vec(32, 32, 32),
    PRESENCE_NONE, -1);
  Assert.IsTrue(LTrace.StartSolid);
  Assert.AreEqual<Integer>(1, LTrace.Area);
end;

procedure TTestAasTracer.UnTraceChePassaInTuttiIRamiDovrebbeStampareLoStackOverflow;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LTrace: TAasTrace;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Chain(130), LKeeper).TraceClientBBox(Vec(-10, 0, 0), Vec(2000, 0, 0),
    PRESENCE_NORMAL, -1);
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.AreEqual('AAS_TraceBoundingBox: stack overflow'#10, LImport.Message(0));
  // the trace that was filled in so far is returned
  Assert.AreEqual<Single>(0, LTrace.Fraction);
end;

procedure TTestAasTracer.UnTraceConUnaStradaCheSiAllontanaDovrebbeFermarsiNelLoStessoPunto;
var
  LTrace: TAasTrace;
begin
  // the start is in the solid half (y < 0 of the root node): the trace is stuck at the start
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(100, -5, 32), Vec(100, -50, 32),
    PRESENCE_CROUCH, -1);
  Assert.IsTrue(LTrace.StartSolid);
  Assert.AreEqual<Single>(100, LTrace.EndPos[0]);
end;

procedure TTestAasTracer.UnAlberoCorrottoDovrebbeFermareIlTrace;
var
  LData: TAasFileData;
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
begin
  // a node that is not in the table
  LData := TAasSample.Content(0);
  LData.Nodes[1].Children[0] := 999;
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  TAasFactory.CreateTracer(TAasWorlds.Make(LData), LKeeper).TraceClientBBox(Vec(32, 32, 32), Vec(40, 32, 32),
    PRESENCE_NORMAL, -1);
  Assert.AreEqual('AAS_TraceBoundingBox: nodenum out of range'#10, LImport.Message(0));
  TAasFactory.CreateTracer(TAasWorlds.Make(LData), LKeeper).TraceAreas(Vec(32, 32, 32), Vec(40, 32, 32), 4, LAreas,
    LPoints);
  Assert.AreEqual('AAS_TraceAreas: nodenum out of range'#10, LImport.Message(1));
  // an area that is not in the settings
  LData := TAasSample.Content(0);
  SetLength(LData.AreaSettings, 2);
  TAasFactory.CreateTracer(TAasWorlds.Make(LData), LKeeper).TraceClientBBox(Vec(160, 32, 32), Vec(170, 32, 32),
    PRESENCE_NORMAL, -1);
  Assert.AreEqual('AAS_TraceBoundingBox: -nodenum out of range'#10, LImport.Message(2));
  // a plane that is not in the table
  LData := TAasSample.Content(0);
  LData.Nodes[1].PlaneNum := 500;
  TAasFactory.CreateTracer(TAasWorlds.Make(LData), LKeeper).TraceClientBBox(Vec(32, 32, 32), Vec(40, 32, 32),
    PRESENCE_NORMAL, -1);
  TAasFactory.CreateTracer(TAasWorlds.Make(LData), LKeeper).TraceAreas(Vec(32, 32, 32), Vec(40, 32, 32), 4, LAreas,
    LPoints);
  Assert.AreEqual('AAS_Trace: the plane 500 of a node is out of range'#10, LImport.Message(3));
  Assert.AreEqual('AAS_Trace: the plane 500 of a node is out of range'#10, LImport.Message(4));
  // a tree with a loop
  LData := TAasSample.Content(0);
  LData.Nodes[1].Children[0] := 1;
  LData.Nodes[1].Children[1] := 1;
  TAasFactory.CreateTracer(TAasWorlds.Make(LData), LKeeper).TraceClientBBox(Vec(32, 32, 32), Vec(40, 32, 32),
    PRESENCE_NORMAL, -1);
  TAasFactory.CreateTracer(TAasWorlds.Make(LData), LKeeper).TraceAreas(Vec(32, 32, 32), Vec(40, 32, 32), 4, LAreas,
    LPoints);
  Assert.AreEqual('AAS_Trace: the tree of nodes has a loop'#10, LImport.Message(5));
  Assert.AreEqual('AAS_Trace: the tree of nodes has a loop'#10, LImport.Message(6));
end;

{ TTestAasFaceTester }

procedure TTestAasFaceTester.LaFacciaDiTerraDovrebbeContenereIlPuntoSopraDiLei;
var
  LTester: IAasFaceTester;
begin
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil);
  // the faces: x faces 1..5, then four for each area: area 1 has y0 = 6, y1 = 7, z0 (ground) = 8, z1 = 9
  Assert.IsTrue(LTester.PointInsideFace(8, Vec(32, 32, 0), 0.01));
  Assert.IsTrue(LTester.PointInsideFace(8, Vec(32, 32, 20), 0.01));
end;

procedure TTestAasFaceTester.UnPuntoFuoriDallaFacciaNonDovrebbeEssereDentro;
var
  LTester: IAasFaceTester;
begin
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil);
  Assert.IsFalse(LTester.PointInsideFace(8, Vec(100, 32, 0), 0.01));
  Assert.IsFalse(LTester.PointInsideFace(8, Vec(32, 100, 0), 0.01));
  Assert.IsFalse(LTester.PointInsideFace(8, Vec(-5, 32, 0), 0.01));
end;

procedure TTestAasFaceTester.LaToleranzaDovrebbeAllargareLaFaccia;
var
  LTester: IAasFaceTester;
begin
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil);
  Assert.IsFalse(LTester.PointInsideFace(8, Vec(64.5, 32, 0), 0.01));
  // the tolerance is multiplied by the length of the edge (64)
  Assert.IsTrue(LTester.PointInsideFace(8, Vec(64.5, 32, 0), 100));
end;

procedure TTestAasFaceTester.InsideFaceDovrebbeUsareLaNormaleDataEPointInsideFaceQuellaDelPiano;
var
  LTester: IAasFaceTester;
begin
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil);
  Assert.IsTrue(LTester.InsideFace(8, Vec(0, 0, 1), Vec(32, 32, 0), 0.01));
  // a normal that is turned the other way makes the inside the outside
  Assert.IsFalse(LTester.InsideFace(8, Vec(0, 0, -1), Vec(32, 32, 0), 0.01));
end;

procedure TTestAasFaceTester.IlPianoDellaFacciaDovrebbeEssereQuelloDelFile;
var
  LTester: IAasFaceTester;
  LNormal: TVec3;
  LDist: Single;
begin
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil);
  LTester.FacePlane(8, LNormal, LDist);
  Assert.AreEqual<Single>(1, LNormal[2]);
  Assert.AreEqual<Single>(0, LDist);
  LTester.FacePlane(2, LNormal, LDist);
  Assert.AreEqual<Single>(1, LNormal[0]);
  Assert.AreEqual<Single>(64, LDist);
end;

procedure TTestAasFaceTester.UnaFacciaFuoriDallaTabellaDovrebbeStampareUnErrore;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LTester: IAasFaceTester;
  LNormal: TVec3;
  LDist: Single;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, LKeeper);
  Assert.IsFalse(LTester.InsideFace(500, Vec(0, 0, 1), Vec(0, 0, 0), 0));
  Assert.IsFalse(LTester.PointInsideFace(-1, Vec(0, 0, 0), 0));
  LTester.FacePlane(500, LNormal, LDist);
  Assert.AreEqual<Single>(0, LDist);
  Assert.AreEqual<Single>(0, LNormal[2]);
  Assert.AreEqual<Integer>(3, LImport.Count);
  Assert.AreEqual('AAS_InsideFace: face 500 out of range'#10, LImport.Message(0));
end;

procedure TTestAasFaceTester.LaFacciaDiTerraDiUnAreaDovrebbeEssereQuellaSottoIlPunto;
var
  LTester: IAasFaceTester;
begin
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(8, LTester.AreaGroundFace(1, Vec(32, 32, 10)));
  // the ground face of the area 2 is the number 12
  Assert.AreEqual<Integer>(12, LTester.AreaGroundFace(2, Vec(100, 20, 10)));
  // the point is outside the face of the area
  Assert.AreEqual<Integer>(0, LTester.AreaGroundFace(1, Vec(100, 32, 10)));
end;

procedure TTestAasFaceTester.UnAreaFuoriDallaTabellaNonDovrebbeAvereFacciaDiTerra;
begin
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil).AreaGroundFace(99,
    Vec(0, 0, 0)));
end;

procedure TTestAasFaceTester.LaFacciaDellaFineDelTraceDovrebbeEssereQuellaDelMuro;
var
  LTrace: TAasTrace;
  LTester: IAasFaceTester;
begin
  // the standing client stops before the crouch only area 2: the end of the trace is on the face between 1 and 2
  LTrace := TAasFactory.CreateTracer(TAasWorlds.Sample, nil).TraceClientBBox(Vec(10, 32, 32), Vec(250, 32, 32),
    PRESENCE_NORMAL, -1);
  LTester := TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(2, LTester.TraceEndFace(LTrace));
end;

procedure TTestAasFaceTester.UnTraceCheParteNelSolidoNonDovrebbeAvereFacciaDiFine;
var
  LTrace: TAasTrace;
begin
  LTrace.StartSolid := True;
  LTrace.LastArea := 1;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil).TraceEndFace(LTrace));
end;

procedure TTestAasFaceTester.UnUltimaAreaFuoriDallaTabellaNonDovrebbeAvereFacciaDiFine;
var
  LTrace: TAasTrace;
begin
  FillChar(LTrace, SizeOf(LTrace), 0);
  LTrace.LastArea := 99;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil).TraceEndFace(LTrace));
  // in the plane of the face but outside it: no face
  LTrace.LastArea := 1;
  LTrace.PlaneNum := 4;
  LTrace.EndPos := Vec(32, 200, 0);
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Sample, nil).TraceEndFace(LTrace));
end;

procedure TTestAasFaceTester.UnaFacciaConBordiFuoriDallaTabellaDovrebbeStampareUnErrore;
var
  LData: TAasFileData;
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  // the first edge of the face is not in the edge index
  LData := TAasSample.Content(0);
  LData.Faces[8].FirstEdge := 9999;
  Assert.IsFalse(TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), LKeeper).PointInsideFace(8, Vec(32, 32, 0), 0));
  // an edge that is not in the edges
  LData := TAasSample.Content(0);
  LData.EdgeIndex[LData.Faces[8].FirstEdge] := 9999;
  Assert.IsFalse(TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), LKeeper).PointInsideFace(8, Vec(32, 32, 0), 0));
  // a vertex that is not in the vertexes
  LData := TAasSample.Content(0);
  LData.Edges[Abs(LData.EdgeIndex[LData.Faces[8].FirstEdge])].Vertexes[1] := 9999;
  Assert.IsFalse(TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), LKeeper).PointInsideFace(8, Vec(32, 32, 0), 0));
  Assert.AreEqual<Integer>(3, LImport.Count);
  Assert.IsTrue(LImport.Message(0).StartsWith('AAS_InsideFace: an edge of the face'));
end;

procedure TTestAasFaceTester.IndiciDelleFacceFuoriDallaTabellaDovrebberoFermareLaRicerca;
var
  LData: TAasFileData;
  LTrace: TAasTrace;
begin
  LData := TAasSample.Content(0);
  LData.Areas[1].FirstFace := 9999;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).AreaGroundFace(1,
    Vec(32, 32, 10)));
  FillChar(LTrace, SizeOf(LTrace), 0);
  LTrace.LastArea := 1;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).TraceEndFace(LTrace));
  // a face that is not in the faces
  LData := TAasSample.Content(0);
  LData.FaceIndex[LData.Areas[1].FirstFace] := 9999;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).AreaGroundFace(1,
    Vec(32, 32, 10)));
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).TraceEndFace(LTrace));
end;

procedure TTestAasFaceTester.UnPianoDellaFacciaFuoriDallaTabellaDovrebbeDareFalso;
var
  LData: TAasFileData;
  LNormal: TVec3;
  LDist: Single;
  LTrace: TAasTrace;
begin
  LData := TAasSample.Content(0);
  LData.Faces[8].PlaneNum := 9999;
  Assert.IsFalse(TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).PointInsideFace(8, Vec(32, 32, 0), 0));
  TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).FacePlane(8, LNormal, LDist);
  Assert.AreEqual<Single>(0, LDist);
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).AreaGroundFace(1,
    Vec(32, 32, 10)));
  FillChar(LTrace, SizeOf(LTrace), 0);
  LTrace.LastArea := 1;
  LTrace.PlaneNum := 9998;
  LData.Faces[8].PlaneNum := 9998;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateFaceTester(TAasWorlds.Make(LData), nil).TraceEndFace(LTrace));
end;

{ TTestAasBoxAreas }

procedure TTestAasBoxAreas.UnBoxDovrebbeDareLeAreeCheTocca;
var
  LAreas: TArray<Integer>;
  LSum: Integer;
  LArea: Integer;
begin
  LAreas := TAasFactory.CreateBoxAreas(TAasWorlds.Sample, nil).BBoxAreas(Vec(70, 10, 10), Vec(150, 50, 50), 8);
  Assert.AreEqual<Integer>(2, Length(LAreas));
  LSum := 0;
  for LArea in LAreas do
    Inc(LSum, LArea);
  Assert.AreEqual<Integer>(5, LSum);
  LAreas := TAasFactory.CreateBoxAreas(TAasWorlds.Sample, nil).BBoxAreas(Vec(-10, 10, 10), Vec(300, 50, 50), 8);
  Assert.AreEqual<Integer>(4, Length(LAreas));
end;

procedure TTestAasBoxAreas.LeAreeDovrebberoVenireInOrdineInversoDiScoperta;
var
  LAreas: TArray<Integer>;
begin
  // the descent pushes the front child and then the back child: the back one (lower x) is visited first,
  // and the list of the links has the last one found first
  LAreas := TAasFactory.CreateBoxAreas(TAasWorlds.Sample, nil).BBoxAreas(Vec(-10, 10, 10), Vec(300, 50, 50), 8);
  Assert.AreEqual<Integer>(4, LAreas[0]);
  Assert.AreEqual<Integer>(1, LAreas[3]);
end;

procedure TTestAasBoxAreas.IlMassimoDiAreeDovrebbeTenereLeUltimeTrovate;
var
  LAreas: TArray<Integer>;
begin
  LAreas := TAasFactory.CreateBoxAreas(TAasWorlds.Sample, nil).BBoxAreas(Vec(-10, 10, 10), Vec(300, 50, 50), 2);
  Assert.AreEqual<Integer>(2, Length(LAreas));
  Assert.AreEqual<Integer>(4, LAreas[0]);
  Assert.AreEqual<Integer>(3, LAreas[1]);
end;

procedure TTestAasBoxAreas.UnBoxNelSolidoNonDovrebbeToccareAree;
begin
  Assert.AreEqual<Integer>(0, Length(TAasFactory.CreateBoxAreas(TAasWorlds.Sample, nil).BBoxAreas(Vec(10, -50, 10),
    Vec(100, -20, 50), 8)));
end;

procedure TTestAasBoxAreas.UnMassimoNonPositivoDovrebbeDareUnaListaVuota;
begin
  Assert.AreEqual<Integer>(0, Length(TAasFactory.CreateBoxAreas(TAasWorlds.Sample, nil).BBoxAreas(Vec(10, 10, 10),
    Vec(100, 50, 50), 0)));
end;

procedure TTestAasBoxAreas.UnBoxChePassaInTuttiIRamiDovrebbeStampareLoStackOverflow;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  TAasFactory.CreateBoxAreas(TAasWorlds.Chain(150), LKeeper).BBoxAreas(Vec(-10, 0, 0), Vec(2000, 5, 5), 500);
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.AreEqual('AAS_LinkEntity: stack overflow'#10, LImport.Message(0));
end;

procedure TTestAasBoxAreas.UnNodoFuoriDallaTabellaDovrebbeStampareUnErrore;
var
  LData: TAasFileData;
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LData := TAasSample.Content(0);
  LData.Nodes[1].Children[0] := 999;
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  TAasFactory.CreateBoxAreas(TAasWorlds.Make(LData), LKeeper).BBoxAreas(Vec(10, 10, 10), Vec(20, 20, 20), 8);
  Assert.AreEqual<Integer>(1, LImport.Count);
  Assert.IsTrue(LImport.Message(0).StartsWith('AAS_LinkEntity: the node 999'));
end;

{ TTestAasAreaQuery }

procedure TTestAasAreaQuery.ClusterEPresenzaDovrebberoVenireDalleImpostazioni;
var
  LQuery: IAasAreaQuery;
begin
  LQuery := TAasFactory.CreateAreaQuery(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(1, LQuery.AreaCluster(1));
  Assert.AreEqual<Integer>(2, LQuery.AreaCluster(3));
  Assert.AreEqual<Integer>(-1, LQuery.AreaCluster(4));
  Assert.AreEqual<Integer>(PRESENCE_CROUCH, LQuery.AreaPresenceType(2));
  Assert.AreEqual<Integer>(PRESENCE_NORMAL or PRESENCE_CROUCH, LQuery.AreaPresenceType(1));
end;

procedure TTestAasAreaQuery.UnNumeroDiAreaNonValidoDovrebbeStampareUnErroreEDareZero;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LQuery: IAasAreaQuery;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  LQuery := TAasFactory.CreateAreaQuery(TAasWorlds.Sample, LKeeper);
  Assert.AreEqual<Integer>(0, LQuery.AreaCluster(0));
  Assert.AreEqual<Integer>(0, LQuery.AreaCluster(5));
  Assert.AreEqual<Integer>(0, LQuery.AreaPresenceType(-1));
  Assert.AreEqual<Integer>(3, LImport.Count);
  Assert.AreEqual(PRT_ERROR, LImport.Level(0));
  Assert.AreEqual('AAS_AreaCluster: invalid area number'#10, LImport.Message(0));
  Assert.AreEqual('AAS_AreaPresenceType: invalid area number'#10, LImport.Message(2));
end;

procedure TTestAasAreaQuery.AreaInfoDovrebbeDareLeInformazioniDellArea;
var
  LInfo: TAasAreaInfo;
begin
  Assert.AreEqual<Integer>(52, TAasFactory.CreateAreaQuery(TAasWorlds.Sample, nil).AreaInfo(3, LInfo));
  Assert.AreEqual<Integer>(AREACONTENTS_JUMPPAD, LInfo.Contents);
  Assert.AreEqual<Integer>(AREA_GROUNDED or AREA_LADDER, LInfo.Flags);
  Assert.AreEqual<Integer>(PRESENCE_NORMAL or PRESENCE_CROUCH, LInfo.PresenceType);
  Assert.AreEqual<Integer>(2, LInfo.Cluster);
  Assert.AreEqual<Single>(128, LInfo.Mins[0]);
  Assert.AreEqual<Single>(192, LInfo.Maxs[0]);
  Assert.AreEqual<Single>(160, LInfo.Center[0]);
end;

procedure TTestAasAreaQuery.AreaInfoConUnNumeroNonValidoDovrebbeDareZero;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LInfo: TAasAreaInfo;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateAreaQuery(TAasWorlds.Sample, LKeeper).AreaInfo(0, LInfo));
  Assert.AreEqual<Integer>(0, LInfo.Cluster);
  Assert.AreEqual('AAS_AreaInfo: areanum 0 out of range'#10, LImport.Message(0));
end;

procedure TTestAasAreaQuery.LaRaggiungibilitaDovrebbeContareLeAreeRaggiungibili;
var
  LQuery: IAasAreaQuery;
begin
  LQuery := TAasFactory.CreateAreaQuery(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(1, LQuery.AreaReachability(1));
  Assert.AreEqual<Integer>(2, LQuery.AreaReachability(2));
  Assert.AreEqual<Integer>(1, LQuery.AreaReachability(4));
end;

procedure TTestAasAreaQuery.LaRaggiungibilitaFuoriDallaTabellaDovrebbeStampareUnErroreFatale;
var
  LImport: TFakeImport;
  LKeeper: IBotImport;
begin
  LImport := TFakeImport.Create;
  LKeeper := LImport;
  Assert.AreEqual<Integer>(0, TAasFactory.CreateAreaQuery(TAasWorlds.Sample, LKeeper).AreaReachability(9));
  Assert.AreEqual(PRT_FATAL, LImport.Level(0));
  // AAS_Error: the message of the original has no line feed
  Assert.AreEqual('AAS_AreaReachability: areanum 9 out of range', LImport.Message(0));
end;

procedure TTestAasAreaQuery.LeFunzioniPerContenutiEFlagDovrebberoGuardareLeImpostazioni;
var
  LQuery: IAasAreaQuery;
  LData: TAasFileData;
begin
  LQuery := TAasFactory.CreateAreaQuery(TAasWorlds.Sample(1), nil);
  Assert.AreEqual<Integer>(AREACONTENTS_WATER, LQuery.AreaContents(2));
  Assert.AreEqual<Integer>(AREA_GROUNDED or AREA_LIQUID, LQuery.AreaFlags(2));
  Assert.IsTrue(LQuery.AreaGrounded(1));
  Assert.IsTrue(LQuery.AreaLiquid(2));
  Assert.IsFalse(LQuery.AreaLiquid(1));
  Assert.IsTrue(LQuery.AreaLadder(3));
  Assert.IsTrue(LQuery.AreaJumpPad(3));
  Assert.IsTrue(LQuery.AreaClusterPortal(4));
  Assert.IsTrue(LQuery.AreaDoNotEnter(5));
  Assert.IsTrue(LQuery.AreaTeleporter(6));
  Assert.IsTrue(LQuery.AreaLava(6));
  Assert.IsFalse(LQuery.AreaSlime(6));
  LData := TAasSample.Content(1);
  LData.AreaSettings[1].Contents := AREACONTENTS_SLIME;
  Assert.IsTrue(TAasFactory.CreateAreaQuery(TAasWorlds.Make(LData), nil).AreaSlime(1));
end;

procedure TTestAasAreaQuery.LeFunzioniPerContenutiEFlagFuoriDallaTabellaDovrebberoDareFalso;
var
  LQuery: IAasAreaQuery;
begin
  LQuery := TAasFactory.CreateAreaQuery(TAasWorlds.Sample, nil);
  Assert.AreEqual<Integer>(0, LQuery.AreaContents(40));
  Assert.AreEqual<Integer>(0, LQuery.AreaFlags(-1));
  Assert.IsFalse(LQuery.AreaGrounded(40));
  Assert.IsFalse(LQuery.AreaLava(40));
  Assert.IsFalse(LQuery.AreaDoNotEnter(-3));
end;

end.
