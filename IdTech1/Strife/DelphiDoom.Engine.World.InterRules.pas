{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Strife for items and damage (p_inter)     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit DelphiDoom.Engine.World.InterRules;

interface

uses
  doomdef,
  sounddata,
  m_rnd,
  i_system,
  am_map,
  p_local,
  p_mobj_h,
  s_sound,
  d_player;

const
// a weapon is found with two clip loads,
// a big item has five clip loads
  maxammo: array[0..Ord(NUMAMMO) - 1] of integer = (250, 50, 25, 400, 100, 30, 16);
  clipammo: array[0..Ord(NUMAMMO) - 1] of integer = (10, 4, 2, 20, 4, 6, 4);

var
  p_maxhealth: integer = 200;
  p_soulspherehealth: integer = 100;
  p_megaspherehealth: integer = 200;
  p_medikithealth: integer = 25;
  p_stimpackhealth: integer = 10;
  p_bonushealth: integer = 1;
  p_maxarmor: integer = 200;
  p_greenarmorclass: integer = 1;
  p_bluearmorclass: integer = 2;

type
  /// <summary>
  ///   What Strife does in the item and damage code of p_inter (issue #185, step 2f-2). The routines that
  ///   are the same in the games are in IdTech1\Base\p_inter.pas; the ones that only this game has stay here
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TInterGameRules = class sealed
  public
    const
      /// <summary>P_GiveArmor accepts a negative armor type, that is given only to a player with no armor (Strife)</summary>
      AllowsNegativeArmor = True;
      /// <summary>P_GiveBody is the method GiveBody of the rules (Strife: the stamina and the medic of the Front)</summary>
      OwnsGiveBody = True;
      /// <summary>A dropped thing scatters on the floor with a random momentum from this engine version on (P_SpawnDroppedMobj)</summary>
      DroppedScatterVersion = VERSION207;

    /// <summary>The player touches a special thing (pickup); the body of P_TouchSpecialThing</summary>
    class procedure TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t); static;
    /// <summary>Damages both enemies and players; the body of P_DamageMobj</summary>
    class procedure DamageMobj(target, inflictor, source: Pmobj_t; damage: integer); static;
    /// <summary>The highest health a player can be given by P_GiveBody</summary>
    class function MaxPlayerHealth(player: Pplayer_t): integer; static;
    /// <summary>The game is in the compatibility mode: the dropped things do not fall</summary>
    class function NeedsCompatibility: boolean; static;
    /// <summary>The body of P_GiveBody when OwnsGiveBody</summary>
    class function GiveBody(player: Pplayer_t; num: integer): boolean; static;
  end;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TInterRoutines = class sealed
  public
    //==============================================================================
    //
    // P_GivePower
    //
    //==============================================================================
    class function P_GivePower(player: Pplayer_t; power: integer): boolean; static;

    //==============================================================================
    //
    // P_GiveCard
    //
    //==============================================================================
    class function P_GiveCard(player: Pplayer_t; card: card_t): boolean; static;

    //==============================================================================
    //
    // P_GiveAmmo
    //
    //==============================================================================
    class function P_GiveAmmo(player: Pplayer_t; ammo: ammotype_t; num: integer): boolean; static;

    //==============================================================================
    //
    // P_GiveWeapon
    //
    //==============================================================================
    class function P_GiveWeapon(player: Pplayer_t; weapon: weapontype_t; dropped: boolean): boolean; static;

    //==============================================================================
    //
    // P_KillMobj
    //
    //==============================================================================
    class procedure P_KillMobj(source: Pmobj_t; target: Pmobj_t); static;
  end;


implementation

uses
  c_cmds,
  d_delphi,
  d_check,
  deh_main,
  info_h,
  info,
  hu_stuff,
  f_finale,
  m_fixed,
  d_items,
  g_game,
  p_friends,
  p_common,
  p_mobj,
  p_obituaries,
  p_pspr,
  DelphiDoom.Engine.World.PspriteRules,
  p_pspr_h,
  p_dialog,
  p_doors,
  p_floor,
  p_spec_h,
  p_spec,
  p_enemy,
  DelphiDoom.Engine.World.EnemyRules,
  p_user,
  DelphiDoom.Engine.World.UserRules,
  ps_main, // JVAL: Script Events
  r_defs,
  r_main,
  udmf_spec,
  tables,
  p_inter,
  DelphiDoom.Engine.World.PickupGivers;

const
  BONUSADD = 6;

//==============================================================================
//
// GET STUFF
//
// P_GiveAmmo
// Num is the number of clip loads,
// not the individual count (0= 1/2 clip).
// Returns false if the ammo can't be picked up at all
//
//==============================================================================
class function TInterRoutines.P_GiveAmmo(player: Pplayer_t; ammo: ammotype_t; num: integer): boolean;
var
  oldammo: integer;
