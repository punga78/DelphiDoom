{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of doomdef for the OpenGL 2D mode unit                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\<Game>\doomdef.pas in DelphiDoom.Tests.OpenGl only: DelphiDoom.Engine.Gl2dMode
// reads just the size of the screen.
unit doomdef;

interface

var
  SCREENWIDTH: Integer = 640;
  SCREENHEIGHT: Integer = 400;

implementation

end.
