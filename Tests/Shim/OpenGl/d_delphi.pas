{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of d_delphi for the OpenGL light units                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Common\d_delphi.pas in DelphiDoom.Tests.OpenGl only: the light units
// (DelphiDoom.Engine.GlScene.LightPainter and LightSorter) take from it just the type float.
unit d_delphi;

interface

type
  float = Single;
  Pfloat = ^float;

implementation

end.
