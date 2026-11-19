{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of DelphiDoom.Engine.World.UserRules (rule tests)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real DelphiDoom.Engine.World.UserRules (Heretic, Hexen) in the rule test projects only: the two inventory rules that PlayerArtifacts asks of the game, with the meaning they have in each game (Heretic: no empty slot check, no clearing; Hexen: a slot with count 0 is empty and the freed slot is zeroed).
{$I Doom32.inc}
unit DelphiDoom.Engine.World.UserRules;

interface

uses
  d_player;

type
  TUserGameRules = class sealed
  public
    class function SlotIsEmpty(const player: Pplayer_t; const slot: integer): boolean; static;
    class procedure ClearFreedSlot(const player: Pplayer_t); static;
  end;

implementation

class function TUserGameRules.SlotIsEmpty(const player: Pplayer_t; const slot: integer): boolean;
begin
  {$IFDEF HEXEN}
  result := player.inventory[slot].count = 0;
  {$ELSE}
  result := false;
  {$ENDIF}
end;

class procedure TUserGameRules.ClearFreedSlot(const player: Pplayer_t);
begin
  {$IFDEF HEXEN}
  player.inventory[player.inventorySlotNum - 1]._type := 0;
  player.inventory[player.inventorySlotNum - 1].count := 0;
  {$ENDIF}
end;

end.
