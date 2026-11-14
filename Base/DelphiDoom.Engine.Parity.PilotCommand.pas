{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the pilot's command as a ticcmd                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.PilotCommand;

interface

uses
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Types,
  d_ticcmd,
  p_mobj_h;

type
  /// <summary>Puts the command of the automatic pilot in the ticcmd that the engine has just built</summary>
  TEngineParityPilotCommand = class
  strict private
    /// <summary>The nearest living monster within ARange map units that the player can see</summary>
    class procedure FindEnemy(APlayer: Pmobj_t; ARange: Integer; var AView: TParityPilotView); static;
  public
    /// <summary>
    ///   Replaces what the keyboard and the mouse made (nothing, as the input is closed) with the command of
    ///   the pilot for the tic. False, and the ticcmd untouched, when the pilot has finished
    /// </summary>
    class function Apply(const APilot: IParityPilot; ACommand: Pticcmd_t; ATic: Integer): Boolean; static;
  end;

implementation

uses
  d_event,
  d_player,
  d_think,
  doomdef,
  g_game,
  m_fixed,
  p_mobj,
  p_sight,
  p_tick;

const
  MAX_WEAPONS_BY_MASK = 8;
  // TOCENTER of p_local
  LOOK_TO_CENTER = -8;
  LOOK_WRAP = 16;
  LOOK_FRACTION = 256;
  // what G_BuildTiccmd gives for a key that has just gone down (a jump starts only then)
  JUMP_PRESSED = 2;
  CROUCH_PRESSED = 1;

{ TEngineParityPilotCommand }

class procedure TEngineParityPilotCommand.FindEnemy(APlayer: Pmobj_t; ARange: Integer; var AView: TParityPilotView);
var
  LThinker: Pthinker_t;
  LMobj: Pmobj_t;
  LDeltaX: Int64;
  LDeltaY: Int64;
  LDistance: Int64;
  LBest: Int64;
begin
  LBest := Int64(ARange) * ARange;
  LThinker := thinkercap.next;
  while LThinker <> @thinkercap do
  begin
    if @LThinker._function.acp1 = @P_MobjThinker then
    begin
      LMobj := Pmobj_t(LThinker);
      if (LMobj.flags and MF_COUNTKILL <> 0) and (LMobj.flags and MF_SHOOTABLE <> 0) and (LMobj.health > 0) then
      begin
        LDeltaX := (Int64(LMobj.x) - APlayer.x) div FRACUNIT;
        LDeltaY := (Int64(LMobj.y) - APlayer.y) div FRACUNIT;
        LDistance := LDeltaX * LDeltaX + LDeltaY * LDeltaY;
        // the sight is traced last, and only for a monster nearer than the best so far: an enemy behind a
        // wall (it can have heard the player) would keep the pilot firing at the wall
        if (LDistance <= LBest) and P_CheckSight(APlayer, LMobj) then
        begin
          LBest := LDistance;
          AView.HasEnemy := True;
          AView.EnemyX := LMobj.x;
          AView.EnemyY := LMobj.y;
          AView.EnemyZ := LMobj.z;
        end;
      end;
    end;
    LThinker := LThinker.next;
  end;
end;

class function TEngineParityPilotCommand.Apply(const APilot: IParityPilot; ACommand: Pticcmd_t;
  ATic: Integer): Boolean;
var
  LView: TParityPilotView;
  LCommand: TParityPilotCommand;
  LConsistency: SmallInt;
  LWeapons: Integer;
  LLook: Integer;
begin
  if APilot.IsFinished(ATic) then
    Exit(False);

  LView := Default(TParityPilotView);
  LView.Tic := ATic;
  if (consoleplayer >= 0) and (consoleplayer < MAXPLAYERS) then
  begin
    LView.Alive := (players[consoleplayer].playerstate = PST_LIVE) and (players[consoleplayer].mo <> nil);
    LView.Health := players[consoleplayer].health;
    if players[consoleplayer].mo <> nil then
    begin
      LView.X := players[consoleplayer].mo.x;
      LView.Y := players[consoleplayer].mo.y;
      LView.Z := players[consoleplayer].mo.z;
      LView.Angle := players[consoleplayer].mo.angle;
    end;
    // only a script that fights asks for the enemies: the automatic pilot never searches the level
    if LView.Alive and (gamestate = GS_LEVEL) and (APilot.EnemyRange > 0) then
      FindEnemy(players[consoleplayer].mo, APilot.EnemyRange, LView);
  end;
  LCommand := APilot.NextCommand(LView);

  LConsistency := ACommand.consistency;
  FillChar(ACommand^, SizeOf(ticcmd_t), 0);
  ACommand.consistency := LConsistency;
  ACommand.forwardmove := LCommand.Forward;
  ACommand.sidemove := LCommand.Side;
  ACommand.angleturn := LCommand.Turn;
  if LCommand.Fire then
    ACommand.buttons := ACommand.buttons or BT_ATTACK;
  if LCommand.Use then
    ACommand.buttons := ACommand.buttons or BT_USE;
  if LCommand.Weapon > 0 then
  begin
    LWeapons := Ord(NUMWEAPONS);
    if LWeapons > MAX_WEAPONS_BY_MASK then
      LWeapons := MAX_WEAPONS_BY_MASK;
    ACommand.buttons := ACommand.buttons or BT_CHANGE or
      (((LCommand.Weapon - 1) mod LWeapons) shl BT_WEAPONSHIFT);
  end;
  // the keys below are asked only by a script (-autoscript): the automatic pilot leaves them at zero
  LLook := LCommand.Look;
  if LCommand.LookCenter then
    LLook := LOOK_TO_CENTER;
  if LLook <> 0 then
  begin
    // the ticcmd keeps the look in four bits (and, since 2.03, in 4.8 fixed point too)
    if LLook < 0 then
      LLook := LLook + LOOK_WRAP;
    ACommand.lookupdown := LLook;
    ACommand.lookupdown16 := LLook * LOOK_FRACTION;
  end;
  if LCommand.Jump then
    ACommand.jump_crouch := (JUMP_PRESSED shl CMD_JUMP_SHIFT) and CMD_JUMP_MASK
  else if LCommand.Crouch then
    ACommand.jump_crouch := (CROUCH_PRESSED shl CMD_CROUCH_SHIFT) and CMD_CROUCH_MASK;
  // the two keys of a game (the free bits of jump_crouch): only a script that names them sets them
  if LCommand.Afterburner then
    ACommand.jump_crouch := ACommand.jump_crouch or CMD_GAMEKEY1_MASK;
  if LCommand.Bomb then
    ACommand.jump_crouch := ACommand.jump_crouch or CMD_GAMEKEY2_MASK;
  Result := True;
end;

end.
