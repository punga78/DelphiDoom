{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of p_secnodes for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real p_secnodes in DelphiDoom.Tests.Rules only: the list head and the creation call that p_maputl names (the real unit keeps the sector lists of the things).
{$I Doom32.inc}
unit p_secnodes;

interface

uses
  m_fixed,
  p_mobj_h;

var
  sector_list: pointer;

procedure P_CreateSecNodeList(thing: Pmobj_t; x, y: fixed_t);

implementation

procedure P_CreateSecNodeList(thing: Pmobj_t; x, y: fixed_t);
begin
end;

end.