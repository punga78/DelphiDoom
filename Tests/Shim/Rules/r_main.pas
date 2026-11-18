{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of r_main for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real r_main in DelphiDoom.Tests.Rules only: the validation counter and the point-in-subsector call that p_maputl names.
{$I Doom32.inc}
unit r_main;

interface

uses
  m_fixed,
  r_defs;

var
  validcount: integer = 1;
  viewx: fixed_t;
  viewy: fixed_t;
  viewz: fixed_t;

type
  TRendererMain = class sealed
  public
    class function R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t; static;
  end;

implementation

class function TRendererMain.R_PointInSubsector(const x: fixed_t; const y: fixed_t): Psubsector_t;
begin
  result := nil;
end;

end.