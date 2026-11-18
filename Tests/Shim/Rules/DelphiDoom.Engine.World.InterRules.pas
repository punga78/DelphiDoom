{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of DelphiDoom.Engine.World.InterRules for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real DelphiDoom.Engine.World.InterRules in DelphiDoom.Tests.Rules only: the strategy that p_inter asks for the health limit (the real unit has the pickups and the damage of the game).
{$I Doom32.inc}
unit DelphiDoom.Engine.World.InterRules;

interface

uses
  d_player,
  p_mobj_h;

type
  TInterGameRules = class sealed
  public
    const
      OwnsGiveBody = False;
    class var ShimMaxHealth: integer;
    class function MaxPlayerHealth(player: Pplayer_t): integer; static;
    class function GiveBody(player: Pplayer_t; num: integer): boolean; static;
    class procedure TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t); static;
    class procedure DamageMobj(target, inflictor, source: Pmobj_t; damage: integer); static;
  end;

implementation

class function TInterGameRules.MaxPlayerHealth(player: Pplayer_t): integer;
begin
  result := ShimMaxHealth;
end;

class function TInterGameRules.GiveBody(player: Pplayer_t; num: integer): boolean;
begin
  result := false;
end;

class procedure TInterGameRules.TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
begin
end;

class procedure TInterGameRules.DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);
begin
end;

end.