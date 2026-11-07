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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//   Save/Load screen preview: the thumbnail that a saved game keeps.
//   The thumbnail is made by R_RenderPlayerView (r_main) with the
//   IImagingThumbnailBuilder of Libs\Imaging and checked by the menus with
//   TImagingSaveThumbnailFormat: this unit keeps only the record of the
//   savegames and the last thumbnail taken.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit mn_screenshot;

interface

uses
  DelphiDoom.Imaging.Types;

const
  MN_SCREENSHOTWIDTH = IMAGING_SAVE_THUMBNAIL_WIDTH;
  MN_SCREENSHOTHEIGHT = IMAGING_SAVE_THUMBNAIL_HEIGHT;
  MN_SCREENSHOTSIZE = IMAGING_SAVE_THUMBNAIL_SIZE;

  MNSCREENSHOT_MAGIC_SIZE = IMAGING_SAVE_THUMBNAIL_MAGIC_SIZE;

type
  // The record of the savegames (4014 bytes): the text MENUSCREENSHOT and 80x50 palette indices
  menuscreenbuffer_t = TImagingSaveThumbnail;
  Pmenuscreenbuffer_t = ^menuscreenbuffer_t;

var
  mn_screenshotbuffer: menuscreenbuffer_t;
  mn_makescreenshot: boolean = false;

implementation

end.
