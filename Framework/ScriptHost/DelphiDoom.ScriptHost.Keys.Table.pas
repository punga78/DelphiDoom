{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the table of the keyboard functions               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The 56 functions "function key_right: integer;" and the like, that were     }
{  one body each in psi_game.pas, are the lines of this table: the name that   }
{  scripts use, the key that it reads, the games that have it. The order is    }
{  the one of the declarations of ps_import.pas.                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Keys.Table;

interface

uses
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>One function of the keyboard that gives the key chosen for an action</summary>
  TScriptKeyEntry = record
    /// <summary>The name that scripts use</summary>
    Name: string;
    /// <summary>What it reads</summary>
    Key: TScriptKey;
    /// <summary>The games that have the function</summary>
    Games: TScriptGameSet;
    /// <summary>
    ///   False if the function answers also during a demo or a network game: it is the case of
    ///   mousebfire only (the old PS_mousebfire had no test: a defect that is kept)
    /// </summary>
    Guarded: Boolean;
  end;

const
  SCRIPT_ALL_GAMES = [sgDoom, sgHeretic, sgHexen, sgStrife];

  /// <summary>The functions of the keyboard, in the order of the declarations</summary>
  SCRIPT_KEY_ENTRIES: array[0..55] of TScriptKeyEntry = (
    (Name: 'key_right'; Key: skRight; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_left'; Key: skLeft; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_up'; Key: skUp; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_down'; Key: skDown; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_lookup'; Key: skLookUp; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_lookdown'; Key: skLookDown; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_lookcenter'; Key: skLookCenter; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_lookright'; Key: skLookRight; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_lookleft'; Key: skLookLeft; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_lookforward'; Key: skLookForward; Games: [sgDoom, sgHeretic, sgHexen]; Guarded: True),
    (Name: 'key_strafeleft'; Key: skStrafeLeft; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_straferight'; Key: skStrafeRight; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_fire'; Key: skFire; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_use'; Key: skUse; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_strafe'; Key: skStrafe; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_speed'; Key: skSpeed; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_jump'; Key: skJump; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_crouch'; Key: skCrouch; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_weapon0'; Key: skWeapon0; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_weapon1'; Key: skWeapon1; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_weapon2'; Key: skWeapon2; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_weapon3'; Key: skWeapon3; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'key_weapon4'; Key: skWeapon4; Games: [sgDoom, sgHeretic, sgStrife]; Guarded: True),
    (Name: 'key_weapon5'; Key: skWeapon5; Games: [sgDoom, sgHeretic, sgStrife]; Guarded: True),
    (Name: 'key_weapon6'; Key: skWeapon6; Games: [sgDoom, sgHeretic, sgStrife]; Guarded: True),
    (Name: 'key_weapon7'; Key: skWeapon7; Games: [sgDoom, sgHeretic, sgStrife]; Guarded: True),
    (Name: 'key_flyup'; Key: skFlyUp; Games: [sgHeretic, sgHexen]; Guarded: True),
    (Name: 'key_flydown'; Key: skFlyDown; Games: [sgHeretic, sgHexen]; Guarded: True),
    (Name: 'key_flycenter'; Key: skFlyCenter; Games: [sgHeretic, sgHexen]; Guarded: True),
    (Name: 'key_invleft'; Key: skInvLeft; Games: [sgHeretic, sgHexen]; Guarded: True),
    (Name: 'key_invright'; Key: skInvRight; Games: [sgHeretic, sgHexen]; Guarded: True),
    (Name: 'key_useartifact'; Key: skUseArtifact; Games: [sgHeretic, sgHexen]; Guarded: True),
    (Name: 'key_invleft'; Key: skInvLeft; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invright'; Key: skInvRight; Games: [sgStrife]; Guarded: True),
    (Name: 'key_weapon8'; Key: skWeapon8; Games: [sgStrife]; Guarded: True),
    (Name: 'key_weapon9'; Key: skWeapon9; Games: [sgStrife]; Guarded: True),
    (Name: 'key_usehealth'; Key: skUseHealth; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invquery'; Key: skInvQuery; Games: [sgStrife]; Guarded: True),
    (Name: 'key_mission'; Key: skMission; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invpop'; Key: skInvPop; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invkey'; Key: skInvKey; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invhome'; Key: skInvHome; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invend'; Key: skInvEnd; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invuse'; Key: skInvUse; Games: [sgStrife]; Guarded: True),
    (Name: 'key_invdrop'; Key: skInvDrop; Games: [sgStrife]; Guarded: True),
    (Name: 'mousebfire'; Key: skMouseFire; Games: SCRIPT_ALL_GAMES; Guarded: False),
    (Name: 'mousebstrafe'; Key: skMouseStrafe; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'mousebforward'; Key: skMouseForward; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joybfire'; Key: skJoyFire; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joybstrafe'; Key: skJoyStrafe; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joybuse'; Key: skJoyUse; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joybspeed'; Key: skJoySpeed; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joybjump'; Key: skJoyJump; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joybcrouch'; Key: skJoyCrouch; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joyblleft'; Key: skJoyLeft; Games: SCRIPT_ALL_GAMES; Guarded: True),
    (Name: 'joyblright'; Key: skJoyRight; Games: SCRIPT_ALL_GAMES; Guarded: True)
  );

implementation

end.
