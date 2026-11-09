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
//  Cheat code checking.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_cheat;

interface

uses
  DelphiDoom.Console.Types,
  DelphiDoom.Console.CheatSequence;

type
  // The record keeps the keys of the cheat as the games write them; the state of the
  // recognition is a TCheatSequence of Libs\Console, created at the first key
  cheatseq_t = record
    sequence: AnsiString;
    p: AnsiString; // set to '' to start the recognition again
    state: TCheatSequence;
  end;
  Pcheatseq_t = ^cheatseq_t;

  cheatstatus_t = (cht_unknown, cht_pending, cht_acquired);

//==============================================================================
//
// cht_CheckCheat
//
//==============================================================================
function cht_CheckCheat(cht: Pcheatseq_t; key: char): cheatstatus_t;

//==============================================================================
//
// cht_GetParam
//
//==============================================================================
procedure cht_GetParam(cht: Pcheatseq_t; var buffer: string);

//==============================================================================
//
// get_cheatseq_string
//
//==============================================================================
function get_cheatseq_string(const A: array of AnsiChar): AnsiString; overload; // JVAL

//==============================================================================
//
// get_cheatseq_string
//
//==============================================================================
function get_cheatseq_string(const A: AnsiString): AnsiString; overload; // JVAL

//==============================================================================
//
// get_cheatseq_string
//
//==============================================================================
function get_cheatseq_string(const x: integer): AnsiString; overload; // JVAL

implementation

uses
  i_system;

//==============================================================================
//
// get_cheatseq_string
//
//==============================================================================
function get_cheatseq_string(const A: array of AnsiChar): AnsiString; // JVAL
var
  i: integer;
begin
  result := '';
  i := 0;
  repeat
    result := result + A[i];
    inc(i);
  until A[i] = AnsiChar($FF);
end;

//==============================================================================
//
// get_cheatseq_string
//
//==============================================================================
function get_cheatseq_string(const A: AnsiString): AnsiString;  // JVAL
var
  i: integer;
begin
  result := '';
  i := 1;
  repeat
    result := result + A[i];
    inc(i);
  until A[i] = AnsiChar($FF);
end;

//==============================================================================
//
// get_cheatseq_string
//
//==============================================================================
function get_cheatseq_string(const x: integer): AnsiString; // JVAL
begin
  result := '';
  if x <> 0 then
    I_Error('get_cheatseq_string(): invalid parameter: %d', [x]);
end;

//==============================================================================
//
// cht_CheckCheat
//
//==============================================================================
function cht_CheckCheat(cht: Pcheatseq_t; key: char): cheatstatus_t;
begin
  if cht.state = nil then
    cht.state := TCheatSequence.Create(cht.sequence)
  else if cht.p = '' then
    cht.state.Reset;
  cht.p := #1; // the recognition is running

  case cht.state.Check(Ord(key)) of
    csPending: result := cht_pending;
    csAcquired: result := cht_acquired;
  else
    result := cht_unknown;
  end;
end;

//==============================================================================
//
// cht_GetParam
//
//==============================================================================
procedure cht_GetParam(cht: Pcheatseq_t; var buffer: string);
begin
  if cht.state = nil then
    buffer := ''
  else
    buffer := cht.state.Param;
end;

end.