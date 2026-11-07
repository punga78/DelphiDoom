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

unit sc_utils;

interface

uses
  DelphiDoom.Scanner.Preprocessor.Intf;

//==============================================================================
//
// SC_ConfigurePreprocessor
//
// The script preprocessor of the engine (TScriptTextPreprocessor of Libs\Scanner),
// given by ComposeEngine
//
//==============================================================================
procedure SC_ConfigurePreprocessor(const APreprocessor: IScriptTextPreprocessor);

//==============================================================================
//
// SC_Preprocess
//
// Kept only for vx_base (VOXELDEF); the other callers receive the
// IScriptTextPreprocessor from ComposeEngine
//
//==============================================================================
function SC_Preprocess(const inp_text: string; const addcomment: boolean): string;

implementation

uses
  i_system;

var
  script_preprocessor: IScriptTextPreprocessor;

//==============================================================================
//
// SC_ConfigurePreprocessor
//
//==============================================================================
procedure SC_ConfigurePreprocessor(const APreprocessor: IScriptTextPreprocessor);
begin
  script_preprocessor := APreprocessor;
end;

//==============================================================================
//
// SC_Preprocess
//
//==============================================================================
function SC_Preprocess(const inp_text: string; const addcomment: boolean): string;
begin
  if script_preprocessor = nil then
    I_Error('SC_Preprocess(): the preprocessor is not configured (ComposeEngine was not called)');
  result := script_preprocessor.Preprocess(inp_text, addcomment);
end;

end.
