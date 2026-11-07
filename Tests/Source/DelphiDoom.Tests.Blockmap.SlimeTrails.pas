{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the blockmap library - TBlockmapSlimeTrailRemover      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Blockmap.SlimeTrails;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Blockmap.Types,
  DelphiDoom.Blockmap.Intf,
  DelphiDoom.Blockmap.Factory,
  DelphiDoom.Tests.Blockmap.Cases,
  DelphiDoom.Tests.Blockmap.Fingerprint;

type
  [TestFixture]
  [Category('blockmap')]
  TTestBlockmapSlimeTrailRemover = class
  strict private
    FRemover: ISlimeTrailRemover;
    class function Point(const AX, AY: Integer): TBlockmapPoint; static;
    // a seg from vertex 1 to vertex 2 of the line from vertex 0 to vertex 3 of the given vertexes
    class function Seg(const AVertex1, AVertex2, ALineVertex1, ALineVertex2: Integer;
      const AVertexes: TArray<TBlockmapPoint>): TBlockmapSeg; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeProiettareUnVerticeSullaLinea;
    [Test]
    procedure DovrebbeLasciareFermiGliEstremiDellaLinea;
    [Test]
    procedure DovrebbeSaltareLeLineeOrtogonali;
    [Test]
    procedure DovrebbeSaltareIMiniseg;
    [Test]
    procedure DovrebbeMuovereUnVerticeUnaSolaVolta;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiVerticeFuoriDallElenco;
    [Test]
    procedure DovrebbeDareGliStessiVerticiDelVecchioCodice;
  end;

implementation

{ TTestBlockmapSlimeTrailRemover }

class function TTestBlockmapSlimeTrailRemover.Point(const AX, AY: Integer): TBlockmapPoint;
begin
  Result.X := AX;
  Result.Y := AY;
end;

class function TTestBlockmapSlimeTrailRemover.Seg(const AVertex1, AVertex2, ALineVertex1,
  ALineVertex2: Integer; const AVertexes: TArray<TBlockmapPoint>): TBlockmapSeg;
begin
  Result.Vertex1 := AVertex1;
  Result.Vertex2 := AVertex2;
  Result.Miniseg := False;
  Result.LineVertex1 := ALineVertex1;
  Result.LineVertex2 := ALineVertex2;
  Result.LineDeltaX := AVertexes[ALineVertex2].X - AVertexes[ALineVertex1].X;
  Result.LineDeltaY := AVertexes[ALineVertex2].Y - AVertexes[ALineVertex1].Y;
end;

procedure TTestBlockmapSlimeTrailRemover.Setup;
begin
  FRemover := TBlockmapFactory.CreateSlimeTrailRemover;
end;

procedure TTestBlockmapSlimeTrailRemover.TearDown;
begin
  FRemover := nil;
end;

procedure TTestBlockmapSlimeTrailRemover.DovrebbeProiettareUnVerticeSullaLinea;
var
  LVertexes: TArray<TBlockmapPoint>;
begin
  // line y = x from (0, 0) to (64, 64); vertex 2 at (10, 20) goes to the middle: (15, 15)
  LVertexes := [Point(0, 0), Point(64 * BLOCKMAP_FRACUNIT, 64 * BLOCKMAP_FRACUNIT),
    Point(10 * BLOCKMAP_FRACUNIT, 20 * BLOCKMAP_FRACUNIT)];
  FRemover.Remove(LVertexes, [Seg(0, 2, 0, 1, LVertexes)]);
  Assert.AreEqual(15 * BLOCKMAP_FRACUNIT, LVertexes[2].X);
  Assert.AreEqual(15 * BLOCKMAP_FRACUNIT, LVertexes[2].Y);
end;

procedure TTestBlockmapSlimeTrailRemover.DovrebbeLasciareFermiGliEstremiDellaLinea;
var
  LVertexes: TArray<TBlockmapPoint>;
begin
  LVertexes := [Point(7, 3), Point(64 * BLOCKMAP_FRACUNIT + 5, 64 * BLOCKMAP_FRACUNIT + 1)];
  FRemover.Remove(LVertexes, [Seg(0, 1, 0, 1, LVertexes)]);
  Assert.AreEqual(7, LVertexes[0].X);
  Assert.AreEqual(3, LVertexes[0].Y);
  Assert.AreEqual(64 * BLOCKMAP_FRACUNIT + 5, LVertexes[1].X);
  Assert.AreEqual(64 * BLOCKMAP_FRACUNIT + 1, LVertexes[1].Y);
end;

procedure TTestBlockmapSlimeTrailRemover.DovrebbeSaltareLeLineeOrtogonali;
var
  LVertexes: TArray<TBlockmapPoint>;
begin
  // horizontal and vertical lines: the vertex stays
  LVertexes := [Point(0, 0), Point(64 * BLOCKMAP_FRACUNIT, 0), Point(10, 20),
    Point(0, 64 * BLOCKMAP_FRACUNIT)];
  FRemover.Remove(LVertexes, [Seg(0, 2, 0, 1, LVertexes), Seg(0, 2, 0, 3, LVertexes)]);
  Assert.AreEqual(10, LVertexes[2].X);
  Assert.AreEqual(20, LVertexes[2].Y);
end;

procedure TTestBlockmapSlimeTrailRemover.DovrebbeSaltareIMiniseg;
var
  LVertexes: TArray<TBlockmapPoint>;
  LSeg: TBlockmapSeg;
begin
  LVertexes := [Point(0, 0), Point(64 * BLOCKMAP_FRACUNIT, 64 * BLOCKMAP_FRACUNIT), Point(10, 20)];
  LSeg := Seg(0, 2, 0, 1, LVertexes);
  LSeg.Miniseg := True;
  FRemover.Remove(LVertexes, [LSeg]);
  Assert.AreEqual(10, LVertexes[2].X);
  Assert.AreEqual(20, LVertexes[2].Y);
end;

procedure TTestBlockmapSlimeTrailRemover.DovrebbeMuovereUnVerticeUnaSolaVolta;
var
  LVertexes: TArray<TBlockmapPoint>;
begin
  // vertex 2 is first projected onto y = x; a second line (y = 0 slanted the other way)
  // would move it again, but a vertex that was processed stays where it is
  LVertexes := [Point(0, 0), Point(64 * BLOCKMAP_FRACUNIT, 64 * BLOCKMAP_FRACUNIT),
    Point(10 * BLOCKMAP_FRACUNIT, 20 * BLOCKMAP_FRACUNIT),
    Point(0, 64 * BLOCKMAP_FRACUNIT), Point(64 * BLOCKMAP_FRACUNIT, 0)];
  FRemover.Remove(LVertexes, [Seg(0, 2, 0, 1, LVertexes), Seg(3, 2, 3, 4, LVertexes)]);
  Assert.AreEqual(15 * BLOCKMAP_FRACUNIT, LVertexes[2].X);
  Assert.AreEqual(15 * BLOCKMAP_FRACUNIT, LVertexes[2].Y);
end;

procedure TTestBlockmapSlimeTrailRemover.DovrebbeRifiutareUnIndiceDiVerticeFuoriDallElenco;
var
  LVertexes: TArray<TBlockmapPoint>;
  LSeg: TBlockmapSeg;
begin
  LVertexes := [Point(0, 0), Point(64 * BLOCKMAP_FRACUNIT, 64 * BLOCKMAP_FRACUNIT)];
  LSeg := Seg(0, 1, 0, 1, LVertexes);
  LSeg.Vertex2 := 7;
  Assert.WillRaise(
    procedure
    begin
      FRemover.Remove(LVertexes, [LSeg]);
    end, EBlockmapException);
end;

procedure TTestBlockmapSlimeTrailRemover.DovrebbeDareGliStessiVerticiDelVecchioCodice;
var
  LNames: TArray<string>;
  LName: string;
  LCase: TBlockmapCase;
  LFailures: string;
begin
  LNames := TBlockmapCase.FileNames;
  if Length(LNames) = 0 then
  begin
    Assert.Pass('no levels in Tests\Data\Blockmap');
    Exit;
  end;
  LFailures := '';
  for LName in LNames do
  begin
    LCase := TBlockmapCase.Load(LName);
    try
      FRemover.Remove(LCase.Vertexes, LCase.Segs);
      if TBlockmapFingerprint.OfVertexes(LCase.Vertexes) <> LCase.SlimeFingerprint then
        LFailures := LFailures + ' ' + LCase.Name;
    finally
      LCase.Free;
    end;
  end;
  Assert.AreEqual('', LFailures, 'levels with different vertexes');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBlockmapSlimeTrailRemover);

end.
