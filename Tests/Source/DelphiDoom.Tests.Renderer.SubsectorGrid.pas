{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the point in subsector grid     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.SubsectorGrid;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   A level of vertical stripes: the subsector of a point is the stripe that has its x,
  ///   and a point that is less than AMargin from a stripe boundary is "on a seg" (-1)
  /// </summary>
  TFakeStripeLocator = class(TInterfacedObject, IRendererSubsectorLocator)
  public
    StripeWidth: Integer;
    Margin: Integer;
    Calls: Integer;
    function Locate(AX, AY: Integer): Integer;
  end;

  [TestFixture]
  [Category('renderer')]
  TTestRendererSubsectorGrid = class(TObject)
  private
    FBuilder: IRendererSubsectorGridBuilder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMisurareIlLivelloDaiVertici;
    [Test]
    procedure DovrebbeDareLaMisuraDelBordoConIlSegno;
    [Test]
    procedure DovrebbeTrovareIlSottosettoreDelleCelleInterne;
    [Test]
    procedure DovrebbeLasciareVuoteLeCelleACavallo;
    [Test]
    procedure DovrebbeChiedereIQuattroAngoliDiOgniCella;
    [Test]
    procedure DovrebbeFallireSenzaVertici;
    [Test]
    procedure DovrebbeFallireSeLeCoordinateDifferiscono;
    [Test]
    procedure DovrebbeRifiutareUnTrovatoreNil;
    /// <summary>
    ///   Parity: R_PrecalcPointInSubSector of the old r_subsectors.pas, copied here as it was,
    ///   and the library give the same grid on random levels
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_PrecalcPointInSubSector;
  end;

implementation

// as in the old code: the cell number times the cell size is a 32 bit integer that wraps around
{$Q-}
{$R-}

uses
  DelphiDoom.Renderer.Factory;

const
  FRACUNIT = 65536;
  CELL = 32 * FRACUNIT;

{ TFakeStripeLocator }

function TFakeStripeLocator.Locate(AX, AY: Integer): Integer;
var
  LOffset: Integer;
begin
  Inc(Calls);
  Result := AX div StripeWidth;
  if AX < 0 then
    Result := -(Abs(AX) div StripeWidth) - 1;
  // the stripes are numbered from 0 at the corner of the test levels, which is the lowest x
  LOffset := AX mod StripeWidth;
  if (Margin > 0) and ((LOffset < Margin) or (LOffset > StripeWidth - Margin)) then
    Result := -1;
end;

{ TTestRendererSubsectorGrid }

procedure TTestRendererSubsectorGrid.Setup;
begin
  FBuilder := TRendererFactory.CreateSubsectorGridBuilder;
end;

procedure TTestRendererSubsectorGrid.TearDown;
begin
  FBuilder := nil;
end;

procedure TTestRendererSubsectorGrid.DovrebbeMisurareIlLivelloDaiVertici;
var
  LGrid: TRendererSubsectorGrid;
  LLocator: IRendererSubsectorLocator;
begin
  LLocator := TFakeStripeLocator.Create;
  TFakeStripeLocator(LLocator as TObject).StripeWidth := 100 * FRACUNIT;
  LGrid := FBuilder.Build([-64 * FRACUNIT, 200 * FRACUNIT, 0], [0, 96 * FRACUNIT, -10 * FRACUNIT],
    LLocator);
  Assert.AreEqual<Int64>(-64 * FRACUNIT, LGrid.MinX);
  Assert.AreEqual<Int64>(-10 * FRACUNIT, LGrid.MinY);
  // (264 / 32) + 1 cells wide and (106 / 32) + 1 cells high, the division truncated
  Assert.AreEqual<Int64>(9, LGrid.Width);
  Assert.AreEqual<Int64>(4, LGrid.Height);
  Assert.AreEqual<Integer>(36, Length(LGrid.Cells));
end;

procedure TTestRendererSubsectorGrid.DovrebbeDareLaMisuraDelBordoConIlSegno;
var
  LGrid: TRendererSubsectorGrid;
  LLocator: IRendererSubsectorLocator;
begin
  LLocator := TFakeStripeLocator.Create;
  TFakeStripeLocator(LLocator as TObject).StripeWidth := 1000 * FRACUNIT;
  LGrid := FBuilder.Build([-300 * FRACUNIT, 100 * FRACUNIT], [50 * FRACUNIT, -700 * FRACUNIT],
    LLocator);
  Assert.AreEqual(700, LGrid.MaxBound);
  LGrid := FBuilder.Build([-300 * FRACUNIT, 100 * FRACUNIT], [50 * FRACUNIT, 40 * FRACUNIT],
    LLocator);
  Assert.AreEqual(300, LGrid.MaxBound);
end;

procedure TTestRendererSubsectorGrid.DovrebbeTrovareIlSottosettoreDelleCelleInterne;
var
  LGrid: TRendererSubsectorGrid;
  LLocator: TFakeStripeLocator;
  LIntf: IRendererSubsectorLocator;
  LColumn: Integer;
begin
  LLocator := TFakeStripeLocator.Create;
  LIntf := LLocator;
  // stripes of 64 map units, two cells each, from x = 0
  LLocator.StripeWidth := 64 * FRACUNIT;
  LGrid := FBuilder.Build([0, 256 * FRACUNIT - 1], [0, 32 * FRACUNIT - 1], LIntf);
  Assert.AreEqual<Int64>(8, LGrid.Width);
  Assert.AreEqual<Int64>(1, LGrid.Height);
  for LColumn := 0 to 7 do
    Assert.AreEqual(LColumn div 2, LGrid.Cells[LColumn]);
  Assert.AreEqual(8, LGrid.HitCount);
end;

procedure TTestRendererSubsectorGrid.DovrebbeLasciareVuoteLeCelleACavallo;
var
  LGrid: TRendererSubsectorGrid;
  LLocator: TFakeStripeLocator;
  LIntf: IRendererSubsectorLocator;
begin
  LLocator := TFakeStripeLocator.Create;
  LIntf := LLocator;
  // stripes of 48 map units: a cell of 32 straddles a boundary every other time
  LLocator.StripeWidth := 48 * FRACUNIT;
  LGrid := FBuilder.Build([0, 192 * FRACUNIT - 1], [0, 31 * FRACUNIT], LIntf);
  Assert.AreEqual<Int64>(6, LGrid.Width);
  Assert.AreEqual(0, LGrid.Cells[0]);
  Assert.AreEqual(-1, LGrid.Cells[1]);
  // a point refused by the locator keeps the cell empty
  LLocator.Margin := 2 * FRACUNIT;
  LGrid := FBuilder.Build([0, 192 * FRACUNIT - 1], [0, 31 * FRACUNIT], LIntf);
  Assert.AreEqual(-1, LGrid.Cells[0], 'the corner at x = 0 is on a boundary');
end;

procedure TTestRendererSubsectorGrid.DovrebbeChiedereIQuattroAngoliDiOgniCella;
var
  LLocator: TFakeStripeLocator;
  LIntf: IRendererSubsectorLocator;
begin
  LLocator := TFakeStripeLocator.Create;
  LIntf := LLocator;
  LLocator.StripeWidth := 1000 * FRACUNIT;
  FBuilder.Build([0, 96 * FRACUNIT - 1], [0, 64 * FRACUNIT - 1], LIntf);
  // 3 x 2 cells, all inside one stripe: four corners each
  Assert.AreEqual(24, LLocator.Calls);
end;

procedure TTestRendererSubsectorGrid.DovrebbeFallireSenzaVertici;
var
  LLocator: IRendererSubsectorLocator;
begin
  LLocator := TFakeStripeLocator.Create;
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(nil, nil, LLocator);
    end, ERendererException);
