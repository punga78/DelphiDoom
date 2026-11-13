{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the scrambling of the header (AAS_DData)          }
{                                                                              }
{  Port of AAS_DData of be_aas_file.c. Based on the Quake III Arena GPL        }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.HeaderCipher;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types;

type
  /// <summary>
  ///   Every byte of the header after the identifier and the version is xor-ed with
  ///   (byte index) * 119 truncated to a byte; the same operation scrambles and unscrambles.
  ///   The index counts from the first scrambled byte (the bytes of the original are
  ///   data[i] with data = header + 8).
  /// </summary>
  TAasHeaderCipher = class
  public
    class procedure Apply(var AHeader: TAasFileHeader); static;
  end;

implementation

{ TAasHeaderCipher }

class procedure TAasHeaderCipher.Apply(var AHeader: TAasFileHeader);
var
  LBytes: PByte;
  LIndex: Integer;
begin
  LBytes := PByte(@AHeader) + AAS_SCRAMBLE_START;
  for LIndex := 0 to SizeOf(TAasFileHeader) - AAS_SCRAMBLE_START - 1 do
    LBytes[LIndex] := LBytes[LIndex] xor Byte(Byte(LIndex) * 119);
end;

end.
