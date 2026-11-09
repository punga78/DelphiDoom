//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    Handles visibility checks (loosely based on the JDoom clipper, Copyright
//    2003 Tim Stump, see Libs\GlMath\DelphiDoom.GlMath.AngleClipper.pas for the
//    notice). The facade of Libs\GlMath (IGlAngleClipper): the ranges of angles
//    are in the library, the unit only reads the view of the player.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit gl_clipper;

interface

uses
  tables,
  DelphiDoom.GlMath.Intf;

//==============================================================================
//
// GL_ConfigureClipper
//
//==============================================================================
procedure GL_ConfigureClipper(const AClipper: IGlAngleClipper);

//==============================================================================
//
// gld_clipper_SafeCheckRange
//
//==============================================================================
function gld_clipper_SafeCheckRange(const startAngle, endAngle: angle_t): boolean;

//==============================================================================
//
// gld_clipper_SafeAddClipRange
//
//==============================================================================
procedure gld_clipper_SafeAddClipRange(const startAngle, endAngle: angle_t);

//==============================================================================
//
// gld_ClipperAddViewRange
//
//==============================================================================
procedure gld_ClipperAddViewRange;

//==============================================================================
//
// gld_ClipperDone
//
//==============================================================================
procedure gld_ClipperDone;

implementation

uses
  DelphiDoom.GlMath.ViewAngle,
  i_system,
  r_main;

var
  clipper_service: IGlAngleClipper = nil;

//==============================================================================
//
// GL_ConfigureClipper
//
//==============================================================================
procedure GL_ConfigureClipper(const AClipper: IGlAngleClipper);
begin
  clipper_service := AClipper;
end;

//==============================================================================
//
// gld_clipper_SafeCheckRange
//
//==============================================================================
function gld_clipper_SafeCheckRange(const startAngle, endAngle: angle_t): boolean;
begin
  result := clipper_service.SafeCheckRange(startAngle, endAngle);
end;

//==============================================================================
//
// gld_clipper_SafeAddClipRange
//
//==============================================================================
procedure gld_clipper_SafeAddClipRange(const startAngle, endAngle: angle_t);
begin
  clipper_service.SafeAddRange(startAngle, endAngle);
end;

//==============================================================================
//
// gld_ClipperAddViewRange
//
//==============================================================================
procedure gld_ClipperAddViewRange;
var
  a1: angle_t;
begin
  if not Assigned(clipper_service) then
    I_Error('gld_ClipperAddViewRange(): the clipper is not configured (call ComposeEngine first)');

  // JVAL Smooth Look Up/Down: lookdir16 is in 1/32 of a degree
  a1 := TGlViewAngle.FrustumAngle(viewplayer.lookdir16, monitor_relative_aspect);
  clipper_service.Clear;
  clipper_service.SafeAddRange(viewangle + a1, viewangle - a1);
end;

//==============================================================================
//
// gld_ClipperDone
//
//==============================================================================
procedure gld_ClipperDone;
begin
  if Assigned(clipper_service) then
    clipper_service.Release;
end;

end.
