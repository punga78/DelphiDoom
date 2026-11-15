{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Heretic for the player (p_user)           }
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
  doomdef,
  d_player,
  m_fixed,
  tables,
  d_ticcmd;

type
  /// <summary>
  ///   What Heretic does in the player code of p_user (issue #185, step 2f-1). The routines that
  ///   are the same in the games are in Base\p_user.pas; the ones that only this game has stay here
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
      SlopesFloorMargin = 4 * FRACUNIT;
      /// <summary>P_DeathThink is a method of the rules (Hexen: the skull and the ice chunk, the poison, the palette, the reborn state)</summary>
      OwnsDeathThink = False;
      /// <summary>The jump and the crouch work out of the new engine too (Strife); the other games run them only in it</summary>
      JumpsAlways = False;
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

//==============================================================================
//
// P_PlayerNextArtifact
//
//==============================================================================
procedure P_PlayerNextArtifact(player: Pplayer_t);

//==============================================================================
//
// P_PlayerUseArtifact
//
//==============================================================================
procedure P_PlayerUseArtifact(player: Pplayer_t; arti: artitype_t);

//==============================================================================
//
// P_GetPlayerNum
//
//==============================================================================
function P_GetPlayerNum(player: Pplayer_t): integer;

//==============================================================================
//
// P_UndoPlayerChicken
//
//==============================================================================
function P_UndoPlayerChicken(player: Pplayer_t): boolean;

//==============================================================================
//
// P_UseArtifact
//
//==============================================================================
function P_UseArtifact(player: Pplayer_t; arti: artitype_t): boolean;

//==============================================================================
//
// P_PlayerRemoveArtifact
//
//==============================================================================
procedure P_PlayerRemoveArtifact(player: Pplayer_t; slot: integer);

implementation

uses
  d_delphi,
  d_event,
  info_h,
  info,
  m_rnd,
{$IFDEF DEBUG}
  i_io,
{$ENDIF}
  g_game,
  p_common,
  p_mobj_h,
  p_mobj,
  DelphiDoom.Engine.World.MobjRules,
  p_tick,
  p_pspr,
  p_local,
  p_playertrace,
  p_friends,
  p_setup,    // JVAL: 3d Floors
  p_slopes,   // JVAL: Slopes
  p_3dfloors, // JVAL: Slopes
  p_spec,
  p_map,
  p_telept,
  p_inter,
  r_main,
  r_defs,
  sb_bar,
  sounddata,
  s_sound,
  p_user,
  DelphiDoom.Engine.World.PlayerThinker,
  DelphiDoom.Engine.World.PlayerColormap;


//----------------------------------------------------------------------------
//
// PROC P_ChickenPlayerThink
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_ChickenPlayerThink(player: Pplayer_t);
var
  pmo: Pmobj_t;
begin
  if player.health > 0 then
  begin // Handle beak movement
    P_UpdateBeak(player, @player.psprites[ps_weapon]);
  end;

  if player.chickenTics and 15 <> 0 then
    exit;

  pmo := player.mo;
  if (pmo.momx + pmo.momy = 0) and (P_Random < 160) then
  begin // Twitch view angle
    pmo.angle := pmo.angle + _SHLW(P_Random - P_Random, 19);
  end;

  if (pmo.z <= pmo.floorz) and (P_Random < 32) then
  begin // Jump and noise
    pmo.momz := pmo.momz + FRACUNIT;
    P_SetMobjState(pmo, S_CHICPLAY_PAIN);
    exit;
  end;

  if P_Random < 48 then // Just noise
    S_StartSound(pmo, Ord(sfx_chicact));
end;

//----------------------------------------------------------------------------
//
// PROC P_ArtiTele
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_ArtiTele(player: Pplayer_t);
var
  i: integer;
  selections: integer;
  destX: fixed_t;
  destY: fixed_t;
  destAngle: angle_t;
