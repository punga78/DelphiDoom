{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixPaletteBuilder                            }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_palette.pas (from dcolors.c of the Doom utilities). The       }
{  arithmetic of the color shifts wraps on a byte, as the original did         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.PaletteBuilder;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf, DelphiDoom.Radix.Intf;

type
  /// <summary>Makes PLAYPAL, COLORMAP and the translation tables from a palette of Radix</summary>
  TRadixPaletteBuilder = class(TInterfacedObject, IRadixPaletteBuilder)
  strict private
    const
      LightLevels = 32;
      PaletteBytes = 768;
    var
      FMatcher: IColorMatcher;
    procedure CheckPalette(const APalette: TBytes);
    procedure ShiftPalette(const ASource: TBytes; var ADestination: TBytes; ADestinationOffset,
      ARed, AGreen, ABlue, AShift, ASteps: Integer);
    function Scaled(const ABasePalette: TBytes): TBytes;
  public
    /// <param name="AMatcher">Finds the nearest color; EArgumentNilException when nil</param>
    constructor Create(const AMatcher: IColorMatcher);
    function Scale(var APalette: TBytes): Boolean;
    function BuildPlayPal(const ABasePalette: TBytes): TBytes;
    function BuildColorMap(const ABasePalette: TBytes): TBytes;
    function BuildTranslation(const AFromPalette, AToPalette: TBytes): TBytes;
  end;

implementation

uses
  DelphiDoom.Radix.Types;

const
  SRadixBadPalette = 'The palette needs 768 bytes, there are %d';

{ TRadixPaletteBuilder }

constructor TRadixPaletteBuilder.Create(const AMatcher: IColorMatcher);
begin
  inherited Create;
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FMatcher := AMatcher;
end;

procedure TRadixPaletteBuilder.CheckPalette(const APalette: TBytes);
begin
  if Length(APalette) < PaletteBytes then
    raise ERadixException.CreateFmt(SRadixBadPalette, [Length(APalette)]);
end;

function TRadixPaletteBuilder.Scale(var APalette: TBytes): Boolean;
var
  LIndex: Integer;
  LMaximum: Integer;
begin
  CheckPalette(APalette);
  LMaximum := APalette[0];
  for LIndex := 1 to PaletteBytes - 1 do
    if APalette[LIndex] > LMaximum then
      LMaximum := APalette[LIndex];
  Result := LMaximum < 64;
  if Result then
    for LIndex := 0 to PaletteBytes - 1 do
      APalette[LIndex] := Byte(4 * APalette[LIndex]);
end;

function TRadixPaletteBuilder.Scaled(const ABasePalette: TBytes): TBytes;
begin
  CheckPalette(ABasePalette);
  Result := Copy(ABasePalette, 0, PaletteBytes);
  Scale(Result);
end;

procedure TRadixPaletteBuilder.ShiftPalette(const ASource: TBytes; var ADestination: TBytes;
  ADestinationOffset, ARed, AGreen, ABlue, AShift, ASteps: Integer);
var
  LColor: Integer;
  LDeltaRed: Integer;
  LDeltaGreen: Integer;
  LDeltaBlue: Integer;
begin
  for LColor := 0 to 255 do
  begin
    LDeltaRed := ARed - ASource[LColor * 3];
    LDeltaGreen := AGreen - ASource[LColor * 3 + 1];
    LDeltaBlue := ABlue - ASource[LColor * 3 + 2];
    ADestination[ADestinationOffset + LColor * 3] :=
      Byte(ASource[LColor * 3] + (LDeltaRed * AShift) div ASteps);
    ADestination[ADestinationOffset + LColor * 3 + 1] :=
      Byte(ASource[LColor * 3 + 1] + (LDeltaGreen * AShift) div ASteps);
    ADestination[ADestinationOffset + LColor * 3 + 2] :=
      Byte(ASource[LColor * 3 + 2] + (LDeltaBlue * AShift) div ASteps);
  end;
end;

function TRadixPaletteBuilder.BuildPlayPal(const ABasePalette: TBytes): TBytes;
var
  LBase: TBytes;
  LIndex: Integer;
begin
  LBase := Scaled(ABasePalette);
  SetLength(Result, PaletteBytes * 22);
  Move(LBase[0], Result[0], PaletteBytes);
  for LIndex := 1 to 8 do
    ShiftPalette(LBase, Result, PaletteBytes * LIndex, 255, 0, 0, LIndex, 9);
  for LIndex := 1 to 4 do
    ShiftPalette(LBase, Result, PaletteBytes * (LIndex + 8), 215, 186, 69, LIndex, 8);
  ShiftPalette(LBase, Result, PaletteBytes * 13, 0, 256, 0, 1, 8);
  for LIndex := 1 to 8 do
    ShiftPalette(LBase, Result, PaletteBytes * (LIndex + 13), 255, 255, 255, LIndex, 9);
end;

function TRadixPaletteBuilder.BuildColorMap(const ABasePalette: TBytes): TBytes;
var
  LBase: TBytes;
  LLight: Integer;
  LColor: Integer;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LGray: Double;
  LGrayByte: Integer;
begin
  LBase := Scaled(ABasePalette);
  SetLength(Result, (LightLevels + 2) * 256);
  for LLight := 0 to LightLevels - 1 do
    for LColor := 0 to 255 do
    begin
      LRed := (LBase[LColor * 3] * (LightLevels - LLight) + LightLevels div 2) div LightLevels;
      LGreen := (LBase[LColor * 3 + 1] * (LightLevels - LLight) + LightLevels div 2) div LightLevels;
      LBlue := (LBase[LColor * 3 + 2] * (LightLevels - LLight) + LightLevels div 2) div LightLevels;
      Result[LLight * 256 + LColor] := FMatcher.BestColor(Byte(LRed), Byte(LGreen), Byte(LBlue), LBase, 0, 255);
    end;
  for LColor := 0 to 255 do
  begin
    // the 265 is the typo of Carmack (doomwiki.org/wiki/Carmack%27s_typo), kept as the converter had it
    LGray := LBase[LColor * 3] * 0.299 / 256 + LBase[LColor * 3 + 1] * 0.587 / 265 +
      LBase[LColor * 3 + 2] * 0.114 / 256;
    LGray := 1.0 - LGray;
    LGrayByte := Trunc(LGray * 255);
    Result[LightLevels * 256 + LColor] :=
      FMatcher.BestColor(Byte(LGrayByte), Byte(LGrayByte), Byte(LGrayByte), LBase, 0, 255);
  end;
  // the last table is all black
  for LColor := 0 to 255 do
    Result[(LightLevels + 1) * 256 + LColor] := 0;
end;

function TRadixPaletteBuilder.BuildTranslation(const AFromPalette, AToPalette: TBytes): TBytes;
var
  LColor: Integer;
begin
  CheckPalette(AFromPalette);
  CheckPalette(AToPalette);
  SetLength(Result, 256);
  for LColor := 0 to 255 do
    Result[LColor] := FMatcher.BestColor(AToPalette[LColor * 3], AToPalette[LColor * 3 + 1],
      AToPalette[LColor * 3 + 2], AFromPalette, 0, 255);
end;

end.
