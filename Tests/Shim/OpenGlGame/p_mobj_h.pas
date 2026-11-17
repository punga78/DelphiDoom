{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_mobj_h for the per-game OpenGL scene tests       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\p_mobj_h.pas in DelphiDoom.Tests.OpenGl.<Game> only: the fields of mobj_t and mobjinfo_t that the OpenGL scene units read (same names and types; the real records are far bigger).
unit p_mobj_h;

interface

uses
  m_fixed,
  r_renderstyle;

const
  MF_SHADOW = $40000;
  MF_EX_TRANSPARENT = 1;

type
  mobjinfo_t = record
    radius: fixed_t;
  end;
  Pmobjinfo_t = ^mobjinfo_t;

  mobj_t = record
    floorz: fixed_t;
    _type: integer;
    info: Pmobjinfo_t;
    flags: integer;
    flags_ex: integer;
    renderstyle: mobjrenderstyle_t;
  end;
  Pmobj_t = ^mobj_t;

implementation

end.