begin
  if deathmatch <> 0 then
  begin
    selections := deathmatch_p;
    i := P_Random mod selections;
    destX := deathmatchstarts[i].x * FRACUNIT;
    destY := deathmatchstarts[i].y * FRACUNIT;
    if player.mo.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
      destAngle := ANG1 * deathmatchstarts[i].angle
    else
      destAngle := ANG45 * (deathmatchstarts[i].angle div 45);
  end
  else
  begin
    destX := playerstarts[0].x * FRACUNIT;
    destY := playerstarts[0].y * FRACUNIT;
    if player.mo.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
      destAngle := ANG1 * playerstarts[0].angle
    else
      destAngle := ANG45 * (playerstarts[0].angle div 45);
  end;
  P_Teleport(player.mo, destX, destY, destAngle);
  S_StartSound(nil, Ord(sfx_wpnup)); // Full volume laugh
end;

//----------------------------------------------------------------------------
//
// PROC P_PlayerNextArtifact
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_PlayerNextArtifact(player: Pplayer_t);
begin
  if player = @players[consoleplayer] then
  begin
    dec(inv_ptr);
    if inv_ptr < 6 then
    begin
      dec(curpos);
      if curpos < 0 then
        curpos := 0;
    end;
    if inv_ptr < 0 then
    begin
      inv_ptr := player.inventorySlotNum - 1;
      if inv_ptr < 6 then
        curpos := inv_ptr
      else
        curpos := 6;
    end;

    player.readyArtifact := artitype_t(player.inventory[inv_ptr]._type);
  end;
end;

//----------------------------------------------------------------------------
//
// PROC P_PlayerRemoveArtifact
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_PlayerRemoveArtifact(player: Pplayer_t; slot: integer);
var
  i: integer;
begin
  dec(player.artifactCount);
  dec(player.inventory[slot].count);
  if player.inventory[slot].count = 0 then
  begin // Used last of a type - compact the artifact list
    player.readyArtifact := arti_none;
    player.inventory[slot]._type := Ord(arti_none);
    for i := slot + 1 to player.inventorySlotNum - 1 do
      player.inventory[i - 1] := player.inventory[i];

    dec(player.inventorySlotNum);
    if player = @players[consoleplayer] then
    begin // Set position markers and get next readyArtifact
      dec(inv_ptr);
      if inv_ptr < 6 then
      begin
        dec(curpos);
        if curpos < 0 then
          curpos := 0;
      end;
      if inv_ptr >= player.inventorySlotNum then
        inv_ptr := player.inventorySlotNum - 1;
      if inv_ptr < 0 then
        inv_ptr := 0;
      player.readyArtifact := artitype_t(player.inventory[inv_ptr]._type);
    end;
  end;
end;

//----------------------------------------------------------------------------
//
// PROC P_PlayerUseArtifact
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_PlayerUseArtifact(player: Pplayer_t; arti: artitype_t);
var
  i: integer;
begin
  for i := 0 to player.inventorySlotNum - 1 do
  begin
    if player.inventory[i]._type = Ord(arti) then
    begin // Found match - try to use
      if P_UseArtifact(player, arti) then
      begin // Artifact was used - remove it from inventory
        P_PlayerRemoveArtifact(player, i);
        if player = @players[consoleplayer] then
        begin
          S_StartSound(nil, Ord(sfx_artiuse));
          ArtifactFlash := 4;
        end
      end
      else // Unable to use artifact, advance pointer
        P_PlayerNextArtifact(player);
      break;
    end;
  end;
end;

//----------------------------------------------------------------------------
//
// FUNC P_UseArtifact
//
// Returns true if artifact was used.
//
//----------------------------------------------------------------------------
//
//==============================================================================
function P_UseArtifact(player: Pplayer_t; arti: artitype_t): boolean;
var
  mo: Pmobj_t;
  angle: angle_t;
  offs: integer;
