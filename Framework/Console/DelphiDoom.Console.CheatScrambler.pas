{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the scrambled keys of the cheats              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CheatScrambler;

interface

type
  /// <summary>
  ///   The sequences of the cheats are written with the bits of every letter mixed up, so that
  ///   they are not readable in the executable. This gives the mixed byte of a key
  /// </summary>
  TCheatScrambler = class
  public
    /// <summary>Bit 0 goes to 7, 1 to 6, 2 stays, 3 goes to 4, 4 to 3, 5 stays, 6 goes to 1, 7 to 0</summary>
    class function Scramble(AValue: Byte): Byte; static;
  end;

implementation

{ TCheatScrambler }

class function TCheatScrambler.Scramble(AValue: Byte): Byte;
begin
  Result := Byte(((AValue and 1) shl 7) +
                 ((AValue and 2) shl 5) +
                 (AValue and 4) +
                 ((AValue and 8) shl 1) +
                 ((AValue and 16) shr 1) +
                 (AValue and 32) +
                 ((AValue and 64) shr 5) +
                 ((AValue and 128) shr 7));
end;

end.
