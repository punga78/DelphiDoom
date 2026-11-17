{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_main for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_main.pas in DelphiDoom.Tests.OpenGl.<Game> only: the player of the view, the camera of the frame and the options of the view.
unit r_main;

interface

uses
  d_player,
  m_fixed,
  tables;

var
  viewplayer: Pplayer_t = nil;
  centery: integer = 0;
  viewx: fixed_t = 0;
  viewy: fixed_t = 0;
  viewz: fixed_t = 0;
  viewangle: angle_t = 0;
  screenblocks: integer = 10;
  zaxisshift: boolean = true;
  monitor_relative_aspect: Double = 1.0;

implementation

end.