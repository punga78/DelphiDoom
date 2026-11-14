{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the A star and the flow fields       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.PathFinding;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Path.Types,
  DelphiDoom.War.Path.AStar, DelphiDoom.War.Path.FlowField, DelphiDoom.War.Path.FlowFields;

type
  /// <summary>wpath_astar on a grid that the test builds</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAStar = class(TObject)
  private
    FGrid: TWarPathGrid;
    FAStar: TWarAStar;
    FPath: TWarMapPath;
    procedure Wall(AX, AY, AWidth, AHeight: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAndareDirettoSuUnCampoLibero;
    [Test]
    procedure DovrebbePartireDallaPartenzaEFinireSullArrivo;
    [Test]
    procedure DovrebbeGirareAttornoAUnMuro;
    [Test]
    procedure DovrebbeLasciareIlPercorsoComeERaSePartenzaEArrivoSonoLaStessaCasella;
    [Test]
    procedure DovrebbeLasciareIlPercorsoComeERaSeLaPartenzaERinchiusa;
    [Test]
    procedure DovrebbeAndareAllaCasellaPiuVicinaSeLArrivoERaggiungibile;
    [Test]
    procedure DovrebbeNonEntrareNellaCasellaDelloStaticoNemmenoSeEL;
    [Test]
    procedure DovrebbeNonVedereUnaUnitaChePassaMaUnaCheStaFerma;
    [Test]
    procedure DovrebbeScegliereTraDueCandidatiAPariDistanzaConLOrdineDeiBucketDelC;
    [Test]
    procedure DovrebbeSollevareUnEccezioneSePartenzaOArrivoSonoFuoriDallaMappa;
    [Test]
    procedure DovrebbePreferireLeDiagonaliPerCheCostanoUnoELaGuidaManhattanLeFaScendere;
    [Test]
    procedure DovrebbeRiusareLoStessoCercatoreSenzaRicordarsiDellaRicercaPrima;
  end;

  /// <summary>The flow fields: the Dijkstra of wpath_flowField and the cache of wpath_computeFlowField and the others</summary>
  [TestFixture]
  [Category('war')]
  TTestWarFlowFields = class(TObject)
  private
    FGrid: TWarPathGrid;
    FFields: TWarFlowFields;
    function IndexOf(AX, AY: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareCostoZeroNullaIlGoalSenzaDirezione;
    [Test]
    procedure DovrebbeContareCentoPerUnPassoSuUnAsseECentoquarantunoInDiagonale;
    [Test]
    procedure DovrebbePuntareVersoIlGoalDaOgniCasella;
    [Test]
    procedure DovrebbeNonEntrareNelleCaselleStaticheEGirarvi;
    [Test]
    procedure DovrebbeLasciareSenzaDirezioneLeCaselleChiuseDaiMuriECostoMassimo;
    [Test]
    procedure DovrebbeTagliareLAngoloTraDueCaselleStaticheInDiagonale;
    [Test]
    procedure DovrebbeLasciarePartireDaUnaCasellaStaticaComeGoal;
    [Test]
    procedure DovrebbeDareIlVettoreUnitarioDellaDirezioneNelCampione;
    [Test]
    procedure DovrebbeDareIlVettoreNulloNelCampioneDelGoalODiUnaCasellaIrraggiungibile;
    [Test]
    procedure DovrebbeSollevareUnEccezioneNelCampioneFuoriDallaMappa;
    [Test]
    procedure DovrebbeTenereIlCampoFinoAChiNonLoRifaGetEEnsure;
    [Test]
    procedure DovrebbeRifareIlCampoSoloSeSiChiedeCompute;
    [Test]
    procedure DovrebbeSovrascrivereIlCampoDelloStessoGoalChiLoTiene;
    [Test]
    procedure DovrebbeContareICampiEILoroCalcoli;
    [Test]
    procedure DovrebbeSollevareUnEccezioneSeIlGoalEFuoriDallaMappa;
    [Test]
    procedure DovrebbeTenereLaFirmaDeiCampiSoloSeLaSiChiede;
    [Test]
    procedure DovrebbeDareFirmeDiverseSeLaGrigliaCambiaTraDueCalcoli;
  end;

implementation

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Types, DelphiDoom.Tests.War.RealData;

{ TTestWarAStar }

procedure TTestWarAStar.Setup;
var
  LZeros: TArray<Word>;
begin
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FAStar := TWarAStar.Create(FGrid);
  FPath.Count := 0;
end;

procedure TTestWarAStar.TearDown;
begin
  FAStar.Free;
  FGrid.Free;
end;

procedure TTestWarAStar.Wall(AX, AY, AWidth, AHeight: Integer);
begin
  FGrid.SetStaticEntity(AX, AY, AWidth, AHeight, 7);
end;

procedure TTestWarAStar.DovrebbeAndareDirettoSuUnCampoLibero;
begin
  Assert.IsTrue(FAStar.FindPath(2, 2, 12, 2, FPath));
  // eleven tiles along the row
  Assert.AreEqual(11, FPath.Count);
  Assert.AreEqual(12, Integer(FPath.Nodes[10].X));
end;

procedure TTestWarAStar.DovrebbePartireDallaPartenzaEFinireSullArrivo;
begin
  Assert.IsTrue(FAStar.FindPath(5, 7, 20, 30, FPath));
  Assert.AreEqual(5, Integer(FPath.Nodes[0].X));
  Assert.AreEqual(7, Integer(FPath.Nodes[0].Y));
  Assert.AreEqual(20, Integer(FPath.Nodes[FPath.Count - 1].X));
  Assert.AreEqual(30, Integer(FPath.Nodes[FPath.Count - 1].Y));
end;

procedure TTestWarAStar.DovrebbeGirareAttornoAUnMuro;
var
  LIndex: Integer;
begin
  Wall(10, 0, 1, 20);
  Assert.IsTrue(FAStar.FindPath(5, 5, 15, 5, FPath));
  Assert.AreEqual(15, Integer(FPath.Nodes[FPath.Count - 1].X));
  for LIndex := 0 to FPath.Count - 1 do
    Assert.IsFalse(FGrid.IsStatic(FPath.Nodes[LIndex].X, FPath.Nodes[LIndex].Y), 'un passo nel muro');
  // it has to go down to the end of the wall and come back
  Assert.IsTrue(FPath.Count > 16);
end;

procedure TTestWarAStar.DovrebbeLasciareIlPercorsoComeERaSePartenzaEArrivoSonoLaStessaCasella;
begin
  FPath.Count := 77;
  Assert.IsFalse(FAStar.FindPath(4, 4, 4, 4, FPath));
  Assert.AreEqual(77, FPath.Count);
end;

procedure TTestWarAStar.DovrebbeLasciareIlPercorsoComeERaSeLaPartenzaERinchiusa;
begin
  // a unit that stands in a pit of static tiles: one tile is closed and the original does not write the path
  Wall(9, 9, 3, 1);
  Wall(9, 11, 3, 1);
  Wall(9, 10, 1, 1);
  Wall(11, 10, 1, 1);
  FPath.Count := 5;
  Assert.IsFalse(FAStar.FindPath(10, 10, 30, 30, FPath));
  Assert.AreEqual(5, FPath.Count);
end;

procedure TTestWarAStar.DovrebbeAndareAllaCasellaPiuVicinaSeLArrivoERaggiungibile;
var
  LIndex: Integer;
begin
  // the end is shut in a box: the path goes to the tile that was reached and is closest to it
  for LIndex := 28 to 32 do
  begin
    Wall(LIndex, 28, 1, 1);
    Wall(LIndex, 32, 1, 1);
    Wall(28, LIndex, 1, 1);
    Wall(32, LIndex, 1, 1);
  end;
  Assert.IsTrue(FAStar.FindPath(10, 30, 30, 30, FPath));
  Assert.AreEqual(27, Integer(FPath.Nodes[FPath.Count - 1].X));
  Assert.AreEqual(30, Integer(FPath.Nodes[FPath.Count - 1].Y));
end;

procedure TTestWarAStar.DovrebbeNonEntrareNellaCasellaDelloStaticoNemmenoSeEL;
begin
  // the end itself is static: it is never entered, so it counts as not reachable and the path stops next to it
  Wall(20, 20, 1, 1);
  Assert.IsTrue(FAStar.FindPath(10, 20, 20, 20, FPath));
  Assert.IsTrue((FPath.Nodes[FPath.Count - 1].X <> 20) or (FPath.Nodes[FPath.Count - 1].Y <> 20));
  Assert.AreEqual(19, Integer(FPath.Nodes[FPath.Count - 1].X));
end;

procedure TTestWarAStar.DovrebbeNonVedereUnaUnitaChePassaMaUnaCheStaFerma;
begin
  // what a unit that stands still occupies is static for the path finding: the path goes around it
  FGrid.SetStaticEntity(15, 10, 1, 1, 42);
  Assert.IsTrue(FAStar.FindPath(10, 10, 20, 10, FPath));
  Assert.AreEqual(20, Integer(FPath.Nodes[FPath.Count - 1].X));
  Assert.IsTrue(FPath.Count >= 11);
end;

procedure TTestWarAStar.DovrebbeScegliereTraDueCandidatiAPariDistanzaConLOrdineDeiBucketDelC;
var
  LAll: TStringList;
  LLine: string;
  LVariant: Integer;
  LY: Integer;
  LIndex: Integer;
  LHash: Cardinal;
  LActual: string;
  LGoldenLines: TStringList;
begin
  LAll := TStringList.Create;
  LGoldenLines := TStringList.Create;
  try
    LAll.LoadFromFile(TWarRealData.GoldenPath('path.units.golden.txt'));
    for LLine in LAll do
      if (LLine <> '') and (LLine[1] = 'T') then
        LGoldenLines.Add(LLine);
    Assert.AreEqual(4, LGoldenLines.Count);
    for LVariant := 0 to 3 do
    begin
      TearDown;
      Setup;
      LY := 10 + LVariant * 11;
      for LIndex := 0 to 63 do
        Wall(26, LIndex, 1, 1);
      Wall(25, LY, 1, 1);
      FPath.Count := 0;
      FAStar.FindPath(10, LY, 30, LY, FPath);
      LHash := 2166136261;
      for LIndex := 0 to FPath.Count - 1 do
      begin
        LHash := (LHash xor Cardinal(FPath.Nodes[LIndex].X)) * 16777619;
        LHash := (LHash xor Cardinal(FPath.Nodes[LIndex].Y)) * 16777619;
      end;
      LActual := Format('T %d 10,%d -> 30,%d n=%d last=%d,%d h=%s', [LVariant, LY, LY, FPath.Count,
        FPath.Nodes[FPath.Count - 1].X, FPath.Nodes[FPath.Count - 1].Y, LowerCase(IntToHex(LHash, 8))]);
      Assert.AreEqual(LGoldenLines[LVariant], LActual);
    end;
  finally
    LGoldenLines.Free;
    LAll.Free;
  end;
end;

procedure TTestWarAStar.DovrebbeSollevareUnEccezioneSePartenzaOArrivoSonoFuoriDallaMappa;
begin
  Assert.WillRaise(
    procedure
    begin
      FAStar.FindPath(-1, 0, 5, 5, FPath);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FAStar.FindPath(0, 0, 64, 5, FPath);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FAStar.FindPath(0, 0, 5, 64, FPath);
    end, EWarException);
end;

procedure TTestWarAStar.DovrebbePreferireLeDiagonaliPerCheCostanoUnoELaGuidaManhattanLeFaScendere;
begin
  // every step costs 1, a diagonal too, and the guess is the Manhattan distance (it overestimates): a diagonal step lowers
  // the score by one, so on a free field the A star goes along the diagonal (eleven tiles from (0,0) to (10,10))
  Assert.IsTrue(FAStar.FindPath(0, 0, 10, 10, FPath));
  Assert.AreEqual(11, FPath.Count);
  Assert.AreEqual(5, Integer(FPath.Nodes[5].X));
  Assert.AreEqual(5, Integer(FPath.Nodes[5].Y));
end;

procedure TTestWarAStar.DovrebbeRiusareLoStessoCercatoreSenzaRicordarsiDellaRicercaPrima;
var
  LFirst: TWarMapPath;
begin
  Assert.IsTrue(FAStar.FindPath(1, 1, 30, 40, FPath));
  LFirst := FPath;
  FPath.Count := 0;
  Assert.IsTrue(FAStar.FindPath(1, 1, 30, 40, FPath));
  Assert.AreEqual(LFirst.Count, FPath.Count);
  Assert.IsTrue(FAStar.FindPath(50, 50, 3, 3, FPath));
  Assert.AreEqual(3, Integer(FPath.Nodes[FPath.Count - 1].X));
end;

{ TTestWarFlowFields }

function TTestWarFlowFields.IndexOf(AX, AY: Integer): Integer;
begin
  Result := AY * 64 + AX;
end;

procedure TTestWarFlowFields.Setup;
var
  LZeros: TArray<Word>;
begin
  SetLength(LZeros, 4096);
  FGrid := TWarPathGrid.Create(LZeros);
  FFields := TWarFlowFields.Create(FGrid);
end;

procedure TTestWarFlowFields.TearDown;
begin
  FFields.Free;
  FGrid.Free;
end;

procedure TTestWarFlowFields.DovrebbeDareCostoZeroNullaIlGoalSenzaDirezione;
var
  LField: TWarFlowField;
begin
  LField := FFields.Compute(20, 20);
  // the goal is the start of the search: it gets neither a direction nor a cost
  Assert.AreEqual(WAR_FLOW_NO_DIRECTION, LField.Direction[IndexOf(20, 20)]);
  Assert.AreEqual(WAR_FLOW_UNREACHED, LField.Cost[IndexOf(20, 20)]);
end;

procedure TTestWarFlowFields.DovrebbeContareCentoPerUnPassoSuUnAsseECentoquarantunoInDiagonale;
var
  LField: TWarFlowField;
begin
  LField := FFields.Compute(20, 20);
  Assert.AreEqual(100, LField.Cost[IndexOf(21, 20)]);
  Assert.AreEqual(100, LField.Cost[IndexOf(20, 19)]);
  Assert.AreEqual(141, LField.Cost[IndexOf(21, 21)]);
  Assert.AreEqual(241, LField.Cost[IndexOf(22, 21)]);
  Assert.AreEqual(500, LField.Cost[IndexOf(25, 20)]);
end;

procedure TTestWarFlowFields.DovrebbePuntareVersoIlGoalDaOgniCasella;
var
  LField: TWarFlowField;
  LX: Integer;
  LY: Integer;
  LDirection: Integer;
  LNextX: Integer;
  LNextY: Integer;
begin
  LField := FFields.Compute(30, 30);
  for LY := 0 to 63 do
    for LX := 0 to 63 do
    begin
      if (LX = 30) and (LY = 30) then
        Continue;
      LDirection := LField.Direction[IndexOf(LX, LY)];
      Assert.IsTrue(LDirection < WAR_FLOW_NO_DIRECTION, 'la casella ha una direzione');
      LNextX := LX + WAR_PATH_DIR_X[LDirection];
      LNextY := LY + WAR_PATH_DIR_Y[LDirection];
      // one step in that direction costs less (or arrives)
      if (LNextX <> 30) or (LNextY <> 30) then
        Assert.IsTrue(LField.Cost[IndexOf(LNextX, LNextY)] < LField.Cost[IndexOf(LX, LY)], 'costo che scende');
    end;
end;

procedure TTestWarFlowFields.DovrebbeNonEntrareNelleCaselleStaticheEGirarvi;
var
  LField: TWarFlowField;
begin
  FGrid.SetStaticEntity(25, 0, 1, 40, 3);
  LField := FFields.Compute(30, 20);
  // the static tiles are not in the field
  Assert.AreEqual(WAR_FLOW_NO_DIRECTION, LField.Direction[IndexOf(25, 10)]);
  Assert.AreEqual(WAR_FLOW_UNREACHED, LField.Cost[IndexOf(25, 10)]);
  // and a tile behind the wall goes around it: it costs more than the straight way
  Assert.IsTrue(LField.Cost[IndexOf(20, 20)] > 1000);
end;

procedure TTestWarFlowFields.DovrebbeLasciareSenzaDirezioneLeCaselleChiuseDaiMuriECostoMassimo;
var
  LField: TWarFlowField;
  LIndex: Integer;
begin
  for LIndex := 9 to 15 do
  begin
    FGrid.SetStaticEntity(LIndex, 9, 1, 1, 3);
    FGrid.SetStaticEntity(LIndex, 15, 1, 1, 3);
    FGrid.SetStaticEntity(9, LIndex, 1, 1, 3);
    FGrid.SetStaticEntity(15, LIndex, 1, 1, 3);
  end;
  LField := FFields.Compute(30, 30);
  Assert.AreEqual(WAR_FLOW_NO_DIRECTION, LField.Direction[IndexOf(12, 12)]);
  Assert.AreEqual(WAR_FLOW_UNREACHED, LField.Cost[IndexOf(12, 12)]);
  Assert.IsTrue(LField.Direction[IndexOf(5, 5)] < WAR_FLOW_NO_DIRECTION);
end;

procedure TTestWarFlowFields.DovrebbeTagliareLAngoloTraDueCaselleStaticheInDiagonale;
var
  LField: TWarFlowField;
begin
  // defect of the original kept: a diagonal step is allowed between two static tiles that touch only at the corner
  FGrid.SetStaticEntity(11, 10, 1, 1, 3);
  FGrid.SetStaticEntity(10, 11, 1, 1, 3);
  LField := FFields.Compute(11, 11);
  // the tile (10, 10) reaches (11, 11) along the diagonal at the cost of one diagonal step
  Assert.AreEqual(141, LField.Cost[IndexOf(10, 10)]);
  Assert.AreEqual(3, LField.Direction[IndexOf(10, 10)]);
end;

procedure TTestWarFlowFields.DovrebbeLasciarePartireDaUnaCasellaStaticaComeGoal;
var
  LField: TWarFlowField;
begin
  // the goal is not looked at: a goal on a static tile (a building, a tree) still makes a field around it
  FGrid.SetStaticEntity(20, 20, 2, 2, 9);
  LField := FFields.Compute(20, 20);
  Assert.AreEqual(WAR_FLOW_NO_DIRECTION, LField.Direction[IndexOf(20, 20)]);
  Assert.IsTrue(LField.Direction[IndexOf(19, 20)] < WAR_FLOW_NO_DIRECTION);
end;

procedure TTestWarFlowFields.DovrebbeDareIlVettoreUnitarioDellaDirezioneNelCampione;
var
  LField: TWarFlowField;
  LVector: TWarVec2;
begin
  LField := FFields.Compute(20, 20);
  // west of the goal the way goes east
  LVector := LField.Sample(15, 20);
  Assert.IsTrue(LVector.X = 1);
  Assert.IsTrue(LVector.Y = 0);
  // north west of the goal the way goes south east: a diagonal is normalized
  LVector := LField.Sample(15, 15);
  Assert.IsTrue(Abs(LVector.X - 0.70710677) < 0.0000001);
  Assert.IsTrue(Abs(LVector.Y - 0.70710677) < 0.0000001);
end;

procedure TTestWarFlowFields.DovrebbeDareIlVettoreNulloNelCampioneDelGoalODiUnaCasellaIrraggiungibile;
var
  LField: TWarFlowField;
  LVector: TWarVec2;
begin
  FGrid.SetStaticEntity(10, 10, 1, 1, 3);
  LField := FFields.Compute(20, 20);
  LVector := LField.Sample(20, 20);
  Assert.IsTrue((LVector.X = 0) and (LVector.Y = 0));
  LVector := LField.Sample(10, 10);
  Assert.IsTrue((LVector.X = 0) and (LVector.Y = 0));
end;

procedure TTestWarFlowFields.DovrebbeSollevareUnEccezioneNelCampioneFuoriDallaMappa;
var
  LField: TWarFlowField;
begin
  LField := FFields.Compute(20, 20);
  Assert.WillRaise(
    procedure
    begin
      LField.Sample(64, 0);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      LField.Sample(0, -1);
    end, EWarException);
end;

procedure TTestWarFlowFields.DovrebbeTenereIlCampoFinoAChiNonLoRifaGetEEnsure;
var
  LField: TWarFlowField;
  LCost: Integer;
begin
  Assert.IsNull(FFields.Get(20, 20), 'prima non c''e''');
  LField := FFields.Ensure(20, 20);
  Assert.IsNotNull(LField);
  LCost := LField.Cost[IndexOf(25, 20)];
  // what is put on the grid afterwards does not change a field that was made: the original never invalidates it
  FGrid.SetStaticEntity(22, 0, 1, 40, 5);
  Assert.AreSame(LField, FFields.Ensure(20, 20));
  Assert.AreSame(LField, FFields.Get(20, 20));
  Assert.AreEqual(LCost, FFields.Ensure(20, 20).Cost[IndexOf(25, 20)]);
  Assert.AreEqual(1, FFields.ComputeCount);
end;

procedure TTestWarFlowFields.DovrebbeRifareIlCampoSoloSeSiChiedeCompute;
var
  LField: TWarFlowField;
begin
  LField := FFields.Ensure(20, 20);
  Assert.AreEqual(500, LField.Cost[IndexOf(25, 20)]);
  FGrid.SetStaticEntity(22, 0, 1, 40, 5);
  FFields.Compute(20, 20);
  Assert.IsTrue(LField.Cost[IndexOf(25, 20)] > 500, 'ora gira attorno al muro');
  Assert.AreEqual(2, FFields.ComputeCount);
end;

procedure TTestWarFlowFields.DovrebbeSovrascrivereIlCampoDelloStessoGoalChiLoTiene;
var
  LFirst: TWarFlowField;
  LSecond: TWarFlowField;
begin
  LFirst := FFields.Compute(20, 20);
  LSecond := FFields.Compute(20, 20);
  Assert.AreSame(LFirst, LSecond);
  Assert.AreEqual(1, FFields.Count);
end;

procedure TTestWarFlowFields.DovrebbeContareICampiEILoroCalcoli;
begin
  FFields.Compute(1, 1);
  FFields.Compute(2, 2);
  FFields.Compute(2, 2);
  FFields.Ensure(3, 3);
  FFields.Ensure(3, 3);
  Assert.AreEqual(3, FFields.Count);
  Assert.AreEqual(4, FFields.ComputeCount);
end;

procedure TTestWarFlowFields.DovrebbeSollevareUnEccezioneSeIlGoalEFuoriDallaMappa;
begin
  Assert.WillRaise(
    procedure
    begin
      FFields.Compute(-1, 5);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FFields.Get(5, 64);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FFields.Ensure(64, 64);
    end, EWarException);
end;

procedure TTestWarFlowFields.DovrebbeTenereLaFirmaDeiCampiSoloSeLaSiChiede;
var
  LBasis: Cardinal;
begin
  LBasis := FFields.Signature;
  FFields.Compute(10, 10);
  Assert.AreEqual(LBasis, FFields.Signature, 'spenta di default');
  FFields.TrackSignature := True;
  FFields.Compute(10, 10);
  Assert.AreNotEqual(LBasis, FFields.Signature);
end;

procedure TTestWarFlowFields.DovrebbeDareFirmeDiverseSeLaGrigliaCambiaTraDueCalcoli;
var
  LOther: TWarFlowFields;
  LZeros: TArray<Word>;
  LOtherGrid: TWarPathGrid;
begin
  SetLength(LZeros, 4096);
  LOtherGrid := TWarPathGrid.Create(LZeros);
  LOther := TWarFlowFields.Create(LOtherGrid);
  try
    FFields.TrackSignature := True;
    LOther.TrackSignature := True;
    FFields.Compute(10, 10);
    LOther.Compute(10, 10);
    Assert.AreEqual(FFields.Signature, LOther.Signature, 'la stessa griglia, la stessa firma');
    LOtherGrid.SetStaticEntity(15, 10, 1, 1, 4);
    FFields.Compute(30, 30);
    LOther.Compute(30, 30);
    Assert.AreNotEqual(FFields.Signature, LOther.Signature);
  finally
    LOther.Free;
    LOtherGrid.Free;
  end;
end;

end.
