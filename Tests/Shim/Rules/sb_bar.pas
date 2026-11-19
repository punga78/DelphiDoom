{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of sb_bar for the rule tests                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real sb_bar (Heretic, Hexen) in the rule test projects only: the two cursor variables of the inventory bar that PlayerArtifacts moves (the real unit is the status bar).
{$I Doom32.inc}
unit sb_bar;

interface

var
  curpos: integer;
  inv_ptr: integer;

implementation

end.
