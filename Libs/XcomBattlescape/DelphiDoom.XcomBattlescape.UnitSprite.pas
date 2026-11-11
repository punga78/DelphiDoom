{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - the sprite of a unit          }
{  (UnitSprite: drawing routines 0, 4, 11, 12, 19, 20 and 21, the ones the      }
{  units of TFTD use)                                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.UnitSprite;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattlescape.UnitSpriteUfo;

type
  EXcomBattlescapeDrawException = class(Exception);

  /// <summary>
  ///   Draws a unit on a surface of two tiles of width: the torso, legs, arms and the objects in the hands in the
  ///   order that depends on the direction, or the one sprite of the aliens. The frames of the sets are shared and
  ///   the C++ moves them (setX, setY) before it blits them: so does this class, and the position they keep
  ///   afterwards is part of what is drawn next. The routines of the soldiers and of TFTD are here, those that only
  ///   UFO has (1 to 3, 5 to 9, 22) in TXcomUnitSpriteUfo, the state in TXcomUnitSpriteBase
  /// </summary>
  TXcomUnitSprite = class(TXcomUnitSpriteUfo)
  strict private
    procedure DrawRoutine0;
    procedure DrawRoutine4;
    procedure DrawRoutine11;
    procedure DrawRoutine12;
    procedure DrawRoutine19;
    procedure DrawRoutine20;
    procedure DrawRoutine21;
  public
    /// <summary>draw: the unit on ATarget (a surface of 64 x 40 that the caller has cleared)</summary>
    procedure Draw(const ATarget: TXcomSurface);
  end;

implementation

uses
  DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Types;

const
  // ForcedTorso: TORSO_USE_GENDER = 0 (TXcomArmor), then these
  TORSO_ALWAYS_MALE = 1;
  TORSO_ALWAYS_FEMALE = 2;

procedure TXcomUnitSprite.Draw(const ATarget: TXcomSurface);
begin
  FTarget := ATarget;
  case FDrawingRoutine of
    0, 10, 13, 14, 15: DrawRoutine0;
    1: DrawRoutine1;
    2: DrawRoutine2;
    3, 22: DrawRoutine3;
    5: DrawRoutine5;
    6: DrawRoutine6;
    7: DrawRoutine7;
    8: DrawRoutine8;
    9: DrawRoutine9;
    4, 17, 18: DrawRoutine4;
    11: DrawRoutine11;
    12, 16: DrawRoutine12;
    19: DrawRoutine19;
    20: DrawRoutine20;
    21: DrawRoutine21;
  else
    raise EXcomBattlescapeDrawException.CreateFmt('The drawing routine %d is not ported', [FDrawingRoutine]);
  end;
end;

procedure TXcomUnitSprite.DrawRoutine0;
const
  LEGS_STAND = 16;
  LEGS_KNEEL = 24;
  LARM_STAND = 0;
  RARM_STAND = 8;
  YOFF_WALK: array[0..7] of Integer = (1, 0, -1, 0, 1, 0, -1, 0);
  MUTON_YOFF_WALK: array[0..7] of Integer = (1, 1, 0, 0, 1, 1, 0, 0);
  AQUATOID_YOFF_WALK: array[0..7] of Integer = (1, 0, 0, 1, 2, 1, 0, 0);
  OFF_X: array[0..7] of Integer = (8, 10, 7, 4, -9, -11, -7, -3);
  OFF_Y: array[0..7] of Integer = (-6, -3, 0, 2, 0, -4, -7, -9);
  OFF_X2: array[0..7] of Integer = (-8, 3, 5, 12, 6, -1, -5, -13);
  OFF_Y2: array[0..7] of Integer = (1, -4, -2, 0, 3, 3, 5, 0);
  OFF_X3: array[0..7] of Integer = (0, 0, 2, 2, 0, 0, 0, 0);
  OFF_Y3: array[0..7] of Integer = (-3, -3, -1, -1, -1, -3, -3, -2);
  OFF_X4: array[0..7] of Integer = (-8, 2, 7, 14, 7, -2, -4, -8);
  OFF_Y4: array[0..7] of Integer = (-3, -3, -1, 0, 3, 3, 0, 1);
  OFF_X5: array[0..7] of Integer = (-1, 1, 1, 2, 0, -1, 0, 0);
  OFF_Y5: array[0..7] of Integer = (1, -1, -1, -1, -1, -1, -3, 0);
  OFF_X6: array[0..7] of Integer = (0, 6, 6, 12, -4, -5, -5, -13);
  OFF_Y6: array[0..7] of Integer = (-4, -4, -1, 0, 5, 0, 1, 0);
  OFF_X7: array[0..7] of Integer = (0, 6, 8, 12, 2, -5, -5, -13);
  OFF_Y7: array[0..7] of Integer = (-4, -6, -1, 0, 3, 0, 1, 0);
  OFF_Y_KNEEL = 4;
  SOLDIER_HEIGHT = 22;
var
  LTorso: TXcomSurface;
  LLegs: TXcomSurface;
  LLeftArm: TXcomSurface;
  LRightArm: TXcomSurface;
  LItemR: TXcomSurface;
  LItemL: TXcomSurface;
  LMaleTorso: Integer;
  LFemaleTorso: Integer;
  LDie: Integer;
  LRarm1H: Integer;
  LLarm2H: Integer;
  LRarm2H: Integer;
  LRarmShoot: Integer;
  LLegsFloat: Integer;
  LTorsoHandsWeaponY: Integer;
  LDir: Integer;
  LWalkPhase: Integer;
  LUnitDir: Integer;
  LTwoHanded: Boolean;
  LNotAiming: Boolean;

  function Legs(AIndex: Integer): Integer;
  begin
    Result := 56 + 24 * AIndex;
  end;

  function LArm(AIndex: Integer): Integer;
  begin
    Result := 40 + 24 * AIndex;
  end;

  function RArm(AIndex: Integer): Integer;
  begin
    Result := 48 + 24 * AIndex;
  end;

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
  LTorso := nil;
  LItemR := nil;
  LItemL := nil;
  LTorsoHandsWeaponY := 0;
  if FDrawingRoutine <= 10 then
  begin
    LDie := 264; // ufo:eu death frame
    LMaleTorso := 32;
    LFemaleTorso := 267;
    LRarm1H := 232;
    LLarm2H := 240;
    LRarm2H := 248;
    LRarmShoot := 256;
    LLegsFloat := 275;
  end
  else if FDrawingRoutine = 13 then
  begin
    if FHelmet then
    begin
      LDie := 259; // aquanaut underwater death frame
      LMaleTorso := 32; // aquanaut underwater ion armour torso
      if FUnit.Armor.ForcedTorso = TXcomArmor.TORSO_USE_GENDER then
        LFemaleTorso := 32 // aquanaut underwater plastic aqua armour torso
      else
        LFemaleTorso := 286; // aquanaut underwater magnetic ion armour torso
      LRarm1H := 248;
      LLarm2H := 232;
      LRarm2H := 240;
      LRarmShoot := 240;
      LLegsFloat := 294;
    end
    else
    begin
      LDie := 256; // aquanaut land death frame
      LMaleTorso := 270; // aquanaut land torso
      LFemaleTorso := 262;
      LRarm1H := 248;
      LLarm2H := 232;
      LRarm2H := 240;
      LRarmShoot := 240;
      LLegsFloat := 294;
    end;
  end
  else
  begin
    LDie := 256; // tftd unit death frame
    LMaleTorso := 32; // tftd unit torso
    LFemaleTorso := 262;
    LRarm1H := 248;
    LLarm2H := 232;
    LRarm2H := 240;
    LRarmShoot := 240;
    LLegsFloat := 294;
  end;
  LUnitDir := FUnit.Direction;
  LWalkPhase := FUnit.WalkingPhase;
  if FUnit.Status = STATUS_COLLAPSING then
  begin
    LTorso := FUnitSurface.GetFrame(LDie + FUnit.FallingPhase);
    LTorso.X := OFF_X_SPRITE;
    DrawRecolored(LTorso);
    Exit;
  end;
  if (FDrawingRoutine = 0) or FHelmet then
  begin
    if ((FUnit.Gender = GENDER_FEMALE) and (FUnit.Armor.ForcedTorso <> TORSO_ALWAYS_MALE)) or
      (FUnit.Armor.ForcedTorso = TORSO_ALWAYS_FEMALE) then
      LTorso := FUnitSurface.GetFrame(LFemaleTorso + LUnitDir)
    else
      LTorso := FUnitSurface.GetFrame(LMaleTorso + LUnitDir);
  end
  else if FUnit.Gender = GENDER_FEMALE then
    LTorso := FUnitSurface.GetFrame(LFemaleTorso + LUnitDir)
  else
    LTorso := FUnitSurface.GetFrame(LMaleTorso + LUnitDir);
  // when walking, torso (fixed sprite) has to be animated up/down
  if FUnit.Status = STATUS_WALKING then
  begin
    if FDrawingRoutine = 10 then
      LTorsoHandsWeaponY := MUTON_YOFF_WALK[LWalkPhase]
    else if (FDrawingRoutine = 13) or (FDrawingRoutine = 14) then
      LTorsoHandsWeaponY := YOFF_WALK[LWalkPhase] + 1
    else if FDrawingRoutine = 15 then
      LTorsoHandsWeaponY := AQUATOID_YOFF_WALK[LWalkPhase]
    else
      LTorsoHandsWeaponY := YOFF_WALK[LWalkPhase];
    LTorso.Y := LTorsoHandsWeaponY;
    LLegs := FUnitSurface.GetFrame(Legs(LUnitDir) + LWalkPhase);
    LLeftArm := FUnitSurface.GetFrame(LArm(LUnitDir) + LWalkPhase);
    LRightArm := FUnitSurface.GetFrame(RArm(LUnitDir) + LWalkPhase);
    if (FDrawingRoutine = 10) and (LUnitDir = 3) then
      LLeftArm.Y := -1;
  end
  else
  begin
    if FUnit.IsKneeled then
      LLegs := FUnitSurface.GetFrame(LEGS_KNEEL + LUnitDir)
    else if FUnit.IsFloating and (FUnit.MovementType = MT_FLY) then
      LLegs := FUnitSurface.GetFrame(LLegsFloat + LUnitDir)
    else
      LLegs := FUnitSurface.GetFrame(LEGS_STAND + LUnitDir);
    LLeftArm := FUnitSurface.GetFrame(LARM_STAND + LUnitDir);
    LRightArm := FUnitSurface.GetFrame(RARM_STAND + LUnitDir);
  end;
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
      if FDrawingRoutine = 10 then
      begin
        if FItemR.Rules.TwoHanded then
        begin
          LItemR.X := OFF_X3[LUnitDir];
          LItemR.Y := OFF_Y3[LUnitDir];
        end
        else
        begin
          LItemR.X := OFF_X5[LUnitDir];
          LItemR.Y := OFF_Y5[LUnitDir];
        end;
      end
      else
      begin
        LItemR.X := 0;
        LItemR.Y := 0;
      end;
    end;
    // draw arms holding the item
    if FItemR.Rules.TwoHanded then
    begin
      LLeftArm := FUnitSurface.GetFrame(LLarm2H + LUnitDir);
      if FUnit.Status = STATUS_AIMING then
        LRightArm := FUnitSurface.GetFrame(LRarmShoot + LUnitDir)
      else
        LRightArm := FUnitSurface.GetFrame(LRarm2H + LUnitDir);
    end
    else if FDrawingRoutine = 10 then
      LRightArm := FUnitSurface.GetFrame(LRarm2H + LUnitDir)
    else
      LRightArm := FUnitSurface.GetFrame(LRarm1H + LUnitDir);
    // the fixed arm(s) have to be animated up/down when walking
    if FUnit.Status = STATUS_WALKING then
    begin
      LItemR.Y := LItemR.Y + LTorsoHandsWeaponY;
      LRightArm.Y := LTorsoHandsWeaponY;
      if FItemR.Rules.TwoHanded then
        LLeftArm.Y := LTorsoHandsWeaponY;
    end;
  end;
  // if we are left handed or dual wielding...
  if Assigned(FItemL) then
  begin
    LLeftArm := FUnitSurface.GetFrame(LLarm2H + LUnitDir);
    LItemL := FItemSurfaceL.GetFrame(FItemL.Rules.HandSprite + LUnitDir);
    if not FItemL.Rules.TwoHanded then
    begin
      if FDrawingRoutine = 10 then
      begin
        LItemL.X := OFF_X4[LUnitDir];
        LItemL.Y := OFF_Y4[LUnitDir];
      end
      else
      begin
        LItemL.X := OFF_X2[LUnitDir];
        LItemL.Y := OFF_Y2[LUnitDir];
      end;
    end
    else
    begin
      LItemL.X := 0;
      LItemL.Y := 0;
      LRightArm := FUnitSurface.GetFrame(LRarm2H + LUnitDir);
    end;
    if (FUnit.Status = STATUS_AIMING) and FItemL.Rules.TwoHanded then
    begin
      LDir := (LUnitDir + 2) mod 8;
      LItemL := FItemSurfaceL.GetFrame(FItemL.Rules.HandSprite + LDir);
      if FDrawingRoutine = 10 then
      begin
        LItemL.X := OFF_X7[LUnitDir];
        LItemL.Y := OFF_Y7[LUnitDir];
      end
      else
      begin
        LItemL.X := OFF_X6[LUnitDir];
        LItemL.Y := OFF_Y6[LUnitDir];
      end;
      LRightArm := FUnitSurface.GetFrame(LRarmShoot + LUnitDir);
    end;
    if FUnit.Status = STATUS_WALKING then
    begin
      LItemL.Y := LItemL.Y + LTorsoHandsWeaponY;
      LLeftArm.Y := LTorsoHandsWeaponY;
      if FItemL.Rules.TwoHanded then
        LRightArm.Y := LTorsoHandsWeaponY;
    end;
  end;
  // offset everything but legs when kneeled
  if FUnit.IsKneeled then
  begin
    if FDrawingRoutine = 13 then
    begin
      // tftd torsos are stubby
      LLeftArm.Y := OFF_Y_KNEEL + 1;
      LRightArm.Y := OFF_Y_KNEEL + 1;
      LTorso.Y := OFF_Y_KNEEL + 1;
      if Assigned(LItemR) then
        LItemR.Y := LItemR.Y + OFF_Y_KNEEL + 1;
      if Assigned(LItemL) then
        LItemL.Y := LItemL.Y + OFF_Y_KNEEL + 1;
    end
    else
    begin
      LLeftArm.Y := OFF_Y_KNEEL;
      LRightArm.Y := OFF_Y_KNEEL;
      LTorso.Y := OFF_Y_KNEEL;
      if Assigned(LItemR) then
        LItemR.Y := LItemR.Y + OFF_Y_KNEEL;
      if Assigned(LItemL) then
        LItemL.Y := LItemL.Y + OFF_Y_KNEEL;
    end;
  end
  else if FUnit.Status <> STATUS_WALKING then
  begin
    LLeftArm.Y := 0;
    LRightArm.Y := 0;
    LTorso.Y := 0;
  end;
  // items are calculated for soldier height (22) - some aliens are smaller, so item is drawn lower
  if Assigned(LItemR) then
    LItemR.Y := LItemR.Y + (SOLDIER_HEIGHT - FUnit.StandHeight);
  if Assigned(LItemL) then
    LItemL.Y := LItemL.Y + (SOLDIER_HEIGHT - FUnit.StandHeight);
  // offset everything to the left by 16 pixels: the sprites are double wide, to accommodate weapons in hand
  LTorso.X := OFF_X_SPRITE;
  LLegs.X := OFF_X_SPRITE;
  LLeftArm.X := OFF_X_SPRITE;
  LRightArm.X := OFF_X_SPRITE;
  if Assigned(LItemR) then
    LItemR.X := LItemR.X + OFF_X_SPRITE;
  if Assigned(LItemL) then
    LItemL.X := LItemL.X + OFF_X_SPRITE;
  // fix the errant muton arm
  if (not Assigned(FItemR)) and (FDrawingRoutine = 10) and (FUnit.Status = STATUS_WALKING) and (LUnitDir = 2) then
    LRightArm.X := 10;
  LNotAiming := FUnit.Status <> STATUS_AIMING;
  LTwoHanded := (Assigned(FItemR) and FItemR.Rules.TwoHanded) or (Assigned(FItemL) and FItemL.Rules.TwoHanded);
  // blit order depends on unit direction, and whether we are holding a 2 handed weapon
  case LUnitDir of
    0:
      begin
        BlitR; BlitL; DrawRecolored(LLeftArm); DrawRecolored(LLegs); DrawRecolored(LTorso); DrawRecolored(LRightArm);
      end;
    1:
      begin
        DrawRecolored(LLeftArm); DrawRecolored(LLegs); BlitL; DrawRecolored(LTorso); BlitR; DrawRecolored(LRightArm);
      end;
    2:
      begin
        DrawRecolored(LLeftArm); DrawRecolored(LLegs); DrawRecolored(LTorso); BlitL; BlitR; DrawRecolored(LRightArm);
      end;
    3:
      if LNotAiming and LTwoHanded then
      begin
        DrawRecolored(LLegs); DrawRecolored(LTorso); DrawRecolored(LLeftArm); BlitR; BlitL; DrawRecolored(LRightArm);
      end
      else
      begin
        DrawRecolored(LLegs); DrawRecolored(LTorso); DrawRecolored(LLeftArm); DrawRecolored(LRightArm); BlitR; BlitL;
      end;
    4:
      begin
        DrawRecolored(LLegs); DrawRecolored(LRightArm); DrawRecolored(LTorso); DrawRecolored(LLeftArm); BlitR; BlitL;
      end;
    5:
      if LNotAiming and LTwoHanded then
      begin
        DrawRecolored(LRightArm); DrawRecolored(LLegs); DrawRecolored(LTorso); DrawRecolored(LLeftArm); BlitR; BlitL;
      end
      else
      begin
        DrawRecolored(LRightArm); DrawRecolored(LLegs); BlitR; BlitL; DrawRecolored(LTorso); DrawRecolored(LLeftArm);
      end;
    6:
      begin
        DrawRecolored(LRightArm); BlitR; BlitL; DrawRecolored(LLegs); DrawRecolored(LTorso); DrawRecolored(LLeftArm);
      end;
    7:
      if LNotAiming and LTwoHanded then
      begin
        DrawRecolored(LRightArm); BlitR; BlitL; DrawRecolored(LLeftArm); DrawRecolored(LLegs); DrawRecolored(LTorso);
      end
      else
      begin
        BlitR; BlitL; DrawRecolored(LLeftArm); DrawRecolored(LRightArm); DrawRecolored(LLegs); DrawRecolored(LTorso);
      end;
  end;
  LTorso.X := 0;
  LLegs.X := 0;
  LLeftArm.X := 0;
  LRightArm.X := 0;
  if Assigned(LItemR) then
    LItemR.X := 0;
  if Assigned(LItemL) then
    LItemL.X := 0;
end;

procedure TXcomUnitSprite.DrawRoutine4;
const
  OFF_X: array[0..7] of Integer = (8, 10, 7, 4, -9, -11, -7, -3);
  OFF_Y: array[0..7] of Integer = (-6, -3, 0, 2, 0, -4, -7, -9);
  OFF_X2: array[0..7] of Integer = (-8, 3, 5, 12, 6, -1, -5, -13);
  OFF_Y2: array[0..7] of Integer = (1, -4, -2, 0, 3, 3, 5, 0);
  OFF_X3: array[0..7] of Integer = (0, 6, 6, 12, -4, -5, -5, -13);
  OFF_Y3: array[0..7] of Integer = (-4, -4, -1, 0, 5, 0, 1, 0);
  STAND_CONVERT: array[0..7] of Integer = (3, 2, 1, 0, 7, 6, 5, 4);
var
  LSurface: TXcomSurface;
  LItemR: TXcomSurface;
  LItemL: TXcomSurface;
  LStand: Integer;
  LWalk: Integer;
  LDie: Integer;
  LUnitDir: Integer;
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
    Exit;
  LItemR := nil;
  LItemL := nil;
  LStand := 0;
  LWalk := 8;
  LDie := 72;
  if FDrawingRoutine = 17 then
  begin
    // tftd civilian - first set
    LStand := 64;
    LWalk := 0;
  end
  else if FDrawingRoutine = 18 then
  begin
    // tftd civilian - second set
    LStand := 140;
    LWalk := 76;
    LDie := 148;
  end;
  LUnitDir := FUnit.Direction;
  if FUnit.Status = STATUS_COLLAPSING then
  begin
    LSurface := FUnitSurface.GetFrame(LDie + FUnit.FallingPhase);
    LSurface.X := OFF_X_SPRITE;
    DrawRecolored(LSurface);
    Exit;
  end
  else if FUnit.Status = STATUS_WALKING then
    LSurface := FUnitSurface.GetFrame(LWalk + (8 * LUnitDir) + FUnit.WalkingPhase)
  else if FDrawingRoutine <> 17 then
    LSurface := FUnitSurface.GetFrame(LStand + LUnitDir)
  else
    LSurface := FUnitSurface.GetFrame(LStand + STAND_CONVERT[LUnitDir]);
  SortRifles;
  if Assigned(FItemR) and (not FItemR.Rules.FixedWeapon) then
  begin
    // draw handob item
    if (FUnit.Status = STATUS_AIMING) and FItemR.Rules.TwoHanded then
    begin
      LDir := (LUnitDir + 2) mod 8;
      LItemR := FItemSurfaceR.GetFrame(FItemR.Rules.HandSprite + LDir);
      LItemR.X := OFF_X[LUnitDir];
      LItemR.Y := OFF_Y[LUnitDir];
    end
    else if FItemR.Slot.Id = 'STR_RIGHT_HAND' then
    begin
      LItemR := FItemSurfaceR.GetFrame(FItemR.Rules.HandSprite + LUnitDir);
      LItemR.X := 0;
      LItemR.Y := 0;
    end
    else
    begin
      LItemR := FItemSurfaceR.GetFrame(FItemR.Rules.HandSprite + LUnitDir);
      LItemR.X := OFF_X2[LUnitDir];
      LItemR.Y := OFF_Y2[LUnitDir];
    end;
  end;
  // if we are dual wielding...
  if Assigned(FItemL) and (not FItemL.Rules.FixedWeapon) then
  begin
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
    end;
    if (FUnit.Status = STATUS_AIMING) and FItemL.Rules.TwoHanded then
    begin
      LDir := (LUnitDir + 2) mod 8;
      LItemL := FItemSurfaceL.GetFrame(FItemL.Rules.HandSprite + LDir);
      LItemL.X := OFF_X3[LUnitDir];
      LItemL.Y := OFF_Y3[LUnitDir];
    end;
  end;
  // offset everything to the right by 16 pixels: the sprites are double wide, to accommodate weapons in hand
  LSurface.X := OFF_X_SPRITE;
  if Assigned(LItemR) then
    LItemR.X := LItemR.X + OFF_X_SPRITE;
  if Assigned(LItemL) then
    LItemL.X := LItemL.X + OFF_X_SPRITE;
  case LUnitDir of
    0: begin BlitL; BlitR; DrawRecolored(LSurface); end;
    1: begin BlitL; DrawRecolored(LSurface); BlitR; end;
    2: begin DrawRecolored(LSurface); BlitL; BlitR; end;
    3, 4: begin DrawRecolored(LSurface); BlitR; BlitL; end;
    5, 6: begin BlitR; DrawRecolored(LSurface); BlitL; end;
    7: begin BlitR; BlitL; DrawRecolored(LSurface); end;
  end;
  LSurface.X := 0;
  if Assigned(LItemR) then
    LItemR.X := 0;
  if Assigned(LItemL) then
    LItemL.X := 0;
end;

procedure TXcomUnitSprite.DrawRoutine11;
const
  OFF_TURRET_X: array[0..7] of Integer = (-2, -6, -5, 0, 5, 6, 2, 0);
  OFF_TURRET_Y_ABOVE: array[0..7] of Integer = (5, 3, 0, 0, 0, 3, 5, 4);
  OFF_TURRET_Y_BELOW: array[0..7] of Integer = (-11, -13, -16, -16, -16, -13, -11, -12);
var
  LBody: Integer;
  LAnimFrame: Integer;
  LSurface: TXcomSurface;
  LTurret: Integer;
begin
  if FUnit.IsOut then
    Exit;
  LBody := 0;
  LAnimFrame := FUnit.WalkingPhase mod 4;
  if FUnit.MovementType = MT_FLY then
  begin
    LBody := 128;
    LAnimFrame := FAnimationFrame mod 4;
  end;
  LSurface := FUnitSurface.GetFrame(LBody + (FPart * 4) + 16 * FUnit.Direction + LAnimFrame);
  LSurface.Y := 4;
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
  LTurret := FUnit.TurretType;
  // draw the turret, overlapping all 4 parts
  if ((FPart = 3) or (FPart = 0)) and (LTurret <> -1) and (not FUnit.FloorAbove) then
  begin
    LSurface := FUnitSurface.GetFrame(256 + (LTurret * 8) + FUnit.TurretDirection);
    LSurface.X := OFF_TURRET_X[FUnit.Direction] + OFF_X_SPRITE;
    if FPart = 3 then
      LSurface.Y := OFF_TURRET_Y_BELOW[FUnit.Direction]
    else
      LSurface.Y := OFF_TURRET_Y_ABOVE[FUnit.Direction];
    DrawRecolored(LSurface);
  end;
end;

procedure TXcomUnitSprite.DrawRoutine12;
const
  DIE = 8;
var
  LSurface: TXcomSurface;
begin
  if FUnit.IsOut then
    Exit;
  LSurface := FUnitSurface.GetFrame((FPart * 8) + FAnimationFrame);
  if (FUnit.Status = STATUS_COLLAPSING) and (FDrawingRoutine = 16) then
    // biodrone death frames
    LSurface := FUnitSurface.GetFrame(DIE + FUnit.FallingPhase);
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
end;

procedure TXcomUnitSprite.DrawRoutine19;
const
  STAND = 0;
  MOVE = 8;
  DIE = 16;
var
  LSurface: TXcomSurface;
begin
  if FUnit.IsOut then
    Exit;
  if FUnit.Status = STATUS_COLLAPSING then
    LSurface := FUnitSurface.GetFrame(DIE + FUnit.FallingPhase)
  else if FUnit.Status = STATUS_WALKING then
    LSurface := FUnitSurface.GetFrame(MOVE + FUnit.Direction)
  else
    LSurface := FUnitSurface.GetFrame(STAND + FUnit.Direction);
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
end;

procedure TXcomUnitSprite.DrawRoutine20;
var
  LSurface: TXcomSurface;
begin
  if FUnit.IsOut then
    Exit;
  if FUnit.Status = STATUS_WALKING then
    LSurface := FUnitSurface.GetFrame((FUnit.WalkingPhase div 2 mod 4) + 5 * (FPart + 4 * FUnit.Direction))
  else
    LSurface := FUnitSurface.GetFrame(5 * (FPart + 4 * FUnit.Direction));
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
end;

procedure TXcomUnitSprite.DrawRoutine21;
var
  LSurface: TXcomSurface;
begin
  if FUnit.IsOut then
    Exit;
  LSurface := FUnitSurface.GetFrame((FPart * 4) + (FUnit.Direction * 16) + (FAnimationFrame mod 4));
  LSurface.X := OFF_X_SPRITE;
  DrawRecolored(LSurface);
end;

end.
