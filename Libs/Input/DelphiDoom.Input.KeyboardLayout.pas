{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the keyboard layouts of the games               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.KeyboardLayout;

interface

const
  /// <summary>The weapon keys of the layouts (the games use the first ones they have)</summary>
  KEYBOARD_LAYOUT_WEAPONS = 8;

type
  /// <summary>The families of games that differ in the keys they have (Heretic and Hexen fly)</summary>
  TKeyboardLayoutKind = (klDoom, klHeretic, klHexen);

  /// <summary>
  ///   The key codes of a layout, the ones the engine keeps in key_right, key_left... and AM_GOBIGKEY...
  ///   The keys a kind of game does not have are zero
  /// </summary>
  TKeyboardLayout = record
    Right: Integer;
    Left: Integer;
    Up: Integer;
    Down: Integer;
    StrafeLeft: Integer;
    StrafeRight: Integer;
    Jump: Integer;
    Crouch: Integer;
    Fire: Integer;
    Use: Integer;
    Strafe: Integer;
    Speed: Integer;
    LookUp: Integer;
    LookDown: Integer;
    LookCenter: Integer;
    LookRight: Integer;
    LookLeft: Integer;
    LookForward: Integer;
    FlyUp: Integer;
    FlyDown: Integer;
    FlyCenter: Integer;
    InventoryLeft: Integer;
    InventoryRight: Integer;
    /// <summary>How many of Weapons the game has</summary>
    WeaponCount: Integer;
    Weapons: array[0..KEYBOARD_LAYOUT_WEAPONS - 1] of Integer;
    AutomapBig: Integer;
    AutomapFollow: Integer;
    AutomapGrid: Integer;
    AutomapRotate: Integer;
    AutomapTextured: Integer;
    AutomapMark: Integer;
    AutomapClearMarks: Integer;
  end;

  /// <summary>
  ///   The three keyboard modes of the options (arrows, WASD, ESDF as G_SetKeyboardMode sets them),
  ///   as data: a table per kind of game instead of a copy of the procedure in each game
  /// </summary>
  TKeyboardLayouts = class sealed
  public
    /// <summary>The keys of a mode</summary>
    /// <param name="AKind">The kind of game</param>
    /// <param name="AMode">0 arrows, 1 WASD, 2 ESDF</param>
    /// <param name="ALayout">The keys; untouched when the mode is unknown</param>
    /// <returns>False if the mode is not one of the three (the old code changed nothing)</returns>
    class function TryGet(const AKind: TKeyboardLayoutKind; const AMode: Integer;
      out ALayout: TKeyboardLayout): Boolean; static;
  end;

implementation

{ TKeyboardLayouts }

class function TKeyboardLayouts.TryGet(const AKind: TKeyboardLayoutKind; const AMode: Integer;
  out ALayout: TKeyboardLayout): Boolean;
var
  LIndex: Integer;
begin
  Result := (AMode >= 0) and (AMode <= 2);
  if not Result then
    Exit;

  FillChar(ALayout, SizeOf(ALayout), 0);
  // the same in every mode
  ALayout.Right := 174;
  ALayout.Left := 172;
  ALayout.Fire := 157;
  ALayout.Use := 32;
  ALayout.Strafe := 184;
  ALayout.Speed := 182;
  ALayout.LookUp := 197;
  ALayout.LookDown := 202;
  ALayout.LookCenter := 199;
  ALayout.LookForward := 13;
  ALayout.AutomapBig := Ord('o');
  ALayout.AutomapFollow := Ord('f');
  ALayout.AutomapGrid := Ord('g');
  ALayout.AutomapRotate := Ord('r');
  ALayout.AutomapTextured := Ord('t');
  ALayout.AutomapMark := Ord('m');
  ALayout.AutomapClearMarks := Ord('c');

  if AKind = klDoom then
  begin
    ALayout.LookRight := 198;
    ALayout.LookLeft := 200;
  end
  else
  begin
    ALayout.LookRight := 42;
    ALayout.LookLeft := 47;
    ALayout.FlyUp := 198;
    ALayout.FlyDown := 200;
    ALayout.FlyCenter := 201;
    ALayout.InventoryLeft := Ord('[');
    ALayout.InventoryRight := Ord(']');
  end;

  if AKind = klHexen then
    ALayout.WeaponCount := 4
  else
    ALayout.WeaponCount := KEYBOARD_LAYOUT_WEAPONS;
  for LIndex := 0 to KEYBOARD_LAYOUT_WEAPONS - 1 do
    ALayout.Weapons[LIndex] := Ord('1') + LIndex;

  case AMode of
    0:
      begin
        ALayout.Up := 173;
        ALayout.Down := 175;
        ALayout.StrafeLeft := 44;
        ALayout.StrafeRight := 46;
        ALayout.Jump := 97;
        ALayout.Crouch := 122;
      end;
    1:
      begin
        ALayout.Up := 119;
        ALayout.Down := 115;
        ALayout.StrafeLeft := 97;
        ALayout.StrafeRight := 100;
        ALayout.Jump := 101;
        ALayout.Crouch := 113;
      end;
    2:
      begin
        ALayout.Up := 101;
        ALayout.Down := 100;
        ALayout.StrafeLeft := 115;
        ALayout.StrafeRight := 102;
        ALayout.Jump := 97;
        ALayout.Crouch := 122;
        ALayout.AutomapFollow := Ord('l');
      end;
  end;
end;

end.
