{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of d_main for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\<Game>\d_main.pas in DelphiDoom.Tests.OpenGl.<Game> only: the developer mode flag.
unit d_main;

interface

var
  devparm: boolean = false;

implementation

end.