begin
  if ammo = am_noammo then
  begin
    result := false;
    exit;
  end;

  if (Ord(ammo) < 0) or (Ord(ammo) > Ord(NUMAMMO)) then
    I_Error('P_GiveAmmo(): bad type %d', [Ord(ammo)]);

  if player.ammo[Ord(ammo)] = player.maxammo[Ord(ammo)] then
  begin
    result := false;
    exit;
  end;

  if num <> 0 then
    num := num * clipammo[Ord(ammo)]
  else
    num := clipammo[Ord(ammo)] div 2;

  if (TGameSession.GameSkill = sk_baby) or (TGameSession.GameSkill = sk_nightmare) then
  begin
    // give double ammo in trainer mode,
    // you'll need in nightmare
    num := num * 2
  end;

  oldammo := player.ammo[Ord(ammo)];
  player.ammo[Ord(ammo)] := player.ammo[Ord(ammo)] + num;

  if player.ammo[Ord(ammo)] > player.maxammo[Ord(ammo)] then
    player.ammo[Ord(ammo)] := player.maxammo[Ord(ammo)];

  // If non zero ammo,
  // don't change up weapons,
  // player was lower on purpose.
  if oldammo <> 0 then
  begin
    result := true;
    exit;
  end;

  // We were down to zero,
  // so select a new weapon.
  // Preferences are not user selectable.

  // villsa [STRIFE] ammo update
  // where's the check for grenades? - haleyjd: verified no switch to grenades
  //   haleyjd 10/03/10: don't change to electric bow when picking up poison
  //   arrows.
  if Ord(player.readyweapon) = 0 then
  begin
    case ammo of
      am_bullets:
        begin
          if player.weaponowned[Ord(wp_rifle)] then
            player.pendingweapon := wp_rifle;
         end;

      am_elecbolts:
        begin
          if player.weaponowned[Ord(wp_elecbow)] then
            player.pendingweapon := wp_elecbow;
         end;

      am_cell:
        begin
          if player.weaponowned[Ord(wp_mauler)] then
            player.pendingweapon := wp_mauler;
        end;

      am_missiles:
        begin
          if player.weaponowned[Ord(wp_missile)] then
            player.pendingweapon := wp_missile;
        end;

    end;
  end;

  result := true;
end;

//==============================================================================
//
// P_GiveWeapon
// The weapon name may have a MF_DROPPED flag ored in.
//
// villsa [STRIFE] some stuff has been changed/moved around
//
//==============================================================================
class function TInterRoutines.P_GiveWeapon(player: Pplayer_t; weapon: weapontype_t; dropped: boolean): boolean;
var
  gaveammo: boolean;
  gaveweapon: boolean;
  ammo: ammotype_t;
begin
  // villsa [STRIFE] new code for giving alternate version
  // of the weapon to player
  if player.weaponowned[Ord(weapon)] then
    gaveweapon := false
  else
  begin
    gaveweapon := true;
    player.weaponowned[Ord(weapon)] := true;

    // Alternate "sister" weapons that you also get as a bonus:
    case weapon of
      wp_elecbow:
        player.weaponowned[Ord(wp_poisonbow)] := true;

      wp_hegrenade:
        player.weaponowned[Ord(wp_wpgrenade)] := true;

      wp_mauler:
        player.weaponowned[Ord(wp_torpedo)] := true;
    end;

    // check for the standard weapons only
    if (Ord(weapon) > Ord(player.readyweapon)) and (Ord(weapon) <= Ord(wp_sigil)) then
      player.pendingweapon := weapon;
  end;

  ammo := weaponinfo[Ord(weapon)].ammo;
  if TGameSession.NetGame and (TGameSession.DeathMatch <> 2) and not dropped then
  begin
  // leave placed weapons forever on net games
    if not gaveweapon then
    begin
      result := false;
      exit;
    end;

    player.bonuscount := player.bonuscount + BONUSADD;
    player.weaponowned[Ord(weapon)] := true;

    if TGameSession.DeathMatch <> 0 then
      P_GiveAmmo(player, ammo, 5)
    else
      P_GiveAmmo(player, ammo, 2);
    player.pendingweapon := weapon;

    if (player = @TGameSession.Players[TGameSession.ConsolePlayer]) then
      TSoundRoutines.S_StartSound(nil, Ord(sfx_wpnup));
    result := false;
    exit;
  end;

  if ammo <> am_noammo then
  begin
  // give one clip with a dropped weapon,
  // two clips with a found weapon
    if dropped then
      gaveammo := P_GiveAmmo(player, ammo, 1)
    else
      gaveammo := P_GiveAmmo(player, ammo, 2);
  end
  else
    gaveammo := false;

  result := gaveweapon or gaveammo;
end;

//==============================================================================
//
// P_GiveBody
// Returns false if the body isn't needed at all
//
// villsa [STRIFE] a lot of changes have been added for stamina
//
//==============================================================================
class function TInterGameRules.GiveBody(player: Pplayer_t; num: integer): boolean;
var
  maxhealth: integer;
  healing: integer;
  mo: Pmobj_t;
begin
  maxhealth := mobjinfo[Ord(MT_PLAYER)].spawnhealth + player.stamina;

  if num >= 0 then // haleyjd 20100923: fixed to give proper amount of health
  begin
    // any healing to do?
    if player.health >= maxhealth then
    begin
      result := false;
      exit;
    end;

    // give, and cap to maxhealth
    player.health := player.health + num;
    if player.health > maxhealth then // JVAL: Changed '>=' with '>'
      player.health := maxhealth;

    // Set mo->health for consistency.
    // haleyjd 20110225: Seems Strife can call this on a NULL player->mo
    // when giving items to players that are not in the game...
    mo := player.mo;
    if mo <> nil then
      mo.health := player.health;
  end
  else
  begin
    // [STRIFE] handle healing from the Front's medic
    // The amount the player's health will be set to scales up with stamina
    // increases.
    // Ex 1: On the wimpiest skill level, -100 is sent in. This restores
    //       full health no matter what your stamina.
    //       (100*100)/100 = 100
    //       (200*100)/100 = 200
    // Ex 2: On the most stringent skill levels, -50 is sent in. This will
    //       restore at most half of your health.
    //       (100*50)/100 = 50
    //       (200*50)/100 = 100
    healing := (-num * maxhealth) div mobjinfo[Ord(MT_PLAYER)].spawnhealth;

    // This is also the "threshold" of healing. You need less health than
    // the amount that will be restored in order to get any benefit.
    // So on the easiest skill you will always be fully healed.
    // On the hardest skill you must have less than 50 health, and will
    // only recover to 50 (assuming base stamina stat)
    if player.health >= healing then
    begin
      result := false;
      exit;
    end;

    // Set health. BUG: Oddly, mo->health is NOT set here...
    // JVAL: player.mo health will be restored in G_RiftPlayer
    player.health := healing;
    // JVAL: 20171217
    if G_PlayingEngineVersion >= VERSION204 then
    begin
      mo := player.mo;
      if mo <> nil then
        mo.health := player.health;
    end;
  end;

  result := true;
