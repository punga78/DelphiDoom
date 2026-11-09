{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedPaletteBuilder                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_CreateDoomPalette (speed_palette.pas, from dcolors.c of the      }
{  Doom utilities) and of GeneratePalette of speed_xlat_wad.pas                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.PaletteBuilder;

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   Makes the 14 palettes of PLAYPAL (red for the pain, yellow for the bonus, green for the
  ///   radiation suit) and the 34 maps of COLORMAP (32 lights, the inverse and a black one) from the
  ///   palette of the game. The palette of the file has 6 bits per component and is multiplied by 4
  ///   when no value reaches 64
  /// </summary>
  TSpeedPaletteBuilder = class(TInterfacedObject, ISpeedPaletteBuilder)
  strict private
    FMatcher: IColorMatcher;
    class procedure ColorShift(const AInput: TBytes; var AOutput: TBytes; AOffset, ARed, AGreen,
      ABlue, AShift, ASteps: Integer); static;
  public
    /// <param name="AMatcher">Matches colors to the palette; EArgumentNilException when nil</param>
    constructor Create(const AMatcher: IColorMatcher);
    function Build(const AFilePalette: TBytes): TSpeedPalette;
  end;

implementation

uses
  DelphiDoom.GameData.Types, DelphiDoom.Speed.Types;

const
  LIGHT_COUNT = 32;

{ TSpeedPaletteBuilder }

constructor TSpeedPaletteBuilder.Create(const AMatcher: IColorMatcher);
begin
  inherited Create;
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FMatcher := AMatcher;
end;

class procedure TSpeedPaletteBuilder.ColorShift(const AInput: TBytes; var AOutput: TBytes;
  AOffset, ARed, AGreen, ABlue, AShift, ASteps: Integer);
var
  LColor: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
begin
  for LColor := 0 to 255 do
  begin
    LRed := ARed - AInput[LColor * 3];
    LGreen := AGreen - AInput[LColor * 3 + 1];
    LBlue := ABlue - AInput[LColor * 3 + 2];
    AOutput[AOffset + LColor * 3] := Byte(AInput[LColor * 3] + (LRed * AShift) div ASteps);
    AOutput[AOffset + LColor * 3 + 1] := Byte(AInput[LColor * 3 + 1] + (LGreen * AShift) div ASteps);
    AOutput[AOffset + LColor * 3 + 2] := Byte(AInput[LColor * 3 + 2] + (LBlue * AShift) div ASteps);
  end;
end;

function TSpeedPaletteBuilder.Build(const AFilePalette: TBytes): TSpeedPalette;
var
  LIndex: Integer;
  LMaximum: Integer;
  LLight: Integer;
  LColor: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LGray: Double;
  LGrayIndex: Integer;
begin
  if Length(AFilePalette) < GAMEDATA_PALETTE_SIZE then
    raise EGameDataException.CreateFmt(SGameDataBadPalette, [GAMEDATA_PALETTE_SIZE, Length(AFilePalette)]);
  SetLength(Result.Source, GAMEDATA_PALETTE_SIZE);
  Move(AFilePalette[0], Result.Source[0], GAMEDATA_PALETTE_SIZE);

  LMaximum := Result.Source[0];
  for LIndex := 1 to GAMEDATA_PALETTE_SIZE - 1 do
    if Result.Source[LIndex] > LMaximum then
      LMaximum := Result.Source[LIndex];
  if LMaximum < 64 then
    for LIndex := 0 to GAMEDATA_PALETTE_SIZE - 1 do
      Result.Source[LIndex] := Byte(4 * Result.Source[LIndex]);

  SetLength(Result.PlayPal, SPEED_PLAYPAL_PALETTES * GAMEDATA_PALETTE_SIZE);
  Move(Result.Source[0], Result.PlayPal[0], GAMEDATA_PALETTE_SIZE);
  for LIndex := 1 to 8 do
    ColorShift(Result.Source, Result.PlayPal, GAMEDATA_PALETTE_SIZE * LIndex, 255, 0, 0, LIndex, 9);
  for LIndex := 1 to 4 do
    ColorShift(Result.Source, Result.PlayPal, GAMEDATA_PALETTE_SIZE * (LIndex + 8), 215, 186, 69,
      LIndex, 8);
  ColorShift(Result.Source, Result.PlayPal, GAMEDATA_PALETTE_SIZE * 13, 0, 256, 0, 1, 8);

  SetLength(Result.ColorMap, SPEED_COLORMAPS * 256);
  for LLight := 0 to LIGHT_COUNT - 1 do
    for LColor := 0 to 255 do
    begin
      LRed := (Result.Source[LColor * 3] * (LIGHT_COUNT - LLight) + LIGHT_COUNT div 2) div LIGHT_COUNT;
      LGreen := (Result.Source[LColor * 3 + 1] * (LIGHT_COUNT - LLight) + LIGHT_COUNT div 2) div LIGHT_COUNT;
      LBlue := (Result.Source[LColor * 3 + 2] * (LIGHT_COUNT - LLight) + LIGHT_COUNT div 2) div LIGHT_COUNT;
      Result.ColorMap[LLight * 256 + LColor] := FMatcher.BestColor(Byte(LRed), Byte(LGreen),
        Byte(LBlue), Result.Source, 0, 255);
    end;

  for LColor := 0 to 255 do
  begin
    LRed := Result.Source[LColor * 3];
    LGreen := Result.Source[LColor * 3 + 1];
    LBlue := Result.Source[LColor * 3 + 2];
    // https://doomwiki.org/wiki/Carmack%27s_typo : the 265 is the typo of the original, as the old
    // code kept it
    LGray := LRed * 0.299 / 256 + LGreen * 0.587 / 265 + LBlue * 0.114 / 256;
    LGray := 1.0 - LGray;
    LGrayIndex := Trunc(LGray * 255);
    Result.ColorMap[LIGHT_COUNT * 256 + LColor] := FMatcher.BestColor(Byte(LGrayIndex),
      Byte(LGrayIndex), Byte(LGrayIndex), Result.Source, 0, 255);
  end;
  // the last map is black
  for LColor := 0 to 255 do
    Result.ColorMap[(LIGHT_COUNT + 1) * 256 + LColor] := 0;

  SetLength(Result.Colors, 256);
  for LColor := 0 to 255 do
    Result.Colors[LColor] := (Cardinal(Result.Source[LColor * 3]) shl 16) +
      (Cardinal(Result.Source[LColor * 3 + 1]) shl 8) + Result.Source[LColor * 3 + 2];
end;

end.