begin
  case arti of
    arti_invulnerability:
      begin
        if not P_GivePower(player, Ord(pw_invulnerability)) then
        begin
          result := false;
          exit;
        end;
      end;
    arti_invisibility:
      begin
        if not P_GivePower(player, Ord(pw_invisibility)) then
        begin
          result := false;
          exit;
        end;
      end;
    arti_health:
      begin
        if not P_GiveBody(player, 25) then
        begin
          result := false;
          exit;
        end;
      end;
    arti_superhealth:
      begin
        if not P_GiveBody(player, 100) then
        begin
          result := false;
          exit;
        end;
      end;
    arti_tomeofpower:
      begin
        if player.chickenTics <> 0 then
        begin // Attempt to undo chicken
          if P_UndoPlayerChicken(player) = false then
            P_DamageMobj(player.mo, nil, nil, 10000)
          else
          begin // Succeeded
            player.chickenTics := 0;
            S_StartSound(player.mo, Ord(sfx_wpnup));
          end;
        end
        else
        begin
          if not P_GivePower(player, Ord(pw_weaponlevel2)) then
          begin
            result := false;
            exit;
          end;

          if player.readyweapon = wp_staff then
            P_SetPsprite(player, ps_weapon, S_STAFFREADY2_1)
          else if player.readyweapon = wp_gauntlets then
            P_SetPsprite(player, ps_weapon, S_GAUNTLETREADY2_1);
        end;
      end;
    arti_torch:
      begin
        if not P_GivePower(player, Ord(pw_infrared)) then
        begin
          result := false;
          exit;
        end;
      end;
    arti_firebomb:
      begin
        angle := player.mo.angle shr ANGLETOFINESHIFT;
        if player.mo.flags2 and MF2_FEETARECLIPPED <> 0 then
          offs := 1
        else
          offs := 0;
        mo := P_SpawnMobj(player.mo.x + 24 * finecosine[angle],
                          player.mo.y + 24 * finesine[angle],
                          player.mo.z - 15 * FRACUNIT * offs,
                          Ord(MT_FIREBOMB));
        mo.target := player.mo;
      end;
    arti_egg:
      begin
        mo := player.mo;
        P_SpawnPlayerMissile(mo, Ord(MT_EGGFX));
        P_SPMAngle(mo, Ord(MT_EGGFX), mo.angle - (ANG45 div 6));
        P_SPMAngle(mo, Ord(MT_EGGFX), mo.angle + (ANG45 div 6));
        P_SPMAngle(mo, Ord(MT_EGGFX), mo.angle - (ANG45 div 3));
        P_SPMAngle(mo, Ord(MT_EGGFX), mo.angle + (ANG45 div 3));
      end;
    arti_fly:
      begin
        if not P_GivePower(player, Ord(pw_flight)) then
        begin
          result := false;
          exit;
        end;
      end;
    arti_teleport:
      begin
        P_ArtiTele(player);
      end
    else
      begin
        result := false;
        exit;
      end;
  end;

  result := true;
end;

//----------------------------------------------------------------------------
//
// FUNC P_GetPlayerNum
//
//----------------------------------------------------------------------------
//
//==============================================================================
function P_GetPlayerNum(player: Pplayer_t): integer;
var
  i: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if player = @players[i] then
    begin
      result := i;
      exit;
    end;

  result := 0;
end;

//----------------------------------------------------------------------------
//
// FUNC P_UndoPlayerChicken
//
//----------------------------------------------------------------------------
//
//==============================================================================
function P_UndoPlayerChicken(player: Pplayer_t): boolean;
var
  fog: Pmobj_t;
  mo: Pmobj_t;
  pmo: Pmobj_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t ;
  angle: angle_t;
  playerNum: integer;
  weapon: weapontype_t;
  oldFlags: integer;
  oldFlags2: integer;
