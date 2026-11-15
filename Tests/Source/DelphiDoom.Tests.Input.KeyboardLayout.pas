{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keyboard layouts                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Input.KeyboardLayout;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Input.KeyboardLayout;

type
  [TestFixture]
  [Category('input')]
  TTestInputKeyboardLayout = class
  strict private
    procedure CompareWithOld(const AKind: TKeyboardLayoutKind; const AMode: Integer);
  public
    [Test]
    procedure DovrebbeDareFalsoPerUnaModalitaSconosciuta;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHexen;
    [Test]
    procedure DovrebbeDareQuattroTastiArmaPerHexen;
  end;

implementation

uses
  System.SysUtils;

var
  key_right, key_left, key_up, key_down, key_strafeleft, key_straferight, key_jump, key_crouch,
    key_fire, key_use, key_strafe, key_speed, key_lookup, key_lookdown, key_lookcenter,
    key_lookright, key_lookleft, key_lookforward, key_flyup, key_flydown, key_flycenter,
    key_invleft, key_invright: Integer;
  key_weapon0, key_weapon1, key_weapon2, key_weapon3, key_weapon4, key_weapon5, key_weapon6,
    key_weapon7: Integer;
  AM_GOBIGKEY, AM_FOLLOWKEY, AM_GRIDKEY, AM_ROTATEKEY, AM_TEXTUREDAUTOMAP, AM_MARKKEY,
    AM_CLEARMARKKEY: Integer;

// The old procedures of the three g_game units, copied as they were (one per kind of game)
{$I old_km.inc}

procedure Forget;
begin
  key_right := -1; key_left := -1; key_up := -1; key_down := -1; key_strafeleft := -1;
  key_straferight := -1; key_jump := -1; key_crouch := -1; key_fire := -1; key_use := -1;
  key_strafe := -1; key_speed := -1; key_lookup := -1; key_lookdown := -1; key_lookcenter := -1;
  key_lookright := -1; key_lookleft := -1; key_lookforward := -1; key_flyup := -1;
  key_flydown := -1; key_flycenter := -1; key_invleft := -1; key_invright := -1;
  key_weapon0 := -1; key_weapon1 := -1; key_weapon2 := -1; key_weapon3 := -1; key_weapon4 := -1;
  key_weapon5 := -1; key_weapon6 := -1; key_weapon7 := -1;
  AM_GOBIGKEY := -1; AM_FOLLOWKEY := -1; AM_GRIDKEY := -1; AM_ROTATEKEY := -1;
  AM_TEXTUREDAUTOMAP := -1; AM_MARKKEY := -1; AM_CLEARMARKKEY := -1;
end;

// A key the old procedure did not set stays -1: the layout gives zero for it
function Expected(const AOldValue, ANewValue: Integer): Boolean;
begin
  Result := (AOldValue = ANewValue) or ((AOldValue = -1) and (ANewValue = 0));
end;

{ TTestInputKeyboardLayout }

procedure TTestInputKeyboardLayout.CompareWithOld(const AKind: TKeyboardLayoutKind;
  const AMode: Integer);
var
  LLayout: TKeyboardLayout;
  LWeapons: array[0..7] of Integer;
  LIndex: Integer;
begin
  Forget;
  case AKind of
    klDoom: OldDoomSetKeyboardMode(AMode);
    klHeretic: OldHereticSetKeyboardMode(AMode);
    klHexen: OldHexenSetKeyboardMode(AMode);
  end;
  Assert.IsTrue(TKeyboardLayouts.TryGet(AKind, AMode, LLayout));
  Assert.IsTrue(Expected(key_right, LLayout.Right), 'right');
  Assert.IsTrue(Expected(key_left, LLayout.Left), 'left');
  Assert.IsTrue(Expected(key_up, LLayout.Up), 'up');
  Assert.IsTrue(Expected(key_down, LLayout.Down), 'down');
  Assert.IsTrue(Expected(key_strafeleft, LLayout.StrafeLeft), 'strafeleft');
  Assert.IsTrue(Expected(key_straferight, LLayout.StrafeRight), 'straferight');
  Assert.IsTrue(Expected(key_jump, LLayout.Jump), 'jump');
  Assert.IsTrue(Expected(key_crouch, LLayout.Crouch), 'crouch');
  Assert.IsTrue(Expected(key_fire, LLayout.Fire), 'fire');
  Assert.IsTrue(Expected(key_use, LLayout.Use), 'use');
  Assert.IsTrue(Expected(key_strafe, LLayout.Strafe), 'strafe');
  Assert.IsTrue(Expected(key_speed, LLayout.Speed), 'speed');
  Assert.IsTrue(Expected(key_lookup, LLayout.LookUp), 'lookup');
  Assert.IsTrue(Expected(key_lookdown, LLayout.LookDown), 'lookdown');
  Assert.IsTrue(Expected(key_lookcenter, LLayout.LookCenter), 'lookcenter');
  Assert.IsTrue(Expected(key_lookright, LLayout.LookRight), 'lookright');
  Assert.IsTrue(Expected(key_lookleft, LLayout.LookLeft), 'lookleft');
  Assert.IsTrue(Expected(key_lookforward, LLayout.LookForward), 'lookforward');
  Assert.IsTrue(Expected(key_flyup, LLayout.FlyUp), 'flyup');
  Assert.IsTrue(Expected(key_flydown, LLayout.FlyDown), 'flydown');
  Assert.IsTrue(Expected(key_flycenter, LLayout.FlyCenter), 'flycenter');
  Assert.IsTrue(Expected(key_invleft, LLayout.InventoryLeft), 'invleft');
  Assert.IsTrue(Expected(key_invright, LLayout.InventoryRight), 'invright');
  LWeapons[0] := key_weapon0;
  LWeapons[1] := key_weapon1;
  LWeapons[2] := key_weapon2;
  LWeapons[3] := key_weapon3;
  LWeapons[4] := key_weapon4;
  LWeapons[5] := key_weapon5;
  LWeapons[6] := key_weapon6;
  LWeapons[7] := key_weapon7;
  for LIndex := 0 to 7 do
  begin
    if LIndex < LLayout.WeaponCount then
      Assert.AreEqual(LWeapons[LIndex], LLayout.Weapons[LIndex], 'weapon ' + IntToStr(LIndex))
    else
      Assert.AreEqual(-1, LWeapons[LIndex], 'weapon not set ' + IntToStr(LIndex));
  end;
  Assert.IsTrue(Expected(AM_GOBIGKEY, LLayout.AutomapBig), 'big');
  Assert.IsTrue(Expected(AM_FOLLOWKEY, LLayout.AutomapFollow), 'follow');
  Assert.IsTrue(Expected(AM_GRIDKEY, LLayout.AutomapGrid), 'grid');
  Assert.IsTrue(Expected(AM_ROTATEKEY, LLayout.AutomapRotate), 'rotate');
  Assert.IsTrue(Expected(AM_TEXTUREDAUTOMAP, LLayout.AutomapTextured), 'textured');
  Assert.IsTrue(Expected(AM_MARKKEY, LLayout.AutomapMark), 'mark');
  Assert.IsTrue(Expected(AM_CLEARMARKKEY, LLayout.AutomapClearMarks), 'clearmarks');
end;

procedure TTestInputKeyboardLayout.DovrebbeDareFalsoPerUnaModalitaSconosciuta;
var
  LLayout: TKeyboardLayout;
begin
  Assert.IsFalse(TKeyboardLayouts.TryGet(klDoom, 3, LLayout));
  Assert.IsFalse(TKeyboardLayouts.TryGet(klDoom, -1, LLayout));
end;

procedure TTestInputKeyboardLayout.DovrebbeEssereUgualeAlVecchioCodiceDiDoom;
var
  LMode: Integer;
begin
  for LMode := 0 to 2 do
    CompareWithOld(klDoom, LMode);
end;

procedure TTestInputKeyboardLayout.DovrebbeEssereUgualeAlVecchioCodiceDiHeretic;
var
  LMode: Integer;
begin
  for LMode := 0 to 2 do
    CompareWithOld(klHeretic, LMode);
end;

procedure TTestInputKeyboardLayout.DovrebbeEssereUgualeAlVecchioCodiceDiHexen;
var
  LMode: Integer;
begin
  for LMode := 0 to 2 do
    CompareWithOld(klHexen, LMode);
end;

procedure TTestInputKeyboardLayout.DovrebbeDareQuattroTastiArmaPerHexen;
var
  LLayout: TKeyboardLayout;
begin
  Assert.IsTrue(TKeyboardLayouts.TryGet(klHexen, 0, LLayout));
  Assert.AreEqual(4, LLayout.WeaponCount);
end;

end.
