{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of GlScene.Types for the per-game OpenGL scene tests   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlScene.Types.pas in DelphiDoom.Tests.OpenGl.<Game> only:
// the fields of GLSprite that the light marker reads (same names and types; the real unit needs r_defs and the
// textures of the engine).
unit DelphiDoom.Engine.GlScene.Types;

interface

uses
  d_delphi,
  p_mobj_h;

type
  GLSprite = record
    x, y, z: float;
    dlights: T2DNumberList;
    mo: Pmobj_t;
  end;
  PGLSprite = ^GLSprite;

implementation

end.
