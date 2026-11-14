{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixTriggerGrid                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.TriggerGrid;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.LevelLogic.Types, DelphiDoom.Radix.TriggerGrid;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixTriggerGrid = class(TObject)
  strict private
    FGrid: TRadixTriggerGrid;
    class function GridData(AWidth, AHeight: Integer): TRadixTriggerGridData; static;
    class function DefaultPosition: TRadixSectorPosition; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLaCellaDiUnPuntoDellaMappa;
    [Test]
    procedure DovrebbeUsareLaPosizioneDelSettore;
    [Test]
    procedure DovrebbeDareIlTriggerDiUnaCella;
    [Test]
    procedure DovrebbeDareNessunTriggerFuoriDallaGriglia;
    [Test]
    procedure DovrebbeDareIlPostoDiUnaCellaNellaMappa;
    [Test]
    procedure DovrebbeNonAvereGrigliaSeLeDimensioniSonoZero;
    [Test]
    procedure DovrebbeDireSeLaNavettaSiMuove;
    [Test]
    procedure DovrebbeCampionareIlMovimentoInTrePunti;
    [Test]
    procedure DovrebbeTenereUnaCellaSolaVoltaNellePosizioni;
    [Test]
    procedure DovrebbeNonCambiareSeIDatiCambianoDopo;
  end;

implementation

const
  GRID_WIDTH = 320;
  GRID_HEIGHT = 128;
  FIXED_UNIT = 65536;

{ TTestRadixTriggerGrid }

class function TTestRadixTriggerGrid.GridData(AWidth, AHeight: Integer): TRadixTriggerGridData;
var
  LIndex: Integer;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Cells, RADIX_GRID_SIZE);
  for LIndex := 0 to RADIX_GRID_SIZE - 1 do
    Result.Cells[LIndex] := RADIX_NO_TRIGGER;
end;

class function TTestRadixTriggerGrid.DefaultPosition: TRadixSectorPosition;
begin
  Result.XMul := RADIX_MAP_X_MULT;
  Result.XAdd := RADIX_MAP_X_ADD;
  Result.YMul := RADIX_MAP_Y_MULT;
  Result.YAdd := RADIX_MAP_Y_ADD;
end;

procedure TTestRadixTriggerGrid.Setup;
var
  LData: TRadixTriggerGridData;
  LPoints: TArray<TRadixLevelMapPoint>;
begin
  LData := GridData(GRID_WIDTH, GRID_HEIGHT);
  LData.Cells[2 * GRID_WIDTH + 3] := 7;
  SetLength(LPoints, RADIX_GRID_SIZE);
  LPoints[2 * GRID_WIDTH + 3].X := -32575;
  LPoints[2 * GRID_WIDTH + 3].Y := -128;
  FGrid := TRadixTriggerGrid.Create(LData, LPoints);
end;

procedure TTestRadixTriggerGrid.TearDown;
begin
  FGrid.Free;
end;

procedure TTestRadixTriggerGrid.DovrebbeDareLaCellaDiUnPuntoDellaMappa;
begin
  // radix x = map x + 32767, radix y = -map y: (200, 130) is column 3, row 2
  Assert.AreEqual(2 * GRID_WIDTH + 3, FGrid.CellAt(DefaultPosition, 200 - 32767, -130));
  Assert.AreEqual(0, FGrid.CellAt(DefaultPosition, -32767, 0));
  Assert.AreEqual(GRID_WIDTH + 1, FGrid.CellAt(DefaultPosition, 64 - 32767, -64));
  Assert.AreEqual(0, FGrid.CellAt(DefaultPosition, 63 - 32767, -63));
end;

procedure TTestRadixTriggerGrid.DovrebbeUsareLaPosizioneDelSettore;
var
  LPosition: TRadixSectorPosition;
begin
  // the second half of the split level: other additions
  LPosition := DefaultPosition;
  LPosition.XAdd := RADIX_MAP_X_ADD2;
  LPosition.YAdd := RADIX_MAP_Y_ADD2;
  Assert.AreEqual(2 * GRID_WIDTH + 3, FGrid.CellAt(LPosition, 200 - 65536, -4096 - 130));
end;

procedure TTestRadixTriggerGrid.DovrebbeDareIlTriggerDiUnaCella;
begin
  Assert.AreEqual(7, FGrid.TriggerAt(2 * GRID_WIDTH + 3));
  Assert.AreEqual(RADIX_NO_TRIGGER, FGrid.TriggerAt(0));
end;

