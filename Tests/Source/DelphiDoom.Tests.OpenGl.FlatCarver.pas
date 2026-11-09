{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL level geometry - the carver of the flats    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.FlatCarver;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf;

type
  /// <summary>A BSP made of arrays; the same data is given to the old code and to the carver</summary>
  TGlFakeWorld = class(TInterfacedObject, IGlFlatWorld)
  public
    Nodes: TArray<TGlCarverNode>;
    Subsectors: TArray<TGlCarverSubsector>;
    Segs: TArray<TGlCarverSeg>;
    function GetSubsectorCount: Integer;
    function GetNode(const AIndex: Integer): TGlCarverNode;
    function GetSubsector(const AIndex: Integer): TGlCarverSubsector;
    function GetSeg(const AIndex: Integer): TGlCarverSeg;
  end;

  /// <summary>A sink that writes a line for every polygon, as the old test code does</summary>
  TGlFakeSink = class(TInterfacedObject, IGlFlatLoopSink)
  public
    Loops: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure AddLoop(const ASectorId: Integer; const APoints: PGlFixedPoint; const ACount: Integer);
  end;

  [TestFixture]
  [Category('opengl')]
  TTestOpenGlFlatCarver = class(TObject)
  strict private
    FWorld: TGlFakeWorld;
    FWorldIntf: IGlFlatWorld;
    FVertices: array[0..4095] of record X, Y: Integer; Unused: array[0..1] of Integer; end;
    FVertexCount: Integer;
    FClosed: array[0..7] of Boolean;
    procedure NewWorld;
    function AddSubsector(const ASector, ALines: Integer): Integer;
    function AddNode(const ADepth: Integer): Integer;
    procedure CopyToOld;
    procedure RandomClosed;
    function OldCarve(const ARoot: Integer): string;
    function NewCarve(const ARoot: Integer): string;
    function OldSubsectorLoops: string;
    function NewSubsectorLoops: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRitagliareUnPoligonoComeIlVecchioCodice;
    [Test]
    procedure DovrebbeDareUnSoloSubsectorSenzaNodi;
    [Test]
    procedure DovrebbeSaltareISettoriChiusi;
    [Test]
    procedure DovrebbeUsareIlSubsectorZeroConLaRadiceMenoUno;
    [Test]
    procedure DovrebbeDareLeStessePuntePerLeNodiGl;
    [Test]
    procedure DovrebbeDareEccezioneSeIlPoligonoHaTroppiLati;
    [Test]
    procedure DovrebbeDareEccezioneSeManca;
  end;

implementation

uses
  DelphiDoom.GlLevel.Factory,
  DelphiDoom.GlLevel.FlatEdgeClipper,
  DelphiDoom.Tests.OpenGl.OldFlatCarver;

{ TGlFakeWorld }

function TGlFakeWorld.GetSubsectorCount: Integer;
begin
  Result := Length(Subsectors);
end;

function TGlFakeWorld.GetNode(const AIndex: Integer): TGlCarverNode;
begin
  Result := Nodes[AIndex];
end;

function TGlFakeWorld.GetSubsector(const AIndex: Integer): TGlCarverSubsector;
begin
  Result := Subsectors[AIndex];
end;

function TGlFakeWorld.GetSeg(const AIndex: Integer): TGlCarverSeg;
begin
  Result := Segs[AIndex];
end;

{ TGlFakeSink }

constructor TGlFakeSink.Create;
begin
  inherited Create;
  Loops := TStringList.Create;
end;

destructor TGlFakeSink.Destroy;
begin
  Loops.Free;
  inherited Destroy;
end;

procedure TGlFakeSink.AddLoop(const ASectorId: Integer; const APoints: PGlFixedPoint; const ACount: Integer);
var
  LIndex: Integer;
  LText: string;
  LPoint: PGlFixedPoint;
begin
  LText := IntToStr(ASectorId) + ':';
  LPoint := APoints;
  for LIndex := 0 to ACount - 1 do
  begin
    LText := LText + IntToStr(LPoint.X) + ',' + IntToStr(LPoint.Y) + ';';
    Inc(LPoint);
  end;
  Loops.Add(LText);
end;

{ TTestOpenGlFlatCarver }

procedure TTestOpenGlFlatCarver.Setup;
begin
  RandSeed := 177;
  old_loops := TStringList.Create;
  NewWorld;
end;

procedure TTestOpenGlFlatCarver.TearDown;
begin
  FWorldIntf := nil;
  FreeAndNil(old_loops);
end;

procedure TTestOpenGlFlatCarver.NewWorld;
begin
  FWorld := TGlFakeWorld.Create;
  FWorldIntf := FWorld;
  FVertexCount := 0;
end;

// A subsector: a random convex-ish polygon of ALines vertexes around a center, its segs in order
function TTestOpenGlFlatCarver.AddSubsector(const ASector, ALines: Integer): Integer;
var
  LCenterX, LCenterY, LRadius, LIndex, LFirst: Integer;
  LAngle: Double;
  LSubsector: TGlCarverSubsector;
  LSeg: TGlCarverSeg;
  LPoints: array of TGlFixedPoint;
begin
  LCenterX := (Random(6000) - 3000) * 65536;
  LCenterY := (Random(6000) - 3000) * 65536;
  LRadius := (50 + Random(1500)) * 65536;
  SetLength(LPoints, ALines);
  for LIndex := 0 to ALines - 1 do
  begin
    // the interior is on the right of a seg (the left side of a divline is discarded): clockwise
    LAngle := -2 * Pi * LIndex / ALines;
    LPoints[LIndex].X := LCenterX + Round(Cos(LAngle) * LRadius) + Random(1000);
    LPoints[LIndex].Y := LCenterY + Round(Sin(LAngle) * LRadius) + Random(1000);
  end;
  LFirst := Length(FWorld.Segs);
  SetLength(FWorld.Segs, LFirst + ALines);
  for LIndex := 0 to ALines - 1 do
  begin
    LSeg.Start := LPoints[LIndex];
    LSeg.Finish := LPoints[(LIndex + 1) mod ALines];
    FWorld.Segs[LFirst + LIndex] := LSeg;
  end;
  LSubsector.SectorId := ASector;
  LSubsector.FirstLine := LFirst;
  LSubsector.LineCount := ALines;
  SetLength(FWorld.Subsectors, Length(FWorld.Subsectors) + 1);
  FWorld.Subsectors[High(FWorld.Subsectors)] := LSubsector;
  Result := High(FWorld.Subsectors);
end;

// A random tree: the answer is the reference of the child (a subsector has the flag)
function TTestOpenGlFlatCarver.AddNode(const ADepth: Integer): Integer;
var
  LNode: TGlCarverNode;
  LIndex, LSide: Integer;
begin
  if (ADepth <= 0) or (Random(5) = 0) then
    Exit(AddSubsector(Random(5), 3 + Random(6)) or GLLEVEL_NODE_SUBSECTOR);
  SetLength(FWorld.Nodes, Length(FWorld.Nodes) + 1);
  LIndex := High(FWorld.Nodes);
  LNode.Line.X := (Random(6000) - 3000) * 65536;
  LNode.Line.Y := (Random(6000) - 3000) * 65536;
  LNode.Line.DX := (Random(4000) - 2000) * 65536 + Random(65536) + 1;
  LNode.Line.DY := (Random(4000) - 2000) * 65536 + Random(65536) + 1;
  LNode.Children[0] := 0;
  LNode.Children[1] := 0;
  FWorld.Nodes[LIndex] := LNode;
  for LSide := 0 to 1 do
  begin
    LNode.Children[LSide] := AddNode(ADepth - 1);
    FWorld.Nodes[LIndex].Children[LSide] := LNode.Children[LSide];
  end;
  Result := LIndex;
end;

procedure TTestOpenGlFlatCarver.CopyToOld;
var
  LIndex: Integer;
begin
  SetLength(old_nodes, Length(FWorld.Nodes));
  for LIndex := 0 to High(FWorld.Nodes) do
  begin
    old_nodes[LIndex].x := FWorld.Nodes[LIndex].Line.X;
    old_nodes[LIndex].y := FWorld.Nodes[LIndex].Line.Y;
    old_nodes[LIndex].dx := FWorld.Nodes[LIndex].Line.DX;
    old_nodes[LIndex].dy := FWorld.Nodes[LIndex].Line.DY;
    old_nodes[LIndex].children[0] := LongWord(FWorld.Nodes[LIndex].Children[0]);
    old_nodes[LIndex].children[1] := LongWord(FWorld.Nodes[LIndex].Children[1]);
  end;
  SetLength(old_subsectors, Length(FWorld.Subsectors));
  for LIndex := 0 to High(FWorld.Subsectors) do
  begin
    old_subsectors[LIndex].sectorid := FWorld.Subsectors[LIndex].SectorId;
    old_subsectors[LIndex].numlines := FWorld.Subsectors[LIndex].LineCount;
    old_subsectors[LIndex].firstline := FWorld.Subsectors[LIndex].FirstLine;
  end;
  // the segs point to vertexes: one record for each end
  SetLength(old_segs, Length(FWorld.Segs));
  for LIndex := 0 to High(FWorld.Segs) do
  begin
    FVertices[2 * LIndex].X := FWorld.Segs[LIndex].Start.X;
    FVertices[2 * LIndex].Y := FWorld.Segs[LIndex].Start.Y;
    FVertices[2 * LIndex + 1].X := FWorld.Segs[LIndex].Finish.X;
    FVertices[2 * LIndex + 1].Y := FWorld.Segs[LIndex].Finish.Y;
    old_segs[LIndex].v1 := Pvertex_t(@FVertices[2 * LIndex]);
    old_segs[LIndex].v2 := Pvertex_t(@FVertices[2 * LIndex + 1]);
  end;
end;

procedure TTestOpenGlFlatCarver.RandomClosed;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FClosed) do
    FClosed[LIndex] := Random(4) = 0;
