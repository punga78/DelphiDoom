{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of po_man for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real po_man in DelphiDoom.Tests.Rules only: the polyobject block map head (polyobjects exist in Hexen only: it stays nil).
{$I Doom32.inc}
unit po_man;

interface

uses
  r_defs;

var
  PolyBlockMap: Ppolyblock_tPArray = nil;

implementation

end.