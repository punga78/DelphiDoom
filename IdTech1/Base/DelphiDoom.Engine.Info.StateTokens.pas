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

unit DelphiDoom.Engine.Info.StateTokens;

interface

uses
  DelphiDoom.Info.Intf;

type
  /// <summary>The names of the states of the scripts (statenames of sc_states), read when they are asked</summary>
  TEngineInfoStateTokens = class(TInterfacedObject, IInfoStateTokens)
  public
    function IndexOfToken(const AToken: string): Integer;
  end;

implementation

uses
  sc_states;

{ TEngineInfoStateTokens }

function TEngineInfoStateTokens.IndexOfToken(const AToken: string): Integer;
begin
  // statenames is made by the first reading of the script states; before that nothing is named
  if statenames = nil then
    Result := -1
  else
    Result := statenames.IndexOfToken(AToken);
end;

end.
