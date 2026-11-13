{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the spatial grid of the units        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapGrid;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Map.Grid;

type
  /// <summary>
  ///   grid.golden.txt is the output of war_lvl_ref.exe: wgrid_clear, wgrid_build, wgrid_tileFromMapTile and
  ///   wgrid_getTileIndex of war_map_grid.c of war1 as they are, compiled with gcc (Tools\Verifica\193), on
  ///   scenarios with a fixed seed
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarMapGrid = class(TObject)
  private
    FState: Cardinal;
    function Next: Cardinal;
    function Range(AMax: Integer): Integer;
    function GridUnit(ASlot: Integer; AActive: Boolean; AX, AY: Single): TWarGridUnit;
  public
    [Test]
    procedure DovrebbeIniziareVuota;
    [Test]
    procedure DovrebbeMettereLUnitaNellaSuaCella;
    [Test]
    procedure DovrebbeDareLUltimaUnitaMessaComePrimaDellaCatena;
    [Test]
    procedure DovrebbeSaltareLeUnitaNonAttive;
    [Test]
    procedure DovrebbeSaltareLeUnitaFuoriDallaMappa;
    [Test]
    procedure DovrebbeRifiutareUnaCasellaFuoriDallaTabella;
    [Test]
    procedure DovrebbeRifareLaGrigliaAOgniCostruzione;
    [Test]
    procedure DovrebbeSvuotareLaGriglia;
    [Test]
    procedure DovrebbeTroncareVersoZeroLaCella;
    [Test]
    procedure DovrebbeDareIndiceMenoUnoFuoriDallaGriglia;
    [Test]
    procedure DovrebbeRifiutareUnaCellaOUnaCasellaFuoriLimite;
    [Test]
    procedure DovrebbeFermareUnaCatenaConUnCiclo;
    [Test]
    procedure DovrebbeDareLeStesseGriglieDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.MathCore.Crc32, DelphiDoom.Tests.War.RealData;

{ TTestWarMapGrid }

function TTestWarMapGrid.Next: Cardinal;
begin
  FState := FState * 1103515245 + 12345;
  Result := (FState shr 16) and $7FFF;
end;

function TTestWarMapGrid.Range(AMax: Integer): Integer;
begin
  Result := Integer(Next mod Cardinal(AMax));
end;

function TTestWarMapGrid.GridUnit(ASlot: Integer; AActive: Boolean; AX, AY: Single): TWarGridUnit;
begin
  Result.Slot := ASlot;
  Result.Active := AActive;
  Result.TileX := AX;
  Result.TileY := AY;
end;

procedure TTestWarMapGrid.DovrebbeIniziareVuota;
var
  LGrid: TWarMapGrid;
  LCell: Integer;
begin
  LGrid := TWarMapGrid.Create;
  try
    for LCell := 0 to WAR_MAP_GRID_CELLS - 1 do
      Assert.AreEqual(-1, LGrid.Head(LCell));
    Assert.AreEqual(-1, LGrid.Next(0));
    Assert.AreEqual(256, WAR_MAP_GRID_CELLS);
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeMettereLUnitaNellaSuaCella;
var
  LGrid: TWarMapGrid;
begin
  LGrid := TWarMapGrid.Create;
  try
    LGrid.Build([GridUnit(7, True, 9.5, 5)]);
    // tile (9.5, 5) is in the cell (2, 1): number 1 * 16 + 2
    Assert.AreEqual(7, LGrid.Head(18));
    Assert.AreEqual(1, Length(LGrid.UnitsInCell(18)));
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeDareLUltimaUnitaMessaComePrimaDellaCatena;
var
  LGrid: TWarMapGrid;
  LUnits: TArray<Integer>;
begin
  LGrid := TWarMapGrid.Create;
  try
    LGrid.Build([GridUnit(3, True, 1, 1), GridUnit(10, True, 2, 2), GridUnit(5, True, 3, 3)]);
    LUnits := LGrid.UnitsInCell(0);
    Assert.AreEqual(3, Length(LUnits));
    Assert.AreEqual(5, LUnits[0]);
    Assert.AreEqual(10, LUnits[1]);
    Assert.AreEqual(3, LUnits[2]);
    Assert.AreEqual(10, LGrid.Next(5));
    Assert.AreEqual(-1, LGrid.Next(3));
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeSaltareLeUnitaNonAttive;
var
  LGrid: TWarMapGrid;
begin
  LGrid := TWarMapGrid.Create;
  try
    LGrid.Build([GridUnit(1, False, 1, 1)]);
    Assert.AreEqual(0, Length(LGrid.UnitsInCell(0)));
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeSaltareLeUnitaFuoriDallaMappa;
var
  LGrid: TWarMapGrid;
  LCell: Integer;
  LCount: Integer;
begin
  LGrid := TWarMapGrid.Create;
  try
    LGrid.Build([GridUnit(1, True, 64, 0), GridUnit(2, True, 0, 70), GridUnit(3, True, -4.5, 3)]);
    LCount := 0;
    for LCell := 0 to WAR_MAP_GRID_CELLS - 1 do
      Inc(LCount, Length(LGrid.UnitsInCell(LCell)));
    // -4.5 / 4 = -1.12 truncates to -1: outside; 64 / 4 = 16: outside
    Assert.AreEqual(0, LCount);
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeRifiutareUnaCasellaFuoriDallaTabella;
var
  LGrid: TWarMapGrid;
begin
  LGrid := TWarMapGrid.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LGrid.Build([GridUnit(1024, True, 1, 1)]);
      end, EWarException);
    Assert.WillRaise(
      procedure
      begin
        LGrid.Build([GridUnit(-1, True, 1, 1)]);
      end, EWarException);
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeRifareLaGrigliaAOgniCostruzione;
var
  LGrid: TWarMapGrid;
