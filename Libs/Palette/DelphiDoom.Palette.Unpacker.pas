{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the palette as packed colors                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.Unpacker;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf, DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   R_DefaultPalette (and the same code of R_InitCustomColormaps and R_InitData): 768 bytes
  ///   to 256 colors $00RRGGBB. It is the converter of the video library with a gamma that
  ///   changes nothing, so nothing is duplicated
  /// </summary>
  TPaletteUnpacker = class(TInterfacedObject, IPaletteUnpacker)
  strict private
    FConverter: IPaletteConverter;
    FIdentityGamma: TBytes;
  public
    constructor Create(const AConverter: IPaletteConverter);
    function Unpack(const APalette: TBytes): TArray<Cardinal>;
  end;

implementation

{ TPaletteUnpacker }

constructor TPaletteUnpacker.Create(const AConverter: IPaletteConverter);
var
  LIndex: Integer;
begin
  inherited Create;
  FConverter := AConverter;
  SetLength(FIdentityGamma, 256);
  for LIndex := 0 to 255 do
    FIdentityGamma[LIndex] := Byte(LIndex);
end;

function TPaletteUnpacker.Unpack(const APalette: TBytes): TArray<Cardinal>;
begin
  if Length(APalette) < PALETTE_BYTE_COUNT then
    raise EPaletteException.CreateFmt(SPaletteTooShort, [Length(APalette), PALETTE_BYTE_COUNT]);
  SetLength(Result, PALETTE_COLOR_COUNT);
  FConverter.Convert(@APalette[0], @FIdentityGamma[0], PCardinal(@Result[0]));
end;

end.