begin
  pmo := player.mo;
  x := pmo.x;
  y := pmo.y;
  z := pmo.z;
  angle := pmo.angle;
  weapon := weapontype_t(pmo.special1);
  oldFlags := pmo.flags;
  oldFlags2 := pmo.flags2;
  P_SetMobjState(pmo, S_FREETARGMOBJ);
  mo := P_SpawnMobj(x, y, z, Ord(MT_PLAYER));
  if not P_TestMobjLocation(mo) then
  begin // Didn't fit
    P_RemoveMobj(mo);
    mo := P_SpawnMobj(x, y, z, Ord(MT_CHICPLAYER));
    mo.angle := angle;
    mo.health := player.health;
    mo.special1 := Ord(weapon);
    mo.player := player;
    mo.flags := oldFlags;
    mo.flags2 := oldFlags2;
    player.mo := mo;
    player.chickenTics := 2 * TICRATE;
    result := false;
    exit;
  end;

  playerNum := P_GetPlayerNum(player);
  if playerNum <> 0 then // Set color translation
    mo.flags := mo.flags or (playerNum shl MF_TRANSSHIFT);

  mo.angle := angle;
  mo.player := player;
  mo.reactiontime := 18;
  if oldFlags2 and MF2_FLY <> 0 then
  begin
    mo.flags2 := mo.flags2 or MF2_FLY;
    mo.flags := mo.flags or MF_NOGRAVITY;
  end;
  player.chickenTics := 0;
  player.powers[Ord(pw_weaponlevel2)] := 0;
  player.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;
  mo.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;
  player.mo := mo;
  angle := angle shr ANGLETOFINESHIFT;
  fog := P_SpawnMobj(x + 20 * finecosine[angle], y + 20 * finesine[angle], z + TELEFOGHEIGHT, Ord(MT_TFOG));
  S_StartSound(fog, Ord(sfx_telept));
  P_PostChickenWeapon(player, weapon);
  result := true;
end;

//==============================================================================
//
// TUserGameRules.ThrustMove
//
//==============================================================================
class function TUserGameRules.ThrustMove(const player: Pplayer_t; const move: fixed_t): fixed_t;
begin
  if (player.powers[Ord(pw_flight)] <> 0) and (player.mo.z > player.mo.floorz) then
    result := move
  else if Psubsector_t(player.mo.subsector).sector.special = 15 then // Friction_Low
    result := move div 4
  else
    result := move;
end;

//==============================================================================
//
// TUserGameRules.FlyBobs
//
//==============================================================================
class function TUserGameRules.FlyBobs(const player: Pplayer_t): boolean;
begin
  result := (player.mo.flags2 and MF2_FLY <> 0) and not onground;
end;

//==============================================================================
//
// TUserGameRules.IsMorphed
//
//==============================================================================
class function TUserGameRules.IsMorphed(const player: Pplayer_t): boolean;
begin
  result := player.chickenTics <> 0;
end;