end;

//==============================================================================
//
// P_GiveCard
//
// [STRIFE] Modified to use larger bonuscount
//
//==============================================================================
class function TInterRoutines.P_GiveCard(player: Pplayer_t; card: card_t): boolean;
begin
  if player.cards[Ord(card)] then
  begin
    result := false;
    exit;
  end;

  player.bonuscount := BONUSADD * 2;
  player.cards[Ord(card)] := true;

  result := true;
end;

//==============================================================================
//
// P_GivePower
//
// [STRIFE] Modifications for new powerups
//
//==============================================================================
class function TInterRoutines.P_GivePower(player: Pplayer_t; power: integer): boolean;
begin
  // haleyjd 09/14/10: [STRIFE] moved to top, exception for Shadow Armor
  if (player.powers[power] <> 0) and (power <> Ord(pw_invisibility)) then
  begin
    result := false;  // already got it
    exit;
  end;

  // if giving pw_invisibility and player already has MVIS, no can do.
  if (power = Ord(pw_invisibility)) and (player.mo.flags and MF_MVIS <> 0) then
  begin
    result := false;
    exit;
  end;

  result := true;
  // villsa [STRIFE]
  if power = Ord(pw_targeter) then
  begin
    player.powers[power] := TARGTICS;
    P_SetPsprite(player, Ord(ps_targcenter), S_TRGT_00); // 10
    P_SetPsprite(player, Ord(ps_targleft),   S_TRGT_01); // 11
    P_SetPsprite(player, Ord(ps_targright),  S_TRGT_02); // 12

    player.psprites[Ord(ps_targcenter)].sx := (160 * FRACUNIT);
    player.psprites[Ord(ps_targleft)  ].sy := (100 * FRACUNIT);
    player.psprites[Ord(ps_targcenter)].sy := (100 * FRACUNIT);
    player.psprites[Ord(ps_targright) ].sy := (100 * FRACUNIT);
    exit;
  end;

  if power = Ord(pw_invisibility) then
  begin
    // if player already had this power...
    if player.powers[power] <> 0 then
    begin
      // remove SHADOW, give MVIS.
      player.mo.flags := player.mo.flags and not MF_SHADOW;
      player.mo.flags := player.mo.flags or MF_MVIS;
    end
    else // give SHADOW
      player.mo.flags := player.mo.flags or MF_SHADOW;

    // set tics if giving shadow, or renew them if MVIS.
    player.powers[power] := INVISTICS;

    exit;
  end;

  if power = Ord(pw_ironfeet) then
  begin
    player.powers[power] := IRONTICS;
    exit;
  end;

  if power = Ord(pw_strength) then
  begin
    P_GiveBody(player, 100);
    player.powers[power] := 1;
    exit;
  end;

  // villsa [STRIFE]
  if power = Ord(pw_allmap) then
  begin
    // remember in mapstate
    if TGameSession.GameMap < 40 then
      player.mapstate[TGameSession.GameMap] := true;

    player.powers[power] := 1;
    exit;
  end;

  // villsa [STRIFE]
  if power = Ord(pw_communicator) then
  begin
    player.powers[power] := 1;
    exit;
  end;

  // default behavior:
  player.powers[power] := 1;
end;

//==============================================================================
//
// P_TouchSpecialThing
//
//==============================================================================
class procedure TInterGameRules.TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
var
  player: Pplayer_t;
  i: integer;
  delta: fixed_t;
  sound: integer;
  pickupmsg: string;
