{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_defs for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_defs.pas in DelphiDoom.Tests.OpenGl.<Game> only: the fields of vissprite_t the weapon reads.
unit r_defs;

interface

uses
  m_fixed;

type
  vissprite_t = record
    x1: integer;
    x2: integer;
    scale: fixed_t;
    texturemid: fixed_t;
  end;
  Pvissprite_t = ^vissprite_t;

implementation

end.