procedure TTestRadixTriggerGrid.DovrebbeDareNessunTriggerFuoriDallaGriglia;
begin
  Assert.IsFalse(FGrid.IsCell(-1));
  Assert.IsFalse(FGrid.IsCell(RADIX_GRID_SIZE));
  Assert.IsTrue(FGrid.IsCell(RADIX_GRID_SIZE - 1));
  Assert.AreEqual(RADIX_NO_TRIGGER, FGrid.TriggerAt(-1));
  Assert.AreEqual(RADIX_NO_TRIGGER, FGrid.TriggerAt(RADIX_GRID_SIZE));
end;

procedure TTestRadixTriggerGrid.DovrebbeDareIlPostoDiUnaCellaNellaMappa;
var
  LX: Integer;
  LY: Integer;
begin
  Assert.IsTrue(FGrid.TryCellToMap(2 * GRID_WIDTH + 3, LX, LY));
  Assert.AreEqual(-32575, LX);
  Assert.AreEqual(-128, LY);
  Assert.IsFalse(FGrid.TryCellToMap(-1, LX, LY));
  Assert.IsFalse(FGrid.TryCellToMap(RADIX_GRID_SIZE, LX, LY));
end;

procedure TTestRadixTriggerGrid.DovrebbeNonAvereGrigliaSeLeDimensioniSonoZero;
var
  LGrid: TRadixTriggerGrid;
  LX: Integer;
  LY: Integer;
begin
  LGrid := TRadixTriggerGrid.Create(GridData(0, 0), nil);
  try
    Assert.IsFalse(LGrid.HasGrid);
    Assert.IsFalse(LGrid.TryCellToMap(0, LX, LY));
    Assert.AreEqual(RADIX_NO_TRIGGER, LGrid.TriggerAt(5));
  finally
    LGrid.Free;
  end;
  Assert.IsTrue(FGrid.HasGrid);
  Assert.AreEqual(GRID_WIDTH, FGrid.Width);
  Assert.AreEqual(GRID_HEIGHT, FGrid.Height);
end;

procedure TTestRadixTriggerGrid.DovrebbeDireSeLaNavettaSiMuove;
begin
  Assert.IsFalse(TRadixTriggerGrid.IsMoving(0, 0));
  Assert.IsTrue(TRadixTriggerGrid.IsMoving(1, 0));
  Assert.IsTrue(TRadixTriggerGrid.IsMoving(0, -1));
end;

procedure TTestRadixTriggerGrid.DovrebbeCampionareIlMovimentoInTrePunti;
var
  LSamples: TRadixMovementSamples;
begin
  LSamples := TRadixTriggerGrid.MovementSamples(100 * FIXED_UNIT, -50 * FIXED_UNIT, 30 * FIXED_UNIT,
    -60 * FIXED_UNIT);
  // two thirds of the way, one third, where the craft is
  Assert.AreEqual(120, LSamples[0].X);
  Assert.AreEqual(-90, LSamples[0].Y);
  Assert.AreEqual(110, LSamples[1].X);
  Assert.AreEqual(-70, LSamples[1].Y);
  Assert.AreEqual(100, LSamples[2].X);
  Assert.AreEqual(-50, LSamples[2].Y);
end;

procedure TTestRadixTriggerGrid.DovrebbeTenereUnaCellaSolaVoltaNellePosizioni;
var
  LPositions: TRadixGridPositions;
begin
  LPositions := TRadixGridPositions.Empty;
  Assert.AreEqual(0, LPositions.Count);
  LPositions.Add(5);
  LPositions.Add(5);
  LPositions.Add(9);
  Assert.AreEqual(2, LPositions.Count);
  Assert.AreEqual(5, LPositions.Cells[0]);
  Assert.AreEqual(9, LPositions.Cells[1]);
  LPositions.Add(1);
  LPositions.Add(2);
  Assert.AreEqual(RADIX_MAX_GRID_POSITIONS, LPositions.Count);
  Assert.AreEqual(1, LPositions.Cells[2]);
end;

procedure TTestRadixTriggerGrid.DovrebbeNonCambiareSeIDatiCambianoDopo;
var
  LData: TRadixTriggerGridData;
  LGrid: TRadixTriggerGrid;
begin
  LData := GridData(GRID_WIDTH, GRID_HEIGHT);
  LData.Cells[10] := 4;
  LGrid := TRadixTriggerGrid.Create(LData, nil);
  try
    LData.Cells[10] := 99;
    Assert.AreEqual(4, LGrid.TriggerAt(10));
  finally
    LGrid.Free;
  end;
end;

end.
