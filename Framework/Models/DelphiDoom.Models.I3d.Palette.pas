{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the palette of the I3D models               }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of OPENGL\i3d_palette.pas of Speed.                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Palette;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Models.I3d.Types;

type
  /// <summary>
  ///   The fixed palette of the I3D models: 256 colors of 6 bits for each channel (the VGA palette
  ///   of the DOS game). The arithmetic wraps on purpose (colors packed in a 32 bit number).
  /// </summary>
  TI3dPalette = class
  public
    /// <summary>The color of an index as numbers from 0 to 1 (the center of the 6 bit step)</summary>
    class function Color3f(const AIndex: Byte): TI3dColor3f; static;
    /// <summary>The color of an index as $00BBGGRR (8 bit for each channel)</summary>
    class function ColorLong(const AIndex: Byte): Cardinal; static;
    /// <summary>
    ///   The index of the color that is nearest to a $00BBGGRR color. As in the old code the
    ///   channels of the color (0..255) are compared with the 6 bit values of the palette without
    ///   scaling: a defect that is kept (it is only used by the editor of the corrections).
    /// </summary>
    class function IndexOf(const AColor: Cardinal): Integer; static;
  end;

implementation

const
  RAW_PALETTE: array[0..767] of Byte = (
    $00, $00, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $3F, $38, $32, $3B, $32, $2C, $38, $2E, $27, $35, $29, $21,
    $32, $24, $1D, $2F, $1F, $18, $2C, $1B, $14, $29, $16, $11, $26, $12, $0D,
    $22, $0F, $0A, $1F, $0B, $07, $1C, $08, $05, $19, $05, $03, $16, $02, $01,
    $13, $01, $00, $10, $00, $00, $3F, $36, $36, $3B, $2B, $2B, $37, $21, $21,
    $33, $18, $18, $2F, $10, $10, $2B, $09, $09, $27, $03, $03, $23, $00, $00,
    $3F, $2A, $17, $3F, $26, $10, $3F, $22, $08, $3F, $1E, $00, $39, $1B, $00,
    $33, $18, $00, $2D, $15, $00, $27, $13, $00, $3F, $3F, $36, $3E, $3D, $30,
    $3D, $3C, $2B, $3C, $3A, $25, $3B, $39, $20, $3A, $37, $1B, $39, $35, $16,
    $38, $33, $12, $33, $2E, $0E, $2E, $2A, $0A, $29, $26, $07, $24, $22, $05,
    $1F, $1D, $03, $1A, $19, $01, $15, $14, $00, $10, $10, $00, $39, $39, $2D,
    $36, $36, $28, $33, $33, $24, $30, $30, $20, $2D, $2D, $1C, $2A, $2B, $19,
    $27, $28, $16, $24, $25, $12, $21, $22, $0F, $1E, $1F, $0D, $1C, $1D, $0A,
    $19, $1A, $08, $16, $17, $06, $13, $14, $04, $10, $11, $03, $0E, $0F, $02,
    $2C, $33, $00, $27, $30, $00, $23, $2E, $00, $1F, $2C, $00, $1B, $29, $00,
    $17, $27, $00, $14, $25, $00, $11, $22, $00, $0E, $20, $00, $0C, $1E, $00,
    $09, $1B, $00, $07, $19, $00, $05, $17, $00, $03, $14, $00, $02, $12, $00,
    $01, $10, $00, $3B, $3D, $3E, $34, $39, $3B, $2D, $34, $37, $28, $31, $34,
    $22, $2E, $31, $1D, $2B, $2E, $18, $27, $2B, $14, $25, $28, $10, $22, $25,
    $0C, $1F, $22, $09, $1C, $1F, $06, $1A, $1C, $04, $17, $19, $02, $15, $16,
    $00, $12, $13, $00, $10, $10, $36, $3B, $3F, $30, $37, $3C, $2B, $33, $3A,
    $27, $2F, $38, $22, $2A, $36, $1E, $26, $34, $1A, $22, $31, $16, $1E, $2F,
    $13, $1A, $2D, $10, $16, $2B, $0D, $12, $29, $0A, $0E, $26, $07, $0A, $24,
    $05, $07, $22, $03, $04, $20, $01, $01, $1E, $31, $24, $1A, $2E, $21, $17,
    $2C, $1F, $14, $29, $1D, $11, $27, $1B, $0F, $24, $19, $0C, $22, $18, $0A,
    $1F, $16, $08, $1D, $14, $06, $1A, $12, $05, $18, $11, $03, $15, $0F, $02,
    $13, $0E, $01, $11, $0C, $00, $0E, $0A, $00, $0C, $09, $00, $3F, $3D, $37,
    $3C, $39, $32, $3A, $36, $2E, $38, $32, $2A, $35, $2F, $26, $33, $2B, $22,
    $31, $27, $1E, $2F, $24, $1B, $2C, $21, $18, $29, $1E, $15, $26, $1B, $13,
    $23, $18, $11, $20, $15, $0F, $1D, $13, $0C, $1B, $10, $0B, $18, $0E, $09,
    $3B, $3B, $3B, $39, $39, $39, $37, $37, $37, $35, $35, $35, $33, $33, $33,
    $31, $31, $31, $2F, $2F, $2F, $2D, $2D, $2D, $2B, $2B, $2B, $29, $29, $29,
    $27, $27, $27, $25, $25, $25, $23, $23, $23, $22, $22, $22, $20, $20, $20,
    $1E, $1E, $1E, $1C, $1C, $1C, $1A, $1A, $1A, $18, $18, $18, $16, $16, $16,
    $14, $14, $14, $12, $12, $12, $10, $10, $10, $0E, $0E, $0E, $0C, $0C, $0C,
    $0A, $0A, $0A, $09, $09, $09, $07, $07, $07, $05, $05, $05, $03, $03, $03,
    $01, $01, $01, $00, $00, $00, $3B, $32, $32, $38, $2C, $2C, $36, $28, $28,
    $34, $23, $23, $32, $1F, $1F, $30, $1A, $1A, $2D, $17, $17, $2B, $13, $13,
    $29, $10, $10, $27, $0C, $0C, $25, $09, $09, $22, $07, $07, $20, $04, $04,
    $1E, $02, $02, $1C, $01, $01, $1A, $00, $00, $3F, $3F, $2E, $3F, $3D, $22,
    $3F, $39, $16, $3F, $34, $0A, $3F, $2D, $00, $37, $26, $00, $2F, $20, $00,
    $27, $1A, $00, $1F, $15, $00, $3B, $32, $3F, $32, $25, $38, $2B, $1B, $31,
    $24, $12, $2A, $1D, $0A, $23, $17, $05, $1C, $11, $01, $15, $37, $38, $3F,
    $33, $33, $3C, $2F, $30, $39, $2C, $2C, $36, $29, $28, $33, $26, $25, $31,
    $24, $22, $2E, $21, $1F, $2B, $1F, $1C, $28, $1D, $19, $25, $1B, $16, $23,
    $19, $14, $20, $17, $11, $1D, $15, $0F, $1A, $13, $0D, $17, $11, $0B, $15,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00, $00, $3F, $00,
    $3F, $10, $3F
  );

