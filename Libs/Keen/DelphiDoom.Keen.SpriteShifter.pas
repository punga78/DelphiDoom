{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the shifted copies of a sprite                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CAL_ShiftSprite of id_ca.c and the shift tables of id_vw_a.asm               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SpriteShifter;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

type
  /// <summary>
  ///   The EGA draws a byte of 8 pixels at a time, so a sprite that is not at a multiple of 8 pixels needs a
  ///   copy of its planes moved right by 2, 4 or 6 pixels and one byte wider. The shifted mask has 1 (the
  ///   screen stays) in the pixels that the shift adds, the shifted data have 0
  /// </summary>
  TKeenSpriteShifter = class
  public
    /// <summary>
    ///   The word that the shift table of AShift pixels (shiftdata0..7 of id_vw_a.asm) gives for a byte:
    ///   the low byte is the byte moved right, the high byte the pixels that fell out of it, at the left
    /// </summary>
    class function ShiftWord(AValue: Byte; AShift: Integer): Word; static;
    /// <summary>
    ///   CAL_ShiftSprite: reads at ASource of AData the mask and the 4 planes (AWidth bytes by AHeight rows)
    ///   and writes at ADest the same planes moved right by APixelShift pixels, each row AWidth + 1 bytes.
    ///   Source and destination are in the same array and do not overlap
    /// </summary>
    class procedure ShiftSprite(var AData: TBytes; ASource, ADest, AWidth, AHeight,
      APixelShift: Integer); static;
    /// <summary>The bytes of the mask and the 4 planes of a sprite whose planes are APlaneSize bytes: 5 planes</summary>
    class function ShiftedSize(AWidth, AHeight: Integer): Integer; static;
  end;

implementation

{ TKeenSpriteShifter }

class function TKeenSpriteShifter.ShiftWord(AValue: Byte; AShift: Integer): Word;
begin
  if (AShift < 0) or (AShift >= KEEN_MAXSHIFTS) then
    raise EKeenException.CreateFmt(SKeenSizeInvalid, [AShift, 0]);
  Result := Word((AValue shr AShift) or (((AValue shl (8 - AShift)) and $FF) shl 8));
end;

class function TKeenSpriteShifter.ShiftedSize(AWidth, AHeight: Integer): Integer;
begin
  Result := (AWidth + 1) * AHeight * (KEEN_EGA_PLANES + 1);
end;

class procedure TKeenSpriteShifter.ShiftSprite(var AData: TBytes; ASource, ADest, AWidth, AHeight,
  APixelShift: Integer);
var
  LSource: Integer;
  LDest: Integer;
  LRow: Integer;
  LColumn: Integer;
  LRows: Integer;
  LShifted: Word;
  LIsMask: Boolean;
begin
  if (AWidth <= 0) or (AHeight <= 0) then
    raise EKeenException.CreateFmt(SKeenSizeInvalid, [AWidth * 8, AHeight]);
  if (ASource < 0) or (ADest < 0) or
    (Int64(ASource) + Int64(AWidth) * AHeight * (KEEN_EGA_PLANES + 1) > Length(AData)) or
    (Int64(ADest) + Int64(AWidth + 1) * AHeight * (KEEN_EGA_PLANES + 1) > Length(AData)) then
    raise EKeenDataException.CreateFmt(SKeenSpriteTooShort,
      [Int64(ADest) + Int64(AWidth + 1) * AHeight * (KEEN_EGA_PLANES + 1), Length(AData)]);
  LSource := ASource;
  LDest := ADest;
  // the mask rows (height of them), then the 4 planes (4 * height rows)
  LRows := AHeight * (KEEN_EGA_PLANES + 1);
  for LRow := 0 to LRows - 1 do
  begin
    LIsMask := LRow < AHeight;
    if LIsMask then
      AData[LDest] := 255
    else
      AData[LDest] := 0;
    for LColumn := 0 to AWidth - 1 do
    begin
      if LIsMask then
        LShifted := ShiftWord(Byte(not AData[LSource]), APixelShift)
      else
        LShifted := ShiftWord(AData[LSource], APixelShift);
      Inc(LSource);
      if LIsMask then
      begin
        // the mask is shifted inverted, then inverted back: the pixels that come in are 1
        LShifted := Word(not LShifted);
        AData[LDest] := AData[LDest] and Byte(LShifted);
      end
      else
        AData[LDest] := AData[LDest] or Byte(LShifted);
      Inc(LDest);
      AData[LDest] := Byte(LShifted shr 8);
    end;
    // the last byte of the row has the pixels that fell out of the last source byte
    Inc(LDest);
  end;
end;

end.