end;

function TTestOpenGlFlatCarver.OldCarve(const ARoot: Integer): string;
begin
  old_loops.Clear;
  try
    gld_CarveFlats(ARoot, 0, nil, PBooleanArray(@FClosed[0]));
  except
    on E: Exception do
      Exit('EXC');
  end;
  Result := old_loops.Text;
end;

function TTestOpenGlFlatCarver.NewCarve(const ARoot: Integer): string;
var
  LSink: TGlFakeSink;
  LSinkIntf: IGlFlatLoopSink;
begin
  LSink := TGlFakeSink.Create;
  LSinkIntf := LSink;
  try
    TGlLevelFactory.CreateFlatCarver(FWorldIntf, LSinkIntf).CarveFlats(ARoot,
      function(const ASectorId: Integer): Boolean
      begin
        Result := FClosed[ASectorId];
      end);
  except
    on E: Exception do
      Exit('EXC');
  end;
  Result := LSink.Loops.Text;
end;

function TTestOpenGlFlatCarver.OldSubsectorLoops: string;
begin
  old_loops.Clear;
  gld_GetSubSectorVertices(PBooleanArray(@FClosed[0]));
  Result := old_loops.Text;
end;

function TTestOpenGlFlatCarver.NewSubsectorLoops: string;
var
  LSink: TGlFakeSink;
  LSinkIntf: IGlFlatLoopSink;
