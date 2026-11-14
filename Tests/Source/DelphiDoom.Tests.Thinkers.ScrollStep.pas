{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the tic of a scroller (T_Scroll)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.ScrollStep;

// The offsets of the random cases are large and the old code let the sums wrap
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Thinkers.OldScroll;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersScrollStep = class(TObject)
  strict private
    FOldWorld: TOldScrollWorld;
    FNewWorld: TOldScrollWorld;
    procedure BuildWorlds(var AState: Cardinal);
    procedure MoveControlSectors(var AState: Cardinal);
    procedure CheckWorlds(const AText: string);
    /// <summary>T_Scroll as Base\p_scroll.pas writes it now, on the world of the test</summary>
    procedure NewScroll(AWorld: POldScrollWorld; AScroller: Pscroll_t);
  public
    [Test]
    procedure DovrebbeDareLeVelocitaSenzaControlloNeAccelerazione;
    [Test]
    procedure DovrebbeDareFalsoSeNonCeNullaDaScorrere;
    [Test]
    procedure DovrebbeSeguireIlCambioDiAltezzaDelSettoreDiControllo;
    [Test]
    procedure DovrebbeNonLeggereAltezzaSenzaControllo;
    [Test]
    procedure DovrebbeSommareLeQuantitaSeAccelera;
    [Test]
    procedure DovrebbeTrasportareSoloChiPoggiaSulPavimento;
    [Test]
    procedure DovrebbeTrasportareAncheChiGalleggiaSottoAcqua;
    [Test]
    procedure DovrebbeNonTrasportareChiNonHaCollisioni;
    [Test]
    procedure DovrebbeDareAcquaSoloSeIlSettoreDiAltezzaStaSopraIlPavimento;
    [Test]
    [TestCase('seme 1', '1')]
    [TestCase('seme 2', '77')]
    [TestCase('seme 3', '2026')]
    procedure DovrebbeSeguireIlVecchioCodicePerMigliaiaDiTic(ASeed: Integer);
  end;

implementation

uses
  DelphiDoom.Thinkers.Scroll.Step, DelphiDoom.Tests.Thinkers.PlaneFakes;

const
  FRACUNIT = 65536;

{ TTestThinkersScrollStep }

procedure TTestThinkersScrollStep.NewScroll(AWorld: POldScrollWorld; AScroller: Pscroll_t);
var
  LDeltaX, LDeltaY, LHeight, LWater: Integer;
  LSector: Psector_t;
  LSide: Pside_t;
  LNode: Pmsecnode_t;
  LThing: Pmobj_t;
begin
  LDeltaX := AScroller.dx;
  LDeltaY := AScroller.dy;
  if AScroller.control <> -1 then
    LHeight := AWorld.sectors[AScroller.control].floorheight +
      AWorld.sectors[AScroller.control].ceilingheight
  else
    LHeight := 0;
  if not TScrollStep.Advance(LDeltaX, LDeltaY, AScroller.control <> -1, LHeight,
    AScroller.last_height, AScroller.accel <> 0, AScroller.vdx, AScroller.vdy) then
    Exit;

  case AScroller._type of
    sc_side:
      begin
        LSide := @AWorld.sides[AScroller.affectee];
        LSide.textureoffset := LSide.textureoffset + LDeltaX;
        LSide.rowoffset := LSide.rowoffset + LDeltaY;
      end;
    sc_floor:
      begin
        LSector := @AWorld.sectors[AScroller.affectee];
        LSector.floor_xoffs := LSector.floor_xoffs + LDeltaX;
        LSector.floor_yoffs := LSector.floor_yoffs + LDeltaY;
      end;
    sc_ceiling:
      begin
        LSector := @AWorld.sectors[AScroller.affectee];
        LSector.ceiling_xoffs := LSector.ceiling_xoffs + LDeltaX;
        LSector.ceiling_yoffs := LSector.ceiling_yoffs + LDeltaY;
      end;
    sc_carry:
      begin
        LSector := @AWorld.sectors[AScroller.affectee];
        LHeight := LSector.floorheight;
        if LSector.heightsec > -1 then
          LWater := TScrollStep.WaterHeight(True,
            AWorld.sectors[LSector.heightsec].floorheight, LHeight)
        else
          LWater := TScrollStep.WaterHeight(False, 0, LHeight);
        LNode := LSector.touching_thinglist;
        while Assigned(LNode) do
        begin
          LThing := LNode.m_thing;
          if TScrollStep.Carries(LThing.flags and MF_NOCLIP <> 0,
            LThing.flags and MF_NOGRAVITY <> 0, LThing.z, LHeight, LWater) then
          begin
            LThing.momx := LThing.momx + LDeltaX;
            LThing.momy := LThing.momy + LDeltaY;
          end;
          LNode := LNode.m_snext;
        end;
      end;
  end;
end;

procedure TTestThinkersScrollStep.BuildWorlds(var AState: Cardinal);
var
  LIndex: Integer;
begin
  FillChar(FOldWorld, SizeOf(FOldWorld), 0);
  for LIndex := 0 to High(FOldWorld.sectors) do
  begin
    FOldWorld.sectors[LIndex].floorheight := TestNumberIn(AState, -64, 64) * FRACUNIT;
    FOldWorld.sectors[LIndex].ceilingheight :=
      FOldWorld.sectors[LIndex].floorheight + TestNumberIn(AState, 0, 128) * FRACUNIT;
    FOldWorld.sectors[LIndex].heightsec := TestNumberIn(AState, -1, High(FOldWorld.sectors));
  end;
  for LIndex := 0 to High(FOldWorld.things) do
  begin
    FOldWorld.things[LIndex].flags := 0;
    if TestNumberIn(AState, 0, 3) = 0 then
      FOldWorld.things[LIndex].flags := FOldWorld.things[LIndex].flags or MF_NOGRAVITY;
    if TestNumberIn(AState, 0, 5) = 0 then
      FOldWorld.things[LIndex].flags := FOldWorld.things[LIndex].flags or MF_NOCLIP;
    FOldWorld.things[LIndex].z := TestNumberIn(AState, -80, 80) * FRACUNIT;
  end;
  FNewWorld := FOldWorld;
  // two things in every sector: the lists point into their own world
  for LIndex := 0 to High(FOldWorld.nodes) do
  begin
    FOldWorld.nodes[LIndex].m_thing := @FOldWorld.things[LIndex];
    FNewWorld.nodes[LIndex].m_thing := @FNewWorld.things[LIndex];
    if Odd(LIndex) then
    begin
      FOldWorld.nodes[LIndex].m_snext := nil;
      FNewWorld.nodes[LIndex].m_snext := nil;
    end
    else
    begin
      FOldWorld.nodes[LIndex].m_snext := @FOldWorld.nodes[LIndex + 1];
      FNewWorld.nodes[LIndex].m_snext := @FNewWorld.nodes[LIndex + 1];
      FOldWorld.sectors[LIndex div 2].touching_thinglist := @FOldWorld.nodes[LIndex];
      FNewWorld.sectors[LIndex div 2].touching_thinglist := @FNewWorld.nodes[LIndex];
    end;
  end;
end;

procedure TTestThinkersScrollStep.MoveControlSectors(var AState: Cardinal);
var
  LIndex, LFloor, LCeiling, LThingZ: Integer;
begin
  for LIndex := 0 to High(FOldWorld.sectors) do
    if TestNumberIn(AState, 0, 2) = 0 then
    begin
      LFloor := TestNumberIn(AState, -2 * FRACUNIT, 2 * FRACUNIT);
      LCeiling := TestNumberIn(AState, -2 * FRACUNIT, 2 * FRACUNIT);
      Inc(FOldWorld.sectors[LIndex].floorheight, LFloor);
      Inc(FOldWorld.sectors[LIndex].ceilingheight, LCeiling);
      Inc(FNewWorld.sectors[LIndex].floorheight, LFloor);
      Inc(FNewWorld.sectors[LIndex].ceilingheight, LCeiling);
    end;
  LIndex := TestNumberIn(AState, 0, High(FOldWorld.things));
  LThingZ := TestNumberIn(AState, -80, 80) * FRACUNIT;
  FOldWorld.things[LIndex].z := LThingZ;
  FNewWorld.things[LIndex].z := LThingZ;
end;

procedure TTestThinkersScrollStep.CheckWorlds(const AText: string);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FOldWorld.sectors) do
  begin
    Assert.AreEqual(FOldWorld.sectors[LIndex].floor_xoffs, FNewWorld.sectors[LIndex].floor_xoffs,
      'floor x of ' + AText);
    Assert.AreEqual(FOldWorld.sectors[LIndex].floor_yoffs, FNewWorld.sectors[LIndex].floor_yoffs,
      'floor y of ' + AText);
    Assert.AreEqual(FOldWorld.sectors[LIndex].ceiling_xoffs,
      FNewWorld.sectors[LIndex].ceiling_xoffs, 'ceiling x of ' + AText);
    Assert.AreEqual(FOldWorld.sectors[LIndex].ceiling_yoffs,
      FNewWorld.sectors[LIndex].ceiling_yoffs, 'ceiling y of ' + AText);
  end;
  for LIndex := 0 to High(FOldWorld.sides) do
  begin
    Assert.AreEqual(FOldWorld.sides[LIndex].textureoffset, FNewWorld.sides[LIndex].textureoffset,
      'texture offset of ' + AText);
    Assert.AreEqual(FOldWorld.sides[LIndex].rowoffset, FNewWorld.sides[LIndex].rowoffset,
      'row offset of ' + AText);
  end;
  for LIndex := 0 to High(FOldWorld.things) do
  begin
    Assert.AreEqual(FOldWorld.things[LIndex].momx, FNewWorld.things[LIndex].momx,
      'momx of ' + AText);
    Assert.AreEqual(FOldWorld.things[LIndex].momy, FNewWorld.things[LIndex].momy,
      'momy of ' + AText);
  end;
