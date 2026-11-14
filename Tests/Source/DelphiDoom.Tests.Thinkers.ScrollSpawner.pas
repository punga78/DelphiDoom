{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the values of the new scrollers (P_SpawnScrollers)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.ScrollSpawner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersScrollSpawner = class(TObject)
  public
    [Test]
    procedure DovrebbeLasciareLoSpecialSenzaControlloComEra;
    [Test]
    procedure DovrebbeRiconoscereGliSpecialASpostamento;
    [Test]
    procedure DovrebbeRiconoscereGliSpecialAdAccelerazione;
    [Test]
    procedure DovrebbeDecodificareOgniSpecialComeIlVecchioCodice;
    [Test]
    procedure DovrebbeDareUnTrentaduesimoDellaLinea;
    [Test]
    procedure DovrebbeDareTreTrentaduesimiAlTrasporto;
    [Test]
    procedure DovrebbeDareLoScorrimentoOrizzontaleLungoIlMuro;
    [Test]
    procedure DovrebbeDareLoScorrimentoVerticaleVersoIlMuro;
    [Test]
    procedure DovrebbeDareIlVettoreDelMuroComeIlVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Thinkers.Scroll.Spawner, DelphiDoom.Tests.Thinkers.OldScroll,
  DelphiDoom.Tests.Thinkers.PlaneFakes;

const
  FRACUNIT = 65536;

{ TTestThinkersScrollSpawner }

procedure TTestThinkersScrollSpawner.DovrebbeLasciareLoSpecialSenzaControlloComEra;
var
  LControl: TScrollControl;
begin
  Assert.AreEqual(250, TScrollSpawner.Decode(250, LControl), '250');
  Assert.AreEqual(Ord(TScrollControl.None), Ord(LControl), 'control of 250');
  Assert.AreEqual(48, TScrollSpawner.Decode(48, LControl), '48');
  Assert.AreEqual(Ord(TScrollControl.None), Ord(LControl), 'control of 48');
  Assert.AreEqual(1026, TScrollSpawner.Decode(1026, LControl), '1026');
  Assert.AreEqual(Ord(TScrollControl.None), Ord(LControl), 'control of 1026');
end;

procedure TTestThinkersScrollSpawner.DovrebbeRiconoscereGliSpecialASpostamento;
var
  LControl: TScrollControl;
  LSpecial: Integer;
begin
  for LSpecial := 245 to 249 do
  begin
    Assert.AreEqual(LSpecial + 5, TScrollSpawner.Decode(LSpecial, LControl), 'special');
    Assert.AreEqual(Ord(TScrollControl.Displacement), Ord(LControl), 'control');
  end;
  Assert.AreEqual(TScrollSpawner.SPECIAL_CEILING, TScrollSpawner.Decode(245, LControl));
  Assert.AreEqual(TScrollSpawner.SPECIAL_WALL, TScrollSpawner.Decode(249, LControl));
end;

procedure TTestThinkersScrollSpawner.DovrebbeRiconoscereGliSpecialAdAccelerazione;
var
  LControl: TScrollControl;
  LSpecial: Integer;
begin
  for LSpecial := 214 to 218 do
  begin
    Assert.AreEqual(LSpecial + 36, TScrollSpawner.Decode(LSpecial, LControl), 'special');
    Assert.AreEqual(Ord(TScrollControl.Accelerative), Ord(LControl), 'control');
  end;
  Assert.AreEqual(TScrollSpawner.SPECIAL_FLOOR, TScrollSpawner.Decode(215, LControl));
  Assert.AreEqual(TScrollSpawner.SPECIAL_CARRY, TScrollSpawner.Decode(216, LControl));
  Assert.AreEqual(TScrollSpawner.SPECIAL_FLOOR_AND_CARRY, TScrollSpawner.Decode(217, LControl));
end;

procedure TTestThinkersScrollSpawner.DovrebbeDecodificareOgniSpecialComeIlVecchioCodice;
var
  LSpecial, LOldSpecial, LOldAccel, LOldControl, LNewSpecial: Integer;
  LControl: TScrollControl;
begin
  for LSpecial := -10 to 1100 do
  begin
    LOldSpecial := LSpecial;
    OldDecodeSpecial(LOldSpecial, LOldAccel, LOldControl);
    LNewSpecial := TScrollSpawner.Decode(LSpecial, LControl);
    Assert.AreEqual(LOldSpecial, LNewSpecial, Format('special %d', [LSpecial]));
    Assert.AreEqual(LOldAccel = 1, LControl = TScrollControl.Accelerative,
      Format('accel of %d', [LSpecial]));
    Assert.AreEqual(LOldControl <> -1, LControl <> TScrollControl.None,
      Format('control of %d', [LSpecial]));
  end;
end;

procedure TTestThinkersScrollSpawner.DovrebbeDareUnTrentaduesimoDellaLinea;
var
  LState: Cardinal;
  LCase, LValue: Integer;
begin
  Assert.AreEqual(2 * FRACUNIT, TScrollSpawner.LineSpeed(64 * FRACUNIT), 'positive');
  Assert.AreEqual(-2 * FRACUNIT, TScrollSpawner.LineSpeed(-64 * FRACUNIT), 'negative');
  Assert.AreEqual(0, TScrollSpawner.LineSpeed(-31), 'towards zero');
  LState := 5;
  for LCase := 1 to 5000 do
  begin
    LValue := TestNumberIn(LState, -MaxInt, MaxInt);
    Assert.AreEqual(OldLineSpeed(LValue), TScrollSpawner.LineSpeed(LValue),
      Format('line %d', [LValue]));
  end;
end;

procedure TTestThinkersScrollSpawner.DovrebbeDareTreTrentaduesimiAlTrasporto;
var
  LState: Cardinal;
  LCase, LValue: Integer;
begin
  Assert.AreEqual(3 * FRACUNIT, TScrollSpawner.CarrySpeed(32 * FRACUNIT), 'positive');
  Assert.AreEqual(-3 * FRACUNIT, TScrollSpawner.CarrySpeed(-32 * FRACUNIT), 'negative');
  LState := 6;
  for LCase := 1 to 5000 do
  begin
    LValue := TestNumberIn(LState, -MaxInt, MaxInt);
    Assert.AreEqual(OldCarrySpeed(LValue), TScrollSpawner.CarrySpeed(LValue),
      Format('speed %d', [LValue]));
  end;
end;

procedure TTestThinkersScrollSpawner.DovrebbeDareLoScorrimentoOrizzontaleLungoIlMuro;
var
  LX, LY: Integer;
begin
  // a wall along x, a movement along x: the texture goes sideways (to the other side)
  TScrollSpawner.WallVector(2 * FRACUNIT, 0, 64 * FRACUNIT, 0, LX, LY);
  // the sine of the table at 90 degrees is one unit short of 1: a few units of rounding
  Assert.IsTrue(Abs(LX + 2 * FRACUNIT) <= 4, Format('x = %d', [LX]));
  Assert.AreEqual(0, LY, 'y');
end;

procedure TTestThinkersScrollSpawner.DovrebbeDareLoScorrimentoVerticaleVersoIlMuro;
var
  LX, LY: Integer;
begin
  // a wall along x, a movement along y: the texture goes up or down
  TScrollSpawner.WallVector(0, 2 * FRACUNIT, 64 * FRACUNIT, 0, LX, LY);
  Assert.AreEqual(0, LX, 'x');
  Assert.IsTrue(Abs(LY - 2 * FRACUNIT) <= 4, Format('y = %d', [LY]));
end;

procedure TTestThinkersScrollSpawner.DovrebbeDareIlVettoreDelMuroComeIlVecchioCodice;
var
  LState: Cardinal;
  LCase, LDeltaX, LDeltaY, LLineX, LLineY, LOldX, LOldY, LNewX, LNewY: Integer;
  LText: string;
begin
  LState := 31;
  for LCase := 1 to 20000 do
  begin
    LDeltaX := TestNumberIn(LState, -8 * FRACUNIT, 8 * FRACUNIT);
    LDeltaY := TestNumberIn(LState, -8 * FRACUNIT, 8 * FRACUNIT);
    LLineX := TestNumberIn(LState, -2048, 2048) * FRACUNIT;
    LLineY := TestNumberIn(LState, -2048, 2048) * FRACUNIT;
    // a line has a length: the old code divides by zero on a point
    if (LLineX = 0) and (LLineY = 0) then
      LLineX := FRACUNIT;
    OldWallScroller(LDeltaX, LDeltaY, LLineX, LLineY, LOldX, LOldY);
    TScrollSpawner.WallVector(LDeltaX, LDeltaY, LLineX, LLineY, LNewX, LNewY);
    LText := Format('case %d (%d, %d) line (%d, %d)', [LCase, LDeltaX, LDeltaY, LLineX, LLineY]);
    Assert.AreEqual(LOldX, LNewX, 'x of ' + LText);
    Assert.AreEqual(LOldY, LNewY, 'y of ' + LText);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersScrollSpawner);

end.