begin
  LSink := TGlFakeSink.Create;
  LSinkIntf := LSink;
  TGlLevelFactory.CreateFlatCarver(FWorldIntf, LSinkIntf).AddSubsectorLoops(
    function(const ASectorId: Integer): Boolean
    begin
      Result := FClosed[ASectorId];
    end);
  Result := LSink.Loops.Text;
end;

procedure TTestOpenGlFlatCarver.DovrebbeRitagliareUnPoligonoComeIlVecchioCodice;
var
  LRound, LRoot, LLoops: Integer;
  LOld, LNew: string;
begin
  LLoops := 0;
  for LRound := 1 to 300 do
  begin
    NewWorld;
    LRoot := AddNode(1 + Random(5));
    RandomClosed;
    CopyToOld;
    LOld := OldCarve(LRoot);
    LNew := NewCarve(LRoot);
    Assert.AreEqual(LOld, LNew, 'albero ' + IntToStr(LRound));
    if LNew <> 'EXC' then
      Inc(LLoops, Length(LNew));
  end;
  // the trees must have given some polygons (and not only exceptions)
  Assert.IsTrue(LLoops > 1000, 'pochi poligoni: ' + IntToStr(LLoops));
end;

procedure TTestOpenGlFlatCarver.DovrebbeDareUnSoloSubsectorSenzaNodi;
var
  LRoot: Integer;
