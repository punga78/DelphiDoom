{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of tables for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\tables.pas in DelphiDoom.Tests.OpenGl.<Game> only: the angle type and the fine angle constants (same values).
unit tables;

interface

type
  angle_t = LongWord;

const
  ANGLETOFINESHIFT = 19;
  FINEANGLES = 1 shl (32 - ANGLETOFINESHIFT);

implementation

end.