begin
  delta := special.z - toucher.z;

  if (delta > toucher.height) or (delta < - 8 * FRACUNIT) then
  // out of reach
    exit;

  sound := Ord(sfx_itemup);
  player := toucher.player;

  // Dead thing touching.
  // Can happen with a sliding player corpse.
  if toucher.health <= 0 then
    exit;

  // villsa [STRIFE] damage toucher if special is spectral
  // haleyjd 09/21/10: corrected to test for SPECTRE thingtypes specifically
  if (special._type = Ord(MT_SPECTRE_A)) or
     (special._type = Ord(MT_SPECTRE_B)) or
     (special._type = Ord(MT_SPECTRE_C)) or
     (special._type = Ord(MT_SPECTRE_D)) or
     (special._type = Ord(MT_SPECTRE_E)) or
     (special._type = Ord(MT_ENTITY)) or
     (special._type = Ord(MT_SUBENTITY)) then
  begin
    P_DamageMobj(toucher, nil, nil, 5);
    exit;
  end;

  // villsa [STRIFE]
  pickupmsg := '';

  // Identify by sprite.
  // villsa [STRIFE] new items
  case special.sprite of
    // bullets
    Ord(SPR_BLIT): // haleyjd: fixed missing MF_DROPPED check
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_bullets, intval(special.flags and MF_DROPPED = 0)) then
          exit;
      end;

    // box of bullets
    Ord(SPR_BBOX):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_bullets, 5) then
          exit;
      end;

    // missile
    Ord(SPR_MSSL):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_missiles, 1) then
          exit;
      end;

    // box of missiles
    Ord(SPR_ROKT):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_missiles, 5) then
          exit;
      end;

    // battery
    Ord(SPR_BRY1):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_cell, 1) then
          exit;
      end;

    // cell pack
    Ord(SPR_CPAC):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_cell, 5) then
          exit;
      end;

    // poison bolts
    Ord(SPR_PQRL):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_poisonbolts, 5) then
          exit;
      end;

    // electric bolts
    Ord(SPR_XQRL):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_elecbolts, 5) then
          exit;
      end;

    // he grenades
    Ord(SPR_GRN1):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_hegrenades, 1) then
          exit;
      end;

    // wp grenades
    Ord(SPR_GRN2):
      begin
        if not TInterRoutines.P_GiveAmmo(player, am_wpgrenades, 1) then
          exit;
      end;

    // rifle
    Ord(SPR_RIFL):
      begin
        if not TInterRoutines.P_GiveWeapon(player, wp_rifle, special.flags and MF_DROPPED <> 0) then
          exit;
        sound := Ord(sfx_wpnup); // haleyjd: SHK-CHK!
      end;

    // flame thrower
    Ord(SPR_FLAM):
      begin
        if not TInterRoutines.P_GiveWeapon(player, wp_flame, false) then
          exit;
        // haleyjd: gives extra ammo.
        TInterRoutines.P_GiveAmmo(player, am_cell, 3);
        sound := Ord(sfx_wpnup); // haleyjd: SHK-CHK!
      end;

    // missile launcher
    Ord(SPR_MMSL):
      begin
        if TInterRoutines.P_GiveWeapon(player, wp_missile, false) then
          exit;
        sound := Ord(sfx_wpnup); // haleyjd: SHK-CHK!
      end;

    // grenade launcher
    Ord(SPR_GRND):
      begin
        if TInterRoutines.P_GiveWeapon(player, wp_hegrenade, special.flags and MF_DROPPED <> 0) then
          exit;
        sound := Ord(sfx_wpnup); // haleyjd: SHK-CHK!
      end;

    // mauler
    Ord(SPR_TRPD):
      begin
        if not TInterRoutines.P_GiveWeapon(player, wp_mauler, false) then
          exit;
        sound := Ord(sfx_wpnup); // haleyjd: SHK-CHK!
      end;

    // electric bolt crossbow
    Ord(SPR_CBOW):
      begin
        if not TInterRoutines.P_GiveWeapon(player, wp_elecbow, special.flags and MF_DROPPED <> 0) then
          exit;
        sound := Ord(sfx_wpnup); // haleyjd: SHK-CHK!
      end;

    // haleyjd 09/21/10: missed case: THE SIGIL!
    Ord(SPR_SIGL):
      begin
        if not TInterRoutines.P_GiveWeapon(player, wp_sigil, special.flags and MF_DROPPED <> 0) then
        begin
          player.sigiltype := special.frame;
          if special.special <> 0 then
          begin
            P_ExecuteActorSpecial(special.special, @special.args, toucher);
            special.special := 0;
          end;
          exit;
        end;

        if TGameSession.NetGame then
          player.sigiltype := 4;

        player.pendingweapon := wp_sigil;
        player.st_update := true;
        if TGameSession.DeathMatch <> 0 then
        begin
          if special.special <> 0 then
          begin
            P_ExecuteActorSpecial(special.special, @special.args, toucher);
            special.special := 0;
          end;
          exit;
        end;
        sound := Ord(sfx_wpnup);
      end;

    // backpack
    Ord(SPR_BKPK):
      begin
        if not player.backpack then
        begin
          for i := 0 to Ord(NUMAMMO) - 1 do
            player.maxammo[i] := player.maxammo[i] * 2;
          player.backpack := true;
        end;
        for i := 0 to Ord(NUMAMMO) - 1 do
          TInterRoutines.P_GiveAmmo(player, ammotype_t(i), 1);
      end;

    // 1 Gold
    Ord(SPR_COIN):
      begin
        P_GiveInventoryItem(player, Ord(SPR_COIN), MT_MONY_1);
      end;

    // 10 Gold
    Ord(SPR_CRED):
      begin
        for i := 0 to 9 do
          P_GiveInventoryItem(player, Ord(SPR_COIN), MT_MONY_1);
      end;

    // 25 Gold
    Ord(SPR_SACK):
      begin
        // haleyjd 09/21/10: missed code: if a SPR_SACK object has negative
        // health, it will give that much gold - STRIFE-TODO: verify
        if special.health < 0 then
        begin
          for i := 1 to -special.health do
            P_GiveInventoryItem(player, Ord(SPR_COIN), MT_MONY_1);
        end
        else
        begin
          for i := 0 to 24 do
            P_GiveInventoryItem(player, Ord(SPR_COIN), MT_MONY_1);
        end;
      end;

    // 50 Gold
    Ord(SPR_CHST):
      begin
        for i := 0 to 49 do
          P_GiveInventoryItem(player, Ord(SPR_COIN), MT_MONY_1);
      end;

    // Leather Armor
    Ord(SPR_ARM1):
      begin
        if not P_GiveArmor(player, -2) then
          if not P_GiveInventoryItem(player, special.sprite, mobjtype_t(special._type)) then
            pickupmsg := '!';
      end;

    // Metal Armor
    Ord(SPR_ARM2):
      begin
        if not P_GiveArmor(player, -1) then
          if not P_GiveInventoryItem(player, special.sprite, mobjtype_t(special._type)) then
            pickupmsg := '!';
      end;

    // All-map powerup
    Ord(SPR_PMAP):
      begin
        if not TInterRoutines.P_GivePower(player, Ord(pw_allmap)) then
          exit;
        sound := Ord(sfx_yeah);
      end;

    // The Comm Unit - because you need Blackbird whining in your ear the
    // whole time and telling you how lost she is :P
    Ord(SPR_COMM):
      begin
        if not TInterRoutines.P_GivePower(player, Ord(pw_communicator)) then
          exit;
        sound := Ord(sfx_yeah);
      end;

    // haleyjd 09/21/10: missed case - Shadow Armor; though, I do not know why
    // this has a case distinct from generic inventory items... Maybe it started
    // out as an auto-use-if-possible item much like regular armor...
    Ord(SPR_SHD1):
      begin
        if not P_GiveInventoryItem(player, Ord(SPR_SHD1), mobjtype_t(special._type)) then
          pickupmsg := '!';
      end;

    // villsa [STRIFE] check default items
    //Ord(SPR_TOKN):
    else
      begin
        if (special._type >= Ord(MT_KEY_BASE)) and (special._type <= Ord(MT_NEWKEY5)) then
        begin
          // haleyjd 09/21/10: Strife player still picks up keys that
          // he has already found. (break, not return)
          TInterRoutines.P_GiveCard(player, card_t(special._type - Ord(MT_KEY_BASE)));
        end
        else
        begin
          if not P_GiveInventoryItem(player, special.sprite, mobjtype_t(special._type)) then
            pickupmsg := '!';
        end;
      end;
  end;

  // villsa [STRIFE] set message
  if pickupmsg = '' then
  begin
    if special.info.name2 <> '' then
      pickupmsg := 'You picked up the ' + special.info.name2 + '.'
    else
      pickupmsg := 'You picked up the item.';
  end
  // use the first character to indicate that the player is full on items
  else if pickupmsg = '!' then
  begin
    player._message := 'You cannot hold any more.';
    exit;
  end;

  if special.flags and MF_GIVEQUEST <> 0 then
  begin
    // [STRIFE]: Award quest flag based on the thing's speed. Quest 8 was
    // apparently at some point given by the Broken Power Coupling, which is
    // why they don't want to award it if you have Quest 6 (which is
    // acquired by destroying the Front's working power coupling). BUT, the
    // broken coupling object's speed is NOT 8... it is 512*FRACUNIT. For
    // strict portability beyond the x86, we need to AND the operand by 31.
    if (special.info.speed <> 8) or (player.questflags and QF_QUEST6 = 0) then
      player.questflags := player.questflags or _SHLW(1, (special.info.speed - 1) and 31);
  end;

  if special.special <> 0 then
  begin
    P_ExecuteActorSpecial(special.special, @special.args, toucher);
    special.special := 0;
  end;

  P_RemoveMobj(special);
  player.bonuscount := player.bonuscount + BONUSADD;
  player._message := pickupmsg;
  if player = @TGameSession.Players[TGameSession.ConsolePlayer] then
    TSoundRoutines.S_StartSound(nil, sound);