begin
  LGrid := TWarMapGrid.Create;
  try
    LGrid.Build([GridUnit(1, True, 1, 1)]);
    LGrid.Build([GridUnit(2, True, 40, 40)]);
    Assert.AreEqual(0, Length(LGrid.UnitsInCell(0)));
    Assert.AreEqual(-1, LGrid.Next(1));
    Assert.AreEqual(2, LGrid.Head(10 * 16 + 10));
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeSvuotareLaGriglia;
var
  LGrid: TWarMapGrid;
begin
  LGrid := TWarMapGrid.Create;
  try
    LGrid.Build([GridUnit(1, True, 1, 1)]);
    LGrid.Clear;
    Assert.AreEqual(-1, LGrid.Head(0));
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeTroncareVersoZeroLaCella;
var
  LX: Integer;
  LY: Integer;
begin
  TWarMapGrid.TileFromMapTile(-0.5, 3.99, LX, LY);
  Assert.AreEqual(0, LX);
  Assert.AreEqual(0, LY);
  TWarMapGrid.TileFromMapTile(-4, 63.99, LX, LY);
  Assert.AreEqual(-1, LX);
  Assert.AreEqual(15, LY);
end;

procedure TTestWarMapGrid.DovrebbeDareIndiceMenoUnoFuoriDallaGriglia;
begin
  Assert.AreEqual(0, TWarMapGrid.GetTileIndex(0, 0));
  Assert.AreEqual(255, TWarMapGrid.GetTileIndex(15, 15));
  Assert.AreEqual(-1, TWarMapGrid.GetTileIndex(16, 0));
  Assert.AreEqual(-1, TWarMapGrid.GetTileIndex(0, 16));
  Assert.AreEqual(-1, TWarMapGrid.GetTileIndex(-1, 3));
  Assert.AreEqual(-1, TWarMapGrid.GetTileIndex(3, -1));
end;

procedure TTestWarMapGrid.DovrebbeRifiutareUnaCellaOUnaCasellaFuoriLimite;
var
  LGrid: TWarMapGrid;
begin
  LGrid := TWarMapGrid.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LGrid.Head(256);
      end, EWarException);
    Assert.WillRaise(
      procedure
      begin
        LGrid.Next(-1);
      end, EWarException);
    Assert.WillRaise(
      procedure
      begin
        LGrid.Next(1024);
      end, EWarException);
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeFermareUnaCatenaConUnCiclo;
var
  LGrid: TWarMapGrid;
begin
  LGrid := TWarMapGrid.Create;
  try
    // the same slot twice in a cell makes the chain point to itself; the original would follow it forever
    LGrid.Build([GridUnit(4, True, 1, 1), GridUnit(4, True, 1, 1)]);
    Assert.AreEqual(1024, Length(LGrid.UnitsInCell(0)));
  finally
    LGrid.Free;
  end;