end;

procedure TTestRendererSubsectorGrid.DovrebbeFallireSeLeCoordinateDifferiscono;
var
  LLocator: IRendererSubsectorLocator;
begin
  LLocator := TFakeStripeLocator.Create;
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build([0, 1], [0], LLocator);
    end, ERendererException);
end;

procedure TTestRendererSubsectorGrid.DovrebbeRifiutareUnTrovatoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build([0], [0], nil);
    end, EArgumentNilException);
end;

procedure TTestRendererSubsectorGrid.DovrebbeFareComeIlVecchioR_PrecalcPointInSubSector;
var
  LScenario: Integer;
  LVertexCount: Integer;
  LVertexX: TArray<Integer>;
  LVertexY: TArray<Integer>;
  LIndex: Integer;
  LLocator: TFakeStripeLocator;
  LIntf: IRendererSubsectorLocator;
  LGrid: TRendererSubsectorGrid;
  // the old code, as it was
  i, j: Integer;
  pvx, pvy: Integer;
  minx, miny, maxx, maxy: Int64;
  width, height: Int64;
  size: Integer;
  map_max_bound: Integer;
  tmp: Integer;
  hitcnt: Integer;
  ss1, ss2: Integer;
  oldcells: array of Integer;
  function Incl(const x, y: Integer): Integer;
  begin
    Result := LLocator.Locate(x, y);
  end;