end;

//==============================================================================
// P_KillMobj
//
// KillMobj
//
//==============================================================================
class procedure TInterRoutines.P_KillMobj(source: Pmobj_t; target: Pmobj_t);
var
  item: integer;
  gibhealth: integer;
  plrkilledmsg: string;
  amount, r: integer;
  mo, loot: Pmobj_t;
  junk: line_t;
  p: Pplayer_t;
  i: integer;
  zpos: integer;
begin
  target.flags := target.flags and not (MF_SHOOTABLE or MF_FLOAT or MF_BOUNCE);
  if target.flags3_ex and MF3_EX_SETGRAVITYONDEATH <> 0 then
    target.flags := target.flags and not MF_NOGRAVITY;

  target.flags3_ex := target.flags3_ex and not MF3_EX_BOUNCE;

  target.flags := target.flags or (MF_CORPSE or MF_DROPOFF);
  target.height := FRACUNIT;  // villsa [STRIFE] set to fracunit instead of >>= 2

  P_ExecuteActorSpecial(target.special, @target.args, target);

  if (source <> nil) and (source.player <> nil) then
  begin
    // count for intermission
    p := source.player;
    if target.flags and MF_COUNTKILL <> 0 then
      p.killcount := p.killcount + 1;

    if target.player <> nil then
    begin
      p.frags[pDiff(target.player, @TGameSession.Players[0], SizeOf(TGameSession.Players[0]))] :=
        p.frags[pDiff(target.player, @TGameSession.Players[0], SizeOf(TGameSession.Players[0]))] + 1;
      if TGameSession.NetGame then
      begin
        sprintf(plrkilledmsg, TDehMainRoutines.DEH_GetString('%s killed %s'),
          [player_names[p.allegiance], player_names[Pplayer_t(target.player).allegiance]]);
        TGameSession.Players[TGameSession.ConsolePlayer]._message := plrkilledmsg;
      end;
    end;
  end
  else if not TGameSession.NetGame and (target.flags and MF_COUNTKILL <> 0) then
  begin
    // count all monster deaths,
    // even those caused by other monsters
    TGameSession.Players[0].killcount := TGameSession.Players[0].killcount + 1;
  end;

  p := target.player;
  if p <> nil then
  begin
    // count environment kills against you
    if source = nil then
      p.frags[pDiff(target.player, @TGameSession.Players[0], SizeOf(TGameSession.Players[0]))] :=
        p.frags[pDiff(target.player, @TGameSession.Players[0], SizeOf(TGameSession.Players[0]))] + 1;

    if (TGameSession.GameMap = 29) and not TGameSession.NetGame then
    begin
      // haleyjd 09/13/10: [STRIFE] Give player the bad ending.
      TFinaleRoutines.F_StartFinale();
      exit;
    end;

    // villsa [STRIFE] spit out inventory items when killed
    if TGameSession.NetGame then
    begin
      while true do
      begin
        if p.inventory[0].amount <= 0 then
          break;

        item := p.inventory[0]._type;
        if item = Ord(MT_MONY_1) then
        begin
          loot := P_SpawnMobj(target.x, target.y, target.z + (24 * FRACUNIT), Ord(MT_MONY_25));

          // [STRIFE] TODO - what the hell is it doing here?
          loot.health := -p.inventory[0].amount;
          amount := p.inventory[0].amount;
        end
        else
        begin
          loot := P_SpawnMobj(target.x, target.y, target.z + (24 * FRACUNIT), item);
          amount := 1;
        end;

        TUserRoutines.P_RemoveInventoryItem(p, 0, amount);
        r := P_Random;
        loot.momx := loot.momx + ((r and 7) - (P_Random and 7)) * FRACUNIT;
        loot.momy := loot.momy + ((P_Random and 7) + 1) * FRACUNIT;
        loot.flags := loot.flags or MF_DROPPED;
      end;
    end;

    target.flags := target.flags and not MF_SOLID;
    p.playerstate := PST_DEAD;
    p.mo.momz := 5 * FRACUNIT;  // [STRIFE]: small hop!

    // JVAL
    // Save the attacker coordinates
    if p.attacker <> nil then
    begin
      p.attackerx := p.attacker.x;
      p.attackery := p.attacker.y;
    end;

    P_DropWeapon(p);

    if (p = @TGameSession.Players[TGameSession.ConsolePlayer]) and (amstate = am_only) then
    begin
      // don't die in auto map,
      // switch view prior to dying
      amstate := am_inactive;
      AM_Stop;
    end;

  end;

  // villsa [STRIFE] some modifications to setting states
  if target.state <> @states[Ord(S_BURN_23)] then
  begin
    if target.health = -6666 then
      P_SetMobjState(target, S_DISR_00)  // 373
    else
    begin
      gibhealth := target.info.gibhealth;
      if gibhealth >= 0 then
        gibhealth := -target.info.spawnhealth;

      if (target.health < gibhealth) and (target.info.xdeathstate <> 0) then
        P_SetMobjState(target, statenum_t(target.info.xdeathstate))
      else
        P_SetMobjState(target, statenum_t(target.info.deathstate));
    end;
  end;
  if target.player <> nil then    // JVAL: Script Events
    PS_EventPlayerDied(pDiff(@TGameSession.Players[0], target.player, SizeOf(player_t)), source);
  PS_EventActorDied(target, source); // JVAL: Script Events

  // Drop stuff.
  // This determines the kind of object spawned
  // during the death frame of a thing.
  // villsa [STRIFE] get item from dialog target