end;

procedure TTestThinkersScrollStep.DovrebbeDareLeVelocitaSenzaControlloNeAccelerazione;
var
  LDeltaX, LDeltaY, LLast, LVelocityX, LVelocityY: Integer;
begin
  LDeltaX := 3;
  LDeltaY := -5;
  LLast := 11;
  LVelocityX := 100;
  LVelocityY := 200;
  Assert.IsTrue(TScrollStep.Advance(LDeltaX, LDeltaY, False, 999, LLast, False,
    LVelocityX, LVelocityY));
  Assert.AreEqual(3, LDeltaX, 'x');
  Assert.AreEqual(-5, LDeltaY, 'y');
  Assert.AreEqual(11, LLast, 'last height untouched');
  Assert.AreEqual(100, LVelocityX, 'velocity x untouched');
  Assert.AreEqual(200, LVelocityY, 'velocity y untouched');
end;

procedure TTestThinkersScrollStep.DovrebbeDareFalsoSeNonCeNullaDaScorrere;
var
  LDeltaX, LDeltaY, LLast, LVelocityX, LVelocityY: Integer;
begin
  LDeltaX := 0;
  LDeltaY := 0;
  LLast := 0;
  LVelocityX := 0;
  LVelocityY := 0;
  Assert.IsFalse(TScrollStep.Advance(LDeltaX, LDeltaY, False, 0, LLast, False,
    LVelocityX, LVelocityY), 'no speed');

  // a control sector that did not move stops the scroll
  LDeltaX := 5 * FRACUNIT;
  LDeltaY := 7 * FRACUNIT;
  LLast := 40 * FRACUNIT;
  Assert.IsFalse(TScrollStep.Advance(LDeltaX, LDeltaY, True, 40 * FRACUNIT, LLast, False,
    LVelocityX, LVelocityY), 'still control sector');
  Assert.AreEqual(0, LDeltaX, 'x');
  Assert.AreEqual(0, LDeltaY, 'y');
