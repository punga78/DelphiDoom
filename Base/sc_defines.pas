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
//
// DESCRIPTION:
//  Defines preprocessor
//

{$I Doom32.inc}

unit sc_defines;

interface

uses
  SysUtils, Classes;

// The #define / #ifdef part of the scripts is TScriptDefines (Libs\Scanner); here are
// only the defines of the game, that every script starts with

var
  gamedefines: TStringList;

//==============================================================================
//
// SC_InitGameDefines
//
//==============================================================================
procedure SC_InitGameDefines;

//==============================================================================
//
// SC_ShutDownGameDefines
//
//==============================================================================
procedure SC_ShutDownGameDefines;

//==============================================================================
//
// SC_AddDefine
//
//==============================================================================
procedure SC_AddDefine(const adef: string);

implementation

//==============================================================================
//
// SC_InitGameDefines
//
//==============================================================================
procedure SC_InitGameDefines;
begin
  gamedefines := TStringList.Create;
end;

//==============================================================================
//
// SC_ShutDownGameDefines
//
//==============================================================================
procedure SC_ShutDownGameDefines;
begin
  gamedefines.Free;
end;

//==============================================================================
//
// SC_AddDefine
//
//==============================================================================
procedure SC_AddDefine(const adef: string);
var
  udef: string;
begin
  udef := UpperCase(adef);
  if gamedefines.IndexOf(udef) < 0 then
    gamedefines.Add(udef);
end;

end.