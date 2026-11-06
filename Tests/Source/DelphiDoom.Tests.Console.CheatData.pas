{******************************************************************************}
{                                                                              }
{  DelphiDoom: data shared by the cheat tests                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CheatData;

interface

const
  // as in st_stuff: "iddqd", "idmus" with a parameter of two keys, and "idkfa"
  IDDQD: array[0..5] of Byte = ($B2, $26, $26, $AA, $26, $FF);
  IDMUS: array[0..8] of Byte = ($B2, $26, $B6, $AE, $EA, $01, $00, $00, $FF);
  IDKFA: array[0..5] of Byte = ($B2, $26, $F2, $66, $A2, $FF);

implementation

end.
