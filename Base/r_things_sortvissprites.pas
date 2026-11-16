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
//  Vissprite sort (Selection sort, Quick sort & Radix sort variant)
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit r_things_sortvissprites;

interface

uses
  DelphiDoom.Renderer.Intf;

//==============================================================================
//
// R_SortVisSprites
//
//==============================================================================
procedure R_SortVisSprites;

//==============================================================================
//
// R_SortVisSpritesMT
//
//==============================================================================
procedure R_SortVisSpritesMT;

//==============================================================================
//
// R_InitSpriteSort
//
//==============================================================================
procedure R_InitSpriteSort;

//==============================================================================
//
// R_ShutDownSpriteSort
//
//==============================================================================
procedure R_ShutDownSpriteSort;


//==============================================================================
//
// R_ConfigureSpriteSort
// The chooser of the sorting of the sprites of Libs\Renderer, given by the composition root
//
//==============================================================================
procedure R_ConfigureSpriteSort(const APolicy: IRendererSpriteSortPolicy);

implementation

uses
  d_delphi,
  i_system,
  m_fixed,
  p_mobj_h,
  r_defs,
  r_things,
  DelphiDoom.Renderer.Types;

var
  sort_policy: IRendererSpriteSortPolicy = nil;
  // the sprites with their keys, for the sorters (it grows, it is not allocated for a frame)
  sort_items: TArray<TRendererSortItem>;

//==============================================================================
//
// R_ConfigureSpriteSort
//
//==============================================================================
procedure R_ConfigureSpriteSort(const APolicy: IRendererSpriteSortPolicy);
begin
  sort_policy := APolicy;
end;

//==============================================================================
// getvissortscale
//
// R_SortVisSprites
//
//==============================================================================
function getvissortscale(const vis: Pvissprite_t): integer;
begin
  result := vis.scale;
  {$IFDEF HEXEN}
  if vis.mo.flags2 and MF2_DROPPED <> 0 then
  {$ELSE}
  if vis.mobjflags and MF_DROPPED <> 0 then
  {$ENDIF}
    inc(result);
end;

//==============================================================================
//
// R_SortVisSprites
//
//==============================================================================
procedure R_SortVisSprites;
var
  i: integer;
  sorter: IRendererSpriteSorter;
begin
  if vissprite_p < 2 then
    exit;

  if sort_policy = nil then
    I_Error('R_SortVisSprites(): R_ConfigureSpriteSort() was not called');

  // The order is made by the sorter that fits the number of sprites (Libs\Renderer): here
  //  the sprites go in with their keys and come back in order.
  sorter := sort_policy.Select(vissprite_p);
  if Length(sort_items) < vissprite_p then
    SetLength(sort_items, vissprite_p + 128);
  if sorter.UsesDroppedAdjustment then
    for i := 0 to vissprite_p - 1 do
    begin
      sort_items[i].Key := getvissortscale(vissprites[i]);
      sort_items[i].Item := vissprites[i];
    end
  else
    for i := 0 to vissprite_p - 1 do
    begin
      sort_items[i].Key := vissprites[i].scale;
      sort_items[i].Item := vissprites[i];
    end;

  sorter.Sort(@sort_items[0], vissprite_p);

  for i := 0 to vissprite_p - 1 do
    vissprites[i] := Pvissprite_t(sort_items[i].Item);
end;

//
// Sorting while the engine does other things, using a separate thread (idea by zokum)
// https://www.doomworld.com/forum/topic/102482-potential-for-improvement-in-vissprites-sorting/?do=findComment&comment=1920806
//

//==============================================================================
//
// R_SortVisSpritesMT
//
//==============================================================================
procedure R_SortVisSpritesMT;
begin
  // Allocating temp space before activating the thread.
  // This is to speed up FastMM memory manager, since we don't have to
  // set the 'ismultithread' flag to true.
  if sort_policy = nil then
    I_Error('R_SortVisSpritesMT(): R_ConfigureSpriteSort() was not called');
  sort_policy.Reserve(vissprite_p);
  if Length(sort_items) < vissprite_p then
    SetLength(sort_items, vissprite_p + 128);
end;

//==============================================================================
//
// R_InitSpriteSort
//
//==============================================================================
procedure R_InitSpriteSort;
begin
  if sort_policy <> nil then
    sort_policy.Release;
  sort_items := nil;
end;

//==============================================================================
//
// R_ShutDownSpriteSort
//
//==============================================================================
procedure R_ShutDownSpriteSort;
begin
  if sort_policy <> nil then
    sort_policy.Release;
  sort_items := nil;
end;

end.