//==============================================================================
//
// TUserGameRules.AdjustViewZ
//
//==============================================================================
class procedure TUserGameRules.AdjustViewZ(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.ClampViewZ
//
//==============================================================================
class procedure TUserGameRules.ClampViewZ(const player: Pplayer_t);
begin
  if player.viewz < player.mo.floorz + 4 * FRACUNIT then
    player.viewz := player.mo.floorz + 4 * FRACUNIT;
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
  onground := (player.mo.z <= player.mo.floorz) or (player.mo.flags2 and MF2_ONMOBJ <> 0);
end;

//==============================================================================
//
// TUserGameRules.MapNoJump
//
//==============================================================================
class function TUserGameRules.MapNoJump: boolean;
begin
  result := (gamemapinfo <> nil) and gamemapinfo.nojump;
end;

//==============================================================================
//
// TUserGameRules.MapNoCrouch
//
//==============================================================================
class function TUserGameRules.MapNoCrouch: boolean;
begin
  result := (gamemapinfo <> nil) and gamemapinfo.nocrouch;
end;

//==============================================================================
//
// TUserGameRules.MoveByCommand
//
//==============================================================================
class procedure TUserGameRules.MoveByCommand(const player: Pplayer_t; const cmd: Pticcmd_t; const cmd_jump, cmd_crouch: byte);
var
  onair: boolean;
  mfactor: integer;
begin
  onair := (player.cheats and CF_LOWGRAVITY <> 0) or (player.mo.flags2 and MF2_FLY <> 0);
  if player.chickenTics <> 0 then
    mfactor := 2500
  else
    mfactor := 2048;

  if (cmd.forwardmove <> 0) and
     (onground or (onair and (player.powers[Ord(pw_flight)] > 0)) or ((cmd_jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0))) then
    P_Thrust(player, player.mo.angle, cmd.forwardmove * mfactor);

  if (cmd.sidemove <> 0) and
     (onground or (onair and (player.powers[Ord(pw_flight)] > 0)) or ((cmd_jump > 0) and (player.mo.momx = 0) and (player.mo.momy = 0))) then
    P_Thrust(player, player.mo.angle - ANG90, cmd.sidemove * mfactor);

  // JVAL: Adjust speed while flying, bye-bye compatibility :(
  if onair and (player.mo.z > player.mo.floorz) then
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

  if (cmd.forwardmove <> 0) or (cmd.sidemove <> 0) then
  begin
    if player.chickenTics <> 0 then
    begin
      if player.mo.state = @states[Ord(S_CHICPLAY)] then
        P_SetMobjState(player.mo, S_CHICPLAY_RUN1);
    end
    else
    begin
      if player.mo.state = @states[Ord(S_PLAY)] then
        P_SetMobjState(player.mo, S_PLAY_RUN1);
    end;
  end;
end;

//==============================================================================
//
// TUserGameRules.LookUpDown
//
//==============================================================================
class function TUserGameRules.LookUpDown(const cmd: Pticcmd_t): integer;
begin
  result := cmd.lookfly and 15;
end;

//==============================================================================
//
// TUserGameRules.AimsAtTarget
//
//==============================================================================
class function TUserGameRules.AimsAtTarget(const player: Pplayer_t): boolean;
begin
  result := false;
end;

//==============================================================================
//
// TUserGameRules.AfterMove
//
//==============================================================================
class procedure TUserGameRules.AfterMove(const player: Pplayer_t; const cmd: Pticcmd_t);
var
  fly: integer;
begin
  fly := _SHR(cmd.lookfly, 4);
  if fly > 7 then
    fly := fly - 16;

  if (fly <> 0) and (player.powers[Ord(pw_flight)] <> 0) then
  begin
    if fly <> TOCENTER then
    begin
      player.flyheight := fly * 2;
      if player.mo.flags2 and MF2_FLY = 0 then
      begin
        player.mo.flags2 := player.mo.flags2 or MF2_FLY;
        player.mo.flags := player.mo.flags or MF_NOGRAVITY;
      end;
    end
    else
    begin
      player.mo.flags2 := player.mo.flags2 and not MF2_FLY;
      player.mo.flags := player.mo.flags and not MF_NOGRAVITY;
    end;
  end
  else if fly > 0 then
    P_PlayerUseArtifact(player, arti_fly);

  if player.mo.flags2 and MF2_FLY <> 0 then
  begin
    player.mo.momz := player.flyheight * FRACUNIT;
    if player.flyheight <> 0 then
      player.flyheight := player.flyheight div 2;
  end;
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
  if player.chickenTics <> 0 then
    P_ChickenPlayerThink(player);
end;

//==============================================================================
//
// TUserGameRules.AfterSector
//
//==============================================================================
class procedure TUserGameRules.AfterSector(const player: Pplayer_t; const cmd: Pticcmd_t);
begin
  if cmd.arti <> 0 then
  begin // Use an artifact
    if cmd.arti = $ff then
      P_PlayerNextArtifact(player)
    else
      P_PlayerUseArtifact(player, artitype_t(cmd.arti));
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

    if (newweapon = wp_staff) and
       (player.weaponowned[Ord(wp_gauntlets)] <> 0) and
       (player.readyweapon <> wp_gauntlets) then
    begin
      newweapon := wp_gauntlets;
      // JVAL: If readyweapon is already the wp_gauntlets return to wp_staff
      // Only if we don't have old compatibility mode suspended
      if not G_NeedsCompatibilityMode then
        if player.readyweapon = wp_gauntlets then
          newweapon := wp_staff;
    end;

    if (player.weaponowned[Ord(newweapon)] <> 0) and
       (newweapon <> player.readyweapon) then
      player.pendingweapon := newweapon;
  end;
end;

//==============================================================================
//
// TUserGameRules.BeforeUseLines
//
//==============================================================================
class procedure TUserGameRules.BeforeUseLines(const player: Pplayer_t);
begin
end;

//==============================================================================
//
// TUserGameRules.BeforePsprites
//
//==============================================================================
class procedure TUserGameRules.BeforePsprites(const player: Pplayer_t);
begin
  // Chicken counter
  if player.chickenTics <> 0 then
  begin
    if player.chickenPeck <> 0 then // Chicken attack counter
      player.chickenPeck := player.chickenPeck - 3;

    dec(player.chickenTics);
    if player.chickenTics = 0 then  // Attempt to undo the chicken
      P_UndoPlayerChicken(player);
  end;
end;

//==============================================================================
//
// TUserGameRules.CountDown
//
//==============================================================================
class procedure TUserGameRules.CountDown(const player: Pplayer_t);
begin
  if player.powers[Ord(pw_invulnerability)] <> 0 then
    player.powers[Ord(pw_invulnerability)] := player.powers[Ord(pw_invulnerability)] - 1;

  if player.powers[Ord(pw_invisibility)] <> 0 then
  begin
    player.powers[Ord(pw_invisibility)] := player.powers[Ord(pw_invisibility)] - 1;
    if player.powers[Ord(pw_invisibility)] = 0 then
      player.mo.flags := player.mo.flags and not MF_SHADOW;
  end;

  if player.powers[Ord(pw_infrared)] <> 0 then
    player.powers[Ord(pw_infrared)] := player.powers[Ord(pw_infrared)] - 1;

  if player.powers[Ord(pw_flight)] <> 0 then
  begin
    player.powers[Ord(pw_flight)] := player.powers[Ord(pw_flight)] - 1;
    if player.powers[Ord(pw_flight)] = 0 then
    begin
      if player.mo.z <> player.mo.floorz then
        player.centering := true;

      player.mo.flags2 := player.mo.flags2 and not MF2_FLY;
      player.mo.flags := player.mo.flags and not MF_NOGRAVITY;
    end;
  end;

  if player.powers[Ord(pw_weaponlevel2)] <> 0 then
  begin
    player.powers[Ord(pw_weaponlevel2)] := player.powers[Ord(pw_weaponlevel2)] - 1;
    if player.powers[Ord(pw_weaponlevel2)] = 0 then
    begin
      if((player.readyweapon = wp_phoenixrod) and
         (player.psprites[ps_weapon].state <> @states[Ord(S_PHOENIXREADY)]) and
         (player.psprites[ps_weapon].state <> @states[Ord(S_PHOENIXUP)])) then
      begin
        P_SetPsprite(player, ps_weapon, S_PHOENIXREADY);
        player.ammo[Ord(am_phoenixrod)] := player.ammo[Ord(am_phoenixrod)] - USE_PHRD_AMMO_2;
        player.refire := 0;
      end
      else if (player.readyweapon = wp_gauntlets) or
              (player.readyweapon = wp_staff) then
        player.pendingweapon := player.readyweapon;
    end;
  end;

  if player.damagecount <> 0 then
    player.damagecount := player.damagecount - 1;

  if player.bonuscount <> 0 then
    player.bonuscount := player.bonuscount - 1;
end;

//==============================================================================
//
// TUserGameRules.Colormap
//
//==============================================================================
class procedure TUserGameRules.Colormap(const player: Pplayer_t);
begin
  TPlayerColormap.Standard(player);
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

