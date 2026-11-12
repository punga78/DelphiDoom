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
  d_ticcmd;

type
  /// <summary>Puts the command of the automatic pilot in the ticcmd that the engine has just built</summary>
  TEngineParityPilotCommand = class
  public
    /// <summary>
    ///   Replaces what the keyboard and the mouse made (nothing, as the input is closed) with the command of
    ///   the pilot for the tic. False, and the ticcmd untouched, when the pilot has finished
    /// </summary>
    class function Apply(const APilot: IParityPilot; ACommand: Pticcmd_t; ATic: Integer): Boolean; static;
  end;

implementation

uses
  DelphiDoom.Parity.Types,
  d_event,
  d_player,
  doomdef,
  g_game;

const
  MAX_WEAPONS_BY_MASK = 8;

{ TEngineParityPilotCommand }

class function TEngineParityPilotCommand.Apply(const APilot: IParityPilot; ACommand: Pticcmd_t;
  ATic: Integer): Boolean;
var
  LView: TParityPilotView;
  LCommand: TParityPilotCommand;
  LConsistency: SmallInt;
  LWeapons: Integer;
begin
  if APilot.IsFinished(ATic) then
    Exit(False);

  LView := Default(TParityPilotView);
  LView.Tic := ATic;
  if (consoleplayer >= 0) and (consoleplayer < MAXPLAYERS) then
  begin
    LView.Alive := (players[consoleplayer].playerstate = PST_LIVE) and (players[consoleplayer].mo <> nil);
    if players[consoleplayer].mo <> nil then
    begin
      LView.X := players[consoleplayer].mo.x;
      LView.Y := players[consoleplayer].mo.y;
    end;
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
  Result := True;
end;

end.
