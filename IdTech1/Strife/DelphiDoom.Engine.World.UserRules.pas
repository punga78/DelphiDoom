{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Strife for the player (p_user)            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.UserRules;

interface

uses
  m_fixed,
  tables,
  p_mobj_h,
  d_player,
  d_ticcmd;

type
  /// <summary>
  ///   What Strife does in the player code of p_user (issue #185, step 2f-1). The routines that
  ///   are the same in the games are in IdTech1\Base\p_user.pas; the ones that only this game has stay here
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TUserGameRules = class sealed
  public
    const
      /// <summary>The slopes version of P_SlopesCalcHeight keeps the old view height when the player is in the air</summary>
      KeepsOldViewZInAir = True;
      /// <summary>The distance from the floor under which the view height is not let to go (slopes version)</summary>
      SlopesFloorMargin = 0;
      /// <summary>P_DeathThink is a method of the rules (Hexen: the skull and the ice chunk, the poison, the palette, the reborn state)</summary>
      OwnsDeathThink = False;
      /// <summary>The jump and the crouch work out of the new engine too (Strife); the other games run them only in it</summary>
      JumpsAlways = True;
      /// <summary>P_PlayerThink starts by leaving when the player has no thing</summary>
      GuardsNilMobj = False;

    /// <summary>Sets onground, the state of the player towards the floor</summary>
    class procedure SetOnGround(const player: Pplayer_t); static;
    /// <summary>The sector or the map forbids the jump</summary>
    class function MapNoJump: boolean; static;
    /// <summary>The sector or the map forbids the crouch</summary>
    class function MapNoCrouch: boolean; static;
    /// <summary>The movement of the player for the commands of the tic (thrust, flight, the running state)</summary>
    class procedure MoveByCommand(const player: Pplayer_t; const cmd: Pticcmd_t; const cmd_jump, cmd_crouch: byte); static;
    /// <summary>The look up and down of the command</summary>
    class function LookUpDown(const cmd: Pticcmd_t): integer; static; inline;
    /// <summary>The player turns to a target: the look commands only center the view (Doom, Strife)</summary>
    class function AimsAtTarget(const player: Pplayer_t): boolean; static; inline;
    /// <summary>What comes after the movement and the look (Heretic, Hexen: the flight)</summary>
    class procedure AfterMove(const player: Pplayer_t; const cmd: Pticcmd_t); static;
    /// <summary>The death of the player (only when OwnsDeathThink)</summary>
    class procedure DeathThink(player: Pplayer_t); static;
    /// <summary>The player thinker (called every tic for every player)</summary>
    class procedure PlayerThink(player: Pplayer_t); static;
    /// <summary>What the player does before the move (Doom, Strife: turn towards a target; Heretic: the chicken)</summary>
    class procedure BeforeMove(const player: Pplayer_t); static;
    /// <summary>What comes after the special sectors (Heretic: the artifacts; Strife: the breath and the inventory)</summary>
    class procedure AfterSector(const player: Pplayer_t; const cmd: Pticcmd_t); static;
    /// <summary>The change of the weapon the buttons ask for</summary>
    class procedure ChangeWeapon(const player: Pplayer_t; const cmd: Pticcmd_t); static;
    /// <summary>What comes before the use of the lines (Strife: the dialogs)</summary>
    class procedure BeforeUseLines(const player: Pplayer_t); static;
    /// <summary>What comes before the weapon sprites move (Heretic: the chicken counter)</summary>
    class procedure BeforePsprites(const player: Pplayer_t); static;
    /// <summary>The counters of the powers and of the screen effects</summary>
    class procedure CountDown(const player: Pplayer_t); static;
    /// <summary>The colormap of the view</summary>
    class procedure Colormap(const player: Pplayer_t); static;
    /// <summary>The last thing of the thinker (Doom: the breath of the player)</summary>
    class procedure AtEnd(const player: Pplayer_t); static;
    /// <summary>The thrust of P_Thrust: Heretic and Hexen weaken it on ice and keep it when flying</summary>
    class function ThrustMove(const player: Pplayer_t; const move: fixed_t): fixed_t; static;
    /// <summary>The bob of a player that flies is fixed (Heretic, Hexen)</summary>
    class function FlyBobs(const player: Pplayer_t): boolean; static; inline;
    /// <summary>The player is a chicken (Heretic) or a pig (Hexen): no crouch, lower view</summary>
    class function IsMorphed(const player: Pplayer_t): boolean; static; inline;
    /// <summary>What a game does to the view height before the ceiling clamp (feet in water)</summary>
    class procedure AdjustViewZ(const player: Pplayer_t); static; inline;
    /// <summary>What a game does to the view height after the ceiling clamp (the floor clamp)</summary>
    class procedure ClampViewZ(const player: Pplayer_t); static; inline;
  end;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TUserRoutines = class sealed
  public
    //==============================================================================
    //
    // P_UseInventoryItem
    //
    //==============================================================================
    class function P_UseInventoryItem(player: Pplayer_t; item: integer): boolean; static;

    //==============================================================================
    //
    // P_DropInventoryItem
    //
    //==============================================================================
    class procedure P_DropInventoryItem(player: Pplayer_t; sprite: integer); static;

    //==============================================================================
    //
    // P_RemoveInventoryItem
    //
    //==============================================================================
    class function P_RemoveInventoryItem(player: Pplayer_t; slot: integer; amount: integer): string; static;

    //==============================================================================
    //
    // P_ItemBehavior
    //
    //==============================================================================
    class function P_ItemBehavior(player: Pplayer_t; item: integer): boolean; static;
  end;


implementation

uses
  d_delphi,
  deh_main,
  d_main,
  m_rnd,
  d_event,
  d_items,
  info_h,
  info,
{$IFDEF DEBUG}
  i_io,
{$ENDIF}
  g_game,
  p_common,
  p_genlin,
  p_playertrace,
  p_friends,
  p_mobj,
  p_tick,
  p_pspr,
  p_pspr_h,
  p_inter,
  DelphiDoom.Engine.World.InterRules,
  DelphiDoom.Engine.World.PickupGivers,
  p_local,
  p_setup,    // JVAL: 3d Floors
  p_slopes,   // JVAL: Slopes
  p_3dfloors, // JVAL: Slopes
  p_spec_h,
  p_spec,
  p_map,
  p_maputl,
  p_dialog,
  r_main,
  r_defs,
  sounddata,
  sounds,
  s_sound,
  doomdef,
  p_user,
  DelphiDoom.Engine.World.PlayerExtras,
  DelphiDoom.Engine.World.PlayerThinker;


//==============================================================================
//
// P_RemoveInventoryItem
// villsa [STRIFE] new function
//
//==============================================================================
class function TUserRoutines.P_RemoveInventoryItem(player: Pplayer_t; slot: integer; amount: integer): string;
var
  _type: integer;
  j: integer;
begin
  player.inventory[slot].amount := player.inventory[slot].amount - amount;
  player.st_update := true;

  _type := player.inventory[slot]._type;

  if player.inventory[slot].amount = 0 then
  begin
      // shift everything above it down
      // see P_TakeDialogItem for notes on possible bugs

    for j := slot + 1 to player.numinventory do
      player.inventory[j - 1] := player.inventory[j];

    // blank the topmost slot
    // BUG: This will overwrite the aforementioned fields if
    // numinventory is equal to the number of slots!
    // STRIFE-TODO: Overflow emulation?
    // JVAL: fix this
    if player.numinventory < NUMINVENTORY then
    begin
      player.inventory[player.numinventory]._type := nummobjtypes;
      player.inventory[player.numinventory].sprite := -1;
      player.inventory[player.numinventory].amount := 0;
    end;
    dec(player.numinventory);

    // update cursor position
    if player.inventorycursor >= player.numinventory then
      if player.inventorycursor > 0 then
        dec(player.inventorycursor);
  end;

  result := mobjinfo[_type].name2;
end;

//==============================================================================
//
// P_DropInventoryItem
// villsa [STRIFE] new function
//
//==============================================================================
class procedure TUserRoutines.P_DropInventoryItem(player: Pplayer_t; sprite: integer);
var
  invslot: integer;
  item: Pinventory_t;
  _type: integer;
  amount: integer;
  angle: angle_t;
  dist: fixed_t;
  mo, mobjitem: Pmobj_t;
  x, y, z: fixed_t;
  r: integer;
begin
  invslot := 0;
  amount := 1;

  while (invslot < player.numinventory) and (sprite <> player.inventory[invslot].sprite) do
    inc(invslot);

  item := @player.inventory[invslot];
  _type := item._type;

  if item.amount > 0 then
  begin
    if item._type = Ord(MT_MONY_1) then
    begin
      if item.amount >= 50 then
      begin
        _type := Ord(MT_MONY_50);
        amount := 50;
      end
      else if item.amount >= 25 then
      begin
        _type := Ord(MT_MONY_25);
        amount := 25;
      end
      else if item.amount >= 10 then
      begin
        _type := Ord(MT_MONY_10);
        amount := 10;
      end;
    end;

    if _type >= nummobjtypes then
      exit;

    angle := player.mo.angle;
    r := P_Random;
    angle := (angle + _SHLW(r - P_Random, 18)) div ANGLETOFINEUNIT;

    if (angle < 7618) and (angle >= 6718) then
      angle := 7618
    else if (angle < 5570) and (angle >= 4670) then
      angle := 5570
    else if (angle < 3522) and (angle >= 2622) then
      angle := 3522
    else if (angle < 1474) and (angle >= 574) then
      angle := 1474;

    mo := player.mo;
    dist := mobjinfo[_type].radius + mo.info.radius + (4 * FRACUNIT);

    x := mo.x + FixedMul(finecosine[angle], dist);
    y := mo.y + FixedMul(finesine[angle], dist);
    z := mo.z + (10 * FRACUNIT);
    mobjitem := P_SpawnMobj(x, y, z, _type);
    mobjitem.flags := mobjitem.flags or (MF_SPECIAL or MF_DROPPED);

    if P_CheckPosition(mobjitem, x, y) then
    begin
      mobjitem.angle := angle * ANGLETOFINEUNIT;
      mobjitem.momx := FixedMul(finecosine[angle], (5 * FRACUNIT)) + mo.momx;
      mobjitem.momy := FixedMul(finesine[angle], (5 * FRACUNIT)) + mo.momy;
      mobjitem.momz := FRACUNIT;

      P_RemoveInventoryItem(player, invslot, amount);
    end
    else
      P_RemoveMobj(mobjitem);
  end;
end;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TUserLocalRoutines = class sealed
  public
    class function P_SpawnTeleportBeacon(player: Pplayer_t): boolean; static;
  end;

//==============================================================================
//
// P_SpawnTeleportBeacon
//
// villsa [STRIFE] new function
// haleyjd 20140918: bug fixed to propagate allegiance properly.
//
//==============================================================================
class function TUserLocalRoutines.P_SpawnTeleportBeacon(player: Pplayer_t): boolean;
var
  angle: angle_t;
  r: integer;
  mo, beacon: Pmobj_t;
  x, y, z, dist: fixed_t;
begin
  angle := player.mo.angle;
  r := P_Random();
  angle := (angle + _SHLW(r - P_Random, 18)) div ANGLETOFINEUNIT;

  if (angle < 7618) and (angle >= 6718) then
    angle := 7618
  else if (angle < 5570) and (angle >= 4670) then
    angle := 5570
  else if (angle < 3522) and (angle >= 2622) then
    angle := 3522
  else if (angle < 1474) and (angle >= 574) then
    angle := 1474;

  mo := player.mo;
  dist := mobjinfo[Ord(MT_BEACON)].radius + mo.info.radius + (4 * FRACUNIT);

  x := mo.x + FixedMul(finecosine[angle], dist);
  y := mo.y + FixedMul(finesine[angle], dist);
  z := mo.z + (10 * FRACUNIT);
  beacon := P_SpawnMobj(x, y, z, Ord(MT_BEACON));

  if P_CheckPosition(beacon, x, y) then
  begin
    beacon.target := mo;
    beacon.miscdata := byte(player.allegiance);
    beacon.angle := angle * ANGLETOFINEUNIT;
    beacon.momx := FixedMul(finecosine[angle], (5 * FRACUNIT));
    beacon.momy := FixedMul(finesine[angle], (5 * FRACUNIT));
    beacon.momz := FRACUNIT;
    P_SetMobjState(beacon, statenum_t(beacon.info.seestate));
    result := true;
  end
  else
  begin
    P_RemoveMobj(beacon);
    result := false;
  end;
end;

//==============================================================================
//
// P_UseInventoryItem
// villsa [STRIFE] new function
//
//==============================================================================
class function TUserRoutines.P_UseInventoryItem(player: Pplayer_t; item: integer): boolean;
var
  i: integer;
  name: string;
begin

  if player.cheats and CF_ONFIRE <> 0 then
  begin
    result := false;
    exit;
  end;

  for i := 0 to player.numinventory - 1 do
  begin
    if item <> player.inventory[i].sprite then
      continue;

    if not P_ItemBehavior(player, item) then
    begin
      result := false;
      exit;
    end;

    name := P_RemoveInventoryItem(player, i, 1);
    if name = '' then
      name := 'Item';

    player._message := 'You used the ' + name;

    if player = @TGameSession.Players[TGameSession.ConsolePlayer] then
      S_StartSound(nil, Ord(sfx_itemup));

    result := true;
    exit;
  end;

  result := false;
end;

//==============================================================================
//
// P_ItemBehavior
// villsa [STRIFE] new function
//
//==============================================================================
class function TUserRoutines.P_ItemBehavior(player: Pplayer_t; item: integer): boolean;
begin
  case item of
    Ord(SPR_ARM1):  // 136
      begin
        result := P_GiveArmor(player, 2);
        exit;
      end;

    Ord(SPR_ARM2):  // 137
      begin
        result := P_GiveArmor(player, 1);
        exit;
      end;

    Ord(SPR_SHD1):  // 186
      begin
        result := TInterRoutines.P_GivePower(player, Ord(pw_invisibility));
        exit;
      end;

    Ord(SPR_MASK):  // 187
      begin
        result := TInterRoutines.P_GivePower(player, Ord(pw_ironfeet));
        exit;
      end;

    Ord(SPR_PMUP):  // 191
      begin
        if player.powers[Ord(pw_allmap)] = 0 then
        begin
          player._message := DEH_GetString('The scanner won''t work without a map!');
          result := false;
          exit;
        end;
        player.powers[Ord(pw_allmap)] := PMUPTICS;
        result := true; // haleyjd 20110228: repaired
        exit;
      end;

    Ord(SPR_STMP):  // 180
      begin
        result := P_GiveBody(player, 10);
        exit;
      end;

    Ord(SPR_MDKT):  // 181
      begin
        result := P_GiveBody(player, 25);
        exit;
      end;

    Ord(SPR_FULL):  // 130
      begin
        result := P_GiveBody(player, 200);
        exit;
      end;

    Ord(SPR_BEAC):  // 135
      begin
        result := TUserLocalRoutines.P_SpawnTeleportBeacon(player);
        exit;
      end;

    Ord(SPR_TARG):  // 108
      begin
        result := TInterRoutines.P_GivePower(player, Ord(pw_targeter));
        exit;
      end;
  end;

  result := false;
end;

//==============================================================================
//
// TUserGameRules.ThrustMove
//
//==============================================================================
class function TUserGameRules.ThrustMove(const player: Pplayer_t; const move: fixed_t): fixed_t;
begin
  result := move;
end;

//==============================================================================
//
// TUserGameRules.FlyBobs
//
//==============================================================================
class function TUserGameRules.FlyBobs(const player: Pplayer_t): boolean;
begin
  result := false;
end;

//==============================================================================
//
// TUserGameRules.IsMorphed
//
//==============================================================================
class function TUserGameRules.IsMorphed(const player: Pplayer_t): boolean;
begin
  result := false;
end;

//==============================================================================
//
// TUserGameRules.AdjustViewZ
//
//==============================================================================
class procedure TUserGameRules.AdjustViewZ(const player: Pplayer_t);
begin
  if player.mo.flags and MF_FEETCLIPPED <> 0 then
    player.viewz := player.viewz - 13 * FRACUNIT;
end;

//==============================================================================
//
// TUserGameRules.ClampViewZ
//
//==============================================================================
class procedure TUserGameRules.ClampViewZ(const player: Pplayer_t);
begin
  if player.viewz < player.mo.floorz then
    player.viewz := player.mo.floorz;
end;

//==============================================================================
//
// TUserGameRules.DeathThink
//
//==============================================================================
class procedure TUserGameRules.DeathThink(player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.SetOnGround
//
//==============================================================================
class procedure TUserGameRules.SetOnGround(const player: Pplayer_t);
begin
  onground := player.mo.z <= player.mo.floorz;
end;

//==============================================================================
//
// TUserGameRules.MapNoJump
//
//==============================================================================
class function TUserGameRules.MapNoJump: boolean;
begin
  result := (TGameSession.GameMapInfo <> nil) and TGameSession.GameMapInfo.nojump;
end;

//==============================================================================
//
// TUserGameRules.MapNoCrouch
//
//==============================================================================
class function TUserGameRules.MapNoCrouch: boolean;
begin
  result := (TGameSession.GameMapInfo <> nil) and TGameSession.GameMapInfo.nocrouch;
end;

//==============================================================================
//
// TUserGameRules.MoveByCommand
//
//==============================================================================
class procedure TUserGameRules.MoveByCommand(const player: Pplayer_t; const cmd: Pticcmd_t; const cmd_jump, cmd_crouch: byte);
var
  movefactor: fixed_t;
begin
  // villsa [STRIFE] allows player to climb over things by jumping
  // haleyjd 20110205: air control thrust should be 256, not cmd.forwardmove
  if not onground and (player.cheats and CF_LOWGRAVITY = 0) and (cmd.forwardmove <> 0) then
  begin
    P_Thrust(player, player.mo.angle, 256);
  end
  else
  begin
    movefactor := ORIG_FRICTION_FACTOR;

    if player.cheats and CF_LOWGRAVITY = 0 then
      if Psubsector_t(player.mo.subsector).sector.special and FRICTION_MASK <> 0 then
        movefactor := P_GetMoveFactor(player.mo);

    if (player.cheats and CF_LOWGRAVITY <> 0) or
      ((cmd.forwardmove <> 0) and
       (onground or ((cmd_jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0)))) then
      P_Thrust(player, player.mo.angle, cmd.forwardmove * movefactor);

    if (player.cheats and CF_LOWGRAVITY <> 0) or
      ((cmd.sidemove <> 0) and
       (onground or ((cmd_jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0)))) then
      P_Thrust(player, player.mo.angle - ANG90, cmd.sidemove * movefactor);
  end;

  // JVAL: Adjust speed while flying
  if (player.cheats and CF_LOWGRAVITY <> 0) and (player.mo.z > player.mo.floorz) then
  begin
    if player.mo.momx > 18 * FRACUNIT then
      player.mo.momx := 18 * FRACUNIT
    else if player.mo.momx < -18 * FRACUNIT then
      player.mo.momx := -18 * FRACUNIT;
    if player.mo.momy > 18 * FRACUNIT then
      player.mo.momy := 18 * FRACUNIT
    else if player.mo.momy < -18 * FRACUNIT then
      player.mo.momy := -18 * FRACUNIT;

    if (cmd.forwardmove = 0) and (cmd.sidemove = 0) then
    begin
      player.mo.momx := player.mo.momx * 15 div 16;
      player.mo.momy := player.mo.momy * 15 div 16;
    end;
  end;

  if ((cmd.forwardmove <> 0) or (cmd.sidemove <> 0)) and
     (player.mo.state = @states[Ord(S_PLAY_00)]) then
    P_SetMobjState(player.mo, S_PLAY_01);
end;

//==============================================================================
//
// TUserGameRules.LookUpDown
//
//==============================================================================
class function TUserGameRules.LookUpDown(const cmd: Pticcmd_t): integer;
begin
  result := cmd.lookupdown;
end;

//==============================================================================
//
// TUserGameRules.AimsAtTarget
//
//==============================================================================
class function TUserGameRules.AimsAtTarget(const player: Pplayer_t): boolean;
begin
  result := player.angletargetticks > 0;
end;

//==============================================================================
//
// TUserGameRules.AfterMove
//
//==============================================================================
class procedure TUserGameRules.AfterMove(const player: Pplayer_t; const cmd: Pticcmd_t);
begin
end;

//==============================================================================
//
// TUserGameRules.PlayerThink
//
//==============================================================================
class procedure TUserGameRules.PlayerThink(player: Pplayer_t);
begin
  TPlayerThinker.Think(player);
end;

//==============================================================================
//
// TUserGameRules.BeforeMove
//
//==============================================================================
class procedure TUserGameRules.BeforeMove(const player: Pplayer_t);
begin
  P_AngleTarget(player);
end;

//==============================================================================
//
// TUserGameRules.AfterSector
//
//==============================================================================
class procedure TUserGameRules.AfterSector(const player: Pplayer_t; const cmd: Pticcmd_t);
begin
  if not G_NeedsCompatibilityMode then
    A_PlayerBreath(player);

  // villsa [STRIFE] handle inventory input
  if cmd.buttons2 and (BT2_HEALTH or BT2_INVUSE or BT2_INVDROP) <> 0 then
  begin
    if not player.inventorydown then
    begin
      if cmd.buttons2 and BT2_HEALTH <> 0 then
        TUserRoutines.P_UseInventoryItem(player, Ord(SPR_FULL))
      else if cmd.buttons2 and BT2_INVUSE <> 0 then
        TUserRoutines.P_UseInventoryItem(player, cmd.inventory)
      else if cmd.buttons2 and BT2_INVDROP <> 0 then
        TUserRoutines.P_DropInventoryItem(player, cmd.inventory);

      player.inventorydown := true;
    end
    else
      player.inventorydown := false;
  end;
end;

//==============================================================================
//
// TUserGameRules.ChangeWeapon
//
//==============================================================================
class procedure TUserGameRules.ChangeWeapon(const player: Pplayer_t; const cmd: Pticcmd_t);
var
  newweapon: weapontype_t;
begin
  if cmd.buttons and BT_CHANGE <> 0 then
  begin
    // The actual changing of the weapon is done
    //  when the weapon psprite can do it
    //  (read: not in the middle of an attack).
    newweapon := weapontype_t(_SHR(cmd.buttons and BT_WEAPONMASK, BT_WEAPONSHIFT));

    // villsa [STRIFE] select poison bow
    if newweapon = wp_elecbow then
      if player.weaponowned[Ord(wp_poisonbow)] and (player.readyweapon = wp_elecbow) then
        if player.ammo[Ord(weaponinfo[Ord(wp_poisonbow)].ammo)] > 0 then
          newweapon := wp_poisonbow;

    // villsa [STRIFE] select wp grenade launcher
    if newweapon = wp_hegrenade then
      if player.weaponowned[Ord(wp_wpgrenade)] and (player.readyweapon = wp_hegrenade) then
        if player.ammo[Ord(weaponinfo[Ord(wp_wpgrenade)].ammo)] > 0 then
          newweapon := wp_wpgrenade;

    // villsa [STRIFE] select torpedo
    if newweapon = wp_mauler then
      if player.weaponowned[Ord(wp_torpedo)] and (player.readyweapon = wp_mauler) then
        // haleyjd 20140924: bug fix - using wrong enum value am_cell
        // caused this to check the missile launcher for rocket ammo
        if player.ammo[Ord(weaponinfo[Ord(wp_torpedo)].ammo)] >= 30 then
          newweapon := wp_torpedo;

    if player.weaponowned[Ord(newweapon)] and (newweapon <> player.readyweapon) then
    begin
      // villsa [STRIFE] check weapon if in demo mode or not
      if weaponinfo[Ord(newweapon)].availabledemo or not isdemoversion then
      begin
        if player.ammo[Ord(weaponinfo[Ord(newweapon)].ammo)] > 0 then
          player.pendingweapon := newweapon
        else
        begin
          // decide between electric bow or poison arrow
          if (newweapon = wp_elecbow) and
             (player.ammo[Ord(am_poisonbolts)] > 0) and
             (player.readyweapon <> wp_poisonbow) then
            player.pendingweapon := wp_poisonbow
          // decide between hp grenade launcher or wp grenade launcher
          else if (newweapon = wp_hegrenade) and
                  (player.ammo[Ord(am_wpgrenades)] > 0) and
                  (player.readyweapon <> wp_wpgrenade) then
            player.pendingweapon := wp_wpgrenade
                  // villsa [STRIFE] - no check for mauler/torpedo??
        end;
      end;
    end;
  end;
end;

//==============================================================================
//
// TUserGameRules.BeforeUseLines
//
//==============================================================================
class procedure TUserGameRules.BeforeUseLines(const player: Pplayer_t);
begin
  P_DialogStart(player);  // villsa [STRIFE]
end;

//==============================================================================
//
// TUserGameRules.BeforePsprites
//
//==============================================================================
class procedure TUserGameRules.BeforePsprites(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.CountDown
//
//==============================================================================
class procedure TUserGameRules.CountDown(const player: Pplayer_t);
begin
  // JVAL
  if player.hardbreathtics > 0 then
    player.hardbreathtics := player.hardbreathtics - 1;

  // Strength counts up to diminish fade.
  if player.powers[Ord(pw_strength)] <> 0 then
    inc(player.powers[Ord(pw_strength)]);

  // villsa [STRIFE] targeter powerup
  if player.powers[Ord(pw_targeter)] > 0 then
  begin
    dec(player.powers[Ord(pw_targeter)]);
    if player.powers[Ord(pw_targeter)] = 1 then
    begin
      P_SetPsprite(player, Ord(ps_targcenter), S_NULL);
      P_SetPsprite(player, Ord(ps_targleft),   S_NULL);
      P_SetPsprite(player, Ord(ps_targright),  S_NULL);
    end
    else if player.powers[Ord(pw_targeter)] - 1 < 5 * TICRATE then
    begin
      if player.powers[Ord(pw_targeter)] and 32 <> 0 then
      begin
        P_SetPsprite(player, Ord(ps_targright), S_NULL);
        P_SetPsprite(player, Ord(ps_targleft),  S_TRGT_01);   // 11
      end
      else if player.powers[Ord(pw_targeter)] and 16 <> 0 then // haleyjd 20110205: missing else
      begin
        P_SetPsprite(player, Ord(ps_targright), S_TRGT_02);  // 12
        P_SetPsprite(player, Ord(ps_targleft),  S_NULL);
      end;
    end;
  end;

  if player.powers[Ord(pw_invisibility)] > 0 then
  begin
    dec(player.powers[Ord(pw_invisibility)]);
    // villsa [STRIFE] remove mvis flag as well
    if player.powers[Ord(pw_invisibility)] = 0 then
      player.mo.flags := player.mo.flags and not (MF_SHADOW or MF_MVIS);
  end;

  if player.powers[Ord(pw_ironfeet)] > 0 then
  begin
    dec(player.powers[Ord(pw_ironfeet)]);

    // villsa [STRIFE] gasmask sound
    if TTickState.LevelTime and $3f = 0 then
      S_StartSound(player.mo, Ord(sfx_mask));
  end;

  if player.powers[Ord(pw_allmap)] > 1 then
    dec(player.powers[Ord(pw_allmap)]);

  // haleyjd 08/30/10: [STRIFE]
  // Nukage count keeps track of exposure to hazardous conditions over time.
  // After accumulating 16 total seconds or more of exposure, you will take
  // 5 damage roughly once per second until the count drops back under 560
  // tics.
  if player.nukagecount > 0 then
  begin
    dec(player.nukagecount);
    if TTickState.LevelTime and $1f = 0 then
      if player.nukagecount > 16 * TICRATE then
        P_DamageMobj(player.mo, nil, nil, 5);
  end;

  if player.damagecount > 0 then
    dec(player.damagecount);

  if player.bonuscount > 0 then
    dec(player.bonuscount);
end;

//==============================================================================
//
// TUserGameRules.Colormap
//
//==============================================================================
class procedure TUserGameRules.Colormap(const player: Pplayer_t);
begin
  // villsa [STRIFE] checks for extralight
  if player.extralight >= 0 then
  begin
    if player.cheats and CF_ONFIRE <> 0 then
      player.fixedcolormap := 1
    else
      player.fixedcolormap := 0;
  end
  else // Sigil shock:
    player.fixedcolormap := INVERSECOLORMAP;
end;

//==============================================================================
//
// TUserGameRules.AtEnd
//
//==============================================================================
class procedure TUserGameRules.AtEnd(const player: Pplayer_t);
begin
end;

end.

