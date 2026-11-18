{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of w_wad for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real w_wad in DelphiDoom.Tests.Rules only: the eight character lump name type (the real unit is the lump directory of the engine).
{$I Doom32.inc}
unit w_wad;

interface

type
  char8_t = array[0..7] of AnsiChar;
  Pchar8_t = ^char8_t;

implementation

end.