{ TI3dPalette }

class function TI3dPalette.Color3f(const AIndex: Byte): TI3dColor3f;
begin
  Result.B := (RAW_PALETTE[3 * AIndex + 2] + 0.5) / 64;
  Result.G := (RAW_PALETTE[3 * AIndex + 1] + 0.5) / 64;
  Result.R := (RAW_PALETTE[3 * AIndex + 0] + 0.5) / 64;
end;

class function TI3dPalette.ColorLong(const AIndex: Byte): Cardinal;
begin
  Result :=
    (Cardinal(RAW_PALETTE[3 * AIndex + 2]) * 4 + 2) shl 16 +
    (Cardinal(RAW_PALETTE[3 * AIndex + 1]) * 4 + 2) shl 8 +
    (Cardinal(RAW_PALETTE[3 * AIndex + 0]) * 4 + 2);
end;

class function TI3dPalette.IndexOf(const AColor: Cardinal): Integer;
var
  LRed, LGreen, LBlue: Integer;
  LDeltaRed, LDeltaGreen, LDeltaBlue: Integer;
  LIndex: Integer;
  LDistance: Cardinal;
  LMinimum: Cardinal;
begin
  LRed := AColor and $FF;
  LGreen := (AColor shr 8) and $FF;
  LBlue := (AColor shr 16) and $FF;
  Result := 0;
  LMinimum := $FFFFFFFF;
  for LIndex := 0 to 255 do
  begin
    LDeltaRed := LRed - RAW_PALETTE[3 * LIndex];
    LDeltaGreen := LGreen - RAW_PALETTE[3 * LIndex + 1];
    LDeltaBlue := LBlue - RAW_PALETTE[3 * LIndex + 2];
    LDistance := Cardinal(LDeltaRed * LDeltaRed + LDeltaGreen * LDeltaGreen + LDeltaBlue * LDeltaBlue);
    if LDistance < LMinimum then
    begin
      Result := LIndex;
      if LDistance = 0 then
        Exit;
      LMinimum := LDistance;
    end;
  end;
end;

end.
