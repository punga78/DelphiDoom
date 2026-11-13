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

// Facade (issue #185, slice 1b): the rules of an entry with several names live in
// Libs\Scanner\DelphiDoom.Scanner.TokenEntry; the list stays a TDStringList because the
// callers read statenames and the other token lists with Strings, Add and Count.

unit sc_tokens;

interface

uses
  d_delphi;

type
  TTokenList = class(TDStringList)
  public
    function IndexOfToken(const S: string): Integer; virtual;
    function AllTokensWithIndex: TDStringList;
  end;

//==============================================================================
//
// SC_EvalueateIntToken
//
//==============================================================================
function SC_EvalueateIntToken(const token: string; const A: array of string): integer;

implementation

uses
  DelphiDoom.Scanner.TokenEntry;

//==============================================================================
//
// TTokenList.IndexOfToken
//
//==============================================================================
function TTokenList.IndexOfToken(const S: string): Integer;
var
  i: integer;
begin
  result := IndexOf(S);
  if result > -1 then
    exit;

  for i := 0 to Count - 1 do
    if TScannerTokenEntry.ListsToken(Strings[i], S) then
    begin
      result := i;
      exit;
    end;
end;

//==============================================================================
//
// TTokenList.AllTokensWithIndex
//
//==============================================================================
function TTokenList.AllTokensWithIndex: TDStringList;
var
  i, j: integer;
  names: TArray<string>;
begin
  Result := TDStringList.Create;

  for i := 0 to Count - 1 do
  begin
    names := TScannerTokenEntry.Split(Strings[i]);
    for j := 0 to Length(names) - 1 do
      Result.AddObject(names[j], TInteger.Create(i));
  end;
end;

//==============================================================================
//
// SC_EvalueateIntToken
//
//==============================================================================
function SC_EvalueateIntToken(const token: string; const A: array of string): integer;
var
  i: integer;
begin
  i := atoi(token);
  if itoa(i) = token then
  begin
    result := i;
    exit;
  end;

  result := TScannerTokenEntry.IndexOfToken(A, token);
end;

end.