begin
  RandSeed := 20261116;
  for LScenario := 1 to 120 do
  begin
    LVertexCount := 2 + Random(30);
    SetLength(LVertexX, LVertexCount);
    SetLength(LVertexY, LVertexCount);
    for LIndex := 0 to LVertexCount - 1 do
    begin
      LVertexX[LIndex] := (Random(1400) - 500) * FRACUNIT + Random(FRACUNIT);
      LVertexY[LIndex] := (Random(900) - 300) * FRACUNIT + Random(FRACUNIT);
    end;
    LLocator := TFakeStripeLocator.Create;
    LIntf := LLocator;
    LLocator.StripeWidth := (20 + Random(200)) * FRACUNIT;
    LLocator.Margin := Random(3) * FRACUNIT;

    LGrid := FBuilder.Build(LVertexX, LVertexY, LIntf);

    // old R_PrecalcPointInSubSector
    pvx := LVertexX[0];
    pvy := LVertexY[0];
    minx := pvx;
    miny := pvy;
    maxx := pvx;
    maxy := pvy;
    for i := 1 to LVertexCount - 1 do
    begin
      pvx := LVertexX[i];
      pvy := LVertexY[i];
      if pvx < minx then
        minx := pvx
      else if pvx > maxx then
        maxx := pvx;
      if pvy < miny then
        miny := pvy
      else if pvy > maxy then
        maxy := pvy;
    end;
    map_max_bound := Abs(Integer(minx div FRACUNIT));
    tmp := Abs(Integer(maxx div FRACUNIT));
    if tmp > map_max_bound then
      map_max_bound := tmp;
    tmp := Abs(Integer(miny div FRACUNIT));
    if tmp > map_max_bound then
      map_max_bound := tmp;
    tmp := Abs(Integer(maxy div FRACUNIT));
    if tmp > map_max_bound then
      map_max_bound := tmp;
    width := (maxx - minx) div CELL + 1;
    height := (maxy - miny) div CELL + 1;
    size := width * height;
    SetLength(oldcells, size);
    for i := 0 to size - 1 do
      oldcells[i] := -1;
    hitcnt := 0;
    for i := 0 to width - 1 do
      for j := 0 to height - 1 do
      begin
        ss1 := Incl(minx + i * CELL, miny + j * CELL);
        ss2 := Incl(minx + i * CELL + CELL - 1, miny + j * CELL);
        if (ss1 >= 0) and (ss1 = ss2) then
        begin
          ss2 := Incl(minx + i * CELL + CELL - 1, miny + j * CELL + CELL - 1);
          if (ss2 >= 0) and (ss1 = ss2) then
          begin
            ss2 := Incl(minx + i * CELL, miny + j * CELL + CELL - 1);
            if (ss2 >= 0) and (ss1 = ss2) then
            begin
              oldcells[j * width + i] := ss2;
              Inc(hitcnt);
            end;
          end;
        end;
      end;

    Assert.AreEqual(minx, LGrid.MinX);
    Assert.AreEqual(miny, LGrid.MinY);
    Assert.AreEqual(width, LGrid.Width);
    Assert.AreEqual(height, LGrid.Height);
    Assert.AreEqual(map_max_bound, LGrid.MaxBound);
    Assert.AreEqual(hitcnt, LGrid.HitCount);
    Assert.AreEqual<Integer>(size, Length(LGrid.Cells));
    for i := 0 to size - 1 do
      Assert.AreEqual(oldcells[i], LGrid.Cells[i], 'cell ' + IntToStr(i));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRendererSubsectorGrid);

end.
