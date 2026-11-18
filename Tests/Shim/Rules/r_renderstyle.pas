{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_renderstyle for the rule tests                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\r_renderstyle.pas in DelphiDoom.Tests.Rules only: the render styles of a mobj
// (the real unit reads the DEHACKED token lists, which pull in the whole patch reader).
unit r_renderstyle;

interface

type
  mobjrenderstyle_t = (mrs_normal, mrs_translucent, mrs_add, mrs_subtract, NUMMOBJRENDERSTYLES);

implementation

end.