end;

procedure TTestThinkersScrollStep.DovrebbeSeguireIlCambioDiAltezzaDelSettoreDiControllo;
var
  LDeltaX, LDeltaY, LLast, LVelocityX, LVelocityY: Integer;
begin
  LDeltaX := 2 * FRACUNIT;
  LDeltaY := -FRACUNIT div 2;
  LLast := 40 * FRACUNIT;
  LVelocityX := 0;
  LVelocityY := 0;
  Assert.IsTrue(TScrollStep.Advance(LDeltaX, LDeltaY, True, 44 * FRACUNIT, LLast, False,
    LVelocityX, LVelocityY));
  Assert.AreEqual(8 * FRACUNIT, LDeltaX, 'x = speed * 4');
  Assert.AreEqual(-2 * FRACUNIT, LDeltaY, 'y = speed * 4');
  Assert.AreEqual(44 * FRACUNIT, LLast, 'the height is remembered');
  Assert.AreEqual(0, LVelocityX, 'no acceleration');
end;

procedure TTestThinkersScrollStep.DovrebbeNonLeggereAltezzaSenzaControllo;
var
  LDeltaX, LDeltaY, LLast, LVelocityX, LVelocityY: Integer;
begin
  LDeltaX := FRACUNIT;
  LDeltaY := FRACUNIT;
  LLast := 7;
  LVelocityX := 0;
  LVelocityY := 0;
  TScrollStep.Advance(LDeltaX, LDeltaY, False, 123456, LLast, False, LVelocityX, LVelocityY);
  Assert.AreEqual(FRACUNIT, LDeltaX, 'x');
  Assert.AreEqual(7, LLast, 'last height');
end;

procedure TTestThinkersScrollStep.DovrebbeSommareLeQuantitaSeAccelera;
var
  LDeltaX, LDeltaY, LLast, LVelocityX, LVelocityY, LTic: Integer;
begin
  LLast := 0;
  LVelocityX := 0;
  LVelocityY := 0;
  for LTic := 1 to 3 do
  begin
    LDeltaX := 10;
    LDeltaY := -4;
    Assert.IsTrue(TScrollStep.Advance(LDeltaX, LDeltaY, False, 0, LLast, True,
      LVelocityX, LVelocityY));
    Assert.AreEqual(10 * LTic, LDeltaX, 'x');
    Assert.AreEqual(-4 * LTic, LDeltaY, 'y');
  end;
  Assert.AreEqual(30, LVelocityX, 'velocity x');
  Assert.AreEqual(-12, LVelocityY, 'velocity y');
