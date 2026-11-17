{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_main for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_main.pas in DelphiDoom.Tests.OpenGl.<Game> only: the player of the view and the centre of the screen.
unit r_main;

interface

uses
  d_player;

var
  viewplayer: Pplayer_t = nil;
  centery: integer = 0;

implementation

end.