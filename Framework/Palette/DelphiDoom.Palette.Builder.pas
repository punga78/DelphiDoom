{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - PLAYPAL, COLORMAP and FOGMAP from a palette    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.Builder;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   V_CreateDoomPalette: from the 768 bytes of the base palette the flashes of PLAYPAL and the
  ///   34 rows of COLORMAP (32 lights, gray, black) and of FOGMAP. What changes between the games
  ///   is in the profile; the nearest color comes from the matcher
  /// </summary>
  TPaletteBuilder = class(TInterfacedObject, IPaletteBuilder)
  strict private
    const
      LIGHT_ROWS = COLORMAP_LIGHT_COUNT;
    var
      FMatcher: IColorMatcher;
      FProfile: TPaletteProfile;
    class procedure ShiftPalette(const AInput: TBytes; var AOutput: TBytes; AOffset: Integer;
      const AShift: TPaletteShift); static;
    class function GrayOf(ARed, AGreen, ABlue: Integer): Double; static;
    function GrayIndex(const APalette: TBytes; AGray: Double): Byte;
    function BuildColormap(const APalette: TBytes): TBytes;
    function BuildFogmap(const APalette: TBytes): TBytes;
  public
    constructor Create(const AMatcher: IColorMatcher; const AProfile: TPaletteProfile);
    function Build(const ABasePalette: TBytes; AWithColormap, AWithFogmap: Boolean): TPaletteSet;
  end;

implementation

{ TPaletteBuilder }

constructor TPaletteBuilder.Create(const AMatcher: IColorMatcher; const AProfile: TPaletteProfile);
begin
  inherited Create;
  FMatcher := AMatcher;
  FProfile := AProfile;
end;

class procedure TPaletteBuilder.ShiftPalette(const AInput: TBytes; var AOutput: TBytes;
  AOffset: Integer; const AShift: TPaletteShift);
var
  LIndex: Integer;
begin
  for LIndex := 0 to PALETTE_COLOR_COUNT - 1 do
  begin
    AOutput[AOffset + LIndex * 3] := Byte(AInput[LIndex * 3] +
      ((AShift.Red - AInput[LIndex * 3]) * AShift.Shift) div AShift.Steps);
    AOutput[AOffset + LIndex * 3 + 1] := Byte(AInput[LIndex * 3 + 1] +
      ((AShift.Green - AInput[LIndex * 3 + 1]) * AShift.Shift) div AShift.Steps);
    AOutput[AOffset + LIndex * 3 + 2] := Byte(AInput[LIndex * 3 + 2] +
      ((AShift.Blue - AInput[LIndex * 3 + 2]) * AShift.Shift) div AShift.Steps);
  end;
end;

class function TPaletteBuilder.GrayOf(ARed, AGreen, ABlue: Integer): Double;
begin
  // https://doomwiki.org/wiki/Carmack%27s_typo : the original has 265 for the green and so do we
  Result := ARed * 0.299 / 256 + AGreen * 0.587 / 265 + ABlue * 0.114 / 256;
end;

function TPaletteBuilder.GrayIndex(const APalette: TBytes; AGray: Double): Byte;
var
  LLevel: Byte;
begin
  LLevel := Byte(Trunc(AGray * 255));
  Result := FMatcher.BestColor(LLevel, LLevel, LLevel, APalette, 0, PALETTE_COLOR_COUNT - 1);
end;

function TPaletteBuilder.BuildColormap(const APalette: TBytes): TBytes;
var
  LLight: Integer;
  LColor: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LGray: Double;
begin
  SetLength(Result, COLORMAP_GENERATED_ROWS * COLORMAP_ROW_SIZE);
  for LLight := 0 to LIGHT_ROWS - 1 do
    for LColor := 0 to PALETTE_COLOR_COUNT - 1 do
    begin
      if FProfile.LastColorShadesAsFirst and (LColor = PALETTE_COLOR_COUNT - 1) then
      begin
        // Hexen palette index 255 - see https://zdoom.org/wiki/Palette#Hexen
        LRed := APalette[0];
        LGreen := APalette[1];
        LBlue := APalette[2];
      end
      else
      begin
        LRed := APalette[LColor * 3];
        LGreen := APalette[LColor * 3 + 1];
        LBlue := APalette[LColor * 3 + 2];
      end;
      LRed := (LRed * (LIGHT_ROWS - LLight) + LIGHT_ROWS div 2) div LIGHT_ROWS;
      LGreen := (LGreen * (LIGHT_ROWS - LLight) + LIGHT_ROWS div 2) div LIGHT_ROWS;
      LBlue := (LBlue * (LIGHT_ROWS - LLight) + LIGHT_ROWS div 2) div LIGHT_ROWS;
      Result[LLight * COLORMAP_ROW_SIZE + LColor] :=
        FMatcher.BestColor(Byte(LRed), Byte(LGreen), Byte(LBlue), APalette, 0, PALETTE_COLOR_COUNT - 1);
    end;

  for LColor := 0 to PALETTE_COLOR_COUNT - 1 do
  begin
    LGray := GrayOf(APalette[LColor * 3], APalette[LColor * 3 + 1], APalette[LColor * 3 + 2]);
    if FProfile.InvertedGrayRow then
      LGray := 1.0 - LGray;
    Result[LIGHT_ROWS * COLORMAP_ROW_SIZE + LColor] := GrayIndex(APalette, LGray);
  end;
  // the last row (black) stays at 0
end;

function TPaletteBuilder.BuildFogmap(const APalette: TBytes): TBytes;
var
  LLight: Integer;
  LColor: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
begin
  SetLength(Result, COLORMAP_GENERATED_ROWS * COLORMAP_ROW_SIZE);
  for LLight := 0 to LIGHT_ROWS - 1 do
    for LColor := 0 to PALETTE_COLOR_COUNT - 1 do
    begin
      // the light acts on the negative of the color: the fog is light, not dark
      LRed := 255 - APalette[LColor * 3];
      LGreen := 255 - APalette[LColor * 3 + 1];
      LBlue := 255 - APalette[LColor * 3 + 2];
      LRed := (LRed * (LIGHT_ROWS - LLight) + LIGHT_ROWS div 2) div LIGHT_ROWS;
      LGreen := (LGreen * (LIGHT_ROWS - LLight) + LIGHT_ROWS div 2) div LIGHT_ROWS;
      LBlue := (LBlue * (LIGHT_ROWS - LLight) + LIGHT_ROWS div 2) div LIGHT_ROWS;
      LRed := 255 - LRed;
      LGreen := 255 - LGreen;
      LBlue := 255 - LBlue;
      Result[LLight * COLORMAP_ROW_SIZE + LColor] :=
        FMatcher.BestColor(Byte(LRed), Byte(LGreen), Byte(LBlue), APalette, 0, PALETTE_COLOR_COUNT - 1);
    end;

  // the gray row of the fog is never inverted, in any game
  for LColor := 0 to PALETTE_COLOR_COUNT - 1 do
    Result[LIGHT_ROWS * COLORMAP_ROW_SIZE + LColor] := GrayIndex(APalette,
      GrayOf(APalette[LColor * 3], APalette[LColor * 3 + 1], APalette[LColor * 3 + 2]));
end;

function TPaletteBuilder.Build(const ABasePalette: TBytes; AWithColormap,
  AWithFogmap: Boolean): TPaletteSet;
var
  LIndex: Integer;
  LMaximum: Integer;
begin
  if Length(ABasePalette) < PALETTE_BYTE_COUNT then
    raise EPaletteException.CreateFmt(SPaletteTooShort, [Length(ABasePalette), PALETTE_BYTE_COUNT]);

  SetLength(Result.BasePalette, PALETTE_BYTE_COUNT);
  Move(ABasePalette[0], Result.BasePalette[0], PALETTE_BYTE_COUNT);
  LMaximum := Result.BasePalette[0];
  for LIndex := 1 to PALETTE_BYTE_COUNT - 1 do
    if Result.BasePalette[LIndex] > LMaximum then
      LMaximum := Result.BasePalette[LIndex];
  // a palette of 6 bits per channel (as the VGA one) is brought to 8
  if LMaximum < 64 then
    for LIndex := 0 to PALETTE_BYTE_COUNT - 1 do
      Result.BasePalette[LIndex] := 4 * Result.BasePalette[LIndex];

  SetLength(Result.Playpal, FProfile.PaletteCount * PALETTE_BYTE_COUNT);
  Move(Result.BasePalette[0], Result.Playpal[0], PALETTE_BYTE_COUNT);
  for LIndex := 0 to High(FProfile.Shifts) do
    ShiftPalette(Result.BasePalette, Result.Playpal,
      FProfile.Shifts[LIndex].TargetIndex * PALETTE_BYTE_COUNT, FProfile.Shifts[LIndex]);

  Result.Colormap := nil;
  Result.Fogmap := nil;
  if AWithColormap then
    Result.Colormap := BuildColormap(Result.BasePalette);
  if AWithFogmap then
    Result.Fogmap := BuildFogmap(Result.BasePalette);
end;

end.
