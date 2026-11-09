{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the mesh optimizer                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.MeshOptimizer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.Voxel.MeshTypes,
  DelphiDoom.Voxel.MeshRenderer.Intf,
  DelphiDoom.Voxel.MeshOptimizer,
  DelphiDoom.Voxel.MeshKvxMap,
  DelphiDoom.Voxel.MeshDdvoxMap,
  DelphiDoom.Tests.Voxel.OldMeshOptimizer;

type
  /// <summary>Records the calls as text lines</summary>
  TRecordingMeshRenderer = class(TInterfacedObject, IVoxelMeshRenderer)
  public
    Lines: TList<string>;
    constructor Create;
    destructor Destroy; override;
    procedure BeginQuads;
    procedure TexCoord(const ACoordS, ACoordT: Single);
    procedure Vertex(const AX, AY, AZ: Single);
    procedure EndQuads;
  end;

  [TestFixture]
  [Category('voxel')]
  TTestVoxelMeshOptimizer = class
  strict private
    FSeed: Cardinal;
    function Next(const ARange: Integer): Integer;
    procedure FillBoth(const ANew: TVoxelMeshOptimizer; const AOld: TOldVoxelMeshOptimizer; const ASize: Integer;
      const AColors: Integer; const ADensity: Integer);
    procedure CheckSame(const ANew: TVoxelMeshOptimizer; const AOld: TOldVoxelMeshOptimizer);
  public
    [Test]
    procedure DovrebbeDareGliStessiQuadDelVecchioConLOttimizzatoreVeloce;
    [Test]
    procedure DovrebbeDareGliStessiQuadDelVecchioConLOttimizzatoreCompleto;
    [TestCase('un passo', '1')]
    [TestCase('due passi', '2')]
    [TestCase('tre passi', '3')]
    procedure DovrebbeDareGliStessiQuadDelVecchioConPiuPassi(const APasses: Integer);
    [Test]
    procedure DovrebbeRiferireIConteggiDiUnCuboPieno;
    [Test]
    procedure DovrebbeMarcareNonValidoUnQuadNonParalleloAgliAssi;
    [Test]
    procedure DovrebbeRiferireIlRisultatoDelleDueStrade;
    [Test]
    procedure DovrebbeLimitareIPassiAlMassimo;
    [Test]
    procedure DovrebbeDisegnareUnQuadConLaMappaDelKvx;
    [Test]
    procedure DovrebbeDisegnareUnQuadConLaMappaDelDdvox;
    [Test]
    procedure DovrebbeSaltareIQuadNonValidiNelDisegno;
    [TestCase('kvx', '1')]
    [TestCase('ddvox', '2')]
    procedure DovrebbeDisegnareLeStesseChiamateDelVecchio(const AKind: Integer);
  end;

implementation

{ TRecordingMeshRenderer }

constructor TRecordingMeshRenderer.Create;
begin
  inherited Create;
  Lines := TList<string>.Create;
end;

destructor TRecordingMeshRenderer.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

procedure TRecordingMeshRenderer.BeginQuads;
begin
  Lines.Add('begin');
end;

procedure TRecordingMeshRenderer.TexCoord(const ACoordS, ACoordT: Single);
begin
  Lines.Add(Format('tex %.9g %.9g', [ACoordS, ACoordT]));
end;

procedure TRecordingMeshRenderer.Vertex(const AX, AY, AZ: Single);
begin
  Lines.Add(Format('v %.9g %.9g %.9g', [AX, AY, AZ]));
end;

procedure TRecordingMeshRenderer.EndQuads;
begin
  Lines.Add('end');
end;

{ TTestVoxelMeshOptimizer }

function TTestVoxelMeshOptimizer.Next(const ARange: Integer): Integer;
begin
  FSeed := FSeed * 1664525 + 1013904223;
  Result := Integer((FSeed shr 8) mod Cardinal(ARange));
end;

procedure TTestVoxelMeshOptimizer.FillBoth(const ANew: TVoxelMeshOptimizer; const AOld: TOldVoxelMeshOptimizer;
  const ASize: Integer; const AColors: Integer; const ADensity: Integer);
var
  LCells: array of Cardinal;
  LX, LY, LZ: Integer;
  LColor: Cardinal;

  function Solid(const AX, AY, AZ: Integer): Boolean;
  begin
    Result := (AX >= 0) and (AY >= 0) and (AZ >= 0) and (AX < ASize) and (AY < ASize) and (AZ < ASize) and
      (LCells[(AX * ASize + AY) * ASize + AZ] <> 0);
  end;

  procedure Add(const AColor: Cardinal; const X0, Y0, Z0, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Single);
  begin
    ANew.AddQuad(AColor, X0, Y0, Z0, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3);
    AOld.AddQuad(AColor, X0, Y0, Z0, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3);
  end;

var
  LX1, LY1, LZ1: Single;
begin
  SetLength(LCells, ASize * ASize * ASize);
  for LX := 0 to Length(LCells) - 1 do
    if Next(100) < ADensity then
      LCells[LX] := Cardinal((Next(AColors) + 1) * $040410)
    else
      LCells[LX] := 0;
  // the same six faces, in the same order, as gld_ListFromCube
  for LX := 0 to ASize - 1 do
    for LY := 0 to ASize - 1 do
      for LZ := 0 to ASize - 1 do
      begin
        LColor := LCells[(LX * ASize + LY) * ASize + LZ];
        if LColor = 0 then
          Continue;
        LX1 := LX + 1;
        LY1 := LY + 1;
        LZ1 := LZ + 1;
        if not Solid(LX, LY, LZ - 1) then
          Add(LColor, LX, LY, LZ, LX, LY1, LZ, LX1, LY1, LZ, LX1, LY, LZ);
        if not Solid(LX, LY - 1, LZ) then
          Add(LColor, LX, LY, LZ, LX, LY, LZ1, LX1, LY, LZ1, LX1, LY, LZ);
        if not Solid(LX - 1, LY, LZ) then
          Add(LColor, LX, LY, LZ, LX, LY, LZ1, LX, LY1, LZ1, LX, LY1, LZ);
        if not Solid(LX, LY, LZ + 1) then
          Add(LColor, LX, LY, LZ1, LX, LY1, LZ1, LX1, LY1, LZ1, LX1, LY, LZ1);
        if not Solid(LX, LY + 1, LZ) then
          Add(LColor, LX, LY1, LZ, LX, LY1, LZ1, LX1, LY1, LZ1, LX1, LY1, LZ);
        if not Solid(LX + 1, LY, LZ) then
          Add(LColor, LX1, LY, LZ, LX1, LY1, LZ, LX1, LY1, LZ1, LX1, LY, LZ1);
      end;
end;

procedure TTestVoxelMeshOptimizer.CheckSame(const ANew: TVoxelMeshOptimizer; const AOld: TOldVoxelMeshOptimizer);
var
  LIndex, LVertex: Integer;
  LNew: PVoxelMeshQuad;
  LOld: voxelquad_p;
begin
  Assert.AreEqual(AOld.numquads, ANew.numquads, 'numero di quad');
  for LIndex := 0 to ANew.numquads - 1 do
  begin
    LNew := @ANew.quads[LIndex];
    LOld := @AOld.quads[LIndex];
    Assert.AreEqual(LOld.valid, LNew.valid, 'valido ' + IntToStr(LIndex));
    Assert.AreEqual(Integer(LOld.orientation), Integer(LNew.orientation), 'orientamento ' + IntToStr(LIndex));
    if not LNew.valid then
      Continue;
    Assert.AreEqual(Cardinal(LOld.color), LNew.color, 'colore ' + IntToStr(LIndex));
    for LVertex := 0 to 3 do
    begin
      Assert.IsTrue(LOld.vertexes[LVertex].x = LNew.vertexes[LVertex].x, 'x ' + IntToStr(LIndex));
      Assert.IsTrue(LOld.vertexes[LVertex].y = LNew.vertexes[LVertex].y, 'y ' + IntToStr(LIndex));
      Assert.IsTrue(LOld.vertexes[LVertex].z = LNew.vertexes[LVertex].z, 'z ' + IntToStr(LIndex));
    end;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeDareGliStessiQuadDelVecchioConLOttimizzatoreVeloce;
var
  LRound: Integer;
  LNew: TVoxelMeshOptimizer;
  LOld: TOldVoxelMeshOptimizer;
begin
  FSeed := 12345;
  for LRound := 1 to 40 do
  begin
    LNew := TVoxelMeshOptimizer.Create;
    LOld := TOldVoxelMeshOptimizer.Create;
    try
      FillBoth(LNew, LOld, 4 + Next(12), 1 + Next(4), 30 + Next(70));
      vx_maxoptimizerpasscount := 0;
      LOld.Optimize;
      LNew.FastOptimize;
      CheckSame(LNew, LOld);
    finally
      LOld.Free;
      LNew.Free;
    end;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeDareGliStessiQuadDelVecchioConLOttimizzatoreCompleto;
begin
  DovrebbeDareGliStessiQuadDelVecchioConPiuPassi(3);
end;

procedure TTestVoxelMeshOptimizer.DovrebbeDareGliStessiQuadDelVecchioConPiuPassi(const APasses: Integer);
var
  LRound: Integer;
  LNew: TVoxelMeshOptimizer;
  LOld: TOldVoxelMeshOptimizer;
begin
  FSeed := 777 + Cardinal(APasses);
  for LRound := 1 to 25 do
  begin
    LNew := TVoxelMeshOptimizer.Create;
    LOld := TOldVoxelMeshOptimizer.Create;
    try
      FillBoth(LNew, LOld, 4 + Next(8), 1 + Next(3), 40 + Next(60));
      vx_maxoptimizerpasscount := APasses;
      LOld.Optimize;
      LNew.Optimize(APasses);
      CheckSame(LNew, LOld);
    finally
      LOld.Free;
      LNew.Free;
    end;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeRiferireIConteggiDiUnCuboPieno;
var
  LNew: TVoxelMeshOptimizer;
  LOld: TOldVoxelMeshOptimizer;
  LResult: TVoxelMeshOptimizeResult;
begin
  FSeed := 1;
  LNew := TVoxelMeshOptimizer.Create;
  LOld := TOldVoxelMeshOptimizer.Create;
  try
    FillBoth(LNew, LOld, 6, 1, 100);
    LResult := LNew.Optimize(3);
    Assert.AreEqual(Integer(vokFull), Integer(LResult.Kind));
    vx_maxoptimizerpasscount := 3;
    LOld.Optimize;
    Assert.AreEqual(LOld.numquads, LResult.NewQuadCount, 'come il vecchio');
    Assert.IsTrue(LResult.NewQuadCount <= LResult.OldQuadCount);
    Assert.AreEqual(LResult.NewQuadCount, LNew.numquads);
    Assert.IsTrue(LResult.Passes >= 1);
  finally
    LOld.Free;
    LNew.Free;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeMarcareNonValidoUnQuadNonParalleloAgliAssi;
var
  LNew: TVoxelMeshOptimizer;
begin
  LNew := TVoxelMeshOptimizer.Create;
  try
    LNew.AddQuad(1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1);
    Assert.AreEqual(1, LNew.numquads);
    Assert.IsFalse(LNew.quads[0].valid);
    Assert.AreEqual(Integer(' '), Integer(LNew.quads[0].orientation));
    LNew.AddQuad(1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0);
    Assert.IsTrue(LNew.quads[1].valid);
    Assert.AreEqual(Integer('z'), Integer(LNew.quads[1].orientation));
  finally
    LNew.Free;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeRiferireIlRisultatoDelleDueStrade;
var
  LNew: TVoxelMeshOptimizer;
  LResult: TVoxelMeshOptimizeResult;
begin
  LNew := TVoxelMeshOptimizer.Create;
  try
    LNew.AddQuad(1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0);
    LResult := LNew.Optimize(0);
    Assert.AreEqual(Integer(vokFast), Integer(LResult.Kind));
    Assert.AreEqual(1, LResult.OldQuadCount);
    Assert.AreEqual(1, LResult.NewQuadCount);
    Assert.AreEqual(0, LResult.Passes);
    LResult := LNew.Optimize(2);
    Assert.AreEqual(Integer(vokFull), Integer(LResult.Kind));
    Assert.AreEqual(1, LResult.Passes);
  finally
    LNew.Free;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeLimitareIPassiAlMassimo;
var
  LNew: TVoxelMeshOptimizer;
  LOld: TOldVoxelMeshOptimizer;
begin
  FSeed := 99;
  LNew := TVoxelMeshOptimizer.Create;
  LOld := TOldVoxelMeshOptimizer.Create;
  try
    FillBoth(LNew, LOld, 7, 2, 70);
    vx_maxoptimizerpasscount := 100; // clamped to 3 by the old one
    LOld.Optimize;
    LNew.Optimize(100);
    CheckSame(LNew, LOld);
  finally
    LOld.Free;
    LNew.Free;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeDisegnareUnQuadConLaMappaDelKvx;
var
  LNew: TVoxelMeshOptimizer;
  LRenderer: TRecordingMeshRenderer;
  LIntf: IVoxelMeshRenderer;
begin
  LNew := TVoxelMeshOptimizer.Create;
  LRenderer := TRecordingMeshRenderer.Create;
  LIntf := LRenderer;
  try
    LNew.AddQuad($FF0000, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0);
    LNew.Render(LIntf, TVoxelMeshKvxMap.Create);
    Assert.AreEqual(7, LRenderer.Lines.Count);
    Assert.AreEqual('begin', LRenderer.Lines[0]);
    // (x, z, -y) of the vertex 1 (0, 1, 0)
    Assert.AreEqual(Format('v %.9g %.9g %.9g', [0.0, 0.0, -1.0]), LRenderer.Lines[3]);
    Assert.AreEqual('end', LRenderer.Lines[6]);
  finally
    LNew.Free;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeDisegnareUnQuadConLaMappaDelDdvox;
var
  LNew: TVoxelMeshOptimizer;
  LRenderer: TRecordingMeshRenderer;
  LIntf: IVoxelMeshRenderer;
  LStep: Single;
begin
  LNew := TVoxelMeshOptimizer.Create;
  LRenderer := TRecordingMeshRenderer.Create;
  LIntf := LRenderer;
  try
    LStep := -0.5;
    LNew.AddQuad($FF0000, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1);
    LNew.Render(LIntf, TVoxelMeshDdvoxMap.Create(2, 3, 4, LStep));
    // (midx - x * step, y * step - midy, z * step - midz) of (1, 0, 0)
    Assert.AreEqual(Format('v %.9g %.9g %.9g', [2 - 1 * LStep, 0 * LStep - 3, 0 * LStep - 4]), LRenderer.Lines[2]);
  finally
    LNew.Free;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeSaltareIQuadNonValidiNelDisegno;
var
  LNew: TVoxelMeshOptimizer;
  LRenderer: TRecordingMeshRenderer;
  LIntf: IVoxelMeshRenderer;
begin
  LNew := TVoxelMeshOptimizer.Create;
  LRenderer := TRecordingMeshRenderer.Create;
  LIntf := LRenderer;
  try
    LNew.AddQuad(1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1);
    LNew.Render(LIntf, TVoxelMeshKvxMap.Create);
    Assert.AreEqual(2, LRenderer.Lines.Count); // begin, end
  finally
    LNew.Free;
  end;
end;

procedure TTestVoxelMeshOptimizer.DovrebbeDisegnareLeStesseChiamateDelVecchio(const AKind: Integer);
var
  LRound: Integer;
  LNew: TVoxelMeshOptimizer;
  LOld: TOldVoxelMeshOptimizer;
  LRenderer: TRecordingMeshRenderer;
  LIntf: IVoxelMeshRenderer;
  LOldLines: TStringList;
  LMap: IVoxelMeshVertexMap;
  LIndex: Integer;
begin
  FSeed := 4242 + Cardinal(AKind);
  for LRound := 1 to 12 do
  begin
    LNew := TVoxelMeshOptimizer.Create;
    LOld := TOldVoxelMeshOptimizer.Create;
    LRenderer := TRecordingMeshRenderer.Create;
    LIntf := LRenderer;
    LOldLines := TStringList.Create;
    try
      FillBoth(LNew, LOld, 4 + Next(6), 1 + Next(5), 40 + Next(60));
      vx_maxoptimizerpasscount := Next(4);
      LOld.Optimize;
      LNew.Optimize(vx_maxoptimizerpasscount);
      if AKind = 1 then
        LMap := TVoxelMeshKvxMap.Create
      else
        LMap := TVoxelMeshDdvoxMap.Create(2.5, -1.25, 0.75, -0.0625);
      LNew.Render(LIntf, LMap);
      LOld.RenderLines(LOldLines, AKind, 2.5, -1.25, 0.75, -0.0625);
      Assert.AreEqual(LOldLines.Count, LRenderer.Lines.Count, 'righe');
      for LIndex := 0 to LOldLines.Count - 1 do
        Assert.AreEqual(LOldLines[LIndex], LRenderer.Lines[LIndex], 'riga ' + IntToStr(LIndex));
    finally
      LOldLines.Free;
      LOld.Free;
      LNew.Free;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelMeshOptimizer);

end.
