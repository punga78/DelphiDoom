{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the drawing routines of the units    }
{  of UFO: Enemy Unknown (UnitSprite::drawRoutine1..3 and 5..9 of OpenXcom)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.UnitSpriteUfo;

interface

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomBattlescape.UnitSpriteBase;

type
  /// <summary>
  ///   The routines of the units that only UFO has: floaters (1), the tanks (2), cyberdiscs and the hallucinoid
  ///   (3 and 22), sectopods and reapers (5), snakemen (6), chryssalids (7), silacoids (8) and celatids (9). As in
  ///   the C++ the frames of the sets are shared and keep the position that a routine gives them: a position that a
  ///   branch does not set is the one of the unit drawn before
  /// </summary>
  TXcomUnitSpriteUfo = class(TXcomUnitSpriteBase)
  protected
    procedure DrawRoutine1;
    procedure DrawRoutine2;
    procedure DrawRoutine3;
    procedure DrawRoutine5;
    procedure DrawRoutine6;
    procedure DrawRoutine7;
    procedure DrawRoutine8;
    procedure DrawRoutine9;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Types;

procedure TXcomUnitSpriteUfo.DrawRoutine1;
const
  STAND = 16;
  WALK = 24;
  DIE = 64;
  // the arms are switched compared with the "normal" sheets
  LARM = 8;
  RARM = 0;
  LARM_2H = 67;
  RARM_2H = 75;
  RARM_SHOOT = 83;
  RARM_1H = 91;
  YOFF_WALK: array[0..7] of Integer = (0, 0, 0, 0, 0, 0, 0, 0);
  OFF_X: array[0..7] of Integer = (8, 10, 7, 4, -9, -11, -7, -3);
  OFF_Y: array[0..7] of Integer = (-6, -3, 0, 2, 0, -4, -7, -9);
  OFF_X2: array[0..7] of Integer = (-8, 3, 7, 13, 6, -3, -5, -13);
  OFF_Y2: array[0..7] of Integer = (1, -4, -1, 0, 3, 3, 5, 0);
  OFF_X3: array[0..7] of Integer = (0, 6, 6, 12, -4, -5, -5, -13);
  OFF_Y3: array[0..7] of Integer = (-4, -4, -1, 0, 5, 0, 1, 0);
var
  LTorso: TXcomSurface;
  LLeftArm: TXcomSurface;
  LRightArm: TXcomSurface;
  LItemR: TXcomSurface;
  LItemL: TXcomSurface;
  LUnitDir: Integer;
  LWalkPhase: Integer;
  LDir: Integer;

  procedure BlitItems;
  begin
    if Assigned(LItemR) then
      Blit(LItemR);
    if Assigned(LItemL) then
      Blit(LItemL);
  end;

begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  LItemR := nil;
  LItemL := nil;
  if FUnit.Status = STATUS_COLLAPSING then
  begin
    LTorso := FUnitSurface.GetFrame(DIE + FUnit.FallingPhase);
    LTorso.X := OFF_X_SPRITE;
    DrawRecolored(LTorso);
    Exit;
  end;
  LUnitDir := FUnit.Direction;
  LWalkPhase := FUnit.WalkingPhase;
  LLeftArm := FUnitSurface.GetFrame(LARM + LUnitDir);
  LRightArm := FUnitSurface.GetFrame(RARM + LUnitDir);
  // when walking torso (fixed sprite) has to be animated up/down
  if FUnit.Status = STATUS_WALKING then
  begin
    // floater only has 5 walk animations instead of 8: the C++ adds walkPhase / 1.6 and the sum becomes an int
    LTorso := FUnitSurface.GetFrame(Trunc(WALK + (5 * LUnitDir) + (LWalkPhase / 1.6)));
    LTorso.Y := YOFF_WALK[LWalkPhase];
  end
  else
    LTorso := FUnitSurface.GetFrame(STAND + LUnitDir);
  SortRifles;
  // holding an item
  if Assigned(FItemR) then
  begin
    // draw handob item
    if (FUnit.Status = STATUS_AIMING) and FItemR.Rules.TwoHanded then
    begin
      LDir := (FUnit.Direction + 2) mod 8;
      LItemR := FItemSurfaceR.GetFrame(FItemR.Rules.HandSprite + LDir);
      LItemR.X := OFF_X[LUnitDir];
      LItemR.Y := OFF_Y[LUnitDir];
    end
    else
    begin
      LItemR := FItemSurfaceR.GetFrame(FItemR.Rules.HandSprite + LUnitDir);
      LItemR.X := 0;
      LItemR.Y := 0;
    end;
    // draw arms holding the item
    if FItemR.Rules.TwoHanded then
    begin
      LLeftArm := FUnitSurface.GetFrame(LARM_2H + LUnitDir);
      if FUnit.Status = STATUS_AIMING then
        LRightArm := FUnitSurface.GetFrame(RARM_SHOOT + LUnitDir)
      else
        LRightArm := FUnitSurface.GetFrame(RARM_2H + LUnitDir);
    end
    else
      LRightArm := FUnitSurface.GetFrame(RARM_1H + LUnitDir);
  end;
  // if we are left handed or dual wielding...
  if Assigned(FItemL) then
  begin
    LLeftArm := FUnitSurface.GetFrame(LARM_2H + LUnitDir);
    LItemL := FItemSurfaceL.GetFrame(FItemL.Rules.HandSprite + LUnitDir);
    if not FItemL.Rules.TwoHanded then
    begin
      LItemL.X := OFF_X2[LUnitDir];
      LItemL.Y := OFF_Y2[LUnitDir];
    end
    else
    begin
      LItemL.X := 0;
      LItemL.Y := 0;
      LRightArm := FUnitSurface.GetFrame(RARM_2H + LUnitDir);
    end;
    if (FUnit.Status = STATUS_AIMING) and FItemL.Rules.TwoHanded then
    begin
      LDir := (LUnitDir + 2) mod 8;
      LItemL := FItemSurfaceL.GetFrame(FItemL.Rules.HandSprite + LDir);
      LItemL.X := OFF_X3[LUnitDir];
      LItemL.Y := OFF_Y3[LUnitDir];
      LRightArm := FUnitSurface.GetFrame(RARM_SHOOT + LUnitDir);
    end;
    if FUnit.Status = STATUS_WALKING then
    begin
      LLeftArm.Y := YOFF_WALK[LWalkPhase];
      LItemL.Y := LItemL.Y + YOFF_WALK[LWalkPhase];
      if FItemL.Rules.TwoHanded then
        LRightArm.Y := YOFF_WALK[LWalkPhase];
    end;
  end;
  // offset everything but legs when kneeled
  if FUnit.Status <> STATUS_WALKING then
  begin
    LLeftArm.Y := 0;
    LRightArm.Y := 0;
    LTorso.Y := 0;
  end;
  // items are calculated for soldier height (22) - some aliens are smaller, so item is drawn lower
  LTorso.X := OFF_X_SPRITE;
  LLeftArm.X := OFF_X_SPRITE;
  LRightArm.X := OFF_X_SPRITE;
  if Assigned(LItemR) then
    LItemR.X := LItemR.X + OFF_X_SPRITE;
  if Assigned(LItemL) then
    LItemL.X := LItemL.X + OFF_X_SPRITE;
  // blit order depends on unit direction
  case LUnitDir of
    0:
      begin
        BlitItems;
        DrawRecolored(LLeftArm);
        DrawRecolored(LTorso);
        DrawRecolored(LRightArm);
      end;
    1, 2:
      begin
        DrawRecolored(LLeftArm);
        DrawRecolored(LTorso);
        DrawRecolored(LRightArm);
        BlitItems;
      end;
    3, 4:
      begin
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
        DrawRecolored(LRightArm);
        BlitItems;
      end;
    5:
      begin
        DrawRecolored(LRightArm);
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
        BlitItems;
      end;
    6:
      begin
        DrawRecolored(LRightArm);
        BlitItems;
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
      end;
    7:
      begin
        DrawRecolored(LRightArm);
        BlitItems;
        DrawRecolored(LLeftArm);
        DrawRecolored(LTorso);
      end;
  end;
  LTorso.X := 0;
  LLeftArm.X := 0;
  LRightArm.X := 0;
  if Assigned(LItemR) then
    LItemR.X := 0;
  if Assigned(LItemL) then
    LItemL.X := 0;
end;

procedure TXcomUnitSpriteUfo.DrawRoutine2;
const
  // hovertank offsets
  OFF_X: array[0..7] of Integer = (-2, -7, -5, 0, 5, 7, 2, 0);
  OFF_Y: array[0..7] of Integer = (-1, -3, -4, -5, -4, -3, -1, -1);
var
  LSurface: TXcomSurface;
  LHoverTank: Integer;
  LTurret: Integer;
  LTurretOffsetX: Integer;
  LTurretOffsetY: Integer;
begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  if FUnit.MovementType = MT_FLY then
    LHoverTank := 32
  else
    LHoverTank := 0;
  LTurret := FUnit.TurretType;
  // draw the animated propulsion below the hwp
  if (FPart > 0) and (LHoverTank <> 0) then
  begin
    LSurface := FUnitSurface.GetFrame(104 + ((FPart - 1) * 8) + FAnimationFrame);
    LSurface.X := OFF_X_SPRITE;
    DrawRecolored(LSurface);
  end;
  // draw the tank itself
  LSurface := FUnitSurface.GetFrame(LHoverTank + (FPart * 8) + FUnit.Direction);
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
  // draw the turret, together with the last part
  if (FPart = 3) and (LTurret <> -1) then
  begin
    LSurface := FUnitSurface.GetFrame(64 + (LTurret * 8) + FUnit.TurretDirection);
    LTurretOffsetX := 0;
    LTurretOffsetY := -4;
    if LHoverTank <> 0 then
    begin
      Inc(LTurretOffsetX, OFF_X[FUnit.Direction]);
      Inc(LTurretOffsetY, OFF_Y[FUnit.Direction]);
    end;
    LSurface.X := LTurretOffsetX + OFF_X_SPRITE;
    LSurface.Y := LTurretOffsetY;
    DrawRecolored(LSurface);
  end;
end;

procedure TXcomUnitSpriteUfo.DrawRoutine3;
var
  LSurface: TXcomSurface;
begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  // draw the animated propulsion below the hwp
  if (FDrawingRoutine = 3) and (FPart > 0) then
  begin
    LSurface := FUnitSurface.GetFrame(32 + ((FPart - 1) * 8) + FAnimationFrame);
    LSurface.X := OFF_X_SPRITE;
    DrawRecolored(LSurface);
  end;
  LSurface := FUnitSurface.GetFrame((FPart * 8) + FUnit.Direction);
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
  // the hallucinoid (routine 22) has the animation above the body
  if (FDrawingRoutine = 22) and (FPart > 0) then
  begin
    LSurface := FUnitSurface.GetFrame(32 + ((FPart - 1) * 8) + FAnimationFrame);
    LSurface.X := OFF_X_SPRITE;
    DrawRecolored(LSurface);
  end;
end;

procedure TXcomUnitSpriteUfo.DrawRoutine5;
var
  LSurface: TXcomSurface;
begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  if FUnit.Status = STATUS_WALKING then
    LSurface := FUnitSurface.GetFrame(32 + (FUnit.Direction * 16) + (FPart * 4) + ((FUnit.WalkingPhase div 2) mod 4))
  else
    LSurface := FUnitSurface.GetFrame((FPart * 8) + FUnit.Direction);
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
end;

procedure TXcomUnitSpriteUfo.DrawRoutine6;
const
  TORSO = 24;
  LEGS_STAND = 16;
  DIE = 96;
  LARM_STAND = 0;
  RARM_STAND = 8;
  RARM_1H = 99;
  LARM_2H = 107;
  RARM_2H = 115;
  RARM_SHOOT = 123;
  LEGS_WALK: array[0..7] of Integer = (32, 40, 48, 56, 64, 72, 80, 88);
  YOFF_WALK: array[0..7] of Integer = (3, 3, 2, 1, 0, 0, 1, 2);
  XOFF_WALK_A: array[0..7] of Integer = (0, 0, 1, 2, 3, 3, 2, 1);
  XOFF_WALK_B: array[0..7] of Integer = (0, 0, -1, -2, -3, -3, -2, -1);
  YOFF_STAND: array[0..7] of Integer = (2, 1, 1, 0, 0, 0, 0, 0);
  OFF_X: array[0..7] of Integer = (8, 10, 5, 2, -8, -10, -5, -2);
  OFF_Y: array[0..7] of Integer = (-6, -3, 0, 0, 2, -3, -7, -9);
  OFF_X2: array[0..7] of Integer = (-8, 2, 7, 13, 7, 0, -3, -15);
  OFF_Y2: array[0..7] of Integer = (1, -4, -2, 0, 3, 3, 5, 0);
  OFF_X3: array[0..7] of Integer = (0, 6, 6, 12, -4, -5, -5, -13);
  OFF_Y3: array[0..7] of Integer = (-4, -4, -1, 0, 5, 0, 1, 0);
var
  LTorso: TXcomSurface;
  LLegs: TXcomSurface;
  LLeftArm: TXcomSurface;
  LRightArm: TXcomSurface;
  LItemR: TXcomSurface;
  LItemL: TXcomSurface;
  LUnitDir: Integer;
  LWalkPhase: Integer;
  LXoffWalk: Integer;
  LDir: Integer;

  procedure BlitR;
  begin
    if Assigned(LItemR) then
      Blit(LItemR);
  end;

  procedure BlitL;
  begin
    if Assigned(LItemL) then
      Blit(LItemL);
  end;

begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  LItemR := nil;
  LItemL := nil;
  if FUnit.Status = STATUS_COLLAPSING then
  begin
    LTorso := FUnitSurface.GetFrame(DIE + FUnit.FallingPhase);
    LTorso.X := OFF_X_SPRITE;
    DrawRecolored(LTorso);
    Exit;
  end;
  LUnitDir := FUnit.Direction;
  LWalkPhase := FUnit.WalkingPhase;
  LTorso := FUnitSurface.GetFrame(TORSO + LUnitDir);
  LLeftArm := FUnitSurface.GetFrame(LARM_STAND + LUnitDir);
  LRightArm := FUnitSurface.GetFrame(RARM_STAND + LUnitDir);
  // when walking, torso(fixed sprite) has to be animated up/down
  if FUnit.Status = STATUS_WALKING then
  begin
    LXoffWalk := 0;
    if LUnitDir < 3 then
      LXoffWalk := XOFF_WALK_A[LWalkPhase];
    if (LUnitDir < 7) and (LUnitDir > 3) then
      LXoffWalk := XOFF_WALK_B[LWalkPhase];
    LTorso.Y := YOFF_WALK[LWalkPhase];
    LTorso.X := LXoffWalk;
    LLegs := FUnitSurface.GetFrame(LEGS_WALK[LUnitDir] + LWalkPhase);
    LRightArm.Y := YOFF_WALK[LWalkPhase];
    LLeftArm.Y := YOFF_WALK[LWalkPhase];
    LRightArm.X := LXoffWalk;
    LLeftArm.X := LXoffWalk;
  end
  else
    LLegs := FUnitSurface.GetFrame(LEGS_STAND + LUnitDir);
  SortRifles;
  // holding an item
  if Assigned(FItemR) then
  begin
    // draw handob item
    if (FUnit.Status = STATUS_AIMING) and FItemR.Rules.TwoHanded then
    begin
      LDir := (LUnitDir + 2) mod 8;
      LItemR := FItemSurfaceR.GetFrame(FItemR.Rules.HandSprite + LDir);
      LItemR.X := OFF_X[LUnitDir];
      LItemR.Y := OFF_Y[LUnitDir];
    end
    else
    begin
      LItemR := FItemSurfaceR.GetFrame(FItemR.Rules.HandSprite + LUnitDir);
      LItemR.X := 0;
      LItemR.Y := 0;
      if not FItemR.Rules.TwoHanded then
        LItemR.Y := YOFF_STAND[LUnitDir];
    end;
    // draw arms holding the item
    if FItemR.Rules.TwoHanded then
    begin
      LLeftArm := FUnitSurface.GetFrame(LARM_2H + LUnitDir);
      if FUnit.Status = STATUS_AIMING then
        LRightArm := FUnitSurface.GetFrame(RARM_SHOOT + LUnitDir)
      else
        LRightArm := FUnitSurface.GetFrame(RARM_2H + LUnitDir);
    end
    else
      LRightArm := FUnitSurface.GetFrame(RARM_1H + LUnitDir);
    // the fixed arm(s) have to be animated up/down when walking
    if FUnit.Status = STATUS_WALKING then
    begin
      LItemR.Y := YOFF_WALK[LWalkPhase];
      LRightArm.Y := YOFF_WALK[LWalkPhase];
      if FItemR.Rules.TwoHanded then
        LLeftArm.Y := YOFF_WALK[LWalkPhase];
    end;
  end;
  // if we are left handed or dual wielding...
  if Assigned(FItemL) then
  begin
    LLeftArm := FUnitSurface.GetFrame(LARM_2H + LUnitDir);
    LItemL := FItemSurfaceL.GetFrame(FItemL.Rules.HandSprite + LUnitDir);
    if not FItemL.Rules.TwoHanded then
    begin
      LItemL.X := OFF_X2[LUnitDir];
      LItemL.Y := OFF_Y2[LUnitDir];
    end
    else
    begin
      // the C++ tests "not two handed" again here, inside the two handed branch: it never sets the stand offset
      LItemL.X := 0;
      LItemL.Y := 0;
      LRightArm := FUnitSurface.GetFrame(RARM_2H + LUnitDir);
    end;
    if (FUnit.Status = STATUS_AIMING) and FItemL.Rules.TwoHanded then
    begin
      LDir := (LUnitDir + 2) mod 8;
      LItemL := FItemSurfaceL.GetFrame(FItemL.Rules.HandSprite + LDir);
      LItemL.X := OFF_X3[LUnitDir];
      LItemL.Y := OFF_Y3[LUnitDir];
      LRightArm := FUnitSurface.GetFrame(RARM_SHOOT + LUnitDir);
    end;
    if FUnit.Status = STATUS_WALKING then
    begin
      LLeftArm.Y := YOFF_WALK[LWalkPhase];
      LItemL.Y := OFF_Y2[LUnitDir] + YOFF_WALK[LWalkPhase];
      if FItemL.Rules.TwoHanded then
        LRightArm.Y := YOFF_WALK[LWalkPhase];
    end;
  end;
  // offset everything but legs when kneeled
  if FUnit.Status <> STATUS_WALKING then
  begin
    LLeftArm.Y := 0;
    LRightArm.Y := 0;
    LTorso.Y := 0;
  end;
  LTorso.X := OFF_X_SPRITE;
  LLegs.X := OFF_X_SPRITE;
  LLeftArm.X := OFF_X_SPRITE;
  LRightArm.X := OFF_X_SPRITE;
  if Assigned(LItemR) then
    LItemR.X := LItemR.X + OFF_X_SPRITE;
  if Assigned(LItemL) then
    LItemL.X := LItemL.X + OFF_X_SPRITE;
  // blit order depends on unit direction
  case LUnitDir of
    0:
      begin
        BlitR;
        BlitL;
        DrawRecolored(LLeftArm);
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
        DrawRecolored(LRightArm);
      end;
    1:
      begin
        DrawRecolored(LLeftArm);
        DrawRecolored(LLegs);
        BlitL;
        DrawRecolored(LTorso);
        BlitR;
        DrawRecolored(LRightArm);
      end;
    2:
      begin
        DrawRecolored(LLeftArm);
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
        DrawRecolored(LRightArm);
        BlitR;
        BlitL;
      end;
    3:
      begin
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
        DrawRecolored(LRightArm);
        BlitR;
        BlitL;
      end;
    4, 5:
      begin
        DrawRecolored(LRightArm);
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
        BlitR;
        BlitL;
      end;
    6:
      begin
        DrawRecolored(LRightArm);
        DrawRecolored(LLegs);
        BlitR;
        BlitL;
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
      end;
    7:
      begin
        BlitR;
        BlitL;
        DrawRecolored(LLeftArm);
        DrawRecolored(LRightArm);
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
      end;
  end;
  // the C++ puts the body back at 0 and leaves the objects where they are ("getX() + 0")
  LTorso.X := 0;
  LLegs.X := 0;
  LLeftArm.X := 0;
  LRightArm.X := 0;
end;

procedure TXcomUnitSpriteUfo.DrawRoutine7;
const
  TORSO = 24;
  LEGS_STAND = 16;
  DIE = 224;
  LARM_STAND = 0;
  RARM_STAND = 8;
  LEGS_WALK = 48;
  LARM_WALK = 32;
  RARM_WALK = 40;
  // the walk frames of a direction follow those of the direction before, 24 frames apart
  WALK_STEP = 24;
  YOFF_WALK: array[0..7] of Integer = (1, 0, -1, 0, 1, 0, -1, 0);
var
  LTorso: TXcomSurface;
  LLegs: TXcomSurface;
  LLeftArm: TXcomSurface;
  LRightArm: TXcomSurface;
  LUnitDir: Integer;
  LWalkPhase: Integer;
begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  if FUnit.Status = STATUS_COLLAPSING then
  begin
    LTorso := FUnitSurface.GetFrame(DIE + FUnit.FallingPhase);
    LTorso.X := OFF_X_SPRITE;
    DrawRecolored(LTorso);
    Exit;
  end;
  LUnitDir := FUnit.Direction;
  LWalkPhase := FUnit.WalkingPhase;
  LTorso := FUnitSurface.GetFrame(TORSO + LUnitDir);
  // when walking, torso(fixed sprite) has to be animated up/down
  if FUnit.Status = STATUS_WALKING then
  begin
    LTorso.Y := YOFF_WALK[LWalkPhase];
    LLegs := FUnitSurface.GetFrame(LEGS_WALK + WALK_STEP * LUnitDir + LWalkPhase);
    LLeftArm := FUnitSurface.GetFrame(LARM_WALK + WALK_STEP * LUnitDir + LWalkPhase);
    LRightArm := FUnitSurface.GetFrame(RARM_WALK + WALK_STEP * LUnitDir + LWalkPhase);
  end
  else
  begin
    LLegs := FUnitSurface.GetFrame(LEGS_STAND + LUnitDir);
    LLeftArm := FUnitSurface.GetFrame(LARM_STAND + LUnitDir);
    LRightArm := FUnitSurface.GetFrame(RARM_STAND + LUnitDir);
    LLeftArm.Y := 0;
    LRightArm.Y := 0;
    LTorso.Y := 0;
  end;
  LTorso.X := OFF_X_SPRITE;
  LLegs.X := OFF_X_SPRITE;
  LLeftArm.X := OFF_X_SPRITE;
  LRightArm.X := OFF_X_SPRITE;
  // blit order depends on unit direction
  case LUnitDir of
    0, 1, 2:
      begin
        DrawRecolored(LLeftArm);
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
        DrawRecolored(LRightArm);
      end;
    3:
      begin
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
        DrawRecolored(LRightArm);
      end;
    4, 5, 6:
      begin
        DrawRecolored(LRightArm);
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
        DrawRecolored(LLeftArm);
      end;
    7:
      begin
        DrawRecolored(LLeftArm);
        DrawRecolored(LRightArm);
        DrawRecolored(LLegs);
        DrawRecolored(LTorso);
      end;
  end;
end;

procedure TXcomUnitSpriteUfo.DrawRoutine8;
const
  BODY = 0;
  AIM = 5;
  DIE = 6;
  PULSATE: array[0..7] of Integer = (0, 1, 2, 3, 4, 3, 2, 1);
var
  LLegs: TXcomSurface;
begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  LLegs := FUnitSurface.GetFrame(BODY + PULSATE[FAnimationFrame]);
  if FUnit.Status = STATUS_COLLAPSING then
    LLegs := FUnitSurface.GetFrame(DIE + FUnit.FallingPhase)
  else if FUnit.Status = STATUS_AIMING then
    LLegs := FUnitSurface.GetFrame(AIM);
  LLegs.X := OFF_X_SPRITE;
  DrawRecolored(LLegs);
end;

procedure TXcomUnitSpriteUfo.DrawRoutine9;
const
  BODY = 0;
  DIE = 25;
var
  LTorso: TXcomSurface;
begin
  if FUnit.IsOut then
    // unit is drawn as an item
    Exit;
  LTorso := FUnitSurface.GetFrame(BODY + FAnimationFrame);
  if FUnit.Status = STATUS_COLLAPSING then
    LTorso := FUnitSurface.GetFrame(DIE + FUnit.FallingPhase);
  LTorso.X := OFF_X_SPRITE;
  DrawRecolored(LTorso);
end;

end.
