{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of m_fixed for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\m_fixed.pas in DelphiDoom.Tests.OpenGl.<Game> only: the fixed point constants
// the scene units use, same values.
unit m_fixed;

interface

const
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;

implementation

end.