begin
  AddSubsector(2, 5);
  LRoot := 0 or GLLEVEL_NODE_SUBSECTOR;
  FillChar(FClosed, SizeOf(FClosed), 0);
  CopyToOld;
  Assert.AreEqual(OldCarve(LRoot), NewCarve(LRoot));
  Assert.AreNotEqual('', NewCarve(LRoot));
end;

procedure TTestOpenGlFlatCarver.DovrebbeSaltareISettoriChiusi;
var
  LRoot: Integer;
begin
  AddSubsector(3, 5);
  LRoot := 0 or GLLEVEL_NODE_SUBSECTOR;
  FillChar(FClosed, SizeOf(FClosed), 0);
  FClosed[3] := True;
  CopyToOld;
  Assert.AreEqual('', OldCarve(LRoot));
  Assert.AreEqual('', NewCarve(LRoot));
end;

procedure TTestOpenGlFlatCarver.DovrebbeUsareIlSubsectorZeroConLaRadiceMenoUno;
begin
  AddSubsector(1, 4);
  FillChar(FClosed, SizeOf(FClosed), 0);
  CopyToOld;
  Assert.AreEqual(OldCarve(-1), NewCarve(-1));
  Assert.AreNotEqual('', NewCarve(-1));
end;

procedure TTestOpenGlFlatCarver.DovrebbeDareLeStessePuntePerLeNodiGl;
var
  LRound, LIndex: Integer;
begin
  for LRound := 1 to 200 do
  begin
    NewWorld;
    for LIndex := 1 to 1 + Random(12) do
      AddSubsector(Random(5), Random(9));
    RandomClosed;
    CopyToOld;
    Assert.AreEqual(OldSubsectorLoops, NewSubsectorLoops, 'giro ' + IntToStr(LRound));
  end;
end;

procedure TTestOpenGlFlatCarver.DovrebbeDareEccezioneSeIlPoligonoHaTroppiLati;
var
  LRoot: Integer;
begin
  AddSubsector(0, 90);
  LRoot := 0 or GLLEVEL_NODE_SUBSECTOR;
  FillChar(FClosed, SizeOf(FClosed), 0);
  CopyToOld;
  Assert.AreEqual('EXC', OldCarve(LRoot));
  Assert.AreEqual('EXC', NewCarve(LRoot));
  Assert.WillRaise(
    procedure
    var
      LSink: IGlFlatLoopSink;
    begin
      LSink := TGlFakeSink.Create;
      TGlLevelFactory.CreateFlatCarver(FWorldIntf, LSink).CarveFlats(LRoot,
        function(const ASectorId: Integer): Boolean
        begin
          Result := False;
        end);
    end, EGlLevelException);
end;

procedure TTestOpenGlFlatCarver.DovrebbeDareEccezioneSeManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlLevelFactory.CreateFlatCarver(nil, TGlFakeSink.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGlLevelFactory.CreateFlatCarver(FWorldIntf, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGlLevelFactory.CreateFlatCarver(FWorldIntf, TGlFakeSink.Create).CarveFlats(-1, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOpenGlFlatCarver);

end.
