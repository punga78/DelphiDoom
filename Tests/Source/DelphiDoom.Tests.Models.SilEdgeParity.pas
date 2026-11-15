{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - silhouette edges parity        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.SilEdgeParity;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Deform.Types,
  DelphiDoom.Tests.Models.GoldenLines;

type
  /// <summary>
  ///   R_IdentifySilEdges (with R_DefineEdge and SilEdgeSort) against the real functions of
  ///   tr_trisurf.cpp compiled with bcc32c (Tests\Data\Models\deform, harness\build.ps1.txt). The
  ///   golden has the edges in a canonical order (planes, then vertexes): the order that qsort gives
  ///   to edges with the same two planes is not defined, so the test sorts the same way and checks
  ///   that the planes are in order.
  /// </summary>
  [TestFixture]
  [Category('Deform')]
  TTestSilEdgeParity = class
  strict private
    FInputs: TGoldenLines;
    FGolden: TGoldenLines;
    function ReadVerts(const ACase: string): TArray<TStaticDrawVert>;
    procedure CheckEdges(const ATag: string; const AEdges: TArray<TStaticSilEdge>; const APerfectHull: Integer;
      const AWarning: string);
    procedure CheckCase(const ACase: string);
    procedure CheckSoup(const AName: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRiprodurreLaStrisciaConLaTexturaSpecchiata;
    [Test]
    procedure DovrebbeRiprodurreIlCubo;
    [Test]
    procedure DovrebbeRiprodurreLaGriglia;
    [Test]
    procedure DovrebbeRiprodurreIlCuboDiDefault;
    [Test]
    procedure DovrebbeRiprodurreLeSuperficiAperteEChiuse;
    [Test]
    procedure DovrebbeRiprodurreSpigoliTripliEDoppi;
    [Test]
    procedure DovrebbeRiprodurreTriangoliDegeneriEVuoto;
    [Test]
    procedure DovrebbeRiprodurreIGruppiDiHashInCollisione;
    [Test]
    procedure DovrebbeRiprodurreLeNubiCasuali;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.DeformBuilder,
  DelphiDoom.Models.Static.SurfaceFinisher,
  DelphiDoom.Models.Static.SilEdgeBuilder,
  DelphiDoom.Models.Static.DefaultModel,
  DelphiDoom.Tests.Models.AnimSupport;

{ TTestSilEdgeParity }

procedure TTestSilEdgeParity.Setup;
begin
  FInputs := TGoldenLines.Create('deform\deform.golden.txt');
  FGolden := TGoldenLines.Create('deform\deform_sil.golden.txt');
end;

procedure TTestSilEdgeParity.TearDown;
begin
  FGolden.Free;
  FInputs.Free;
end;

function TTestSilEdgeParity.ReadVerts(const ACase: string): TArray<TStaticDrawVert>;
var
  LValues: TArray<Single>;
  LIndex: Integer;
begin
  LValues := FInputs.Floats(ACase + ' in verts');
  SetLength(Result, Length(LValues) div 5);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Clear;
    Result[LIndex].Xyz := TIdVec3.Create(LValues[LIndex * 5], LValues[LIndex * 5 + 1], LValues[LIndex * 5 + 2]);
    Result[LIndex].St := TIdVec2.Create(LValues[LIndex * 5 + 3], LValues[LIndex * 5 + 4]);
  end;
end;

procedure TTestSilEdgeParity.CheckEdges(const ATag: string; const AEdges: TArray<TStaticSilEdge>;
  const APerfectHull: Integer; const AWarning: string);
var
  LGolden: TArray<Integer>;
  LSorted: TArray<TStaticSilEdge>;
  LIndex, LInner: Integer;
  LTemp: TStaticSilEdge;
  LKey: string;
  LBefore: Boolean;
begin
  LKey := 'SIL ' + ATag;
  LGolden := FGolden.Ints(LKey);
  Assert.AreEqual<Integer>(LGolden[0], Length(AEdges), LKey + ': number of edges');
  if LGolden[1] >= 0 then
    Assert.AreEqual<Integer>(LGolden[1], APerfectHull, LKey + ': perfect hull');
  // the planes must be in order, as qsort leaves them
  for LIndex := 1 to High(AEdges) do
    Assert.IsTrue((AEdges[LIndex].P1 > AEdges[LIndex - 1].P1) or
      ((AEdges[LIndex].P1 = AEdges[LIndex - 1].P1) and (AEdges[LIndex].P2 >= AEdges[LIndex - 1].P2)),
      LKey + ': edges not sorted by planes at ' + IntToStr(LIndex));
  Assert.AreEqual<Integer>(1, LGolden[2], LKey + ': the original is sorted');
  // the canonical order of the golden
  LSorted := Copy(AEdges);
  for LIndex := 1 to High(LSorted) do
    for LInner := LIndex downto 1 do
    begin
      LBefore := (LSorted[LInner].P1 < LSorted[LInner - 1].P1) or
        ((LSorted[LInner].P1 = LSorted[LInner - 1].P1) and ((LSorted[LInner].P2 < LSorted[LInner - 1].P2) or
        ((LSorted[LInner].P2 = LSorted[LInner - 1].P2) and ((LSorted[LInner].V1 < LSorted[LInner - 1].V1) or
        ((LSorted[LInner].V1 = LSorted[LInner - 1].V1) and (LSorted[LInner].V2 < LSorted[LInner - 1].V2))))));
      if not LBefore then
        Break;
      LTemp := LSorted[LInner];
      LSorted[LInner] := LSorted[LInner - 1];
      LSorted[LInner - 1] := LTemp;
    end;
  for LIndex := 0 to High(LSorted) do
  begin
    Assert.AreEqual<Integer>(LGolden[3 + LIndex * 4], LSorted[LIndex].P1, Format('%s: p1 of edge %d', [LKey, LIndex]));
    Assert.AreEqual<Integer>(LGolden[4 + LIndex * 4], LSorted[LIndex].P2, Format('%s: p2 of edge %d', [LKey, LIndex]));
    Assert.AreEqual<Integer>(LGolden[5 + LIndex * 4], LSorted[LIndex].V1, Format('%s: v1 of edge %d', [LKey, LIndex]));
    Assert.AreEqual<Integer>(LGolden[6 + LIndex * 4], LSorted[LIndex].V2, Format('%s: v2 of edge %d', [LKey, LIndex]));
  end;
  // the warning of DWarning
  if FGolden.Has(LKey + ' warning') then
    Assert.AreEqual(string.Join(' ', FGolden.Tokens(LKey + ' warning')), AWarning, LKey + ': warning')
  else
    Assert.AreEqual('', AWarning, LKey + ': no warning expected');
end;

procedure TTestSilEdgeParity.CheckCase(const ACase: string);
var
  LSource: TArray<TStaticDrawVert>;
  LIndexes: TArray<Integer>;
  LInfo: TStaticDeformInfo;
  LTriangles, LCleaned: TStaticTriangles;
  LUnsmoothed, LMode: Integer;
  LLog: TRecordingLog;
  LLogIntf: IIdLibLog;
  LCreate: Boolean;
begin
  LSource := ReadVerts(ACase);
  LIndexes := FInputs.Ints(ACase + ' in idx');
  LLog := TRecordingLog.Create;
  LLogIntf := LLog;
  for LUnsmoothed := 0 to 1 do
  begin
    LInfo := TStaticDeformBuilder.Build(LSource, LIndexes, LUnsmoothed <> 0, LLogIntf);
    CheckEdges(Format('%s deform %d', [ACase, LUnsmoothed]), LInfo.SilEdges, -1, Trim(LLog.Text));
    LLog.Clear;
  end;
  LTriangles.Verts := LSource;
  LTriangles.Indexes := LIndexes;
  for LMode := 0 to 3 do
  begin
    LCreate := (LMode and 1) = 0;
    LUnsmoothed := Ord((LMode and 2) <> 0);
    LCleaned := TStaticSurfaceFinisher.Cleanup(LTriangles, LCreate, LUnsmoothed <> 0, LLogIntf);
    CheckEdges(Format('%s cleanup %d %d', [ACase, Ord(LCreate), LUnsmoothed]), LCleaned.SilEdges,
      Ord(LCleaned.PerfectHull), Trim(LLog.Text));
    LLog.Clear;
  end;
end;

procedure TTestSilEdgeParity.CheckSoup(const AName: string);
var
  LIndexes: TArray<Integer>;
  LEdges: TArray<TStaticSilEdge>;
  LPerfect: Boolean;
  LLog: TRecordingLog;
  LLogIntf: IIdLibLog;
begin
  LIndexes := FGolden.Ints('SIL in ' + AName);
  LLog := TRecordingLog.Create;
  LLogIntf := LLog;
  LEdges := TStaticSilEdgeBuilder.Identify(LIndexes, LPerfect, LLogIntf);
  CheckEdges(AName, LEdges, Ord(LPerfect), Trim(LLog.Text));
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreLaStrisciaConLaTexturaSpecchiata;
begin
  CheckCase('mirror');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreIlCubo;
begin
  CheckCase('cube');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreLaGriglia;
begin
  CheckCase('grid');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreIlCuboDiDefault;
var
  LTriangles: TStaticTriangles;
begin
  LTriangles := TStaticDefaultModel.Build('x').Surfaces[0].Triangles;
  CheckEdges('default cleanup', LTriangles.SilEdges, Ord(LTriangles.PerfectHull), '');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreLeSuperficiAperteEChiuse;
begin
  CheckSoup('single');
  CheckSoup('pair');
  CheckSoup('tetra');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreSpigoliTripliEDoppi;
begin
  CheckSoup('tripled');
  CheckSoup('duplicated');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreTriangoliDegeneriEVuoto;
begin
  CheckSoup('degenerate');
  CheckSoup('empty');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreIGruppiDiHashInCollisione;
begin
  CheckSoup('collide');
end;

procedure TTestSilEdgeParity.DovrebbeRiprodurreLeNubiCasuali;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    CheckSoup('soup' + IntToStr(LIndex));
end;

end.