// JVAL: Check if dropitem is set to drop a custom item.
  if target.flags2_ex and MF2_EX_CUSTOMDROPITEM <> 0 then
  begin
    item := target.dropitem;

// JVAL: 20200301 - Fix P_SpawnDroppedMobj() bug
    if item <= 0 then
      Exit;
  end
  else
  begin
    item := P_DialogFind(mobjtype_t(target._type), target.miscdata).dropitem;

    // JVAL: Check if dropitem is set, to drop a custom item.
    if item = 0 then
      if target.info.dropitem > 0 then
        item := target.info.dropitem;

    if item = 0 then
    begin
      // villsa [STRIFE] drop default items
      case target._type of
        Ord(MT_GUARD5):
          begin
            if teaser = 1 then
              item := Ord(MT_KEY_TRAVEL);
          end;
        Ord(MT_ORACLE):
          begin
            item := Ord(MT_MEAT);
          end;

        Ord(MT_PROGRAMMER):
          begin
            item := Ord(MT_SIGIL_A);
          end;

        Ord(MT_PRIEST):
          begin
            item := Ord(MT_JUNK);
          end;

        Ord(MT_BISHOP):
          begin
            item := Ord(MT_AMINIBOX);
          end;

        Ord(MT_PGUARD),
        Ord(MT_CRUSADER):
          begin
            item := Ord(MT_ACELL);
          end;

        Ord(MT_RLEADER):
          begin
            item := Ord(MT_AAMMOBOX);
          end;

        Ord(MT_GUARD1),
        Ord(MT_REBEL1),
        Ord(MT_SHADOWGUARD):
          begin
            item := Ord(MT_ACLIP);
          end;

        Ord(MT_SPECTRE_B):
          begin
            item := Ord(MT_SIGIL_B);
          end;

        Ord(MT_SPECTRE_C):
          begin
            item := Ord(MT_SIGIL_C);
          end;

        Ord(MT_SPECTRE_D):
          begin
            item := Ord(MT_SIGIL_D);
          end;

        Ord(MT_SPECTRE_E):
          begin
            item := Ord(MT_SIGIL_E);
          end;

        Ord(MT_COUPLING):
          begin
            junk.tag := 225;
            TDoorRoutines.EV_DoDoor(@junk, vld_close);

            junk.tag := 44;
            EV_DoFloor(@junk, lowerFloor);

            P_GiveVoiceObjective('VOC13', 'LOG13', 0);

            item := Ord(MT_COUPLING_BROKEN);
            TGameSession.Players[0].questflags := TGameSession.Players[0].questflags or _SHLW(1, mobjinfo[Ord(MT_COUPLING)].speed - 1);
          end;

        else
          exit;

      end;
    end;
  end;

  // handle special case for scripted target's dropped item
  case item of
    Ord(MT_TOKEN_SHOPCLOSE):
      begin
        junk.tag := 222;
        TDoorRoutines.EV_DoDoor(@junk, vld_close);
        P_NoiseAlert(TGameSession.Players[0].mo, TGameSession.Players[0].mo);

        if TGameSession.DeathMatch <> 0 then
        begin
          plrkilledmsg := TDehMainRoutines.DEH_GetString('You''re dead!  You set off the alarm.');
          TGameSession.Players[TGameSession.ConsolePlayer]._message := plrkilledmsg;
        end;

        exit;
      end;

    Ord(MT_TOKEN_PRISON_PASS):
      begin
        junk.tag := 223;
        TDoorRoutines.EV_DoDoor(@junk, vld_open);
        exit;
      end;

    Ord(MT_TOKEN_DOOR3):
      begin
        junk.tag := 224;
        TDoorRoutines.EV_DoDoor(@junk, vld_open);
        exit;
      end;

    Ord(MT_SIGIL_A),
    Ord(MT_SIGIL_B),
    Ord(MT_SIGIL_C),
    Ord(MT_SIGIL_D),
    Ord(MT_SIGIL_E):
      begin
        for i := 0 to MAXPLAYERS - 1 do
        begin
          if not P_GiveWeapon(@TGameSession.Players[i], wp_sigil, false) then
          begin
            inc(TGameSession.Players[i].sigiltype);
            if TGameSession.Players[i].sigiltype > 4 then
              TGameSession.Players[i].sigiltype := 4;
          end;

          // haleyjd 20110225: fixed these two assignments which Watcom munged
          // up in the assembly by pre-incrementing the pointer into players[]
          TGameSession.Players[i].st_update := true;
          TGameSession.Players[i].pendingweapon := wp_sigil;
        end;
        exit;
      end;

    Ord(MT_TOKEN_ALARM):
      begin
        P_NoiseAlert(TGameSession.Players[0].mo, TGameSession.Players[0].mo);

        if TGameSession.DeathMatch <> 0 then
        begin
          plrkilledmsg := TDehMainRoutines.DEH_GetString('You Fool!  You''ve set off the alarm');
          TGameSession.Players[TGameSession.ConsolePlayer]._message := plrkilledmsg;
          exit;
        end;
      end;

  end;

  // villsa [STRIFE] toss out item
  if (TGameSession.DeathMatch = 0) or (mobjinfo[item].flags and MF_NOTDMATCH = 0) then
  begin
    if target.flags4_ex and MF4_EX_ABSOLUTEDROPITEMPOS <> 0 then
      zpos := target.z
    else
      zpos := target.z + 24 * FRACUNIT;

    mo := P_SpawnMobj(target.x, target.y, zpos, item);
    r := P_Random;
    mo.momx := mo.momx + ((r and 7) - (P_Random and 7)) * FRACUNIT;
    r := P_Random;
    mo.momy := mo.momy + ((r and 7) - (P_Random and 7)) * FRACUNIT;
    mo.flags := mo.flags or (MF_SPECIAL or MF_DROPPED);   // special versions of items
  end;
