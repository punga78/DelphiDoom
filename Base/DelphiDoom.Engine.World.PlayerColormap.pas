{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the colormap of the view of the player                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PlayerColormap;

interface

uses
  d_player;

type
  /// <summary>
  ///   The colormap of the view of Doom and Heretic (issue #185, step 2f-1): the powers that
  ///   invert or light it. Strife and Hexen have other powers and their own rules
  /// </summary>
  TPlayerColormap = class sealed
  public
    /// <summary>Sets fixedcolormap of the player from its powers (called every tic)</summary>
    class procedure Standard(player: Pplayer_t); static;
  end;

implementation

uses
  r_main,
  doomdef;

//==============================================================================
//
// TPlayerColormap.Standard
//
//==============================================================================
class procedure TPlayerColormap.Standard(player: Pplayer_t);
begin
  // Handling colormaps.
  if player.powers[Ord(pw_invulnerability)] <> 0 then
  begin
    if (player.powers[Ord(pw_invulnerability)] > 4 * 32) or
       (player.powers[Ord(pw_invulnerability)] and 8 <> 0) then
      player.fixedcolormap := INVERSECOLORMAP
    else
      player.fixedcolormap := 0;
  end
  else if player.powers[Ord(pw_infrared)] <> 0 then
  begin
    if (player.powers[Ord(pw_infrared)] > 4 * 32) or
       (player.powers[Ord(pw_infrared)] and 8 <> 0) then
      // almost full bright
      player.fixedcolormap := 1
    else
      player.fixedcolormap := 0;
  end
  else
    player.fixedcolormap := 0;
end;

end.
