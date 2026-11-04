{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the node building of the glbsp port                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Node.Builder;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Level.Analyzer,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Node.Builder,
  DelphiDoom.Glbsp.Node.Partitioner,
  DelphiDoom.Glbsp.Node.SuperBlocks,
  DelphiDoom.Glbsp.Options;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspNodeBuilder = class(TObject)
  private
    FData: TGlbspLevelData;
    FOptions: TGlbspOptions;
    FMessages: TStringList;
    FAnalyzer: TGlbspLevelAnalyzer;
    FPartitioner: TGlbspPartitioner;
    FBuilder: TGlbspNodeBuilder;
    FRoot: TGlbspNode;
    FRootSub: TGlbspSubsec;
    procedure CreateObjects;
    function AddVertex(const AX, AY: Double): TGlbspVertex;
    function AddLine(const AStart, AEnd: TGlbspVertex; const ARight,
      ALeft: TGlbspSidedef): TGlbspLinedef;
    function AddSidedef(const ASector: TGlbspSector): TGlbspSidedef;
    procedure AddClosedRoom(const ACoordinates: array of Integer);
    procedure BuildTree;
    function RoomBounds: TGlbspBlockmapBounds;
    function CountSegs(const AReal: Boolean): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSuperBloccoContaSegReaEMiniseg;
    [Test]
    procedure TestSuperBloccoSegCheAttraversaIlCentroRestaNelPadre;
    [Test]
    procedure TestScatolaRispettoAUnaPartizione;
    [Test]
    procedure TestCreaSegSaltaLineeNulleESovrapposte;
    [Test]
    procedure TestCreaSegPartnerSuLineaADueLati;
    [Test]
    procedure TestStanzaConvessaDiventaUnSoloSubsettore;
    [Test]
    procedure TestStanzaAEleCreaNodiESubsettoriConvessi;
    [Test]
    procedure TestOrdineOrarioDeiSegDiUnSubsettore;
    [Test]
    procedure TestNormalizzazioneTogliLeMiniseg;
    [Test]
    procedure TestAltezzaDellAlbero;
    [Test]
    procedure TestLimitiDiUnaListaDiSeg;
  end;

implementation

{ TTestGlbspNodeBuilder }

procedure TTestGlbspNodeBuilder.Setup;
begin
  FData := TGlbspLevelData.Create;
  FOptions := TGlbspOptions.Default;
  FOptions.MiniWarnings := True;
  FMessages := TStringList.Create;
end;

procedure TTestGlbspNodeBuilder.TearDown;
begin
  FBuilder.Free;
  FPartitioner.Free;
  FAnalyzer.Free;
  FMessages.Free;
  FData.Free;
end;

procedure TTestGlbspNodeBuilder.CreateObjects;
begin
  FAnalyzer := TGlbspLevelAnalyzer.Create(FData, FOptions, FMessages);
  FPartitioner := TGlbspPartitioner.Create(FData, FAnalyzer, FOptions, FMessages);
  FBuilder := TGlbspNodeBuilder.Create(FData, FAnalyzer, FPartitioner, FOptions, nil,
    FMessages);
end;

function TTestGlbspNodeBuilder.AddVertex(const AX, AY: Double): TGlbspVertex;
begin
  Result := FData.NewVertex;
  Result.X := AX;
  Result.Y := AY;
  Result.Index := FData.Vertices.Count - 1;
end;

function TTestGlbspNodeBuilder.AddSidedef(const ASector: TGlbspSector): TGlbspSidedef;
begin
  Result := FData.NewSidedef;
  Result.Sector := ASector;
  Result.Index := FData.Sidedefs.Count - 1;
  Inc(ASector.RefCount);
end;

function TTestGlbspNodeBuilder.AddLine(const AStart, AEnd: TGlbspVertex; const ARight,
  ALeft: TGlbspSidedef): TGlbspLinedef;
begin
  Result := FData.NewLinedef;
  Result.Start := AStart;
  Result.EndVertex := AEnd;
  Result.Right := ARight;
  Result.Left := ALeft;
  Result.TwoSided := Assigned(ALeft);
  Result.Index := FData.Linedefs.Count - 1;
  Result.ZeroLength := (Abs(AStart.X - AEnd.X) < DIST_EPSILON) and
    (Abs(AStart.Y - AEnd.Y) < DIST_EPSILON);
end;

// A room with one sector and one sided lines; the points go clockwise, so
// the inside of the room is on the right of every line
procedure TTestGlbspNodeBuilder.AddClosedRoom(const ACoordinates: array of Integer);
var
  LSector: TGlbspSector;
  LVertices: array of TGlbspVertex;
  LCount, LIndex: Integer;
begin
  LSector := FData.NewSector;
  LSector.Index := FData.Sectors.Count - 1;
  LCount := Length(ACoordinates) div 2;
  SetLength(LVertices, LCount);
  for LIndex := 0 to LCount - 1 do
    LVertices[LIndex] := AddVertex(ACoordinates[2 * LIndex], ACoordinates[2 * LIndex + 1]);
  for LIndex := 0 to LCount - 1 do
    AddLine(LVertices[LIndex], LVertices[(LIndex + 1) mod LCount], AddSidedef(LSector), nil);
end;

function TTestGlbspNodeBuilder.RoomBounds: TGlbspBlockmapBounds;
begin
  Result.X := -8;
  Result.Y := -8;
  Result.Width := 5;
  Result.Height := 5;
end;

procedure TTestGlbspNodeBuilder.BuildTree;
var
  LBlock: TGlbspSuperBlock;
begin
  CreateObjects;
  FAnalyzer.CalculateWallTips;
  LBlock := FBuilder.CreateSegs(RoomBounds);
  try
    FBuilder.BuildNodes(LBlock, FRoot, FRootSub, 0, nil);
  finally
    LBlock.Free;
  end;
  FBuilder.ClockwiseBspTree;
end;

function TTestGlbspNodeBuilder.CountSegs(const AReal: Boolean): Integer;
var
  LSeg: TGlbspSeg;
begin
  Result := 0;
  for LSeg in FData.Segs do
  begin
    if Assigned(LSeg.Linedef) = AReal then
      Inc(Result);
  end;
end;

procedure TTestGlbspNodeBuilder.TestSuperBloccoContaSegReaEMiniseg;
var
  LBlock: TGlbspSuperBlock;
  LReal, LMini: TGlbspSeg;
  LLine: TGlbspLinedef;
begin
  LBlock := TGlbspSuperBlock.Create;
  try
    LBlock.X1 := 0;
    LBlock.Y1 := 0;
    LBlock.X2 := 1024;
    LBlock.Y2 := 1024;
    LLine := FData.NewLinedef;
    LReal := FData.NewSeg;
    LReal.Linedef := LLine;
    LReal.Start := AddVertex(10, 10);
    LReal.EndVertex := AddVertex(20, 10);
    LMini := FData.NewSeg;
    LMini.Start := AddVertex(600, 10);
    LMini.EndVertex := AddVertex(700, 10);

    TGlbspSuperBlocks.AddSegToSuper(LBlock, LReal);
    TGlbspSuperBlocks.AddSegToSuper(LBlock, LMini);

    Assert.AreEqual(1, LBlock.RealNum);
    Assert.AreEqual(1, LBlock.MiniNum);
    // Both are in leaf blocks of 256 below the top block
    Assert.IsNull(LBlock.Segs);
    Assert.IsNotNull(LReal.Block);
    Assert.IsTrue(LReal.Block.IsLeaf);
    Assert.AreEqual(0, LReal.Block.X1);
    Assert.AreEqual(256, LReal.Block.X2 - LReal.Block.X1);
  finally
    LBlock.Free;
  end;
end;

procedure TTestGlbspNodeBuilder.TestSuperBloccoSegCheAttraversaIlCentroRestaNelPadre;
var
  LBlock: TGlbspSuperBlock;
  LSeg: TGlbspSeg;
begin
  LBlock := TGlbspSuperBlock.Create;
  try
    LBlock.X2 := 1024;
    LBlock.Y2 := 1024;
    LSeg := FData.NewSeg;
    LSeg.Linedef := FData.NewLinedef;
    LSeg.Start := AddVertex(500, 100);
    LSeg.EndVertex := AddVertex(600, 100);

    TGlbspSuperBlocks.AddSegToSuper(LBlock, LSeg);

    Assert.AreSame(LBlock, LSeg.Block);
    Assert.AreSame(LSeg, LBlock.Segs);
  finally
    LBlock.Free;
  end;
end;

procedure TTestGlbspNodeBuilder.TestScatolaRispettoAUnaPartizione;
var
  LBox: TGlbspSuperBlock;
  LPart: TGlbspSeg;
begin
  LBox := TGlbspSuperBlock.Create;
  LPart := FData.NewSeg;
  try
    // The partition goes up along x = 0
    LPart.Start := AddVertex(0, 0);
    LPart.EndVertex := AddVertex(0, 10);
    TGlbspPartitioner.RecomputeSeg(LPart);

    LBox.X1 := 100;
    LBox.X2 := 200;
    Assert.AreEqual(1, TGlbspSuperBlocks.BoxOnLineSide(LBox, LPart));
    LBox.X1 := -200;
    LBox.X2 := -100;
    Assert.AreEqual(-1, TGlbspSuperBlocks.BoxOnLineSide(LBox, LPart));
    LBox.X1 := -50;
    LBox.X2 := 50;
    Assert.AreEqual(0, TGlbspSuperBlocks.BoxOnLineSide(LBox, LPart));
  finally
    LBox.Free;
  end;
end;

procedure TTestGlbspNodeBuilder.TestCreaSegSaltaLineeNulleESovrapposte;
var
  LSector: TGlbspSector;
  LA, LB, LC: TGlbspVertex;
  LBlock: TGlbspSuperBlock;
  LLine: TGlbspLinedef;
begin
  LSector := FData.NewSector;
  LA := AddVertex(0, 0);
  LB := AddVertex(64, 0);
  LC := AddVertex(64, 64);
  AddLine(LA, LB, AddSidedef(LSector), nil);
  // A zero length line and a line that overlaps the first one
  AddLine(LC, LC, AddSidedef(LSector), nil);
  LLine := AddLine(LA, LB, AddSidedef(LSector), nil);
  LLine.Overlap := FData.Linedefs[0];
  CreateObjects;

  LBlock := FBuilder.CreateSegs(RoomBounds);
  try
    Assert.AreEqual(1, FData.Segs.Count);
    Assert.AreEqual(1, LBlock.RealNum);
  finally
    LBlock.Free;
  end;
end;

procedure TTestGlbspNodeBuilder.TestCreaSegPartnerSuLineaADueLati;
var
  LSectorA, LSectorB: TGlbspSector;
  LA, LB: TGlbspVertex;
  LBlock: TGlbspSuperBlock;
begin
  LSectorA := FData.NewSector;
  LSectorB := FData.NewSector;
  LA := AddVertex(0, 0);
  LB := AddVertex(64, 0);
  AddLine(LA, LB, AddSidedef(LSectorA), AddSidedef(LSectorB));
  CreateObjects;

  LBlock := FBuilder.CreateSegs(RoomBounds);
  try
    Assert.AreEqual(2, FData.Segs.Count);
    Assert.AreSame(FData.Segs[1], FData.Segs[0].Partner);
    Assert.AreSame(FData.Segs[0], FData.Segs[1].Partner);
    Assert.AreEqual(0, FData.Segs[0].Side);
    Assert.AreEqual(1, FData.Segs[1].Side);
    Assert.AreSame(LB, FData.Segs[1].Start);
    Assert.AreSame(LSectorB, FData.Segs[1].Sector);
    Assert.AreEqual(Double(64), FData.Segs[0].PLength, 1E-9);
    Assert.AreEqual(Double(0), FData.Segs[0].PAngle, 1E-9);
  finally
    LBlock.Free;
  end;
end;

procedure TTestGlbspNodeBuilder.TestStanzaConvessaDiventaUnSoloSubsettore;
begin
  AddClosedRoom([0, 0, 0, 128, 128, 128, 128, 0]);

  BuildTree;

  Assert.IsNull(FRoot);
  Assert.IsNotNull(FRootSub);
  Assert.AreEqual(1, FData.Subsecs.Count);
  Assert.AreEqual(0, FData.Nodes.Count);
  Assert.AreEqual(4, FRootSub.SegCount);
  Assert.AreEqual(4, FData.NumCompleteSeg);
  Assert.AreEqual(Double(64), FRootSub.MidX, 1E-9);
  Assert.AreEqual(Double(64), FRootSub.MidY, 1E-9);
  Assert.AreEqual(0, FMessages.Count);
end;

procedure TTestGlbspNodeBuilder.TestStanzaAEleCreaNodiESubsettoriConvessi;
var
  LSub: TGlbspSubsec;
  LSegs: Integer;
  LHasReal: Boolean;
  LSeg: TGlbspSeg;
begin
  // L shaped room, clockwise: concave at (64,64)
  AddClosedRoom([0, 0, 0, 128, 64, 128, 64, 64, 128, 64, 128, 0]);

  BuildTree;

  Assert.IsNotNull(FRoot);
  Assert.IsNull(FRootSub);
  Assert.IsTrue(FData.Nodes.Count >= 1);
  Assert.IsTrue(FData.Subsecs.Count >= 2);
  Assert.IsTrue(CountSegs(False) >= 2, 'minisegs were expected');
  LSegs := 0;
  for LSub in FData.Subsecs do
  begin
    Inc(LSegs, LSub.SegCount);
    LHasReal := False;
    LSeg := LSub.SegList;
    while Assigned(LSeg) do
    begin
      LHasReal := LHasReal or Assigned(LSeg.Linedef);
      LSeg := LSeg.Next;
    end;
    Assert.IsTrue(LHasReal, 'a subsector without real segs');
  end;
  Assert.AreEqual(LSegs, FData.NumCompleteSeg);
  Assert.AreEqual(FData.Segs.Count, FData.NumCompleteSeg);
  // Every subsector is closed and in a single sector
  Assert.AreEqual(0, FMessages.Count, FMessages.Text);
  Assert.IsTrue(FData.NumGlVert >= 1, 'the splits create GL vertices');
end;

procedure TTestGlbspNodeBuilder.TestOrdineOrarioDeiSegDiUnSubsettore;
var
  LSeg: TGlbspSeg;
  LNext: TGlbspSeg;
begin
  AddClosedRoom([0, 0, 0, 128, 128, 128, 128, 0]);

  BuildTree;

  // Each seg ends where the next one starts, and the angles from the middle
  // descend (clockwise)
  LSeg := FRootSub.SegList;
  while Assigned(LSeg) do
  begin
    if Assigned(LSeg.Next) then
      LNext := LSeg.Next
    else
      LNext := FRootSub.SegList;
    Assert.AreSame(LSeg.EndVertex, LNext.Start);
    LSeg := LSeg.Next;
  end;
  Assert.AreEqual(0, FRootSub.SegList.Index);
  Assert.AreEqual(3, FRootSub.SegList.Next.Next.Next.Index);
end;

procedure TTestGlbspNodeBuilder.TestNormalizzazioneTogliLeMiniseg;
var
  LSub: TGlbspSubsec;
  LSeg: TGlbspSeg;
  LReal: Integer;
begin
  AddClosedRoom([0, 0, 0, 128, 64, 128, 64, 64, 128, 64, 128, 0]);
  BuildTree;
  Assert.IsTrue(CountSegs(False) > 0);

  FBuilder.NormaliseBspTree;

  LReal := 0;
  for LSub in FData.Subsecs do
  begin
    LSeg := LSub.SegList;
    while Assigned(LSeg) do
    begin
      Assert.IsNotNull(LSeg.Linedef, 'a miniseg is left');
      Inc(LReal);
      LSeg := LSeg.Next;
    end;
  end;
  Assert.AreEqual(CountSegs(True), LReal);
  Assert.AreEqual(LReal, FData.NumCompleteSeg);
end;

procedure TTestGlbspNodeBuilder.TestAltezzaDellAlbero;
begin
  Assert.AreEqual(1, TGlbspNodeBuilder.ComputeBspHeight(nil));
  AddClosedRoom([0, 0, 0, 128, 64, 128, 64, 64, 128, 64, 128, 0]);
  BuildTree;

  Assert.IsTrue(TGlbspNodeBuilder.ComputeBspHeight(FRoot) >= 2);
end;

procedure TTestGlbspNodeBuilder.TestLimitiDiUnaListaDiSeg;
var
  LBlock: TGlbspSuperBlock;
  LBox: TGlbspBBox;
begin
  AddClosedRoom([0, 0, 0, 128, 128, 128, 128, 0]);
  CreateObjects;
  LBlock := FBuilder.CreateSegs(RoomBounds);
  try
    LBox := TGlbspPartitioner.FindLimits(LBlock);

    Assert.AreEqual(0, LBox.MinX);
    Assert.AreEqual(0, LBox.MinY);
    Assert.AreEqual(128, LBox.MaxX);
    Assert.AreEqual(128, LBox.MaxY);
  finally
    LBlock.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspNodeBuilder);

end.