end;

//==============================================================================
//
// P_DamageMobj
// Damages both enemies and players
// "inflictor" is the thing that caused the damage
//  creature or missile, can be NULL (slime, etc)
// "source" is the thing to target after taking damage
//  creature or NULL
// Source and inflictor are the same for melee attacks.
// Source can be NULL for slime, barrel explosions
// and other environmental stuff.
//
// [STRIFE] Extensive changes for spectrals, fire damage, disintegration, and
//  a plethora of mobjtype-specific hacks.
//
//==============================================================================
class procedure TInterGameRules.DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);
var
  ang: angle_t;
  saved: integer;
  tp, player: Pplayer_t;
  thrust: fixed_t;
  mass: integer;
  ignore: boolean;
begin
  if target.flags and MF_SHOOTABLE = 0 then
  begin
  // 19/9/2009 JVAL: Display a warning message for debugging
    I_DevWarning('P_DamageMobj(): Trying to damage unshootable mobj "%s"'#13#10, [target.info.name]);
//    target.tics := -1;
    exit; // shouldn't happen...
  end;

  // JVAL: Invulnerable monsters
  if target.flags_ex and MF_EX_INVULNERABLE <> 0 then
    exit;

  if target.flags2_ex and MF2_EX_NODAMAGE <> 0 then
    exit;

  if target.health <= 0 then
    exit;

  if not P_DamageFlagFilter(target, inflictor, damage) then
    exit;

  player := target.player;
  if (player <> nil) and (TGameSession.GameSkill = sk_baby) then
    damage := damage div 2; // take half damage in trainer mode

  if (inflictor <> nil) and (target.flags_ex and MF_EX_FIRERESIST <> 0) then
  begin
    if damage > 1 then
      damage := damage div 2;
  end;

  // Some close combat weapons should not
  // inflict thrust and push the victim out of reach,
  // thus kick away unless using the chainsaw.
  if (inflictor <> nil) and (target.flags and MF_NOCLIP = 0) and
    ((source = nil) or (source.player = nil) or (Pplayer_t(source.player).readyweapon <> wp_flame)) then
  begin
    ang := TRendererMain.R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y);

    mass := target.mass;
    if mass = 0 then
    begin
      I_DevWarning('P_DamageMobj(): Target (%s) mass is zero'#13#10, [target.info.name]);
      thrust := 0;
    end
    else
      thrust := (damage * $2000 * 100) div mass;

    // make fall forwards sometimes
    if (damage < 40) and (damage > target.health) and
       (target.z - inflictor.z > 64 * FRACUNIT) and (P_Random and 1 <> 0) then
    begin
      ang := ang + ANG180;
      thrust := thrust * 4;
    end;

    {$IFDEF FPC}
    ang := _SHRW(ang, ANGLETOFINESHIFT);
    {$ELSE}
    ang := ang shr ANGLETOFINESHIFT;
    {$ENDIF}
    target.momx := target.momx + FixedMul(thrust, finecosine[ang]);
    target.momy := target.momy + FixedMul(thrust, finesine[ang]);
  end;

  // player specific
  if player <> nil then
  begin
    // end of game hell hack
    if (Psubsector_t(target.subsector).sector.special = 11) and (damage >= target.health) then
      damage := target.health - 1;

    // Below certain threshold,
    // ignore damage in GOD mode
    // villsa [STRIFE] removed pw_invulnerability check
    if (damage < 1000) and
       (player.cheats and CF_GODMODE <> 0) then
      exit;

      // villsa [STRIFE] flame attacks don't damage player if wearing envirosuit
      if (player.powers[Ord(pw_ironfeet)] <> 0) and (inflictor <> nil) then
      begin
        if (inflictor._type = Ord(MT_SFIREBALL)) or
           (inflictor._type = Ord(MT_C_FLAME)) or
           (inflictor._type = Ord(MT_PFLAME)) then
          damage := 0;
      end;

    if player.armortype <> 0 then
    begin
      if player.armortype = 1 then
        saved := damage div 3
      else
        saved := damage div 2;

      if player.armorpoints <= saved then
      begin
        // armor is used up
        saved := player.armorpoints;
        player.armortype := 0;

        // villsa [STRIFE]
        TUserRoutines.P_UseInventoryItem(player, Ord(SPR_ARM1));
        TUserRoutines.P_UseInventoryItem(player, Ord(SPR_ARM2));
      end;
      player.armorpoints := player.armorpoints - saved;
      damage := damage - saved;
    end;
    player.health := player.health - damage;  // mirror mobj health here for Dave

    player.attacker := source;
    player.damagecount := player.damagecount + damage;  // add damage after armor / invuln

    if player.damagecount > 100 then
      player.damagecount := 100;  // teleport stomp does 10k points...

    player.hardbreathtics := player.damagecount * 10;
  end;

  // do the damage
  target.health := target.health - damage;

  // villsa [STRIFE] auto use medkits
  if player <> nil then
    if player.health < 50 then
      if (TGameSession.DeathMatch <> 0) or (player.cheats and CF_AUTOHEALTH <> 0) then
      begin
        while (player.health < 50) and (TUserRoutines.P_UseInventoryItem(player, Ord(SPR_MDKT))) do begin end;
        while (player.health < 50) and (TUserRoutines.P_UseInventoryItem(player, Ord(SPR_STMP))) do begin end;
      end;

  if target.health <= 0 then
  begin
    // villsa [STRIFE] grenades hurt... OUCH
    if (inflictor <> nil) and (inflictor._type = Ord(MT_HEGRENADE)) then
      target.health := -target.info.spawnhealth
    else if target.flags and MF_NOBLOOD = 0 then
    begin
      // villsa [STRIFE] disintegration death
      if inflictor <> nil then
        if (inflictor._type = Ord(MT_STRIFEPUFF3)) or
           (inflictor._type = Ord(MT_L_LASER)) or
           (inflictor._type = Ord(MT_TORPEDO)) or
           (inflictor._type = Ord(MT_TORPEDOSPREAD)) then
        begin
          TSoundRoutines.S_StartSound(target, Ord(sfx_dsrptr));
          target.health := -6666;
        end;
    end;

    // villsa [STRIFE] flame death stuff
    if (target.flags and MF_NOBLOOD = 0) and
       (inflictor <> nil) and (
                (inflictor._type = Ord(MT_SFIREBALL)) or
                (inflictor._type = Ord(MT_C_FLAME)) or
                (inflictor._type = Ord(MT_PFLAME)) ) then
    begin
      target.flags := target.flags and not (MF_SHOOTABLE or MF_FLOAT or MF_SHADOW or MF_MVIS);
      tp := target.player;
      if tp <> nil then
      begin
        tp.cheats := tp.cheats or CF_ONFIRE;
        tp.powers[Ord(pw_communicator)] := 0;
        tp.readyweapon := wp_fist;
        P_SetPsprite(tp, Ord(ps_weapon), S_WAVE_00); // 02
        P_SetPsprite(tp, Ord(ps_flash), S_NULL);
      end;

      P_SetMobjState(target, S_BURN_00);  // 349
      TSoundRoutines.S_StartSound(target, Ord(sfx_burnme));

      exit;
    end;

    TInterRoutines.P_KillMobj(source, target);
    P_Obituary(target, inflictor, source);
    exit;
  end;

  // villsa [STRIFE] set crash state
  if (target.health <= 6) and (target.info.crashstate <> 0) then
  begin
    P_SetMobjState(target, statenum_t(target.info.crashstate));
    exit;
  end;

  if damage <> 0 then
    if P_Random < target.painchance then
    begin
      target.flags := target.flags or MF_JUSTHIT; // fight back!
      P_SetMobjState(target, statenum_t(target.info.painstate));
    end;

  target.reactiontime := 0; // we're awake now...

  if source <> nil then
    if (target._type <> Ord(MT_PROGRAMMER)) and
       ((target.threshold = 0) or (target.flags4_ex and MF4_EX_NOTHRESHOLD <> 0)) and
       (source <> target) and
       (source.flags4_ex and MF4_EX_DMGIGNORED = 0) and
       ((source.flags and MF_ALLY) <> (target.flags and MF_ALLY)) then
    begin
      // if not intent on another player,
      // chase after this one
      if G_PlayingEngineVersion >= VERSION207 then
        ignore := P_BothFriends(target, source) or TCommonFriendActions.P_InfightingImmune(target, source)
      else
        ignore := false;

      if (target.flags2_ex and MF2_EX_DONTINFIGHTMONSTERS = 0) and not ignore then
      begin
        target.target := source;
        target.threshold := BASETHRESHOLD;
        if (target.state = @states[target.info.spawnstate]) and
           (target.info.seestate <> Ord(S_NULL)) then
          P_SetMobjState(target, statenum_t(target.info.seestate));
      end;
    end;

end;

//==============================================================================
//
// TInterGameRules.MaxPlayerHealth
//
//==============================================================================
class function TInterGameRules.MaxPlayerHealth(player: Pplayer_t): integer;
begin
  result := mobjinfo[Ord(MT_PLAYER)].spawnhealth + player.stamina;
end;

//==============================================================================
//
// TInterGameRules.NeedsCompatibility
//
//==============================================================================
class function TInterGameRules.NeedsCompatibility: boolean;
begin
  result := G_NeedsCompatibilityMode;
end;

end.

