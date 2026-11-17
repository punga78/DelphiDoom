{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of doomdef for the per-game OpenGL scene tests        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\<Game>\doomdef.pas in DelphiDoom.Tests.OpenGl.<Game> only: the size of the screen.
unit doomdef;

interface

var
  SCREENWIDTH: Integer = 640;
  SCREENHEIGHT: Integer = 400;

implementation

end.