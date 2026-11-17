{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_draw for the per-game OpenGL scene tests         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_draw.pas in DelphiDoom.Tests.OpenGl.<Game> only: the view window and the colour regions.
unit r_draw;

interface

type
  crange_idx_e = (
    CR_BRICK, CR_TAN, CR_GRAY, CR_GREEN, CR_BROWN, CR_GOLD, CR_RED, CR_BLUE, CR_ORANGE, CR_YELLOW, CR_BLUE2,
    CR_BLACK, CR_PURPL, CR_WHITE, CR_TRANS0, CR_TRANS1, CR_TRANS2, CR_TRANS3, CR_TRANS4, CR_TRANS5, CR_TRANS6,
    CR_TRANS7, CR_TRANS8, CR_TRANS9, CR_LIMIT
  );

var
  viewwindowx: integer = 0;
  viewwindowy: integer = 0;
  viewwidth: integer = 0;
  viewheight: integer = 0;

implementation

end.