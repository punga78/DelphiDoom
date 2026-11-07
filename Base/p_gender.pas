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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_gender;

interface

uses
  DelphiDoom.Obituary.Intf;

type
  gender_t = (
    gender_Default,
    gender_Male,
    gender_Female,
    gender_Plural,
    gender_Team,
    gender_Neutral,
    NUMGENDERS
  );

//==============================================================================
//
// R_ConfigureGenders
//
//==============================================================================
procedure R_ConfigureGenders(const AGenders: IObituaryGenders);

//==============================================================================
//
// R_GetGenderForName
//
//==============================================================================
function R_GetGenderForName(const s: string): gender_t;

//==============================================================================
//
// R_GenderName
//
//==============================================================================
function R_GenderName(const g: gender_t): string;

implementation

uses
  DelphiDoom.Obituary.Types,
  i_system;

var
  genders: IObituaryGenders = nil;

//==============================================================================
//
// R_ConfigureGenders
//
//==============================================================================
procedure R_ConfigureGenders(const AGenders: IObituaryGenders);
begin
  // the ordinals of gender_t are the ones that DEHACKED and ACTORDEF store
  if Ord(NUMGENDERS) <> OBITUARY_GENDER_COUNT then
    I_Error('R_ConfigureGenders(): the genders of the engine (%d) and of the library (%d) differ',
      [Ord(NUMGENDERS), OBITUARY_GENDER_COUNT]);
  genders := AGenders;
end;

//==============================================================================
//
// R_GetGenderForName
//
//==============================================================================
function R_GetGenderForName(const s: string): gender_t;
begin
  if genders = nil then
    I_Error('R_GetGenderForName(): the genders are not configured (ComposeEngine was not called)');
  result := gender_t(genders.FindByName(s));
end;

//==============================================================================
//
// R_GenderName
//
//==============================================================================
function R_GenderName(const g: gender_t): string;
begin
  if genders = nil then
    I_Error('R_GenderName(): the genders are not configured (ComposeEngine was not called)');
  result := genders.NameOf(TObituaryGender(g));
end;

end.