end;

procedure TTestThinkersScrollStep.DovrebbeTrasportareSoloChiPoggiaSulPavimento;
begin
  Assert.IsTrue(TScrollStep.Carries(False, False, 0, 0, Low(Integer)), 'on the floor');
  Assert.IsTrue(TScrollStep.Carries(False, False, -8, 0, Low(Integer)), 'below the floor');
  Assert.IsFalse(TScrollStep.Carries(False, False, 1, 0, Low(Integer)), 'in the air');
  Assert.IsFalse(TScrollStep.Carries(False, True, 0, 0, Low(Integer)), 'floating on the floor');
end;

procedure TTestThinkersScrollStep.DovrebbeTrasportareAncheChiGalleggiaSottoAcqua;
begin
  Assert.IsTrue(TScrollStep.Carries(False, True, 10, 0, 32), 'floating under the water');
  Assert.IsTrue(TScrollStep.Carries(False, False, 10, 0, 32), 'in the water, above the floor');
  Assert.IsFalse(TScrollStep.Carries(False, True, 32, 0, 32), 'at the surface');
end;

procedure TTestThinkersScrollStep.DovrebbeNonTrasportareChiNonHaCollisioni;
begin
  Assert.IsFalse(TScrollStep.Carries(True, False, 0, 0, Low(Integer)), 'on the floor');
  Assert.IsFalse(TScrollStep.Carries(True, True, 10, 0, 32), 'under the water');
end;

procedure TTestThinkersScrollStep.DovrebbeDareAcquaSoloSeIlSettoreDiAltezzaStaSopraIlPavimento;
begin
  Assert.AreEqual(Low(Integer), TScrollStep.WaterHeight(False, 100, 0), 'no height sector');
  Assert.AreEqual(100, TScrollStep.WaterHeight(True, 100, 0), 'above the floor');
  Assert.AreEqual(Low(Integer), TScrollStep.WaterHeight(True, 0, 0), 'at the floor');
  Assert.AreEqual(Low(Integer), TScrollStep.WaterHeight(True, -5, 0), 'below the floor');
end;

procedure TTestThinkersScrollStep.DovrebbeSeguireIlVecchioCodicePerMigliaiaDiTic(ASeed: Integer);
const
  SCROLLER_COUNT = 12;
  TIC_COUNT = 4000;
var
  LState: Cardinal;
  LOld, LNew: array[0..SCROLLER_COUNT - 1] of scroll_t;
  LIndex, LTic: Integer;
  LText: string;
begin
  LState := Cardinal(ASeed);
  BuildWorlds(LState);
  for LIndex := 0 to SCROLLER_COUNT - 1 do
  begin
    FillChar(LOld[LIndex], SizeOf(scroll_t), 0);
    LOld[LIndex]._type := scrolltype_e(TestNumberIn(LState, 0, Ord(High(scrolltype_e))));
    LOld[LIndex].dx := TestNumberIn(LState, -4 * FRACUNIT, 4 * FRACUNIT);
    LOld[LIndex].dy := TestNumberIn(LState, -4 * FRACUNIT, 4 * FRACUNIT);
    if TestNumberIn(LState, 0, 5) = 0 then
    begin
      LOld[LIndex].dx := 0;
      LOld[LIndex].dy := 0;
    end;
    LOld[LIndex].affectee := TestNumberIn(LState, 0, 3);
    LOld[LIndex].control := TestNumberIn(LState, -1, 3);
    if LOld[LIndex].control <> -1 then
      LOld[LIndex].last_height := FOldWorld.sectors[LOld[LIndex].control].floorheight +
        FOldWorld.sectors[LOld[LIndex].control].ceilingheight;
    LOld[LIndex].accel := TestNumberIn(LState, 0, 1);
    LNew[LIndex] := LOld[LIndex];
  end;

  for LTic := 1 to TIC_COUNT do
  begin
    MoveControlSectors(LState);
    for LIndex := 0 to SCROLLER_COUNT - 1 do
    begin
      OldScroll(@FOldWorld, @LOld[LIndex]);
      NewScroll(@FNewWorld, @LNew[LIndex]);
      LText := Format('tic %d scroller %d', [LTic, LIndex]);
      Assert.AreEqual(LOld[LIndex].last_height, LNew[LIndex].last_height, 'last height of ' + LText);
      Assert.AreEqual(LOld[LIndex].vdx, LNew[LIndex].vdx, 'vdx of ' + LText);
      Assert.AreEqual(LOld[LIndex].vdy, LNew[LIndex].vdy, 'vdy of ' + LText);
    end;
    CheckWorlds(Format('tic %d', [LTic]));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersScrollStep);

end.
