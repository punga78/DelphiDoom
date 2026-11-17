{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of gl_defs for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\gl_defs.pas in DelphiDoom.Tests.OpenGl.<Game> only: the options the
// scene units read, same names and same initial values as the real ones.
unit gl_defs;

interface

uses
  dglOpenGL,
  m_fixed;

type
  gld_camera_t = record
    position: TGLVectorf3;
    rotation: TGLVectorf3;
  end;
  Pgld_camera_t = ^gld_camera_t;

const
  MAP_COEFF = 128.0;
  MAP_SCALE = MAP_COEFF * FRACUNIT;

var
  camera: gld_camera_t;
  use_fog: boolean = false;
  fog_density: integer = 100;
  use_white_fog: boolean = true;
  white_fog_density: integer = 200;

implementation

end.
