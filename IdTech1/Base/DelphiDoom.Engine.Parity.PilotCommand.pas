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
  p_mobj_h,
  p_maputl;

type
  /// <summary>What saves or loads the game of a slot for a script (the routines of the menus of a game)</summary>
  TEngineParitySlotProc = procedure(ASlot: Integer);

  /// <summary>Puts the command of the automatic pilot in the ticcmd that the engine has just built</summary>
  TEngineParityPilotCommand = class
  strict private
    class var FSaveGame: TEngineParitySlotProc;
    class var FLoadGame: TEngineParitySlotProc;
    class var FPendingShot: Integer;
    /// <summary>A key of the engine goes down and up, as two events of the queue of the game</summary>
    class procedure PostKey(AKey: Integer); static;
    /// <summary>The nearest living monster within ARange map units that the player can see</summary>
    class procedure FindEnemy(APlayer: Pmobj_t; ARange: Integer; var AView: TParityPilotView); static;
  public
    /// <summary>
    ///   The steps "save" and "load" of a script (-autoscript) call these. The games save and load with
    ///   different routines: the part of the composition of a game gives its own (today Radix); without
    ///   them the two steps do nothing
    /// </summary>
    class procedure ConfigureSaveGames(ASaveGame, ALoadGame: TEngineParitySlotProc); static;
    /// <summary>
    ///   The number of the picture that the step "shot" of a script has asked for since the last call
    ///   (0 = none): who writes the frames takes it once
    /// </summary>
    class function TakePendingShot: Integer; static;
    /// <summary>
    ///   Replaces what the keyboard and the mouse made (nothing, as the input is closed) with the command of
    ///   the pilot for the tic. False, and the ticcmd untouched, when the pilot has finished
    /// </summary>
    class function Apply(const APilot: IParityPilot; ACommand: Pticcmd_t; ATic: Integer): Boolean; static;
  end;

implementation

uses
  d_event,
  d_main,
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

class procedure TEngineParityPilotCommand.ConfigureSaveGames(ASaveGame, ALoadGame: TEngineParitySlotProc);
begin
  FSaveGame := ASaveGame;
  FLoadGame := ALoadGame;
end;

class function TEngineParityPilotCommand.TakePendingShot: Integer;
begin
  Result := FPendingShot;
  FPendingShot := 0;
end;

class procedure TEngineParityPilotCommand.PostKey(AKey: Integer);
var
  LEvent: event_t;
begin
  FillChar(LEvent, SizeOf(LEvent), 0);
  LEvent._type := ev_keydown;
  LEvent.data1 := AKey;
  TMainRoutines.D_PostEvent(@LEvent);
  LEvent._type := ev_keyup;
  TMainRoutines.D_PostEvent(@LEvent);
end;

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
  LThinker := TTickState.ThinkerCap.next;
  while LThinker <> @TTickState.ThinkerCap do
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
  LButtons: Byte;
  LWeapons: Integer;
  LLook: Integer;
begin
  if APilot.IsFinished(ATic) then
    Exit(False);

  LView := Default(TParityPilotView);
  LView.Tic := ATic;
  if (TGameSession.ConsolePlayer >= 0) and (TGameSession.ConsolePlayer < MAXPLAYERS) then
  begin
    LView.Alive := (TGameSession.Players[TGameSession.ConsolePlayer].playerstate = PST_LIVE) and (TGameSession.Players[TGameSession.ConsolePlayer].mo <> nil);
    LView.Health := TGameSession.Players[TGameSession.ConsolePlayer].health;
    if TGameSession.Players[TGameSession.ConsolePlayer].mo <> nil then
    begin
      LView.X := TGameSession.Players[TGameSession.ConsolePlayer].mo.x;
      LView.Y := TGameSession.Players[TGameSession.ConsolePlayer].mo.y;
      LView.Z := TGameSession.Players[TGameSession.ConsolePlayer].mo.z;
      LView.Angle := TGameSession.Players[TGameSession.ConsolePlayer].mo.angle;
      LView.Speed := TMapUtilRoutines.P_AproxDistance(TGameSession.Players[TGameSession.ConsolePlayer].mo.momx, TGameSession.Players[TGameSession.ConsolePlayer].mo.momy);
    end;
    // only a script that fights asks for the enemies: the automatic pilot never searches the level
    if LView.Alive and (TGameSession.GameState = GS_LEVEL) and (APilot.EnemyRange > 0) then
      FindEnemy(TGameSession.Players[TGameSession.ConsolePlayer].mo, APilot.EnemyRange, LView);
  end;
  LCommand := APilot.NextCommand(LView);

  // a script that saves or loads: the game does it between two tics, as for its menus
  if LCommand.Save and Assigned(FSaveGame) then
    FSaveGame(LCommand.Slot);
  if LCommand.Load and Assigned(FLoadGame) then
    FLoadGame(LCommand.Slot);
  // a script that works the menus: the key goes where the keyboard (closed) would have put it
  if LCommand.Key > 0 then
    PostKey(LCommand.Key);
  if LCommand.Shot > 0 then
    FPendingShot := LCommand.Shot;

  LConsistency := ACommand.consistency;
  LButtons := ACommand.buttons;
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
  // The special buttons that the engine has just built (the save asked at the tic before) take the place
  // of the buttons of the pilot, as they do for a player at the keyboard; the moves stay. The automatic
  // pilot never meets them: the input is closed and it asks for no save
  if LButtons and BT_SPECIAL <> 0 then
    ACommand.buttons := LButtons;
  Result := True;
end;

end.
