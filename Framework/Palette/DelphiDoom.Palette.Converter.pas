{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the palette converter                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.Converter;

interface

uses
  DelphiDoom.Palette.Intf;

type
  TPaletteConverter = class(TInterfacedObject, IPaletteConverter)
  public
    const
      COLOR_COUNT = 256;
    procedure Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal);
  end;

implementation

uses
  DelphiDoom.Palette.ScreenPalette;

{ TPaletteConverter }

procedure TPaletteConverter.Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal);
begin
  // the colors without alpha: the same loop that the engine runs on the screen palettes
  TScreenPalette.Convert(ASource, AGamma, ADest, 0);
end;

end.
