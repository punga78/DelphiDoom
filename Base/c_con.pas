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

unit c_con;

//
// Console
//
// What is left of the console unit: its settings (issue #145). The console itself (text,
// line of input, drawing, keys) is the class TEngineConsoleScreen
// (DelphiDoom.Engine.Console.Screen) behind IEngineConsole, given by the composition root.
//

interface

var
  // the colormap that darkens the background of the console (option consolecolormap)
  ConsoleColormap: integer;

var
  // the text of the console goes to the file stdout too (option mirror_stdout)
  mirror_stdout: boolean;
  // the autoexec file, from -autoexec or DEFAUTOEXEC
  autoexecfile: string;

const
{$IFDEF DOOM}
  DEFAUTOEXEC = 'Doom32.con';
{$ENDIF}
{$IFDEF HERETIC}
  DEFAUTOEXEC = 'Heretic32.con';
{$ENDIF}
{$IFDEF HEXEN}
  DEFAUTOEXEC = 'Hexen32.con';
{$ENDIF}
{$IFDEF STRIFE}
  DEFAUTOEXEC = 'Strife32.con';
{$ENDIF}

implementation

end.
