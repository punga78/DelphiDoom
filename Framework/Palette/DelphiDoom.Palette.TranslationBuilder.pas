{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - translation tables between two palettes        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.TranslationBuilder;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>V_CreateTranslation, and the identity table</summary>
  TTranslationBuilder = class(TInterfacedObject, ITranslationBuilder)
  strict private
    FMatcher: IColorMatcher;
  public
    constructor Create(const AMatcher: IColorMatcher);
    function Build(const AFromPalette, AToPalette: TBytes): TBytes;
    function Identity: TBytes;
  end;

implementation

{ TTranslationBuilder }

constructor TTranslationBuilder.Create(const AMatcher: IColorMatcher);
begin
  inherited Create;
  FMatcher := AMatcher;
end;

function TTranslationBuilder.Build(const AFromPalette, AToPalette: TBytes): TBytes;
var
  LIndex: Integer;
begin
  if Length(AToPalette) < PALETTE_BYTE_COUNT then
    raise EPaletteException.CreateFmt(SPaletteTooShort, [Length(AToPalette), PALETTE_BYTE_COUNT]);
  SetLength(Result, COLORMAP_ROW_SIZE);
  for LIndex := 0 to PALETTE_COLOR_COUNT - 1 do
    Result[LIndex] := FMatcher.BestColor(AToPalette[LIndex * 3], AToPalette[LIndex * 3 + 1],
      AToPalette[LIndex * 3 + 2], AFromPalette, 0, PALETTE_COLOR_COUNT - 1);
end;

function TTranslationBuilder.Identity: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, COLORMAP_ROW_SIZE);
  for LIndex := 0 to COLORMAP_ROW_SIZE - 1 do
    Result[LIndex] := Byte(LIndex);
end;

end.