end;

procedure TTestWarMapGrid.DovrebbeDareLeStesseGriglieDelCodiceOriginale;
const
  COORDINATES: array[0..9] of Single = (-1.0, -0.5, 0.0, 3.9, 4.0, 15.75, 63.0, 63.99, 64.0, 70.0);
var
  LGolden: TStringList;
  LActual: TStringList;
  LGrid: TWarMapGrid;
  LScenario: Integer;
  LCount: Integer;
  LIndex: Integer;
  LUnits: TArray<TWarGridUnit>;
  LEnabled: Boolean;
  LDying: Boolean;
  LCollapsing: Boolean;
  LWholeX: Integer;
  LFractionX: Integer;
  LWholeY: Integer;
  LFractionY: Integer;
  LSlot: Integer;
  LCrc: TCrc32;
  LValue: Integer;
  LBytes: array[0..3] of Byte;
  LNonEmpty: Integer;
  LLine: string;
  LCellX: Integer;
  LCellY: Integer;
  LCellX2: Integer;
  LCellY2: Integer;
begin
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  LGrid := TWarMapGrid.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('grid.golden.txt'));
    for LScenario := 0 to 59 do
    begin
      FState := 9000 + Cardinal(LScenario);
      LCount := Range(200);
      SetLength(LUnits, LCount);
      for LIndex := 0 to LCount - 1 do
      begin
        LSlot := LIndex * 5 + Range(5);
        LEnabled := Range(8) <> 0;
        LDying := Range(10) = 0;
        LCollapsing := Range(12) = 0;
        LWholeX := Range(75) - 5;
        LFractionX := Range(4);
        LWholeY := Range(75) - 5;
        LFractionY := Range(4);
        LUnits[LIndex] := GridUnit(LSlot, LEnabled and not LDying and not LCollapsing,
          LWholeX + LFractionX * 0.25, LWholeY + LFractionY * 0.25);
      end;
      LGrid.Build(LUnits);
      LCrc := TCrc32.Create;
      try
        for LIndex := 0 to WAR_MAP_GRID_CELLS - 1 do
        begin
          LValue := LGrid.Head(LIndex);
          LBytes[0] := Byte(LValue);
          LBytes[1] := Byte(LValue shr 8);
          LBytes[2] := 0;
          LBytes[3] := 0;
          LCrc.Update(LBytes[0], 4);
        end;
        for LIndex := 0 to 1023 do
        begin
          LValue := LGrid.Next(LIndex);
          LBytes[0] := Byte(LValue);
          LBytes[1] := Byte(LValue shr 8);
          LBytes[2] := 0;
          LBytes[3] := 0;
          LCrc.Update(LBytes[0], 4);
        end;
        LActual.Add(Format('B %d %d %s', [LScenario, LCount, LowerCase(TCrc32.ToHex(LCrc.Value))]));
      finally
        LCrc.Free;
      end;
      LGrid.Clear;
      LNonEmpty := 0;
      for LIndex := 0 to WAR_MAP_GRID_CELLS - 1 do
        if LGrid.Head(LIndex) <> -1 then
          Inc(LNonEmpty);
      LActual.Add(Format('b %d %d', [LScenario, LNonEmpty]));
    end;
    LLine := 'X';
    for LIndex := 0 to High(COORDINATES) do
    begin
      TWarMapGrid.TileFromMapTile(Trunc(COORDINATES[LIndex]), Trunc(COORDINATES[(LIndex + 3) mod 10]), LCellX, LCellY);
      TWarMapGrid.TileFromMapTile(COORDINATES[LIndex], COORDINATES[(LIndex + 3) mod 10], LCellX2, LCellY2);
      LLine := LLine + Format(' %d,%d:%d:%d', [LCellX, LCellY, TWarMapGrid.GetTileIndex(LCellX, LCellY),
        TWarMapGrid.GetTileIndex(LCellX2, LCellY2)]);
    end;
    LActual.Add(LLine);
    Assert.AreEqual(LGolden.Count, LActual.Count);
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'riga ' + IntToStr(LIndex));
  finally
    LGrid.Free;
    LActual.Free;
    LGolden.Free;
  end;
end;

end.
