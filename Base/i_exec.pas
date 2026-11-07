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
//  Run a (console) program in background, capture program output.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_exec;

interface

uses
  DelphiDoom.Platform.Intf;

//==============================================================================
//
// I_ConfigureExec
// Gives the unit the runner of programs it uses. The composition root calls it
//
//==============================================================================
procedure I_ConfigureExec(const ARunner: IProcessRunner);

//==============================================================================
//
// I_ExecProgram
//
//==============================================================================
function I_ExecProgram(const cmd: string; const quiet: boolean): boolean;

implementation

uses
  d_delphi,
  i_system;

var
  // given by the composition root (I_ConfigureExec)
  engine_runner: IProcessRunner = nil;

//==============================================================================
//
// I_ConfigureExec
//
//==============================================================================
procedure I_ConfigureExec(const ARunner: IProcessRunner);
begin
  engine_runner := ARunner;
end;

//==============================================================================
//
// I_ExecProgram
//
//==============================================================================
function I_ExecProgram(const cmd: string; const quiet: boolean): boolean;
begin
  if not Assigned(engine_runner) then
    I_Error('I_ExecProgram(): the runner of programs was not configured');

  if quiet then
    result := engine_runner.Run(cmd, nil)
  else
    result := engine_runner.Run(cmd,
      procedure(const AText: AnsiString)
      begin
        printf(string(AText));
      end);
end;

end.
